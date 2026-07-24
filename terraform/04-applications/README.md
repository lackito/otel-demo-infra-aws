# 04 - Applications

## Overview

The **Applications** layer manages application-specific resources required for workloads running on the Amazon EKS platform.

This layer sits above:

```
01-bootstrap
        |
        v
02-infrastructure
        |
        v
03-platform
        |
        v
04-applications
```

The responsibility of this layer is intentionally limited to application prerequisites and supporting AWS resources.

Application deployment is handled through **GitOps using Argo CD**.

---

# Responsibilities

The Applications layer currently manages:

- Amazon ECR repositories
- Application container image lifecycle support
- Application-specific AWS resources
- GitHub Actions OIDC access for publishing application images

It does **not** directly deploy Kubernetes workloads.

---

# Architecture

```
┌──────────────────────────┐
│ Developer                │
│                          │
│ Application Source Code  │
└─────────────┬────────────┘
              |
              v
┌──────────────────────────┐
│ GitHub Actions           │
│                          │
│ Build Container Image    │
│ Push Image               │
└─────────────┬────────────┘
              |
              v
┌──────────────────────────┐
│ Amazon ECR               │
│                          │
│ recommendation:dev       │
└─────────────┬────────────┘
              |
              v
┌──────────────────────────┐
│ otel-demo-gitops           │
│                          │
│ Helm Values              │
│ ArgoCD Application       │
└─────────────┬────────────┘
              |
              v
┌──────────────────────────┐
│ Argo CD                  │
│                          │
│ Kubernetes Deployment    │
└──────────────────────────┘
```

---

# Repository Structure

```
04-applications/

├── environments/
│   └── dev/
│       ├── backend.tf
│       ├── locals.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── terraform.tfvars
│       ├── variables.tf
│       └── versions.tf
│
└── modules/
    └── ecr-repositories/
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

---

# Terraform Modules

## ECR Repositories

The current module creates and manages Amazon Elastic Container Registry repositories.

Example:

```hcl
repositories = [
  "recommendation"
]
```

Terraform manages:

- Repository creation
- Image scanning configuration
- Repository tagging

Example tags:

```text
Project     = ot-demo
Environment = dev
Layer       = applications
ManagedBy   = Terraform
```

---

# Recommendation CI/CD Identity

The `dev` environment creates a GitHub OIDC provider and a dedicated IAM role
for `lackito/otel-demo-apps` on the `main` branch. The role has only the ECR
permissions needed to publish to the existing `recommendation` repository.

After applying this layer, set the resulting
`recommendation_github_actions_role_arn` output as the `AWS_ROLE_TO_ASSUME`
secret in `otel-demo-apps`. The application workflow uses this short-lived OIDC
identity to build, publish, and update GitOps; it has no Kubernetes credentials.

# Current Application Images

## Recommendation Service

The recommendation service is the first application integrated into the deployment workflow.

ECR repository:

```
recommendation
```

Example image:

```
123456789012.dkr.ecr.us-east-1.amazonaws.com/recommendation:dev
```

Deployment flow:

```
Source Code
    |
    v
Docker Build
    |
    v
Amazon ECR
    |
    v
Argo CD
    |
    v
EKS Deployment
```

---

# GitOps Integration

Application deployment is managed by:

```
otel-demo-gitops
```

Repository structure:

```
otel-demo-gitops/

├── argocd/
│   └── applications/
│       └── otel-demo.yaml
│
└── applications/
    └── otel-demo/
        └── values.yaml
```

Argo CD consumes:

- OpenTelemetry Demo Helm chart
- Git-managed Helm values

Example image override:

```yaml
components:
  recommendation:
    imageOverride:
      repository: 123456789012.dkr.ecr.us-east-1.amazonaws.com/recommendation
      tag: dev
```

---

# Deployment Ownership

The project intentionally separates responsibilities:

| Layer | Responsibility |
|---|---|
| Terraform Infrastructure | AWS resources |
| Terraform Platform | Kubernetes platform services |
| Terraform Applications | Application prerequisites |
| GitHub Actions | Build and publish images |
| Argo CD | Kubernetes deployments |

---

# Deferred Applications

## Product Catalog

The original course implementation was evaluated but intentionally deferred.

Reason:

The course implementation uses a different architecture:

- Local `products/products.json`
- File-based product loading

The current OpenTelemetry Demo implementation expects:

- Database-backed product catalog
- PostgreSQL integration
- Different runtime configuration

Decision:

Product Catalog deployment is postponed until the architecture is aligned.

---

## Ad Service

The Ad service is also deferred.

Current priority:

1. Recommendation service
2. CI/CD pipeline validation
3. GitOps deployment workflow

---

# Dependencies

Before deploying this layer:

Required:

- AWS Account
- AWS CLI configured
- Terraform >= 1.13
- Existing Terraform backend
- EKS infrastructure deployed

Recommended:

- Docker installed
- GitHub repository configured
- ECR authentication configured

---

# Provider Versions

Current providers:

```hcl
terraform {
  required_version = ">= 1.13"

  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

---

# Deployment

Initialize:

```bash
terraform init
```

Validate:

```bash
terraform validate
```

Plan:

```bash
terraform plan
```

Apply:

```bash
terraform apply
```

---

# Validation

Verify ECR repositories:

```bash
aws ecr describe-repositories
```

Example:

```text
recommendation
```

---

Verify images:

```bash
aws ecr list-images \
--repository-name recommendation
```

Expected:

```text
dev
```

---

# Destroy

Recommended lifecycle:

```
Applications

↓

Platform

↓

Infrastructure

↓

Bootstrap
```

Destroy:

```bash
terraform destroy
```

Note:

Destroying this Terraform layer removes AWS application resources.

It does not automatically remove Kubernetes applications managed by Argo CD.

Those must be removed through GitOps/Argo CD first.

---

# Troubleshooting

## Repository already exists

Example:

```
RepositoryAlreadyExistsException
```

Cause:

The repository was created manually before Terraform management.

Solutions:

Import:

```bash
terraform import \
module.ecr_repositories.aws_ecr_repository.this["recommendation"] \
recommendation
```

or remove the existing repository.

---

## Image cannot be pulled by Kubernetes

Symptoms:

```
ImagePullBackOff
```

Check:

```bash
kubectl describe pod <pod-name>
```

Possible causes:

- Incorrect ECR repository URL
- Incorrect image tag
- Missing EKS permissions
- Image not pushed

---

# Design Principles

This layer follows:

- Separation of infrastructure and application lifecycle
- Immutable container images
- GitOps-based deployments
- Terraform-managed AWS resources
- Kubernetes ownership through Argo CD
- Environment-specific configuration

---

# Lessons Learned

During development:

- Application deployment ownership must be clearly separated.
- Terraform should not compete with Argo CD for Kubernetes ownership.
- Existing AWS resources should be imported before Terraform management.
- Container validation locally helps isolate application issues.
- The recommendation service provided the cleanest path for validating CI/CD and GitOps workflows.

---

# Future Enhancements

Potential additions:

- GitHub Actions CI pipeline
- Automated Docker image builds
- Automated ECR publishing
- Image version promotion strategy
- Security scanning integration
- SBOM generation
- Application deployment approvals
- Production environment support
