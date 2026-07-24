data "terraform_remote_state" "infrastructure" {

  backend = "s3"

  config = {
    bucket = "lackito-tf-state"
    key    = "otel-demo-infra-aws/dev/infrastructure.tfstate"
    region = var.aws_region
  }

}

data "aws_eks_cluster" "this" {
  name = data.terraform_remote_state.infrastructure.outputs.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.infrastructure.outputs.cluster_name
}

module "aws_load_balancer_controller" {
  source             = "../../modules/aws-load-balancer-controller"
  cluster_name       = data.terraform_remote_state.infrastructure.outputs.cluster_name
  oidc_issuer_url    = data.terraform_remote_state.infrastructure.outputs.cluster_oidc_issuer_url
  oidc_provider_arn  = data.terraform_remote_state.infrastructure.outputs.cluster_oidc_provider_arn
  vpc_id             = data.terraform_remote_state.infrastructure.outputs.vpc_id
  region             = var.aws_region
  helm_chart_version = var.helm_chart_version
}

module "argocd" {
  source = "../../modules/argocd"
}
