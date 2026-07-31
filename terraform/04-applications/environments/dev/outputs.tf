output "repository_urls" {
  description = "Map of repository URLs."
  value       = module.ecr_repositories.repository_urls
}

output "repository_arns" {
  description = "Map of repository ARNs."
  value       = module.ecr_repositories.repository_arns
}

output "recommendation_github_actions_role_arn" {
  description = "IAM role ARN for the recommendation GitHub Actions workflow."
  value       = module.recommendation_github_actions.role_arn
}
