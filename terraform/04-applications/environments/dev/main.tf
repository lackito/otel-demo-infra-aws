module "ecr_repositories" {
  source       = "../../modules/ecr-repositories"
  repositories = local.ecr_repositories
  # This dev environment is disposable; destroy also removes its stored images.
  force_delete = true
  tags         = local.common_tags
}

module "argocd_application" {
  source        = "../../modules/argocd-application"
  gitops_repo   = "https://github.com/lackito/otel-demo-gitops-aws.git"
  gitops_branch = "main"
  gitops_path   = "applications/otel-demo"
}

module "service_github_actions" {
  for_each               = toset(["recommendation", "product-catalog", "ad"])
  source                 = "../../modules/github-actions-ecr-publisher"
  oidc_provider_arn      = data.aws_iam_openid_connect_provider.github_actions.arn
  ecr_repository_arn     = module.ecr_repositories.repository_arns[each.key]
  github_owner           = "lackito"
  github_owner_id        = "6595109"
  github_repository_name = "otel-demo-apps"
  github_repository_id   = "1305341394"
  github_branch          = "main"
  role_name              = "otel-demo-aws-dev-${each.key}-github-actions"
  tags                   = local.common_tags
}
