variable "region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "service_name" {
  description = "Name of the service/app"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the ECS service and ALB (optional if using tag discovery or default VPC)"
  type        = string
  default     = ""
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB (optional if using tag discovery)"
  type        = list(string)
  default     = null
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks (optional if using tag discovery)"
  type        = list(string)
  default     = null
}

variable "vpc_tag_filters" {
  description = "Tag filters to discover the VPC if vpc_id is not provided, e.g. { Name = \"my-vpc\" }"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tag_filters" {
  description = "Tag filters to discover public subnets if IDs not provided, e.g. { Tier = \"public\" }"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tag_filters" {
  description = "Tag filters to discover private subnets if IDs not provided, e.g. { Tier = \"private\" }"
  type        = map(string)
  default     = {}
}

variable "container_port" {
  description = "Container port exposed by the app"
  type        = number
  default     = 3000
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "cpu" {
  description = "Fargate task CPU units"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Fargate task memory (MiB)"
  type        = string
  default     = "512"
}

variable "image_tag" {
  description = "Container image tag to deploy from ECR"
  type        = string
  default     = "latest"
}

variable "health_check_path" {
  description = "ALB health check path"
  type        = string
  default     = "/"
}

variable "assign_public_ip" {
  description = "Assign a public IP to ECS tasks"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
