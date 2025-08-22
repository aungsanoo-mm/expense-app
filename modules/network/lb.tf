############################################
# Application Load Balancer (public)
############################################
####################################################
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

# HTTP listener
resource "aws_lb_listener" "http" {
  count             = var.http_redirect_to_https ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# HTTPS listener 
resource "aws_lb_listener" "https" {
  count             = var.http_redirect_to_https ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = aws_acm_certificate.aungsanoo_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}




# Get Route53 Zone
data "aws_route53_zone" "selected" {
  name         = "aungsanoo.org."
  private_zone = false
}

# Create ACM Certificate
resource "aws_acm_certificate" "aungsanoo_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  tags = {
    Name = "aungsanoo-ssl-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create Route53 validation records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.aungsanoo_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = "Z00089162HOKS08BTX6Z2"
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}


# Wait for certificate validation
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.aungsanoo_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  depends_on = [aws_route53_record.cert_validation]
}

# # HTTP to HTTPS Redirect
# resource "aws_lb_listener" "http_redirect" {
#   load_balancer_arn = aws_lb.alb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type = "redirect"
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }