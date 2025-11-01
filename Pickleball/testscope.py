"""
Test scope helpers for Pickleball.

Env:
- EXCALIBUR_TEST_SCOPE=smart|full|changed  (default: smart)
- EXCALIBUR_TEST_SELECTORS=comma,separated globs (optional)
- EXCALIBUR_PYTEST_ARGS=extra args (optional)
- EXCALIBUR_TEST_CMD=base test runner (default: pytest)
- EXCALIBUR_TEST_TIMEOUT=seconds (default: 30)
"""
from __future__ import annotations
import os
import shlex
from pathlib import Path

DEFAULT_SCOPE = os.getenv("EXCALIBUR_TEST_SCOPE", "smart").lower()
DEFAULT_CMD = os.getenv("EXCALIBUR_TEST_CMD", "pytest")
EXTRA_ARGS = os.getenv("EXCALIBUR_PYTEST_ARGS", "")
SELECTORS = [s.strip() for s in os.getenv("EXCALIBUR_TEST_SELECTORS", "").split(",") if s.strip()]
TIMEOUT = int(os.getenv("EXCALIBUR_TEST_TIMEOUT", "30"))

def build_cmd(changed_path: str | None, workspace: Path) -> tuple[list[str], str]:
    """
    Return (argv, scope_label): argv for subprocess.run, human label of scope.
    """
    scope = DEFAULT_SCOPE
    base = shlex.split(DEFAULT_CMD)
    extra = shlex.split(EXTRA_ARGS) if EXTRA_ARGS else []

    if scope == "full" or (scope == "smart" and changed_path is None):
        return (base + ["-q", "--maxfail=1", "--tb=short"] + extra, "full")

    # changed/smart subset:
    candidates: list[str] = []
    if SELECTORS:
        candidates.extend(SELECTORS)

    if changed_path:
        p = Path(changed_path)
        name = p.stem
        # common mirrors
        tests = workspace / "tests"
        mirrors = [
            tests / p.with_name(f"test_{p.stem}.py").name,
            tests / (p.parent.name if p.parent != Path() else "") / f"test_{p.stem}.py",
        ]
        for m in mirrors:
            if m.is_file():
                candidates.append(str(m.relative_to(workspace)))
        # directory suite
        d = tests / (p.parent.name if p.parent != Path() else "")
        if d.is_dir():
            candidates.append(str(d.relative_to(workspace)))
        # name pattern fallback
        candidates.append(f"-k={name}")

    # Dedup, keep order
    seen = set()
    uniq: list[str] = []
    for c in candidates:
        if c not in seen:
            seen.add(c)
            uniq.append(c)

    if not uniq:
        # nothing matched → safer to run full
        return (base + ["-q", "--maxfail=1", "--tb=short"] + extra, "full")

    argv = base + ["-q", "--maxfail=1", "--tb=short", "--last-failed"] + extra + uniq
    return (argv, "subset:" + ",".join(x for x in uniq if not x.startswith("-k")))
