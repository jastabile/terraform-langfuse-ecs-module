module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.13.0"

  name        = "${var.name}-aurora"
  engine      = "aurora-postgresql"
  engine_mode = "provisioned"

  engine_version = "16.6"
  instance_class = "db.serverless"

  vpc_id               = local.vpc_id
  db_subnet_group_name = local.database_subnet_group_name

  enable_http_endpoint = true
  database_name        = var.postgres_db
  master_username      = var.postgres_user

  instances = {
    for i in range(var.postgres_instance_count) :
    "instance-${i + 1}" => {
      publicly_accessible = true
    }
  }

  enabled_cloudwatch_logs_exports = ["postgresql"]


  db_cluster_parameter_group_parameters = [
    {
      name  = "rds.force_ssl"
      value = 1
    }
  ]

  vpc_security_group_ids = [aws_security_group.postgres.id]

  serverlessv2_scaling_configuration = {
    min_capacity = var.postgres_min_capacity
    max_capacity = var.postgres_max_capacity
  }

  storage_encrypted = true

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  monitoring_interval    = 30
  create_monitoring_role = true

  skip_final_snapshot = true

  tags = {
    Name = "${var.name}-aurora"
  }

  deletion_protection     = false
  publicly_accessible     = true
  backup_retention_period = 35

  depends_on = [
    aws_cloudwatch_log_group.database_logs
  ]
}

resource "aws_cloudwatch_log_group" "database_logs" {
  name              = "${var.name}-database/postgresql"
  retention_in_days = 14
}

resource "aws_security_group" "postgres" {
  name        = "${var.name}-postgres"
  description = "Security group for Langfuse PostgreSQL"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr_block]
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
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
    Name = "${var.name}-postgres"
  }
}


resource "null_resource" "create_postgres_user" {
  triggers = {
    cluster_identifier = module.aurora.cluster_id
    database_name      = var.postgres_db
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Create user
      aws rds-data execute-statement \
        --resource-arn ${module.aurora.cluster_arn} \
        --secret-arn ${module.aurora.cluster_master_user_secret[0].secret_arn} \
        --sql "CREATE USER ${var.postgres_user}_app WITH PASSWORD '${random_password.postgres_password.result}';" \
        --database ${var.postgres_db}

      # Grant default privileges on tables
      aws rds-data execute-statement \
        --resource-arn ${module.aurora.cluster_arn} \
        --secret-arn ${module.aurora.cluster_master_user_secret[0].secret_arn} \
        --sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${var.postgres_user}_app;" \
        --database ${var.postgres_db}

      # Grant default privileges on sequences
      aws rds-data execute-statement \
        --resource-arn ${module.aurora.cluster_arn} \
        --secret-arn ${module.aurora.cluster_master_user_secret[0].secret_arn} \
        --sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO ${var.postgres_user}_app;" \
        --database ${var.postgres_db}

      # Grant default privileges on functions
      aws rds-data execute-statement \
        --resource-arn ${module.aurora.cluster_arn} \
        --secret-arn ${module.aurora.cluster_master_user_secret[0].secret_arn} \
        --sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO ${var.postgres_user}_app;" \
        --database ${var.postgres_db}

      # Grant database connection
      aws rds-data execute-statement \
        --resource-arn ${module.aurora.cluster_arn} \
        --secret-arn ${module.aurora.cluster_master_user_secret[0].secret_arn} \
        --sql "GRANT CONNECT ON DATABASE ${var.postgres_db} TO ${var.postgres_user}_app;" \
        --database ${var.postgres_db}

      # Grant table permissions
      aws rds-data execute-statement \
        --resource-arn ${module.aurora.cluster_arn} \
        --secret-arn ${module.aurora.cluster_master_user_secret[0].secret_arn} \
        --sql "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${var.postgres_user}_app;" \
        --database ${var.postgres_db}

      # Grant schema usage and creation
      aws rds-data execute-statement \
        --resource-arn ${module.aurora.cluster_arn} \
        --secret-arn ${module.aurora.cluster_master_user_secret[0].secret_arn} \
        --sql "GRANT USAGE, CREATE ON SCHEMA public TO ${var.postgres_user}_app;" \
        --database ${var.postgres_db}

      # Grant sequence usage
      aws rds-data execute-statement \
        --resource-arn ${module.aurora.cluster_arn} \
        --secret-arn ${module.aurora.cluster_master_user_secret[0].secret_arn} \
        --sql "GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO ${var.postgres_user}_app;" \
        --database ${var.postgres_db}

      # Grant function execution
      aws rds-data execute-statement \
        --resource-arn ${module.aurora.cluster_arn} \
        --secret-arn ${module.aurora.cluster_master_user_secret[0].secret_arn} \
        --sql "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO ${var.postgres_user}_app;" \
        --database ${var.postgres_db}
    EOT
  }

  depends_on = [
    module.aurora
  ]
}
