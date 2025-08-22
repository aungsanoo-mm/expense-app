data "aws_elb_hosted_zone_id" "main" {}
resource "aws_route53_record" "expense_tracker_alias" {
  zone_id = var.zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = data.aws_elb_hosted_zone_id.main.id
    evaluate_target_health = var.evaluate_target_health
  }
}