# Pickleball top-level Makefile

PY?=python3
PIP?=pip
VENV?=venv
ACTIVATE?=. $(VENV)/bin/activate

# ---- Python -------------------------------------------------------------------
.PHONY: venv deps run test fmt lint clean

venv:
	$(PY) -m venv $(VENV)

deps: venv
	$(ACTIVATE) && $(PIP) install -U pip && $(PIP) install -r requirements.txt

run:  ## Run the daemon in foreground on 127.0.0.1:8765
	$(ACTIVATE) && EXCALIBUR_WORKSPACE=$$(pwd) uvicorn Pickleball:app --host 127.0.0.1 --port $${PORT:-8765} --no-access-log

test:  ## Run tests (scoped to Pickleball/)
	$(ACTIVATE) && cd Pickleball && PYTHONPATH=. pytest -q

fmt:   ## Format Python (ruff/black optional if installed)
	-$(ACTIVATE) && ruff check --select I --fix || true
	-$(ACTIVATE) && ruff format || true
	-$(ACTIVATE) && black Pickleball || true

lint:  ## Lint Python (ruff optional)
	-$(ACTIVATE) && ruff check || true

clean:
	rm -rf $(VENV) .pytest_cache **/__pycache__ Pickleball/**/__pycache__

# ---- VS Code extension --------------------------------------------------------
.PHONY: vscode-build vscode-watch vscode-package

vscode-build:
	cd Pickleball/vscode && npm ci && npm run build

vscode-watch:
	cd Pickleball/vscode && npm run watch

vscode-package:
	cd Pickleball/vscode && npx vsce package

# ---- Android / Termux ---------------------------------------------------------
.PHONY: droid service-install service-logs

droid: ## Run resilient loop in Termux (uses wakelock)
	Pickleball/bin/Pickleball.droid

service-install: ## Install as termux-services runit service
	Pickleball/bin/Pickleball.termux-service-setup

service-logs:
	tail -f $$HOME/.local/state/Pickleball/service.out.log

# ---- Helpers ------------------------------------------------------------------
.PHONY: health version

health:
	@curl -fsS http://127.0.0.1:$${PORT:-8765}/health | jq .

version:
	@curl -fsS http://127.0.0.1:$${PORT:-8765}/version | jq .

# Default target
.DEFAULT_GOAL := help

help:
	@awk 'BEGIN {FS:=":.*##"; printf "\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST); echo ""

.PHONY: verify
verify:
	@./tools/verify.sh
