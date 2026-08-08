---
interface:
  display_name: "Security Review"
  short_description: "Comprehensive security checklist and vulnerability detection"
  brand_color: "#EF4444"
  slash_command: "/security"
  default_prompt: "Run security checklist: secrets, input validation, injection prevention, auth, rate limiting"
policy:
  allow_implicit_invocation: true
  trigger_patterns:
    - "authentication"
    - "authorization"
    - "secret"
    - "api.key"
    - "password"
    - "token"
    - "user.input"
    - "file.upload"
    - "payment"
claude:
  model: "claude-sonnet-4-6"
  read_skill_md: true
---
