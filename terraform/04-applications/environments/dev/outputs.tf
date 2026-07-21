output "repository_urls" {
  description = "Map of repository URLs."
  value = module.ecr_repositories.repository_urls
}

output "repository_arns" {
  description = "Map of repository ARNs."
  value = module.ecr_repositories.repository_arns
}
