# Issue & PR Ordering Audit — dpwns523/MoaDev

**Date:** 2026-08-02  
**Scope:** All issues and PRs (open + closed/merged) as of audit date  
**Method:** Read-only analysis; no GitHub state mutations  
**Data sources:** `gh issue list --state all`, `gh pr list --state all`, local codebase explorer  

---

## 1. Product Vision Reference

Per `CLAUDE.md` and Epics #35 / #40, the canonical MoaDev product vision is:

> A **production-ready, authenticated AI knowledge platform** that aggregates external technology content (starting with Keek News / IT company tech blogs), provides structured Korean translation (line-by-line translation, summaries, glossary, concept explanations, related concepts), and delivers this through an authenticated web interface on a self-managed multi-cloud Kubernetes platform.

**Canonical dependency chain (coarse-grained):**
```
Data Registry/Persistence → Ingestion Pipeline → Authenticated API → Web UX
                             ↑
          Auth Boundary (prerequisite to all above API/Web work)
                             ↑
                Platform/Infra Scaffold (parallel P1 track)
```

**Epics (authoritative scope containers):**

| Epic | Priority | State | Summary |
|------|----------|-------|---------|
| #4 | P0 | closed | Baseline recovery (feed scaffold + tests) |
| #7 | P2 | open | Documentation hardening |
| #11 | P1 | closed | Integration recovery baseline (backfill milestone) |
| #19 | P1 | open | Self-managed OCI/AWS Kubernetes platform scaffold |
| #35 | P0 | open | AI knowledge product definition + first-production architecture |
| #40 | P0 | open | Implement closed MVP authenticated AI knowledge workflow |

---

## 2. Epic-to-Child Mapping (prose-parsed from epic bodies)

| Epic | Child Items (from epic body prose) | Status |
|------|-------------------------------------|--------|
| #4 | #5, #6 | Both closed/done |
| #7 | #8, #9, #10 | All open (backlog) |
| #11 | self-contained milestone | closed immediately |
| #19 | #12, #13, #14, #15, #16, #17, #18✓, #20✓, #25✓, #26✓, #27, #28, #29 | Mixed |
| #35 | #36✓, #37✓, #38✓, #19, #33, #12, #14, #29, #34 | Mixed |
| #40 | #41✓, #42✓, #43, #44, #45, #19, #14, #29, #34 | Mixed |

*(✓ = child closed or its implementation PR merged)*

---

## 3. Codebase Implementation-State Evidence

The following implementation states were confirmed by direct codebase inspection:

