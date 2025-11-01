#!/usr/bin/env bash
# Run pytest with serial token + logging via xrun_logged.sh.
set -euo pipefail

# EXIGENT directory for the test project:
cd "$HOME/HouseOfYes/king_of_swing"

RUNNER="$HOME/Pickleball/tools/xrun_logged.sh"
if [[ ! -x "$RUNNER" ]]; then
  echo "ERROR: missing runner: $RUNNER" >&2
  exit 1
fi

CMD='pytest -q -x -vv'
echo "👉 Running: $CMD"
"$RUNNER" "$CMD"
