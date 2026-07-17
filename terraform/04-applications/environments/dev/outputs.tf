output "otel_namespace" {
  value = module.otel_demo.namespace
}

output "otel_release" {
  value = module.otel_demo.release_name
}

output "otel_status" {
  value = module.otel_demo.status
}
