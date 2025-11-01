#!/usr/bin/env bash
# Pickleball Docker runner: build, run, health-check, and stream logs.
# Usage:
#   bin/run_docker.sh [--workspace /path/to/repo] [--image Pickleball:local] [--no-build]
# Env (optional):
#   EXCALIBUR_WORKSPACE, EXCALIBUR_ALLOWLIST, EXCALIBUR_TEST_CMD, EXCALIBUR_LOG_FILE, PORT
set -euo pipefail

IMAGE="${IMAGE:-Pickleball:local}"
NO_BUILD="false"
WORKSPACE_DEFAULT="${EXCALIBUR_WORKSPACE:-$PWD}"
CONTAINER_NAME="${CONTAINER_NAME:-excalibur_daemon}"
LOG_DIR="${LOG_DIR:-$PWD/logs}"
RETRIES="${RETRIES:-30}"   # ~30 * 0.25s = 7.5s health window
SLEEP_SECS="0.25"

die() { echo "✖ $*" >&2; exit 1; }
info(){ echo "➜ $*"; }
ok()  { echo "✔ $*"; }

# --- args ---------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace) WORKSPACE_DEFAULT="$2"; shift 2;;
    --image)     IMAGE="$2"; shift 2;;
    --no-build)  NO_BUILD="true"; shift 1;;
    *) die "Unknown arg: $1";;
  esac
done

# --- checks -------------------------------------------------------------------
command -v docker >/dev/null 2>&1 || die "Docker not found. Install Docker first."

# Load .env if present (without error if missing)
if [[ -f ".env" ]]; then
  info "Loading .env"
  set -a; # export all sourced vars
  # shellcheck disable=SC1091
  . ".env"
  set +a
fi

WORKSPACE="${EXCALIBUR_WORKSPACE:-$WORKSPACE_DEFAULT}"
[[ -d "$WORKSPACE" ]] || die "Workspace not found: $WORKSPACE"
PORT="${PORT:-8765}"
EXCALIBUR_ALLOWLIST="${EXCALIBUR_ALLOWLIST:-.}"
EXCALIBUR_TEST_CMD="${EXCALIBUR_TEST_CMD:-PYTHONPATH=. pytest -q}"
EXCALIBUR_LOG_FILE="${EXCALIBUR_LOG_FILE:-.ide-bridge.log}"

# Port sanity check (best-effort)
if command -v ss >/dev/null 2>&1; then
  if ss -lnt "( sport = :$PORT )" | grep -q ":$PORT"; then
    die "Port $PORT appears in use. Set PORT to another value or free it."
  fi
fi

# --- build --------------------------------------------------------------------
if [[ "$NO_BUILD" != "true" ]]; then
  info "Building Docker image: $IMAGE"
  docker build -t "$IMAGE" -f docker/Dockerfile . >/dev/null
  ok "Image built."
else
  info "Skipping docker build (--no-build)."
fi

# Remove any previous container with the same name
if docker ps -a --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
  info "Removing previous container: $CONTAINER_NAME"
  docker rm -f "$CONTAINER_NAME" >/dev/null || true
fi

# --- run ----------------------------------------------------------------------
mkdir -p
