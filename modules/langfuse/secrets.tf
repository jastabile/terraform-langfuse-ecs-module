# Generate random passwords
resource "random_password" "langfuse_encryption_key" {
  length  = 64
  special = true
  upper   = true
  lower   = true
  numeric = true
}

resource "random_password" "postgres_password" {
  length      = 64
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

resource "random_password" "clickhouse_password" {
  length           = 16
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!-"
}

resource "random_password" "langfuse_salt" {
  length      = 64
  special     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

resource "random_password" "nextauth_secret" {
  length      = 64
  special     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

resource "random_integer" "secret_number" {
  min = 1
  max = 500
}

# Create AWS Secrets Manager secret
resource "aws_secretsmanager_secret" "langfuse" {
  name        = "${var.name}-secrets-${random_integer.secret_number.result}"
  description = "Secrets for Langfuse application"
}

# Store all passwords in the secret
resource "aws_secretsmanager_secret_version" "langfuse" {
  secret_id = aws_secretsmanager_secret.langfuse.id
  secret_string = jsonencode({
    DATABASE_URL                  = "postgresql://${var.postgres_user}_app:${random_password.postgres_password.result}@${module.aurora.cluster_endpoint}:5432/${var.postgres_db}"
    ENCRYPTION_KEY                = random_password.langfuse_encryption_key.result
    CLICKHOUSE_USER               = "${var.clickhouse_user}"
    CLICKHOUSE_PASSWORD           = random_password.clickhouse_password.result
    SALT                          = random_password.langfuse_salt.result
    NEXTAUTH_SECRET               = random_password.nextauth_secret.result
    LANGFUSE_S3_ACCESS_KEY_ID     = aws_iam_access_key.langfuse_s3.id
    LANGFUSE_S3_SECRET_ACCESS_KEY = aws_iam_access_key.langfuse_s3.secret
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
