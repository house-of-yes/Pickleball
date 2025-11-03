#!/usr/bin/env bash
# Hygiene checks for Pickleball repo (non-fatal). Green Stream:
# - If no warnings: print a single ✅ Hygiene clean.
# - If warnings: print each as ⚠️ lines, still exit 0.
set -uo pipefail

warns=()

have(){ eval "$1" >/dev/null 2>&1; }
note_warn(){ warns+=("$1"); }

# .gitignore patterns
have 'grep -q "^var/logs/" .gitignore' || note_warn ".gitignore missing var/logs/"
have 'grep -q "^\*\.log$" .gitignore || grep -q "\*\.log" .gitignore' || note_warn ".gitignore missing *.log"
have 'grep -q "__pycache__/" .gitignore' || note_warn ".gitignore missing __pycache__/"

# var/logs exists
[ -d var/logs ] || note_warn "var/logs/ missing (Phoenix will create as needed)"

# no stray external/context
[ -d external/context ] && note_warn "external/context/ still present; migrate to root context/"

# README triple backticks (M-1 suggests indented blocks)
if [ -f README.md ] && grep -q '```' README.md; then
  note_warn "README contains triple backticks; consider indented blocks (M-1)"
fi

# Phoenix hygiene log info (not a warn)
# [no-op]

if [ "${#warns[@]}" -eq 0 ]; then
  echo "✅ Hygiene clean"
else
  for w in "${warns[@]}"; do
    echo "⚠️  $w"
  done
fi

exit 0
