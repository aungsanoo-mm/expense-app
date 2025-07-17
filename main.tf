terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_instance" "expense_app" {
  ami           = "ami-0b8607d2721c94a77"  # Ubuntu 22.04
  instance_type = "t2.micro"
  key_name      = "expenseapp"             # Replace with your actual key pair

    user_data = <<-EOF
            #!/bin/bash
            exec > >(tee /var/log/user-data.log) 2>&1
            set -e

            # Update packages
            apt-get update -y

            # Install Nginx, Git, MySQL Server, Python, pip
            DEBIAN_FRONTEND=noninteractive apt-get install -y nginx git mysql-server python3-pip python3-venv python3

            # Enable and start Nginx
            systemctl enable nginx
            systemctl start nginx

            # Start MySQL and wait until ready
            systemctl start mysql
            until mysqladmin ping &>/dev/null; do
            echo "Waiting for MySQL to be ready..."
            sleep 5
            done

            # Setup DB, user, and permissions
            mysql -u root -e "CREATE DATABASE IF NOT EXISTS expenses_db;"
            mysql -u root -e "CREATE USER IF NOT EXISTS 'exp_user'@'localhost' IDENTIFIED BY 'StrongPassword123!';"
            mysql -u root -e "GRANT ALL PRIVILEGES ON expenses_db.* TO 'exp_user'@'localhost';"
            mysql -u root -e "FLUSH PRIVILEGES;"

            # Create expenses table
            mysql -u root <<EOL
            USE expenses_db;
            CREATE TABLE IF NOT EXISTS expenses (
            id INT AUTO_INCREMENT PRIMARY KEY,
            date DATE,
            details TEXT,
            cat1 FLOAT,
            cat2 FLOAT,
            cat3 FLOAT,
            cat4 FLOAT,
            cat5 FLOAT,
            remarks TEXT,
            income FLOAT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            EOL

            # Log table status
            mysql -u root -e "SHOW TABLES IN expenses_db;" >> /var/log/mysql-init.log

            # Setup project
            mkdir -p /var/www/html/expense-tracker
            git clone https://github.com/aungsanoo-mm/expense-app.git /var/www/html/expense-tracker
            chown -R www-data:www-data /var/www/html/expense-tracker
            sudo cp -r /var/www/html/expense-tracker/expense.service /etc/systemd/system/
            # Install Python dependencies
            sudo pip3 install -r /var/www/html/expense-tracker/requirements.txt
            sudo pip3 install gunicorn
            # Configure Gunicorn service
            systemctl daemon-reload
            systemctl enable expense.service
            systemctl start expense.service
            EOF

  tags = {
    Name = "ExpenseApp"
  }

  vpc_security_group_ids = [aws_security_group.expense_sg.id]
}

resource "aws_security_group" "expense_sg" {
  name        = "expense-sg"
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # HTTP
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Optional Flask API
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
