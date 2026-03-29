SHELL := /usr/bin/env bash

WEB_DIR := apps/web
API_DIR := services/api
AGENTS_RUNTIME_DIR := services/agents-runtime
E2E_DIR := e2e
TF_DIR := infra/terraform
TF_DEV_DIR := $(TF_DIR)/envs/dev
TF_PROD_DIR := $(TF_DIR)/envs/prod
API_VENV := $(API_DIR)/.venv
AGENTS_RUNTIME_VENV := $(AGENTS_RUNTIME_DIR)/.venv

.PHONY: bootstrap build test lint typecheck e2e verify format \
web-build web-test web-lint web-typecheck \
api-test api-lint api-typecheck \
agents-test agents-lint agents-typecheck \
tf-fmt tf-validate

bootstrap: ; @if [ -f "$(WEB_DIR)/package.json" ]; then \
	(cd "$(WEB_DIR)" && npm install); \
else \
	echo "bootstrap: skipping $(WEB_DIR) (package.json not found)"; \
fi; \
if [ -f "$(API_DIR)/pyproject.toml" ]; then \
	python3 -m venv "$(API_VENV)" && "$(API_VENV)/bin/pip" install -U pip && (cd "$(API_DIR)" && "$(abspath $(API_VENV))/bin/pip" install -e ".[dev]"); \
else \
	echo "bootstrap: skipping $(API_DIR) (pyproject.toml not found)"; \
fi; \
if [ -f "$(AGENTS_RUNTIME_DIR)/pyproject.toml" ]; then \
	python3 -m venv "$(AGENTS_RUNTIME_VENV)" && "$(AGENTS_RUNTIME_VENV)/bin/pip" install -U pip && (cd "$(AGENTS_RUNTIME_DIR)" && "$(abspath $(AGENTS_RUNTIME_VENV))/bin/pip" install -e ".[dev]"); \
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
	(cd "$(WEB_DIR)" && npm run format); \
else \
	echo "format: skipping $(WEB_DIR) (package.json not found)"; \
fi; \
if [ -x "$(API_VENV)/bin/ruff" ]; then \
	(cd "$(API_DIR)" && "$(abspath $(API_VENV))/bin/ruff" format .); \
else \
	echo "format: skipping $(API_DIR) (.venv with ruff not found)"; \
fi; \
if [ -x "$(AGENTS_RUNTIME_VENV)/bin/ruff" ]; then \
	(cd "$(AGENTS_RUNTIME_DIR)" && "$(abspath $(AGENTS_RUNTIME_VENV))/bin/ruff" format .); \
else \
	echo "format: skipping $(AGENTS_RUNTIME_DIR) (.venv with ruff not found)"; \
fi; \
if command -v terraform >/dev/null 2>&1 && [ -d "$(TF_DIR)" ]; then \
	(cd "$(TF_DIR)" && terraform fmt -recursive); \
else \
	echo "format: skipping $(TF_DIR) (terraform CLI or directory not found)"; \
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

api-test: ; @if [ -x "$(API_VENV)/bin/pytest" ]; then \
	cd "$(API_DIR)" && "$(abspath $(API_VENV))/bin/pytest" -q; \
else \
	echo "api-test: skipping $(API_DIR) (.venv with pytest not found)"; \
fi

api-lint: ; @if [ -x "$(API_VENV)/bin/ruff" ]; then \
	cd "$(API_DIR)" && "$(abspath $(API_VENV))/bin/ruff" check .; \
else \
	echo "api-lint: skipping $(API_DIR) (.venv with ruff not found)"; \
fi

api-typecheck: ; @if [ -x "$(API_VENV)/bin/mypy" ]; then \
	cd "$(API_DIR)" && "$(abspath $(API_VENV))/bin/mypy" app; \
else \
	echo "api-typecheck: skipping $(API_DIR) (.venv with mypy not found)"; \
fi

agents-test: ; @if [ -x "$(AGENTS_RUNTIME_VENV)/bin/pytest" ]; then \
	cd "$(AGENTS_RUNTIME_DIR)" && "$(abspath $(AGENTS_RUNTIME_VENV))/bin/pytest" -q; \
else \
	echo "agents-test: skipping $(AGENTS_RUNTIME_DIR) (.venv with pytest not found)"; \
fi

agents-lint: ; @if [ -x "$(AGENTS_RUNTIME_VENV)/bin/ruff" ]; then \
	cd "$(AGENTS_RUNTIME_DIR)" && "$(abspath $(AGENTS_RUNTIME_VENV))/bin/ruff" check .; \
else \
	echo "agents-lint: skipping $(AGENTS_RUNTIME_DIR) (.venv with ruff not found)"; \
fi

agents-typecheck: ; @if [ -x "$(AGENTS_RUNTIME_VENV)/bin/mypy" ]; then \
	cd "$(AGENTS_RUNTIME_DIR)" && "$(abspath $(AGENTS_RUNTIME_VENV))/bin/mypy" app; \
else \
	echo "agents-typecheck: skipping $(AGENTS_RUNTIME_DIR) (.venv with mypy not found)"; \
fi

tf-fmt: ; @if command -v terraform >/dev/null 2>&1 && [ -d "$(TF_DIR)" ]; then \
	(cd "$(TF_DIR)" && terraform fmt -check -recursive); \
else \
	echo "tf-fmt: skipping $(TF_DIR) (terraform CLI or directory not found)"; \
fi

tf-validate: ; @if command -v terraform >/dev/null 2>&1 && [ -d "$(TF_DEV_DIR)" ]; then \
	(cd "$(TF_DEV_DIR)" && terraform init -backend=false && terraform validate); \
else \
	echo "tf-validate: skipping $(TF_DEV_DIR) (terraform CLI or directory not found)"; \
fi; \
if command -v terraform >/dev/null 2>&1 && [ -d "$(TF_PROD_DIR)" ]; then \
	(cd "$(TF_PROD_DIR)" && terraform init -backend=false && terraform validate); \
else \
	echo "tf-validate: skipping $(TF_PROD_DIR) (terraform CLI or directory not found)"; \
fi
