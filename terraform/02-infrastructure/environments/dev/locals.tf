locals {
  project      = "otel-demo"
  repository   = "otel-demo-infra-aws"
  layer        = "infrastructure"
  cluster_name = "${local.project}-${var.environment}"

  common_tags = {
    Project     = local.project
    Repository  = local.repository
    Environment = var.environment
    Layer       = local.layer
    ManagedBy   = "Terraform"
  }
}
