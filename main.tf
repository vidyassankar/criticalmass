# Define the provider and AWS region
provider "aws" {
  region = var.aws_region
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_block
}

# Create subnets in different availability zones
resource "aws_subnet" "my_subnet_1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.subnet_cidr_block_1
  availability_zone = var.availability_zone_1
}

resource "aws_subnet" "my_subnet_2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.subnet_cidr_block_2
  availability_zone = var.availability_zone_2
}

# Create an internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create a route table and associate it with the subnets
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table_association" "my_association_1" {
  subnet_id      = aws_subnet.my_subnet_1.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_route_table_association" "my_association_2" {
  subnet_id      = aws_subnet.my_subnet_2.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create a security group
resource "aws_security_group" "my_security_group" {
  name        = var.security_group_name
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an ECR repository
resource "aws_ecr_repository" "my_repository" {
  name = var.ecr_repository_name
}

data "aws_ecr_repository" "my_repository" {
  name = aws_ecr_repository.my_repository.name
}
# Create an ECS Cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = var.ecs_cluster_name
}

# Create IAM roles for ECS task execution and task roles
resource "aws_iam_role" "my_execution_role" {
  name = var.execution_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "flask_execution_role_policy" {
  name   = "flask-execution-role-policy"
  role   = aws_iam_role.my_execution_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action":  [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:BatchGetImage"
          // Add any other required ECR actions here
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role" "my_task_role" {
  name = var.task_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Create an ECS Task Definition
resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = var.task_definition_family
  task_role_arn            = aws_iam_role.my_task_role.arn
  execution_role_arn       = aws_iam_role.my_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
   container_definitions = jsonencode([
   { 
    "name": var.container-name,
    "image": "${data.aws_ecr_repository.my_repository.repository_url}:latest",
    "portMappings": [
      {
        "containerPort": var.container_port,
        "hostPort": var.hostPort,		
        "protocol": "tcp"
      }
    ],
    "essential": true
  }
])
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
  target_type = "ip"

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_load_balancer.arn
  port              = var.listner-port-tg
  protocol          = "HTTP"


  default_action {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    type             = "forward"
  }
}  
# Create an ECS Service
resource "aws_ecs_service" "my_service" {
  name                   = var.service_name
  cluster                = aws_ecs_cluster.my_cluster.id
  task_definition        = aws_ecs_task_definition.my_task_definition.arn
  desired_count          = var.desired_count
  launch_type            = "FARGATE"
  network_configuration {
    subnets         = [aws_subnet.my_subnet_1.id, aws_subnet.my_subnet_2.id]
    security_groups = [aws_security_group.my_security_group.id]
    assign_public_ip = var.assign_public_ip
  }
  load_balancer {
    target_group_arn  = aws_lb_target_group.my_target_group.arn
    container_name    = var.container-name
    container_port    = 5000

  }  
}

resource "aws_lb" "my_load_balancer" {
  name               = var.my-load-balancer
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_security_group.id]
  subnets            = [aws_subnet.my_subnet_1.id, aws_subnet.my_subnet_2.id]

  enable_deletion_protection = false
}

output "alb_dns_name" {
  value = aws_lb.my_load_balancer.dns_name
}

output "aws_region" {
  value = var.aws_region
}

output "ecr_repository" {
  value = aws_ecr_repository.my_repository.name
}

output "ecs_service" {
  value = var.service_name
}

output "ALB_TARGET_GROUP_ARN" {
  value =   aws_lb_target_group.my_target_group.arn
}

output "ecs_cluster" {
  value = var.ecs_cluster_name
}
  