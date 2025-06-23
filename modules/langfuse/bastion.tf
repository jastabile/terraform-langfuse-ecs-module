# Security group for bastion host
resource "aws_security_group" "bastion" {
  count       = var.deploy_bastion ? 1 : 0
  name        = "${var.name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = local.vpc_id

  # Allow SSH access from specified CIDR blocks
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidr_blocks
    description = "Allow SSH access from specified CIDR blocks"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.name} Bastion Security Group"
  }
}

# IAM role for bastion host
resource "aws_iam_role" "bastion" {
  count = var.deploy_bastion ? 1 : 0
  name  = "${var.name}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name} Bastion Role"
  }
}

# IAM instance profile for bastion host
resource "aws_iam_instance_profile" "bastion" {
  count = var.deploy_bastion ? 1 : 0
  name  = "${var.name}-bastion-profile"
  role  = aws_iam_role.bastion[0].name
}

# Bastion host EC2 instance
resource "aws_instance" "bastion" {
  count         = var.deploy_bastion ? 1 : 0
  ami           = data.aws_ami.bastion_ami[0].id
  instance_type = var.bastion_instance_type
  subnet_id     = local.public_subnets[0] # Place in first public subnet
  key_name      = var.bastion_key_name

  vpc_security_group_ids = [aws_security_group.bastion[0].id]
  iam_instance_profile   = aws_iam_instance_profile.bastion[0].name

  associate_public_ip_address = true

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.name}-bastion"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Using last version AMI Amazon 2
data "aws_ami" "bastion_ami" {
  count = var.deploy_bastion ? 1 : 0

  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["amazon"]
}
