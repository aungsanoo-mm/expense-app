# --- RDS Postgres Instance ---
resource "aws_db_instance" "expense_rds" {
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = var.db_parameter_group_name
  skip_final_snapshot  = true
  publicly_accessible  = false
  multi_az             = var.db_multi_az
  port                 = var.db_port
  # db_subnet_group_name   = [aws_db_subnet_group.database.name]
  vpc_security_group_ids = [var.db_sg_id]
}

resource "aws_db_subnet_group" "database" {
  name       = "db-subnet-group"
  subnet_ids = [var.private_subnet_ids[0], var.private_subnet_ids[1]]

  tags = {
    Name = "db-subnet-group"
  }
}