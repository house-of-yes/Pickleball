#!/usr/bin/env bash
# Quickstart (hardened)
set -euo pipefail
IFS=$'\n\t'
. "$(dirname "$0")/../scripts/shell_prelude.sh"

echo "Pickleball quickstart"
python3 -V
echo "Run: make bootstrap && make check"
