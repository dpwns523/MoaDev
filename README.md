# MoaDev

Authenticated AI knowledge web application monorepo for:
- web frontend (`apps/web`)
- API (`services/api`)
- agent runtime (`services/agents-runtime`)
- infrastructure (`infra/terraform`)
- platform delivery (`platform/helm`, `platform/argocd`)
- monitoring (`platform/monitoring`)

Current product direction:
- aggregate useful external technology content
- provide structured Korean translation and explanation outputs per article
- require authenticated access to the web application
- grow toward a broader knowledge platform in later phases

Primary product docs:
- `docs/prd.md`
- `docs/prd.ko.md`
- `docs/product-plan.md`
- `docs/product-plan.ko.md`
- `docs/agents-product.md`
- `docs/agents-product.ko.md`
- `docs/architecture.md`
- `docs/production-plan.md`
- `docs/production-plan.ko.md`

## Quick start

```bash
make bootstrap
make lint
make typecheck
make test
make verify
```

## Repo layout

- `apps/web` - Next.js UI
- `services/api` - FastAPI API
- `services/agents-runtime` - product-facing agent orchestration
- `infra/terraform` - Terraform IaC
- `platform/helm` - Helm chart
- `platform/argocd` - GitOps manifests
- `platform/monitoring` - monitoring stack values
- `src` - legacy bootstrap placeholder kept during workspace migration
- `tests` - repository-level unit and integration tests
- `e2e` - end-to-end flows
- `scripts` - local automation

## Codex usage

- Root instructions: `AGENTS.md`
- Folder-specific rules: `AGENTS.override.md`
- Skills: `.agents/skills/`
- Subagents: `.codex/agents/`

## Commands

- `make build`
- `make test`
- `make lint`
- `make typecheck`
- `make e2e`
- `make verify`
