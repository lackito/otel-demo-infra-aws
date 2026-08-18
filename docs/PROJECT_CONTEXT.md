# PROJECT_CONTEXT.md

# OpenTelemetry Demo on AWS EKS
## Project Context

Last Updated: July 2026

---

# Project Goal

This project evolved beyond the original Udemy course into a production-style DevOps implementation.

Instead of deploying the OpenTelemetry Demo directly from Terraform, the project now follows a layered infrastructure architecture using GitOps with Argo CD and CI/CD with GitHub Actions.

The project demonstrates:

- Infrastructure as Code with Terraform
- Kubernetes on Amazon EKS
- GitOps with Argo CD
- CI/CD with GitHub Actions
- Secure AWS authentication using GitHub OIDC
- Private container registry using Amazon ECR
- Production-style layered Terraform architecture
- Modular infrastructure design
- End-to-end automated application deployment

---

# Repositories

## 1. otel-demo-infra-aws

Infrastructure repository.

Responsible for:

- Terraform backend
- AWS infrastructure
- Kubernetes platform
- Application AWS resources
- Project documentation

Terraform layers:

```
01-bootstrap
02-infrastructure
03-platform
04-applications
```

---

## 2. otel-demo-gitops

GitOps repository.

Contains:

- Argo CD Applications
- Helm value overrides
- Kubernetes desired state

Terraform never deploys workloads.

Argo CD owns workloads.

---

## 3. otel-demo-apps

Application source repository.

Contains customized OpenTelemetry services.

Currently customized:

- recommendation

Deferred:

- product-catalog
- ad

---

# High-Level Architecture

```
Developer
    │
    ▼
GitHub Commit
    │
    ▼
GitHub Actions
    │
    ▼
Build Recommendation Image
    │
    ▼
Push to Amazon ECR
    │
    ▼
Update GitOps values.yaml
    │
    ▼
Commit to otel-demo-gitops
    │
    ▼
Argo CD detects Git change
    │
    ▼
Deploys to Amazon EKS
```

Terraform provisions infrastructure only.

Argo CD deploys Kubernetes workloads.

---

# Terraform Layering

## 01-bootstrap

Purpose

Creates the Terraform backend.

Resources

- Amazon S3 bucket
- Versioning
- Server-side encryption
- Public access block
- Native S3 lock file support

Notes

The project originally used DynamoDB locking.

It now uses Terraform native S3 lock files (`use_lockfile = true`).

Independent state.

---

## 02-infrastructure

Creates AWS infrastructure.

Resources

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

Outputs consumed by downstream layers:

- cluster_name
- cluster_endpoint
- cluster_ca_certificate
- cluster_oidc_issuer_url
- cluster_oidc_provider_arn
- vpc_id

Independent Terraform state.

---

## 03-platform

Deploys Kubernetes platform services.

Current components:

- AWS Load Balancer Controller
- IRSA
- Argo CD
- Terraform-managed Argo CD Application registration

Managed using:

- Terraform
- Helm Provider
- Kubernetes Provider

Important:

Terraform installs Argo CD.

Terraform also creates the Argo CD Application CRD.

Argo CD then owns all application workloads.

---

## 04-applications

Only provisions AWS resources required by applications.

Current resources:

Amazon ECR

Repositories:

- recommendation

No Kubernetes workloads are managed here.

Independent Terraform state.

---

# Terraform Modules

## 03-platform/modules

- aws-load-balancer-controller
- argocd
- argocd-application

Future

- metrics-server
- external-dns
- cert-manager
- karpenter
- external-secrets

---

## 04-applications/modules

- ecr-repositories

---

# AWS Resources

Infrastructure

- VPC
- Subnets
- Route Tables
- Internet Gateway
- NAT Gateway
- Amazon EKS
- IAM
- OIDC

Platform

- AWS Load Balancer Controller
- IRSA
- Argo CD

Applications

- Amazon ECR

Repository

recommendation

---

# Kubernetes

Namespaces

- kube-system
- argocd
- opentelemetry-demo

Argo CD

Installed by Terraform.

Application registration

Installed by Terraform.

Workloads

Managed exclusively by Argo CD.

---

# Argo CD

Installed through Terraform.

GitOps repository

```
otel-demo-gitops
```

Application

```
otel-demo
```

Application source

```
applications/otel-demo
```

Repository

