# ECS Service for ClickHouse
resource "aws_ecs_service" "clickhouse" {
  name            = "${var.name}-clickhouse"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.clickhouse.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  enable_execute_command            = var.enable_execute_command
  health_check_grace_period_seconds = 30

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [aws_security_group.ecs_security_group.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.clickhouse.arn
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

}

# ECS Service for Langfuse Web
resource "aws_ecs_service" "langfuse_web" {
  name            = "${var.name}-web"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.langfuse_web.arn
  desired_count   = 0
  launch_type     = "FARGATE"

  enable_execute_command            = var.enable_execute_command
  health_check_grace_period_seconds = 30

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [aws_security_group.ecs_security_group.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.web.arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.langfuse_web.arn
    container_name   = "langfuse-web"
    container_port   = 3000
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# ECS Service for Langfuse Worker
resource "aws_ecs_service" "langfuse_worker" {
  name            = "${var.name}-worker"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.langfuse_worker.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  enable_execute_command            = var.enable_execute_command
  health_check_grace_period_seconds = 30

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [aws_security_group.ecs_security_group.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.worker.arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.langfuse_worker.arn
    container_name   = "langfuse-worker"
    container_port   = 3030
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50
}
