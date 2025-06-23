# General variables
variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = "langfuse"
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "enable_execute_command" {
  description = "Whether to enable ECS Exec for the services"
  type        = bool
  default     = false
}

# VPC and Network variables
variable "use_existing_vpc" {
  description = "Whether to use an existing VPC or create a new one"
  type        = bool
  default     = false
}

variable "vpc_cidr" {
  description = "CIDR block for VPC. Required only when use_existing_vpc is false"
  type        = string
  default     = null
}

variable "use_single_nat_gateway" {
  description = "To use a single NAT Gateway (cheaper), or one per AZ (more resilient). Required only when use_existing_vpc is false"
  type        = bool
  default     = null
}

variable "existing_vpc_id" {
  description = "The ID of the existing VPC to use when use_existing_vpc is true"
  type        = string
  default     = ""
}

variable "existing_private_subnets" {
  description = "List of existing private subnet IDs to use when use_existing_vpc is true"
  type        = list(string)
  default     = []
}

variable "existing_public_subnets" {
  description = "List of existing public subnet IDs to use when use_existing_vpc is true"
  type        = list(string)
  default     = []
}

variable "existing_database_subnets" {
  description = "List of existing database subnet IDs to use when use_existing_vpc is true"
  type        = list(string)
  default     = []
}

variable "existing_database_subnet_group_name" {
  description = "The name of the existing database subnet group to use when use_existing_vpc is true"
  type        = string
  default     = ""
}

# Route53 and Domain variables
variable "domain" {
  description = "Domain name used for resource naming (e.g., company.com)"
  type        = string
}

variable "use_existing_hosted_zone" {
  description = "Whether to use an existing Route53 hosted zone or create a new one"
  type        = bool
  default     = false
}

variable "existing_zone_id" {
  description = "The ID of the existing Route53 hosted zone to use when use_existing_hosted_zone is true"
  type        = string
  default     = ""
}

variable "cert_arn" {
  description = "The ARN of the existing ACM certificate to use when use_existing_hosted_zone is true"
  type        = string
  default     = ""
}

variable "postgres_instance_count" {
  description = "Number of PostgreSQL instances to create"
  type        = number
  default     = 2 # Default to 2 instances for high availability
}

variable "postgres_min_capacity" {
  description = "Minimum ACU capacity for PostgreSQL Serverless v2"
  type        = number
  default     = 0.5
}

variable "postgres_max_capacity" {
  description = "Maximum ACU capacity for PostgreSQL Serverless v2"
  type        = number
  default     = 2.0 # Higher default for production readiness
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
}

# Redis (ElastiCache) variables
variable "cache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.small"
}

variable "cache_instance_count" {
  description = "Number of ElastiCache instances used in the cluster"
  type        = number
  default     = 2
}

# ClickHouse variables
variable "clickhouse_instance_count" {
  description = "Number of ClickHouse instances used in the cluster"
  type        = number
  default     = 3
}

variable "clickhouse_user" {
  description = "Clickhouse username"
  type        = string
}

variable "clickhouse_db" {
  description = "Clickhouse database name"
  type        = string
}

variable "clickhouse_cluster_enabled" {
  description = "Whether to enable ClickHouse cluster"
  type        = bool
  default     = false
}

# S3 variables
variable "s3_bucket_name" {
  description = "S3 bucket name for Langfuse"
  type        = string
}

# variable "s3_access_key" {
#   description = "S3 access key"
#   type        = string
#   sensitive   = true
# }

# variable "s3_secret_key" {
#   description = "S3 secret key"
#   type        = string
#   sensitive   = true
# }

# variable "s3_endpoint" {
#   description = "S3 endpoint URL"
#   type        = string
# }

# Langfuse application variables
# variable "langfuse_salt" {
#   description = "Salt for Langfuse"
#   type        = string
# }

# variable "nextauth_url" {
#   description = "NextAuth URL"
#   type        = string
# }

# variable "nextauth_secret" {
#   description = "NextAuth secret"
#   type        = string
#   sensitive   = true
# }

# Langfuse initialization variables
variable "langfuse_init_org_id" {
  description = "Initial organization ID for Langfuse"
  type        = string
  default     = ""
}

variable "langfuse_init_org_name" {
  description = "Initial organization name for Langfuse"
  type        = string
  default     = ""
}

variable "langfuse_init_project_id" {
  description = "Initial project ID for Langfuse"
  type        = string
  default     = ""
}

variable "langfuse_init_project_name" {
  description = "Initial project name for Langfuse"
  type        = string
  default     = ""
}

variable "langfuse_init_project_public_key" {
  description = "Initial project public key for Langfuse"
  type        = string
  default     = ""
}

variable "langfuse_init_project_secret_key" {
  description = "Initial project secret key for Langfuse"
  type        = string
  default     = ""
}

variable "langfuse_init_user_email" {
  description = "Initial user email for Langfuse"
  type        = string
  default     = ""
}

variable "langfuse_init_user_name" {
  description = "Initial user name for Langfuse"
  type        = string
  default     = ""
}

variable "langfuse_init_user_password" {
  description = "Initial user password for Langfuse"
  type        = string
  default     = ""
  sensitive   = true
}

# Bastion host variables
variable "deploy_bastion" {
  description = "Whether to create a bastion host"
  type        = bool
  default     = false
}

variable "bastion_allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to the bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Default to allow all, should be restricted in production
}

variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.nano"
}

variable "bastion_key_name" {
  description = "Name of the SSH key pair to use for the bastion host"
  type        = string
}

variable "auth_disable_username_password" {
  description = "Whether to disable username/password authentication"
  type        = bool
  default     = true
}

variable "alerts_recipient_emails" {
  description = "List of email addresses to send alerts to"
  type        = list(string)
  default     = []
}
