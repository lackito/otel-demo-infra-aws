output "role_arn" {
  description = "IAM role ARN used by AWS Load Balancer Controller"
  value       = aws_iam_role.this.arn
}
