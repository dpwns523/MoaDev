---
description: Activate TDD workflow — write tests first, implement, verify 80%+ coverage
---

Confirm what you're building, then: write failing tests covering the happy path, edge cases, and error scenarios (RED) → implement the minimal code to pass them (GREEN) → refactor while keeping tests green → check coverage against the ~80% default in CLAUDE.md.

For non-trivial changes, spawn `reviewer` afterward to validate; skip it for small/obvious ones.

```bash
npm test                    # web: run all tests
npm run test:coverage       # web: with coverage report
pytest --cov=. --cov-report=term-missing   # api: with coverage
make test                   # all services
```
