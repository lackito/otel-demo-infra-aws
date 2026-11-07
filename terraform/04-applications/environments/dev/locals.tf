locals {
  project     = "otel-demo"
  repository  = "otel-demo-infra-aws"
  environment = "dev"
  layer       = "applications"

  ecr_repositories = {

    recommendation = {
      scan_on_push = true
    }

    product-catalog = { image_tag_mutability = "IMMUTABLE" }
    ad              = { image_tag_mutability = "IMMUTABLE" }

  }

  common_tags = {
    Project     = local.project
    Repository  = local.repository
    Environment = local.environment
    Layer       = local.layer
    ManagedBy   = "Terraform"
  }
}
