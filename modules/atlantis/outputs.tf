output "vpc_id" {
  description = "ID of the VPC (passed as input)"
  value       = var.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (passed as input)"
  value       = var.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (passed as input)"
  value       = var.private_subnet_ids
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.atlantis.repository_url
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.atlantis.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.atlantis.zone_id
}

output "atlantis_url" {
  description = "URL to access Atlantis"
  value       = var.ssl_certificate_arn != null ? "https://${var.domain_name != null ? var.domain_name : aws_lb.atlantis.dns_name}" : "http://${aws_lb.atlantis.dns_name}"
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.atlantis.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.atlantis.name
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}
