# Architecture

## Repository Shape

`MoaDev` uses a polyglot monorepo with these primary workspaces:

- `apps/web` for the Next.js user interface
- `services/api` for the FastAPI backend
- `services/agents-runtime` for product-facing agent orchestration
- `infra/terraform` for cloud infrastructure definitions
- `platform/helm` for chart packaging
- `platform/argocd` for GitOps application definitions
- `platform/monitoring` for dashboards, alerts, and observability overlays

The repository still keeps early bootstrap placeholders under `src/`, `tests/`, `e2e/`, and `scripts/` while the workspace-based layout grows. Migrate incrementally rather than with a broad rewrite.

## High-Level Flow

The intended product path is:

1. `apps/web` renders the developer-facing UI.
2. `services/api` exposes application APIs and domain workflows.
3. `services/agents-runtime` coordinates product-facing agent execution and background automation.
4. `infra/terraform` provisions cloud resources used by the services.
5. `platform/helm` and `platform/argocd` package and promote deployments.
6. `platform/monitoring` captures metrics, logs, traces, dashboards, and alerts for operators.

## Engineering Boundaries

- Keep route handlers thin and move domain logic into service or domain modules.
- Validate data at system boundaries.
- Prefer additive workspace scaffolding over restructuring existing code without a migration plan.
- Use root `make` commands as the canonical automation entrypoint for contributors and agents.

## API Service Layout

`services/api` uses a route-based FastAPI layout:

- `app/main.py` assembles the application and exposes the app factory.
- `app/api/router.py` is the top-level router registry.
- `app/api/endpoints/` contains unversioned operational endpoints such as health checks.
- `app/api/v1/router.py` composes versioned API routers.
- `app/api/v1/endpoints/` contains versioned HTTP route modules grouped by resource.
- `app/schemas/` contains request and response boundary models.
- `app/services/` contains domain and service logic used by the route handlers.

This keeps route registration explicit, makes endpoint modules easier to grow independently, and preserves thin HTTP handlers that delegate business logic to service modules.
