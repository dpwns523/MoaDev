# Release Notes

Use this file as the standard release template. For each release, duplicate the template block below, replace placeholders, and keep the newest release at the top.

If a section does not apply, write `None`.

---

## Release: `ai-knowledge-product-plan`

- Date: `2026-04-17`
- Status: `planned`
- Owner: `repository-maintainers`

### Summary

Reframed the repository from a generic developer feed direction to an authenticated AI knowledge product plan, and added English and Korean planning docs for product scope, product-facing agent roles, and first-production application architecture.

### User Impact

- Who is affected: contributors, operators, and reviewers planning the next implementation phase
- What users will notice: the repository now defines `MoaDev` as an authenticated article-centric knowledge product with explicit translation, glossary, concept, related-concept, and categorization requirements
- Expected benefits: clearer scope for API, web, runtime, auth, and platform work, plus less drift between product ambition and infrastructure planning

### Migration Notes

- Required upgrade steps: none
- Data or config changes: none
- Operator actions: use `docs/prd.md`, `docs/agents-product.md`, and `docs/production-plan.md` before starting new feature or platform implementation work

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `None` | no | none | No new environment variables were introduced. |

### Breaking Changes

- Product planning assumptions changed from a feed-first developer signal surface to an authenticated AI knowledge workflow for approved technology content.

### Rollback Notes

- Rollback trigger: the new product definition is rejected or proves incompatible with the current repository direction
- Rollback steps: revert the PRD, product-plan, agent-role, and production-plan document set together so the repository returns to one consistent planning state
- Data recovery notes: none

### Known Issues

- Source licensing, raw content retention policy, and exact auth provider choice remain open decisions.
- The runtime, API, and web code still need implementation work to match the new plan.

---

## Release: `terraform-platform-contracts`

- Date: `2026-04-15`
- Status: `planned`
- Owner: `repository-maintainers`

### Summary

Added a typed Terraform platform contract module and environment-root variable declarations so the checked-in multi-cloud sample tfvars are validated explicitly before broader VM and network scaffold work lands.

### User Impact

- Who is affected: contributors and operators working on Terraform environment roots and sample platform values
- What users will notice: `infra/terraform/envs/dev` and `infra/terraform/envs/prod` now validate the grouped topology contract, provider-specific placement assumptions, and shared config groups instead of accepting only the old minimal application stub
- Expected benefits: less drift between sample files and Terraform, earlier validation of multi-cloud topology assumptions, and a clearer handoff into follow-up Terraform module work

### Migration Notes

- Required upgrade steps: refresh any local `terraform.tfvars` copies from the updated examples before running `terraform validate`
- Data or config changes: AWS and OCI provider blocks now include explicit placement and bastion fields in the example contract
- Operator actions: run Terraform validation from each environment root after updating local sample copies

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `None` | no | none | No new environment variables were introduced. |

### Breaking Changes

- Terraform environment roots now expect the grouped topology contract instead of only the old minimal application inputs.

### Rollback Notes

- Rollback trigger: the typed contract blocks follow-up scaffold work or cannot be validated in the current environment
- Rollback steps: remove the platform contract module wiring and revert the environment roots to the minimal application-only inputs
- Data recovery notes: none

### Known Issues

- The contract validates input shape and cross-field assumptions only; live VM, subnet, and host bootstrap resources still belong to follow-up infrastructure issues.

---

## Release: `platform-topology-docs`

- Date: `2026-04-15`
- Status: `planned`
- Owner: `repository-maintainers`

### Summary

Added a dedicated platform topology document in English and Korean, plus a visual architecture diagram built from vendored official AWS and Oracle icon assets.

### User Impact

- Who is affected: contributors and operators reviewing the current multi-cloud runtime shape
- What users will notice: the repository now has a plain-language topology guide, a Korean version, and a single visual diagram that explains the AWS control plane, AWS worker pool, OCI worker pool, and tool boundaries
- Expected benefits: faster review, fewer mismatched interpretations of `environment` versus `provider`, and a clearer handoff contract across Terraform, Ansible, Kubespray, Helm, and Argo CD

### Migration Notes

- Required upgrade steps: none
- Data or config changes: none
- Operator actions: use `docs/platform-topology.md` or `docs/platform-topology.ko.md` as the entry point before modifying platform sample values

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `None` | no | none | No new environment variables were introduced. |

