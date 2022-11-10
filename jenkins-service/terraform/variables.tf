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
  type        = string
  description = "region where to deploy jenkins service"
  default     = "ap-southeast-1"
}

variable "aws_account" {
  type        = string
  description = "account where to deploy jenkins service"
}

variable "app_image_name" {
  type        = string
  description = "container image name of jenkins app"
  default     = null
}

variable "app_image_tag" {
  type        = string
  description = "container image tag of jenkins app"
  default     = null
}

variable "admin_username" {
  type        = string
  description = "dashboard admin username"
}

variable "admin_password" {
  type        = string
  description = "dashboard admin password"
}

variable "admin_email" {
  type        = string
  description = "email address of the dashboard admin account"
}

variable "github_username" {
  type        = string
  description = "username of the admin of github organization defined in the jenkins job dsl"
}

variable "github_token" {
  type        = string
  description = "token of the admin of github organization defined in the jenkins job dsl"
}

variable "cpu_unit" {
  type        = number
  description = "the cpu unit of the jenkins controller"
  default     = 2048
}

variable "memory_unit" {
  type        = number
  description = "the memory unit of the jenkins controller"
  default     = 4096
}

variable "agent_cpu_unit" {
  type        = number
  description = "the cpu unit of the jenkins ecs agent"
  default     = 1024
}

variable "agent_memory_unit" {
  type        = number
  description = "the memory unit of the jenkins ecs agent"
  default     = 2048
}

variable "main_domain_name" {
  type        = string
  description = "main domain name"
}

variable "domain_name" {
  type        = string
  description = "sub domain name for jenkins service"
}
