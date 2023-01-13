output "jenkins_repository_arn" {
  value = aws_ecr_repository.jenkins.arn
}

output "jenkins_repository_url" {
  value = aws_ecr_repository.jenkins.repository_url
}
