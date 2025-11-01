#!/usr/bin/env bash
# Pickleball: repair_excalibur_service.sh
# Purpose:
#   Recover from runit supervision issues (e.g., "unable to open supervise/ok")
#   and reliably restart the Pickleball service under Termux.
#
# Behavior:
#   - Ensures runit supervision is active for $PREFIX/var/service
#   - (Re)creates service directory if missing/broken
#   - Uses sv (if present) or falls back to bin/Pickleball.termux-service-setup
#   - Emits banners for clear output; idempotent and safe to re-run

set -euo pipefail

banner () {
  local msg="$1"
  printf '\n======================================\n%s\n======================================\n' "$msg"
}

# ── Resolve repo root and setup script ────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SETUP="$ROOT_DIR/bin/Pickleball.termux-service-setup"

if [[ ! -f "$SETUP" ]]; then
  echo "ERROR: Expected setup script not found: $SETUP" >&2
  exit 1
fi
chmod +x "$SETUP" 2>/dev/null || true

# ── Termux paths and service dir ──────────────────────────────────────────────
PREFIX_DEFAULT="/data/data/com.termux/files/usr"
PREFIX="${PREFIX:-$PREFIX_DEFAULT}"
SERVICE_DIR="$PREFIX/var/service/Pickleball"

banner "🏗  Environment"
echo "ROOT_DIR   : $ROOT_DIR"
echo "SETUP      : $SETUP"
echo "PREFIX     : $PREFIX"
echo "SERVICE_DIR: $SERVICE_DIR"

# ── Ensure runit supervision is alive ─────────────────────────────────────────
ensure_supervision () {
  banner "🧪 Checking runit supervision"
  mkdir -p "$PREFIX/var/service"

  # Try official helper if available
  if command -v termux-services >/dev/null 2>&1; then
    termux-services start || true
  fi

  # Spawn runsvdir if not running
  if ! pgrep -f "runsvdir .*${PREFIX}/var/service" >/dev/null 2>&1; then
    echo "Spawning runsvdir for $PREFIX/var/service …"
    nohup "$PREFIX/bin/runsvdir" -P "$PREFIX/var/service" >/dev/null 2>&1 &
    sleep 0.3
  fi

  # Probe sv
  if command -v sv >/dev/null 2>&1; then
    sv status "$SERVICE_DIR" >/dev/null 2>&1 || true
    echo "sv available."
  else
    echo "sv not found; will use setup script fallbacks."
  fi
  echo "Supervision ensured (best-effort)."
}

ensure_supervision

# ── (Re)install the service if missing/broken ─────────────────────────────────
needs_reinstall=false
if [[ ! -d "$SERVICE_DIR" ]]; then
  echo "Service directory missing."
  needs_reinstall=true
elif [[ ! -e "$SERVICE_DIR/supervise/ok" ]]; then
  echo "Service supervise/ok missing (broken supervision)."
  needs_reinstall=true
fi

if $needs_reinstall; then
  banner "🛠  (Re)installing Pickleball service"
  if "$SETUP" install 2>/dev/null; then
    echo "Installer completed."
  else
    echo "No 'install' action; running setup script to provision…"
    "$SETUP" || true
  fi

  # Fallback minimal stub if service dir still missing
  if [[ ! -d "$SERVICE_DIR" ]]; then
    banner "🧩 Creating minimal service stub (fallback)"
    mkdir -p "$SERVICE_DIR" "$SERVICE_DIR/log"
    cat > "$SERVICE_DIR/run" <<SUBEOF
#!/usr/bin/env bash
exec "$SETUP" run
SUBEOF
    chmod +x "$SERVICE_DIR/run"
    cat > "$SERVICE_DIR/log/run" <<'SUBEOF'
#!/usr/bin/env bash
exec svlogd -tt .
SUBEOF
    chmod +x "$SERVICE_DIR/log/run"
  fi
  sleep 0.2
fi

# ── Restart the service ───────────────────────────────────────────────────────
banner "🔁 Restarting Pickleball service"
if command -v sv >/dev/null 2>&1; then
  sv stop "$SERVICE_DIR" >/dev/null 2>&1 || true
  sleep 0.2
  sv start "$SERVICE_DIR" || sv restart "$SERVICE_DIR" || true
else
  "$SETUP" restart
fi

# ── Status & next steps ───────────────────────────────────────────────────────
sleep 0.3
banner "📊 Service status"
if command -v sv >/dev/null 2>&1; then
  sv status "$SERVICE_DIR" || true
else
  echo "sv not available; verify via logs or dashboard."
fi

banner "✅ DONE"
echo "Tip: add an alias: alias xcal-repair='$TARGET'"
