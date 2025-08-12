locals {
  ssh_user         = "ubuntu"
  private_key_path = "expenseapp.pem"
  key_name         = "expenseapp"

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