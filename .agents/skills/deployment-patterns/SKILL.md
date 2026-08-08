---
name: deployment-patterns
description: MoaDev's actual deployment topology (self-managed K8s via Helm/Argo CD/Terraform) — not generic Vercel/Railway/Docker-Compose deployment patterns.
origin: MoaDev
---

MoaDev deploys to self-managed OCI/AWS Kubernetes via Helm charts and Argo CD GitOps promotion (dev → prod), provisioned by Terraform — see `platform-engineer` agent for the review focus and file locations (`platform/helm/`, `platform/argocd/`, `infra/terraform/`).

Rollback is `kubectl rollout undo` or an Argo CD sync to a previous revision — not a Vercel/Railway-style promote command. Health checks are Kubernetes liveness/readiness/startup probes against each service's `/health` endpoint, configured in the Helm chart.

Before a deploy-relevant change: confirm DB migrations are backward-compatible (services/api uses Alembic — see `database-migrations` skill), and that `make verify` passes.
