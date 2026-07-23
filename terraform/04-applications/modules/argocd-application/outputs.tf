output "application_name" {

  value = kubernetes_manifest.otel_demo.manifest.metadata.name

}
