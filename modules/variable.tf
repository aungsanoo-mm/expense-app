#VPC settings and region
########################################################## 
variable "aws_region" {
  description = "AWS region for the VPC"
  type        = string
  default     = "ap-southeast-1"
}
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
# Route53 settings
variable "zone_name" {
  description = "Name of the Route53 zone"
  type        = string
  default     = null
}
variable "zone_id" {
  description = "ID of the Route53 zone"
  type        = string
  default     = null
}
variable "record_name" {
  description = "Name of the Route53 record"
  type        = string
  default     = null
}
variable "evaluate_target_health" {
  description = "Evaluate target health for the Route53 record"
  type        = bool
  default     = true
}
################################################
# Compute settings
variable "ssh_key_name" {
  description = "Name of the SSH key pair to use for instances"
  type        = string
}

#########################################################
#DB settings
variable "db_name" {
  description = "The name of the database to create"
  type        = string
}
variable "db_password" {
  description = "value of the database password"
  type        = string
}
variable "db_username" {
  description = "value of the database username"
  type        = string
}

variable "db_port" {
  description = "The port on which the database accepts connections"
  type        = number
}
variable "db_engine" {
  description = "The database engine to use"
  type        = string

}
variable "db_engine_version" {
  description = "The version of the database engine to use"
  type        = string

}
variable "db_instance_class" {
  description = "The instance class for the RDS instance"
  type        = string

}
variable "db_multi_az" {
  description = "Whether to create a Multi-AZ deployment"
  type        = bool
}
variable "db_parameter_group_name" {
  description = "The name of the DB parameter group to associate with the RDS instance"
  type        = string
}
variable "db_allocated_storage" {
  description = "The amount of storage (in GB) to allocate for the RDS instance"
  type        = number
}