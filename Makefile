SHELL := /usr/bin/env bash

WEB_DIR := apps/web
API_DIR := services/api
AGENTS_RUNTIME_DIR := services/agents-runtime
E2E_DIR := e2e
TF_DIR := infra/terraform
TF_DEV_DIR := $(TF_DIR)/envs/dev
TF_PROD_DIR := $(TF_DIR)/envs/prod

.PHONY: bootstrap build test lint typecheck e2e verify format \
web-build web-test web-lint web-typecheck \
api-test api-lint api-typecheck \
agents-test agents-lint agents-typecheck \
tf-fmt tf-validate

bootstrap: ; @if [ -f "$(WEB_DIR)/package.json" ]; then \
	cd "$(WEB_DIR)" && npm install; \
else \
	echo "bootstrap: skipping $(WEB_DIR) (package.json not found)"; \
fi; \
python -m pip install -U pip; \
if [ -f "$(API_DIR)/pyproject.toml" ]; then \
	cd "$(API_DIR)" && python -m pip install -e ".[dev]"; \
else \
	echo "bootstrap: skipping $(API_DIR) (pyproject.toml not found)"; \
fi; \
if [ -f "$(AGENTS_RUNTIME_DIR)/pyproject.toml" ]; then \
	cd "$(AGENTS_RUNTIME_DIR)" && python -m pip install -e ".[dev]"; \
else \
	echo "bootstrap: skipping $(AGENTS_RUNTIME_DIR) (pyproject.toml not found)"; \
fi

build: ; @$(MAKE) web-build

test: ; @$(MAKE) web-test && $(MAKE) api-test && $(MAKE) agents-test

lint: ; @$(MAKE) web-lint && $(MAKE) api-lint && $(MAKE) agents-lint && $(MAKE) tf-fmt

typecheck: ; @$(MAKE) web-typecheck && $(MAKE) api-typecheck && $(MAKE) agents-typecheck

e2e: ; @if [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ] || [ -f "$(E2E_DIR)/package.json" ]; then \
	cd "$(E2E_DIR)" && npx playwright test; \
else \
	echo "e2e: skipping Playwright (configuration not found)"; \
fi

verify: lint typecheck test tf-validate ; @echo "verify: ok"

format: ; @if [ -f "$(WEB_DIR)/package.json" ]; then \
	cd "$(WEB_DIR)" && npm run format; \
else \
	echo "format: skipping $(WEB_DIR) (package.json not found)"; \
fi; \
if [ -f "$(API_DIR)/pyproject.toml" ]; then \
	cd "$(API_DIR)" && ruff format .; \
else \
	echo "format: skipping $(API_DIR) (pyproject.toml not found)"; \
fi; \
if [ -f "$(AGENTS_RUNTIME_DIR)/pyproject.toml" ]; then \
	cd "$(AGENTS_RUNTIME_DIR)" && ruff format .; \
else \
	echo "format: skipping $(AGENTS_RUNTIME_DIR) (pyproject.toml not found)"; \
fi; \
if [ -d "$(TF_DIR)" ]; then \
	cd "$(TF_DIR)" && terraform fmt -recursive; \
else \
	echo "format: skipping $(TF_DIR) (directory not found)"; \
fi

web-build: ; @if [ -f "$(WEB_DIR)/package.json" ]; then \
	cd "$(WEB_DIR)" && npm run build; \
else \
	echo "web-build: skipping $(WEB_DIR) (package.json not found)"; \
fi

web-test: ; @if [ -f "$(WEB_DIR)/package.json" ]; then \
	cd "$(WEB_DIR)" && npm run test; \
else \
	echo "web-test: skipping $(WEB_DIR) (package.json not found)"; \
fi

web-lint: ; @if [ -f "$(WEB_DIR)/package.json" ]; then \
	cd "$(WEB_DIR)" && npm run lint; \
else \
	echo "web-lint: skipping $(WEB_DIR) (package.json not found)"; \
fi

web-typecheck: ; @if [ -f "$(WEB_DIR)/package.json" ]; then \
	cd "$(WEB_DIR)" && npm run typecheck; \
else \
	echo "web-typecheck: skipping $(WEB_DIR) (package.json not found)"; \
fi

api-test: ; @if [ -f "$(API_DIR)/pyproject.toml" ]; then \
	cd "$(API_DIR)" && pytest -q; \
else \
	echo "api-test: skipping $(API_DIR) (pyproject.toml not found)"; \
fi

api-lint: ; @if [ -f "$(API_DIR)/pyproject.toml" ]; then \
	cd "$(API_DIR)" && ruff check .; \
else \
	echo "api-lint: skipping $(API_DIR) (pyproject.toml not found)"; \
fi

api-typecheck: ; @if [ -f "$(API_DIR)/pyproject.toml" ]; then \
	cd "$(API_DIR)" && mypy app; \
else \
	echo "api-typecheck: skipping $(API_DIR) (pyproject.toml not found)"; \
fi

agents-test: ; @if [ -f "$(AGENTS_RUNTIME_DIR)/pyproject.toml" ]; then \
	cd "$(AGENTS_RUNTIME_DIR)" && pytest -q; \
else \
	echo "agents-test: skipping $(AGENTS_RUNTIME_DIR) (pyproject.toml not found)"; \
fi

agents-lint: ; @if [ -f "$(AGENTS_RUNTIME_DIR)/pyproject.toml" ]; then \
	cd "$(AGENTS_RUNTIME_DIR)" && ruff check .; \
else \
	echo "agents-lint: skipping $(AGENTS_RUNTIME_DIR) (pyproject.toml not found)"; \
fi

agents-typecheck: ; @if [ -f "$(AGENTS_RUNTIME_DIR)/pyproject.toml" ]; then \
	cd "$(AGENTS_RUNTIME_DIR)" && mypy app; \
else \
	echo "agents-typecheck: skipping $(AGENTS_RUNTIME_DIR) (pyproject.toml not found)"; \
fi

tf-fmt: ; @if [ -d "$(TF_DIR)" ]; then \
	cd "$(TF_DIR)" && terraform fmt -check -recursive; \
else \
	echo "tf-fmt: skipping $(TF_DIR) (directory not found)"; \
fi

tf-validate: ; @if [ -d "$(TF_DEV_DIR)" ]; then \
	cd "$(TF_DEV_DIR)" && terraform init -backend=false && terraform validate; \
else \
	echo "tf-validate: skipping $(TF_DEV_DIR) (directory not found)"; \
fi; \
if [ -d "$(TF_PROD_DIR)" ]; then \
	cd "$(TF_PROD_DIR)" && terraform init -backend=false && terraform validate; \
else \
	echo "tf-validate: skipping $(TF_PROD_DIR) (directory not found)"; \
fi
