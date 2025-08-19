#####################################################
#VPC settings
variable "vpc_name" { type = string }
variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }

variable "enable_nat_gateway" { type = bool }
variable "single_nat_gateway" { type = bool }
variable "enable_dns_hostnames" { type = bool }
variable "enable_dns_support" { type = bool }
variable "map_public_ip_on_launch" { type = bool }
#########################################################
# ALB settings

variable "lb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = null
}

variable "target_group_name" {
  description = "Name of the target group"
  type        = string
  default     = null

}
variable "alb_internal" {
  description = "Set to true for internal ALB, false for public ALB"
  type        = bool
  default     = false

}
variable "alb_deletion_protection" {
  description = "Enable deletion protection for the ALB"
  type        = bool
  default     = false
}

# Listeners
variable "alb_http_enabled" {
  description = "Enable HTTP listener"
  type        = bool
  default     = true

}
variable "alb_https_enabled" {
  description = "Enable HTTPS listener"
  type        = bool
  default     = false

}
variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS listener"
  type        = string
  default     = null

}
variable "ssl_policy" {
  description = "SSL policy for the ALB"
  type        = string
  default     = "ELBSecurityPolicy-2016-08"

}

# Target group
variable "tg_target_type" {
  description = "Target type for the target group (instance or ip)"
  type        = string
  default     = "instance"

}
variable "tg_port" {
  description = "Port for the target group"
  type        = number
  default     = 80

}
variable "tg_protocol" {
  description = "Protocol for the target group"
  type        = string
  default     = "HTTP"

}
variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/"

}
variable "tg_deregistration_delay" {
  description = "Deregistration delay for the target group"
  type        = number
  default     = 10

}
#########################################################
#Security Group Variables
variable "ssh_port" {
  description = "SSH port"
  type        = number
  default     = 22
}

variable "web_port" {
  description = "Application HTTP port"
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "bastion_ssh_cidrs" {
  description = "CIDRs allowed to SSH to bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"] # tighten to your office IP(s) in prod
}
##############################################################  