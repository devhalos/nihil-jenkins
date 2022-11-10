resource "aws_cloudwatch_log_group" "jenkins" {
  name              = local.log_group_name
  retention_in_days = 7
  kms_key_id        = aws_kms_key.jenkins_logs.arn
}
