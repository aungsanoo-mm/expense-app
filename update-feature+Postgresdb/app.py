import os
import traceback
import logging
from datetime import datetime
from flask import Flask, request, jsonify, render_template, redirect, url_for, flash, session
from flask_cors import CORS
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from flask_bcrypt import Bcrypt
import psycopg2
import psycopg2.extras
from functools import wraps
from urllib.parse import urlparse, quote_plus
from itsdangerous import URLSafeTimedSerializer, BadSignature, SignatureExpired
from jinja2 import TemplateNotFound

# Configure logging
logging.basicConfig(level=logging.DEBUG)

# --- Environment Check & DB URL Construction ---
DATABASE_URL = os.environ.get("DATABASE_URL")

if not DATABASE_URL:
    pg_host = os.environ.get("POSTGRES_HOST")
    pg_user = os.environ.get("POSTGRES_USER")
    pg_port = os.environ.get("POSTGRES_PORT", "5432")
    pg_pass = os.environ.get("POSTGRES_PASSWORD")
    pg_db   = os.environ.get("POSTGRES_DB")

    missing = [name for name, val in {
        "POSTGRES_HOST": pg_host,
        "POSTGRES_USER": pg_user,
        "POSTGRES_PASSWORD": pg_pass,
        "POSTGRES_DB": pg_db,
    }.items() if not val]
    if missing:
        raise RuntimeError(f"Missing required environment variables: {', '.join(missing)}")

    # URL-encode password so special chars don't break the URL
    encoded_pass = quote_plus(pg_pass)
    DATABASE_URL = f"postgresql://{pg_user}:{encoded_pass}@{pg_host}:{pg_port}/{pg_db}"

ADMIN_SETUP_TOKEN = os.environ.get("ADMIN_SETUP_TOKEN", "")  # optional secret to create/promote admin

app = Flask(__name__)
app.secret_key = os.environ.get("SESSION_SECRET", "default-secret-key-change-me")
CORS(app)

# token serializer for password reset links
serializer = URLSafeTimedSerializer(app.secret_key)

# Initialize Flask-Login and Bcrypt
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'
login_manager.login_message = 'Please log in to access this page.'
bcrypt = Bcrypt(app)

# User class for Flask-Login
class User(UserMixin):
    def __init__(self, id, username, email, role='user'):
        self.id = id
        self.username = username
        self.email = email
        self.role = role
    
    def is_admin(self):
        return self.role == 'admin'

@login_manager.user_loader
def load_user(user_id):
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute("SELECT id, username, email, role FROM users WHERE id = %s", (user_id,))
        user_data = cursor.fetchone()
        cursor.close()
        db.close()
        
        if user_data:
            return User(user_data['id'], user_data['username'], user_data['email'], user_data['role'])
    except Exception as e:
        logging.error(f"Error loading user: {e}")
    return None

# --- DB Connection Helper ---
def get_db():
    return psycopg2.connect(DATABASE_URL, cursor_factory=psycopg2.extras.RealDictCursor)

# --- Admin Required Decorator ---
def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated or not current_user.is_admin():
            flash('You need admin privileges to access this page.', 'error')
            return redirect(url_for('dashboard'))
        return f(*args, **kwargs)
    return decorated_function

