#!/usr/bin/env bash
# Wrapper for repo verification (Green Stream)
set -euo pipefail

# Constitution (must pass)
tests/constitution.sh

# Hygiene (non-fatal)
tests/hygiene.sh || true
