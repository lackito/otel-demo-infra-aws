locals {
  project     = "ot-demo"
  repository  = "ot-demo-tf"
  environment = "dev"
  layer       = "applications"

  ecr_repositories = {

    recommendation = {
      scan_on_push = true
    }

    checkout = {
      image_tag_mutability = "IMMUTABLE"
    }

    frontend = {}

  }

  common_tags = {
    Project     = local.project
    Repository  = local.repository
    Environment = local.environment
    Layer       = local.layer
    ManagedBy   = "Terraform"
  }
}
