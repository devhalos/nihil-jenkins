
data "aws_iam_policy_document" "jenkins_task_trust_relationship" {
  statement {
    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

data "aws_iam_policy_document" "jenkins_task" {
  statement {
    sid = "JenkinsTask"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]
    resources = [
      "arn:aws:elasticfilesystem:${var.aws_region}:${var.aws_account}:file-system/${aws_efs_file_system.jenkins.id}"
    ]
  }
}

resource "aws_iam_policy" "jenkins_task" {
  name   = "${local.component_name}-task"
  policy = data.aws_iam_policy_document.jenkins_task.json
}

resource "aws_iam_role" "jenkins_task" {
  name = "${local.component_name}-task"
  managed_policy_arns = [
    aws_iam_policy.jenkins_task.arn
  ]
  assume_role_policy = data.aws_iam_policy_document.jenkins_task_trust_relationship.json
}

data "aws_iam_policy_document" "jenkins_task_execution" {
  statement {
    sid = "Ecr"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = [
      "*"
      # "arn:aws:ecr:${var.aws_region}:${var.aws_account}:repository/*"
    ]
  }

  statement {
    sid = "Logs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "jenkins_task_execution" {
  name   = "${local.component_name}-task-execution"
  policy = data.aws_iam_policy_document.jenkins_task_execution.json
}

resource "aws_iam_role" "jenkins_task_execution" {
  name = "${local.component_name}-task-execution"
  managed_policy_arns = [
    aws_iam_policy.jenkins_task_execution.arn
  ]
  assume_role_policy = data.aws_iam_policy_document.jenkins_task_trust_relationship.json
}

resource "aws_iam_user" "jenkins_agent" {
  name = "${local.component_name}-agent"
}

resource "aws_iam_access_key" "jenkins_agent" {
  user = aws_iam_user.jenkins_agent.name
}


data "aws_iam_policy_document" "jenkins_agent_trust_relationship" {
  statement {
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_user.jenkins_agent.arn
      ]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

data "aws_iam_policy_document" "jenkins_agent" {
  statement {
    sid = "EcsAll"
    actions = [
      "ecs:DeregisterTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecs:ListClusters"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid = "Ecs"
    actions = [
      "ecs:RunTask",
      "ecs:StopTask",
      "ecs:DescribeTasks",
    ]
    resources = [
      "arn:aws:ecs:${var.aws_region}:${var.aws_account}:task/*/*",
      "arn:aws:ecs:${var.aws_region}:${var.aws_account}:task-definition/*:*"
    ]
  }

  statement {
    sid = "Iam"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::${var.aws_account}:role/${aws_iam_role.jenkins_task_execution.name}"
    ]
  }

  statement {
    sid = "LogStreams"
    actions = [
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.aws_account}:log-group:${aws_cloudwatch_log_group.jenkins.name}:log-stream:*"
    ]
  }

  statement {
    sid = "Logs"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.aws_account}:log-group:*"
    ]
  }
}

resource "aws_iam_policy" "jenkins_agent" {
  name   = "${local.component_name}-agent"
  policy = data.aws_iam_policy_document.jenkins_agent.json
}

resource "aws_iam_role" "jenkins_agent" {
  name = "${local.component_name}-agent"
  managed_policy_arns = [
    aws_iam_policy.jenkins_agent.arn
  ]
  assume_role_policy = data.aws_iam_policy_document.jenkins_agent_trust_relationship.json
}
