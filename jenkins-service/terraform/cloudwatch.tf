resource "aws_cloudwatch_log_group" "jenkins" {
  name              = local.component_name
  retention_in_days = 7
}
