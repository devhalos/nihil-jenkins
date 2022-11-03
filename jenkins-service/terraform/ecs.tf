resource "aws_ecs_cluster" "jenkins" {
  name = local.component_name
}

resource "aws_ecs_task_definition" "jenkins" {
  family                   = local.component_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu_unit
  memory                   = var.memory_unit
  task_role_arn            = aws_iam_role.jenkins_task.arn
  execution_role_arn       = aws_iam_role.jenkins_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = local.component_name
      image     = local.app_image_full
      cpu       = var.cpu_unit
      memory    = var.memory_unit
      essential = true
      portMappings = [
        {
          containerPort = local.jenkins_port
          hostPort      = local.jenkins_port
        }
      ]
      mountPoints = [
        {
          containerPath = "/var/jenkins_home"
          sourceVolume  = local.component_name
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.jenkins.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = local.component_name
        }
      },
      environment = [
        {
          name  = "JENKINS_ADMIN_USERNAME"
          value = var.admin_username
        },
        {
          name  = "JENKINS_ADMIN_PASSWORD"
          value = var.admin_password
        },
        {
          name  = "JENKINS_URL",
          value = "https://${var.domain_name}"
        },
        {
          name  = "JENKINS_ECS_ASSUMED_ROLE_ARN",
          value = aws_iam_role.jenkins_agent.arn
        },
        {
          name  = "JENKINS_ECS_AGENT_NAME",
          value = local.component_name
        },
        {
          name  = "JENKINS_ECS_IMAGE",
          value = "jenkins/inbound-agent:alpine"
        },
        {
          name  = "JENKINS_ECS_TUNNEL",
          value = local.jenkins_ecs_tunnel
        },
        {
          name  = "JENKINS_ECS_TASK_EXECUTION_ROLE",
          value = aws_iam_role.jenkins_task_execution.name
        },
        {
          name  = "JENKINS_ECS_CLUSTER_NAME_ARN",
          value = aws_ecs_cluster.jenkins.arn
        },
        {
          name  = "JENKINS_ECS_CLUSTER_REGION",
          value = var.aws_region
        },
        {
          name  = "JENKINS_ECS_SUBNETS",
          value = join(",", [for d in aws_subnet.jenkins_pri : d.id])
        },
        {
          name  = "JENKINS_ECS_SECURITY_GROUPS",
          value = aws_security_group.ecs.id
        },
        {
          name  = "JENKINS_ECS_AWSLOGS_GROUP",
          value = aws_cloudwatch_log_group.jenkins.name
        },
        {
          name  = "JENKINS_ECS_AWSLOGS_REGION",
          value = var.aws_region
        },
        {
          name  = "JENKINS_ECS_AWSLOGS_STREAM_PREFIX",
          value = local.component_name
        },
        {
          name  = "JENKINS_ECS_CPU",
          value = tostring(var.agent_cpu_unit)
        },
        {
          name  = "JENKINS_ECS_MEMORY_RESERVATION",
          value = tostring(var.agent_memory_unit)
        },
        {
          name  = "AWS_ACCESS_KEY_ID",
          value = aws_iam_access_key.jenkins_agent.id
        },
        {
          name  = "AWS_SECRET_ACCESS_KEY",
          value = aws_iam_access_key.jenkins_agent.secret
        },
        {
          name  = "GITHUB_USERNAME",
          value = var.github_username
        },
        {
          name  = "GITHUB_TOKEN",
          value = var.github_token
        },
        {
          name  = "ADMIN_EMAIL_ADDRESS",
          value = var.admin_email
        }
      ]
    }
  ])

  volume {
    name = local.component_name

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.jenkins.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.jenkins.id
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "jenkins" {
  name                               = local.component_name
  cluster                            = aws_ecs_cluster.jenkins.id
  task_definition                    = aws_ecs_task_definition.jenkins.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
  health_check_grace_period_seconds  = 300
  force_new_deployment               = true

  service_registries {
    registry_arn = aws_service_discovery_service.jenkins.arn
    port         = local.jenkins_tunnel_port
  }

  network_configuration {
    assign_public_ip = true
    subnets          = [for d in aws_subnet.jenkins_pri : d.id]
    security_groups = [
      aws_security_group.ecs.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.jenkins.arn
    container_name   = local.component_name
    container_port   = local.jenkins_port
  }
}
