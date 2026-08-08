---
interface:
  display_name: "E2E Testing"
  short_description: "Playwright end-to-end tests for critical user flows"
  brand_color: "#06B6D4"
  default_prompt: "Write Playwright E2E tests covering critical user flows with semantic selectors and proper assertions"
policy:
  allow_implicit_invocation: true
  trigger_patterns:
    - "e2e"
    - "playwright"
    - "end-to-end"
    - "user flow"
    - "browser test"
claude:
  model: "claude-sonnet-4-6"
  read_skill_md: true
---
