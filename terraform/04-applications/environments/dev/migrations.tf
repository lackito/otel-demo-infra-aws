# Keep the existing Recommendation role and inline policy when consolidating
# publishers under the shared module. Retain these blocks for older states.
moved {
  from = module.recommendation_github_actions.aws_iam_role.this
  to   = module.service_github_actions["recommendation"].aws_iam_role.this
}

moved {
  from = module.recommendation_github_actions.aws_iam_role_policy.ecr_push
  to   = module.service_github_actions["recommendation"].aws_iam_role_policy.ecr_push
}

# The former Recommendation module once owned the account-wide provider.
# Preserve it if an older state still contains that binding.
removed {
  from = module.recommendation_github_actions.aws_iam_openid_connect_provider.github_actions

  lifecycle {
    destroy = false
  }
}
