resource "aws_ecr_repository" "jenkins" {
  name                 = local.component_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.jenkins_ecr.key_id
  }
}
