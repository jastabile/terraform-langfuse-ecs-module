output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.ecs_cluster.name
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.langfuse.dns_name
}

output "route53_nameservers" {
  description = "Nameserver for the Route53 zone"
  value       = var.use_existing_hosted_zone ? [] : aws_route53_zone.zone[0].name_servers
}
