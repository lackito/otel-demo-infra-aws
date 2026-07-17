module "otel_demo" {

  source = "../../modules/otel-demo"

  cluster_name = data.terraform_remote_state.platform.outputs.cluster_name

}
