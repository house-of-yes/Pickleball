#!/usr/bin/env bash
# Rewrite old local imports to package imports.
# Usage: bash tools/fix_imports.sh
set -euo pipefail
shopt -s nullglob

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Prefer ripgrep + sd; fall back to perl -pi
do_replace() {
  local pattern="$1" repl="$2"
  if command -v rg >/dev/null 2>&1 && command -v sd >/dev/null 2>&1; then
    rg -l --glob '!**/.venv/**' --glob '!**/.git/**' "$pattern" "$root" | while read -r f; do
      sd "$pattern" "$repl" "$f"
    done
  else
    # portable fallback
    find "$root" -type f \( -name '*.py' -o -name '*.md' -o -name '*.sh' \) \
      -not -path '*/.git/*' -not -path '*/.venv/*' \
      -exec perl -0777 -pi -e "s/$pattern/$repl/g" {} +
  fi
}

# from logging_setup import X  -> from Pickleball.logging_setup import X
do_replace '\bfrom\s+logging_setup\s+import\b' 'from Pickleball.logging_setup import'
# import logging_setup          -> import Pickleball.logging_setup as logging_setup (safer)
do_replace '^\s*import\s+logging_setup\b' 'import Pickleball.logging_setup as logging_setup'

# from config import X          -> from Pickleball.config import X
do_replace '\bfrom\s+config\s+import\b' 'from Pickleball.config import'
# import config                 -> import Pickleball.config as config
do_replace '^\s*import\s+config\b' 'import Pickleball.config as config'

echo "Rewrites complete."
