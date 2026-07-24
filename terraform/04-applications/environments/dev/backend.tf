terraform {
  backend "s3" {
    bucket       = "20260710-tf-remote-state-bucket"
    key          = "otel-demo-infra-aws/dev/applications.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
