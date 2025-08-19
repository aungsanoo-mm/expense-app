# --- Security Groups (inside the network module) ---

########################
# Bastion (public)
########################
resource "aws_security_group" "bastion_sg" {
  name        = "${var.vpc_name}-bastion-sg"
  description = "Bastion host security group"
  vpc_id      = module.vpc.vpc_id

  # outbound: all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.vpc_name}-bastion-sg" }
}

# inbound: SSH from anywhere (adjust to your office IP range in prod)
resource "aws_security_group_rule" "bastion_ssh_in" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion_sg.id
  from_port         = var.ssh_port
  to_port           = var.ssh_port
  protocol          = "tcp"
  cidr_blocks       = var.bastion_ssh_cidrs
}

########################
# ALB (public)
########################
resource "aws_security_group" "alb_sg" {
  name        = "${var.vpc_name}-alb-sg"
  description = "ALB security group"
  vpc_id      = module.vpc.vpc_id

  # outbound: all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.vpc_name}-alb-sg" }
}

# inbound: HTTP/HTTPS from anywhere (public LB)
resource "aws_security_group_rule" "alb_http_in" {
  type              = "ingress"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "alb_https_in" {
  type              = "ingress"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

########################
# Webapp A (private)
########################
resource "aws_security_group" "webapp_a_sg" {
  name        = "${var.vpc_name}-webapp-a-sg"
  description = "Webapp A security group (private)"
  vpc_id      = module.vpc.vpc_id

  # outbound: all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.vpc_name}-webapp-a-sg" }
}

# SSH from bastion only
resource "aws_security_group_rule" "webapp_a_ssh_from_bastion" {
  type                     = "ingress"
  security_group_id        = aws_security_group.webapp_a_sg.id
  from_port                = var.ssh_port
  to_port                  = var.ssh_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
}

# HTTP from ALB only
resource "aws_security_group_rule" "webapp_a_http_from_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.webapp_a_sg.id
  from_port                = var.web_port
  to_port                  = var.web_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
}

########################
# Webapp B (private)
########################
resource "aws_security_group" "webapp_b_sg" {
  name        = "${var.vpc_name}-webapp-b-sg"
  description = "Webapp B security group (private)"
  vpc_id      = module.vpc.vpc_id

  # outbound: all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.vpc_name}-webapp-b-sg" }
}

# SSH from bastion only
resource "aws_security_group_rule" "webapp_b_ssh_from_bastion" {
  type                     = "ingress"
  security_group_id        = aws_security_group.webapp_b_sg.id
  from_port                = var.ssh_port
  to_port                  = var.ssh_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
}

# HTTP from ALB only
resource "aws_security_group_rule" "webapp_b_http_from_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.webapp_b_sg.id
  from_port                = var.web_port
  to_port                  = var.web_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
}

########################
# Database (private)
########################
resource "aws_security_group" "db_sg" {
  name        = "${var.vpc_name}-db-sg"
  description = "DB security group (PostgreSQL)"
  vpc_id      = module.vpc.vpc_id

  # outbound: all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.vpc_name}-db-sg" }
}

# DB 5432 only from Webapp A
resource "aws_security_group_rule" "db_from_webapp_a" {
  type                     = "ingress"
  security_group_id        = aws_security_group.db_sg.id
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.webapp_a_sg.id
}

# DB 5432 only from Webapp B
resource "aws_security_group_rule" "db_from_webapp_b" {
  type                     = "ingress"
  security_group_id        = aws_security_group.db_sg.id
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.webapp_b_sg.id
}
