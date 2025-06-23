data "aws_region" "current" {}

# Application Load Balancer
resource "aws_lb" "langfuse" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = local.public_subnets

  enable_deletion_protection = false

  tags = {
    Name = "${var.name}-alb"
  }
}

# Target group for the web service
resource "aws_lb_target_group" "langfuse_web" {
  name        = "${var.name}-web-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.name} Web Target Group"
  }
}

# Target group for the worker service
resource "aws_lb_target_group" "langfuse_worker" {
  name        = "${var.name}-worker-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.name} Worker Target Group"
  }
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.langfuse.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.langfuse.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.langfuse_web.arn
  }
}

resource "aws_lb_listener_rule" "worker" {
  listener_arn = aws_lb_listener.https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.langfuse_worker.arn
  }

  condition {
    host_header {
      values = ["${var.name}-worker.${var.domain}"]
    }
  }
}

resource "aws_lb_listener_rule" "web" {
  listener_arn = aws_lb_listener.https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.langfuse_web.arn
  }

  condition {
    host_header {
      values = ["${var.name}.${var.domain}"]
    }
  }
}
