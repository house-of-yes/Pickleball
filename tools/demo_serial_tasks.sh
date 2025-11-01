#!/usr/bin/env bash
# Example "Fancy Serve" using serial tokens.
# Safe to re-run; each TASK is idempotent by token.
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source tools/serial_tasks.sh

# Example tasks (replace with real ones)
task_run "TOK-0001" "Ensure logs + state directories exist" -- 'mkdir -p var/logs var/state/tasks'
task_run "TOK-0002" "Print python version" -- 'python -V || python3 -V'
task_run "TOK-0003" "Pytest quick dry-run" -- 'pytest -q -x -vv || true'
