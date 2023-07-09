variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnet_cidr_block_1" {
  description = "CIDR block for subnet 1"
  type        = string
}

variable "subnet_cidr_block_2" {
  description = "CIDR block for subnet 2"
  type        = string
}

variable "availability_zone_1" {
  description = "Availability Zone for subnet 1"
  type        = string
}

variable "availability_zone_2" {
  description = "Availability Zone for subnet 2"
  type        = string
}

variable "security_group_name" {
  description = "Name for the security group"
  type        = string
}

variable "ecr_repository_name" {
  description = "Name for the ECR repository"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name for the ECS cluster"
  type        = string
}

variable "execution_role_name" {
  description = "Name for the ECS task execution role"
  type        = string
}

variable "task_role_name" {
  description = "Name for the ECS task role"
  type        = string
}

variable "task_definition_family" {
  description = "Family name for the ECS task definition"
  type        = string
}

variable "container-name" {
  description = "container Name"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the ECS task"
  type        = number
}

variable "task_memory" {
  description = "Memory for the ECS task"
  type        = number
}

variable "service_name" {
  description = "Name for the ECS service"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks to run"
  type        = number
}

variable "assign_public_ip" {
  description = "Assign a public IP to the ECS tasks"
  type        = bool
}
variable "container_port" {
  description = "Container port "
  type        = number
}
variable "hostPort" {
  description = "Host Port"
  type        = number
}
variable "my-load-balancer" {
  description = "Application Load balancer Name"
  type        = string
}
variable "my-target-group" {
  description = "Target roup Name"
  type        = string
}
variable "listner-port-tg" {
  description = "Target group ListnerPort"
  type        = number
}
