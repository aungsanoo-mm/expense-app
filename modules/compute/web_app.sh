#!/bin/bash

# Install script for Expense Tracker Web Server
set -e  # Exit on any error

# Variables (these should be passed as environment variables or via Terraform)
POSTGRES_HOST=${postgres_host}
POSTGRES_PORT=${postgres_port}
POSTGRES_USER=${postgres_user}
POSTGRES_PASSWORD=${postgres_password}
POSTGRES_DB=${postgres_db}

# Update and install packages
echo "Cleaning apt cache and updating packages..."
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get update -y
apt-get install -y nginx git python3 python3-pip python3-venv libpq-dev python3-dev supervisor

# Enable and start Nginx
echo "Starting Nginx..."
systemctl enable nginx
systemctl start nginx

# Clone the repository
echo "Cloning expense tracker repository..."
git clone https://github.com/aungsanoo-mm/expense-app.git /var/www/html/expense-tracker

# Copy specific files and directories
echo "Copying application files..."
cd /var/www/html/expense-tracker
git checkout update-feature+Postgresdb  # Ensure we're on the right branch

# Copy required files to main directory
cp update-feature+Postgresdb/app.py .
cp update-feature+Postgresdb/expense-tracker.service .
cp update-feature+Postgresdb/requirements.txt .

# Copy templates and static directories
cp -r update-feature+Postgresdb/templates/ .
cp -r update-feature+Postgresdb/static/ .

# Set permissions
echo "Setting permissions..."
chown -R www-data:www-data /var/www/html/expense-tracker

# Copy service file
echo "Setting up systemd service..."
cp /var/www/html/expense-tracker/expense-tracker.service /etc/systemd/system/
chmod 644 /etc/systemd/system/expense-tracker.service
# Create and configure Nginx
echo "Configuring Nginx..."
cat >/etc/nginx/sites-available/expense-nginx <<'EOF'
server {
    listen 80;
    server_name _;

    location /health {
        return 200 'ok';
        add_header Content-Type text/plain;
    }

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /var/www/html/expense-tracker/static/;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/expense-nginx /etc/nginx/sites-enabled/

# Remove default Nginx configurations
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

# Update nginx.conf to use our config
sed -i 's|include /etc/nginx/sites-enabled/\*;|include /etc/nginx/sites-enabled/expense-nginx;|' /etc/nginx/nginx.conf

# Create .env file for database connection
echo "Creating environment file..."
cat > /var/www/html/expense-tracker/.env << EOF
POSTGRES_HOST=$POSTGRES_HOST
POSTGRES_PORT=$POSTGRES_PORT
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=$POSTGRES_DB
EOF

chmod 644 /var/www/html/expense-tracker/.env

# Create virtual environment
echo "Setting up Python virtual environment..."
python3 -m venv /var/www/html/expense-tracker/venv

# Install Python dependencies
echo "Installing Python dependencies..."
/var/www/html/expense-tracker/venv/bin/pip install -r /var/www/html/expense-tracker/requirements.txt

# Create systemd override directory
echo "Configuring systemd overrides..."
mkdir -p /etc/systemd/system/expense-tracker.service.d

# Create systemd override for environment file
cat > /etc/systemd/system/expense-tracker.service.d/override.conf << 'EOF'
[Service]
EnvironmentFile=/var/www/html/expense-tracker/.env
EOF

# Reload systemd and start the service
echo "Starting application service..."
systemctl daemon-reload
systemctl enable expense-tracker.service
systemctl start expense-tracker.service

# Restart Nginx to apply changes
echo "Restarting Nginx..."
systemctl restart nginx

echo "Installation completed successfully!"