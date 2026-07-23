module "ecr_repositories" {
  source = "../../modules/ecr-repositories"
  repositories = local.ecr_repositories
  tags = local.common_tags
}

module "recommendation_github_actions" {
  source = "../../modules/github-actions-ecr"

  ecr_repository_arn = module.ecr_repositories.repository_arns["recommendation"]

  github_owner           = "lackito"
  github_owner_id        = "6595109"
  github_repository_name = "ot-demo-apps"
  github_repository_id   = "1305341394"
  github_branch          = "main"
  
  role_name          = "ot-demo-dev-recommendation-github-actions"
  tags               = local.common_tags
}

module "argocd_application" {
  source = "../../modules/argocd-application"
  gitops_repo = "https://github.com/lackito/ot-demo-gitops.git"
  gitops_branch = "main"
  gitops_path = "applications/otel-demo"
}