### Breaking Changes

- None.

### Rollback Notes

- Rollback trigger: the new topology documents or diagram no longer match the checked-in platform samples
- Rollback steps: remove or update the topology docs together with the sample config model so the documentation does not drift
- Data recovery notes: none

### Known Issues

- The diagram documents the intended contract and sample defaults, not completed live Terraform or Kubespray wiring.

---

## Release: `multicloud-config-samples`

- Date: `2026-04-09`
- Status: `planned`
- Owner: `repository-maintainers`

### Summary

Updated the sample platform configuration model so Terraform, Ansible, and operator env samples describe a self-managed multi-cloud Kubernetes cluster with AWS control-plane capacity and worker pools split across AWS and OCI.

### User Impact

- Who is affected: contributors and operators preparing infrastructure config samples
- What users will notice: the sample files now describe `1` AWS control-plane node, `3` AWS worker nodes, and `3` OCI worker nodes, with future AWS control-plane scale-out represented explicitly
- Expected benefits: fewer conflicting provider-specific defaults and a clearer path for future Terraform and Ansible wiring

### Migration Notes

- Required upgrade steps: refresh any local sample copies made from the old `EKS` or `OKE`-style examples
- Data or config changes: rename single-provider fields such as `platform_provider` and managed-cluster node pool fields to the new multi-cloud topology model
- Operator actions: keep node counts in shared topology fields and keep provider-specific compute, subnet, and storage overrides in the cloud-specific sample files

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `MOADEV_PLATFORM_TOPOLOGY` | yes | none | Declares whether the platform is single-provider or `multicloud`. |
| `MOADEV_CONTROL_PLANE_PROVIDER` | yes | none | Identifies which cloud hosts the Kubernetes control plane. |
| `MOADEV_AWS_CONTROL_PLANE_DESIRED_COUNT` | no | `1` | Sample desired AWS control-plane node count for the initial topology. |
| `MOADEV_OCI_WORKER_DESIRED_COUNT` | no | `3` | Sample desired OCI worker node count for the initial topology. |

### Breaking Changes

- Sample config field names changed from managed-cluster terminology such as `platform_provider`, `node_group_name`, and `node_pool_size` to a topology-oriented model.

### Rollback Notes

- Rollback trigger: downstream scaffolds still depend on the old single-provider sample field names
- Rollback steps: restore the previous sample field names and managed-cluster placeholders, then defer topology normalization to a follow-up PR
- Data recovery notes: none

### Known Issues

- The sample topology is not wired into live Terraform modules or Ansible inventories yet.
- Ansible CLI validation is not available in the current local environment.

---

## Release: `web-home-live-feed`

- Date: `2026-04-01`
- Status: `planned`
- Owner: `repository-maintainers`

### Summary

Rebuilt the web home page into an editorial, Stripe Blog-inspired briefing surface and connected it to the FastAPI curated feed with a resilient preview fallback.

### User Impact

- Who is affected: contributors and operators running the web app against the API service
- What users will notice: the home page now shows a designed editorial feed instead of a plain scaffold list, and it can render live `/api/v1/feeds` content when the API is reachable
- Expected benefits: clearer product direction, a more intentional first impression, and a usable integration point between `apps/web` and `services/api`

### Migration Notes

- Required upgrade steps: set `MOADEV_API_BASE_URL` when the web app needs to reach a non-local API host
- Data or config changes: the web app now reads the FastAPI feed contract at `/api/v1/feeds`
- Operator actions: verify the API base URL is reachable from the Next.js runtime environment

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `MOADEV_API_BASE_URL` | no | `http://127.0.0.1:8000` | Base URL used by the Next.js home page when fetching the FastAPI curated feed. |

### Breaking Changes

- None.

### Rollback Notes

- Rollback trigger: the new home feed fetch or editorial layout blocks local preview or deployment expectations
- Rollback steps: revert the new `apps/web` home page and helper files, then restore the previous static scaffold content
- Data recovery notes: none

### Known Issues

- The live API currently returns a very small curated set, so the page relies on layout polish and a preview fallback more than content volume.
- If `MOADEV_API_BASE_URL` is misconfigured, the page intentionally falls back to preview stories instead of surfacing a hard failure.

