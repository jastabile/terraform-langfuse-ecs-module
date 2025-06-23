# CloudWatch Log Group for ClickHouse
resource "aws_cloudwatch_log_group" "clickhouse" {
  name              = "/ecs/${var.name}/clickhouse"
  retention_in_days = 30
}

# CloudWatch Log Group for Langfuse Web
resource "aws_cloudwatch_log_group" "langfuse_web" {
  name              = "/ecs/${var.name}/web"
  retention_in_days = 30
}

# CloudWatch Log Group for Langfuse Worker
resource "aws_cloudwatch_log_group" "langfuse_worker" {
  name              = "/ecs/${var.name}/worker"
  retention_in_days = 30
}
