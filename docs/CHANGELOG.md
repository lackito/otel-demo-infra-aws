# Changelog

All notable changes to this project are documented in this file.

This project follows a milestone-based changelog approach rather than strict semantic versioning because infrastructure changes span multiple repositories and deployment layers.

---

# [Unreleased]

## Planned

### CI/CD Automation

- Create GitHub Actions workflow for application builds.
- Build Docker images automatically.
- Push images to Amazon ECR.
- Update GitOps repository image references.
- Allow Argo CD to automatically deploy updated versions.

### Security Enhancements

Planned improvements:

- Container vulnerability scanning.
- Software Bill of Materials (SBOM) generation.
- Image signing.
- Security policy enforcement.

### Application Improvements

Planned:

- Integrate Product Catalog service.
- Integrate Ad service.
- Validate additional OpenTelemetry Demo components.
- Establish promotion workflow between environments.

---

# [0.1.0] - Initial Platform Foundation

## Overview

Established the foundational AWS, Kubernetes, Terraform, and GitOps architecture for the OpenTelemetry Demo deployment.

Major accomplishments:

- Created layered Terraform architecture.
- Provisioned Amazon EKS infrastructure.
- Installed Kubernetes platform components.
- Implemented Argo CD GitOps workflow.
- Successfully deployed Recommendation service.

---

# Infrastructure Layer

Repository:

```text
ot-demo-tf
```

Terraform layers created:

```text
01-bootstrap
02-infrastructure
03-platform
04-applications
```

---

## 01-bootstrap

Implemented Terraform backend foundation.

Created:

- Amazon S3 Terraform state storage.
- DynamoDB state locking.

Purpose:

- Remote Terraform state management.
- Safe team collaboration.
- State consistency.

---

# 02-infrastructure

## Amazon VPC

Created AWS networking foundation:

- VPC.
- Public subnets.
- Private subnets.
- Route tables.
- Internet Gateway.
- NAT Gateway.

---

## Amazon EKS

Provisioned:

- Amazon EKS cluster.
- Managed node groups.
- IAM roles.
- Kubernetes API access.
- OIDC provider.

Current cluster:

```text
Cluster:
ot-demo-dev

Region:
us-east-1
```

---

## Terraform Remote State

Implemented dependency flow:

```text
02-infrastructure
        |
        v
03-platform
        |
        v
04-applications
```

Platform and application layers consume infrastructure outputs through Terraform remote state.

---

# 03-platform

## AWS Load Balancer Controller

Implemented Kubernetes AWS integration.

Created:

- IAM Policy.
- IAM Role.
- IAM Role Policy Attachment.
- Kubernetes Service Account.
- IRSA configuration.
- Helm deployment.

Purpose:

Allow Kubernetes workloads to provision AWS load balancing resources.

Architecture:

```text
Kubernetes Ingress
        |
        v
AWS Load Balancer Controller
        |
        v
AWS ALB/NLB
```

---

## Argo CD Installation

Added GitOps deployment capability.

Installed:

- Argo CD Helm chart.

Namespace:

```text
argocd
```

Configuration:

- ClusterIP service.
- Insecure development mode.
- Port-forward access.

Purpose:

Move Kubernetes application ownership from Terraform to GitOps.

---

# 04-applications

## Amazon ECR

Implemented application container registry management.

Created:

```text
recommendation
```

Repository configuration:

- Terraform managed.
- Image scanning enabled.
- Environment tagging applied.

Example image:

```text
123456789012.dkr.ecr.us-east-1.amazonaws.com/recommendation:dev
```

---

# GitOps Repository

Repository:

```text
ot-demo-gitops
```

Purpose:

Store Kubernetes desired state.

Created:

```text
argocd/
└── applications/
    └── otel-demo.yaml

applications/
└── otel-demo/
    └── values.yaml
```

---

## Argo CD Application

Implemented:

- Helm chart source from OpenTelemetry repository.
- Git repository value overrides.
- Automated synchronization.
- Self-healing.
- Pruning.

Deployment flow:

```text
Git Repository
       |
       v
Argo CD
       |
       v
Amazon EKS
```

---

# Recommendation Service

## Deployment Validation

Successfully validated:

- Docker image creation.
- ECR push.
- Kubernetes deployment.
- Argo CD synchronization.

Application image:

```text
recommendation:dev
```

Deployment path:

```text
Source Code
      |
      v
Docker Build
      |
      v
Amazon ECR
      |
      v
GitOps Values
      |
      v
Argo CD
      |
      v
EKS
```

---

# Important Architecture Decisions

## Terraform vs Argo CD Ownership

Decision:

Terraform manages:

- AWS resources.
- Kubernetes platform components.

Argo CD manages:

- Kubernetes applications.

Reason:

Avoid multiple tools managing the same Kubernetes resources.

---

## Product Catalog Decision

The course implementation was reviewed and intentionally deferred.

The course version uses:

```text
products/products.json
```

The OpenTelemetry Demo architecture expects:

```text
PostgreSQL-backed product catalog
```

Decision:

Do not deploy until implementation matches the target architecture.

---

## Ad Service Decision

Deferred.

Priority remains:

1. Recommendation service.
2. CI/CD automation.
3. GitOps workflow.
4. Additional applications.

---

# Lessons Learned

## EKS Recreation

Destroying and recreating EKS changes:

- Cluster identity.
- OIDC provider.

Impact:

IRSA trust relationships must be recreated.

---

## Terraform Resource Conflicts

Manually created AWS resources cause conflicts:

Examples:

```text
RepositoryAlreadyExistsException
EntityAlreadyExists
```

Solution:

Either:

- Import into Terraform state.
- Delete and allow Terraform ownership.

---

## Helm Provider Changes

Provider versions affect:

- Syntax.
- Resource behavior.
- Timeout handling.

Current providers:

```hcl
aws        ~> 6.0
kubernetes ~> 2.38
helm       ~> 3.0
```

---

## GitOps Repository Access

Argo CD requires:

- Correct repository URL.
- Authentication for private repositories.

Public repository access simplified initial setup.

---

# Current Project Status

Completed:

✅ Terraform backend  
✅ AWS infrastructure  
✅ Amazon EKS  
✅ Kubernetes platform  
✅ AWS Load Balancer Controller  
✅ IRSA  
✅ Amazon ECR  
✅ Argo CD  
✅ GitOps repository  
✅ Recommendation service deployment  

Current state:

```text
Infrastructure:
READY

Platform:
READY

GitOps:
READY

Applications:
PARTIAL
```

---

# Next Development Phase

## CI/CD Pipeline

Target workflow:

```text
Developer Commit
        |
        v
GitHub Actions
        |
        v
Docker Build
        |
        v
Amazon ECR
        |
        v
Update GitOps Repository
        |
        v
Argo CD Sync
        |
        v
Amazon EKS
```

---

# Version History

| Version | Date | Description |
|---|---|---|
| 0.1.0 | 2026-07 | Initial AWS, Terraform, Kubernetes, Argo CD, and GitOps foundation |

---

# Repository Documentation

Related documentation:

```text
docs/
├── PROJECT_CONTEXT.md
└── CHANGELOG.md

ot-demo-tf/
├── terraform/
│   ├── 02-infrastructure/
│   ├── 03-platform/
│   └── 04-applications/

ot-demo-gitops/
└── README.md
```
