module "ecr_repositories" {
  source       = "../../modules/ecr-repositories"
  repositories = local.ecr_repositories
  tags         = local.common_tags
}

module "recommendation_github_actions" {
  source            = "../../modules/github-actions-ecr"
  oidc_provider_arn = data.aws_iam_openid_connect_provider.github_actions.arn

  ecr_repository_arn = module.ecr_repositories.repository_arns["recommendation"]

  github_owner           = "lackito"
  github_owner_id        = "6595109"
  github_repository_name = "otel-demo-apps"
  github_repository_id   = "1305341394"
  github_branch          = "main"

  role_name = "otel-demo-aws-dev-recommendation-github-actions"
  tags      = local.common_tags
}

module "argocd_application" {
  source        = "../../modules/argocd-application"
  gitops_repo   = "https://github.com/lackito/otel-demo-gitops-aws.git"
  gitops_branch = "main"
  gitops_path   = "applications/otel-demo"
}

module "service_github_actions" {
  for_each               = toset(["product-catalog", "ad"])
  source                 = "../../modules/github-actions-ecr-publisher"
  oidc_provider_arn      = module.recommendation_github_actions.oidc_provider_arn
  ecr_repository_arn     = module.ecr_repositories.repository_arns[each.key]
  github_owner           = "lackito"
  github_owner_id        = "6595109"
  github_repository_name = "otel-demo-apps"
  github_repository_id   = "1305341394"
  github_branch          = "main"
  role_name              = "otel-demo-aws-dev-${each.key}-github-actions"
  tags                   = local.common_tags
}
