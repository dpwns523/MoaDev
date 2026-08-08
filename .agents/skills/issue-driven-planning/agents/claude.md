---
interface:
  display_name: "Issue-Driven Planning"
  short_description: "Break features into GitHub issues before coding"
  brand_color: "#6366F1"
  default_prompt: "Plan this feature as a set of scoped GitHub issues with acceptance criteria before writing code"
policy:
  allow_implicit_invocation: true
  trigger_patterns:
    - "plan.*feature"
    - "break.*down"
    - "github issue"
    - "complex.*feature"
claude:
  model: "claude-sonnet-4-6"
  read_skill_md: true
---
