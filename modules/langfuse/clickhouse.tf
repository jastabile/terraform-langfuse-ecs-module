# EFS Access Points for Clickhouse instance
resource "aws_efs_access_point" "clickhouse" {
  file_system_id = aws_efs_file_system.langfuse.id

  root_directory {
    path = "/clickhouse"
    creation_info {
      owner_gid   = 101
      owner_uid   = 101
      permissions = "0755"
    }
  }

  posix_user {
    gid = 101
    uid = 101
  }

  tags = {
    Name = "${var.name} Clickhouse"
  }
}
