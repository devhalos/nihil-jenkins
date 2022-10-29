terraform {
  required_version = ">= 1.2.0"

  backend "s3" {
    bucket  = "devhalos-nihil-remote-backend-jenkins-casc-state"
    key     = "terraform.tfstate"
    region  = "ap-southeast-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.28.0"
    }
  }
}

