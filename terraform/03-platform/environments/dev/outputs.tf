output "cluster_name" {
  value = data.terraform_remote_state.infrastructure.outputs.cluster_name
}

output "cluster_endpoint" {
  value = data.terraform_remote_state.infrastructure.outputs.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  value = data.terraform_remote_state.infrastructure.outputs.cluster_oidc_issuer_url
}

output "vpc_id" {
  value = data.terraform_remote_state.infrastructure.outputs.vpc_id
}

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN used by AWS Load Balancer Controller"
  value       = module.aws_load_balancer_controller.role_arn
}
