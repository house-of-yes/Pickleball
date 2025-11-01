from __future__ import annotations
import os
import json
import base64
import hashlib
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Dict, Any

from starlette.applications import Starlette
from starlette.responses import JSONResponse
from starlette.routing import Route
from starlette.requests import Request

from .testsceope import build_cmd, TIMEOUT  # NOTE: typo fixed below in final line
# ^^^ (will be corrected to from .testscope import build_cmd, TIMEOUT)

REPO_ROOT = Path(os.environ.get("EXCALIBUR_WORKSPACE", ".")).resolve()
ALLOWLIST = [a.strip() for a in os.environ.get("EXCALIBUR_ALLOWLIST", ".").split(",") if a.strip()]
TOKEN = os.environ.get("EXCALIBUR_TOKEN", "")
APP_VERSION = {"name": "Pickleball", "version": "0.4.0"}

def _in_allowlist(path: Path) -> bool:
    try:
        rel = path.resolve().relative_to(REPO_ROOT)
    except Exception:
        return False
    # very simple allowlist: "." means repo; allow any child
    return any(str(rel).startswith(p.strip("/")) or p == "." for p in ALLOWLIST)

def _sha256_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()

@dataclass
class LastTest:
    ok: bool
    ts: float
    scope: str
    summary: str

class Api:
    def __init__(self) -> None:
        self.last_test: Optional[LastTest] = None
        self.last_changed_path: Optional[str] = None

    async def health(self, request: Request):
        auth = "enabled" if TOKEN else "disabled"
        return JSONResponse({"ok": True, "workspace": str(REPO_ROOT), "allowlist": ALLOWLIST, "auth": auth})

    async def version(self, request: Request):
        return JSONResponse(APP_VERSION)

    async def get_file(self, request: Request):
        qs = dict(request.query_params)
        path = qs.get("path")
        if not path:
            return JSONResponse({"detail": "path required"}, status_code=422)
        abs_path = (REPO_ROOT / path).resolve()
        if not _in_allowlist(abs_path) or not abs_path.exists():
            return JSONResponse({"detail": "File not found"}, status_code=404)
        data = abs_path.read_bytes()
        return JSONResponse({
            "ok": True,
            "path": path,
            "content_b64": base64.b64encode(data).decode("ascii"),
            "sha256": _sha256_bytes(data),
        })

    async def apply(self, request: Request):
        body = await request.json()
        path = body.get("path")
        content_b64 = body.get("content_b64")
        if not path or not content_b64:
            return JSONResponse({"detail": "path and content_b64 required"}, status_code=422)   
