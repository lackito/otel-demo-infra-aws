variable "helm_repo" {
  default = "https://open-telemetry.github.io/opentelemetry-helm-charts"
}

variable "helm_chart" {
  default = "opentelemetry-demo"
}

variable "helm_chart_version" {
  default = "0.38.4"
}

variable "values_file" {
  default = "$values/applications/otel-demo/values.yaml"
}

variable "gitops_repo" {
  description = "GitOps repository containing application manifests"
  type        = string
}

variable "gitops_branch" {
  description = "GitOps branch"
  type        = string
  default     = "main"
}

variable "gitops_path" {
  description = "Application path inside GitOps repository"
  type        = string
}
