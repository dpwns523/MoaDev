---
interface:
  display_name: "TDD Workflow"
  short_description: "Test-driven development with 80%+ coverage"
  brand_color: "#22C55E"
  slash_command: "/tdd"
  default_prompt: "Follow TDD: write failing tests first, implement minimal code, verify ≥80% coverage"
policy:
  allow_implicit_invocation: true
  trigger_patterns:
    - "write.*test"
    - "new feature"
    - "fix.*bug"
    - "add.*endpoint"
    - "refactor"
claude:
  model: "claude-sonnet-4-6"
  read_skill_md: true
---
