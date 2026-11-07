# 04 - Applications

## Overview

The **Applications** layer manages application-specific resources required for workloads running on the Amazon EKS platform.

This layer sits above:

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

The responsibility of this layer is intentionally limited to application prerequisites and supporting AWS resources.

Application deployment is handled through **GitOps using Argo CD**.

---

# Responsibilities

The Applications layer currently manages:

- Amazon ECR repositories
- Application container image lifecycle support
- Application-specific AWS resources
- GitHub Actions OIDC access for publishing application images

It does **not** directly deploy Kubernetes workloads.

---

# Architecture

```
┌──────────────────────────┐
│ Developer                │
│                          │
│ Application Source Code  │
└─────────────┬────────────┘
              |
              v
┌──────────────────────────┐
│ GitHub Actions           │
│                          │
│ Build Container Image    │
│ Push Image               │
└─────────────┬────────────┘
              |
              v
┌──────────────────────────┐
│ Amazon ECR               │
│                          │
│ recommendation:dev       │
└─────────────┬────────────┘
              |
              v
┌──────────────────────────┐
│ otel-demo-gitops-aws           │
│                          │
│ Helm Values              │
│ ArgoCD Application       │
└─────────────┬────────────┘
              |
              v
┌──────────────────────────┐
│ Argo CD                  │
│                          │
│ Kubernetes Deployment    │
└──────────────────────────┘
```

---

# Repository Structure

```
04-applications/

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
└── modules/
    └── ecr-repositories/
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

---

# Terraform Modules

## ECR Repositories

The current module creates and manages Amazon Elastic Container Registry repositories.

Example:

```hcl
repositories = [
  "recommendation"
]
```

Terraform manages:

- Repository creation
- Image scanning configuration
- Repository tagging

Example tags:

```text
Project     = otel-demo
Environment = dev
Layer       = applications
ManagedBy   = Terraform
```

---

# Service Publisher CI/CD Identities

The `dev` environment reuses the account-wide GitHub OIDC provider and creates
one dedicated IAM role per custom service through `module.service_github_actions`.
The keys are `recommendation`, `ad`, and `product-catalog`. Every role trusts
`lackito/otel-demo-apps` on `main` and has ECR permissions for its service only.

The AWS-specific application workflow references the resulting non-sensitive
role ARN directly. The `service_github_actions_role_arns` output maps all three
services to their ARNs and can verify that workflow configuration. The workflow uses this short-lived
OIDC identity to build, publish, and update GitOps; it has no Kubernetes
credentials.

This repository uses a customized GitHub OIDC subject containing immutable
owner and repository IDs. The IAM trust policy therefore restricts GitHub's
OIDC token to:

```text
aud = sts.amazonaws.com
sub = repo:lackito@6595109/otel-demo-apps@1305341394:ref:refs/heads/main
```

If GitHub Actions reports `Not authorized to perform
sts:AssumeRoleWithWebIdentity`, apply this Terraform layer and confirm that its
role output matches the role ARN configured in the application workflow:

```bash
terraform output -json service_github_actions_role_arns
```

# Current Application Images

## Recommendation Service

The recommendation service is the first application integrated into the deployment workflow.

ECR repository:

```
recommendation
```

Example image:

```
123456789012.dkr.ecr.us-east-1.amazonaws.com/recommendation:dev
```

Deployment flow:

```
Source Code
    |
    v
Docker Build
    |
    v
Amazon ECR
    |
    v
Argo CD
    |
    v
EKS Deployment
```

---

# GitOps Integration

Application deployment is managed by:

```
otel-demo-gitops-aws
```

Repository structure:

```
otel-demo-gitops-aws/
├── argocd/
│   └── applications/
│       └── otel-demo.yaml
│
└── applications/
    └── otel-demo/
        └── values.yaml
