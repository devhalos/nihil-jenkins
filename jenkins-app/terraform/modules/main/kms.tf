resource "aws_kms_key" "jenkins_ecr" {
  description         = "Encrypt ${var.component} ecr repository"
  enable_key_rotation = true

}

resource "aws_kms_alias" "jenkins_ecr" {
  name          = "alias/${local.component_name}-ecr"
  target_key_id = aws_kms_key.jenkins_ecr.key_id
}
