# 04: Application

Set up ECR, GitHub Actions publisher roles, and the Argo CD Application for the
OpenTelemetry Demo. Apply layers 02 and 03 first: EKS and the Argo CD CRDs must
exist before this layer can be planned.

## Resources and ownership

| Resource | Configuration |
| --- | --- |
| ECR repositories | `ad`, `product-catalog`, `recommendation` |
| Publisher roles | One each for Ad, Product Catalog, and Recommendation |
| Argo CD Application | `otel-demo-aws`, namespace `argocd` |
| Workload namespace | `opentelemetry-demo` |
| GitOps source | `lackito/otel-demo-gitops-aws`, branch `main` |

The three custom services use independent publisher roles created by
`module.service_github_actions`. ECR repositories are created only for these
three services.

Argo CD combines the pinned upstream Helm chart with AWS GitOps values.
Terraform registers the Application; Argo CD manages its workloads.

## Release credentials

This layer reads the existing account-wide IAM OIDC provider for
`https://token.actions.githubusercontent.com`. The provider must exist and
include audience `sts.amazonaws.com`. It is shared account configuration,
separate from EKS's OIDC provider, and is not destroyed by this layer.

Publisher roles are named `otel-demo-aws-dev-<service>-github-actions`.
Each can push only to its corresponding ECR repository, with registry login
permission. They trust GitHub OIDC for `otel-demo-apps/main` using this subject:

```text
repo:lackito@6595109/otel-demo-apps@1305341394:ref:refs/heads/main
```

The application repository's GitHub OIDC subject settings and workflow claims
must match that policy. AWS authentication uses OIDC, with no AWS access-key
secret in GitHub.

In `otel-demo-apps`, configure:

- `AWS_GITOPS_REPOSITORY_TOKEN`: Contents read/write access to `otel-demo-gitops-aws`.
- Repository variable `AWS_RELEASES_ENABLED=true` when the infrastructure is ready.

The infrastructure repository does not need a release token. For workflow
configuration and branch usage, see the
[application delivery guide](https://github.com/lackito/otel-demo-apps/blob/main/DELIVERY.md).

## Deploy and inspect outputs

From the infrastructure repository root:

```bash
terraform -chdir=terraform/04-applications/environments/dev init
terraform -chdir=terraform/04-applications/environments/dev plan
terraform -chdir=terraform/04-applications/environments/dev apply
terraform -chdir=terraform/04-applications/environments/dev output
```

| Output | Contents |
| --- | --- |
| `repository_urls` | ECR URLs keyed by service |
| `repository_arns` | ECR ARNs keyed by service |
| `service_github_actions_role_arns` | Publisher ARNs for `ad`, `product-catalog`, and `recommendation` |

## Publish and validate

New repositories contain no images. In `otel-demo-apps` → Actions, run each AWS
release workflow from `main`: Ad, Product Catalog, and Recommendation. A
successful job publishes the image, runs its smoke test, and updates that
service's image override in the AWS GitOps repository. Argo CD deploys the pushed
values change.

```bash
make application-validate
```

Compare all three image tags with their release commit SHAs. Compare running
image IDs with the corresponding ECR platform digests. An image index and its
platform image have different digests. See
[Operations](../../docs/OPERATIONS.md#validate-the-deployment) for the complete
verification process.

## Destroy and rebuild

Dev ECR repositories use `force_delete=true`. Destroying this layer deletes
those repositories and all their stored images, including untagged manifests
and attestations. No separate ECR cleanup is needed.

The Application includes `resources-finalizer.argocd.argoproj.io`, so Argo CD
cleans up its workloads when Terraform deletes it. Keep Argo CD and EKS running
until layer 04 finishes:

```bash
terraform -chdir=terraform/04-applications/environments/dev destroy
```

You can recreate just this layer while retaining 02 and 03. Republish **all
three images** after recreation; GitOps still references tags from the deleted
repositories. For complete teardown, continue with 03 → 02. Retain the shared
state backend and GitHub OIDC provider.

## Configuration checks

The offline tests inspect publisher roles and application validation behavior:

```bash
python3 -m unittest discover -s tests -v
```

Run them from the repository root. They do not connect to AWS.
