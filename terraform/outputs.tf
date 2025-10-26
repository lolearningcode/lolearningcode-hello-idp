output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.app_service.ecr_repository_url
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN"
  value       = module.app_service.ecs_cluster_arn
}

output "ecs_service_arn" {
  description = "ECS Service ARN"
  value       = module.app_service.ecs_service_arn
}

output "task_definition_arn" {
  description = "ECS Task Definition ARN"
  value       = module.app_service.task_definition_arn
}

output "load_balancer_dns" {
  description = "ALB DNS name"
  value       = module.app_service.load_balancer_dns
}

output "log_group_name" {
  description = "CloudWatch Logs log group name"
  value       = module.app_service.log_group_name
}

output "service_url" {
  description = "Convenient HTTP URL to access the service via ALB"
  value       = module.app_service.service_url
}
