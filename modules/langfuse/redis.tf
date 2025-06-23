resource "aws_security_group" "redis" {
  name        = "${var.name}-redis"
  description = "Security group for Langfuse Redis"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-redis"
  }
}

resource "aws_elasticache_parameter_group" "redis" {
  family = "redis7"
  name   = "${var.name}-redis-params"

  parameter {
    name  = "maxmemory-policy"
    value = "noeviction"
  }
}

resource "aws_cloudwatch_log_group" "redis" {
  name              = "/redis/${var.name}"
  retention_in_days = 7
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.name}-redis-subnet-group"
  subnet_ids = local.database_subnets
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = var.name
  description                = "Redis cluster for Langfuse"
  node_type                  = var.cache_node_type
  port                       = 6379
  parameter_group_name       = aws_elasticache_parameter_group.redis.name
  automatic_failover_enabled = var.cache_instance_count > 1 ? true : false
  num_cache_clusters         = var.cache_instance_count
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  engine                     = "redis"
  engine_version             = "7.0"

  transit_encryption_enabled = false

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  tags = {
    Name = "${var.name}-redis"
  }
}
