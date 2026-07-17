resource "helm_release" "this" {

  name             = "opentelemetry-demo"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-demo"
  version          = var.chart_version

  namespace        = var.namespace
  create_namespace = true

  wait    = true
  timeout = 600

  values = [
    file("${path.module}/values.yaml")
  ]

}
