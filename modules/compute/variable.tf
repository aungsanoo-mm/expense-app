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

variable "webapp_b_sg_id" {
  type = string
}
variable "ssh_key_name" {
  description = "Name of the SSH key pair to use for instances"
  type        = string
}