```

Argo CD consumes:

- OpenTelemetry Demo Helm chart
- Git-managed Helm values

The Terraform module in this stage registers the Argo CD Application. Its
declarative YAML definition also remains in the GitOps repository alongside
the desired application state.

Example image override:

```yaml
components:
  recommendation:
    imageOverride:
      repository: 123456789012.dkr.ecr.us-east-1.amazonaws.com/recommendation
      tag: dev
```

---

# Deployment Ownership

The project intentionally separates responsibilities:

| Layer | Responsibility |
|---|---|
| Terraform Infrastructure | AWS resources |
| Terraform Platform | Kubernetes platform services |
| Terraform Applications | Application prerequisites |
| GitHub Actions | Build and publish images |
| Argo CD | Kubernetes deployments |

---

# Deferred Applications

## Product Catalog

The original course implementation was evaluated but intentionally deferred.

Reason:

The course implementation uses a different architecture:

- Local `products/products.json`
- File-based product loading

The current OpenTelemetry Demo implementation expects:

- Database-backed product catalog
- PostgreSQL integration
- Different runtime configuration

Decision:

Product Catalog deployment is postponed until the architecture is aligned.

---

## Ad Service

The Ad service is also deferred.

Current priority:

1. Recommendation service
2. CI/CD pipeline validation
3. GitOps deployment workflow

---

# Dependencies

Before deploying this layer:

Required:

- AWS Account
- AWS CLI configured
- Terraform >= 1.13
- Existing Terraform backend
- EKS infrastructure deployed

Recommended:

- Docker installed
- GitHub repository configured
- ECR authentication configured

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

Verify ECR repositories:

```bash
aws ecr describe-repositories
```

Example:

```text
recommendation
```

---

Verify images:

```bash
aws ecr list-images \
--repository-name recommendation
```

Expected:

```text
dev
```

---

# Destroy

Recommended lifecycle:

```
Applications

↓

Platform

↓

Infrastructure

↓

