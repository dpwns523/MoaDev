---
name: security-review
description: Security checks specific to MoaDev's actual stack (Next.js/NextAuth, FastAPI/SQLAlchemy). Use alongside CLAUDE.md's Security Guidelines, not instead of it — that has the canonical checklist.
origin: MoaDev
---

CLAUDE.md's Security Guidelines section is the canonical checklist (secrets, input validation, injection, XSS, CSRF, auth, rate limiting). This skill only adds what's specific to MoaDev's stack:

**NextAuth 5 (web):** session tokens are httpOnly cookies by default — don't move them to localStorage. OAuth callback URLs must be allowlisted per provider config, not wildcarded.

**FastAPI (api):** authorization checks belong in dependency-injected guards (`app/core/security.py` / `app/api/dependencies/auth.py`), not scattered inline in route handlers — keeps the check point auditable in one place.

**SQLAlchemy:** use the ORM/query builder, never raw string-interpolated SQL — parameterization is automatic when you don't build queries with f-strings.

**Dependency audit:** `npm audit --audit-level=high` (web) and `pip-audit` (api) — neither runs in CI by default, so run manually before a release-relevant change.

No Supabase, no blockchain/wallet code in this repo — ignore security guidance elsewhere that assumes either.
