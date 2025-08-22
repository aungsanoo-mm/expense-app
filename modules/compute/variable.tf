variable "vpc_name" {
  description = "CIDR block for the VPC"
  type        = string
}
variable "public_subnet_ids" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}
variable "private_subnet_ids" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}
variable "bastion_sg_id" {
  type = string
}
variable "webapp_a_sg_id" {
  type = string
}

# variable "webapp_b_sg_id" {
#   type = string
# }
variable "ssh_key_name" {
  description = "Name of the SSH key pair to use for instances"
  sensitive = true
  type        = string
}
variable "db_name" {
  description = "The name of the database to create"
  sensitive = true
  type        = string
  
}
variable "db_password" {
  description = "value of the database password"
  sensitive = true
  type        = string
  
}

variable "db_username" {
  description = "value of the database username"
  sensitive = true
  type        = string  
  
}

# variable "db_port" {
#   description = "The port on which the database accepts connections"
#   type        = number
# }
variable "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  type        = string
  default     = null
  
}
variable "target_group_arn" {
  description = "The ARN of the target group for the ALB"
  type        = string
}
variable "db_address" {
  description = "The RDS instance for the expense tracker application"
  type        = string
  default     = null
}
variable "db_port" {
  description = "The port for the RDS instance"
  type        = number
  default     = null
  
}