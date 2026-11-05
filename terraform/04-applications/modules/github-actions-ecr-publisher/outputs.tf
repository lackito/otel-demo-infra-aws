output "role_arn" {
  description = "IAM role ARN assumed by a GitHub Actions workflow."
  value       = aws_iam_role.this.arn
}
