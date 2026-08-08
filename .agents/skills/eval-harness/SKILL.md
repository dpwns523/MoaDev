---
name: eval-harness
description: Eval-driven development for agent-implemented features — define pass/fail criteria before implementing, track regressions across changes.
origin: MoaDev
tools: Read, Write, Edit, Bash, Grep, Glob
---

Before implementing an agent-driven feature, write capability + regression criteria to `.codex/evals/<feature>.md` (path is tool-agnostic — applies whether the session is Codex or Claude Code), then implement against them and log results to `.codex/evals/<feature>.log`.

Prefer deterministic code graders (`grep`/test-pattern/build-succeeds checks) over model-graded rubrics where possible; reserve human review for security-sensitive or genuinely ambiguous outputs — don't fully automate those.

`pass@k` = at least one success in k attempts (use for capability evals, target >90% at k=3); `pass^k` = all k attempts succeed (use for regression evals on release-critical paths, target 100%). Avoid overfitting evals to known examples, and don't let a flaky grader sit in a release gate.
