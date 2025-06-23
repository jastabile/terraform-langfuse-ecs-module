# Langfuse Terraform Module

This Terraform module deploys a complete Langfuse stack on AWS using ECS (Elastic Container Service) with Fargate. Langfuse is an open-source LLM observability and analytics platform that helps you monitor, debug, and improve your LLM applications.

## Requisites after apply
After applying the Terraform configuration, follow these steps:

1. Wait for the ClickHouse container to be running and healthy:
   - Go to the AWS Console
   - Navigate to ECS > Clusters > langfuse
   - Click on the "clickhouse" service
   - Under "Tasks", wait for the task to show "RUNNING" status
   - Wait a few more minutes to ensure ClickHouse has fully initialized

2. Once ClickHouse is healthy, scale up the web service:
   - Stay in the same ECS cluster
   - Click on the "web" service
   - Click "Update"
   - Set "Desired tasks" to 1
   - Click "Update" to apply



## Known Limitations

- ClickHouse server is currently limited to running a single task at a time. Scaling requires stopping existing tasks before deploying new ones.
- The `clickhouse_cluster_enabled` feature has not been tested.
- Redis is currently deployed without password authentication. This should be improved for production environments by implementing proper authentication.

## Features

- Deploys Langfuse on AWS ECS Fargate with all necessary components
- Flexible VPC configuration (use existing or create new)
- Aurora PostgreSQL database with RDS Data API integration
- Redis caching layer using ElastiCache
- ClickHouse for analytics (Note: Currently limited to single task deployment, scaling requires task replacement)
- S3 storage for file uploads
- Application Load Balancer with HTTPS support
- Automatic DNS configuration with Route53
- IAM roles and security groups
- EFS for persistent storage
- CloudWatch logging


## Prerequisites

- AWS account and credentials configured
- Terraform 1.0.0 or newer
- Domain name for the application (if using Route53)

## Usage

```hcl
module "langfuse" {
  source = "path/to/module"

  # Required variables
  region    = "us-east-1"
  domain    = "your-domain.com"
  
  # Database configuration
  postgres_user = "langfuse"
  postgres_db   = "langfuse"
  
  # S3 configuration
  s3_bucket_name = "your-langfuse-bucket"
  
  # Optional: Use existing VPC
  use_existing_vpc = true
  existing_vpc_id  = "vpc-xxxxxx"
  existing_private_subnets = ["subnet-xxxxxx", "subnet-yyyyyy"]
  existing_public_subnets  = ["subnet-zzzzzz", "subnet-wwwwww"]
  
  # Optional: Initial setup
  langfuse_init_user_email    = "admin@example.com"
  langfuse_init_user_name     = "Admin"
  langfuse_init_user_password = "secure-password"
}
```

## Architecture

The module creates the following AWS resources:

1. **Networking**
   - VPC (optional, can use existing)
   - Public and private subnets
   - NAT Gateways
   - Security groups

2. **Database**
   - Aurora PostgreSQL cluster
   - Automatic user creation using RDS Data API
   - Database subnet group

3. **Caching**
   - ElastiCache Redis cluster
   - Redis security group

4. **Storage**
   - S3 bucket for file storage
   - EFS for persistent storage

5. **Compute**
   - ECS cluster with Fargate launch type
   - ECS services for Langfuse components running on Fargate
   - Task definitions optimized for Fargate
   - IAM roles and policies
   - Custom ECR repository containing copies of:
     - clickhouse/clickhouse
     - langfuse/langfuse-worker
     - langfuse/langfuse-web

6. **Networking & Security**
   - Application Load Balancer
   - ACM certificate
   - Route53 records
   - Security groups

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for resources | `string` | `"langfuse"` | no |
| region | AWS region where resources will be created | `string` | n/a | yes |
| domain | Domain name used for resource naming | `string` | n/a | yes |
| use_existing_vpc | Whether to use an existing VPC | `bool` | `false` | no |
| postgres_user | PostgreSQL username | `string` | n/a | yes |
| postgres_db | PostgreSQL database name | `string` | n/a | yes |
| s3_bucket_name | S3 bucket name for Langfuse | `string` | n/a | yes |

For a complete list of variables, see the `variables.tf` file.

## Outputs

| Name | Description |
|------|-------------|
| alb_dns_name | DNS name of the load balancer |
| rds_endpoint | Endpoint of the RDS instance |
| redis_endpoint | Endpoint of the Redis cluster |
| s3_bucket_name | Name of the S3 bucket |

## Security

- All sensitive data is stored in AWS Secrets Manager
- Database credentials are managed securely
- HTTPS is enforced for all traffic
- Security groups are configured with least privilege access
- IAM roles follow the principle of least privilege

## Maintenance

- The module uses Aurora Serverless v2 for the database, which automatically scales based on demand
- Redis cluster is configured for high availability
- ECS services are configured with auto-scaling capabilities and run on Fargate for serverless container execution
- CloudWatch logs are enabled for all services
- Fargate tasks automatically scale based on CPU and memory utilization
