# AWS EKS Operations Guide

Detailed deployment procedures, architecture notes, and project milestones.
Return to the [project overview](../README.md).

This project deploys the OpenTelemetry Demo application on Amazon EKS using a fully automated GitOps workflow.

---

# Documentation

- **[README.md](../README.md)** — Project overview and architecture
- **[docs/PROJECT_WALKTHROUGH.md](PROJECT_WALKTHROUGH.md)** — High-level explanation of how everything works
- **[docs/PROJECT_CONTEXT.md](PROJECT_CONTEXT.md)** — Complete project context for continuing development
- **[docs/CHANGELOG.md](CHANGELOG.md)** — Major milestones and project history

---

# Project Overview

The goal of this project is to demonstrate an enterprise-style deployment workflow:

1. Infrastructure is created using Terraform.
2. Kubernetes platform components are installed.
3. Argo CD is configured to manage applications.
4. Developers push application code.
5. GitHub Actions builds and publishes container images.
6. GitOps repositories are updated automatically.
7. Argo CD detects changes and deploys workloads to Kubernetes.

Application releases follow the GitOps workflow; Terraform manages infrastructure
and platform changes.

Git is the source of truth.

---

# Architecture

```
                         Developer

                            |
                            |
                         git push

                            |
                            v

                    GitHub Actions
                            |
                            |
              +-------------+-------------+
              |                           |
              v                           v

          Docker Build              GitOps Update

              |                           |
              v                           v

        Amazon ECR              otel-demo-gitops Repository

                                          |
                                          |
                                          v

                                      Argo CD

                                          |
                                          |
                                          v

                                  Amazon EKS Cluster

                                          |
                                          |
                                          v

                              OpenTelemetry Demo Application
```

---

# Repository Structure

The project is separated into independent repositories.

## Infrastructure Repository

```
otel-demo-infra-aws
```

Contains the AWS implementation’s Terraform code.

```
otel-demo-infra-aws
|
└── terraform
    ├── 01-bootstrap
    ├── 02-infrastructure
    ├── 03-platform
    └── 04-applications
```

---

## GitOps Repository

```
otel-demo-gitops
```

Contains Kubernetes desired state.

```
otel-demo-gitops

├── applications
│   └── otel-demo
│       └── values.yaml
│
└── argocd
    └── applications
        └── otel-demo.yaml
```

---

## Application Repository

```
otel-demo-apps
```

Contains application source code and CI/CD workflows.

Example:

```
otel-demo-apps

├── apps
│   └── recommendation
│
└── .github
    └── workflows
        └── recommendation-release.yml
```

---

# Terraform Layers

## 01 - Bootstrap

Creates Terraform backend resources.

Examples:

- S3 Terraform state bucket
- S3-native state locking through `use_lockfile = true` in downstream backends

Purpose:

Provide centralized Terraform state management.

---

# 02 - Infrastructure

Creates AWS infrastructure.

Responsibilities:

- VPC
- Networking
- Subnets
- Security Groups
- Amazon EKS Cluster
- Worker Nodes
- IAM configuration

Result:

A running Kubernetes cluster.

---

# 03 - Platform

Installs shared Kubernetes platform services.

Current components:

- AWS Load Balancer Controller
- IAM Role for Service Accounts (IRSA)
- Argo CD
- Helm-based Kubernetes platform deployments

Purpose:

Prepare Kubernetes for application workloads.

---

# 04 - Applications

Bootstraps application delivery.

Responsibilities:

- Create ECR repositories
- Configure GitHub Actions IAM permissions
- Register Argo CD Applications

Argo CD manages application deployment.

---

# GitOps Workflow

## Application Development

Developer changes code:

```
apps/recommendation
```

and pushes:

```
git push
```

---

## Continuous Integration

GitHub Actions:

1. Checks out source code
2. Authenticates with AWS using OIDC
3. Builds Docker image
4. Pushes image to Amazon ECR
5. Updates GitOps values file
6. Commits GitOps change

Example:

Before:

```yaml
image:
  tag: old-version
```

After:

```yaml
image:
  tag: new-git-sha
```

---

## Continuous Deployment

