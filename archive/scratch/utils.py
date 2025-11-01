"""
Utility functions for interacting with the Pickleball daemon from Python.

- prep(): light housekeeping (loads .env files if present)
- sendfile(path): POST raw file contents to /apply
- get(path): GET /get?path=... (returns text)
- health(): GET /health (returns dict)
- version(): GET /version (returns dict)
"""

from __future__ import annotations

import os
import pathlib
import requests
from typing import Dict, Any, Iterable, Optional


# --- tiny dotenv loader (no external dependency) -----------------------------

def _load_env_file(env_path: pathlib.Path) -> None:
    """Load KEY=VALUE pairs from a .env file into os.environ (best-effort)."""
    try:
        with env_path.open("r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if "=" not in line:
                    continue
                key, val = line.split("=", 1)
                key = key.strip()
                # Strip surrounding quotes if present
                val = val.strip().strip('"').strip("'")
                # Do not overwrite existing environment
                os.environ.setdefault(key, val)
    except FileNotFoundError:
        pass


def prep(extra_env_paths: Optional[Iterable[str]] = None) -> None:
    """
    Housekeeping:
      - Load .env from CWD
      - Load .env from git repo root (if any)
      - Load any extra paths passed in
    """
    _load_env_file(pathlib.Path(".env"))

    # Load from git root if available
    try:
        import subprocess

        top = (
            subprocess.run(
                ["git", "rev-parse", "--show-toplevel"],
                check=False,
                capture_output=True,
                text=True,
            ).stdout.strip()
            or None
        )
        if top:
            _load_env_file(pathlib.Path(top) / ".env")
    except Exception:
        # git may not be present; ignore
        pass

    if extra_env_paths:
        for p in extra_env_paths:
            _load_env_file(pathlib.Path(p))


# --- endpoint + auth ---------------------------------------------------------

def _api_base() -> str:
    host = os.environ.get("EX_HOST", "127.0.0.1")
    port = os.environ.get("EX_PORT") or os.environ.get("PORT", "8765")
    return f"http://{host}:{port}"


def _auth_headers() -> Dict[str, str]:
    token = os.environ.get("EX_TOKEN") or os.environ.get("EXCALIBUR_TOKEN")
    return {"Authorization": f"Bearer {token}"} if token else {}


# --- core utilities ----------------------------------------------------------

def sendfile(path: str) -> requests.Response:
    """
    Send the raw contents of `path` to the Pickleball daemon (/apply endpoint).
    """
    prep()  # ensure env is loaded before resolving base/auth
    p = pathlib.Path(path)
    if not p.exists():
        raise FileNotFoundError(path)

    headers = {"Content-Type": "text/plain; charset=utf-8", **_auth_headers()}
    with p.open("rb") as fh:
        resp = requests.post(f"{_api_base()}/apply", headers=headers, data=fh)
    resp.raise_for_status()
    return resp


def get(path: str) -> str:
    """
    Fetch a repo-relative file via /get and return its text.
    """
    prep()
    params = {"path": path}
    headers = _auth_headers()
    resp = requests.get(f"{_api_base()}/get", headers=headers, params=params)
    resp.raise_for_status()
    return resp.text


def health() -> Dict[str, Any]:
    """
    Return /health JSON as a dict.
    """
    prep()
    headers = _auth_headers()
    resp = requests.get(f"{_api_base()}/health", headers=headers, timeout=5)
    resp.raise_for_status()
    return resp.json()


def version() -> Dict[str, Any]:
    """
    Return /version JSON as a dict.
    """
    prep()
    headers = _auth_headers()
    resp = requests.get(f"{_api_base()}/version", headers=headers, timeout=5)
    resp.raise_for_status()
    return resp.json()