Bootstrap
```

Destroy:

```bash
terraform destroy
```

Note:

Destroying this Terraform layer removes AWS application resources.

The Application declares Argo CD's foreground cascading-deletion finalizer.
Deleting it through Terraform makes Argo remove the managed demo resources
before Application deletion completes. A separate manual Application deletion
is not required. Keep layer 03 and the Argo controller running until layer 04
finishes destroying; then destroy 03 before 02.

Fresh installations receive the finalizer automatically. For an Application
created before this setting was added, apply layer 04 once to install the
finalizer before using `terraform destroy`. Changing the source file alone does
not update an existing Application. If Argo was already uninstalled, restore
its controller before expecting it to perform finalizer cleanup.

The disposable dev environment sets `force_delete = true` on its ECR module.
Terraform destroy deletes these repositories including all stored images, image
indexes, and attestations; a separate image-cleanup command is not needed.
The reusable module defaults to false for environments that retain images.
For repositories created before this setting, apply the updated configuration
once before destroy so Terraform records the setting. Adding it to source and
immediately running destroy does not persist it in existing state. Helm may keep
Argo CRDs when layer 03 is uninstalled; that is separate from application cleanup
and the CRDs disappear when layer 02 deletes the cluster.

---

# Troubleshooting

## Repository already exists

Example:

```
RepositoryAlreadyExistsException
```

Cause:

The repository was created manually before Terraform management.

Solutions:

Import:

```bash
terraform import \
module.ecr_repositories.aws_ecr_repository.this["recommendation"] \
recommendation
```

or remove the existing repository.

---

## Image cannot be pulled by Kubernetes

Symptoms:

```
ImagePullBackOff
```

Check:

```bash
kubectl describe pod <pod-name>
```

Possible causes:

- Incorrect ECR repository URL
- Incorrect image tag
- Missing EKS permissions
- Image not pushed

---

# Design Principles

This layer follows:

- Separation of infrastructure and application lifecycle
- Immutable container images
- GitOps-based deployments
- Terraform-managed AWS resources
- Kubernetes ownership through Argo CD
- Environment-specific configuration

---

# Lessons Learned

During development:

- Application deployment ownership must be clearly separated.
- Terraform should not compete with Argo CD for Kubernetes ownership.
- Existing AWS resources should be imported before Terraform management.
- Container validation locally helps isolate application issues.
- The recommendation service provided the cleanest path for validating CI/CD and GitOps workflows.

---

# Future Enhancements

Potential additions:

- GitHub Actions CI pipeline
- Automated Docker image builds
- Automated ECR publishing
- Image version promotion strategy
- Security scanning integration
- SBOM generation
- Application deployment approvals
- Production environment support


## Product Catalog and Ad publishers

Layer 04 adds `product-catalog` and `ad` ECR repositories (immutable tags),
plus one main-only GitHub OIDC publisher role per repository. Existing
Recommendation, Checkout, and Frontend repositories are retained.
Layer 04 looks up the existing account-wide GitHub OIDC provider by URL and
reuses its ARN for all three publisher roles. It verifies the provider includes
`sts.amazonaws.com` as an audience. The provider is an account-level prerequisite,
not an application-owned resource; do not import it into this layer if another
Terraform state already owns it. All three roles are created by the shared
publisher module on a fresh layer-04 deployment.

Publisher policies allow layer upload, PutImage, repository-scoped image
inspection/pull (required by release verification), and GetAuthorizationToken
on `*` as required by ECR. They grant no deployment, repository deletion, or
cross-repository image permissions. New role ARNs are exposed by
`service_github_actions_role_arns`, which includes `recommendation`, `ad`, and
`product-catalog`. The standalone Recommendation output is removed; use the
`recommendation` key in this map. The existing Recommendation role receives
the same repository-scoped inspection/pull additions.

Validate with `terraform init -backend=false` and `terraform validate` in
`environments/dev`. Before applying, initialize the real backend and review a
saved plan: expect additive repositories and roles, and an in-place policy
update; stop if existing ECR, role, or OIDC resources are replaced/deleted.
Validation is not a cloud plan or proof of deployed infrastructure.
Apply layer 04 before enabling apps release workflows. Those workflows publish
full-SHA images and validate them before updating GitOps. Argo CD continues
to own workloads; chart 0.38.4 and the Application source are unchanged.

## AWS and kind naming migration

The AWS Argo Application is `otel-demo-aws`, its GitOps source is
`otel-demo-gitops-aws`, and publisher roles use `otel-demo-aws-dev-*`.
These names assume the previous infrastructure was destroyed before migration.
Terraform addresses remain stable, but applying this change to surviving old
roles would replace their names; inspect the saved plan against real state.
Keep the shared Helm release name `otel-demo`. See the
[naming guide](https://github.com/lackito/otel-demo-apps/blob/main/docs/NAMING.md)
for the coordinated repository rename and release configuration.

## Recover from GitHub OIDC EntityAlreadyExists (HTTP 409)

AWS already has a provider for `https://token.actions.githubusercontent.com`,
but older layer-04 code always tried to create it. A failed apply may already
have created ECR repositories and the Argo Application; successful operations
are normally recorded in state even when another operation fails. Do not destroy
those resources or remove their state to retry.

The corrected configuration reads the existing provider and uses its ARN in
all three role trust policies. It does not change the provider's audiences,
thumbprints, tags, or ownership in another state. For a new AWS account,
provision this shared provider once through account-level bootstrap before
applying layer 04. This is separate from EKS's cluster-specific OIDC provider.

After merging/pulling the fix, authenticate with the AWS profile used for this
environment and run from `environments/dev`:

```sh
terraform init
terraform state list
terraform plan -out=layer04.tfplan
terraform show layer04.tfplan
# After reviewing the plan:
terraform apply layer04.tfplan
```

Confirm the account is the intended one using `aws sts get-caller-identity`.
To inspect the existing provider (for the configured account):

