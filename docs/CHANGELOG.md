# CHANGELOG.md

# Changelog

All notable changes to this project are documented in this file.

This project follows a milestone-based approach rather than strict semantic versioning during development.

---

# Version 1.0.0
## Complete AWS DevOps / GitOps Implementation

Release Date: July 2026

This release represents the completion of the first major milestone of the project.

The project now demonstrates a complete production-style DevOps workflow using Terraform, Amazon EKS, Argo CD, GitHub Actions, GitOps, and Amazon ECR.

---

# Highlights

✅ Layered Terraform architecture

✅ Amazon EKS deployment

✅ GitOps with Argo CD

✅ GitHub Actions CI/CD

✅ GitHub OIDC authentication

✅ Amazon ECR integration

✅ Automated image promotion

✅ End-to-end automated deployment

---

# Repository Restructuring

Repository names standardized.

Renamed

```
ot-demo-tf
```

to

```
otel-demo-infra-aws
```

Repository layout finalized.

```
otel-demo-infra-aws
otel-demo-apps
otel-demo-gitops
```

Infrastructure repository now clearly represents the AWS implementation while allowing future local or cloud-specific variants.

---

# Documentation

Added

- PROJECT_CONTEXT.md
- CHANGELOG.md

Updated

- Root README
- 02-infrastructure README
- 03-platform README
- 04-applications README
- otel-demo-gitops README

Created

- PROJECT_WALKTHROUGH.md

Documentation now explains:

- architecture
- deployment flow
- GitOps workflow
- CI/CD pipeline
- infrastructure layering
- troubleshooting
- lessons learned

---

# Terraform

Completed layered architecture.

```
01-bootstrap

↓

02-infrastructure

↓

03-platform

↓

04-applications
```

Each layer now maintains independent Terraform state.

---

# Bootstrap

Implemented

- Amazon S3 backend
- Versioning
- Encryption
- Public access block

Migrated from DynamoDB locking to Terraform native S3 lock files.

Backend now uses:

```
use_lockfile = true
```

Simplifying backend infrastructure.

---

# Infrastructure

Completed

- VPC
- Public Subnets
- Private Subnets
- Internet Gateway
- NAT Gateway
- Route Tables
- Amazon EKS
- Managed Node Groups
- IAM Roles
- OIDC Provider

Published remote-state outputs consumed by downstream layers.

---

# Platform

Implemented

AWS Load Balancer Controller

Implemented IRSA

Installed Argo CD

Added Terraform-managed Argo CD Application registration.

Terraform now automatically creates:

```
Application
otel-demo
```

inside the cluster.

---

# Applications

Created dedicated applications layer.

Current AWS resources:

Amazon ECR

Repositories

- recommendation

Kubernetes workloads intentionally remain outside Terraform ownership.

---

# GitOps

Completed repository structure.

```
applications/
└── otel-demo/
    └── values.yaml

argocd/
└── applications/
    └── otel-demo.yaml
```

Argo CD now watches

```
applications/otel-demo
```

instead of the repository root.

Desired state is fully Git-driven.

---

# GitHub Actions

Implemented production-style deployment pipeline.

Workflow

```
recommendation-release.yaml
```

Pipeline

```
Commit

↓

Build Docker Image

↓

Authenticate using GitHub OIDC

↓

Push Image to Amazon ECR

↓

Clone GitOps Repository

↓

Update values.yaml

↓

Commit

↓

Push

↓

Argo CD Sync

↓

Deploy
```

---

# Authentication

AWS authentication migrated to GitHub OIDC.

Benefits

- No long-lived AWS credentials
- Short-lived credentials
- Least privilege
- Production best practice

GitOps repository access implemented using a fine-grained GitHub Personal Access Token.

---

# Amazon ECR

Created dedicated repository.

```
recommendation
```

Recommendation service now publishes uniquely tagged container images using the Git commit SHA.

---

# Recommendation Service

Successfully customized.

Implemented

- Docker build
- Amazon ECR publishing
- GitOps image promotion
- Automatic Kubernetes deployment

End-to-end deployment validated successfully.

---

# Argo CD

Terraform now installs

- Argo CD
- Argo CD Application

Automatic sync enabled

- Self Heal
- Prune
- CreateNamespace

Validated successful synchronization from GitOps repository to Kubernetes.

---

# Kubernetes

Namespaces

- kube-system
- argocd
- opentelemetry-demo

Recommendation service successfully deployed through GitOps.

---

# Major Architectural Decisions

Terraform owns

- AWS resources
- Platform components
- Argo CD installation
- Argo CD Application registration

Argo CD owns

- Kubernetes workloads

Applications remain cloud-agnostic.

Infrastructure remains AWS-specific.

GitOps repository remains reusable.

---

# Troubleshooting & Lessons Learned

Resolved

## OIDC recreation

Destroying and recreating EKS changes the OIDC provider.

IRSA trust relationships must be recreated.

---

## kubectl configuration

Recreated EKS clusters require kubeconfig updates.

---

## Helm

Timeout values use seconds.

---

## IAM

Existing resources can conflict with Terraform-managed resources.

---

## Argo CD

Healthy Application does not necessarily mean workloads exist.

Root cause:

Application pointed to the wrong GitOps path.

Correct path:

```
applications/otel-demo
```

---

## GitOps

Updating GitOps desired state does not deploy images unless:

- Image exists in Amazon ECR
- Argo CD detects repository change
- Application watches the correct directory

---

## Recommendation deployment

ImagePullBackOff observed when ECR repository was empty.

Resolved by executing GitHub Actions pipeline.

---

## Terraform backend

Learned Terraform backend migration process.

Determined migration unnecessary for this project because infrastructure is intentionally destroyed between work sessions.

---

# Project Philosophy

Infrastructure is intentionally disposable.

Every development session validates:

- Terraform
- GitOps
- Argo CD
- GitHub Actions
- Documentation

Destroying and rebuilding the environment continuously verifies Infrastructure as Code completeness.

---

# Current Status

Infrastructure

✅ Complete

Platform

✅ Complete

GitOps

✅ Complete

CI/CD

✅ Complete

Recommendation Service

✅ Complete

End-to-End Deployment

✅ Complete

---

# Deferred Work

Application customization

- Product Catalog
- Ad Service

Platform enhancements

- cert-manager
- ExternalDNS
- HTTPS
- Karpenter
- External Secrets
- Metrics Server
- Monitoring improvements

---

# Next Milestone (Version 1.1)

Local Kubernetes implementation.

Target repository

```
otel-demo-local
```

Objectives

- kind cluster
- Local Docker registry
- Argo CD
- GitHub Actions
- Reuse existing application repository
- Reuse existing GitOps repository
- Compare AWS and Local implementations
- Reinforce Kubernetes knowledge by rebuilding the platform without managed AWS services

---

# Project Outcome

This project evolved from a guided course into a production-style DevOps portfolio project demonstrating:

- Infrastructure as Code
- Kubernetes
- GitOps
- CI/CD
- Cloud Infrastructure
- Secure Authentication
- Container Registries
- Automated Deployments
- Operational Troubleshooting
- Production Architecture
- Documentation and Knowledge Transfer