# --- Improved DB Initialization Logic ---
def init_db():
    print("⏳ Starting database initialization...")

    try:
        db = get_db()
        cursor = db.cursor()
        
        # Create users table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                username VARCHAR(80) UNIQUE NOT NULL,
                email VARCHAR(120) UNIQUE NOT NULL,
                password_hash VARCHAR(256) NOT NULL,
                role VARCHAR(10) DEFAULT 'user' CHECK (role IN ('user', 'admin')),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Create expenses table with user_id foreign key
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS expenses (
                id SERIAL PRIMARY KEY,
                user_id INTEGER NOT NULL,
                date DATE,
                details TEXT,
                cat1 DECIMAL(10,2) DEFAULT 0,
                cat2 DECIMAL(10,2) DEFAULT 0,
                cat3 DECIMAL(10,2) DEFAULT 0,
                cat4 DECIMAL(10,2) DEFAULT 0,
                cat5 DECIMAL(10,2) DEFAULT 0,
                remarks TEXT,
                income DECIMAL(10,2) DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            )
        """)
        
        db.commit()
        cursor.close()
        db.close()
        print("✅ Tables 'users' and 'expenses' are ready.")

    except psycopg2.Error as err:
        print("❌ PostgreSQL error during init_db():")
        print(err)
    except Exception as e:
        print("❌ Unexpected error during init_db():")
        traceback.print_exc()

# Always run init on load
init_db()

# -----------------------------
# Helpers for password reset
# -----------------------------
def generate_reset_token(user_id: int) -> str:
    return serializer.dumps({"uid": user_id})

def verify_reset_token(token: str, max_age: int = 3600) -> int:
    data = serializer.loads(token, max_age=max_age)
    return int(data["uid"])

def _render(template_name, fallback_html=None, **ctx):
    """Try to render template; if missing, serve a minimal fallback form."""
    try:
        return render_template(template_name, **ctx)
    except TemplateNotFound:
        if fallback_html is not None:
            return fallback_html.format(**ctx)
        raise

# --- Authentication Routes ---
@app.route("/")
def index():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    return render_template('index.html')

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        username = request.form.get('username')
        email = request.form.get('email')
        password = request.form.get('password')
        confirm_password = request.form.get('confirm_password')
        
        # Validation
        if not username or not email or not password:
            flash('All fields are required.', 'error')
            return render_template('register.html')
        
        if password != confirm_password:
            flash('Passwords do not match.', 'error')
            return render_template('register.html')
        
        if len(password) < 6:
            flash('Password must be at least 6 characters long.', 'error')
            return render_template('register.html')
        
        try:
            db = get_db()
            cursor = db.cursor()
            
            # Check if user already exists
            cursor.execute("SELECT id FROM users WHERE username = %s OR email = %s", (username, email))
            if cursor.fetchone():
                flash('Username or email already exists.', 'error')
                cursor.close()
                db.close()
                return render_template('register.html')
            
            # Create new user
            password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
            cursor.execute(
                "INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s) RETURNING id",
                (username, email, password_hash)
            )
            result = cursor.fetchone()
            if result:
                user_id = result[0] if isinstance(result, tuple) else result['id']
            else:
                raise Exception("Failed to create user")
            db.commit()
            cursor.close()
            db.close()
            
            # Log in the new user
            user = User(user_id, username, email)
            login_user(user)
            flash('Registration successful! Welcome to Expense Tracker.', 'success')
            return redirect(url_for('dashboard'))
            
        except Exception as e:
            flash('An error occurred during registration. Please try again.', 'error')
            logging.error(f"Registration error: {e}")
            return render_template('register.html')
    
    return render_template('register.html')

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get('username')
        password = request.form.get('password')
        
        if not username or not password:
            flash('Username and password are required.', 'error')
            return render_template('login.html')
        
        try:
            db = get_db()
            cursor = db.cursor()
            cursor.execute(
                "SELECT id, username, email, password_hash, role FROM users WHERE username = %s OR email = %s",
                (username, username)
            )
            user_data = cursor.fetchone()
            cursor.close()
            db.close()
            
            if user_data and bcrypt.check_password_hash(user_data['password_hash'], password):
                user = User(user_data['id'], user_data['username'], user_data['email'], user_data['role'])
                login_user(user)
                flash(f'Welcome back, {user.username}!', 'success')
                
                # Redirect to admin dashboard if admin, otherwise regular dashboard
                if user.is_admin():
                    return redirect(url_for('admin_dashboard'))
                return redirect(url_for('dashboard'))
            else:
                flash('Invalid username or password.', 'error')
                
        except Exception as e:
            flash('An error occurred during login. Please try again.', 'error')
            logging.error(f"Login error: {e}")
    
    return render_template('login.html')

@app.route("/logout")
@login_required
def logout():
    logout_user()
    flash('You have been logged out.', 'info')
    return redirect(url_for('index'))

# --- Create/Promote Admin (protected with ADMIN_SETUP_TOKEN) ---
@app.route("/setup/create-admin", methods=["POST"])
def setup_create_admin():
    # Accept JSON or form
    if request.is_json:
        data = request.get_json(silent=True) or {}
    else:
        data = request.form.to_dict()

    setup_token = (data.get("setup_token") or "").strip()
    if not ADMIN_SETUP_TOKEN or setup_token != ADMIN_SETUP_TOKEN:
        return jsonify({"error": "Forbidden"}), 403

    username = (data.get("username") or "").strip()
    email = (data.get("email") or "").strip()
    password = data.get("password") or ""

    if not username or not email or not password:
        return jsonify({"error": "username, email, password are required"}), 400

    try:
        db = get_db()
        cursor = db.cursor()
        pw_hash = bcrypt.generate_password_hash(password).decode("utf-8")
        cursor.execute("""
            INSERT INTO users (username, email, password_hash, role)
            VALUES (%s, %s, %s, 'admin')
            ON CONFLICT (username) DO UPDATE
                SET email = EXCLUDED.email,
                    password_hash = EXCLUDED.password_hash,
                    role = 'admin'
            RETURNING id
        """, (username, email, pw_hash))
        user_id = cursor.fetchone()["id"]
        db.commit()
        cursor.close(); db.close()
        return jsonify({"message": "Admin ensured", "user_id": user_id, "username": username}), 200
    except Exception as e:
        logging.error(f"Create admin error: {e}")
        return jsonify({"error": "failed to create admin"}), 500

# --- Forgot Password (request a reset link) ---
@app.route("/forgot-password", methods=["GET", "POST"])
def forgot_password():
    if request.method == "GET":
        return _render("forgot_password.html", fallback_html="""
            <h2>Forgot Password</h2>
            <form method="post">
              <label>Email</label>
              <input type="email" name="email" required />
              <button type="submit">Send reset link</button>
            </form>
        """)

    email = (request.form.get("email") or "").strip()
    if not email:
        flash("Email is required.", "error")
        return _render("forgot_password.html")

    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
        row = cursor.fetchone()
        cursor.close(); db.close()

        # Always show generic message; log the link if user exists
        if row:
            uid = row["id"] if isinstance(row, dict) else row[0]
            token = generate_reset_token(uid)
            reset_link = url_for("reset_password", token=token, _external=True)
            logging.info(f"[PasswordReset] Link for {email}: {reset_link}")

        flash("If that email exists, a reset link has been sent.", "info")
        return redirect(url_for("login"))
    except Exception as e:
        logging.error(f"Forgot password error: {e}")
        flash("Error processing request. Try again.", "error")
        return _render("forgot_password.html")

# --- Reset Password (follow link) ---
@app.route("/reset-password/<token>", methods=["GET", "POST"])
def reset_password(token):
    if request.method == "GET":
        return _render("reset_password.html", fallback_html="""
            <h2>Reset Password</h2>
            <form method="post">
              <input type="hidden" name="token" value="{token}">
              <label>New password</label>
              <input type="password" name="password" required minlength="6" />
              <label>Confirm password</label>
              <input type="password" name="confirm_password" required minlength="6" />
              <button type="submit">Update password</button>
            </form>
        """, token=token)

    password = request.form.get("password") or ""
    confirm  = request.form.get("confirm_password") or ""
    if not password or password != confirm:
        flash("Passwords must match and not be empty.", "error")
        return _render("reset_password.html", token=token)

    try:
        user_id = verify_reset_token(token, max_age=3600)  # 1 hour
    except SignatureExpired:
        flash("Reset link expired. Please request a new one.", "error")
        return redirect(url_for("forgot_password"))
    except BadSignature:
        flash("Invalid reset link.", "error")
        return redirect(url_for("forgot_password"))

    try:
        db = get_db()
        cursor = db.cursor()
        pw_hash = bcrypt.generate_password_hash(password).decode("utf-8")
        cursor.execute("UPDATE users SET password_hash = %s WHERE id = %s", (pw_hash, user_id))
        db.commit()
        cursor.close(); db.close()
        flash("Password updated. Please log in.", "success")
        return redirect(url_for("login"))
    except Exception as e:
        logging.error(f"Reset password error: {e}")
        flash("Could not update password. Try again.", "error")
        return _render("reset_password.html", token=token)

# --- Dashboard Routes ---
@app.route("/dashboard")
@login_required
def dashboard():
    return render_template('dashboard.html', user=current_user)

@app.route("/admin")
@login_required
@admin_required
def admin_dashboard():
    try:
        db = get_db()
        cursor = db.cursor()
        
        # Get all users
        cursor.execute("SELECT id, username, email, role, created_at FROM users ORDER BY created_at DESC")
        users = cursor.fetchall()
        
        # Get expense summary by user
        cursor.execute("""
            SELECT u.username, COUNT(e.id) as expense_count, 
                   COALESCE(SUM(e.cat1 + e.cat2 + e.cat3 + e.cat4 + e.cat5), 0) as total_expenses,
                   COALESCE(SUM(e.income), 0) as total_income
            FROM users u 
            LEFT JOIN expenses e ON u.id = e.user_id 
            GROUP BY u.id, u.username
            ORDER BY total_expenses DESC
        """)
        user_summaries = cursor.fetchall()
        
        cursor.close()
        db.close()
        
        return render_template('admin_dashboard.html', users=users, user_summaries=user_summaries)
        
    except Exception as e:
        flash('Error loading admin dashboard.', 'error')
        logging.error(f"Admin dashboard error: {e}")
        return redirect(url_for('dashboard'))

# --- API Routes (Modified for User Isolation) ---
@app.route("/api/expense", methods=["POST"])
@login_required
def add_expense():
    data = request.get_json()
    required_fields = ['date', 'details']
    if not all(field in data and data[field] is not None for field in required_fields):
        return jsonify({"error": "Missing required expense fields"}), 400

    sql = (
        "INSERT INTO expenses (user_id, date, details, cat1, cat2, cat3, cat4, cat5, remarks, income) "
        "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
    )
    values = (
        current_user.id,  # Add user_id to associate expense with current user
        data['date'],
        data['details'],
        data.get('cat1', 0),
        data.get('cat2', 0),
        data.get('cat3', 0),
        data.get('cat4', 0),
        data.get('cat5', 0),
        data.get('remarks', ''),
        data.get('income', 0)
    )

    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute(sql, values)
        db.commit()
        cursor.close()
        db.close()
        return jsonify({"message": "Expense added successfully"}), 200
    except Exception as err:
        logging.error(f"Add expense error: {err}")
        return jsonify({"error": str(err)}), 500

@app.route("/api/expense", methods=["GET"])
@login_required
def get_expenses():
    try:
        db = get_db()
        cursor = db.cursor()
        
        # If admin, get all expenses, otherwise get only user's expenses
        if current_user.is_admin():
            cursor.execute("""
                SELECT e.date, e.details, e.cat1, e.cat2, e.cat3, e.cat4, e.cat5, e.remarks, e.income, u.username
                FROM expenses e 
                JOIN users u ON e.user_id = u.id 
                ORDER BY e.date DESC
            """)
            include_username = True
        else:
            cursor.execute(
                "SELECT date, details, cat1, cat2, cat3, cat4, cat5, remarks, income "
                "FROM expenses WHERE user_id = %s ORDER BY date DESC",
                (current_user.id,)
            )
            include_username = False
            
        rows = cursor.fetchall()
        cursor.close()
        db.close()

        expenses = []
        for row in rows:
            expense = {
                "date": row['date'].strftime("%Y-%m-%d") if hasattr(row['date'], 'strftime') else str(row['date']),
                "details": row['details'],
                "cat1": float(row['cat1']),
                "cat2": float(row['cat2']),
                "cat3": float(row['cat3']),
                "cat4": float(row['cat4']),
                "cat5": float(row['cat5']),
                "remarks": row['remarks'],
                "income": float(row['income'])
            }
            if include_username:
                expense["username"] = row['username']
            expenses.append(expense)

        return jsonify(expenses), 200
    except Exception as err:
        logging.error(f"Get expenses error: {err}")
        return jsonify({"error": str(err)}), 500

# --- Health Check ---
@app.route("/health", methods=["GET"])
def health():
    try:
        db = get_db()
        db.close()
        return jsonify({"status": "ok"}), 200
    except Exception as e:
        return jsonify({"status": "error", "error": str(e)}), 500

# Legacy routes for backward compatibility
@app.route("/expense", methods=["POST", "GET"])
@login_required
def expense_legacy():
    if request.method == "POST":
        return add_expense()
    else:
        return get_expenses()

if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)