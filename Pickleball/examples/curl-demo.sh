#!/usr/bin/env bash
# One-minute HTTP demo: health → apply → get → list → version.
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:8765}"
TOKEN="${EXCALIBUR_TOKEN:-}"
HDRS=(-H "Content-Type: application/json")
if [[ -n "$TOKEN" ]]; then
  HDRS+=(-H "X-Pickleball-Token: $TOKEN")
fi

pretty() {
  if command -v jq >/dev/null 2>&1; then jq .; else python -m json.tool; fi
}

echo "==> GET /health"
curl -fsS "${BASE_URL}/health" | pretty

echo "==> POST /apply (roles/demo.py)"
PAYLOAD=$(cat <<'JSON'
{
  "path": "roles/demo.py",
  "content": "def add(a,b):\n    return a+b\n",
  "run_tests": false
}
JSON
)
curl -fsS -X POST "${HDRS[@]}" --data "$PAYLOAD" "${BASE_URL}/apply" | pretty

echo "==> GET /get?path=roles/demo.py"
curl -fsS "${BASE_URL}/get?path=roles/demo.py" | pretty

echo "==> GET /list?path=.&glob=**/*.py&max=10"
curl -fsS "${BASE_URL}/list?path=.&glob=**/*.py&max=10" \
  ${TOKEN:+-H "X-Pickleball-Token: $TOKEN"} | pretty

echo "==> GET /version"
curl -fsS "${BASE_URL}/version" | pretty

echo "✓ Done."

