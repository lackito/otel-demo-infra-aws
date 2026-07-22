output "role_arn" {
  description = "IAM role ARN assumed by the recommendation GitHub Actions workflow."
  value       = aws_iam_role.this.arn
}
