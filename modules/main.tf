##################################
# Root Main.tf
##################################
# VPC Module
module "network" {
  source = "./network"

  vpc_name                = var.vpc_name
  vpc_cidr                = var.vpc_cidr
  azs                     = var.azs
  public_subnets          = var.public_subnets
  private_subnets         = var.private_subnets
  enable_nat_gateway      = var.enable_nat_gateway
  single_nat_gateway      = var.single_nat_gateway
  enable_dns_hostnames    = var.enable_dns_hostnames
  enable_dns_support      = var.enable_dns_support
  map_public_ip_on_launch = var.map_public_ip_on_launch
  # db_subnet_group_name    = var.aws_db_subnet_group.database.name
  # ALB inputs passed to the child module
  lb_name                 = coalesce(var.lb_name, "${var.vpc_name}-alb")
  alb_internal            = var.alb_internal
  alb_deletion_protection = var.alb_deletion_protection
  

  alb_http_enabled        = var.alb_http_enabled
  alb_https_enabled       = var.alb_https_enabled
  certificate_arn         = var.certificate_arn
  ssl_policy              = var.ssl_policy
  tg_target_type          = var.tg_target_type
  tg_port                 = var.tg_port
  tg_protocol             = var.tg_protocol
  health_check_path       = var.health_check_path
  tg_deregistration_delay = var.tg_deregistration_delay

}
############################################################
# Route53 Module
module "route53" {
  source = "./route53"

  zone_id                = "Z00089162HOKS08BTX6Z2"
  record_name            = "expense-tracker.aungsanoo.org"
  alb_dns_name           = module.network.alb_dns_name
  alb_zone_id            = module.network.alb_zone_id
  evaluate_target_health = true

}
##########################################################
# Compute Module
module "compute" {
  source = "./compute"
  #DB inputs
  rds_endpoint =       module.DB.rds_endpoint
  db_port               =  module.DB.db_port
  db_address            =  module.DB.db_address
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  # db_port                 = var.db_port

  # Network inputs
  vpc_name           = var.vpc_name
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  # Security group inputs
  bastion_sg_id  = module.network.bastion_sg_id
  # webapp_b_sg_id = module.network.webapp_b_sg_id
  webapp_a_sg_id = module.network.webapp_a_sg_id
  # # SSH configuration
  ssh_key_name = var.ssh_key_name
  depends_on = [ module.DB ]
  #Auto scalling group inputs
  target_group_arn = module.network.target_group_arn
}
#########################################################
# RDS Module
module "DB" {
  source                  = "./DB"
  vpc_name                = var.vpc_name
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  db_port                 = var.db_port
  db_allocated_storage    = var.db_allocated_storage
  db_engine               = var.db_engine
  db_engine_version       = var.db_engine_version
  db_instance_class       = var.db_instance_class
  db_multi_az             = var.db_multi_az
  db_parameter_group_name = var.db_parameter_group_name
  private_subnet_ids      = module.network.private_subnet_ids
  vpc_id                 = module.network.vpc_id
  # Pass the security group ID for the RDS instance
  db_sg_id = module.network.db_sg_id
}