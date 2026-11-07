# 03: Platform

Install AWS Load Balancer Controller and Argo CD on the EKS cluster from
[02: Infrastructure](../02-infrastructure/README.md).

## Ownership

The controller uses IAM Roles for Service Accounts (IRSA) with the cluster's
EKS OIDC provider. Argo CD owns application reconciliation; this layer installs
Argo CD but does not register the demo Application. Layer 04 does that after
the Argo CD CRDs exist.

The controller's installation does not create an application load balancer.
The application also needs routing configuration to request one. The current
operations guide uses port forwarding for access.

## Deploy

From the repository root:

```bash
terraform -chdir=terraform/03-platform/environments/dev init
terraform -chdir=terraform/03-platform/environments/dev plan
terraform -chdir=terraform/03-platform/environments/dev apply
```

This layer reads infrastructure outputs from remote state. Review settings in
`environments/dev` and module Helm values before applying.

## Validate

```bash
kubectl --context otel-demo-aws \
  -n kube-system rollout status deployment/aws-load-balancer-controller
kubectl --context otel-demo-aws -n argocd get pods
helm list --all-namespaces
```

Continue with [04: Application](../04-applications/README.md).
See [Operations](../../docs/OPERATIONS.md#open-the-application) for Argo CD access
and its initial admin password.

## Destroy

Destroy layer 04 first: its Application finalizer needs a running Argo CD to
remove managed workloads. Then run:

```bash
terraform -chdir=terraform/03-platform/environments/dev destroy
```

Helm can report retained Argo CD CRDs. They remain until the cluster is deleted;
this does not mean application workloads were cleaned up. Complete teardown by
destroying layer 02.
