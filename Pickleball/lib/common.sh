#!/data/data/com.termux/files/usr/bin/bash
# Common helpers shared across platform scripts (Termux, Linux, iOS, desktop).

set -euo pipefail

# --- Paths / defaults
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
LOG_ROOT="${LOG_ROOT:-$HOME/.local/state/Pickleball}"
mkdir -p "$LOG_ROOT" 2>/dev/null || true

# --- Tools
CURL="$(command -v curl || true)"
JQ="$(command -v jq || true)"
SS="$(command -v ss || true)"
NETSTAT="$(command -v netstat || true)"

ts(){ date +"%Y-%m-%d %H:%M:%S"; }

# --- API endpoint resolution
EX_HOST="${EX_HOST:-127.0.0.1}"
EX_PORT="${EX_PORT:-${PORT:-8765}}"
ex_api_base(){ printf "http://%s:%s" "$EX_HOST" "$EX_PORT"; }

# --- JSON pretty (if jq present)
ex_json(){ if [ -n "$JQ" ]; then "$JQ" -c . 2>/dev/null || cat; else cat; fi; }

# --- Health + version probe
ex_probe_health_and_version() {
  local base; base="$(ex_api_base)"
  local hurl="$base/health" vurl="$base/version"
  if [ -n "$CURL" ] && "$CURL" -fsS "$hurl" >/dev/null 2>&1; then
    if [ -n "$JQ" ]; then
      HEALTH_JSON="$("$CURL" -fsS "$hurl" | ex_json)"
      VERSION_JSON="$("$CURL" -fsS "$vurl" | ex_json || echo '{}')"
    else
      HEALTH_JSON="$("$CURL" -fsS "$hurl" || echo '{}')"
      VERSION_JSON="$("$CURL" -fsS "$vurl" || echo '{}')"
    fi
    return 0
  fi
  return 1
}

# --- Port diagnostics
ex_port_who() {
  local port="$EX_PORT"
  if [ -n "$SS" ]; then
    ss -ltnp 2>/dev/null | awk -v p=":"p '$4 ~ p {print "  ",$0}'
  elif [ -n "$NETSTAT" ]; then
    netstat -ltnp 2>/dev/null | awk -v p=":"p '$4 ~ p {print "  ",$0}'
  fi
}

ex_port_in_use() {
  local port="$EX_PORT"
  if [ -n "$SS" ] && ss -ltnp 2>/dev/null | grep -q ":$port "; then return 0; fi
  if [ -n "$NETSTAT" ] && netstat -ltnp 2>/dev/null | grep -q ":$port "; then return 0; fi
  return 1
}

# --- HTTP helpers
ex_http_post_json() {
  # args: <path> <json-string>
  # uses: EX_HOST/EX_PORT
  [ -n "$CURL" ] || { echo "[!] curl not found" >&2; return 2; }
  local base; base="$(ex_api_base)"
  "$CURL" -fsS "$base/$1" -H "Content-Type: application/json" -d "$2"
}

ex_http_get() {
  # args: <path>
  [ -n "$CURL" ] || { echo "[!] curl not found" >&2; return 2; }
  local base; base="$(ex_api_base)"
  "$CURL" -fsS "$base/$1"
}

# --- Pickleball-specific convenience
# Send a file's raw contents to /apply without RP wrapping (plain text payload).
# The Riot Act use-case prefers this.
ex_apply_plain() {
  # args: <filesystem-path>
  [ $# -eq 1 ] || { echo "[!] ex_apply_plain requires a file path" >&2; return 2; }
  [ -f "$1" ] || { echo "[!] file not found: $1" >&2; return 2; }
  [ -n "$CURL" ] || { echo "[!] curl not found" >&2; return 2; }
  local base; base="$(ex_api_base)"
  "$CURL" -fsS "$base/apply" -H "Content-Type: application/json" --data-binary @"$1"
}

# Fetch a path via /get (returns raw file content).
ex_get_path() {
  # args: <repo-relative-path> (e.g., context/riot.act)
  [ $# -eq 1 ] || { echo "[!] ex_get_path requires a repo-relative path" >&2; return 2; }
  ex_http_get "get?path=$1"
}

