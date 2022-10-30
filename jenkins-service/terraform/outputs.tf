output "jenkins_url" {
  value = aws_lb.jenkins.dns_name
}
