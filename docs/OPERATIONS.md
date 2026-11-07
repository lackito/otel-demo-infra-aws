# AWS operations

[Overview](../README.md) · [Architecture](ARCHITECTURE.md)

Run commands from `otel-demo-infra-aws` unless another directory is named.
The examples use region `us-east-1`. Review the environment settings before
provisioning.

## Prerequisites

Install Terraform, AWS CLI, kubectl, Helm, Make, and Python 3.
Check the active account:

```bash
aws sts get-caller-identity
```

The S3 backend must exist before layers 02–04 initialize. Its configuration is
in `terraform/01-bootstrap`; retain this shared backend during routine teardown.
Layer 04 also requires the account-wide GitHub OIDC provider. See the
[application setup guide](../terraform/04-applications/README.md#release-credentials).

## Deploy

For each layer below, run `init`, review `plan`, then `apply`, in order:

```bash
terraform -chdir=terraform/02-infrastructure/environments/dev init
terraform -chdir=terraform/02-infrastructure/environments/dev plan
terraform -chdir=terraform/02-infrastructure/environments/dev apply
```

Configure the context after layer 02:

```bash
aws eks update-kubeconfig \
  --region us-east-1 --name otel-demo-aws-dev --alias otel-demo-aws
kubectl --context otel-demo-aws get nodes
```

Install the platform and then register the application:

```bash
terraform -chdir=terraform/03-platform/environments/dev init
terraform -chdir=terraform/03-platform/environments/dev plan
terraform -chdir=terraform/03-platform/environments/dev apply
terraform -chdir=terraform/04-applications/environments/dev init
terraform -chdir=terraform/04-applications/environments/dev plan
terraform -chdir=terraform/04-applications/environments/dev apply
```

Keep the layers separate: the Argo CD CRDs installed by 03 must exist before
Terraform can plan 04. New ECR repositories are empty. Configure release
credentials, then run the AWS release workflows for **Ad, Product Catalog, and
Recommendation** from `main` in `otel-demo-apps`. Each publishes its image and
updates the corresponding GitOps values. See [release setup](../terraform/04-applications/README.md).

## Validate the deployment

```bash
make application-validate
```

The command waits for `otel-demo-aws` to be `Synced` and `Healthy`, checks all
Deployment rollouts and three stable health samples, then prints pods and all
three custom service images and image IDs. It is read-only. Set
`AWS_CLUSTER_CONTEXT=<context>` to use a different EKS context.

To verify a release:

1. Find its source commit SHA and image URI in the successful AWS release job.
2. Match that full SHA with the service's ECR tag and GitOps image override.
3. Check Argo CD is synced to the generated GitOps commit.
4. Match the deployed image reference and running image ID from validation.

An image tag can point to an image index. The pod can report a platform image
digest within that index, so compare it with the matching platform digest in
ECR. A healthy rollout does not prove telemetry delivery: exercise the store,
then check Ad, Product Catalog, and Recommendation traces in Jaeger and metrics
in Grafana. OpenSearch is disabled in AWS; stored logs are not validated by this
command. Container logs remain available through `kubectl logs`.

## Open the application

Keep this command running in a separate terminal:

```bash
kubectl --context otel-demo-aws \
  -n opentelemetry-demo port-forward svc/frontend-proxy 8080:8080
```

Open the store at `http://localhost:8080`, Grafana at
`http://localhost:8080/grafana/`, or Jaeger at
`http://localhost:8080/jaeger/ui/`.

For Argo CD, retrieve the initial password:

```bash
kubectl --context otel-demo-aws -n argocd \
  get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode
echo
```

Then keep this running in another terminal:

```bash
kubectl --context otel-demo-aws \
  -n argocd port-forward svc/argocd-server 18080:80
```

Open `http://localhost:18080` and sign in as `admin` with that password, unless
you have changed it. The AWS Argo CD values use HTTP behind the service.

## Troubleshooting

For an image pull failure, inspect events and confirm the exact tag exists in
ECR. After rebuilding the infrastructure, publish all three images again.

```bash
kubectl --context otel-demo-aws \
  -n opentelemetry-demo get events --sort-by=.lastTimestamp
```

For a skipped AWS release, check the workflow runs on `main` and the repository
variable `AWS_RELEASES_ENABLED` is `true`. For access denied, compare its OIDC
claims and role ARN with layer 04's output. For a stalled Argo sync, inspect the
Application's sync errors and GitOps revision before changing workloads.

## Tear down

Set `AWS_RELEASES_ENABLED=false` in `otel-demo-apps` to stop automatic AWS
publishing while the environment is down. Destroy in this order:

```bash
terraform -chdir=terraform/04-applications/environments/dev destroy
terraform -chdir=terraform/03-platform/environments/dev destroy
terraform -chdir=terraform/02-infrastructure/environments/dev destroy
```

Layer 04's Application finalizer lets Argo CD remove the demo workloads; its
ECR `force_delete` setting removes stored images. Keep Argo CD running until
04 finishes. Retained Argo CD CRDs reported by Helm are expected and disappear
when EKS is deleted. Retain the shared layer-01 backend and GitHub OIDC provider.
