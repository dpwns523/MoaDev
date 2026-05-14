---
description: Run security review checklist — secrets, input validation, injection prevention, auth, rate limiting
---

Read `.agents/skills/security-review/SKILL.md` and run the complete security checklist against the current code changes.

## Quick Scan (run immediately)

```bash
# 1. Hardcoded secrets
grep -rn "sk-\|api_key\s*=\s*['\"][^'\"]\|password\s*=\s*['\"][^'\"]" \
  --include="*.ts" --include="*.tsx" --include="*.py" \
  . | grep -v node_modules | grep -v ".git" | grep -v ".env" | head -20

# 2. console.log in production code
grep -rn "console\.log\|print(" \
  --include="*.ts" --include="*.tsx" --include="*.py" \
  apps/ services/ | head -20

# 3. TODO/FIXME security notes
grep -rn "TODO.*auth\|FIXME.*security\|HACK.*bypass" \
  --include="*.ts" --include="*.py" \
  apps/ services/ | head -10

# 4. Dependency vulnerabilities
cd apps/web && npm audit --audit-level=high 2>&1 | tail -20
```

## Checklist

Work through each category and mark pass/fail:

**Secrets Management**
- [ ] No hardcoded API keys, tokens, or passwords
- [ ] All secrets in environment variables
- [ ] `.env.local` in .gitignore
- [ ] No secrets in git history

**Input Validation**
- [ ] All user inputs validated with schemas (Zod / Pydantic)
- [ ] File uploads restricted (size, type, extension)
- [ ] No direct user input in queries

**Injection Prevention**
- [ ] All database queries parameterized (no string concatenation)
- [ ] ORM/query builder used correctly
- [ ] HTML output sanitized (DOMPurify or equivalent)

**Authentication & Authorization**
- [ ] Tokens in httpOnly cookies (not localStorage)
- [ ] Authorization checks before sensitive operations
- [ ] Role-based access control implemented

**API Security**
- [ ] Rate limiting on all endpoints
- [ ] CORS properly configured
- [ ] Error messages generic (no stack traces to users)

## Output Report

```
SECURITY REVIEW REPORT
======================
Secrets:        [PASS/FAIL]
Input Validation: [PASS/FAIL]
Injection:      [PASS/FAIL]
Auth/Authz:     [PASS/FAIL]
API Security:   [PASS/FAIL]

CRITICAL Issues (block merge):
- ...

HIGH Issues (fix soon):
- ...

APPROVED
```

If CRITICAL issues are found: STOP work → fix all CRITICAL issues → re-run this command → then continue.
