locals {
  project     = "ot-demo"
  repository  = "ot-demo-tf"
  environment = "dev"
  layer       = "applications"

  common_tags = {
    Project     = local.project
    Repository  = local.repository
    Environment = local.environment
    Layer       = local.layer
    ManagedBy   = "Terraform"
  }
}
