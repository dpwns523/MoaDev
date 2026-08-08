---
description: Platform engineering review — Helm charts, Argo CD, Terraform, Kubernetes manifests
---

Spawn the `platform-engineer` subagent via the Task tool to review changes to `platform/helm/`, `platform/argocd/`, `infra/terraform/`, or raw Kubernetes manifests. Pass it the diff output and files changed.

```bash
git diff HEAD --name-only -- platform/ infra/
helm template moadev platform/helm/moadev/ -f platform/helm/moadev/values-aws-dev.yaml 2>&1 | head -50
cd infra/terraform/dev && terraform plan -out=tfplan 2>&1 | tail -30
```
