---
name: verification-loop
description: When to re-run verification during a long session — the mechanics themselves live in the /verify command.
origin: MoaDev
---

Use `/verify` for the actual build/typecheck/lint/test/security/diff loop — this skill only covers cadence: for a long session, re-verify after finishing a component or function, not just once at the very end. Catching a regression right after introducing it is far cheaper than finding it after several more changes are stacked on top.
