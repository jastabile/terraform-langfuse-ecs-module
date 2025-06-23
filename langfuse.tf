locals {
  domain = "mydomain.com"
}

module "langfuse" {
  source = "./modules/langfuse"

  enable_execute_command = true

  name   = "langfuse"
  region = "us-east-2"

  use_existing_vpc                    = true
  existing_vpc_id                     = module.vpc.vpc_id
  existing_private_subnets            = module.vpc.private_subnets
  existing_public_subnets             = module.vpc.public_subnets
  existing_database_subnets           = module.vpc.database_subnets
  existing_database_subnet_group_name = module.vpc.database_subnet_group_name

  domain                   = local.domain # will create a subdomain langfuse.${domain} and worker.${domain}
  use_existing_hosted_zone = true
  existing_zone_id         = data.aws_route53_zone.domain.zone_id
  cert_arn                 = data.aws_acm_certificate.primary.arn

  postgres_instance_count = 1
  postgres_min_capacity   = 0.5
  postgres_max_capacity   = 2.0
  postgres_user           = "postgres"
  postgres_db             = "langfuse"

  cache_node_type      = "cache.t4g.small"
  cache_instance_count = 1

  clickhouse_instance_count  = 1
  clickhouse_user            = "clickhouse-app"
  clickhouse_cluster_enabled = false
  clickhouse_db              = "default"

  s3_bucket_name = "mybucket-langfuse"

  deploy_bastion   = true
  bastion_key_name = "deployer-common"

  auth_disable_username_password = true
}

data "aws_route53_zone" "domain" {
  name = local.domain
}

data "aws_acm_certificate" "primary" {
  domain = local.domain
}
