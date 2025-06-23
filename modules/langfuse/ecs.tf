# Create an ECS cluster with a single node
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ECSCluster-${var.name}"
}

# Creating a data source to get the most recent AMI from the Marketplace for the EC2 Node
data "aws_ami" "ecs_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-*-x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["amazon"]
}


resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity_providers" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
    base              = 0
  }
}