```
https://github.com/lackito/otel-demo-gitops.git
```

Branch

```
main
```

Sync Policy

- Automated
- Self Heal
- Prune
- CreateNamespace

Application registration is managed through Terraform using the Kubernetes provider.

---

# GitOps Repository

Repository

```
otel-demo-gitops
```

Structure

```
applications/
└── otel-demo/
    └── values.yaml

argocd/
└── applications/
    └── otel-demo.yaml
```

The Terraform applications stage registers the Argo CD Application, while its
declarative YAML definition remains documented in the GitOps repository.

The Argo CD Application points directly at:

```
applications/otel-demo
```

This directory contains the desired state consumed by Argo CD.

---

# Recommendation Service

Customized service.

Source

```
otel-demo-apps/apps/recommendation
```

Container Registry

Amazon ECR

Image

```
recommendation:<git-sha>
```

Successfully deployed through GitOps.

---

# CI/CD Pipeline

Repository

```
otel-demo-apps
```

Workflow

```
recommendation-release.yaml
```

Pipeline

```
Developer Commit

↓

GitHub Actions

↓

Authenticate to AWS (OIDC)

↓

Build Docker Image

↓

Push Image to Amazon ECR

↓

Clone GitOps Repository

↓

Update values.yaml

↓

Commit & Push

↓

Argo CD detects Git change

↓

Deploy Updated Application
```

Authentication

GitHub OIDC

Repository access

Fine-grained GitHub Personal Access Token

---

# Provider Versions

Terraform

>= 1.13

Providers

AWS

```
~> 6.0
```

Kubernetes

```
~> 2.38
```

Helm

```
~> 3.0
```

---

# Remote State

Each Terraform layer maintains independent state.

Dependency flow

```
01-bootstrap

↓

02-infrastructure

↓

03-platform

↓

04-applications
```

Platform reads Infrastructure outputs.

Applications read Infrastructure outputs.

Backend

Amazon S3

Locking

Native S3 lock file.

---

# Deployment Order

```
01-bootstrap

↓

02-infrastructure

↓

03-platform

↓

04-applications

↓

GitHub Actions

↓

GitOps Repository

↓

Argo CD

↓

Running Workloads
```

---

# Destroy Order

```
Delete Argo CD Applications (optional)

↓

03-platform

↓

02-infrastructure

↓

01-bootstrap (optional)

04-applications usually remains to preserve ECR images.
```

---

# Important Design Decisions

Terraform owns:

- AWS resources
- Platform services
- Argo CD installation
- Argo CD Application registration

Argo CD owns:

- Kubernetes workloads

Applications remain cloud-agnostic.

Only infrastructure is AWS-specific.

Recommendation image stored in Amazon ECR.

Platform installs cluster services.

Applications layer only provisions AWS resources.

---

# Lessons Learned

- EKS recreation changes OIDC provider.
- IRSA trust relationships must be recreated after cluster rebuild.
- kubectl context must be refreshed after EKS recreation.
- Helm provider timeout values use seconds.
- Existing IAM resources may require import or deletion.
- Argo CD Applications are Kubernetes CRDs.
- A Healthy Argo CD Application does not guarantee workloads exist.
- Correct GitOps repository path is critical.
- ECR must contain the image before Argo CD can deploy.
- GitOps updates desired state; Argo CD performs deployment.
- Native S3 locking replaces DynamoDB for Terraform state locking.
- Treating infrastructure as disposable validates Infrastructure as Code completeness.

---

# Known Issues

Deferred

- Product Catalog customization
- Ad service customization

Future

- ALB Ingress
- External DNS
- cert-manager
- HTTPS
- Production monitoring
- Autoscaling

---

# Current Project Status

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

Remaining

- Product Catalog
- Ad Service
- Local Kubernetes implementation

---

# Next Major Project

Create a local Kubernetes implementation.

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
- Compare AWS vs Local implementations

---

# Resume Checklist

If continuing development in a future conversation:

1. Deploy Bootstrap
2. Deploy Infrastructure
3. Deploy Platform
4. Verify Argo CD
5. Verify Argo CD Application
6. Verify Recommendation image exists in Amazon ECR
7. Push application change
8. Verify GitHub Actions
9. Verify GitOps commit
10. Verify Argo CD automatic deployment
11. Continue Product Catalog or Local Kubernetes implementation
