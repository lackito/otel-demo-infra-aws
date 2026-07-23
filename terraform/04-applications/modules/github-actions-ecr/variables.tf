variable "ecr_repository_arn" {
  description = "ARN of the ECR repository the workflow may publish to."
  type        = string
}

variable "github_owner"           { type = string }
variable "github_owner_id"        { type = string }
variable "github_repository_name" { type = string }
variable "github_repository_id"   { type = string }
variable "github_branch"          { type = string }

variable "role_name" {
  description = "Name of the IAM role for GitHub Actions."
  type        = string
}

variable "tags" {
  description = "Tags applied to created IAM resources."
  type        = map(string)
  default     = {}
}
