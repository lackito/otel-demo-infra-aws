terraform {
  backend "s3" {
    bucket       = "lackito-tf-state"
    key          = "otel-demo-infra-aws/dev/platform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
