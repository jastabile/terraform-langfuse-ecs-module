# EFS File System
resource "aws_efs_file_system" "langfuse" {
  creation_token  = "${var.name}-efs"
  encrypted       = true
  throughput_mode = "elastic"

  tags = {
    Name = "${var.name}-efs"
  }
}

# Mount targets in each private subnet
resource "aws_efs_mount_target" "ecs" {
  count           = length(local.private_subnets)
  file_system_id  = aws_efs_file_system.langfuse.id
  subnet_id       = local.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Security group for EFS
resource "aws_security_group" "efs" {
  name        = "${var.name}-efs"
  description = "Security group for EFS"
  vpc_id      = local.vpc_id

  ingress {
    description = "NFS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-efs"
  }
}

# EFS IAM Policy
resource "aws_iam_policy" "efs" {
  name = "${var.name}-efs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.name}-efs"
  }
}

# ECS Task Execution Role for EFS
resource "aws_iam_role" "efs" {
  name = "${var.name}-efs-ecs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs" {
  policy_arn = aws_iam_policy.efs.arn
  role       = aws_iam_role.efs.name
}

resource "aws_efs_access_point" "clickhouse_logs" {
  file_system_id = aws_efs_file_system.langfuse.id

  root_directory {
    path = "/clickhouse/logs"
    creation_info {
      owner_gid   = 101
      owner_uid   = 101
      permissions = "755"
    }
  }

  posix_user {
    gid = 101
    uid = 101
  }
}
