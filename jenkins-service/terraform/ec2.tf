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
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    path                = "/login"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 120
    interval            = 300
    matcher             = 200
  }
}

resource "aws_lb_listener" "jenkins" {
  load_balancer_arn = aws_lb.jenkins.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }
}

