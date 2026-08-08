---
name: search-first
description: Check for an existing solution (in-repo, or a maintained package) before writing custom code — and this repo's actual package-manager facts.
origin: MoaDev
---

Before writing a new utility or dependency, check the repo first (`grep`/`Glob` for existing implementations), then a maintained package — a model already knows to do this, the value here is just the repo-specific facts:

- **apps/web**: npm, `npm install` (see `Makefile`'s `bootstrap` target)
- **services/api**, **services/agents-runtime**: plain `venv` + `pip install -e ".[dev]"` — no Poetry, no uv
- Check `.codex/config.toml` for configured MCP servers before assuming one doesn't exist

Avoid wrapping a library so heavily it loses its benefit, and avoid pulling in a large dependency for something a few lines of code would cover.
