locals {
  project     = "ot-demo"
  repository  = "otel-demo-infra-aws"
  environment = "dev"
  layer       = "platform"

  common_tags = {
    Project     = local.project
    Repository  = local.repository
    Environment = local.environment
    Layer       = local.layer
    ManagedBy   = "Terraform"
  }
}
