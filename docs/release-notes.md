# Release Notes

Use this file as the standard release template. For each release, duplicate the template block below, replace placeholders, and keep the newest release at the top.

If a section does not apply, write `None`.

---

## Release: `api-route-based-architecture`

- Date: `2026-04-01`
- Status: `planned`
- Owner: `repository-maintainers`

### Summary

Restructured `services/api` to a FastAPI route-based architecture with an app factory, a top-level router registry, versioned `api/v1/endpoints` modules, and dedicated API boundary schemas.

### User Impact

- Who is affected: contributors extending the FastAPI service and operators reviewing API structure
- What users will notice: no endpoint path changes, but the API code is now organized around `APIRouter` modules and `api/v1/endpoints` instead of defining all routes in `app/main.py`
- Expected benefits: clearer separation between app assembly, HTTP routes, schemas, and domain services

### Migration Notes

- Required upgrade steps: none
- Data or config changes: none
- Operator actions: none

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `None` | no | none | No new environment variables were introduced. |

### Breaking Changes

- None.

### Rollback Notes

- Rollback trigger: contributors need to temporarily return to a single-file FastAPI entrypoint
- Rollback steps: move route registrations and boundary schemas back into `app/main.py` and remove the router package
- Data recovery notes: none

### Known Issues

- The API currently has only a small route surface, so some route modules are intentionally lightweight until more endpoints are added.

---

## Release: `api-feed-validation-hardening`

- Date: `2026-04-01`
- Status: `planned`
- Owner: `repository-maintainers`

### Summary

Hardened the `/api/v1/feeds` response boundary so malformed feed items consistently return the structured `feed_validation_error` envelope, including mapping-based inputs and whitespace-only string fields.

### User Impact

- Who is affected: API consumers and operators relying on curated feed responses
- What users will notice: `/api/v1/feeds` now rejects whitespace-only `id`, `title`, and `source` values at the API boundary and preserves the documented JSON error envelope for malformed mapping/object feed items
- Expected benefits: a stricter and more predictable validation contract for curated feed payloads

### Migration Notes

- Required upgrade steps: none
- Data or config changes: none
- Operator actions: none

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `None` | no | none | No new environment variables were introduced. |

### Breaking Changes

- None.

### Rollback Notes

- Rollback trigger: feed producers must temporarily allow whitespace-only values or rely on generic FastAPI 500 responses for malformed feed items
- Rollback steps: revert the API boundary validator and restore the previous feed serialization path
- Data recovery notes: none

### Known Issues

- Feed producers still need to provide one of the curated `kind` values: `news` or `pull-request`.

---

## Release: `core-workspace-scaffolds`

- Date: `2026-03-29`
- Status: `planned`
- Owner: `repository-maintainers`

### Summary

Added runnable workspace scaffolds for the web app, FastAPI API, agent runtime, and Terraform layouts, and wired the root verification flow to those concrete workspaces.

### User Impact

- Who is affected: contributors and operators working in the scaffolded monorepo workspaces
- What users will notice: `apps/web`, `services/api`, `services/agents-runtime`, and `infra/terraform` now exist with working baseline code and root `make` targets execute real workspace commands instead of only skip paths
- Expected benefits: contributors can bootstrap, build, lint, typecheck, test, and validate the core workspaces from the repository root

### Migration Notes

- Required upgrade steps: run `make bootstrap` before local development in a fresh checkout
- Data or config changes: none
- Operator actions: install the local `terraform` CLI before running Terraform validation targets

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `None` | no | none | No new environment variables were introduced. |

### Breaking Changes

- None.

### Rollback Notes

- Rollback trigger: the new workspace scaffolds or root verification flow block local development
- Rollback steps: revert the scaffolded workspace directories and restore the previous skip-only root command behavior
- Data recovery notes: none

### Known Issues

- `platform/helm`, `platform/argocd`, and `platform/monitoring` are still not scaffolded.
- End-to-end Playwright wiring has not been added yet.

---

## Release: `repo-bootstrap-foundation`

- Date: `2026-03-26`
- Status: `planned`
- Owner: `repository-maintainers`

### Summary

Standardized the root contributor workflow with canonical `make` commands, concise repository instructions, project-local Codex agent role definitions, a default Korean pull request template, and Codex-oriented skill guidance under `.agents/skills/`.

### User Impact

- Who is affected: contributors and operators working from the repository root
- What users will notice: a consistent `make` entrypoint, clearer repository expectations, documented target workspace layout, a prefilled Korean PR body template, and skill docs that reference Codex paths and workflows instead of legacy Claude-specific ones
- Expected benefits: lower onboarding friction and fewer ad hoc command conventions

### Migration Notes

- Required upgrade steps: use `make` targets from the repository root instead of ad hoc local commands
- Data or config changes: none
- Operator actions: scaffold the planned workspaces before replacing skip-based command placeholders

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `None` | no | none | No new environment variables were introduced. |

### Breaking Changes

- None.

### Rollback Notes

- Rollback trigger: root workflow changes block contributor onboarding or automation
- Rollback steps: restore the previous `AGENTS.md`, `README.md`, and `docs` guidance, then remove or simplify the `Makefile`
- Data recovery notes: none

### Known Issues

- Several documented workspaces are planned and not yet scaffolded.
- Root `make` targets intentionally skip missing workspaces until those directories are added.

---

## Release: `<version-or-name>`

- Date: `<YYYY-MM-DD>`
- Status: `<planned|shipped|rolled back>`
- Owner: `<team-or-person>`

### Summary

Briefly describe what shipped and why it matters.

### User Impact

- Who is affected:
- What users will notice:
- Expected benefits:

### Migration Notes

- Required upgrade steps:
- Data or config changes:
- Operator actions:

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `EXAMPLE_ENV_VAR` | no | none | Describe when and why it is needed. |

### Breaking Changes

- Describe any incompatible API, behavior, schema, or workflow changes.
- Include who must take action and by when.

### Rollback Notes

- Rollback trigger:
- Rollback steps:
- Data recovery notes:

### Known Issues

- List any known limitations, follow-up work, or temporary mitigations.

---
