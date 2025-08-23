#Create VPC

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name                    = var.vpc_name
  cidr                    = var.vpc_cidr
  azs                     = var.azs
  public_subnets          = var.public_subnets
  private_subnets         = var.private_subnets
  enable_nat_gateway      = var.enable_nat_gateway
  single_nat_gateway      = var.single_nat_gateway
  enable_dns_hostnames    = var.enable_dns_hostnames
  enable_dns_support      = var.enable_dns_support
  map_public_ip_on_launch = var.map_public_ip_on_launch

  # Uniform tags for all subnets/route tables
  public_subnet_tags = {
    Tier = "public"
    Name = "${var.vpc_name}-public-subnets"
  }
  private_subnet_tags = {
    Tier = "private"
    Name = "${var.vpc_name}-private-subnets"
  }
  public_route_table_tags = {
    Scope = "public"
    Name  = "${var.vpc_name}-public-rt"
  }
  private_route_table_tags = {
    Scope = "private"
    Name  = "${var.vpc_name}-private-rt"
  }
  nat_gateway_tags = {
    Name = "${var.vpc_name}-nat-gw"
  }
  igw_tags = {
    Name = "${var.vpc_name}-igw"
  }

}


