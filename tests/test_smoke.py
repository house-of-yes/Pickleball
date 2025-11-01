#!/usr/bin/env python3
import json, os, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "bootstrap"
STATE = ROOT / "var" / "state" / "bootstrap.json"
LOGDIR = ROOT / "var" / "logs"
LATEST = LOGDIR / "bootstrap.latest.log"
FIFO = Path.home() / "var" / "run" / "hotdrop_in.fifo"

def run_bootstrap(*args):
    return subprocess.run([str(SCRIPT), *args], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

def test_bootstrap_contract_and_banner():
    proc = run_bootstrap("--color=always")
    out = proc.stdout
    assert proc.returncode in (0,2), f"exit {proc.returncode}\n{out}"
    assert ("BOOTSTRAP PASSED CLEAN" in out) or ("READY WITH WARNINGS" in out)
    assert STATE.exists()
    data = json.loads(STATE.read_text())
    for k in ("version","duration_ms","counts","exit_code","tools","services","paths","ui"):
        assert k in data

def test_color_flag_paths():
    proc = run_bootstrap("--color=never")
    assert "\x1b[" not in proc.stdout

def test_hotdrop_fifo_created():
    try:
        if FIFO.exists(): FIFO.unlink()
    except Exception: pass
    proc = run_bootstrap("--color=never")
    assert FIFO.exists()
    assert "created hotdrop fifo" in proc.stdout.lower()

def test_log_rotation_and_latest():
    proc = run_bootstrap("--color=never")
    assert proc.returncode in (0,2)
    assert LATEST.exists()
    logs = list(LOGDIR.glob("bootstrap.*.log"))
    assert any("bootstrap." in l.name for l in logs)
