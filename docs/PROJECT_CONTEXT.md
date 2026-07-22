# PROJECT_CONTEXT.md

# OpenTelemetry Demo on AWS EKS
## Project Context

Last Updated: July 2026

---

# Project Goal

This project evolved beyond the original Udemy course into a production-style DevOps implementation.

Instead of deploying the OpenTelemetry Demo directly with Helm from Terraform, the project now follows a layered infrastructure architecture with GitOps using Argo CD.

The objectives are to demonstrate:

- AWS Infrastructure as Code (Terraform)
- Kubernetes on Amazon EKS
- GitOps with Argo CD
- CI/CD using GitHub Actions
- Custom application builds
- Secure AWS integrations (IRSA)
- Production-style Terraform layering
- Modular infrastructure

---

# Repositories

## 1. ot-demo-tf

Infrastructure repository.

Contains all Terraform code.

Responsible for:

- Bootstrap
- Infrastructure
- Platform
- Application AWS resources

---

## 2. ot-demo-gitops

GitOps repository.

Contains:

- Argo CD Applications
- Helm values
- Kubernetes manifests

Terraform never deploys workloads.

Argo CD owns workloads.

---

## 3. ot-demo-apps

Application source code.

Contains customized services.

Currently customized:

- recommendation

Deferred:

- product-catalog
- ad

---

# Architecture

Bootstrap

↓

Infrastructure

↓

Platform

↓

Applications (AWS resources)

↓

GitOps (Argo CD)

↓

Kubernetes Workloads

---

Terraform only provisions infrastructure.

Argo CD deploys applications.

---

# Terraform Layering

## 01-bootstrap

Purpose

Creates remote Terraform backend.

Resources

- S3 bucket
- DynamoDB lock table

State

Independent

---

## 02-infrastructure

Creates AWS infrastructure.

Resources

- VPC
- Public Subnets
- Private Subnets
- NAT Gateway
- Internet Gateway
- Route Tables

EKS

- Amazon EKS
- Managed Node Groups
- IAM Roles
- OIDC Provider

Outputs consumed by Platform

- cluster_name
- cluster_endpoint
- cluster_ca_certificate
- cluster_oidc_issuer_url
- cluster_oidc_provider_arn
- vpc_id

---

## 03-platform

Deploys Kubernetes platform components.

Currently

- AWS Load Balancer Controller
- IRSA
- Argo CD

Managed with

Terraform

using

Helm provider

Argo CD installed as Helm chart.

OpenTelemetry Demo removed from this layer.

---

## 04-applications

Only manages AWS resources required by applications.

Currently

ECR repositories

Current repository

recommendation

No Kubernetes workloads deployed here.

---

# Current Terraform Modules

03-platform/modules

aws-load-balancer-controller

argocd

04-applications/modules

ecr-repositories

Future modules

external-dns

cert-manager

karpenter

metrics-server

external-secrets

---

# AWS Resources

Infrastructure

VPC

Subnets

EKS

IAM

OIDC

Platform

AWS Load Balancer Controller

IRSA

Applications

Amazon ECR

recommendation

---

# Kubernetes

Namespaces

kube-system

argocd

opentelemetry-demo

Argo CD

installed by Terraform

Applications

managed by GitOps

---

# Argo CD

Installed via Terraform.

Application manifests stored in

ot-demo-gitops

Application

otel-demo.yaml

Uses

Multiple Sources

Source 1

OpenTelemetry Helm Chart

Repository

https://open-telemetry.github.io/opentelemetry-helm-charts

Version

0.38.4

Source 2

GitHub

ot-demo-gitops

Contains

applications/otel-demo/values.yaml

Sync

Automated

Prune

Enabled

Self Heal

Enabled

Create Namespace

Enabled

---

# Helm Overrides

Current customization

Recommendation service

repository

650032249451.dkr.ecr.us-east-1.amazonaws.com/recommendation

tag

dev

Other services currently use upstream images.

---

# Recommendation Service

Custom image built locally.

Source

ot-demo-apps/apps/recommendation

Image

recommendation:dev

Published to

Amazon ECR

Verified working on EKS.

---

# Product Catalog

Current status

Deferred.

Reason

