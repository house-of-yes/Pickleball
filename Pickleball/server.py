#!/usr/bin/env python3
"""
Minimal built-in HTTP server for local testing.

Endpoints:
  GET  /health                    -> {"ok": true}
  GET  /version                   -> {"version": "..."}
  GET  /get?path=<repo-path>      -> returns file text
  GET  /ls?path=<dir>             -> {"entries": ["a", "b", ...]}
  POST /apply[?dry_run=1]         -> writes body to repo path given by header X-Path

Env:
  EX_HOST (default 127.0.0.1)
  EX_PORT (default 8765)
  EX_ROOT (default repo root = directory containing this file, parent)

Notes:
  - Text only. No auth. For local dev sanity checks.
"""
from __future__ import annotations
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
from pathlib import Path

try:
    from Pickleball import __version__ as VERSION
except Exception:
    VERSION = "0.0.0"

REPO_ROOT = Path(os.environ.get("EX_ROOT") or (__file__)).resolve().parents[1]

def _json(handler: BaseHTTPRequestHandler, status: int, obj) -> None:
    payload = json.dumps(obj, ensure_ascii=False).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(payload)))
    handler.end_headers()
    handler.wfile.write(payload)

def _text(handler: BaseHTTPRequestHandler, status: int, text: str) -> None:
    data = text.encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "text/plain; charset=utf-8")
    handler.send_header("Content-Length", str(len(data)))
    handler.end_headers()
    handler.wfile.write(data)

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):  # keep output quiet
        return

    def do_GET(self) -> None:  # noqa: N802
        url = urlparse(self.path)
        if url.path == "/health":
            return _json(self, 200, {"ok": True, "root": str(REPO_ROOT)})
        if url.path == "/version":
            return _json(self, 200, {"version": VERSION})
        if url.path == "/get":
            qs = parse_qs(url.query)
            rel = (qs.get("path") or [""])[0]
            if not rel:
                return _json(self, 400, {"ok": False, "err": "missing path"})
            p = (REPO_ROOT / rel).resolve()
            if not str(p).startswith(str(REPO_ROOT)) or not p.exists() or not p.is_file():
                return _json(self, 404, {"ok": False, "err": "not found"})
            return _text(self, 200, p.read_text(encoding="utf-8"))
        if url.path == "/ls":
            qs = parse_qs(url.query)
            rel = (qs.get("path") or [""])[0]
            p = (REPO_ROOT / rel).resolve()
            if not str(p).startswith(str(REPO_ROOT)) or not p.exists() or not p.is_dir():
                return _json(self, 404, {"ok": False, "err": "not found"})
            entries = sorted([q.name for q in p.iterdir()])
            return _json(self, 200, {"entries": entries})
        return _json(self, 404, {"ok": False, "err": "unknown endpoint"})

    def do_POST(self) -> None:  # noqa: N802
        url = urlparse(self.path)
        if url.path != "/apply":
            return _json(self, 404, {"ok": False, "err": "unknown endpoint"})
        qs = parse_qs(url.query)
        dry_run = (qs.get("dry_run") or ["0"])[0] in ("1", "true", "True")
        target = self.headers.get("X-Path")  # expected repo-relative path
        if not target:
            return _json(self, 400, {"ok": False, "err": "missing X-Path header"})
        dest = (REPO_ROOT / target).resolve()
        if not str(dest).startswith(str(REPO_ROOT)):
            return _json(self, 400, {"ok": False, "err": "path escapes repo root"})
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length)
        if not dry_run:
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(body)
        return _json(self, 200, {"ok": True, "dry_run": dry_run, "bytes": len(body), "path": str(dest.relative_to(REPO_ROOT))})

def main() -> None:
    host = os.environ.get("EX_HOST", "127.0.0.1")
    port = int(os.environ.get("EX_PORT", "8765"))
    with HTTPServer((host, port), Handler) as httpd:
        print(f"Serving on http://{host}:{port} (root={REPO_ROOT})")
        httpd.serve_forever()

if __name__ == "__main__":
    main()
