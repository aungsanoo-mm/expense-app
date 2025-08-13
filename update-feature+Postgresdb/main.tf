terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0"
    }
  }
}


# --- RDS Security Group ---
resource "aws_security_group" "rds_postgres" {
  name        = "rds-postgres-sg"
  description = "Allow Postgres from EC2 only" 

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.expense_demo.id]
  }
}
resource "aws_security_group" "lb_security_group" {
  name        = "lb-security-group"
  description = "Allow HTTP and HTTPS traffic to the load balancer"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress  {
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


# --- RDS Postgres Instance ---
resource "aws_db_instance" "expense_rds" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "11.22-rds.20240418"
  instance_class         = "db.t3.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.postgres11"
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = true
  vpc_security_group_ids = [aws_security_group.rds_postgres.id]
}

# --- Output RDS Endpoint ---
output "rds_endpoint" {
  value = aws_db_instance.expense_rds.endpoint
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_instance" "expense_app" {
  count         = 2
  ami           = "ami-0b8607d2721c94a77" # Ubuntu 22.04
  instance_type = "t2.micro"
  key_name      = local.key_name
  tags = {
    Name = "Webapp"
  }
  vpc_security_group_ids = [aws_security_group.expense_demo.id]

  provisioner "remote-exec" {
    inline = ["echo 'echo ssh for ready' "]
    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(local.private_key_path)
      host        = self.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${self.public_ip},' --private-key ${local.private_key_path} webserver.yaml -e 'postgres_host=${replace(aws_db_instance.expense_rds.endpoint, ":5432", "")} postgres_port=${var.db_port} postgres_user=${var.db_username} postgres_password=${var.db_password} postgres_db=${var.db_name}'"
  }
}

resource "aws_lb" "expense_lb" {
  name               = "expense-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.lb_security_group.id]
}

resource "aws_lb_target_group" "expense_tg" {
  name     = "expense-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path = "/health"
  }
}

resource "aws_lb_target_group_attachment" "expense_tg_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.expense_tg.arn
  target_id        = aws_instance.expense_app[count.index].id
  port             = 80
}

resource "aws_lb_listener" "expense_listener" {
  load_balancer_arn = aws_lb.expense_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.expense_tg.arn
  }
}

resource "aws_security_group" "expense_demo" {
  name        = "expense-demo"
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
