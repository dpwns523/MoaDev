---
name: issue-driven-planning
description: Use this skill when the team wants GitHub Issues to be the source of truth for planning and execution instead of a docs task list. It helps structure epic and task issues with priorities, acceptance criteria, planned files, verification, and branch strategy.
origin: MoaDev
---

# Issue-Driven Planning

Use this skill when work should be tracked in GitHub Issues rather than `docs/task-list.md`.

## Source of Truth

- GitHub Issues are the canonical tracker for planned, active, and follow-up work.
- `docs/task-list.md` is only a migration pointer and should not hold live status.
- Keep user-visible or operator-visible changes in `docs/release-notes.md`, but keep execution state in Issues.

## Templates

- Use `.github/ISSUE_TEMPLATE/recovery-epic.yml` for milestone-sized work such as `P0`, `P1`, and `P2`.
- Use `.github/ISSUE_TEMPLATE/recovery-task.yml` for implementable units that should fit into a focused PR.

## Workflow

1. Decide whether the work is an Epic or a Task.
2. Fill in priority (`P0`, `P1`, `P2`) and keep the title outcome-focused.
3. Write clear scope and explicit out-of-scope boundaries.
4. List planned files before implementation when practical.
5. Define acceptance criteria as checkboxes.
6. Add concrete verification commands such as `make test` or `make verify`.
7. Link the PR back to the issue and record any follow-up work as new issues instead of hidden TODOs.

## Branching

- One focused issue should usually map to one focused branch and one PR.
- Good branch patterns:
  - `codex/issue-123-api-feed-validation`
  - `codex/p0-baseline-recovery`
- Split branches when the work crosses different review surfaces, such as app code vs infra vs docs-only work.

## Epic Guidelines

- Epics coordinate a milestone, not a grab bag of unrelated work.
- Keep child issues small enough that each can be reviewed and rolled back independently.
- Put cross-cutting risks, dependency order, and verification expectations in the Epic.

## Task Guidelines

- Tasks should be implementable without hidden subprojects.
- Prefer test-first wording when the task changes behavior.
- Planned files should stay narrow; if the list keeps growing, split the task.

## Completion Rule

- Close the issue only after the linked PR is merged and the acceptance criteria are actually met.
- If any scope is deferred, open a follow-up issue before closing the current one.