Argo CD detects the GitOps repository change.

Argo CD:

1. Pulls latest configuration
2. Renders Helm chart
3. Applies Kubernetes resources
4. Maintains desired state

---

# Technologies Used

## Cloud

- AWS
- Amazon EKS
- Amazon ECR
- IAM
- VPC

## Infrastructure as Code

- Terraform
- Terraform Remote State
- Terraform Modules

## Kubernetes

- Kubernetes
- Helm
- Argo CD

## CI/CD

- GitHub Actions
- GitHub OIDC Authentication

## Observability

- OpenTelemetry Demo
- Prometheus
- Grafana
- Jaeger

---

# Deployment Process

## Deploy Infrastructure

First provision or verify the `01-bootstrap` state backend. Then run the
remaining Terraform layers in order:

```
02-infrastructure

↓

03-platform

↓

04-applications
```

---

## Verify EKS

Update kubeconfig:

```bash
aws eks update-kubeconfig \
--region us-east-1 \
--name otel-demo-dev
```

Check nodes:

```bash
kubectl get nodes
```

---

## Verify Argo CD

```bash
kubectl get applications -n argocd
```

Expected:

```
NAME        SYNC STATUS   HEALTH STATUS

otel-demo   Synced        Healthy
```

---

## Verify Application

```bash
kubectl get pods \
-n opentelemetry-demo
```

Expected:

All services running.

---

# Destroy Procedure

Destroy workloads and dependent resources before their supporting layers.
Review Argo CD application deletion behavior and confirm workload-created load
balancers are removed before tearing down the controller or cluster.

The dependency order is reversed for teardown:

```
04-applications

↓

03-platform

↓

02-infrastructure

↓

01-bootstrap
```

Why?

Higher layers depend on lower layers. Retain `01-bootstrap` and its state bucket
for ordinary environment teardown. Remove the backend only for permanent
retirement, after dependent resources are gone and needed state is preserved.
A versioned S3 bucket may require separate cleanup; the sequence is not a
single-command destruction procedure.

---

# Important Design Decisions

## GitOps over direct Kubernetes deployment

Applications are not deployed using:

```
kubectl apply
```

or:

```
helm upgrade
```

Git is the source of truth.

---

## Terraform manages infrastructure

Terraform creates:

- AWS resources
- Kubernetes platform components
- Argo CD registration

Terraform does not manage application releases.

---

## Argo CD manages applications

Argo CD owns:

- Helm rendering
- Kubernetes synchronization
- Application lifecycle

---

## IRSA instead of node IAM permissions

AWS permissions are attached to Kubernetes service accounts instead of worker nodes.

Benefits:

- Least privilege
- Better security isolation
- AWS recommended approach

---

# Lessons Learned

During development several real-world issues were encountered:

- Terraform state must be separated by lifecycle layer
- EKS recreation changes OIDC providers
- kubectl contexts must be refreshed after cluster recreation
- Helm provider versions affect syntax
- Argo CD Applications require correct source configuration
- A Git repository containing only values.yaml cannot deploy without a Helm chart source
- Multi-source Argo CD Applications are required when combining external Helm charts with Git-managed values
- GitHub Actions must update GitOps repositories, not Kubernetes directly

---

# Future Improvements

Possible enhancements:

- Add production environment
- Add ApplicationSet for multiple applications
- Add automated testing stages
- Add security scanning gates
- Add Terraform CI validation
- Add Helm chart customization
- Add External Secrets Operator
- Add cert-manager
- Add Karpenter autoscaling
- Add monitoring dashboards

---

# Project Status

Recorded implementation milestones (verify current deployment separately):

✅ AWS infrastructure automated with Terraform  
✅ Amazon EKS cluster deployed  
✅ Kubernetes platform configured  
✅ AWS Load Balancer Controller installed  
✅ Argo CD installed  
✅ OpenTelemetry Demo deployed through GitOps  
✅ GitHub Actions builds and publishes images  
✅ GitOps image promotion workflow working  
✅ Argo CD automatically synchronizes deployments  

The project records a completed GitOps delivery path. Verify the current
workflow run, GitOps revision, and cluster health before treating it as live.
