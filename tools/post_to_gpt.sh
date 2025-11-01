#!/usr/bin/env bash
# post_to_gpt.sh — ship Termux output into Pickleball’s inbox for GPT review
#
# Usage:
#   some_command | tools/post_to_gpt.sh
#
# Behavior:
#   - Wraps stdin into a markdown file with timestamp.
#   - Drops it into inbox/<timestamp>.md inside your repo.
#   - Uses the running Pickleball service (/apply) to save the file.
#   - Removes the file locally after upload (inbox stays only on the server).
#   - Prints “OK -> inbox/...” on success.
#
set -euo pipefail
IFS=$'\n\t'

ts="$(date -u +'%Y%m%d-%H%M%S')"
dest="inbox/${ts}.md"

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
{
  echo "# Report"
  echo
  echo "Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  echo
  cat
} > "$tmp"

curl -s -X POST \
  -H "Content-Type: text/plain; charset=utf-8" \
  -H "X-Path: ${dest}" \
  --data-binary @"$tmp" \
  "http://${EX_HOST:-127.0.0.1}:${EX_PORT:-8765}/apply" >/dev/null

echo "OK -> ${dest}"
