---
name: database-migrations
description: Alembic migration conventions for MoaDev's services/api (SQLAlchemy/PostgreSQL) — not Prisma/Drizzle/Django/golang-migrate, which this repo doesn't use.
origin: MoaDev
---

`services/api` uses Alembic. Migration files live under `services/api/alembic/versions/`, named `<timestamp>_<short_slug>.py` (e.g. `20260421_0001_article_persistence_baseline.py`).

```bash
cd services/api
alembic revision --autogenerate -m "description"   # generate from model diff
alembic upgrade head                                 # apply pending
alembic downgrade -1                                  # roll back one
```

Production-safety reminders worth applying even though the model already knows the SQL for these — the risk is forgetting to *think* about lock behavior on a large table, not not knowing the syntax:
- Adding `NOT NULL` to an existing column without a default rewrites and locks the whole table — add nullable, backfill, then constrain in a later migration.
- `CREATE INDEX` blocks writes on large tables — use `CREATE INDEX CONCURRENTLY` (can't run inside a transaction; Alembic needs `with op.get_context().autocommit_block():` for this).
- Keep schema changes (DDL) and data backfills (DML) as separate migrations — easier to reason about and roll back independently.
- Never edit a migration that's already run in an environment — write a new one.
