---
name: docker-patterns
description: MoaDev's actual Docker setup — three multi-stage Dockerfiles feeding the Helm/K8s deploy pipeline, no docker-compose (no local Compose dev workflow exists here).
origin: MoaDev
---

Three Dockerfiles exist: `apps/web/Dockerfile` (`node:22-alpine`, multi-stage), `services/api/Dockerfile` (`python:3.12-slim`, builds into a venv), `services/agents-runtime/Dockerfile`. No `docker-compose.yml` exists anywhere in this repo — local dev runs services directly (`make bootstrap` + per-service dev servers), and images are only built for the Helm/Argo CD deploy pipeline (see `platform-engineer` agent), not local orchestration.

If adding local Compose-based dev in the future, standard hardening applies (pinned tags, non-root user, `.dockerignore`, secrets via env not baked into layers) — a frontier model already knows this without a checklist.
