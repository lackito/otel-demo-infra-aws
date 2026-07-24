# Simple Project Walkthrough

## The Big Picture

At a high level, this project automates the entire path from writing code to running it in Kubernetes.

```text
Developer
    │
    │ git push
    ▼
GitHub Actions
    │
    │ builds Docker image
    ▼
Amazon ECR
    │
    │ updates GitOps repository
    ▼
Argo CD
    │
    │ deploys changes
    ▼
Amazon EKS
    │
    ▼
Running application
```

Terraform builds all of the infrastructure that makes this workflow possible.

---

# 02 - Infrastructure

## Question it answers

> Where does my application run?

Think of this layer as building an empty office building.

Before anyone can work, you need:

- Land
- Roads
- Electricity
- The building itself

Terraform creates:

- VPC
- Public Subnets
- Private Subnets
- Internet Gateway
- NAT Gateway
- Route Tables
- Security Groups
- Amazon EKS Cluster
- Worker Nodes

At the end of this layer you have:

> An empty Kubernetes cluster waiting for applications.

No applications exist yet.

---

# 03 - Platform

## Question it answers

> What shared tools does the Kubernetes cluster need?

Imagine the office building is finished.

Now you install:

- Elevators
- Wi-Fi
- Security cameras
- Badge readers

These are shared services that every application uses.

In our project this layer installs:

- AWS Load Balancer Controller
- IAM Role for Service Accounts (IRSA)

The Load Balancer Controller allows Kubernetes to automatically create AWS Load Balancers whenever an application exposes an Ingress or LoadBalancer Service.

At the end of this layer you have:

- Kubernetes Cluster
- Shared Platform Services

Still...

No business applications.

---

# 04 - Applications

## Question it answers

> How do applications get into Kubernetes?

Originally Terraform installed the OpenTelemetry Demo directly.

Now the architecture is much cleaner.

Terraform installs:

- Amazon ECR repositories
- GitHub Actions IAM Role
- Argo CD
- Argo CD Application

Terraform **does not deploy the application**.

Instead, Terraform tells Argo CD:

> "Watch this Git repository."

After that, Argo CD takes over.

---

# GitOps Repository

The GitOps repository is the **desired state** of the cluster.

Think of it as the recipe book.

It describes exactly what should be running.

Example:

```text
Recommendation image:
abc123

Grafana:
enabled

Jaeger:
enabled

Collector:
configured
```

Argo CD continuously compares Kubernetes against this repository.

If they are different...

Argo CD fixes Kubernetes automatically.

---

# GitHub Actions

## Question it answers

> How do I publish a new version?

When code is pushed:

1. Build Docker image
2. Push image to Amazon ECR
3. Update `applications/otel-demo/values.yaml` in the GitOps repository
4. Commit and push the GitOps repository

GitHub Actions **never talks directly to Kubernetes**.

It only updates Git.

---

# Argo CD

Argo CD continuously asks:

> "Has the GitOps repository changed?"

If yes:

- Pull latest configuration
- Compare desired state
- Synchronize Kubernetes

Nobody runs:

```bash
kubectl apply
```

Nobody runs:

```bash
helm upgrade
```

Everything happens automatically.

---

# Putting It Together

## 02 Infrastructure

Build the restaurant.

- Building
- Kitchen
- Electricity
- Parking lot

---

## 03 Platform

Install the shared equipment.

- Stove
- Freezer
- Security system
- Internet

---

## 04 Applications

Hire the restaurant manager.

The manager (Argo CD) receives one instruction:

> Follow the recipe book.

---

## GitOps Repository

The recipe book says:

```text
Today's recipe:

Recommendation image:
abc123

Grafana:
enabled

Jaeger:
enabled
```

---

## GitHub Actions

The chef invents a better recipe.

Instead of walking into the kitchen...

The chef updates the recipe book.

---

## Argo CD

The manager notices the recipe changed.

The manager tells the kitchen:

> Start using the new recipe.

The developer never walks into the kitchen.

The developer only edits the recipe.

---

# Old Way vs Modern GitOps

## Traditional Deployment

```text
Developer
    │
    ▼
kubectl apply
    │
    ▼
Cluster
```

The developer changes the cluster directly.

---

## GitOps Deployment

```text
Developer
    │
    ▼
Git Push
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
```

Git becomes the **single source of truth**.

Nobody changes Kubernetes manually.

---

# Final Architecture

```text
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
└── Registers GitOps Application
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
Recommendation Service
```

---

# The Three Questions

Everything in this project answers one of these three questions:

### 1. Where does my application run?

Answered by:

**02 - Infrastructure**

---

### 2. What does Kubernetes need before applications can run?

Answered by:

**03 - Platform**

---

### 3. How do new versions get deployed automatically?

Answered by:

**04 - Applications + GitHub Actions + GitOps + Argo CD**

---

Once these three layers are in place, the deployment process becomes very simple:

```text
Write code
    │
    ▼
git push
    │
    ▼
GitHub Actions builds image
    │
    ▼
Push image to ECR
    │
    ▼
Update GitOps repository
    │
    ▼
Argo CD detects change
    │
    ▼
Deploy new version to Kubernetes
```

No manual deployments.

No manual `kubectl apply`.

No manual Helm commands.

Everything flows automatically from Git.
