output "ecr_repository_url" {
  value       = aws_ecr_repository.this.repository_url
  description = "ECR repository URL"
}

output "ecs_cluster_arn" {
  value       = aws_ecs_cluster.this.arn
  description = "ECS Cluster ARN"
}

output "ecs_service_arn" {
  value       = aws_ecs_service.this.arn
  description = "ECS Service ARN"
}

output "task_definition_arn" {
  value       = aws_ecs_task_definition.this.arn
  description = "ECS Task Definition ARN"
}

output "load_balancer_dns" {
  value       = aws_lb.this.dns_name
  description = "ALB DNS name"
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.this.name
  description = "CloudWatch Logs log group name"
}

output "service_url" {
  value       = "http://${aws_lb.this.dns_name}"
  description = "Convenient HTTP URL to access the service via ALB"
}