| Artifact | Location | State |
|----------|----------|-------|
| Auth boundary (web OAuth) | `apps/web/auth.ts`, `apps/web/lib/auth/` | ✅ Exists |
| Auth boundary (API) | `services/api/app/api/dependencies/auth.py`, `app/core/security.py` | ✅ Exists |
| Article domain model (SourceRegistryEntry, Article, ArticleSegment, ArticleStructuredOutput) | `services/api/app/domain/articles/models.py` | ✅ Exists |
| Article persistence migration | `services/api/alembic/versions/20260421_0001_article_persistence_baseline.py` | ✅ Exists |
| Authenticated feeds endpoint | `services/api/app/api/v1/endpoints/feeds.py` | ✅ Exists |
| Article/category/status API endpoints | `services/api/app/api/v1/endpoints/` | ❌ Missing (only `feeds.py`; PR #50 in flight) |
| Ingestion/enrichment pipeline | `services/agents-runtime/app/` | ❌ Scaffold only (`runtime.py`, `worker.py`; no ingestion logic) |
| Helm chart | `platform/helm/` | ❌ Missing (directory does not exist; PR #52 in flight) |
| Terraform VM-based cluster foundations | `infra/terraform/modules/aws_compute_nodes`, `oci_compute_nodes`, `aws_network`, `oci_network` | ✅ Exists (PR #49 merged, issue #13 still open — tracking gap) |
| Ansible group_vars scaffold | `ansible/group_vars/` | ✅ Partial (group_vars only; inventories/playbooks not found) |
| CI/CD workflows | `.github/workflows/` | ❌ Missing |

---

## 4. Complete Item Classification Table

> **Table key:**  
> - **Active** = open PR with in-flight code changes only  
> - **Prereq ✓** = explorer-confirmed implementation exists; **Prereq ✗** = not confirmed; **N/A** = closed or non-implementation item  
> - **Drift type:** `dep-inv` = dependency inversion; `pri-inv` = priority inversion; `none` = no drift  
> - **Redundant:** whether item duplicates another item's objective  

### 4.1 Issues

| # | Title | Type | State | Priority | Epic Mapping | Active | Prereq | Drift Type | Redundant | Rationale |
|---|-------|------|-------|----------|--------------|--------|--------|-----------|-----------|-----------|
| #4 | [Epic][P0] Baseline recovery | Epic | closed | P0 | Self (#4) | No | N/A | none | No | Foundational Epic; closed and delivered |
| #5 | [Task][P0][Backend] Failure-path tests and feed boundary validation | Task | closed | P0 | #4 | No | N/A | none | No | Child of #4; implemented via PR #23 |
| #6 | [Task][P0][Frontend] Minimal web home API integration | Task | closed | P0 | #4 | No | N/A | none | No | Child of #4; implemented via PR #30 |
| #7 | [Epic][P2] Documentation hardening | Epic | open | P2 | Self (#7) | No | N/A | none | No | P2 docs epic; all children open, no blocking dependency unmet |
| #8 | [Task][P2][Docs] Update architecture guide | Task | open | P2 | #7 | No | N/A | none | No | Backlog docs task; no active PR; no drift |
| #9 | [Task][P2][Docs] Update conventions guide | Task | open | P2 | #7 | No | N/A | none | No | Backlog docs task; no active PR; no drift |
| #10 | [Task][P2][Docs] Update release notes | Task | open | P2 | #7 | No | N/A | none | No | Backlog docs task; no active PR; no drift |
| #11 | [Epic][P1] Integration recovery baseline (backfill) | Epic | closed | P1 | Self (#11) | No | N/A | none | No | Historical milestone closed on creation; agents-runtime and Terraform baseline confirmed in codebase |
| #12 | [Task][P1][Docs] Add monitoring scaffold and platform docs alignment | Task | open | P1 | #19 | No | N/A | none | No | Child of #19 and referenced by #35; backlog, no active PR |
| #13 | [Task][P1][Infra] Expand Terraform for VM-based cluster foundations | Task | open | P1 | #19 | No | ✅ (modules confirmed) | none | No | **Tracking gap:** PR #49 is merged and Terraform modules exist; issue was never closed. No drift — work is done, tracking housekeeping needed |
| #14 | [Task][P1][Tooling] Add CI/CD and deploy workflow scaffold | Task | open | P1 | #19 / #35 / #40 | No | N/A | none | No | Cross-referenced by #19, #35, #40; .github/workflows/ missing; backlog, no active PR |
| #15 | [Task][P1][Infra] Add Ansible low-cost operations scaffold | Task | open | P1 | #19 | No | N/A | none | No | Ansible group_vars scaffold partial; inventory/playbooks absent; backlog, no active PR |
| #16 | [Task][P1][Infra] Add Helm chart and OCI/AWS cluster scaffold | Task | open | P1 | #19 | No (PR #52) | ✗ (no platform/ dir) | none | No | PR #52 is the active implementation; work correctly ordered after #25✓, #26✓ |
| #17 | [Task][P1][Infra] Add Kubespray bootstrap scaffold | Task | open | P1 | #19 | No | N/A | none | No | Backlog; no Kubespray files found; logically after #16 |
| #18 | [Task][P1][Tooling] Externalize mutable platform config samples | Task | closed | P1 | #19 | No | N/A | none | No | Implemented via PR #24 |
| #19 | [Epic][P1] Self-managed OCI/AWS Kubernetes platform scaffold | Epic | open | P1 | Self (#19) | No | N/A | none | No | Ongoing P1 platform epic; parallel to P0 MVP per explicit epic design |
| #20 | [Task][P1][Tooling] Audit repo gaps and add app container packaging | Task | closed | P1 | #19 | No | N/A | none | No | Implemented via PR #22; Dockerfiles confirmed present |
| #25 | [Task][P1][Infra] Define platform runtime contract and tool boundaries | Task | closed | P1 | #19 | No | N/A | none | No | Implemented via PR #31 / #32 |
| #26 | [Task][P1][Infra] Map externalized platform config into Terraform variable contracts | Task | closed | P1 | #19 | No | N/A | none | No | Implemented via PR #32 |
| #27 | [Task][P1][Infra] Define Helm values layering and release boundaries | Task | open | P1 | #19 | No | N/A | none | No | Backlog design task; **partial overlap with PR #52** — PR #52 body describes implementing values layering in the chart itself; however #27 is specifically a "define/document" scope while #16 is implementation. Not redundant, but needs coordination once PR #52 merges to avoid duplicated effort |
| #28 | [Task][P1][Infra] Define Ansible and Kubespray inventory boundaries | Task | open | P1 | #19 | No | N/A | none | No | Backlog; no active PR |
| #29 | [Task][P1][Tooling] Stage platform validation targets before root verify wiring | Task | open | P1 | #19 / #35 / #40 | No | N/A | none | No | Cross-referenced by #19, #35, #40; backlog, no active PR |
| #33 | [Task][P1][Docs] Update platform topology SVG for AWS/OCI reference architecture | Task | open | P1 | #35 | No | N/A | none | No | Child of #35; docs/assets/diagrams exists; backlog, no active PR |
| #34 | [Task][P1][Tooling] Define production launch gate, rollback, and operator runbooks | Task | open | P1 | #35 / #40 | No | N/A | none | No | Cross-referenced by #35 and #40; backlog, no active PR |
| #35 | [Epic][P0] AI knowledge product definition and first-production architecture | Epic | open | P0 | Self (#35) | No | N/A | none | No | Core planning epic; children #36/#37/#38 closed; remaining children are P1 platform items |
| #36 | [Task][P0][Docs] Define MoaDev MVP AI knowledge product and user journeys | Task | closed | P0 | #35 | No | N/A | none | No | Implemented via PR #39 |
| #37 | [Task][P0][Agents-Runtime] Define ingestion, translation, and enrichment agent roles | Task | closed | P0 | #35 | No | N/A | none | No | Implemented via PR #39 |
| #38 | [Task][P0][Architecture] Define first-production application and infrastructure design | Task | closed | P0 | #35 | No | N/A | none | No | Implemented via PR #39 |
| #40 | [Epic][P0] Implement closed MVP authenticated AI knowledge workflow | Epic | open | P0 | Self (#40) | No | N/A | none | No | Active P0 implementation epic; children #41/#42 done; #43/#44/#45 in progress |
| #41 | [Task][P0][Auth] Add authenticated session boundary for web and API | Task | closed | P0 | #40 | No | ✅ (auth.ts + dependencies/auth.py confirmed) | none | No | Implemented via PR #46; code confirmed in codebase |
| #42 | [Task][P0][Data] Add article source registry and persistence model | Task | closed | P0 | #40 | No | ✅ (models.py + migration confirmed) | none | No | Implemented via PR #48; SourceRegistryEntry, Article, ArticleSegment, ArticleStructuredOutput confirmed |
| #43 | [Task][P0][Agents-Runtime] Add seed-source ingestion and enrichment pipeline scaffold | Task | open | P0 | #40 | No | ✗ (agents-runtime has scaffold only) | none | No | Backlog; #43 logically precedes #44 in the data flow chain (ingest→publish→read), but #44 API endpoints read from DB, not from the pipeline directly — see §5 |
| #44 | [Task][P0][API] Add authenticated article, category, and processing-status APIs | Task | open | P0 | #40 | No (PR #50) | ✅ (#41 auth ✓, #42 schema ✓) | none | No | PR #50 implements this; prerequisites #41 and #42 are confirmed in code; see §5 for sequencing note with #43 |
| #45 | [Task][P0][Web] Build authenticated knowledge home, list, and article detail flows | Task | open | P0 | #40 | No | ✗ (#44 API not yet merged) | none | No | Backlog; correctly sequenced after #44 per dependency chain |
| #47 | [Task][P0][Auth] Operationalize OAuth provider setup and verification | Task | open | P0 | non-epic (logically #40) | No | N/A | none | No | Not listed in any epic body; operationalizes #41's code foundation. Logically belongs to Epic #40 but is unclaimed. No active PR. Backlog item |

### 4.2 Pull Requests

| PR# | Title | State | Priority | Epic Mapping | Active | Prereq | Drift Type | Redundant | Rationale |
|-----|-------|-------|----------|--------------|--------|--------|-----------|-----------|-----------|
| #1 | 리포지토리 워크플로와 Codex 초기 설정 부트스트랩 | merged | untagged | non-epic / out of scope | No | N/A | none | No | Foundational bootstrap PR predating Epic structure; pure chore/setup; not force-mapped |
| #2 | 핵심 워크스페이스 스캐폴드와 검증 경로 추가 | merged | untagged | non-epic / out of scope | No | N/A | none | No | Workspace scaffold; predates Epic structure; pure chore/setup; not force-mapped |
| #3 | 핵심 워크스페이스 스캐폴드와 검증 경로를 main에 반영 | merged | untagged | non-epic / out of scope | No | N/A | none | No | Merge PR for PR #2 to main; predates Epic structure; pure chore/setup; not force-mapped |
| #21 | chore: switch repository planning to issue-driven workflow | merged | untagged | non-epic / out of scope | No | N/A | none | No | Pure process/workflow change; non-epic chore; not force-mapped to any feature Epic |
| #22 | [Task][P1][Tooling] Audit repo gaps and add app container packaging | merged | P1 | #19 (→ #20) | No | N/A | none | No | Implements Issue #20; Dockerfiles confirmed present |
| #23 | feat: validate curated feed boundary | merged | P0 | #4 (→ #5) | No | N/A | none | No | Implements Issue #5 backend tests |
| #24 | [Task][P1][Tooling] Externalize mutable platform config samples | merged | P1 | #19 (→ #18) | No | N/A | none | No | Implements Issue #18 |
| #30 | feat: build editorial web home feed | merged | P0 | #4 (→ #6) | No | N/A | none | No | Implements Issue #6 minimal web-API integration |
| #31 | docs: add multi-cloud platform topology guide and diagram | merged | P1 | #19 / #35 (→ #25) | No | N/A | none | No | Topology guide; relates to #25 |
| #32 | infra: Terraform 플랫폼 계약 모듈 추가 | merged | P1 | #19 (→ #25 / #26) | No | N/A | none | No | Implements Terraform platform contract; #25/#26 |
| #39 | docs: define AI knowledge product and first-production plan | merged | P0 | #35 (→ #36, #37, #38) | No | N/A | none | No | Implements #36, #37, #38 together |
| #46 | feat(auth): web OAuth와 API 인증 세션 경계 추가 | merged | P0 | #40 (→ #41) | No | N/A | none | No | Implements Issue #41; auth code confirmed in codebase |
| #48 | feat(data): add article persistence baseline | merged | P0 | #40 (→ #42) | No | N/A | none | No | Implements Issue #42; models + migration confirmed |
| #49 | [Task][P1][Infra] Expand Terraform for VM-based cluster foundations | merged | P1 | #19 (→ #13) | No | N/A | none | No | Implements Issue #13 (Terraform VM modules); modules confirmed; issue #13 not closed — tracking gap |
| #50 | [Task][P0][API] Add authenticated article, category, and processing-status APIs | open | P0 | #40 (→ #44) | **Yes** | ✅ (#41, #42 confirmed) | none | No | Active; prerequisites confirmed; see §5 for ordering note with #43 |
| #51 | feat: migrate Codex agent config to Claude Code | merged | untagged | non-epic / out of scope | No | N/A | none | **Yes (see below)** | First attempt to migrate agent config; merged 2026-05-16T07:25; pure tooling chore; not force-mapped |
| #52 | [Task][P1][Infra] Add Helm chart scaffold for moadev | open | P1 | #19 (→ #16) | **Yes** | ✅ (#25, #26 confirmed) | none | No | Active; platform/ dir absent — correctly introducing new artifact |
| #53 | feat: migrate Codex agent config to Claude Code | merged | untagged | non-epic / out of scope | No | N/A | none | **Yes (supersedes #51)** | Identical title to PR #51; merged 13 min later (2026-05-16T07:38); updated model assignments (claude-opus-4-7). Both merged to main — re-roll of #51. #53 is canonical; pure tooling chore; not force-mapped |

### 4.3 Non-Epic / Out of Scope Items (Distinct Bucket)

> Items here map to **no Epic** in the six authoritative Epic bodies (#4, #7, #11, #19, #35, #40) **and** are pure chore, CI, process, or developer-tooling work. They are **not force-mapped** to a loosely-fitting Epic. They carry no MVP delivery obligation and are excluded from drift and sequencing analysis.

| # | Title | Type | State | Priority | Category | Rationale |
|---|-------|------|-------|----------|----------|-----------|
| PR #1 | 리포지토리 워크플로와 Codex 초기 설정 부트스트랩 | PR | merged | untagged | repo-bootstrap | Foundational repo setup (workflow + Codex init). Predates all Epics. Pure chore; no product feature content. |
| PR #2 | 핵심 워크스페이스 스캐폴드와 검증 경로 추가 | PR | merged | untagged | repo-bootstrap | Core workspace scaffold and verify path. Predates all Epics. Pure chore. |
| PR #3 | 핵심 워크스페이스 스캐폴드와 검증 경로를 main에 반영 | PR | merged | untagged | repo-bootstrap | Merge PR for #2 content to main. Predates all Epics. Pure chore. |
| PR #21 | chore: switch repository planning to issue-driven workflow | PR | merged | untagged | process | Pure workflow change: adopted issue-driven planning. Not a product feature. No Epic reference in body. |
| PR #51 | feat: migrate Codex agent config to Claude Code | PR | merged | untagged | developer-tooling | Agent config migration from Codex to Claude Code. Internal tooling; no product deliverable. Redundant (superseded by PR #53). |
| PR #53 | feat: migrate Codex agent config to Claude Code | PR | merged | untagged | developer-tooling | Supersedes PR #51 (13 min later); corrected model assignments. Internal tooling; no product deliverable. Canonical state of the agent config migration. |

**What is NOT in this bucket:**
- Issue #47 — though not listed in any Epic body, it is a P0 implementation task (OAuth provider ops) that logically extends Epic #40's auth scope. It is categorized as "non-epic (logically #40)" in §4.1 — not force-mapped, but also not pure chore.
- Issues #8, #9, #10 (Epic #7 docs tasks) — these ARE mapped to Epic #7 and remain in §4.1.

---

## 5. Drift Analysis

> **Only open PRs are eligible for drift classification.** Open issues without a PR are backlog items, not drift.

### 5.1 Active PRs Eligible for Drift Review

| Active PR | Issue | Title | Drift Assessment |
|-----------|-------|-------|-----------------|
| PR #50 | #44 | Add authenticated article/category/status APIs | See below |
| PR #52 | #16 | Add Helm chart scaffold for moadev | See below |

### 5.2 PR #50 (Issue #44) — API Endpoints

**Dependencies checked:**
- Issue #41 (auth boundary): ✅ CONFIRMED — `services/api/app/api/dependencies/auth.py` and `core/security.py` present
- Issue #42 (article persistence): ✅ CONFIRMED — `services/api/app/domain/articles/models.py` + migration `20260421_0001_article_persistence_baseline.py` present

**Epic ordering concern (#43 before #44):**  
Epic #40 lists #43 (ingestion pipeline) before #44 (authenticated API). A strict reading suggests: build the ingestion pipeline first, then expose data via API. However, code-level analysis shows that #44's API endpoints read from the database (which is fully modeled in #42) and do **not** require the ingestion pipeline code to exist in order to be implemented. The API is a read surface; the ingestion pipeline is a write path. These can be developed in parallel without a code-level dependency.

**Verdict: `drift_type = none`**  
The code-level prerequisites (#41 auth, #42 schema) are confirmed satisfied. The epic ordering between #43 and #44 is advisory, not a hard dependency. **UNVERIFIED** if any specific ingestion artifact is needed by the API before it can be tested end-to-end with real data.

### 5.3 PR #52 (Issue #16) — Helm Chart Scaffold

**Dependencies checked:**
- Issue #25 (platform runtime contract): ✅ CONFIRMED — `infra/terraform/modules/platform_contract/` present
- Issue #26 (Terraform variable contracts): ✅ CONFIRMED — `infra/terraform/modules/` AWS/OCI modules present
- Issue #27 (Helm values layering — design doc): ⚠️ Issue still OPEN; however PR #52 body includes values layering as part of its implementation scope

**Ordering concern (#27 vs #16):**  
Issue #27 ("Define Helm values layering and release boundaries") is a design/documentation task that logically should precede the Helm chart implementation (#16). PR #52 appears to implement both the chart AND the values layering in one go, potentially superseding #27's design-doc scope.

**Verdict: `drift_type = none` (UNVERIFIED edge with #27)**  
Code-level prerequisites for Helm chart work (#25, #26) are confirmed. The relationship with #27 is a design-doc concern, not a code-level blocker. Mark the #27/#16 ordering as **UNVERIFIED** — if #27 was meant to produce a design document that #16 would implement, that design step has been skipped. Suggest validating this with the team.

### 5.4 Ranked Drift List

> **Ranking rules (per Seed precedence contract):**
> 1. Drift-type severity: `dependency-inversion` → `priority-inversion` → `none`
> 2. Then priority tag: `P0` → `P1` → `P2` → `untagged`
> 3. Then item number ascending
> 4. A linked issue/PR pair is counted as one entry, citing both numbers

**Confirmed drift items: NONE.** Both active PRs (#50, #52) have all code-level prerequisites verified by codebase explorer. No open PR exhibits a confirmed dependency-inversion or priority-inversion.

**UNVERIFIED dependency-inversion candidates** (ranked by the rules above; would rank ahead of any confirmed priority-inversions if edge evidence were confirmed):

| Rank | Items | Drift Type | Priority | Epic | Rationale |
|------|-------|-----------|----------|------|-----------|
| U-1 | PR #50 / Issue #44 (vs. Issue #43) | dep-inv — **UNVERIFIED** | P0 | #40 | Epic #40 body lists Issue #43 (ingestion pipeline) before Issue #44 (authenticated API). At code level, the API reads from the persisted DB schema (#42 ✅) and does not require ingestion code to be written. However, whether PR #50's API can be meaningfully end-to-end tested with real ingested data before #43 exists is **UNVERIFIED**. Not a hard blocker — but the advisory ordering from the epic body is skipped. |
| U-2 | PR #52 / Issue #16 (vs. Issue #27) | dep-inv — **UNVERIFIED** | P1 | #19 | Issue #27 ("Define Helm values layering and release boundaries") is a design/documentation task that logically precedes the Helm chart implementation in Issue #16 / PR #52. PR #52 incorporates values layering as part of its implementation scope, potentially skipping the design step. Whether #27 was intended as a prerequisite artifact that #16 would implement is **UNVERIFIED** — if yes, this is a dependency inversion; if #27 is supplementary docs, it is not. |

---

## 6. Redundancy Analysis

> **Scope note:** This section is distinct from the ordering-drift ranking in §5.4. Drift flags items whose *sequence* is wrong (a dependency skipped, a priority inverted). Redundancy flags items that *duplicate the same objective*, regardless of sequence. A redundant item may have been correctly sequenced and fully merged.
>
> **Definition:** Two items are redundant when they pursue materially the same deliverable — producing the same artifact, implementing the same feature, or writing the same document — such that one supersedes or absorbs the other with no additive scope remaining in the weaker item.

### 6.1 Confirmed Redundant Pairs

#### R-1: PR #51 vs PR #53 — Codex-to-Claude Code Agent Config Migration

| Field | PR #51 | PR #53 |
|-------|--------|--------|
| Title | feat: migrate Codex agent config to Claude Code | feat: migrate Codex agent config to Claude Code |
| State | merged | merged |
| Merged at | 2026-05-16T07:25:04Z | 2026-05-16T07:38:30Z |
| Scope | Initial migration: CLAUDE.md, `.claude/settings.json`, `.claude/agents/` (6 agents) | Same migration scope; corrects model assignments (`reviewer`+`platform-engineer` → `claude-opus-4-7`) |
| Epic mapping | non-epic / developer-tooling | non-epic / developer-tooling |

**Redundancy verdict: Yes — PR #53 supersedes PR #51.**

Both PRs carry identical titles and cover the same migration scope (Codex → Claude Code native configuration). PR #53 was merged 13 minutes after PR #51 and contains a corrected model-assignment table for the same set of agents. This is a **re-roll pattern**: PR #51 was submitted, then immediately superseded by PR #53 with the updated model assignments. Both are in `main`, which means the canonical config is whatever PR #53 delivered. PR #51 is redundant because every artifact it introduced was overwritten by PR #53 within the same working session.

**Consequence:** No action required (both are merged). PR #51 adds no additive value beyond what PR #53 provides. This inflates PR history and is worth noting so the team prefers amending or superseding on the same branch rather than opening a second PR in the future.

---

#### R-2: PR #2 vs PR #3 — Core Workspace Scaffold (Stacked-PR Re-land)

| Field | PR #2 | PR #3 |
|-------|-------|-------|
| Title | 핵심 워크스페이스 스캐폴드와 검증 경로 추가 | 핵심 워크스페이스 스캐폴드와 검증 경로를 main에 반영 |
| State | merged | merged |
| Merged at | 2026-03-29T05:08:22Z | 2026-03-29T05:22:05Z |
| Branch base | `codex/repo-bootstrap-foundation` (stacked on PR #1) | `main` (promotion/re-land of PR #2 content) |
| Scope | Adds `apps/web` (Next.js 16), `services/api` (FastAPI scaffold), `services/agents-runtime`, `infra/terraform` workspace scaffold and Makefile wiring | Identical workspace additions; PR body describes it as "a promotion PR to bring PR #2's content to main" on top of PR #1's foundation |
| Epic mapping | non-epic / repo-bootstrap | non-epic / repo-bootstrap |

**Redundancy verdict: Yes — PR #3 is a promotion re-land of PR #2.**

PR #2 was a stacked PR built on PR #1's `codex/repo-bootstrap-foundation` branch. Because stacked PRs cannot merge directly into `main` while their base branch is still pending, PR #3 was opened 14 minutes later as a clean promotion of the same content targeting `main`. Both carry materially identical diffs; PR #3 simply re-lands PR #2 onto the correct merge target.

**Consequence:** Both are merged. No action required. Understood as a necessary artifact of the stacked-PR workflow in use at the time (pre-issue-driven planning). PR #2 is the "draft" stacked PR; PR #3 is the canonical merged state. This pattern recurred because the team later switched to issue-driven planning (PR #21).

---

### 6.2 Non-Redundant / Adjacent Items (Cited Rationale)

The following pairs were considered for redundancy but are **not** redundant:

| Items | Redundant? | Rationale |
|-------|-----------|-----------|
| PR #1 vs PR #2/#3 (bootstrap group) | **No** | PR #1 focuses on Codex config, subagents, skills, and docs templates (repo-ops bootstrap). PR #2/#3 add the actual `apps/`, `services/`, `infra/` workspace scaffold and Makefile wiring. Different artifacts, additive scopes, intentionally sequential (PR #1 body: "workspace scaffold in subsequent PR #2"). |
| Issue #47 vs Issue #41 | **No** | #41 is "add authenticated session boundary" (code implementation: `auth.ts`, `dependencies/auth.py`). #47 is "operationalize OAuth provider setup and verification" (runbook/env-config task). Complementary: #47 picks up the operator checklist where #41's code leaves off. |
| Issue #27 vs PR #52 scope | **Partial overlap, not redundant** | Issue #27 ("Define Helm values layering and release boundaries") is a design-document task. PR #52 implements values layering *inside* the Helm chart itself, potentially pre-empting #27's scope. These are not purely the same deliverable (design doc ≠ chart implementation), but the design intent of #27 may be absorbed by PR #52. Team should explicitly decide whether #27 still requires a standalone design artifact after PR #52 merges. |
| Issue #13 (open) vs PR #49 (merged) | **Tracking gap, not redundancy** | PR #49 implements #13's Terraform VM-cluster work; Terraform modules confirmed present in codebase. Issue #13 was simply never closed. Not duplicate effort — just an unclosed tracking item. |

### 6.3 Redundancy Summary

| ID | Items | Type | Verdict |
|----|-------|------|---------|
| R-1 | PR #51 vs PR #53 | Agent config migration re-roll | **Redundant** — PR #51 superseded by PR #53 within 13 min |
| R-2 | PR #2 vs PR #3 | Workspace scaffold stacked-PR re-land | **Redundant** — PR #3 is the canonical main-land of PR #2 content |

**Total confirmed redundant pairs: 2**  
Both redundant items are already merged; no active work item is redundant. No open issues or open PRs carry a redundancy flag.

---

## 7. Epic-to-Vision Mapping

| Epic | Vision Alignment | Notes |
|------|-----------------|-------|
| #4 — Baseline recovery | ✅ Aligned | Established the runnable scaffold; complete |
| #7 — Documentation hardening | ✅ Aligned (P2) | Supporting docs; no blocking dependency |
| #11 — Integration recovery backfill | ✅ Aligned | Historical milestone; closed |
| #19 — K8s platform scaffold | ✅ Aligned (P1) | Supports production hosting; parallel to MVP; correct P1 sequencing |
| #35 — Product definition + architecture | ✅ Aligned | Critical P0 planning; children delivered |
| #40 — MVP authenticated workflow | ✅ Aligned (core P0) | Central implementation epic; 2 of 5 tasks done |
| #47 (non-epic) | ✅ Partially aligned | Auth operationalization; logically belongs to #40 but unlinked |

---

## 8. Recommended Corrective Execution Order

> Only items with identified drift or ordering concerns are ranked here. Items without drift continue on their current path.

### 8.1 Corrective Execution Sequence — Drift-Flagged Items Only

> **This numbered sequence covers ONLY items identified as drift candidates in § 5.4 (ranked drift list). Each linked issue/PR pair is deduplicated into one entry per the linked-pair rule. Ordering follows the Seed precedence contract: dependency-inversion severity first, then priority (P0 → P1 → P2), then item number ascending.**

No open PR carries a **confirmed** `dependency-inversion` or `priority-inversion` drift verdict based on code-level evidence. Both open PRs (#50, #52) have all code-level prerequisites satisfied. The two **UNVERIFIED** candidates from §5.4 form the actionable corrective sequence below:

---

**1. [U-1] Resolve #43 ↔ PR #50 / Issue #44 ordering — P0, Epic #40, dep-inv UNVERIFIED**

| Field | Value |
|-------|-------|
| Items (deduplicated pair) | PR #50 + Issue #44 (one entry) |
| Drift type | dependency-inversion — **UNVERIFIED** |
| Priority | P0 |
| Epic | #40 |
| Identified ordering gap | Epic #40 body lists Issue #43 (ingestion/enrichment pipeline) before Issue #44 (authenticated API endpoints). PR #50 (implementing #44) is active without Issue #43 being started. |
| Corrective action | Before merging PR #50: confirm whether end-to-end API testing requires real ingested data from Issue #43's pipeline. **If YES:** start Issue #43 in parallel immediately; validate end-to-end before merging PR #50. **If NO** (API reads from empty/seeded DB schema only): merge PR #50 now, then open Issue #43 as the very next P0 task. |

---

**2. [U-2] Resolve #27 ↔ PR #52 / Issue #16 ordering — P1, Epic #19, dep-inv UNVERIFIED**

| Field | Value |
|-------|-------|
| Items (deduplicated pair) | PR #52 + Issue #16 (one entry) |
| Drift type | dependency-inversion — **UNVERIFIED** |
| Priority | P1 |
| Epic | #19 |
| Identified ordering gap | Issue #27 ("Define Helm values layering and release boundaries") is a design/documentation task that logically precedes the Helm chart implementation in Issue #16 / PR #52. PR #52 incorporates values layering directly in its implementation scope, potentially bypassing the design step. |
| Corrective action | Before merging PR #52: make an explicit team decision. **(a) Absorb:** close Issue #27 as subsumed by PR #52's self-documenting chart implementation. **(b) Preserve:** defer PR #52 merge until Issue #27 design doc is produced, then implement. Do NOT leave Issue #27 open and unresolved after PR #52 merges — the ambiguity inflates backlog. |

---

**End of drift-only corrective sequence (2 entries, deduplicated; confirmed drift count: 0).**

---

### 8.2 Recommended Sequence for Open Work

The following ordering is recommended based on **dependency correctness > priority labels > MVP-first delivery**:

#### Track A — P0 MVP (Sequential, highest urgency)

```
1. [MERGE] PR #50 — #44 API endpoints
   Prerequisites: ✅ #41 auth ✅ #42 persistence
   
2. [START] Issue #43 — Ingestion/enrichment pipeline scaffold
   Prerequisites: ✅ #41 auth ✅ #42 persistence ✅ #44 API (after PR #50 merges — needed for end-to-end data flow testing)
   Note: Can begin #43 in parallel with #50 at code level, but should validate end-to-end after both land
   
3. [START] Issue #47 — OAuth provider setup and verification runbook
   Prerequisites: ✅ #41 (code exists); can be worked in parallel with #43
   Note: Link this issue to Epic #40 to avoid orphan status

4. [START] Issue #45 — Authenticated web knowledge home/list/detail
   Prerequisites: PR #50 merged (#44 API) + #43 pipeline scaffold (for realistic test data)
```

#### Track B — P1 Platform (Parallel to Track A)

```
5. [MERGE] PR #52 — #16 Helm chart scaffold
   Prerequisites: ✅ #25 ✅ #26; no blocking dependency on MVP track
   
6. [CLOSE] Issue #13 — Terraform VM-based cluster foundations
   Implementation confirmed in codebase (PR #49 merged); close as tracking cleanup

7. [DECIDE] Issue #27 — Helm values layering design doc
   After PR #52 merges, assess whether #27 scope is absorbed by the chart or still needed as a standalone design document

8. [START] Issue #17 — Kubespray bootstrap scaffold
   Prerequisites: #16 Helm chart (#52 merged), group_vars scaffold present

9. [START] Issue #15 — Ansible operations scaffold
   Prerequisites: Ansible group_vars present; can parallelize with #17

10. [START] Issue #14 — CI/CD workflow scaffold
    Prerequisites: Dockerfiles confirmed (via #20✓); .github/workflows/ missing; unblocked

11. [START] Issue #28 — Ansible/Kubespray inventory boundaries
    Prerequisites: #17 and #15
    
12. [START] Issue #29 — Platform validation targets
    Prerequisites: #14, #16, partial #15
    
13. [START] Issue #34 — Production launch gate and runbooks
    Prerequisites: substantial progress on #40 MVP + #19 platform
```

#### Track C — P2 Docs (Low urgency, no blocking dependency)

```
14. Issues #8, #9, #10 (Epic #7) — Documentation hardening
    Can proceed at any point; not blocking any P0/P1 work
```

---

## 9. Summary Findings

| Category | Count | Key Items |
|----------|-------|-----------|
| Total items audited | 53 | 35 issues + 18 PRs |
| Drift-flagged (confirmed) | 0 | No confirmed code-level dependency inversions |
| Drift-flagged (UNVERIFIED edge) | 2 | U-1: #43 ingestion vs PR #50 API end-to-end test need; U-2: #27 design-doc vs PR #52 implementation (see §5.4 and §8.1) |
| Redundant items | 2 PR pairs | R-1: PR #51 superseded by PR #53 (13-min re-roll); R-2: PR #2 superseded by PR #3 (stacked-PR re-land to main) |
| Tracking gaps | 1 | Issue #13 open despite PR #49 merged + implementation confirmed |
| Non-epic orphan | 1 | Issue #47 logically belongs to Epic #40 but not linked |
| Active PRs | 2 | PR #50 (P0 API), PR #52 (P1 Helm) |
| Prerequisites satisfied for active PRs | 2/2 | Both PRs have confirmed code-level prerequisites |

### Verdict

**MoaDev's execution sequence is broadly correct.** The P0 MVP track (Epic #40) is following the dependency chain correctly: auth (#41) → persistence (#42) → API (#44, in flight via PR #50) → ingestion (#43) → web (#45). The P1 platform track (Epic #19) is running correctly in parallel. No confirmed out-of-sequence drift exists for active work.

**Recommended immediate actions (non-mutating — team-facing guidance only):**
1. **Merge PR #50** — prerequisites satisfied, unblocks #43 (ingestion) and #45 (web)
2. **Merge PR #52** — prerequisites satisfied; then decide fate of issue #27
3. **Link issue #47 to Epic #40** (editorial change, no priority change)
4. **Close issue #13** — PR #49 merged; Terraform VM modules confirmed in codebase
5. **Start issue #43** (ingestion pipeline) — begins after PR #50 merges for full end-to-end test coverage

---

*Report generated: 2026-08-02 | Analyst: Claude Code (read-only, no GitHub mutations)*
