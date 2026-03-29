# AGENTS.md

## Commands
- Bootstrap: `make bootstrap`
- Build: `make build`
- Test: `make test`
- Lint: `make lint`
- Typecheck: `make typecheck`
- E2E: `make e2e`
- Verify: `make verify`

## Repository expectations
- Use `/plan` for any task that is not trivially small.
- Before building custom logic, use `$search-first` and summarize reuse options.
- For domain logic and backend work, use `$tdd-workflow` and start with failing tests whenever practical.
- For API contract changes, use `$api-design`.
- For infra, auth, secrets, networking, and deployment changes, use `$security-review`.
- Before considering a task complete, run `$verification-loop` or `make verify`.
- Keep diffs small and incremental.
- Prefer reuse over new abstractions.
- Never commit secrets, credentials, `.tfstate`, or generated plan files.

## Documentation
- Update `docs/task-list.md` whenever task status changes.
- Update `docs/architecture.md` when boundaries, data flow, deployment shape, or observability changes.
- Update `docs/release-notes.md` when user-visible or operator-visible behavior changes.
- Keep `docs/conventions.md` aligned with actual commands and tooling.

## Repository structure
- `apps/web` - Next.js UI
- `services/api` - FastAPI API
- `services/agents-runtime` - product-facing agent orchestration
- `infra/terraform` - cloud infrastructure
- `platform/helm` - Helm chart
- `platform/argocd` - GitOps applications
- `platform/monitoring` - observability overlays
- `e2e` - end-to-end flows
- `scripts` - local automation

## Working style
- Keep route handlers thin; business logic belongs in domain and service modules.
- Validate data at system boundaries.
- Use the closest `AGENTS.override.md` for directory-specific rules.
