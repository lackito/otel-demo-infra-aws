output "repository_urls" {
  description = "Map of repository URLs."
  value       = module.ecr_repositories.repository_urls
}

output "repository_arns" {
  description = "Map of repository ARNs."
  value       = module.ecr_repositories.repository_arns
}

output "service_github_actions_role_arns" {
  description = "GitHub Actions publisher role ARNs for all custom services."
  value       = { for service, publisher in module.service_github_actions : service => publisher.role_arn }
}
