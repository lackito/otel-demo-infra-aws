mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  oidc_provider_arn      = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  ecr_repository_arn     = "arn:aws:ecr:us-east-1:123456789012:repository/recommendation"
  github_owner           = "example"
  github_owner_id        = "123"
  github_repository_name = "otel-demo-apps"
  github_repository_id   = "456"
  github_branch          = "main"
  role_name              = "otel-demo-aws-dev-recommendation-github-actions"
}

run "reuse_shared_provider" {
  command = plan

  assert {
    condition     = output.oidc_provider_arn == var.oidc_provider_arn
    error_message = "Other publishers must receive the existing shared provider ARN."
  }

  assert {
    condition     = one(one(data.aws_iam_policy_document.github_actions_assume_role.statement).principals).identifiers == toset([var.oidc_provider_arn])
    error_message = "The Recommendation role must trust the existing provider ARN."
  }

  assert {
    condition     = aws_iam_role.this.name == var.role_name
    error_message = "Reusing OIDC must not rename the existing publisher role."
  }
}
