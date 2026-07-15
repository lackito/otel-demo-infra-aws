# 02 - Infrastructure

## Overview

The Infrastructure layer provisions the core AWS networking and Kubernetes resources required by the OpenTelemetry Demo platform.

This layer is responsible for creating the foundational infrastructure that all higher layers depend on.

The infrastructure is intentionally isolated from the Platform and Application layers to provide clear ownership boundaries and independent Terraform state management.

---

## Resources Created

### Networking

- VPC
- Public Subnets
- Private Subnets
- Internet Gateway
- Route Tables
- NAT Gateway (if enabled)

### Kubernetes

- Amazon EKS Cluster
- Managed Node Groups
- IAM Roles for the EKS Control Plane
- IAM Roles for Worker Nodes

---

## Repository Structure

```
02-infrastructure/
├── environments/
│   ├── dev/
│   └── prod/
│
└── modules/
    ├── eks-cluster/
    └── vpc/
```

---

## Inputs

Environment-specific values are defined in:

```
environments/<environment>/terraform.tfvars
```

Examples include:

- Environment
- Cluster Version
- VPC CIDR
- Availability Zones
- Node Group Configuration

---

## Outputs

This layer exposes the following outputs for downstream Terraform projects.

| Output | Description |
|---------|-------------|
| cluster_name | EKS Cluster Name |
| cluster_endpoint | Kubernetes API Endpoint |
| cluster_certificate_authority_data | Kubernetes CA Certificate |
| cluster_oidc_issuer_url | OIDC Issuer URL |
| cluster_security_group_id | Cluster Security Group |
| vpc_id | VPC Identifier |
| private_subnet_ids | Private Subnets |
| public_subnet_ids | Public Subnets |
| node_group_role_arn | Worker Node IAM Role |

These outputs are consumed by the **03-platform** layer using `terraform_remote_state`.

---

## Deployment

Change into the desired environment.

```bash
cd environments/dev
```

Initialize Terraform.

```bash
terraform init
```

Review the execution plan.

```bash
terraform plan
```

Deploy the infrastructure.

```bash
terraform apply
```

---

## Validation

Update the local kubeconfig.

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name <cluster-name>
```

Verify cluster access.

```bash
kubectl get nodes
```

Expected output:

- Worker nodes are in the `Ready` state.

---

## Destroy

```bash
terraform destroy
```

The Infrastructure layer should only be destroyed after all Platform and Application resources have been removed.

Destroy order:

1. Applications
2. Platform
3. Infrastructure
4. Bootstrap (optional)

---

## Dependencies

### Required

- AWS Account
- Bootstrap layer completed
- Remote Terraform State Bucket
- AWS CLI configured

### Produces

The Infrastructure layer produces the networking and Kubernetes platform required by:

- 03-platform
- 04-applications

---

## Design Principles

- Modular Terraform architecture
- Separate Terraform state per layer
- Environment-specific configuration
- Reusable Terraform modules
- Infrastructure exposed through Terraform outputs
- Platform consumes Infrastructure via `terraform_remote_state`