---

## Release: `api-route-based-architecture`

- Date: `2026-04-01`
- Status: `planned`
- Owner: `repository-maintainers`

### Summary

Restructured `services/api` to a FastAPI route-based architecture with an app factory, a top-level router registry, versioned `api/v1/endpoints` modules, and dedicated API boundary schemas.

### User Impact

- Who is affected: contributors extending the FastAPI service and operators reviewing API structure
- What users will notice: no endpoint path changes, but the API code is now organized around `APIRouter` modules and `api/v1/endpoints` instead of defining all routes in `app/main.py`
- Expected benefits: clearer separation between app assembly, HTTP routes, schemas, and domain services

### Migration Notes

- Required upgrade steps: none
- Data or config changes: none
- Operator actions: none

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `None` | no | none | No new environment variables were introduced. |

### Breaking Changes

- None.

### Rollback Notes

- Rollback trigger: contributors need to temporarily return to a single-file FastAPI entrypoint
- Rollback steps: move route registrations and boundary schemas back into `app/main.py` and remove the router package
- Data recovery notes: none

### Known Issues

- The API currently has only a small route surface, so some route modules are intentionally lightweight until more endpoints are added.

---

## Release: `api-feed-validation-hardening`

- Date: `2026-04-01`
- Status: `planned`
- Owner: `repository-maintainers`

### Summary

Hardened the `/api/v1/feeds` response boundary so malformed feed items consistently return the structured `feed_validation_error` envelope, including mapping-based inputs and whitespace-only string fields.

### User Impact

- Who is affected: API consumers and operators relying on curated feed responses
- What users will notice: `/api/v1/feeds` now rejects whitespace-only `id`, `title`, and `source` values at the API boundary and preserves the documented JSON error envelope for malformed mapping/object feed items
- Expected benefits: a stricter and more predictable validation contract for curated feed payloads

### Migration Notes

- Required upgrade steps: none
- Data or config changes: none
- Operator actions: none

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `None` | no | none | No new environment variables were introduced. |

### Breaking Changes

- None.

### Rollback Notes

- Rollback trigger: feed producers must temporarily allow whitespace-only values or rely on generic FastAPI 500 responses for malformed feed items
- Rollback steps: revert the API boundary validator and restore the previous feed serialization path
- Data recovery notes: none

### Known Issues

- Feed producers still need to provide one of the curated `kind` values: `news` or `pull-request`.

---

## Release: `container-packaging-scaffolds`

- Date: `2026-03-30`
- Status: `planned`
- Owner: `repository-maintainers`

### Summary

Added production-oriented container packaging for the Next.js web app, FastAPI API, and agent runtime, including standalone web output for self-hosted deployment.

### User Impact

- Who is affected: contributors and operators packaging or self-hosting the application surfaces
- What users will notice: `apps/web`, `services/api`, and `services/agents-runtime` now each include a production-focused Dockerfile, and repository-root `.dockerignore` rules now protect root-context image builds
- Expected benefits: smaller runtime images, clearer deployment handoff, and a direct path to building service images without baking secrets into source control

### Migration Notes

- Required upgrade steps: provide runtime secrets and environment-specific configuration at deploy time instead of baking them into images
- Data or config changes: none
- Operator actions: build from the repository root with `docker build -f apps/web/Dockerfile .`, `docker build -f services/api/Dockerfile .`, and `docker build -f services/agents-runtime/Dockerfile .`

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `AGENTS_RUNTIME_LOG_LEVEL` | no | `INFO` | Python logging level for the runtime worker. |
| `AGENTS_RUNTIME_MAX_BATCH_SIZE` | no | `3` | Maximum number of signals included in each planned batch. |
| `AGENTS_RUNTIME_POLL_INTERVAL_SECONDS` | no | `30` | Delay between worker polling cycles. |
| `AGENTS_RUNTIME_RUN_ONCE` | no | `false` | Run a single planning cycle and exit, useful for validation and one-shot jobs. |
| `AGENTS_RUNTIME_SIGNALS_JSON` | no | `[]` | JSON array of seed signals used until a real upstream signal source is wired in. |

### Breaking Changes

- None.

### Rollback Notes

