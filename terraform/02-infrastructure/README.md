# 02: Infrastructure

Create the AWS network and EKS cluster used by the demo.

## Resources

- VPC, public and private subnets, routing, and NAT.
- EKS cluster and managed worker nodes.
- Cluster IAM roles and the EKS OIDC provider used for IRSA.

Dev settings live in `environments/dev/terraform.tfvars`. Review the Kubernetes
version, region, instance type, and node counts before applying. State is stored
in the S3 backend configured in that environment. The shared backend must exist.

## Deploy

From the repository root:

```bash
aws-vault exec admin -- terraform -chdir=terraform/02-infrastructure/environments/dev init
aws-vault exec admin -- terraform -chdir=terraform/02-infrastructure/environments/dev plan
aws-vault exec admin -- terraform -chdir=terraform/02-infrastructure/environments/dev apply
aws-vault exec admin -- terraform -chdir=terraform/02-infrastructure/environments/dev output
```

Outputs include the cluster name, endpoint, VPC and subnet IDs, and OIDC
provider details consumed by the platform layer.

```bash
aws-vault exec admin -- aws eks update-kubeconfig \
  --region us-east-1 --name otel-demo-aws-dev --alias otel-demo-aws
aws-vault exec admin -- kubectl --context otel-demo-aws get nodes
```

Continue with [03: Platform](../03-platform/README.md) once nodes are ready.

## Destroy

Destroy layers 04 and 03 first, while Kubernetes is reachable. Then run:

```bash
aws-vault exec admin -- terraform -chdir=terraform/02-infrastructure/environments/dev destroy
```

Keep Terraform state and the shared backend for the next run. See
[Operations](../../docs/OPERATIONS.md) for the full lifecycle.
