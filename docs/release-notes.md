# Release Notes

Use this file as the standard release template. For each release, duplicate the template block below, replace placeholders, and keep the newest release at the top.

If a section does not apply, write `None`.

---

## Release: `repo-bootstrap-foundation`

- Date: `2026-03-26`
- Status: `planned`
- Owner: `repository-maintainers`

### Summary

Standardized the root contributor workflow with canonical `make` commands, concise repository instructions, project-local Codex agent role definitions, and a default Korean pull request template.

### User Impact

- Who is affected: contributors and operators working from the repository root
- What users will notice: a consistent `make` entrypoint, clearer repository expectations, documented target workspace layout, and a prefilled Korean PR body template
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
