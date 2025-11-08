#!/usr/bin/env bash
# phoenix-manifesto.sh — runtime indexing for manifesto fragments

set -euo pipefail

PHOENIX_MANIFESTO_DIR="${PHOENIX_MANIFESTO_DIR:-context/manifesto}"

# Build index (lexicographic order on ON_*.fragment)
mapfile -t _mf_list < <(find "$PHOENIX_MANIFESTO_DIR" -maxdepth 1 -type f -name 'ON_*.fragment' 2>/dev/null | sort || true)
export PHOENIX_HAS_MANIFESTO=0
export PHOENIX_MANIFESTO_COUNT=0
export PHOENIX_MANIFESTO_INDEX=""

if (( ${#_mf_list[@]} )); then
  PHOENIX_HAS_MANIFESTO=1
  PHOENIX_MANIFESTO_COUNT=${#_mf_list[@]}
  PHOENIX_MANIFESTO_INDEX=$(printf '%s\n' "${_mf_list[@]}")
fi

export PHOENIX_HAS_MANIFESTO PHOENIX_MANIFESTO_COUNT PHOENIX_MANIFESTO_INDEX

phoenix_manifesto_list() {
  if [[ "${PHOENIX_HAS_MANIFESTO:-0}" -eq 0 ]]; then
    echo "No manifesto fragments found."
    return 0
  fi
  nl -ba <<<"$PHOENIX_MANIFESTO_INDEX"
}

phoenix_manifesto_print() {
  if [[ "${PHOENIX_HAS_MANIFESTO:-0}" -eq 0 ]]; then
    echo "No manifesto fragments to print."
    return 0
  fi
  while IFS= read -r f; do
    echo "===== $(basename "$f") ====="
    cat "$f"
    echo
  done <<<"$PHOENIX_MANIFESTO_INDEX"
}

# Covenant loader (roles)
if [[ -f context/PHOENIX_ROLES.agreement ]]; then
  export PHOENIX_ROLES_AGREEMENT_PATH="context/PHOENIX_ROLES.agreement"
else
  export PHOENIX_ROLES_AGREEMENT_PATH=""
fi

