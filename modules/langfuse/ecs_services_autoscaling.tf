# Auto-scaling configuration for Langfuse Web service
resource "aws_appautoscaling_target" "langfuse_web" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.langfuse_web.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU utilization target tracking for Langfuse Web
resource "aws_appautoscaling_policy" "langfuse_web_cpu" {
  name               = "${var.name}-web-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.langfuse_web.resource_id
  scalable_dimension = aws_appautoscaling_target.langfuse_web.scalable_dimension
  service_namespace  = aws_appautoscaling_target.langfuse_web.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Memory utilization target tracking for Langfuse Web
resource "aws_appautoscaling_policy" "langfuse_web_memory" {
  name               = "${var.name}-web-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.langfuse_web.resource_id
  scalable_dimension = aws_appautoscaling_target.langfuse_web.scalable_dimension
  service_namespace  = aws_appautoscaling_target.langfuse_web.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Auto-scaling configuration for Langfuse Worker service
resource "aws_appautoscaling_target" "langfuse_worker" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.langfuse_worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU utilization target tracking for Langfuse Worker
resource "aws_appautoscaling_policy" "langfuse_worker_cpu" {
  name               = "${var.name}-worker-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.langfuse_worker.resource_id
  scalable_dimension = aws_appautoscaling_target.langfuse_worker.scalable_dimension
  service_namespace  = aws_appautoscaling_target.langfuse_worker.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Memory utilization target tracking for Langfuse Worker
resource "aws_appautoscaling_policy" "langfuse_worker_memory" {
  name               = "${var.name}-worker-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.langfuse_worker.resource_id
  scalable_dimension = aws_appautoscaling_target.langfuse_worker.scalable_dimension
  service_namespace  = aws_appautoscaling_target.langfuse_worker.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Can't scale at the moment
# # Auto-scaling configuration for ClickHouse service
# resource "aws_appautoscaling_target" "clickhouse" {
#   max_capacity       = 3
#   min_capacity       = 1
#   resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.clickhouse.name}"
#   scalable_dimension = "ecs:service:DesiredCount"
#   service_namespace  = "ecs"
# }

# CPU utilization target tracking for ClickHouse
# resource "aws_appautoscaling_policy" "clickhouse_cpu" {
#   name               = "${var.name}-clickhouse-cpu-autoscaling"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.clickhouse.resource_id
#   scalable_dimension = aws_appautoscaling_target.clickhouse.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.clickhouse.service_namespace

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageCPUUtilization"
#     }
#     target_value       = 70.0
#     scale_in_cooldown  = 300
#     scale_out_cooldown = 300
#   }
# }

# # Memory utilization target tracking for ClickHouse
# resource "aws_appautoscaling_policy" "clickhouse_memory" {
#   name               = "${var.name}-clickhouse-memory-autoscaling"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.clickhouse.resource_id
#   scalable_dimension = aws_appautoscaling_target.clickhouse.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.clickhouse.service_namespace

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageMemoryUtilization"
#     }
#     target_value       = 70.0
#     scale_in_cooldown  = 300
#     scale_out_cooldown = 300
#   }
# }
