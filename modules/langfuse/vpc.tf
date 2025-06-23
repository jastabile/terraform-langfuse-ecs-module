data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # VPC and subnet IDs to use
  vpc_id                     = var.use_existing_vpc ? var.existing_vpc_id : module.vpc.vpc_id
  private_subnets            = var.use_existing_vpc ? var.existing_private_subnets : module.vpc.private_subnets
  public_subnets             = var.use_existing_vpc ? var.existing_public_subnets : module.vpc.public_subnets
  database_subnets           = var.use_existing_vpc ? var.existing_database_subnets : module.vpc.database_subnets
  database_subnet_group_name = var.use_existing_vpc ? var.existing_database_subnet_group_name : module.vpc.database_subnet_group_name
  private_route_table_ids    = var.use_existing_vpc ? [] : module.vpc.private_route_table_ids
  vpc_cidr_block             = var.use_existing_vpc ? data.aws_vpc.existing[0].cidr_block : module.vpc.vpc_cidr_block
}

# Get existing VPC data if using existing VPC
data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
  id    = var.existing_vpc_id
}

module "vpc" {
  count   = var.use_existing_vpc ? 0 : 1
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]

  enable_nat_gateway     = true
  single_nat_gateway     = !var.use_single_nat_gateway
  one_nat_gateway_per_az = var.use_single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  tags = {
    Name = "${var.name}-vpc"
  }
}

# VPC Endpoints for AWS services
resource "aws_vpc_endpoint" "sts" {
  vpc_id             = local.vpc_id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = local.private_subnets
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = {
    Name = "${var.name} STS VPC Endpoint"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = local.private_route_table_ids

  tags = {
    Name = "${var.name} S3 VPC Endpoint"
  }
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.name}-vpc-endpoints"
  description = "Security group for VPC endpoints"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr_block]
  }

  tags = {
    Name = "${var.name} VPC Endpoints"
  }
}

# Security group for ECS services
resource "aws_security_group" "ecs_security_group" {
  name        = "${var.name}-ecs-sg"
  description = "Security group for ECS services"
  vpc_id      = local.vpc_id

  # Allow inbound traffic from ALB
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow inbound traffic from ALB to web service"
  }

  ingress {
    from_port       = 3030
    to_port         = 3030
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow inbound traffic from ALB to worker service"
  }

  # Allow ClickHouse ports
  ingress {
    from_port   = 8123
    to_port     = 8123
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr_block]
    description = "Allow ClickHouse HTTP interface"
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr_block]
    description = "Allow ClickHouse native interface"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.name} ECS Security Group"
  }
}

# Security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "${var.name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = local.vpc_id

  # Allow inbound HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic"
  }

  # Allow inbound HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.name} ALB Security Group"
  }
}
