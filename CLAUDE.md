# MoaDev — Claude Code Instructions

This is a **production-ready AI knowledge platform monorepo** providing authenticated aggregation of external technology content with structured Korean translation and explanation outputs.

## Project Structure

```
apps/web/              — Next.js 16 frontend (React 19, NextAuth 5)
services/api/          — FastAPI backend (SQLAlchemy, PostgreSQL, Alembic)
services/agents-runtime/ — Agent orchestration service (Python 3.9+)
infra/terraform/       — Terraform IaC (dev/prod envs)
platform/helm/         — Kubernetes Helm charts
platform/argocd/       — GitOps manifests
platform/monitoring/   — Monitoring stack
docs/                  — Project documentation
.agents/skills/        — Reusable skill definitions
.claude/agents/        — Claude Code subagent definitions
.claude/commands/      — Slash command definitions
```

## Core Principles

1. **Security-First** — Never compromise on security; validate all inputs
2. **Immutability** — Always create new objects, never mutate existing ones
3. **Tests as default** — This repo's convention is tests-first with ~80% coverage; deviate with justification, not silently
4. **Delegate deliberately** — Use a subagent when the task needs parallel exploration, an isolated context window, or a distinct tool-permission boundary. For small or sequential work, just do it directly.

## Available Subagents

Spawn via the Task tool from `.claude/agents/` when delegation genuinely helps (see Core Principles above) — not as a fixed step for every task.

| Agent | Purpose |
|-------|---------|
| explorer | Read-only codebase/doc research — evidence gathering, API/framework behavior verification |
| reviewer | Correctness, security, regression, and test-coverage review |
| platform-engineer | Kubernetes, Helm, Terraform, Argo CD |
| observability-reviewer | Metrics, logs, traces, dashboards, alerts |
| release-manager | CI/CD, GitOps, release notes |

## Skills

Skills live in `.agents/skills/`, each with a `SKILL.md`. Read one when its purpose matches the current task — they hold project-specific information you can't derive from the codebase alone, not general coding advice.

| Skill | Path | Purpose |
|-------|------|---------|
| issue-driven-planning | `.agents/skills/issue-driven-planning/` | Issue-driven workflow conventions |
| security-review | `.agents/skills/security-review/` | Security checks specific to this stack |
| verification-loop | `.agents/skills/verification-loop/` | Build/test/lint loop mechanics |
| database-migrations | `.agents/skills/database-migrations/` | Alembic conventions for this repo |
| e2e-testing | `.agents/skills/e2e-testing/` | Playwright setup and test infra facts |
| deployment-patterns | `.agents/skills/deployment-patterns/` | This repo's deploy topology/env facts |
| docker-patterns | `.agents/skills/docker-patterns/` | Base images and registry conventions used here |
| eval-harness | `.agents/skills/eval-harness/` | Agent evaluation harness mechanics |
| search-first | `.agents/skills/search-first/` | Repo-specific search-tool facts |
| cost-aware-llm-pipeline | `.agents/skills/cost-aware-llm-pipeline/` | LLM pipeline cost/model-selection guidance |
| strategic-compact | `.agents/skills/strategic-compact/` | Context-compaction mechanics |

## Slash Commands

- `/tdd` — Activate TDD workflow
- `/verify` — Run verification loop (build, test, lint, types, security)
- `/security` — Run security review checklist
- `/platform` — Platform engineering review

## Security Guidelines

**Before ANY commit:**
- No hardcoded secrets (API keys, passwords, tokens)
- All user inputs validated (Zod for TypeScript, Pydantic for Python)
- Parameterized queries only; sanitized HTML output
- CSRF protection, auth/authz verified, rate limiting on all endpoints
- Error messages don't leak sensitive data

**Secrets:** never hardcode; use environment variables or a secret manager; validate required secrets at startup; rotate any exposed secret immediately, no exceptions.

**On a real finding:** fix CRITICAL issues before merging, and rotate any exposed secret right away — everything else is judgment on sequencing.

## Coding Style

**Immutability (CRITICAL):** Always create new objects, never mutate. Return new copies with changes applied.

**File organization:** Many small files over few large ones (200–400 lines typical, 800 max), organized by feature/domain.

**Error handling & validation:** Handle errors at every level; log detail server-side, keep UI messages friendly; validate all input at system boundaries with schema-based validation (Zod/Pydantic); never trust external data.

## Testing Requirements

Unit, integration, and E2E (Playwright) tests are all expected for non-trivial changes, at ~80% coverage. TDD (test first, minimal implementation, refactor) is this repo's default workflow — use `/tdd` for a fuller pass.

Run tests: `make test` or per-service `npm test` / `pytest`.

## Development Workflow

1. Understand the change — read the relevant code directly, or delegate to `explorer` if it needs parallel/isolated research
2. Plan non-trivial work before writing code
3. Implement, test-first by default
4. Review before opening a PR — delegate to `reviewer` for non-trivial changes; use judgment for small ones
5. `/verify` before opening a PR
6. Capture durable project knowledge in `docs/`; ask before creating new top-level files if there's no obvious location
7. Commit with conventional commit format; write a comprehensive PR summary

## Git Workflow

**Commit format:** `<type>: <description>`
Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

**PR workflow:** Analyze full commit history → draft comprehensive summary → include test plan → push with `-u` flag.

**Language:** Always write GitHub-facing content (PR titles/descriptions, issue titles/bodies, PR comments) in Korean. Commit messages stay in English per the format above.

## Architecture Patterns

**API response format (FastAPI):** Consistent envelope with `success`, `data`, `error`, and `meta` fields.

**Repository pattern:** Encapsulate data access behind a standard interface (`list`, `get`, `create`, `update`, `delete`); business logic depends on the abstract interface, not the storage mechanism.

**Agents runtime:** `services/agents-runtime/` orchestrates AI agent workflows. Prefer stateless handlers, idempotent operations, explicit retry logic.

## Make Targets

```bash
make bootstrap   # Install all dependencies (npm, pip venvs)
make build       # Build web app
make test        # Run all tests (web, api, agents-runtime)
make lint        # Lint all services + Terraform
make typecheck   # TypeScript & Python type checking
make e2e         # Run Playwright end-to-end tests
make verify      # Full verification: lint + typecheck + test + tf-validate
make format      # Format code (Prettier, Ruff, Terraform)
```

## Context Management

Avoid the last 20% of context window for large refactors and multi-file features; docs/simple fixes tolerate higher utilization. When troubleshooting a build, fix one error category at a time and verify after each fix.

## Adding to This Harness

Before adding a skill, agent, or checklist item, ask: *is this information the model can't derive from the codebase, training knowledge, or plain reasoning — and would getting it wrong actually break something (correctness, security, compliance)?* If it's generic best-practice coaching or a style preference a frontier model already applies, don't add it.
