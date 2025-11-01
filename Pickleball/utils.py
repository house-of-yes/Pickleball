"""
Utility functions for interacting with the Pickleball service over HTTP.

Public API:
- version()  -> dict
- health()   -> dict
- get(path)  -> str
- sendfile(path, dry_run=False) -> requests.Response
- listdir(dirpath=".") -> list[str]
"""
from __future__ import annotations

import os
import pathlib
import time
from typing import Any, Dict, Iterable, List, Optional, Tuple

import requests  # runtime dependency

# -------------------- tiny dotenv loader (no external dependency) --------------------


def _load_env_file(env_path: pathlib.Path) -> None:
    """Load KEY=VALUE pairs from a .env file into os.environ (best-effort)."""
    try:
        with env_path.open("r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, val = line.split("=", 1)
                key = key.strip()
                val = val.strip().strip('"').strip("'")
                os.environ.setdefault(key, val)
    except FileNotFoundError:
        pass


def prep(extra_env_paths: Optional[Iterable[str]] = None) -> None:
    """Housekeeping: load .env from CWD, git root (if available), and any extras."""
    _load_env_file(pathlib.Path(".env"))
    # Load from git root if available (ignore errors if git missing)
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
        pass

    if extra_env_paths:
        for p in extra_env_paths:
            _load_env_file(pathlib.Path(p))


# -------------------- endpoint + auth --------------------


def _api_base() -> str:
    host = os.environ.get("EX_HOST", "127.0.0.1")
    port = os.environ.get("EX_PORT") or os.environ.get("PORT", "8765")
    return f"http://{host}:{port}"


def _auth_headers() -> Dict[str, str]:
    token = os.environ.get("EX_TOKEN") or os.environ.get("EXCALIBUR_TOKEN")
    return {"Authorization": f"Bearer {token}"} if token else {}


# -------------------- HTTP helpers --------------------

_DEFAULT_TIMEOUT: Tuple[float, float] = (10.0, 30.0)  # (connect, read)


def _request(
    method: str,
    url: str,
    *,
    headers: Optional[Dict[str, str]] = None,
    params: Optional[Dict[str, Any]] = None,
    data: Any = None,
    retries: int = 2,
):
    """Basic requests wrapper with small retry/backoff."""
    prep()
    headers = headers or {}
    for attempt in range(retries + 1):
        try:
            resp = requests.request(
                method,
                url,
                headers=headers,
                params=params,
                data=data,
                timeout=_DEFAULT_TIMEOUT,
            )
            resp.raise_for_status()
            return resp
        except Exception:
            if attempt >= retries:
                raise
            time.sleep(2.0)


# -------------------- public utilities --------------------


def sendfile(path: str, dry_run: bool = False) -> requests.Response:
    """Send raw contents of `path` to /apply. Returns the Response if status is 2xx.

    Server expects a repo-relative target in header X-Path.
    By default we send the path you provide as X-Path.
    """
    p = pathlib.Path(path)
    if not p.exists():
        raise FileNotFoundError(path)
    headers = {
        "Content-Type": "text/plain; charset=utf-8",
        "X-Path": str(p.as_posix()),
        **_auth_headers(),
    }
    url = f"{_api_base()}/apply"
    if dry_run:
        url += "?dry_run=1"
    with p.open("rb") as fh:
        return _request("POST", url, headers=headers, data=fh)


def get(path: str) -> str:
    """Fetch a repo-relative file via /get and return its text."""
    headers = _auth_headers()
    resp = _request("GET", f"{_api_base()}/get", headers=headers, params={"path": path})
    return resp.text


def health() -> Dict[str, Any]:
    """Return /health JSON as a dict."""
    headers = _auth_headers()
    resp = _request("GET", f"{_api_base()}/health", headers=headers)
    return resp.json()


def version() -> Dict[str, Any]:
    """Return /version JSON as a dict."""
    headers = _auth_headers()
    resp = _request("GET", f"{_api_base()}/version", headers=headers)
    return resp.json()


def listdir(dirpath: str = ".") -> List[str]:
    """Return directory listing from the service via /ls (expects JSON {'entries': [...]})."""
    headers = _auth_headers()
    resp = _request(
        "GET",
        f"{_api_base()}/ls",
        headers=headers,
        params={"path": dirpath},
    )
    data = resp.json()
    entries = data.get("entries", [])
    return [str(e) for e in entries]
