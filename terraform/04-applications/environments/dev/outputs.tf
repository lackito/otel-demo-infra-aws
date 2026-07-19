output "otel_namespace" {
  value = module.otel_demo.namespace
}

output "otel_release" {
  value = module.otel_demo.release_name
}

output "otel_status" {
  value = module.otel_demo.status
}

output "repository_urls" {
  description = "Map of repository URLs."
  value = module.ecr_repositories.repository_urls
}

output "repository_arns" {
  description = "Map of repository ARNs."
  value = module.ecr_repositories.repository_arns
}
