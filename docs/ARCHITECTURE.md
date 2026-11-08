# AWS architecture

[Overview](../README.md) · [Operations](OPERATIONS.md)

## Engineering focus

- Separate Terraform state by lifecycle: backend, infrastructure, platform, and applications.
- Provision networking, EKS, and IAM through reusable Terraform modules.
- Install the AWS Load Balancer Controller with IAM Roles for Service Accounts (IRSA).
- Authenticate GitHub Actions to AWS using OIDC for services (Ad/Product Catalog/Recommendation) image publishing.
- Let Argo CD reconcile application releases from GitOps values rather than deploying from CI.

The demo application comes from OpenTelemetry. The work here focuses on its
infrastructure, delivery automation, and operational boundaries.

## Ownership

| Owner | Responsibility |
| --- | --- |
| Terraform 01 | Shared S3 state backend |
| Terraform 02 | VPC, subnets, NAT, EKS, worker nodes, and EKS OIDC for IRSA |
| Terraform 03 | AWS Load Balancer Controller with IRSA and Argo CD |
| Terraform 04 | ECR repositories, GitHub Actions publisher roles, and Application registration |
| `otel-demo-apps` | Ad, Product Catalog, and Recommendation source and release workflows |
| `otel-demo-gitops-aws` | Helm values and the declarative Application definition |
| Argo CD | Reconciliation of application workloads |

- Terraform layers have separate state and consume outputs from the preceding
layers.
- Argo CD and its CRDs must exist before layer 04 can plan the Application.
- The Helm release is `otel-demo` in namespace `opentelemetry-demo`.

## Releases

A service change on `otel-demo-apps/main` starts its AWS release workflow when
`AWS_RELEASES_ENABLED=true`. The workflow assumes that service's IAM role via
GitHub OIDC, publishes an image tagged with the full source commit SHA, smoke-tests it,
and updates that service's image in `otel-demo-gitops-aws/main`.
Argo CD renders the upstream chart with those values and deploys the change.

Ad, Product Catalog, and Recommendation use the same delivery pattern. A change
limited to one service builds that service; shared release inputs can trigger
several workflows. CI does not need Kubernetes credentials.

The account-wide GitHub OIDC provider is shared and read by layer 04.
It is separate from the cluster-specific EKS OIDC provider used for IRSA.
Each publisher role permits pushes to its own ECR repository and trusts the
application repository's `main` branch.

## Access and telemetry

The platform installs AWS Load Balancer Controller. Installing the controller
alone does not create an application load balancer: routing also requires an
Ingress or another supported resource. The operations guide uses port forwarding
for application access with the current values.

Services send OTLP to the Collector; traces go to Jaeger and metrics to
Prometheus. The current AWS values disable OpenSearch while the chart's log
exporter still targets it. AWS log storage therefore needs configuration before
it can be validated. The kind overlay has its own OpenSearch configuration.

## Lifecycle

The Application has Argo CD's cascading-deletion finalizer. Destroying layer 04
lets Argo CD delete managed workloads before the Application disappears. Keep
Argo CD and EKS running until this finishes.

The disposable dev ECR repositories use `force_delete=true`, so layer-04 destroy
also removes their images. Recreating repositories leaves them empty: run all
three service release workflows before expecting their pinned images to pull.
Destroy 04 → 03 → 02; retain the shared S3 backend and GitHub OIDC provider.
