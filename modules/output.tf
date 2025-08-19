output "vpc_id" { value = module.network.vpc_id }
output "public_subnets" { value = module.network.public_subnet_ids }
output "private_subnets" { value = module.network.private_subnet_ids }
output "zone_id" { value = module.route53.zone_id }

