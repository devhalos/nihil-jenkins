provider "aws" {
  region = "ap-southeast-1"

  default_tags {
    tags = {
      organization = var.organization
      project      = var.project
      component    = var.component
    }
  }
}

locals {
  component_name = "${var.project}-${terraform.workspace}-${var.component}"

  public_subnets = [
    "10.0.0.0/24",
    "10.0.1.0/24"
  ]

  private_subnets = [
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]

  subnets = concat(
    local.public_subnets,
    local.private_subnets
  )

  service_discovery_namespace_name = local.component_name
  service_discovery_service_name   = var.component
  jenkins_port                     = 8080
  jenkins_tunnel_port              = 50000
  jenkins_ecs_tunnel               = "${local.service_discovery_service_name}.${local.service_discovery_namespace_name}:${local.jenkins_tunnel_port}"
  app_registry                     = "${var.aws_account}.dkr.ecr.${var.aws_region}.amazonaws.com"
  app_image_name                   = coalesce(var.app_image_name, "${var.project}-${terraform.workspace}-jenkins-app")
  app_image_tag                    = coalesce(var.app_image_tag, terraform.workspace)
  app_image_full                   = "${local.app_registry}/${local.app_image_name}:${local.app_image_tag}"
}
