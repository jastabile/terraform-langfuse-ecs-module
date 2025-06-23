resource "aws_cloudwatch_metric_alarm" "alb_errors" {
  alarm_name          = "${var.name}_target_5xx_errors_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors 5xx errors from any target of the ALB"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions = {
    LoadBalancer = trimprefix(aws_lb.langfuse.arn, "arn:aws:elasticloadbalancing:${var.region}:${data.aws_caller_identity.current.account_id}:loadbalancer/")
  }
}

resource "aws_cloudwatch_metric_alarm" "elb_5xx_alarm" {
  alarm_name          = "${var.name}_alb_5xx_errors_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alarm for HTTPCode_ELB_5XX_Count metric on ALB"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions = {
    LoadBalancer = trimprefix(aws_lb.langfuse.arn, "arn:aws:elasticloadbalancing:${var.region}:${data.aws_caller_identity.current.account_id}:loadbalancer/")
  }
}

resource "aws_cloudwatch_metric_alarm" "target_response_time_alarm" {
  alarm_name          = "${var.name}_target_response_time"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "17"
  alarm_description   = "Alarm for Target Response Time metric on ALB"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions = {
    LoadBalancer = trimprefix(aws_lb.langfuse.arn, "arn:aws:elasticloadbalancing:${var.region}:${data.aws_caller_identity.current.account_id}:loadbalancer/")
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_rejected_connections_alarm" {
  alarm_name          = "${var.name}_alb_rejected_connections"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "RejectedConnectionCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alarm for Rejected Connection Count metric on ALB"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions = {
    LoadBalancer = trimprefix(aws_lb.langfuse.arn, "arn:aws:elasticloadbalancing:${var.region}:${data.aws_caller_identity.current.account_id}:loadbalancer/")
  }
}

resource "aws_cloudwatch_metric_alarm" "langfuse_worker_cpu_utilized" {
  alarm_name          = "langfuse_worker_cpu_utilized"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "Percentage of CPU units that the Langfuse Worker tasks are currently using"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.langfuse_worker.name
  }
}

resource "aws_cloudwatch_metric_alarm" "langfuse_worker_memory_utilized" {
  alarm_name          = "langfuse_worker_memory_utilized"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "Percentage of memory units that the Langfuse Worker tasks are currently using"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.langfuse_worker.name
  }
}

resource "aws_cloudwatch_metric_alarm" "langfuse_web_cpu_utilized" {
  alarm_name          = "langfuse_web_cpu_utilized"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "Percentage of CPU units that the Langfuse Web tasks are currently using"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.langfuse_web.name
  }
}

resource "aws_cloudwatch_metric_alarm" "langfuse_web_memory_utilized" {
  alarm_name          = "langfuse_web_memory_utilized"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "Percentage of memory units that the Langfuse Web tasks are currently using"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.langfuse_web.name
  }
}

resource "aws_cloudwatch_metric_alarm" "clickhouse_cpu_utilized" {
  alarm_name          = "clickhouse_cpu_utilized"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "Percentage of CPU units that the Clickhouse tasks are currently using"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.clickhouse.name
  }
}

resource "aws_cloudwatch_metric_alarm" "clickhouse_memory_utilized" {
  alarm_name          = "clickhouse_memory_utilized"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "Percentage of memory units that the Clickhouse tasks are currently using"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.clickhouse.name
  }
}
