#!/usr/bin/env bash
# tools/serial_tasks.sh
# Helpers for idempotent "Atomic Tasks" keyed by SERIAL_TOKEN.
# Usage patterns:
#   source tools/serial_tasks.sh
#   task_run "TOKEN-001" "Create config dir" -- bash -lc 'mkdir -p config'
#   task_run "TOKEN-002" "Init DB" -- ./bin/init-db --flags
#
# Conventions:
# - Each task has a unique token string (A–Z, 0–9, dashes/underscores).
# - Completion recorded at: var/state/tasks/<token>.done  (NDJSON metadata)
# - Re-run safe: if done, we print a "SKIP" banner and continue.
# - Force re-run: export SERIAL_FORCE=1  (or task_run --force TOKEN ...).
# - Logging: stdout/stderr captured to var/logs/actions/ and appended NDJSON record
#            if tools/xrun_logged.sh exists; otherwise we inline-run and emit banners.

set -euo pipefail

# Resolve repo root from this file's location
SERIAL_THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERIAL_ROOT="$(cd "$SERIAL_THIS/.." && pwd)"
SERIAL_STATE_DIR="$SERIAL_ROOT/var/state/tasks"
SERIAL_LOG_DIR="$SERIAL_ROOT/var/logs"
SERIAL_ACT_DIR="$SERIAL_LOG_DIR/actions"
mkdir -p "$SERIAL_STATE_DIR" "$SERIAL_ACT_DIR"

_serial_ts() { date -Is; }

_serial_json_escape() {
  python - <<'PY' 2>/dev/null || perl -MJSON::PP -ne 'print encode_json($_) . "\n"' <<'PL'
import json,sys
print(json.dumps(sys.stdin.read()))
PY
cat >/dev/null <<'PL'
PL
}

# Internal: record completion metadata (ndjson) in the .done file
_serial_mark_done() {
  local token="$1" desc="$2" rc="$3" outp="$4" errp="$5"
  local ts="$(_serial_ts)"
  local f="$SERIAL_STATE_DIR/${token}.done"
  local T=$(printf '%s' "$token" | _serial_json_escape)
  local D=$(printf '%s' "$desc"  | _serial_json_escape)
  local O=$(printf '%s' "$outp"  | _serial_json_escape)
  local E=$(printf '%s' "$errp"  | _serial_json_escape)
  printf '{"ts":%s,"token":%s,"desc":%s,"rc":%d,"out":"%s","err":"%s"}\n' \
    "\"$ts\"" "$T" "$D" "$rc" "$outp" "$errp" >> "$f"
}

# Public API: task_run [--force] TOKEN DESC -- <command...>
task_run() {
  local force="${SERIAL_FORCE:-0}"
  if [[ "${1:-}" == "--force" ]]; then force=1; shift; fi
  local token="${1:-}"; shift || true
  local desc="${1:-}"; shift || true
  if [[ "${1:-}" != "--" ]]; then
    echo "task_run: usage: task_run [--force] TOKEN DESC -- <cmd...>" >&2
    return 2
  fi
  shift
  if [[ -z "$token" || -z "$desc" ]]; then
    echo "task_run: TOKEN and DESC required" >&2; return 2
  fi

  local done_file="$SERIAL_STATE_DIR/${token}.done"
  local ts="$(_serial_ts)"

  printf '\n======================================\nTASK %s — %s\n======================================\n' "$token" "$desc"

  if [[ -f "$done_file" && "$force" != "1" ]]; then
    echo "SKIP: already done ($done_file). Export SERIAL_FORCE=1 or use --force to re-run."
    return 0
  fi

  # Choose runner: prefer logged runner if available
  local runner="$SERIAL_ROOT/tools/xrun_logged.sh"
  local rc=0 outp="" errp=""
  if [[ -x "$runner" ]]; then
    local stamp="$(date +%Y%m%d-%H%M%S)-$$"
    outp="$SERIAL_ACT_DIR/${stamp}.${token}.out"
    errp="$SERIAL_ACT_DIR/${stamp}.${token}.err"
    # Run via xrun_logged to capture NDJSON action; also tee to our files for token context
    set +e
    "$runner" "$*" > >(tee "$outp") 2> >(tee "$errp" >&2)
    rc=$?
    set -e
  else
    # Direct execution with inline capture
    local tmpdir; tmpdir="$(mktemp -d)"
    outp="$tmpdir/out"
    errp="$tmpdir/err"
    set +e
    bash -lc "$*" > >(tee "$outp") 2> >(tee "$errp" >&2)
    rc=$?
    set -e
  fi

  _serial_mark_done "$token" "$desc" "$rc" "$outp" "$errp"

  if [[ "$rc" -eq 0 ]]; then
    echo "✅ TASK ${token} OK"
  else
    echo "❌ TASK ${token} FAILED (rc=$rc) — see:"
    echo "   OUT: $outp"
    echo "   ERR: $errp"
    return "$rc"
  fi
}

# Convenience: task_always TOKEN DESC -- <cmd...>
# Marks done regardless of rc, but still returns rc to the caller.
task_always() {
  local token="${1:-}"; shift || true
  local desc="${1:-}"; shift || true
  if [[ "${1:-}" != "--" ]]; then
    echo "task_always: usage: task_always TOKEN DESC -- <cmd...>" >&2
    return 2
  fi
  shift
  local rc=0
  bash -lc "$@" || rc=$?
  _serial_mark_done "$token" "$desc" "$rc" "" ""
  return "$rc"
}
