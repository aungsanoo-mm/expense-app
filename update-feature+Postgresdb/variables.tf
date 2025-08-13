locals {
  ssh_user         = "ubuntu"
  private_key_path = "expenseapp.pem"
  key_name         = "expenseapp"
  public_subnets   = ["subnet-0ef3c8767c2cc76a4"]
  
}
variable "db_username" {
  default = "exp_user"
}
variable "db_password" {
  default = "StrongPassword123!"

}
variable "db_name" {
  default = "expenses_db"
  
}
variable "db_port" {
  default = 5432
  
}
variable "vpc_id" {
  description = "The VPC ID where resources will be deployed."
  type        = string
  default     = "vpc-0d3360c0d0d44198b"

}
variable "public_subnets" {
  description = "List of public subnet IDs for the load balancer."
  type        = list(string)
  default     = ["subnet-0ef3c8767c2cc76a4","subnet-08dc7aa620486831d","subnet-061478a0a17988005"]
}