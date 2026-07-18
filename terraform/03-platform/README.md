# 03 - Platform

## Overview

The **Platform** layer installs shared Kubernetes platform services on the Amazon EKS cluster created by the Infrastructure layer.

Its primary responsibility is to prepare the Kubernetes platform so application teams can deploy workloads without requiring AWS-specific knowledge.

Currently this layer deploys the **AWS Load Balancer Controller**, which enables Kubernetes `Ingress` and `Service` resources to automatically provision AWS Elastic Load Balancers.

Keeping Platform separate from Infrastructure and Applications provides:

- Independent Terraform state
- Clear separation of responsibilities
- Reusable platform modules
- Easier upgrades and maintenance
- Cleaner destroy/rebuild lifecycle

---

# Architecture

```
┌──────────────────────────┐
│ 01-bootstrap             │
│ S3 Backend + DynamoDB    │
└─────────────┬────────────┘
              │
              ▼
┌──────────────────────────┐
│ 02-infrastructure        │
│                          │
│ • VPC                    │
│ • EKS Cluster            │
│ • Node Groups            │
│ • IAM                    │
└─────────────┬────────────┘
              │
              ▼
┌──────────────────────────┐
│ 03-platform              │
│                          │
│ • AWS LB Controller      │
│ • IRSA                   │
│ • Helm                   │
└─────────────┬────────────┘
              │
              ▼
┌──────────────────────────┐
│ 04-applications          │
│                          │
│ OpenTelemetry Demo       │
└──────────────────────────┘
```

---

# What This Layer Deploys

The Platform layer currently installs:

- AWS Load Balancer Controller Helm chart
- IAM Policy
- IAM Role
- IAM Role Policy Attachment
- Kubernetes Service Account
- IRSA (IAM Roles for Service Accounts)

Terraform creates the IAM resources while Helm installs the controller into the Kubernetes cluster.

---

# What This Layer Does **NOT** Do

A common misconception is that deploying this project immediately creates an AWS Application Load Balancer.

**It does not.**

This layer only installs the **AWS Load Balancer Controller** inside the Kubernetes cluster.

The controller continuously watches Kubernetes resources.

When an application later creates an:

- Ingress
- Service of type LoadBalancer

the controller automatically provisions the appropriate AWS resources, including:

- Application Load Balancer (ALB)
- Network Load Balancer (NLB)
- Target Groups
- Security Groups
- Listener Rules

In other words:

```
Terraform
     │
     ▼
AWS Load Balancer Controller
     │
     ▼
Kubernetes Ingress
     │
     ▼
AWS ALB
```

---

# Repository Structure

```
03-platform/
├── environments/
│   └── dev/
│       ├── backend.tf
│       ├── data.tf
│       ├── locals.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── terraform.tfvars
│       └── versions.tf
│
└── modules/
    └── aws-load-balancer-controller/
        ├── helm.tf
        ├── iam.tf
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

---

# Dependencies

Before deploying this layer the following must already exist.

- AWS Account
- AWS CLI configured
- kubectl installed
- Helm installed
- Terraform >= 1.13

Infrastructure layer must already be deployed.

This project consumes the following remote state outputs:

| Output | Purpose |
|---------|----------|
| cluster_name | EKS cluster |
| cluster_endpoint | Kubernetes provider |
| cluster_oidc_issuer_url | IRSA |
| cluster_oidc_provider_arn | IRSA |
| vpc_id | Load Balancer Controller |

---

# Configuration

Environment configuration lives in:

```
environments/dev/terraform.tfvars
```

Example:

```hcl
aws_region = "us-east-1"

helm_chart_version = "1.11.0"
```

---

# Deployment

Initialize Terraform.

```bash
terraform init
```

Validate.

```bash
terraform validate
```

Review changes.

```bash
terraform plan
```

Deploy.

```bash
terraform apply
```

---

# Validation

Update kubeconfig.

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name ot-demo-dev
```

Verify deployment.

```bash
kubectl get deployment \
aws-load-balancer-controller \
-n kube-system
```

Expected:

```
READY   UP-TO-DATE   AVAILABLE
2/2
```

---

Verify Pods.

```bash
kubectl get pods \
-n kube-system \
-l app.kubernetes.io/name=aws-load-balancer-controller
```

Expected:

```
2 Running
```

---

Verify Service Account.

```bash
kubectl get sa \
aws-load-balancer-controller \
-n kube-system \
-o yaml
```

Verify the annotation exists.

```yaml
annotations:
  eks.amazonaws.com/role-arn:
```

This confirms IRSA is correctly configured.

---

# Outputs

| Output | Description |
|---------|-------------|
| cluster_name | EKS cluster name |
| cluster_endpoint | Kubernetes API endpoint |
| cluster_oidc_issuer_url | OIDC issuer URL |
| vpc_id | Cluster VPC |
| aws_load_balancer_controller_role_arn | IAM Role used by IRSA |

---

# Troubleshooting

## kubectl points to an old cluster

Symptoms:

```
no such host
```

Update kubeconfig.

```bash
aws eks update-kubeconfig \
--region us-east-1 \
--name ot-demo-dev
```

---

## OIDC provider changed

Symptoms:

```
AccessDenied

AssumeRoleWithWebIdentity
```

Cause:

The EKS cluster was destroyed and recreated.

The OIDC provider changed.

Solution:

```bash
terraform apply
```

Terraform recreates the IAM trust relationship.

---

## IAM Policy already exists

Symptoms:

```
EntityAlreadyExists
```

Cause:

The IAM policy was previously created manually.

Solution:

Delete the manually created policy or import it into Terraform state.

---

## Helm deployment timeout

Symptoms:

```
context deadline exceeded
```

Increase:

```hcl
timeout = 600
```

The Helm provider expects the timeout value in **seconds**, not as a string such as `"10m"`.

---

# Destroy

Destroy resources in the following order.

```
04-applications

↓

03-platform

↓

02-infrastructure

↓

01-bootstrap (optional)
```

Destroy the Platform layer.

```bash
terraform destroy
```

---

# Design Principles

- Layered Terraform architecture
- Independent Terraform state
- Modular design
- Infrastructure consumed through Remote State
- Least privilege IAM
- IRSA instead of node IAM permissions
- Reusable Terraform modules
- Environment-specific configuration

---

# Future Enhancements

Potential platform components include:

- Metrics Server
- ExternalDNS
- cert-manager
- Cluster Autoscaler
- Karpenter
- ArgoCD
- NGINX Ingress Controller
- External Secrets Operator
- Prometheus Operator
- Grafana Operator

---

# Lessons Learned

During development of this project the following real-world scenarios were encountered and resolved:

- EKS recreation changes the cluster OIDC provider
- IRSA trust relationships must be updated after cluster recreation
- `kubectl` must be reconfigured after EKS rebuilds
- Helm provider syntax differs between provider versions
- Helm timeout values are specified in seconds
- Existing IAM resources can conflict with Terraform-managed resources
- Installing the AWS Load Balancer Controller **does not** immediately create an AWS Application Load Balancer

These troubleshooting experiences have been intentionally documented to help others deploying the project and to serve as operational runbooks for future maintenance.
