# ECC for Claude Code

This supplements the root `CLAUDE.md` with Claude Code-specific guidance.

## Model Recommendations

| Task Type | Recommended Model |
|-----------|------------------|
| Routine coding, tests, formatting | claude-sonnet-4-6 |
| Complex features, architecture | claude-sonnet-4-6 |
| Debugging, refactoring | claude-sonnet-4-6 |
| Security review | claude-sonnet-4-6 |
| Fast lookups, simple transforms | claude-haiku-4-5-20251001 |
| Highest-stakes decisions | claude-opus-4-6 |

## Skills Discovery

Skills are loaded from `.agents/skills/`. Each skill contains:
- `SKILL.md` — Detailed instructions and workflow
- `agents/openai.yaml` — Codex interface metadata
- `agents/claude.md` — Claude Code interface metadata

Available skills with Claude slash commands:
- `tdd-workflow` → `/tdd` — Test-driven development with 80%+ coverage
- `security-review` → `/security` — Comprehensive security checklist
- `verification-loop` → `/verify` — Build, test, lint, typecheck, security
- `frontend-patterns` — React/Next.js patterns
- `backend-patterns` — FastAPI, SQLAlchemy, PostgreSQL patterns
- `e2e-testing` — Playwright E2E tests
- `coding-standards` — Universal coding standards
- `api-design` — REST API design patterns
- `python-patterns` — Python development patterns
- `python-testing` — Python testing practices
- `database-migrations` — DB migration patterns
- `deployment-patterns` — Deployment best practices
- `docker-patterns` — Docker patterns
- `issue-driven-planning` — Issue-driven planning workflow
- `strategic-compact` — Context management
- `eval-harness` — Eval-driven development

## Subagents

Claude Code subagents are defined in `.claude/agents/`. Use the **Task tool** to spawn them:

```python
# Example: spawn explorer before making edits
Task(
  description="Explore the auth module before modifying it",
  prompt="Read .claude/agents/explorer.md for instructions. Trace the auth flow in services/api/... and report findings."
)
```

Available subagents:
- `explorer` — Read-only evidence gathering (spawn before edits)
- `reviewer` — Correctness/security review (spawn after edits)
- `docs-researcher` — API and release-note verification
- `platform-engineer` — Kubernetes, Helm, Argo CD, Terraform → `/platform`
- `observability-reviewer` — Metrics, logs, traces, dashboards
- `release-manager` — CI/CD, GitOps, release notes

## Key Differences from Codex CLI

| Feature | Claude Code | Codex CLI |
|---------|------------|-----------|
| Context file | `CLAUDE.md` + `AGENTS.md` | `AGENTS.md` only |
| Skills | `.agents/skills/` + `/command` | `.agents/skills/` + instruction |
| Subagents | Task tool + `.claude/agents/*.md` | `/agent` + `.codex/agents/*.toml` |
| Hooks | 8+ event types (PreToolUse, PostToolUse, etc.) | Not supported |
| MCP | Full support | `config.toml` + `codex mcp add` |
| Settings | `.claude/settings.json` | `.codex/config.toml` |
| Models | claude-sonnet-4-6 / opus-4-6 / haiku-4-5 | gpt-5.4 |

## Claude Code Hooks

Claude Code supports hooks for automated quality enforcement. Example hooks to consider adding in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "echo 'Running bash command'"}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{"type": "command", "command": "cd $PROJECT_ROOT && make lint 2>&1 | head -20"}]
      }
    ]
  }
}
```

## Security Without Hooks Fallback

If hooks are not configured, use instruction-based enforcement:
1. Always validate inputs at system boundaries
2. Never hardcode secrets — use environment variables
3. Run `npm audit` / `pip-audit` before committing
4. Run `/security` command before opening PRs
5. Use `make verify` as the pre-PR gate

## Context Management

Claude Code's context window is large but finite. For long sessions:
- Use `/compact` to compress conversation history
- Spawn subagents for isolated tasks (they start fresh)
- Read only the file sections you need
- Use `make verify` output rather than reading full test logs
