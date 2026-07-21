module "ecr_repositories" {
  source = "../../modules/ecr-repositories"

  repositories = local.ecr_repositories

  tags = local.common_tags
}
