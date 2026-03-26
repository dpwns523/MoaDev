# Conventions

This document defines the default engineering conventions for this repository. Keep it stable, explicit, and easy to update as tooling becomes concrete.

## Package Manager

- Default package manager: `npm`
- If the repo adopts another package manager later, update this file and `AGENTS.md` together.
- Do not mix lockfiles or package managers in the same branch.

## Commands

Canonical root commands are standardized through the repository `Makefile`.

- Bootstrap: `make bootstrap`
- Build: `make build`
- Test: `make test`
- Lint: `make lint`
- Typecheck: `make typecheck`
- E2E: `make e2e`
- Verify: `make verify`
- Format: `make format`

These commands are rooted in the workspace scaffolds under `apps/`, `services/`, and `infra/`. Terraform targets require a local `terraform` CLI to run. Keep this section and `AGENTS.md` aligned with the actual `Makefile`.

## Naming

- Files and folders: `kebab-case` unless a framework requires another format.
- Variables and functions: `camelCase`
- Types, interfaces, classes, and React components: `PascalCase`
- Constants and environment variable names: `UPPER_SNAKE_CASE`
- Use descriptive verb-noun names for functions and action handlers.
- Prefer plural resource names for API paths, collections, and repository methods.

## Folder Responsibilities

- `apps/web/`: Next.js UI
- `services/api/`: FastAPI API
- `services/agents-runtime/`: product-facing agent orchestration
- `infra/terraform/`: cloud infrastructure
- `platform/helm/`: Helm chart
- `platform/argocd/`: GitOps applications
- `platform/monitoring/`: observability overlays
- `src/`: temporary bootstrap runtime code before workspace extraction
- `tests/`: repository-level unit and integration tests
- `e2e/`: end-to-end and workflow-level tests
- `scripts/`: developer and CI utilities
- `docs/`: product, architecture, conventions, task tracking, and release notes
- `.agents/`: reusable skill and agent instructions
- `.codex/`: local Codex configuration and agent profiles

Keep business logic out of `scripts/` and keep test-only helpers out of `src/` unless they are shared runtime utilities.

## Environment Variables

- Never hardcode secrets, tokens, or credentials in source, tests, or docs.
- Read configuration from environment variables at the system boundary.
- Validate required environment variables at startup and fail fast with a clear message.
- Use checked-in examples such as `.env.example` for names and documentation, never for real secrets.
- Keep names explicit and scoped, for example `OPENAI_API_KEY` or `DATABASE_URL`.

## API Responses And Errors

- Use consistent JSON responses.
- Success responses return `data`; collection responses may also return `meta` and `links`.
- Error responses return an `error` object with `code`, `message`, and optional `details`.
- Use HTTP status codes semantically; do not encode failure only inside a `200` response.
- API routes should be lowercase, plural, and `kebab-case`.

Example success shape:

```json
{ "data": { "id": "123" } }
```

Example error shape:

```json
{ "error": { "code": "validation_error", "message": "Invalid request" } }
```

## Testing Policy

- Complex work starts in `/plan`.
- Failing tests come before production code.
- Follow RED -> GREEN -> REFACTOR for new behavior and bug fixes whenever practical.
- Add or update unit, integration, and E2E coverage based on the change surface.
- Do not change tests only to make incorrect behavior pass.
- If coverage is deferred, call out the gap and risk clearly in the final summary.

## Review Checklist

- Scope matches the task and avoids unrelated edits.
- Names, file placement, and boundaries follow this document.
- Inputs are validated and secrets are not hardcoded.
- Error handling is intentional and user-visible behavior is clear.
- API responses and status codes are consistent.
- Tests cover the change, or missing coverage is documented.
- Behavior changes include updates to `docs/task-list.md` and `docs/release-notes.md`.
