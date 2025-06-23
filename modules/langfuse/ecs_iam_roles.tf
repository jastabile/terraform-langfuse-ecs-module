# IAM Role for ECS Task Execution
resource "aws_iam_role" "TaskExecutionRole" {
  name = "${var.name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "TaskExecutionRolePolicy" {
  role       = aws_iam_role.TaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional CloudWatch Logs permissions for task execution role
resource "aws_iam_role_policy" "task_execution_logs_policy" {
  name = "${var.name}-task-execution-logs-policy"
  role = aws_iam_role.TaskExecutionRole.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.name}/*"
      }
    ]
  })
}

# Additional Secrets Manager permissions for task execution role
resource "aws_iam_role_policy" "task_execution_secrets_policy" {
  name = "${var.name}-task-execution-secrets-policy"
  role = aws_iam_role.TaskExecutionRole.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.langfuse.arn
        ]
      }
    ]
  })
}

# IAM Role for ClickHouse tasks
resource "aws_iam_role" "ecs_task_role_clickhouse" {
  name = "${var.name}-clickhouse-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Role for Langfuse tasks
resource "aws_iam_role" "ecs_task_role_langfuse" {
  name = "${var.name}-langfuse-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for Langfuse tasks
resource "aws_iam_role_policy" "langfuse_task_policy" {
  name = "${var.name}-langfuse-task-policy"
  role = aws_iam_role.ecs_task_role_langfuse.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.name}/*"
      }
    ]
  })
}

# IAM Policy for ClickHouse tasks
resource "aws_iam_role_policy" "clickhouse_task_policy" {
  name = "${var.name}-clickhouse-task-policy"
  role = aws_iam_role.ecs_task_role_clickhouse.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.name}/*"
      }
    ]
  })
}


resource "aws_iam_role_policy" "ecs_task_execute_command_policy_langfuse" {
  count = var.enable_execute_command ? 1 : 0
  name  = "ecs-execute-command-policy-langfuse"
  role  = aws_iam_role.ecs_task_role_langfuse.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_execute_command_policy_clickhouse" {
  count = var.enable_execute_command ? 1 : 0
  name  = "ecs-execute-command-policy-clickhouse"
  role  = aws_iam_role.ecs_task_role_clickhouse.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}