- Rollback trigger: image builds or self-hosted startup behavior regress for the web or service workspaces
- Rollback steps: remove the added Docker packaging files and restore the previous non-containerized packaging state
- Data recovery notes: none

### Known Issues

- Audit snapshot: packaging had no Dockerfiles or container build automation before this change; `.github` currently contains issue and PR templates only, with no workflow files for image build or publish automation.
- Audit snapshot: `infra/terraform` exists and is wired into root verification, but `platform/helm`, `platform/argocd`, and `platform/monitoring` are still referenced by docs without corresponding directories in the repository.
- Follow-up likely needed: `services/agents-runtime` now starts a long-running polling worker, but it still needs real upstream signal sources beyond env-provided seed data.

---

## Release: `core-workspace-scaffolds`

- Date: `2026-03-29`
- Status: `planned`
- Owner: `repository-maintainers`

### Summary

Added runnable workspace scaffolds for the web app, FastAPI API, agent runtime, and Terraform layouts, and wired the root verification flow to those concrete workspaces.

### User Impact

- Who is affected: contributors and operators working in the scaffolded monorepo workspaces
- What users will notice: `apps/web`, `services/api`, `services/agents-runtime`, and `infra/terraform` now exist with working baseline code and root `make` targets execute real workspace commands instead of only skip paths
- Expected benefits: contributors can bootstrap, build, lint, typecheck, test, and validate the core workspaces from the repository root

### Migration Notes

- Required upgrade steps: run `make bootstrap` before local development in a fresh checkout
- Data or config changes: none
- Operator actions: install the local `terraform` CLI before running Terraform validation targets

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `None` | no | none | No new environment variables were introduced. |

### Breaking Changes

- None.

### Rollback Notes

- Rollback trigger: the new workspace scaffolds or root verification flow block local development
- Rollback steps: revert the scaffolded workspace directories and restore the previous skip-only root command behavior
- Data recovery notes: none

### Known Issues

- `platform/helm`, `platform/argocd`, and `platform/monitoring` are still not scaffolded.
- End-to-end Playwright wiring has not been added yet.

---

## Release: `repo-bootstrap-foundation`

- Date: `2026-03-26`
- Status: `planned`
- Owner: `repository-maintainers`

### Summary

Standardized the root contributor workflow with canonical `make` commands, concise repository instructions, project-local Codex agent role definitions, a default Korean pull request template, and Codex-oriented skill guidance under `.agents/skills/`.

### User Impact

- Who is affected: contributors and operators working from the repository root
- What users will notice: a consistent `make` entrypoint, clearer repository expectations, documented target workspace layout, a prefilled Korean PR body template, and skill docs that reference Codex paths and workflows instead of legacy Claude-specific ones
- Expected benefits: lower onboarding friction and fewer ad hoc command conventions

### Migration Notes

- Required upgrade steps: use `make` targets from the repository root instead of ad hoc local commands
- Data or config changes: none
- Operator actions: scaffold the planned workspaces before replacing skip-based command placeholders

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `None` | no | none | No new environment variables were introduced. |

### Breaking Changes

- None.

### Rollback Notes

- Rollback trigger: root workflow changes block contributor onboarding or automation
- Rollback steps: restore the previous `AGENTS.md`, `README.md`, and `docs` guidance, then remove or simplify the `Makefile`
- Data recovery notes: none

### Known Issues

- Several documented workspaces are planned and not yet scaffolded.
- Root `make` targets intentionally skip missing workspaces until those directories are added.

---

## Release: `<version-or-name>`

- Date: `<YYYY-MM-DD>`
- Status: `<planned|shipped|rolled back>`
- Owner: `<team-or-person>`

### Summary

Briefly describe what shipped and why it matters.

### User Impact

- Who is affected:
- What users will notice:
- Expected benefits:

### Migration Notes

- Required upgrade steps:
- Data or config changes:
- Operator actions:

### New Env Vars

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `EXAMPLE_ENV_VAR` | no | none | Describe when and why it is needed. |

### Breaking Changes

- Describe any incompatible API, behavior, schema, or workflow changes.
- Include who must take action and by when.

### Rollback Notes

- Rollback trigger:
- Rollback steps:
- Data recovery notes:

### Known Issues

- List any known limitations, follow-up work, or temporary mitigations.

---
