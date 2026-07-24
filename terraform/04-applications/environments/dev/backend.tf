terraform {
  backend "s3" {
    bucket       = "lackito-tf-state"
    key          = "otel-demo-infra-aws/dev/applications.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
