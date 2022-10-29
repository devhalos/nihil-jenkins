variable "organization" {
  type    = string
  default = "devhalos"
}

variable "project" {
  type    = string
  default = "nihil"
}

variable "component" {
  type    = string
  default = "jenkins-service"
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "aws_account" {
  type = string
}

variable "docker_image_name" {
  type    = string
  default = null
}

variable "docker_image_tag" {
  type    = string
  default = null
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type = string
}

variable "github_username" {
  type = string
}

variable "github_token" {
  type = string
}

variable "admin_email" {
  type = string
}

variable "cpu_unit" {
  type    = number
  default = 1024
}

variable "memory_unit" {
  type    = number
  default = 2048
}
