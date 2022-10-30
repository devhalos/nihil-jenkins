resource "aws_efs_file_system" "jenkins" {
  creation_token = local.component_name
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name = local.component_name
  }
}

resource "aws_efs_access_point" "jenkins" {
  file_system_id = aws_efs_file_system.jenkins.id

  root_directory {
    path = "/"


    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = 755
    }
  }

  posix_user {
    uid = 0
    gid = 0
  }

  tags = {
    Name = local.component_name
  }
}

resource "aws_efs_mount_target" "jenkins" {
  for_each = aws_subnet.jenkins_pri

  file_system_id = aws_efs_file_system.jenkins.id
  subnet_id      = each.value.id
  security_groups = [
    aws_security_group.efs.id
  ]
}
