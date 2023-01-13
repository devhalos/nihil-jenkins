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
  default = "jenkins-app"
}

variable "environment" {
  type = string
}

variable "force_delete_repository" {
  type    = bool
  default = false
}

variable "image_tag_mutability" {
  type    = string
  default = "IMMUTABLE"
}
