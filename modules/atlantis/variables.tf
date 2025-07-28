variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "atlantis_image_tag" {
  description = "Atlantis Docker image tag"
  type        = string
  default     = "latest"
}

variable "github_user" {
  description = "GitHub username for Atlantis"
  type        = string
}

variable "github_token_secret_name" {
  description = "AWS Secrets Manager secret name for GitHub token"
  type        = string
}

variable "github_webhook_secret_name" {
  description = "AWS Secrets Manager secret name for GitHub webhook secret"
  type        = string
}

variable "repo_allowlist" {
  description = "Atlantis repo allowlist"
  type        = string
}

variable "cpu" {
  description = "CPU units for ECS task"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Memory (MB) for ECS task"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "ssl_certificate_arn" {
  description = "SSL certificate ARN for HTTPS"
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Custom domain name for Atlantis"
  type        = string
  default     = null
}
