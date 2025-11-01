#!/usr/bin/env bash
# Pickleball tools/xcal_interceptor.sh
# Toggleable DEBUG-trap that routes most external commands through `xcal eval`.
# Safe defaults; exclusions to avoid recursion/footguns.

# --- Config -------------------------------------------------------------------
: "${XCAL_BINARY:=xcal}"             # override if xcal lives elsewhere
: "${XCAL_MODE:=off}"                # default off; use `xcal-on` to enable
: "${XCAL_FIXUPS:=on}"               # apply tiny typo fixups when routing
: "${XCAL_ECHO:=off}"                # echo rewritten command prior to running

# Commands we will NOT intercept (regex alternation, anchored by bash regex)
# - builtins & common shell metas; add more as needed
XCAL_EXCLUDE_REGEX='^(
  (cd|pushd|popd|exit|logout|fg|bg|jobs|kill|wait|disown)|
  (alias|unalias|type|hash|help|history)|
  (export|readonly|local|declare|typeset|unset|eval|exec|source|\.)|
  (function)|(:)|(\{)|(\})|
  (\[[^]]*\]) # test built-in
)$'

# Lines we skip entirely (empty, pure comments)
_xcal_skip_line () {
  [[ -z "${1// }" ]] && return 0
  [[ "$1" =~ ^[[:space:]]*# ]] && return 0
  return 1
}

# Quick heuristic: is this an assignment or control structure we should skip?
_xcal_is_controlish () {
  local cmd="$1"
  [[ "$cmd" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] && return 0
  [[ "$cmd" =~ ^(if|then|elif|else|fi|for|select|while|until|do|done|case|esac)\b ]] && return 0
  [[ "$cmd" =~ \\$ ]] && return 0   # continued lines
  [[ "$cmd" =~ \|$ ]] && return 0   # pipeline continuation
  return 1
}

# Gentle fixups for frequent typos (preserve intent; keep very narrow)
_xcal_fixup () {
  local s="$1"
  # pytest flags spaced
  s="${s//pytest-q/pytest -q}"
  s="${s//pytest-vv/pytest -vv}"
  s="${s//pytest-x/pytest -x}"
  s="${s//pytest- q/pytest -q}"
  s="${s//pytest- vv/pytest -vv}"
  s="${s//pytest- x/pytest -x}"
  printf '%s' "$s"
}

# Public helper: run a command string via xcal with fixups (unless 'verbatim' is set)
xrun () {
  if [[ $# -eq 0 ]]; then
    echo "Usage: xrun <command string>" >&2
    return 2
  fi
  local s="$*"
  if [[ "${1:-}" == "verbatim" ]]; then
    shift
    s="$*"
  elif [[ "$XCAL_FIXUPS" == "on" ]]; then
    s="$(_xcal_fixup "$s")"
  fi
  [[ "$XCAL_ECHO" == "on" ]] && echo "[xcal] $s" >&2
  "$XCAL_BINARY" eval "$s"
}

# Toggle & status
xcal-on ()  { export XCAL_MODE=on;  echo "[xcal] interception ON"; }
xcal-off () { export XCAL_MODE=off; echo "[xcal] interception OFF"; }
xcal-status () {
  echo "[xcal] mode=$XCAL_MODE fixups=$XCAL_FIXUPS echo=$XCAL_ECHO binary=${XCAL_BINARY}"
}

# DEBUG trap: decide to intercept or not
_xcal_trap () {
  # Only intercept in interactive shells
  [[ $- == *i* ]] || return 0
  [[ "${XCAL_MODE}" == "on" ]] || return 0

  local cmd="$BASH_COMMAND"

  _xcal_skip_line "$cmd" && return 0
  _xcal_is_controlish "$cmd" && return 0

  # Do not intercept our own helper commands or excluded builtins
  if [[ "$cmd" =~ ^(xcal-(on|off|status)|xrun)\b ]]; then
    return 0
  fi
  if [[ "$cmd" =~ $XCAL_EXCLUDE_REGEX ]]; then
    return 0
  fi

  # Avoid infinite loops: do not intercept xcal itself
  if [[ "$cmd" =~ ^(xcal|${XCAL_BINARY//\//\\/})\b ]]; then
    return 0
  fi

  # Perform fixups if enabled
  if [[ "$XCAL_FIXUPS" == "on" ]]; then
    cmd="$(_xcal_fixup "$cmd")"
  fi

  [[ "$XCAL_ECHO" == "on" ]] && echo "[xcal] $cmd" >&2

  # Execute via xcal; then prevent the original command from running
  "$XCAL_BINARY" eval "$cmd"
  # Replace the current command with a no-op so bash doesn't run it again
  builtin :
  # Important: Return nonzero to tell bash the original failed? No — we noop.
  return 0
}

# Enable trap
enable_xcal_trap () {
  # Avoid stacking multiple traps
  case "$PROMPT_COMMAND" in
    *"_xcal_trap"*) : ;;
    *) trap '_xcal_trap' DEBUG ;;
  esac
}

# Disable trap
disable_xcal_trap () {
  trap - DEBUG || true
}

# Auto-enable only if user toggled on
[[ "$XCAL_MODE" == "on" ]] && enable_xcal_trap || true
