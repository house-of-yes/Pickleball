import os
import sys
import importlib
from pathlib import Path
from starlette.testclient import TestClient

# Ensure repo root on path
THIS_DIR = Path(__file__).resolve().parent
REPO_ROOT = THIS_DIR.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

def make_client(tmp_path: Path) -> TestClient:
    # Per-test environment
    os.environ["EXCALIBUR_WORKSPACE"] = str(tmp_path)
    os.environ["EXCALIBUR_ALLOWLIST"] = "."
    os.environ["EXCALIBUR_DRY_RUN_DEFAULT"] = "false"
    os.environ["EXCALIBUR_LOG_FILE"] = str(tmp_path / ".ide-bridge.log")
    os.environ["EXCALIBUR_TEST_CMD"] = "python -c \"print('ok')\""

    # Reload the app module so globals pick up fresh env
    app_mod = importlib.import_module("Pickleball.Pickleball")
    app_mod = importlib.reload(app_mod)
    return TestClient(app_mod.app)

def test_health(tmp_path):
    client = make_client(tmp_path)
    r = client.get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body.get("ok") is True
    assert str(tmp_path) in body.get("workspace", "")

def test_apply_json_no_tests(tmp_path):
    client = make_client(tmp_path)
    payload = {"path": "roles/example.py", "content": "def add(a,b):\n    return a+b\n", "run_tests": False}
    r = client.post("/apply", json=payload)
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["applied"] is True
    written = tmp_path / "roles" / "example.py"
    assert written.exists()
    assert "tests" not in data

def test_get_returns_file_after_apply(tmp_path):
    client = make_client(tmp_path)
    rel = "pkg/mod.py"
    content = "VALUE = 42\n"
    r1 = client.post("/apply", json={"path": rel, "content": content, "run_tests": False})
    assert r1.status_code == 200, r1.text
    r2 = client.get("/get", params={"path": rel})
    assert r2.status_code == 200, r2.text
    body = r2.json()
    assert body["relpath"] == rel
    assert body["size"] == len(content)
    assert body["content"] == content

def test_toggle_inactive_roundtrip(tmp_path):
    client = make_client(tmp_path)
    rel = "tests/test_math.py"
    init = "def test_add():\n    assert 1+1 == 2\n"
    (tmp_path / "tests").mkdir(parents=True, exist_ok=True)
    (tmp_path / rel).write_text(init, encoding="utf-8")

    # Deactivate test_*.py -> inactive_*.py
    r1 = client.post("/toggle_inactive", json={"path": rel})
    assert r1.status_code == 200, r1.text
    out1 = r1.json()
    assert out1["action"] == "deactivated"
    deactivated = tmp_path / "tests" / "inactive_math.py"
    assert deactivated.exists() and not (tmp_path / rel).exists()

    # Reactivate inactive_*.py -> test_*.py
    r2 = client.post("/toggle_inactive", json={"path": "tests/inactive_math.py"})
    assert r2.status_code == 200, r2.text
    out2 = r2.json()
    assert out2["action"] == "reactivated"
    reactivated = tmp_path / rel
    assert reactivated.exists() and not deactivated.exists()
