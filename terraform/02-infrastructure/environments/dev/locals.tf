locals {
  project = "ot-demo"

  cluster_name = "${local.project}-${var.environment}"

  common_tags = {
    Project     = "ot-demo"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
