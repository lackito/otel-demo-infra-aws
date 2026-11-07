mock_provider "aws" {}

variables {
  repositories = {
    recommendation  = {}
    ad              = { image_tag_mutability = "IMMUTABLE" }
    product-catalog = { image_tag_mutability = "IMMUTABLE" }
    checkout        = { image_tag_mutability = "IMMUTABLE" }
    frontend        = {}
  }
}

run "retain_images_by_default" {
  command = plan

  assert {
    condition     = alltrue([for repository in aws_ecr_repository.this : !repository.force_delete])
    error_message = "The reusable module must not enable destructive image cleanup by default."
  }
}

run "delete_images_for_disposable_environment" {
  command = plan

  variables {
    force_delete = true
  }

  assert {
    condition     = length(aws_ecr_repository.this) == 5 && alltrue([for repository in aws_ecr_repository.this : repository.force_delete])
    error_message = "The dev opt-in must enable cleanup on all five configured repositories."
  }

  assert {
    condition     = aws_ecr_repository.this["ad"].image_tag_mutability == "IMMUTABLE" && aws_ecr_repository.this["product-catalog"].image_tag_mutability == "IMMUTABLE"
    error_message = "Image cleanup must not change the service tag immutability settings."
  }
}
