# --- Output RDS Endpoint ---
output "rds_endpoint" {
  value = aws_db_instance.expense_rds.endpoint
}
output "db_subnet_group_name" {
  value = aws_db_subnet_group.database.name

}
