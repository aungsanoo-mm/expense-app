variable "zone_id" {
  description = "Hosted Zone ID (preferred). If null, set zone_name and we will look it up."
  type        = string
  default     = null
}

variable "zone_name" {
  description = "Hosted Zone name (used only when zone_id is null), e.g. aungsanoo.org"
  type        = string
  default     = null
}

variable "record_name" {
  description = "Record to create, e.g. expense-tracker.aungsanoo.org"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name from network module output"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID from network module output"
  type        = string
}

variable "evaluate_target_health" {
  type    = bool
  default = true
}

variable "create_aaaa_record" {
  description = "Also create AAAA alias for IPv6"
  type        = bool
  default     = false
}
