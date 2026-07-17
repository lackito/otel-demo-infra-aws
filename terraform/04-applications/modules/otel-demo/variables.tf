variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "chart_version" {
  description = "OpenTelemetry Demo Helm chart version"
  type        = string
  default     = "0.38.4"
}

variable "namespace" {
  description = "Namespace where the demo will be installed"
  type        = string
  default     = "opentelemetry-demo"
}
