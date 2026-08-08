---
description: Run full verification loop — build, typecheck, lint, test, security scan, diff review
---

Use `make verify` if available; otherwise run phases individually. Report failures as you go — continue to phases that don't depend on the failed one (e.g. lint and typecheck are independent of each other), but skip phases that are meaningless without an earlier one (e.g. tests after a failed build, if the build output is what's under test).

```bash
make build       # or: cd apps/web && npm run build
make typecheck    # or: cd apps/web && npx tsc --noEmit  /  cd services/api && mypy .
make lint         # or: cd apps/web && npm run lint  /  cd services/api && ruff check .
make test         # or: npm run test:coverage  /  pytest --cov=. --cov-report=term-missing
```

Security scan and diff review:
```bash
grep -rn "sk-\|api_key\s*=" --include="*.ts" --include="*.py" . | grep -v node_modules | grep -v ".git" | head -10
cd apps/web && npm audit; cd services/api && pip-audit 2>/dev/null || true
git diff --stat
```

End with a short summary of what passed/failed and whether the change is ready for a PR — size the report to what actually failed, not a fixed template.
