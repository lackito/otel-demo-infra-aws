# PROJECT_WALKTHROUGH.md

# OpenTelemetry Demo AWS Project Walkthrough

This document explains the project from a high level.

It intentionally avoids implementation details and instead focuses on **what each phase is trying to accomplish**.

If you understand this document, you'll understand the overall architecture.

---

# The Big Picture

Our goal is **not simply to run the OpenTelemetry Demo.**

Our goal is to build a production-style DevOps platform where:

- Infrastructure is managed with Terraform.
- Applications are built automatically.
- Kubernetes deployments happen automatically.
- Git becomes the single source of truth.

Instead of manually deploying applications, everything happens automatically.

---

# Overall Architecture

```
Terraform
│
├── Creates AWS Infrastructure
│
├── Creates Kubernetes Cluster
│
├── Installs Platform Services
│
├── Installs Argo CD
│
└── Registers Argo CD Application
          │
          ▼
GitHub Actions
          │
          ▼
Amazon ECR
          │
          ▼
GitOps Repository
          │
          ▼
Argo CD
          │
          ▼
Amazon EKS
          │
          ▼
Running OpenTelemetry Demo
```

Each tool has exactly one responsibility.

---

# Step 1 - Bootstrap

Terraform creates the place where Terraform stores its own state.

Think of this as creating Terraform's notebook.

It contains:

- S3 Bucket
- Versioning
- Encryption
- Native Terraform lock file support

Nothing else is created yet.

---

# Step 2 - Infrastructure

Now Terraform builds the AWS environment.

Think of this as building an empty neighborhood.

Terraform creates:

- VPC
- Subnets
- Internet Gateway
- NAT Gateway
- Route Tables
- Amazon EKS Cluster
- Worker Nodes
- IAM Roles
- OIDC Provider

At this point...

We have a Kubernetes cluster.

But the cluster is empty.

No applications exist.

---

# Step 3 - Platform

Now we install software **inside** Kubernetes.

Think of this as installing the operating system for our neighborhood.

In our project this layer installs:

- AWS Load Balancer Controller
- IAM Roles for Service Accounts (IRSA)
- Argo CD
- Registers the Argo CD Application

The AWS Load Balancer Controller allows Kubernetes to automatically create AWS Load Balancers whenever an application exposes an Ingress or LoadBalancer Service.

Argo CD is our GitOps engine.

Terraform installs Argo CD and tells it **which Git repository to watch**.

At the end of this layer we have:

- Kubernetes Cluster
- Shared Platform Services
- Argo CD ready to deploy applications automatically

Still...

No business applications are running yet.

---

# Step 4 - Applications

This layer creates only the AWS resources required by our applications.

Currently it creates:

- Amazon ECR repositories

Terraform does **not** deploy Kubernetes workloads.

Terraform also does **not** install Argo CD.

Those responsibilities belong to the Platform layer.

After this layer finishes:

GitHub Actions has somewhere to publish container images.

---

# GitHub Actions

This is where our application deployment begins.

Suppose we modify the Recommendation service.

We push code.

GitHub Actions automatically runs.

GitHub Actions:

- Builds the Docker image
- Pushes the image to Amazon ECR
- Updates the GitOps repository

Notice something important:

GitHub Actions **never talks directly to Kubernetes**.

It only:

- Builds software
- Publishes images
- Updates Git

That's all.

---

# GitOps Repository

This repository represents the desired state of Kubernetes.

Think of it as the blueprint for the cluster.

Example:

```
applications/
└── otel-demo/
    └── values.yaml
```

GitHub Actions updates:

```
values.yaml
```

changing

```
tag: abc123
```

to

```
tag: def456
```

Nothing is deployed yet.

Git simply records what Kubernetes *should* be running.

---

# Argo CD

Argo CD constantly watches the GitOps repository.

When it notices a Git change:

It compares

Git

vs

Kubernetes.

If they differ...

Argo CD updates Kubernetes automatically.

This is GitOps.

Nobody manually runs:

```
kubectl apply
```

---

# Amazon EKS

Kubernetes receives the new deployment.

The Recommendation pod is recreated.

The new image is pulled from Amazon ECR.

Traffic begins flowing to the new version.

Deployment complete.

---

# Complete Deployment Flow

```
Developer
