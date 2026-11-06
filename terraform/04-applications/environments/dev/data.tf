data "terraform_remote_state" "platform" {
  backend = "s3"

  config = {
    bucket = "lackito-tf-state"
    key    = "otel-demo-infra-aws/dev/platform.tfstate"
    region = var.aws_region
  }
}

data "aws_eks_cluster" "this" {
  name = data.terraform_remote_state.platform.outputs.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = data.aws_eks_cluster.this.name
}

# Reuse the account-level provider; creating it again fails with HTTP 409.
data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  lifecycle {
    postcondition {
      condition     = contains(self.client_id_list, "sts.amazonaws.com")
      error_message = "The existing GitHub OIDC provider must include the sts.amazonaws.com audience. Update it through its account-level owner before applying layer 04."
    }
  }
}
