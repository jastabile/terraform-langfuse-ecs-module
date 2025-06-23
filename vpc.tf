locals {
  vpc_cidr_block          = "10.200.0.0/16"
  vpc_azs                 = ["us-east-2a", "us-east-2b", "us-east-2c"]
  vpc_public_subnets      = ["10.200.10.0/24", "10.200.11.0/24"]
  vpc_private_subnets     = ["10.200.20.0/24", "10.200.21.0/24"]
  vpc_database_subnets    = ["10.200.22.0/24", "10.200.23.0/24"]
  vpc_domain_name_servers = ["AmazonProvidedDNS"]
  region                  = "us-east-2"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1.2"
  name    = "myvpc"
  cidr    = local.vpc_cidr_block

  azs              = local.vpc_azs
  public_subnets   = local.vpc_public_subnets
  private_subnets  = local.vpc_private_subnets
  database_subnets = local.vpc_database_subnets

  enable_dns_hostnames             = true
  enable_dns_support               = true
  enable_dhcp_options              = true
  dhcp_options_domain_name         = "${local.region}.compute.internal"
  dhcp_options_domain_name_servers = local.vpc_domain_name_servers

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}
