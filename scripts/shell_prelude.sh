#!/usr/bin/env bash
# Pickleball Shell Prelude — standard helpers & safety for scripts/*
# Provides:
#   - Strict mode + safe IFS
#   - Color constants: C_RESET C_RED C_YELLOW C_GREEN C_BLUE C_DIM
#   - Line helpers: say, ok, fix, warn, err  (with [OK]/[FIX]/[WARN]/[ERR] tags)
#   - JSON helpers: json_escape, COLOR_JSON
#   - Defaults: DO_BEEP, DO_NOTIFY

# --- Safety ---
set -euo pipefail
IFS=$'\n\t'

# --- Minimal tool sanity ---
command -v mktemp >/dev/null 2>&1 || { echo "[ERR] mktemp required"; exit 1; }

# --- Defaults (overridable via env) ---
: "${DO_BEEP:=0}"
: "${DO_NOTIFY:=0}"

# --- Color detection (Termux-safe) ---
_color_enabled=0
if [ -t 1 ]; then
  if command -v tput >/dev/null 2>&1; then
    if tput setaf 1 >/dev/null 2>&1; then
      _color_enabled=1
    fi
  fi
fi

if [ "${NO_COLOR:-}" != "" ]; then _color_enabled=0; fi
if [ "${FORCE_COLOR:-}" != "" ]; then _color_enabled=1; fi

if [ "$_color_enabled" -eq 1 ]; then
  C_RESET="$(printf '\033[0m')"
  C_RED="$(printf '\033[31m')"
  C_YELLOW="$(printf '\033[33m')"
  C_GREEN="$(printf '\033[32m')"
  C_BLUE="$(printf '\033[34m')"
  C_DIM="$(printf '\033[2m')"
else
  C_RESET=""; C_RED=""; C_YELLOW=""; C_GREEN=""; C_BLUE=""; C_DIM=""
fi

# JSON mirror of UI/color capability
if [ "$_color_enabled" -eq 1 ]; then
  COLOR_JSON='{"color":true}'
else
  COLOR_JSON='{"color":false}'
fi

# --- Line helpers ---
# Note: Bootstrap’s summary counts rely on ^\[OK], ^\[FIX], ^\[WARN], ^\[ERR]
say()  { printf "%s%s%s\n" "$C_DIM" "$*" "$C_RESET"; }
ok()   { printf "[OK] %s%s%s\n"   "$C_GREEN" "$*" "$C_RESET"; }
fix()  { printf "[FIX] %s%s%s\n"  "$C_BLUE"  "$*" "$C_RESET"; }
warn() { printf "[WARN] %s%s%s\n" "$C_YELLOW" "$*" "$C_RESET"; }
err()  { printf "[ERR] %s%s%s\n"  "$C_RED" "$*" "$C_RESET"; }

# --- JSON escape helper ---
# Escapes \, ", newline, tab, carriage return for embedding shell strings into JSON
json_escape() {
  # shellcheck disable=SC2001
  sed \
    -e 's/\\/\\\\/g' \
    -e 's/"/\\"/g' \
    -e 's/\r/\\r/g' \
    -e 's/\t/\\t/g' \
    -e ':a;N;$!ba;s/\n/\\n/g'
}

# --- End Prelude ---
