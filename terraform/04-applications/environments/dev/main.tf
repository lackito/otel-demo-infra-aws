module "otel_demo" {

  source = "../../modules/otel-demo"

  cluster_name = data.terraform_remote_state.platform.outputs.cluster_name

}

module "ecr_repositories" {
  source = "../../modules/ecr-repositories"

  repositories = local.ecr_repositories

  tags = local.common_tags
}