```sh
aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn arn:aws:iam::650032249451:oidc-provider/token.actions.githubusercontent.com
```

The saved plan should retain successfully created ECR repositories and the Argo
Application, reuse the provider, and create any publisher roles/policies that
were blocked by the failed provider creation. Actual actions depend on state;
backend-free validation does not establish the live recovery plan.

The publisher module has mocked regression tests for shared-provider trust and
uniform OIDC-only trust actions. They do not access AWS:

```sh
cd ../../modules/github-actions-ecr-publisher
terraform init -backend=false
terraform test
```

## Disposable layer-04 rebuilds

All three custom services use `module.service_github_actions`; there is no
separate Recommendation module or standalone role output. Read all role ARNs
with `terraform output -json service_github_actions_role_arns` and select the
service key. All publishers use the same OIDC-only trust policy structure.

This development environment is rebuilt from scratch rather than migrated.
There are no moved/removed blocks or Recommendation-specific compatibility
options. Destroy the existing layer 04 using the current deployed configuration
before merging/pulling the refactor. Do not apply the new addresses over the old
state or discard the state file; destroy first so AWS objects and state agree.

To retest this publisher refactor, destroy and recreate **04-applications only**.
Keep 03-platform (Argo CD/controller), 02-infrastructure (EKS/network), and the
01-bootstrap state backend. Those layers have no changes in this refactor.

Rebuild sequence:

1. Pause AWS release runs while rebuilding and keep layer 03's Argo controller
   running. The Application finalizer makes Terraform deletion cascade through
   the demo workloads, so a separate manual Argo deletion is not needed.
   An existing Application must already have the finalizer applied before
   destroy; new installations include it automatically.
2. The dev ECR module's `force_delete = true` removes stored images together
   with its repositories. No manual image cleanup is required after that setting
   has been applied. Existing repositories need the setting applied once first.
   Unrelated repositories and the shared GitHub OIDC provider are unaffected.
3. From `terraform/04-applications/environments/dev`, run `terraform destroy`
   under `aws-vault exec admin --`. Review the destroy plan. Existing roles,
   policies, ECR repositories, and Application registration belong to this layer.
4. Merge/pull the simplified publisher code, then run `terraform init`, review
   a fresh plan, and apply it in that same directory. The shared module creates
   Recommendation, Ad, and Product Catalog publishers and the output map lists
   all three. The shared GitHub provider remains an account-level prerequisite.
5. Re-enable AWS releases and manually run all three service AWS workflows on
   `main`. Recreated ECR repositories are empty; Terraform does not build or
   restore images. GitOps may still reference the previous tags until releases
   publish, verify, and promote new images. Validate afterward with
   `aws-vault exec admin -- make application-validate` from the repo root.

For a complete teardown after testing, destroy 04 → 03 → 02. Layer 04's
Application finalizer cleans up demo workloads while the controller is available. Keep the shared
01 state backend for the next run; it is not necessary to destroy it to test or
rebuild these publisher modules.

## ECR cleanup during destroy

`environments/dev/main.tf` explicitly opts into the ECR module's `force_delete`
setting because this environment is disposable. The module itself defaults to
false. This affects only repositories in `local.ecr_repositories`; it does not
grant image or repository deletion rights to application publishing workflows.

When Terraform deletes one of these repositories, AWS also deletes its images.
This includes tagged manifests, image indexes, and untagged build attestations.
No provisioner, shell cleanup script, or ECR lifecycle policy is needed.

New repositories receive the setting during creation. If they already exist,
review and apply a normal plan once to record the setting before destroying.
If the previous environment is already gone, the next rebuild handles this
automatically. Retain the 04 → 03 → 02 teardown order so Argo can finish the
Application finalizer while its controller is still available.

The module has credential-free plan tests for the default retained-image behavior
and the explicit disposable-environment opt-in:

```sh
cd ../../modules/ecr-repositories
terraform init -backend=false
terraform test
```
