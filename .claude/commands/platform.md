---
description: Platform engineering review — Helm charts, Argo CD, Terraform, Kubernetes manifests
---

Spawn the `platform-engineer` subagent via the Task tool to review the current platform/infrastructure changes.

## When to Use

- Modifying `platform/helm/` (Helm charts, values files, templates)
- Modifying `platform/argocd/` (Argo CD application definitions)
- Modifying `infra/terraform/` (Terraform modules, variables, outputs)
- Modifying Kubernetes manifests directly
- Planning a new service deployment

## What the Agent Will Review

1. **Blast radius** — what could break if this goes wrong
2. **Helm chart correctness** — structure, values hierarchy, template helpers
3. **Argo CD wiring** — sync policy, target revision, health checks
4. **Terraform safety** — plan impact, state correctness, destroy protections
5. **Kubernetes resources** — HPA, PDB, ingress, RBAC
6. **Rollout safety** — rollback procedure, deployment strategy, feature flags

## Quick Context Commands

```bash
# Show recent platform changes
git diff HEAD --name-only -- platform/ infra/

# Helm template render (dry run)
helm template moadev platform/helm/moadev/ -f platform/helm/moadev/values-aws-dev.yaml 2>&1 | head -50

# Terraform plan (requires init first)
cd infra/terraform/dev && terraform plan -out=tfplan 2>&1 | tail -30
```

Provide the platform-engineer agent with the diff output and specific files changed.
