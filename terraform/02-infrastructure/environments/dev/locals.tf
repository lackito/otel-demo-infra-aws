locals {
  project     = "otel-demo"
  repository  = "otel-demo-infra-aws"
  environment = "dev"
  layer       = "infrastructure"
  cluster_name = "${local.project}-${local.environment}"

  common_tags = {
    Project     = local.project
    Repository  = local.repository
    Environment = local.environment
    Layer       = local.layer
    ManagedBy   = "Terraform"
  }
}
