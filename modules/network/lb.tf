############################################
# Application Load Balancer (public)
############################################
# ALB itself
resource "aws_lb" "alb" {
  name               = coalesce(var.lb_name, "${var.vpc_name}-alb")
  load_balancer_type = "application"

  # SG created in network/sg.tf
  security_groups = [aws_security_group.alb_sg.id]

  # Public subnets from the upstream VPC module
  subnets = module.vpc.public_subnets

  enable_deletion_protection = var.alb_deletion_protection
}

# Target Group (instance targets by default)
resource "aws_lb_target_group" "app" {
  name                 = coalesce(var.target_group_name, "${var.vpc_name}-tg")
  vpc_id               = module.vpc.vpc_id
  target_type          = var.tg_target_type
  port                 = var.tg_port
  protocol             = var.tg_protocol
  deregistration_delay = var.tg_deregistration_delay

  health_check {
    enabled             = true
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
  }

}

# HTTP listener (optional)
resource "aws_lb_listener" "http" {
  count             = var.alb_http_enabled ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# HTTPS listener (optional)
resource "aws_lb_listener" "https" {
  count             = var.alb_https_enabled ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

