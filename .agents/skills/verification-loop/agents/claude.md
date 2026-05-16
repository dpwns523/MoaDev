---
interface:
  display_name: "Verification Loop"
  short_description: "Build, typecheck, lint, test, and security verification"
  brand_color: "#10B981"
  slash_command: "/verify"
  default_prompt: "Run full verification: build → typecheck → lint → test → security scan → diff review"
policy:
  allow_implicit_invocation: true
  trigger_patterns:
    - "before.*PR"
    - "before.*merge"
    - "ready.*review"
    - "check.*everything"
claude:
  model: "claude-sonnet-4-6"
  read_skill_md: true
---
