resource "aws_lb" "jenkins" {
  name               = local.component_name
  internal           = false
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.alb.id
  ]
  subnets = [for subnet in aws_subnet.jenkins_pub : subnet.id]
}

resource "aws_lb_target_group" "jenkins" {
  name        = local.component_name
  vpc_id      = aws_vpc.jenkins.id
  port        = local.jenkins_port
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    path                = "/login"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 30
    interval            = 60
    matcher             = 200
  }
}

resource "aws_lb_listener" "jenkins" {
  load_balancer_arn = aws_lb.jenkins.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.jenkins.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn

  }
}

resource "aws_lb_listener" "jenkins_http_to_https" {
  load_balancer_arn = aws_lb.jenkins.arn
  port              = "80"
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

