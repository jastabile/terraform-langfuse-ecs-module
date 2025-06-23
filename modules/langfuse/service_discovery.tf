# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "langfuse" {
  name        = "${var.name}.local"
  vpc         = local.vpc_id
  description = "Service discovery namespace for Langfuse"
}

# Service Discovery Service for ClickHouse
resource "aws_service_discovery_service" "clickhouse" {
  name = "clickhouse"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.langfuse.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# Service Discovery Service for Worker
resource "aws_service_discovery_service" "worker" {
  name = "worker"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.langfuse.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# Service Discovery Service for Web
resource "aws_service_discovery_service" "web" {
  name = "web"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.langfuse.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
