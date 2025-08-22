###Output for VPC and Subnets
output "vpc_name" { value = module.vpc.name }
output "vpc_id" { value = module.vpc.vpc_id }
output "public_subnet_ids" { value = module.vpc.public_subnets }
output "private_subnet_ids" { value = module.vpc.private_subnets }
###################################################################
###Output for Security Groups
output "alb_sg_id" { value = aws_security_group.alb_sg.id }
output "bastion_sg_id" { value = aws_security_group.bastion_sg.id }
output "webapp_a_sg_id" { value = aws_security_group.webapp_a_sg.id }
# output "webapp_b_sg_id" { value = aws_security_group.webapp_b_sg.id }
output "db_sg_id" { value = aws_security_group.db_sg.id }
############################################################
#Output for ALB information
output "alb_arn" { value = aws_lb.alb.arn }
output "alb_dns_name" { value = aws_lb.alb.dns_name }
output "alb_zone_id" { value = aws_lb.alb.zone_id }
output "target_group_arn" { value = aws_lb_target_group.app.arn }
output "target_group_arn_suffix" { value = aws_lb_target_group.app.arn_suffix }
