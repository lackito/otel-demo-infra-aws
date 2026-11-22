# otel-demo-infra-aws

An AWS platform engineering project that provisions infrastructure with **Terraform** and delivers the upstream **[OpenTelemetry Demo](https://opentelemetry.io/docs/demo/)** through **Helm, Argo CD, GitHub Actions, and Amazon ECR**.

The deployment uses custom versions of `Ad`, `Product Catalog`, and `Recommendation`,
built from [otel-demo-apps](https://github.com/lackito/otel-demo-apps) and published to Amazon ECR. GitOps image overrides
replace the corresponding upstream images while retaining the upstream
OpenTelemetry Demo Helm chart.

This repository owns AWS provisioning, platform services, and Argo CD
Application registration.

## Related repositories

- [otel-demo-apps](https://github.com/lackito/otel-demo-apps): Custom services source, build, and release workflows.
- [otel-demo-gitops-aws](https://github.com/lackito/otel-demo-gitops-aws): AWS application desired state.

## How it works

```mermaid
flowchart LR
    A["Custom service source<br/>Ad, Product Catalog, Recommendation"] --> B[GitHub Actions]
    B --> C["Amazon ECR: custom images"]
    B --> D[GitOps values commit]
    D --> E[Argo CD]
    H[Upstream Helm chart] --> E
    E --> F[EKS workloads]
    C --> F
    T[Terraform layers] --> G[AWS infrastructure and platform]
    G --> E
```

- Terraform manages the infrastructure, platform, ECR repositories, publisher roles, and Application registration.
- Custom services (`Ad`, `Product Catalog`, and `Recommendation`) each have an independent release
workflow and ECR publisher role.
- Release workflows publish custom service images to ECR and update their GitOps image overrides.
- Argo CD deploys the workloads.

## Start here

| Goal | Guide |
| --- | --- |
| Build, verify, access, or destroy the environment | [Operations](docs/OPERATIONS.md) |
| Understand ownership and delivery | [Architecture](docs/ARCHITECTURE.md) |
| Create the network and EKS | [02: Infrastructure](terraform/02-infrastructure/README.md) |
| Install controllers and Argo CD | [03: Platform](terraform/03-platform/README.md) |
| Set up ECR, release roles, and the Application | [04: Application](terraform/04-applications/README.md) |

Terraform runs in order: state backend `01-bootstrap`, then 02 → 03 → 04.
Routine teardown uses 04 → 03 → 02 and retains the shared state backend.

## Validate the application

From this repository's root, after configuring the EKS context:

```bash
make application-validate
```

This reads the `otel-demo-aws` context, checks Argo CD health and deployment
rollouts, and prints the images and running image IDs for all three custom
services. It does not change resources. See [validation](docs/OPERATIONS.md#validate-the-deployment)
for image comparison and telemetry checks.

## Other repositories

- [otel-demo-infra-kind](https://github.com/lackito/otel-demo-infra-kind): local kind cluster and platform.
- [otel-demo-gitops-kind](https://github.com/lackito/otel-demo-gitops-kind): local kind application state.

See [Names and repositories](https://github.com/lackito/otel-demo-apps/blob/main/docs/NAMING.md)
for the shared naming reference.
