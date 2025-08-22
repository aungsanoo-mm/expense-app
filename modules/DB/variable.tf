variable "db_name" {
  description = "The name of the database to create"
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
variable "db_sg_id" {
  description = "Security group ID for the RDS instance"
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
variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}
variable "private_subnet_ids" {
  description = "List of private subnet IDs for the RDS instance"
  type        = list(string)
}
variable "vpc_id" {
  description = "The ID of the VPC where the RDS instance will be created"
  type        = string
  
}