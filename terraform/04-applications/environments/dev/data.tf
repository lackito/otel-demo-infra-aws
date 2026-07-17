data "terraform_remote_state" "platform" {
  backend = "s3"

  config = {
    bucket = "20260710-tf-remote-state-bucket"
    key    = "ot-demo-tf/dev/platform.tfstate"
    region = var.aws_region
  }
}

data "aws_eks_cluster" "this" {
  name = data.terraform_remote_state.platform.outputs.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = data.aws_eks_cluster.this.name
}
