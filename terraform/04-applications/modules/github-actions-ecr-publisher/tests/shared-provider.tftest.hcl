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
    condition     = one(one(data.aws_iam_policy_document.github_actions_assume_role.statement).principals).identifiers == toset([var.oidc_provider_arn])
    error_message = "Each publisher must trust the existing provider ARN."
  }

  assert {
    condition     = aws_iam_role.this.name == var.role_name
    error_message = "The publisher role must use its configured service role name."
  }
}

run "all_publishers_use_oidc_only_trust" {
  command = plan

  assert {
    condition     = one(data.aws_iam_policy_document.github_actions_assume_role.statement).actions == toset(["sts:AssumeRoleWithWebIdentity"])
    error_message = "All publishers must use the same OIDC-only trust actions."
  }
}
