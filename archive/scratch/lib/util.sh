# Utility helpers for Pickleball scripts. Source this file; do not exec.

# No 'set -euo pipefail' here because this file is meant to be *sourced*.
# Callers (scripts) can choose their own shell options.

# prep
# - Load .env if present (cwd or repo root).
# - Set sensible defaults for host/port.
prep() {
  # Load .env from CWD
  [ -f .env ] && . ./.env

  # Load .env from repo root if available
  if command -v git >/dev/null 2>&1; then
    local top
    top="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    if [ -n "$top" ] && [ -f "$top/.env" ]; then
      . "$top/.env"
    fi
  fi

  EX_HOST="${EX_HOST:-127.0.0.1}"
  EX_PORT="${EX_PORT:-${PORT:-8765}}"
  EX_TOKEN="${EX_TOKEN:-${EXCALIBUR_TOKEN:-}}"
}

# sendfile <path>
# - Sends the raw contents of <path> to the Pickleball daemon (no RP wrapping).
# - Uses EX_HOST/EX_PORT (or PORT), optional bearer token via EX_TOKEN/EXCALIBUR_TOKEN.
sendfile() {
  [ $# -eq 1 ] || { printf "[!] usage: sendfile <repo-relative-path>\n" >&2; return 2; }
  local path="$1"
  [ -f "$path" ] || { printf "[!] file not found: %s\n" "$path" >&2; return 2; }

  prep

  local base="http://${EX_HOST}:${EX_PORT}"
  if [ -n "$EX_TOKEN" ]; then
    curl -fsS "$base/apply" \
      -H "Authorization: Bearer $EX_TOKEN" \
      -H "Content-Type: text/plain; charset=utf-8" \
      --data-binary @"$path"
  else
    curl -fsS "$base/apply" \
      -H "Content-Type: text/plain; charset=utf-8" \
      --data-binary @"$path"
  fi
}
