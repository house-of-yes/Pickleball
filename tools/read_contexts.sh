#!/usr/bin/env bash
# read_contexts.sh — Print ALL files found under any directory literally named "context"
# Usage:
#   tools/read_contexts.sh                # scans $HOME by default
#   tools/read_contexts.sh /path/to/root  # scan a specific root directory tree
#
# Behavior:
# - Recursively finds every directory named "context" anywhere under ROOT.
# - For every regular file inside those context dirs (including subdirs), prints:
#       <absolute file path>
#       <file contents>
#   followed by a blank line.
# - Skips unreadable files quietly.
# - Deterministic ordering (sorted by path).
# - Exits non-zero if ROOT is invalid.

set -euo pipefail

ROOT_INPUT="${1:-$HOME}"

# Resolve to absolute path without relying on readlink -f (Termux-safe)
if [ ! -d "$ROOT_INPUT" ]; then
  echo "ERROR: ROOT directory not found: $ROOT_INPUT" >&2
  exit 1
fi
ROOT_ABS="$(cd "$ROOT_INPUT" && pwd -P)"

# Collect all context dirs, then all files within them; print absolute paths in sorted order
# Use null-delimited pipelines to handle spaces/newlines in filenames robustly.
# shellcheck disable=SC2010

# Build a null-delimited list of files under any .../context/... dir
files_tmp="$(mktemp)"
trap 'rm -f "$files_tmp"' EXIT

# Find all directories named exactly "context"
find "$ROOT_ABS" -type d -name context -print0 \
| while IFS= read -r -d '' ctxdir; do
  # For each context dir, find all regular files within (recursive)
  find "$ctxdir" -type f -print0
done >"$files_tmp"

# If nothing found, exit quietly (success)
if [ ! -s "$files_tmp" ]; then
  exit 0
fi

# Sort paths deterministically and stream each: path line, then contents, then blank line
# Use awk to null→newline safely before sort, then re-read line-by-line.
awk -v RS='\0' '{print}' "$files_tmp" | LC_ALL=C sort | while IFS= read -r f; do
  # Only print readable regular files
  if [ -f "$f" ] && [ -r "$f" ]; then
    printf '%s\n' "$f"
    cat -- "$f"
    printf '\n'
  fi
done
