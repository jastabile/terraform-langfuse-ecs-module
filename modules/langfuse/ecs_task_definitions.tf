resource "aws_ecs_task_definition" "clickhouse" {
  family                   = "${var.name}-clickhouse"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 4096
  execution_role_arn       = aws_iam_role.TaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecs_task_role_clickhouse.arn

  container_definitions = jsonencode([
    {
      name      = "clickhouse"
      image     = "582760239244.dkr.ecr.us-east-2.amazonaws.com/clickhouse-server:25.5"
      essential = true
      user      = "101:101"

      secrets = [
        {
          name      = "CLICKHOUSE_USER"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:CLICKHOUSE_USER::"
        },
        {
          name      = "CLICKHOUSE_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:CLICKHOUSE_PASSWORD::"
        }
      ]

      environment = [
        {
          name  = "CLICKHOUSE_DB"
          value = "${var.clickhouse_db}"
        },
        {
          name  = "CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT"
          value = "1"
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "clickhouse-data"
          containerPath = "/var/lib/clickhouse"
          readOnly      = false
        },
        {
          sourceVolume  = "clickhouse-logs"
          containerPath = "/var/log/clickhouse-server"
          readOnly      = false
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:8123/ping || exit 1"]
        interval    = 5
        timeout     = 5
        retries     = 10
        startPeriod = 1
      }

      portMappings = [
        {
          containerPort = 8123
          hostPort      = 8123
          protocol      = "tcp"
        },
        {
          containerPort = 9000
          hostPort      = 9000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.name}/clickhouse"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "clickhouse"
        }
      }
    }
  ])

  volume {
    name = "clickhouse-data"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.langfuse.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.clickhouse.id
        iam             = "ENABLED"
      }
    }
  }

  volume {
    name = "clickhouse-logs"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.langfuse.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.clickhouse_logs.id
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_task_definition" "langfuse_worker" {
  family                   = "${var.name}-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.TaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecs_task_role_langfuse.arn

  container_definitions = jsonencode([
    {
      name      = "langfuse-worker"
      image     = "582760239244.dkr.ecr.us-east-2.amazonaws.com/langfuse-worker:3.66"
      essential = true

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:DATABASE_URL::"
        },
        {
          name      = "SALT"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:SALT::"
        },
        {
          name      = "ENCRYPTION_KEY"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:ENCRYPTION_KEY::"
        },
        {
          name      = "CLICKHOUSE_USER"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:CLICKHOUSE_USER::"
        },
        {
          name      = "CLICKHOUSE_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:CLICKHOUSE_PASSWORD::"
        },
        {
          name      = "LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:LANGFUSE_S3_ACCESS_KEY_ID::"
        },
        {
          name      = "LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:LANGFUSE_S3_SECRET_ACCESS_KEY::"
        },
        {
          name      = "LANGFUSE_S3_MEDIA_UPLOAD_ACCESS_KEY_ID"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:LANGFUSE_S3_ACCESS_KEY_ID::"
        },
        {
          name      = "LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:LANGFUSE_S3_SECRET_ACCESS_KEY::"
        },
        {
          name      = "LANGFUSE_S3_BATCH_EXPORT_ACCESS_KEY_ID"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:LANGFUSE_S3_ACCESS_KEY_ID::"
        },
        {
          name      = "LANGFUSE_S3_BATCH_EXPORT_SECRET_ACCESS_KEY"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:LANGFUSE_S3_SECRET_ACCESS_KEY::"
        },
        {
          name      = "AUTH_GOOGLE_CLIENT_ID"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:AUTH_GOOGLE_CLIENT_ID::"
        },
        {
          name      = "AUTH_GOOGLE_CLIENT_SECRET"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:AUTH_GOOGLE_CLIENT_SECRET::"
        }
      ]

      environment = [
        {
          name  = "AUTH_DISABLE_USERNAME_PASSWORD"
          value = tostring(var.auth_disable_username_password)
        },
        {
          name  = "TELEMETRY_ENABLED"
          value = "true"
        },
        {
          name  = "LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES"
          value = "true"
        },
        {
          name  = "CLICKHOUSE_MIGRATION_URL"
          value = "clickhouse://clickhouse.${var.name}.local:9000"
        },
        {
          name  = "CLICKHOUSE_URL"
          value = "http://clickhouse.${var.name}.local:8123"
        },
        {
          name  = "CLICKHOUSE_CLUSTER_ENABLED"
          value = "false" # TODO: Must check if it's easy to enable.
        },
        {
          name  = "LANGFUSE_S3_EVENT_UPLOAD_BUCKET"
          value = aws_s3_bucket.langfuse.id
        },
        {
          name  = "LANGFUSE_S3_EVENT_UPLOAD_REGION"
          value = var.region
        },
        {
          name  = "LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT"
          value = "https://s3.${var.region}.amazonaws.com"
        },
        {
          name  = "LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE"
          value = "true"
        },
        {
          name  = "LANGFUSE_S3_EVENT_UPLOAD_PREFIX"
          value = "events/"
        },
        {
          name  = "LANGFUSE_S3_MEDIA_UPLOAD_BUCKET"
          value = aws_s3_bucket.langfuse.id
        },
        {
          name  = "LANGFUSE_S3_MEDIA_UPLOAD_REGION"
          value = var.region
        },
        {
          name  = "LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT"
          value = "https://s3.${var.region}.amazonaws.com"
        },
        {
          name  = "LANGFUSE_S3_MEDIA_UPLOAD_FORCE_PATH_STYLE"
          value = "true"
        },
        {
          name  = "LANGFUSE_S3_MEDIA_UPLOAD_PREFIX"
          value = "media/"
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_ENABLED"
          value = "false"
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_BUCKET"
          value = aws_s3_bucket.langfuse.id
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_PREFIX"
          value = "exports/"
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_REGION"
          value = var.region
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_ENDPOINT"
          value = "https://s3.${var.region}.amazonaws.com"
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_EXTERNAL_ENDPOINT"
          value = "https://s3.${var.region}.amazonaws.com"
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_FORCE_PATH_STYLE"
          value = "true"
        },
        {
          name  = "LANGFUSE_INGESTION_QUEUE_DELAY_MS"
          value = ""
        },
        {
          name  = "LANGFUSE_INGESTION_CLICKHOUSE_WRITE_INTERVAL_MS"
          value = ""
        },
        {
          name  = "REDIS_HOST"
          value = aws_elasticache_replication_group.redis.primary_endpoint_address
        },
        {
          name  = "REDIS_PORT"
          value = "6379"
        },
        {
          name  = "REDIS_TLS_ENABLED"
          value = "false"
        },
        {
          name  = "REDIS_TLS_CA"
          value = ""
        },
        {
          name  = "REDIS_TLS_CERT"
          value = ""
        },
        {
          name  = "REDIS_TLS_KEY"
          value = ""
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://$HOSTNAME:3030/ || exit 1"]
        interval    = 5
        timeout     = 5
        retries     = 10
        startPeriod = 1
      }

      portMappings = [
        {
          containerPort = 3030
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.name}/worker"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "worker"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "langfuse_web" {
  family                   = "${var.name}-web"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.TaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecs_task_role_langfuse.arn

  container_definitions = jsonencode([
    {
      name      = "langfuse-web"
      image     = "582760239244.dkr.ecr.us-east-2.amazonaws.com/langfuse:3.66"
      essential = true

      secrets = [
        {
          name      = "NEXTAUTH_SECRET"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:NEXTAUTH_SECRET::"
        },
        {
          name      = "DATABASE_URL"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:DATABASE_URL::"
        },
        {
          name      = "SALT"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:SALT::"
        },
        {
          name      = "ENCRYPTION_KEY"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:ENCRYPTION_KEY::"
        },
        {
          name      = "CLICKHOUSE_USER"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:CLICKHOUSE_USER::"
        },
        {
          name      = "CLICKHOUSE_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:CLICKHOUSE_PASSWORD::"
        },
        {
          name      = "LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:LANGFUSE_S3_ACCESS_KEY_ID::"
        },
        {
          name      = "LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:LANGFUSE_S3_SECRET_ACCESS_KEY::"
        },
        {
          name      = "LANGFUSE_S3_MEDIA_UPLOAD_ACCESS_KEY_ID"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:LANGFUSE_S3_ACCESS_KEY_ID::"
        },
        {
          name      = "LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:LANGFUSE_S3_SECRET_ACCESS_KEY::"
        },
        {
          name      = "LANGFUSE_S3_BATCH_EXPORT_ACCESS_KEY_ID"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:LANGFUSE_S3_ACCESS_KEY_ID::"
        },
        {
          name      = "LANGFUSE_S3_BATCH_EXPORT_SECRET_ACCESS_KEY"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:LANGFUSE_S3_SECRET_ACCESS_KEY::"
        },
        {
          name      = "AUTH_GOOGLE_CLIENT_ID"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:AUTH_GOOGLE_CLIENT_ID::"
        },
        {
          name      = "AUTH_GOOGLE_CLIENT_SECRET"
          valueFrom = "${aws_secretsmanager_secret.langfuse.arn}:AUTH_GOOGLE_CLIENT_SECRET::"
        }
      ]
      environment = [
        {
          name  = "AUTH_DISABLE_USERNAME_PASSWORD"
          value = tostring(var.auth_disable_username_password)
        },
        {
          name  = "NEXTAUTH_URL"
          value = "https://${var.name}.${var.domain}"
        },
        {
          name  = "LANGFUSE_INIT_ORG_ID"
          value = var.langfuse_init_org_id
        },
        {
          name  = "LANGFUSE_INIT_ORG_NAME"
          value = var.langfuse_init_org_name
        },
        {
          name  = "LANGFUSE_INIT_PROJECT_ID"
          value = var.langfuse_init_project_id
        },
        {
          name  = "LANGFUSE_INIT_PROJECT_NAME"
          value = var.langfuse_init_project_name
        },
        {
          name  = "LANGFUSE_INIT_PROJECT_PUBLIC_KEY"
          value = var.langfuse_init_project_public_key
        },
        {
          name  = "LANGFUSE_INIT_PROJECT_SECRET_KEY"
          value = var.langfuse_init_project_secret_key
        },
        {
          name  = "LANGFUSE_INIT_USER_EMAIL"
          value = var.langfuse_init_user_email
        },
        {
          name  = "LANGFUSE_INIT_USER_NAME"
          value = var.langfuse_init_user_name
        },
        {
          name  = "LANGFUSE_INIT_USER_PASSWORD"
          value = var.langfuse_init_user_password
        },
        {
          name  = "TELEMETRY_ENABLED"
          value = "true"
        },
        {
          name  = "LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES"
          value = "true"
        },
        {
          name  = "CLICKHOUSE_MIGRATION_URL"
          value = "clickhouse://clickhouse.${var.name}.local:9000"
        },
        {
          name  = "CLICKHOUSE_URL"
          value = "http://clickhouse.${var.name}.local:8123"
        },
        {
          name  = "CLICKHOUSE_CLUSTER_ENABLED"
          value = "false"
        },
        {
          name  = "LANGFUSE_S3_EVENT_UPLOAD_BUCKET"
          value = aws_s3_bucket.langfuse.id
        },
        {
          name  = "LANGFUSE_S3_EVENT_UPLOAD_REGION"
          value = var.region
        },
        {
          name  = "LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT"
          value = "https://s3.${var.region}.amazonaws.com"
        },
        {
          name  = "LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE"
          value = "true"
        },
        {
          name  = "LANGFUSE_S3_EVENT_UPLOAD_PREFIX"
          value = "events/"
        },
        {
          name  = "LANGFUSE_S3_MEDIA_UPLOAD_BUCKET"
          value = aws_s3_bucket.langfuse.id
        },
        {
          name  = "LANGFUSE_S3_MEDIA_UPLOAD_REGION"
          value = var.region
        },
        {
          name  = "LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT"
          value = "https://s3.${var.region}.amazonaws.com"
        },
        {
          name  = "LANGFUSE_S3_MEDIA_UPLOAD_FORCE_PATH_STYLE"
          value = "true"
        },
        {
          name  = "LANGFUSE_S3_MEDIA_UPLOAD_PREFIX"
          value = "media/"
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_ENABLED"
          value = "false"
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_BUCKET"
          value = aws_s3_bucket.langfuse.id
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_PREFIX"
          value = "exports/"
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_REGION"
          value = var.region
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_ENDPOINT"
          value = "https://s3.${var.region}.amazonaws.com"
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_EXTERNAL_ENDPOINT"
          value = "https://s3.${var.region}.amazonaws.com"
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_FORCE_PATH_STYLE"
          value = "true"
        },
        {
          name  = "LANGFUSE_INGESTION_QUEUE_DELAY_MS"
          value = ""
        },
        {
          name  = "LANGFUSE_INGESTION_CLICKHOUSE_WRITE_INTERVAL_MS"
          value = ""
        },
        {
          name  = "REDIS_HOST"
          value = aws_elasticache_replication_group.redis.primary_endpoint_address
        },
        {
          name  = "REDIS_PORT"
          value = "6379"
        },
        {
          name  = "REDIS_TLS_ENABLED"
          value = "false"
        },
        {
          name  = "REDIS_TLS_CA"
          value = ""
        },
        {
          name  = "REDIS_TLS_CERT"
          value = ""
        },
        {
          name  = "REDIS_TLS_KEY"
          value = ""
        }
      ]

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.name}/web"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "web"
        }
      }
    }
  ])
}

