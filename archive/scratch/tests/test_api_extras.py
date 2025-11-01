import os
import sys
import importlib
from pathlib import Path
from starlette.testclient import TestClient

THIS_DIR = Path(__file__).resolve().parent
REPO_ROOT = THIS_DIR.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))


def make_client(tmp_path: Path, *, token: str | None = None, allowlist: str = ".") -> TestClient:
    # Per-test environment
    os.environ["EXCALIBUR_WORKSPACE"] = str(tmp_path)
    os.environ["EXCALIBUR_ALLOWLIST"] = allowlist
    os.environ["EXCALIBUR_DRY_RUN_DEFAULT"] = "false"
    os.environ["EXCALIBUR_LOG_FILE"] = str(tmp_path / ".ide-bridge.log")
    os.environ["EXCALIBUR_TEST_CMD"] = "python -c \"print('ok')\""
    if token is not None:
        os.environ["EXCALIBUR_TOKEN"] = token
    else:
        os.environ.pop("EXCALIBUR_TOKEN", None)

    app_mod = importlib.import_module("Pickleball.Pickleball")
    app_mod = importlib.reload(app_mod)
    return TestClient(app_mod.app)


def test_version_endpoint_has_expected_shape(tmp_path: Path):
    client = make_client(tmp_path)
    r = client.get("/version")
    assert r.status_code == 200, r.text
    body = r.json()
    # minimal shape checks (works even outside a git repo)
    assert body["ok"] is True
    assert body["name"] == "Pickleball"
    assert "workspace" in body and isinstance(body["workspace"], str)
    assert "git" in body and {"commit", "tag", "branch"} <= set(body["git"].keys())
    assert "build" in body and "mtime" in body["build"]


def test_auth_required_on_protected_endpoints(tmp_path: Path):
    # list_files is protected by token when EXCALIBUR_TOKEN is set
    token = "secret123"
    client = make_client(tmp_path, token=token)

    # No token header -> 401
    r1 = client.get("/list", params={"path": ".", "glob": "**/*", "max": "10"})
    assert r1.status_code == 401, r1.text

    # With token header -> 200
    r2 = client.get("/list", params={"path": ".", "glob": "**/*", "max": "10"}, headers={"X-Pickleball-Token": token})
    assert r2.status_code == 200, r2.text


def test_allowlist_enforced_for_apply(tmp_path: Path):
    # Only allow 'roles' subtree
    client = make_client(tmp_path, allowlist="roles")

    # Allowed path
    r_ok = client.post("/apply", json={"path": "roles/ok.py", "content": "X=1\n", "run_tests": False})
    assert r_ok.status_code == 200, r_ok.text

    # Disallowed path
    r_bad = client.post("/apply", json={"path": "other/nope.py", "content": "Y=2\n", "run_tests": False})
    assert r_bad.status_code == 403
    assert "allowlist" in r_bad.text


def test_apply_via_code_fence(tmp_path: Path):
    client = make_client(tmp_path)
    body = (
        "```python\n"
        "pkg/thing.py\n"
        "VALUE = 7\n"
        "```\n"
    )
    r = client.post("/apply", data=body, headers={"Content-Type": "text/plain"})
    assert r.status_code == 200, r.text
    assert (tmp_path / "pkg/thing.py").exists()


def test_list_glob_and_max(tmp_path: Path):
    client = make_client(tmp_path)
    # create a small tree
    files = [
        tmp_path / "a.py",
        tmp_path / "b.txt",
        tmp_path / "sub" / "c.py",
        tmp_path / "sub" / "d.md",
    ]
    for p in files:
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("x\n", encoding="utf-8")

    # only *.py
    r_py = client.get("/list", params={"path": ".", "glob": "**/*.py", "max": "10"})
    assert r_py.status_code == 200, r_py.text
    names = set(r_py.json()["files"])
    assert names == {"a.py", "sub/c.py"}

    # max=1 truncates
    r_one = client.get("/list", params={"path": ".", "glob": "**/*", "max": "1"})
    assert r_one.status_code == 200, r_one.text
    assert r_one.json()["count"] == 1