Upstream project migrated from JSON product catalog to PostgreSQL.

The Udemy course uses an older implementation.

The current upstream application exits immediately without a PostgreSQL connection.

Decision

Do not spend time fixing.

Continue project using recommendation service.

---

# Ad Service

Deferred.

Will be revisited later.

---

# Provider Versions

Terraform

>=1.13

AWS

~>6.0

Kubernetes

~>2.38

Helm

~>3.0

---

# Remote State

Platform

reads

Infrastructure

Applications

reads

Infrastructure

Bootstrap

contains backend

Each layer has independent state.

---

# Deployment Order

01-bootstrap

↓

02-infrastructure

↓

03-platform

↓

04-applications

↓

Git Push

↓

Argo CD Sync

↓

Applications Running

---

# Destroy Order

Delete Argo CD Applications

↓

03-platform

↓

02-infrastructure

↓

01-bootstrap (optional)

04-applications typically remains because ECR images should be preserved.

---

# GitOps Workflow

Developer

↓

Build Recommendation

↓

Push to Amazon ECR

↓

Update values.yaml

↓

Git Push

↓

Argo CD detects change

↓

Deploys automatically

Terraform is NOT used to deploy workloads.

---

# Repository Structure

ot-demo-tf

01-bootstrap

02-infrastructure

03-platform

04-applications

README.md

PROJECT_CONTEXT.md

---

ot-demo-gitops

argocd/

applications/

README.md

---

ot-demo-apps

recommendation

product-catalog

ad

...

---

# Conventions

Terraform

Layered architecture

One state per layer

Modules reusable

Remote state only

No hardcoded values

Environment folders

dev

prod

GitOps

Terraform installs Argo CD

Argo CD deploys applications

Helm values live in GitOps repo

---

# Important Design Decisions

OpenTelemetry Demo removed from Terraform.

Argo CD owns workloads.

Recommendation image stored in ECR.

Applications layer only provisions AWS resources.

Platform installs cluster services.

Infrastructure remains cloud-only.

---

# Lessons Learned

EKS recreation changes OIDC.

IRSA trust must be recreated.

kubectl context must be refreshed.

Helm provider timeout uses seconds.

Existing IAM resources may require Terraform import.

Argo CD Applications are Kubernetes CRDs.

Deleting an Application does not always delete workloads immediately.

Private GitHub repositories require Argo CD repository credentials.

Public repositories simplify GitOps.

Current upstream Product Catalog requires PostgreSQL.

---

# Known Issues

Product Catalog not customized.

Ad service not customized.

CI/CD pipeline not yet fully automated.

Ingress/ALB not yet configured.

TLS not configured.

External DNS not installed.

Monitoring still uses demo defaults.

---

# Remaining Work (Priority)

High

- GitHub Actions pipeline
- Automatic Docker build
- Push Recommendation image to ECR
- Update Helm values automatically
- GitOps deployment verification

Medium

- ALB Ingress
- External DNS
- cert-manager
- HTTPS

Low

- Product Catalog modernization
- Ad service customization
- Autoscaling
- Karpenter
- External Secrets
- Production monitoring

---

# Resume Checklist

If continuing development in a future conversation:

1. Deploy Bootstrap
2. Deploy Infrastructure
3. Deploy Platform
4. Verify Argo CD
5. Verify Recommendation image exists in ECR
6. Push GitOps changes
7. Sync Argo CD
8. Continue CI/CD implementation

# Current Session Handoff

Date:
2026-07-21

Completed:
- Terraform infrastructure deployed successfully
- Platform layer deployed successfully
- AWS Load Balancer Controller installed
- ECR recommendation repository created
- Recommendation image pushed:
  123456789012.dkr.ecr.us-east-1.amazonaws.com/recommendation:dev
- Argo CD installed
- GitOps repository connected
- OpenTelemetry Demo deployed through Argo CD
- Recommendation service validated

Next Task:
Implement GitHub Actions CI/CD pipeline.

Target workflow:

Developer Commit
        |
        v
GitHub Actions
        |
        v
Docker Build
        |
        v
Push Image to ECR
        |
        v
Update ot-demo-gitops values.yaml
        |
        v
Argo CD Sync
        |
        v
EKS Deployment
