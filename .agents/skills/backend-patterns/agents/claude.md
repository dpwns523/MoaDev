---
interface:
  display_name: "Backend Patterns"
  short_description: "FastAPI, SQLAlchemy, PostgreSQL, and caching patterns"
  brand_color: "#F59E0B"
  default_prompt: "Apply FastAPI best practices: repository pattern, Pydantic validation, async handlers, proper error handling"
policy:
  allow_implicit_invocation: true
  trigger_patterns:
    - "fastapi"
    - "endpoint"
    - "database"
    - "sqlalchemy"
    - "repository"
    - "api route"
claude:
  model: "claude-sonnet-4-6"
  read_skill_md: true
---
