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

1. **Agent-First** — Delegate to specialized subagents for domain tasks
2. **Test-Driven** — Write tests before implementation; 80%+ coverage required
3. **Security-First** — Never compromise on security; validate all inputs
4. **Immutability** — Always create new objects, never mutate existing ones
5. **Plan Before Execute** — Plan complex features before writing code

## Available Subagents

Use the Task tool to spawn subagents defined in `.claude/agents/`:

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| explorer | Read-only codebase exploration | Before any edit — gather evidence |
| reviewer | Correctness, security, regression review | After writing/modifying code |
| docs-researcher | API and framework doc verification | Verify behavior before implementing |
| platform-engineer | Kubernetes, Helm, Terraform, Argo CD | Infrastructure changes |
| observability-reviewer | Metrics, logs, traces, dashboards | Telemetry and monitoring changes |
| release-manager | CI/CD, GitOps, release notes | Release and deployment workflows |

### Agent Orchestration

Spawn agents proactively — don't wait for the user to ask:
- Complex feature requests → **explorer** first, then implement
- Code just written/modified → **reviewer**
- Bug fix or new feature → use tdd-workflow skill
- Architectural decision → **explorer** + **docs-researcher** in parallel
- Security-sensitive code → **reviewer** with security focus
- Platform/infra changes → **platform-engineer**
- Monitoring changes → **observability-reviewer**
- Release prep → **release-manager**

Use **parallel execution** for independent operations — spawn multiple agents simultaneously.

## Skills

Skills are located in `.agents/skills/`. Each skill contains a `SKILL.md` with detailed instructions. Activate the relevant skill by reading its `SKILL.md` before executing the workflow.

| Skill | Path | Purpose |
|-------|------|---------|
| tdd-workflow | `.agents/skills/tdd-workflow/` | TDD with 80%+ coverage |
| security-review | `.agents/skills/security-review/` | Security checklist and patterns |
| verification-loop | `.agents/skills/verification-loop/` | Build, test, lint, typecheck |
| coding-standards | `.agents/skills/coding-standards/` | Universal coding standards |
| frontend-patterns | `.agents/skills/frontend-patterns/` | React/Next.js patterns |
| backend-patterns | `.agents/skills/backend-patterns/` | API design, database, caching |
| api-design | `.agents/skills/api-design/` | REST API design patterns |
| python-patterns | `.agents/skills/python-patterns/` | Python development patterns |
| python-testing | `.agents/skills/python-testing/` | Python testing practices |
| database-migrations | `.agents/skills/database-migrations/` | DB migration patterns |
| e2e-testing | `.agents/skills/e2e-testing/` | Playwright E2E tests |
| deployment-patterns | `.agents/skills/deployment-patterns/` | Deployment best practices |
| docker-patterns | `.agents/skills/docker-patterns/` | Docker patterns |
| issue-driven-planning | `.agents/skills/issue-driven-planning/` | Issue-driven workflow |

## Slash Commands

Use these Claude Code slash commands for common workflows:

- `/tdd` — Activate TDD workflow
- `/verify` — Run verification loop (build, test, lint, types, security)
- `/security` — Run security review checklist
- `/platform` — Platform engineering review

## Security Guidelines

**Before ANY commit:**
- No hardcoded secrets (API keys, passwords, tokens)
- All user inputs validated (use Zod for TypeScript, Pydantic for Python)
- SQL injection prevention (parameterized queries only)
- XSS prevention (sanitized HTML output)
- CSRF protection enabled
- Authentication/authorization verified
- Rate limiting on all API endpoints
- Error messages don't leak sensitive data

**Secret management:** NEVER hardcode secrets. Use environment variables or a secret manager. Validate required secrets at startup. Rotate any exposed secrets immediately.

**If a security issue is found:** STOP → spawn **reviewer** agent → fix CRITICAL issues → rotate exposed secrets → review codebase for similar issues.

## Coding Style

**Immutability (CRITICAL):** Always create new objects, never mutate. Return new copies with changes applied.

**File organization:** Many small files over few large ones. 200–400 lines typical, 800 max. Organize by feature/domain, not by type. High cohesion, low coupling.

**Error handling:** Handle errors at every level. Provide user-friendly messages in UI code. Log detailed context server-side. Never silently swallow errors.

**Input validation:** Validate all user input at system boundaries. Use schema-based validation (Zod / Pydantic). Fail fast with clear messages. Never trust external data.

**Code quality checklist:**
- Functions small (<50 lines), files focused (<800 lines)
- No deep nesting (>4 levels)
- Proper error handling, no hardcoded values
- Readable, well-named identifiers

## Testing Requirements

**Minimum coverage: 80%**

Test types (all required):
1. **Unit tests** — Individual functions, utilities, components
2. **Integration tests** — API endpoints, database operations
3. **E2E tests** — Critical user flows (Playwright)

**TDD workflow (mandatory):**
1. Write test first (RED) — test should FAIL
2. Write minimal implementation (GREEN) — test should PASS
3. Refactor (IMPROVE) — verify coverage ≥ 80%

Run tests: `make test` or per-service `npm test` / `pytest`

## Development Workflow

1. **Explore** — Spawn **explorer** agent to gather codebase evidence
2. **Plan** — Identify dependencies and risks, break into phases
3. **TDD** — Write tests first, implement, refactor (use `/tdd` command)
4. **Review** — Spawn **reviewer** agent; address CRITICAL/HIGH issues immediately
5. **Verify** — Run `/verify` before opening PR
6. **Capture knowledge** in the right place:
   - Team/project knowledge (architecture decisions, API changes, runbooks) → `docs/`
   - If no obvious doc location, ask before creating new top-level files
7. **Commit** — Conventional commits format, comprehensive PR summaries

## Git Workflow

**Commit format:** `<type>: <description>`
Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

**PR workflow:** Analyze full commit history → draft comprehensive summary → include test plan → push with `-u` flag.

## Architecture Patterns

**API response format (FastAPI):** Consistent envelope with `success`, `data`, `error`, and `meta` fields.

**Repository pattern:** Encapsulate data access behind standard interface (`list`, `get`, `create`, `update`, `delete`). Business logic depends on abstract interface, not storage mechanism.

**Agents runtime:** The `services/agents-runtime/` service orchestrates AI agent workflows. Prefer stateless handlers, idempotent operations, and explicit retry logic.

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

## Performance

**Context management:** Avoid last 20% of context window for large refactoring and multi-file features. Lower-sensitivity tasks (single edits, docs, simple fixes) tolerate higher utilization.

**Build troubleshooting:** Analyze errors incrementally — fix one category at a time, verify after each fix.

## Success Metrics

- All tests pass with 80%+ coverage
- No security vulnerabilities
- Code is readable and maintainable
- Performance is acceptable
- User requirements are met
