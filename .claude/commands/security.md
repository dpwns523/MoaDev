---
description: Run security review checklist — secrets, input validation, injection prevention, auth, rate limiting
---

Read `.agents/skills/security-review/SKILL.md` for MoaDev-specific security checks. Review the current changes directly — reading the code and diff finds far more than any fixed pattern list.

## Optional fast pre-check

These catch a few obvious cases quickly, but don't substitute for actually reading the diff:

```bash
grep -rn "sk-\|api_key\s*=\s*['\"][^'\"]\|password\s*=\s*['\"][^'\"]" \
  --include="*.ts" --include="*.tsx" --include="*.py" \
  . | grep -v node_modules | grep -v ".git" | grep -v ".env" | head -20

cd apps/web && npm audit --audit-level=high 2>&1 | tail -20
```

Cover secrets management, input validation, injection prevention, auth/authz, and API security (see the MoaDev Security Guidelines in CLAUDE.md for the specific baseline).

Surface CRITICAL findings prominently and fix them before merging — rotate any exposed secret immediately, no exceptions there. Everything else (sequencing, whether to fix now vs. follow up) is a judgment call, not a mechanical gate.
