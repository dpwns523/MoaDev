# Release Notes

Use this file as the standard release template. For each release, duplicate the template block below, replace placeholders, and keep the newest release at the top.

If a section does not apply, write `None`.

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
