output "role_arn" {
  description = "IAM role ARN assumed by the recommendation GitHub Actions workflow."
  value       = aws_iam_role.this.arn
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github_actions.arn
}
