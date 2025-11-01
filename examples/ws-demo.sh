#!/usr/bin/env bash
# One-minute WebSocket demo: connect to /events and print messages.
set -euo pipefail

BASE_URL="${BASE_URL:-ws://127.0.0.1:8765/events}"
TOKEN="${EXCALIBUR_TOKEN:-}"

URL="$BASE_URL"
if [[ -n "$TOKEN" ]]; then
  URL="${BASE_URL}?token=${TOKEN}"
fi

echo "[i] Connecting to $URL"

if command -v wscat >/dev/null 2>&1; then
  # Node.js ws client (npm i -g wscat)
  exec wscat -c "$URL"
else
  # Python fallback
  python3 - <<PY
import asyncio, websockets, os, sys

url = os.environ.get("URL", "$URL")

async def main():
    async with websockets.connect(url) as ws:
        print("[connected]")
        try:
            async for msg in ws:
                print(msg)
        except KeyboardInterrupt:
            print("[bye]")
            sys.exit(0)

asyncio.run(main())
PY
fi
