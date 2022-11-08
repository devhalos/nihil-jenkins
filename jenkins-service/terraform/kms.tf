data "aws_iam_policy_document" "jenkins_kms_logs" {
  statement {
    sid = "root"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.aws_account}:root"
      ]
    }

    actions = [
      "kms:*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "logs"

    principals {
      type = "Service"
      identifiers = [
        "logs.${var.aws_region}.amazonaws.com"
      ]
    }

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"

      values = [
        "arn:aws:logs:${var.aws_region}:${var.aws_account}:log-group:${local.log_group_name}"
      ]
    }
  }
}

resource "aws_kms_key" "jenkins_logs" {
  description         = "Encrypt ${var.component} logs"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.jenkins_kms_logs.json
}

resource "aws_kms_alias" "jenkins_logs" {
  name          = "alias/${local.component_name}-logs"
  target_key_id = aws_kms_key.jenkins_logs.key_id
}
