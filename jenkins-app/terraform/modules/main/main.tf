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
  sub_prefix     = terraform.workspace != "default" ? "-${terraform.workspace}" : ""
  prefix         = "${var.environment}${local.sub_prefix}"
  component_name = "${local.prefix}-${var.project}-${var.component}"
}
