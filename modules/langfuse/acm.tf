# ACM Certificate for the domain
resource "aws_acm_certificate" "cert" {
  count             = var.use_existing_hosted_zone ? 0 : 1
  domain_name       = var.domain
  validation_method = "DNS"

  subject_alternative_names = [
    "langfuse.${var.domain}",
    "worker.${var.domain}"
  ]

  tags = {
    Name = "${var.name}-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create Route53 zone for the domain
resource "aws_route53_zone" "zone" {
  count = var.use_existing_hosted_zone ? 0 : 1
  name  = var.domain

  tags = {
    Name = "${var.name}-zone"
  }
}

# Create DNS records for certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = var.use_existing_hosted_zone ? {} : {
    for dvo in aws_acm_certificate.cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.use_existing_hosted_zone ? var.existing_zone_id : aws_route53_zone.zone[0].zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "cert" {
  count                   = var.use_existing_hosted_zone ? 0 : 1
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Create Route53 record for the Langfuse ALB
resource "aws_route53_record" "langfuse" {
  zone_id = var.use_existing_hosted_zone ? var.existing_zone_id : aws_route53_zone.zone[0].zone_id
  name    = "${var.name}.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_lb.langfuse.dns_name
    zone_id                = aws_lb.langfuse.zone_id
    evaluate_target_health = true
  }
}

# Create Route53 record for the Worker ALB
resource "aws_route53_record" "worker" {
  zone_id = var.use_existing_hosted_zone ? var.existing_zone_id : aws_route53_zone.zone[0].zone_id
  name    = "${var.name}-worker.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_lb.langfuse.dns_name
    zone_id                = aws_lb.langfuse.zone_id
    evaluate_target_health = true
  }
}
