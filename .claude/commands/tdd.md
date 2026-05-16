---
description: Activate TDD workflow — write tests first, implement, verify 80%+ coverage
---

Read `.agents/skills/tdd-workflow/SKILL.md` and follow the TDD workflow for the current task.

## Execution Steps

1. **Identify what to build** — confirm the feature, bug fix, or refactor target with the user
2. **Write user journeys** — define expected behavior as user stories before touching any code
3. **Generate failing tests** — write comprehensive tests covering happy paths, edge cases, and error scenarios; run them to confirm they fail (RED)
4. **Implement minimal code** — write the smallest implementation that makes tests pass (GREEN)
5. **Run tests** — confirm all tests pass: `make test` or `npm test` / `pytest`
6. **Refactor** — improve code quality while keeping tests green
7. **Verify coverage** — run coverage report and confirm ≥ 80%: `npm run test:coverage` / `pytest --cov`
8. **Spawn reviewer** — use the Task tool to spawn the `reviewer` subagent to validate the implementation

## Coverage Targets

- Branches: 80%+
- Functions: 80%+
- Lines: 80%+
- Statements: 80%+

## Quick Reference

```bash
# Web (Next.js)
npm test                    # run all tests
npm run test:coverage       # run with coverage report
npm test -- --watch         # watch mode

# API (FastAPI/pytest)
pytest                      # run all tests
pytest --cov=. --cov-report=term-missing  # with coverage

# All services
make test                   # runs all service tests
```
