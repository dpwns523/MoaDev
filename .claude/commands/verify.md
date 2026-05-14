---
description: Run full verification loop — build, typecheck, lint, test, security scan, diff review
---

Read `.agents/skills/verification-loop/SKILL.md` and run all verification phases. Use `make verify` if available; fall back to individual commands per phase.

## Verification Phases

Run each phase in order. STOP and report if a phase fails.

### Phase 1 — Build
```bash
make build
# or: cd apps/web && npm run build
```

### Phase 2 — Type Check
```bash
make typecheck
# or: cd apps/web && npx tsc --noEmit
# or: cd services/api && mypy .
```

### Phase 3 — Lint
```bash
make lint
# or: cd apps/web && npm run lint
# or: cd services/api && ruff check .
```

### Phase 4 — Tests with Coverage
```bash
make test
# or: cd apps/web && npm run test:coverage
# or: cd services/api && pytest --cov=. --cov-report=term-missing
```

### Phase 5 — Security Scan
```bash
# Check for hardcoded secrets
grep -rn "sk-" --include="*.ts" --include="*.py" . | grep -v node_modules | grep -v ".git" | head -10
grep -rn "api_key\s*=" --include="*.ts" --include="*.py" . | grep -v node_modules | head -10

# Dependency audit
cd apps/web && npm audit
cd services/api && pip-audit 2>/dev/null || echo "pip-audit not installed"
```

### Phase 6 — Diff Review
```bash
git diff --stat
git diff HEAD~1 --name-only 2>/dev/null || git diff --cached --name-only
```

## Output Report

After all phases, produce:

```
VERIFICATION REPORT
===================
Build:      [PASS/FAIL]
Types:      [PASS/FAIL] (N errors)
Lint:       [PASS/FAIL] (N warnings)
Tests:      [PASS/FAIL] (N/M passed, X% coverage)
Security:   [PASS/FAIL] (N issues)
Diff:       N files changed

Overall:    [READY / NOT READY] for PR

Issues to Fix:
1. ...
```
