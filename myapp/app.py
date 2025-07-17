from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector

app = Flask(__name__)
CORS(app)

# 🔁 Utility function to get a fresh DB connection
def get_db():
    return mysql.connector.connect(
        host="localhost",
        user="exp_user",
        password="StrongPassword123!",
        database="expenses_db"
    )

# ✅ API: Health Check
@app.route("/", methods=["GET"])
def health_check():
    return "✅ Flask API is up and running!"

# 📝 API: Add New Expense
@app.route("/expense", methods=["POST"])
def add_expense():
    data = request.get_json()
    required_fields = ['date', 'details', 'cat1', 'cat2', 'cat3', 'cat4', 'cat5']

    if not all(field in data and data[field] is not None for field in required_fields):
        return jsonify({"error": "Missing required expense fields"}), 400

    sql = """
        INSERT INTO expenses (date, details, cat1, cat2, cat3, cat4, cat5, remarks, income)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    values = (
        data['date'],
        data['details'],
        data['cat1'],
        data['cat2'],
        data['cat3'],
        data['cat4'],
        data['cat5'],
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
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500

# 📦 API: Retrieve All Expenses
@app.route("/expense", methods=["GET"])
def get_expenses():
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute("""
            SELECT date, details, cat1, cat2, cat3, cat4, cat5, remarks, income
            FROM expenses ORDER BY date DESC
        """)
        rows = cursor.fetchall()
        cursor.close()
        db.close()

        expenses = []
        for row in rows:
            expenses.append({
                "date": row[0].strftime("%Y-%m-%d"),
                "details": row[1],
                "cat1": float(row[2]),
                "cat2": float(row[3]),
                "cat3": float(row[4]),
                "cat4": float(row[5]),
                "cat5": float(row[6]),
                "remarks": row[7],
                "income": float(row[8])
            })
        return jsonify(expenses), 200

    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500

# 🏁 Start Server
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)

