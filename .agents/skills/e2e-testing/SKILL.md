---
name: e2e-testing
description: MoaDev's actual E2E test scaffold state (Playwright, not yet wired up) — see e2e/README.md for the current suggested first flows.
origin: MoaDev
---

`e2e/` is a placeholder scaffold — no `playwright.config.ts` exists yet and no specs have been written. `e2e/README.md` lists the suggested first critical flows (reviewing curated tech news, inspecting PR activity, moving from an item to a follow-up action) — check it before assuming test infra is in place.

No wallet/Web3/financial flows exist in this repo — ignore any E2E guidance elsewhere that assumes them.

When setting up the first real suite: standard Playwright conventions apply (Page Object Model, `data-testid` locators, auto-waiting over `waitForTimeout`) — a frontier model doesn't need these spelled out, just wire up `playwright.config.ts` with `testDir: './e2e'` and go from there.
