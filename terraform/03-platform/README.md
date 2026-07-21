# 03 - Platform

## Overview

The **Platform** layer installs shared Kubernetes services required by applications running on the Amazon EKS cluster created by the Infrastructure layer.

This layer sits between:

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

The purpose of this layer is to provide Kubernetes platform capabilities without coupling application deployments to AWS infrastructure details.

---

# Responsibilities

The Platform layer currently manages:

- AWS Load Balancer Controller
- IAM permissions required by Kubernetes workloads
- IRSA (IAM Roles for Service Accounts)
- Helm-based Kubernetes platform deployments
- Argo CD installation for GitOps workflows

---

# Architecture

```
┌──────────────────────────┐
│ 01-bootstrap             │
│                          │
│ S3 Backend               │
│ DynamoDB Locking         │
└─────────────┬────────────┘
              |
              v
┌──────────────────────────┐
│ 02-infrastructure        │
│                          │
│ VPC                      │
│ EKS Cluster              │
│ Managed Node Groups      │
│ IAM                      │
│ OIDC Provider            │
└─────────────┬────────────┘
              |
              v
┌──────────────────────────┐
│ 03-platform              │
│                          │
│ AWS LB Controller        │
│ IRSA                     │
│ Argo CD                  │
│ Helm Deployments         │
└─────────────┬────────────┘
              |
              v
┌──────────────────────────┐
│ 04-applications          │
│                          │
│ ECR                      │
│ Application Deployments  │
└──────────────────────────┘
```

---

# Repository Structure

```
03-platform/

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
├── modules/
│   │
│   ├── aws-load-balancer-controller/
│   │   ├── helm.tf
│   │   ├── iam_policy.json
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── service-account.tf
│   │   └── variables.tf
│   │
│   └── argocd/
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
│
└── README.md
```

---

# Terraform Modules

## AWS Load Balancer Controller

The module installs:

- AWS Load Balancer Controller Helm chart
- IAM Policy
- IAM Role
- IAM Role Policy Attachment
- Kubernetes Service Account

The controller uses **IRSA** instead of node-level IAM permissions.

Flow:

```
Kubernetes Service Account
            |
            v
        IRSA Trust
            |
            v
     IAM Role
            |
            v
 AWS Load Balancer Controller
            |
            v
 AWS APIs
```

---

## Argo CD

The Argo CD module installs the GitOps deployment engine.

Current configuration:

- Helm chart: `argo-cd`
- Repository:
  ```
  https://argoproj.github.io/argo-helm
  ```

- Namespace:
  ```
  argocd
  ```

Development configuration:

```yaml
server:
  service:
    type: ClusterIP

configs:
  params:
    server.insecure: true
```

Access is provided using Kubernetes port forwarding:

```bash
kubectl port-forward svc/argocd-server \
-n argocd \
8080:443
```

---

# Dependencies

Before deploying this layer:

Required:

- AWS Account
- AWS CLI configured
- Terraform >= 1.13
- kubectl
- Helm

The Infrastructure layer must already exist.

This layer consumes Terraform remote state outputs:

| Output | Usage |
|---|---|
| cluster_name | Kubernetes access |
| cluster_endpoint | Kubernetes provider |
| cluster_oidc_provider_arn | IRSA |
| cluster_oidc_issuer_url | IRSA |
| vpc_id | AWS Load Balancer Controller |

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

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
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

Update kubeconfig:

```bash
aws eks update-kubeconfig \
--region us-east-1 \
--name ot-demo-dev
```

---

## Verify AWS Load Balancer Controller

```bash
kubectl get deployment \
aws-load-balancer-controller \
-n kube-system
```

Expected:

```
READY   AVAILABLE
2/2
```

Verify pods:

```bash
kubectl get pods \
-n kube-system \
-l app.kubernetes.io/name=aws-load-balancer-controller
```

---

## Verify IRSA

```bash
kubectl get serviceaccount \
aws-load-balancer-controller \
-n kube-system \
-o yaml
```

Expected:

```yaml
annotations:
  eks.amazonaws.com/role-arn:
```

---

## Verify Argo CD

```bash
kubectl get pods -n argocd
```

Expected:

```
argocd-server
argocd-repo-server
argocd-application-controller
```

---

# GitOps Workflow

The deployment workflow is:

```
Developer
    |
    v
Application Repository
    |
    v
GitHub Actions
    |
    v
Container Image
    |
    v
Amazon ECR
    |
    v
GitOps Repository
    |
    v
Argo CD
    |
    v
Amazon EKS
```

The GitOps repository:

```
ot-demo-gitops
```

contains:

```
argocd/
 └── applications/
      └── otel-demo.yaml

applications/
 └── otel-demo/
      └── values.yaml
```

Argo CD manages application synchronization from Git.

---

# Destroy Procedure

Recommended order:

```
04-applications

↓

03-platform

↓

02-infrastructure

↓

01-bootstrap
```

Destroy this layer:

```bash
terraform destroy
```

Before destroying:

- Remove Argo CD managed applications
- Confirm workloads are removed
- Confirm no AWS resources depend on platform components

---

# Troubleshooting

## EKS recreated and IRSA fails

Symptoms:

```
AccessDenied
AssumeRoleWithWebIdentity
```

Cause:

The EKS OIDC provider changed.

Solution:

```bash
terraform apply
```

Terraform recreates IAM trust relationships.

---

## Existing IAM resources conflict

Symptoms:

```
EntityAlreadyExists
RepositoryAlreadyExists
```

Cause:

Resource exists outside Terraform management.

Solutions:

Import:

```bash
terraform import
```

or delete the existing resource.

---

## Argo CD cannot access Git repository

Symptoms:

```
Failed to load target state
failed to get git client
```

Possible causes:

- Incorrect repository URL
- Private repository without credentials
- Invalid Git reference

Validation:

```bash
kubectl get application \
-n argocd
```

---

# Design Principles

This project follows:

- Layered Terraform architecture
- Separate Terraform state per layer
- Infrastructure/platform/application separation
- Least privilege IAM
- IRSA instead of node permissions
- GitOps-based application delivery
- Environment-specific configuration
- Reproducible destroy/rebuild lifecycle

---

# Lessons Learned

During development:

- Recreating EKS changes the OIDC identity.
- Terraform state separation simplifies recovery.
- Existing AWS resources should be imported or removed before Terraform management.
- AWS Load Balancer Controller does not create load balancers by itself.
- Argo CD requires valid Git repository references.
- GitOps repositories should remain separate from infrastructure repositories.
- Application lifecycle ownership must be clear between Terraform and Argo CD.

---

# Future Enhancements

Potential platform additions:

- Metrics Server
- ExternalDNS
- cert-manager
- Cluster Autoscaler
- Karpenter
- External Secrets Operator
- Prometheus Operator
- Grafana Operator
- Network Policies
- Pod Security Standards
