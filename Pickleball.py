"""
Pickleball daemon — app wiring & runtime state.
"""
import os
from pathlib import Path
from typing import List, Optional

from starlette.applications import Starlette
from starlette.routing import Route, WebSocketRoute

from .api import Api, EventHub

# --- Config -------------------------------------------------------------------
WORKSPACE = Path(os.getenv("EXCALIBUR_WORKSPACE", os.getcwd())).resolve()

# Allowlist
_allow_raw = os.getenv("EXCALIBUR_ALLOWLIST", "").replace(" ", "")
ALLOWLIST_RAW: List[str] = [p for p in _allow_raw.split(",") if p]

def _resolve_allowlist(raw: List[str]) -> List[Path]:
    resolved: List[Path] = []
    for entry in raw:
        if not entry:
            continue
        p = Path(entry)
        base = (WORKSPACE / p).resolve() if not p.is_absolute() else p.resolve()
        try:
            base.relative_to(WORKSPACE)
        except Exception:
            continue
        resolved.append(base)
    return resolved

ALLOWLIST_ABS: List[Path] = _resolve_allowlist(ALLOWLIST_RAW)

# Security
EXCALIBUR_TOKEN: Optional[str] = os.getenv("EXCALIBUR_TOKEN") or None

# Other knobs
TEST_CMD = os.getenv("EXCALIBUR_TEST_CMD", "PYTHONPATH=. pytest -q")
MAX_SUMMARY_LINES = int(os.getenv("EXCALIBUR_MAX_SUMMARY_LINES", "200"))
DRY_RUN_DEFAULT = os.getenv("EXCALIBUR_DRY_RUN_DEFAULT", "false").lower() == "true"
LOG_FILE = Path(os.getenv("EXCALIBUR_LOG_FILE", ".ide-bridge.log")).resolve()

# --- App & routes --------------------------------------------------------------
hub = EventHub()
api = Api(
    workspace=WORKSPACE,
    allowlist_abs=ALLOWLIST_ABS,
    token=EXCALIBUR_TOKEN,
    test_cmd=TEST_CMD,
    max_summary_lines=MAX_SUMMARY_LINES,
    dry_run_default=DRY_RUN_DEFAULT,
    log_file=LOG_FILE,
    hub=hub,
)

routes = [
    Route("/health", endpoint=api.health, methods=["GET"]),
    Route("/version", endpoint=api.version, methods=["GET"]),
    Route("/apply", endpoint=api.apply, methods=["POST"]),
    Route("/get", endpoint=api.get_file, methods=["GET"]),
    Route("/list", endpoint=api.list_files, methods=["GET"]),
    Route("/toggle_inactive", endpoint=api.toggle_inactive, methods=["POST"]),
    Route("/tail", endpoint=api.tail, methods=["GET"]),
    WebSocketRoute("/events", endpoint=api.ws_endpoint_factory()),
]

app = Starlette(routes=routes)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("Pickleball:app", host="127.0.0.1", port=int(os.getenv("PORT", "8765")), reload=False)
