#!/data/data/com.termux/files/usr/bin/bash
# Termux cleanup/doctor for Pickleball runit service + rogue processes.
# Usage: ./Pickleball/bin/Pickleball.termux-clean.sh [doctor|start|restart|status|stop|disable|purge|fix-supervisor]

set -euo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
SERVICE_NAME="Pickleball"
DEF_DIR="$PREFIX/etc/sv/$SERVICE_NAME"        # service definition
VAR_DIR="$PREFIX/var/service"                 # runsvdir watches this
VAR_LINK="$VAR_DIR/$SERVICE_NAME"             # symlink -> DEF_DIR
SVC_PATH="$VAR_LINK"                          # used for sv commands
SVBIN="$PREFIX/bin/sv"
RUNSVDIRBIN="$PREFIX/bin/runsvdir"
LOG_ROOT="${LOG_ROOT:-$HOME/.local/state/Pickleball}"
SCRIPT_LOG="$LOG_ROOT/clean.log"

mkdir -p "$LOG_ROOT" 2>/dev/null || true

# --- shared libs (graceful fallback) ---------------------------------------
ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

# UI: banner lives here; fallback is a plain one-liner
if [ -f "$ROOT_DIR/lib/ui.sh" ]; then
  . "$ROOT_DIR/lib/ui.sh"
else
  ex_banner_alive(){ printf "Pickleball IS ALIVE\n"; }
fi

# Common helpers (health/port). Keep fallback minimal.
if [ -f "$ROOT_DIR/lib/common.sh" ]; then
  . "$ROOT_DIR/lib/common.sh"
else
  CURL="$(command -v curl || true)"; JQ="$(command -v jq || true)"
  ex_probe_health_and_version() {
    local port="${PORT:-8765}"
    local hurl="http://127.0.0.1:$port/health"
    local vurl="http://127.0.0.1:$port/version"
    if [ -n "$CURL" ] && "$CURL" -fsS "$hurl" >/dev/null 2>&1; then
      HEALTH_JSON="$("$CURL" -fsS "$hurl" 2>/dev/null || echo '{}')"
      VERSION_JSON="$("$CURL" -fsS "$vurl" 2>/dev/null || echo '{}')"
      return 0
    fi
    return 1
  }
  ex_port_in_use(){ return 1; }
  ex_port_who(){ :; }
fi

ts(){ date +"%Y-%m-%d %H:%M:%S"; }
log(){ printf "[%s] %s\n" "$(ts)" "$*" | tee -a "$SCRIPT_LOG" >/dev/null; }

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>
  doctor            Full diagnostic (default)
  start             Robust start (fix symlink, supervisor, perms, health+version check + banner)
  restart           Restart service then health+version check + banner
  status            Show 'sv status' for the service
  stop              Stop service and kill rogue uvicorn processes
  disable           Disable service (remove symlink)
  purge             Remove service definition & symlink; kill supervisors & uvicorns
  fix-supervisor    Restart runsvdir pointing at \$PREFIX/var/service

Script log: $SCRIPT_LOG
EOF
}

unset_svc_env(){ unset SVDIR || true; }

need_termux_services() {
  if ! command -v "$SVBIN" >/dev/null 2>&1 || ! command -v "$RUNSVDIRBIN" >/dev/null 2>&1; then
    log "Installing termux-services…"
    pkg install -y termux-services
  fi
}

kill_uvicorn(){ log "Killing any uvicorn Pickleball:app processes"; pkill -f "uvicorn Pickleball:app" 2>/dev/null || true; sleep 0.2; }

check_definition() {
  log "Checking definition at $DEF_DIR"
  if [ ! -d "$DEF_DIR" ]; then
    echo "[!] Missing definition. Run: ./Pickleball/bin/Pickleball.termux-service-setup"
    return 2
  fi
  [ -x "$DEF_DIR/run" ] || { log "chmod +x $DEF_DIR/run"; chmod +x "$DEF_DIR/run" || true; }
  [ -x "$DEF_DIR/log/run" ] || { log "chmod +x $DEF_DIR/log/run"; chmod +x "$DEF_DIR/log/run" || true; }
  [ -d "$DEF_DIR/log/main" ] || { log "mkdir -p $DEF_DIR/log/main"; mkdir -p "$DEF_DIR/log/main"; }
}

ensure_symlink() {
  log "Ensuring symlink $VAR_LINK -> $DEF_DIR"
  mkdir -p "$VAR_DIR"
  if [ -L "$VAR_LINK" ]; then :; else
    [ -e "$VAR_LINK" ] && { log "Removing non-symlink $VAR_LINK"; rm -rf "$VAR_LINK"; }
    ln -s "$DEF_DIR" "$VAR_LINK"
  fi
}

fix_supervisor() {
  need_termux_services
  log "Killing rogue runsvdir"
  pkill -f runsvdir 2>/dev/null || true
  sleep 0.2
  log "Ensuring supervision dir: $VAR_DIR"
  mkdir -p "$VAR_DIR"
  log "Starting runsvdir on $VAR_DIR"
  unset_svc_env
  setsid -f "$RUNSVDIRBIN" -P "$VAR_DIR" >/dev/null 2>&1 || true
  sleep 0.3
  if pgrep -fa runsvdir >/dev/null; then
    echo "[ok] runsvdir running:"; pgrep -fa runsvdir
  else
    echo "[err] runsvdir did not start; reopen Termux or run: setsid -f $RUNSVDIRBIN -P $VAR_DIR &"
    return 2
  fi
}

sv_status() {
  unset_svc_env
  "$SVBIN" status "$SVC_PATH" 2>/dev/null || { echo "[!] sv status failed (service disabled or supervisor down)"; return 1; }
}

tails_quick() {
  echo "[i] Logs (last lines if present):"
  tail -n 10 "$DEF_DIR/log/main/current" 2>/dev/null || true
  tail -n 10 "$LOG_ROOT/service.out.log" 2>/dev/null || true
  tail -n 10 "$LOG_ROOT/service.err.log" 2>/dev/null || true
  echo "[i] Script log tail:"; tail -n 10 "$SCRIPT_LOG" 2>/dev/null || true
}

doctor() {
  need_termux_services
  echo "[i] Environment:"
  printf "  PREFIX=%s\n  DEF_DIR=%s\n  VAR_DIR=%s\n  VAR_LINK=%s\n" "$PREFIX" "$DEF_DIR" "$VAR_DIR" "$VAR_LINK"
  env | grep -E '^(EXCALIBUR_|PORT=|PYTHONPATH=)' | sed 's/^/  /' || true
  check_definition || true
  echo "[i] var/service:"; ls -al "$VAR_DIR" 2>/dev/null || true; [ -L "$VAR_LINK" ] && ls -al "$VAR_LINK" || echo "[!] No symlink at $VAR_LINK"
  echo "[i] Supervisor:"; pgrep -fa runsvdir >/dev/null && pgrep -fa runsvdir || echo "[!] No runsvdir (run: $0 fix-supervisor)"
  echo "[i] sv status:"; sv_status || true
  echo "[i] Port check:"; ex_port_who || true
  echo "[i] Quick health probe:"; [ -n "${CURL:-}" ] && "$CURL" -fsS "http://127.0.0.1:${PORT:-8765}/health" 2>/dev/null | { [ -n "${JQ:-}" ] && "$JQ" . || cat; } || true
  tails_quick
}

robust_start() {
  need_termux_services
  kill_uvicorn
  check_definition || return 2
  ensure_symlink
  fix_supervisor || true

  if ex_port_in_use; then
    echo "[warn] Port ${PORT:-8765} appears busy."
    ex_port_who || true
    echo "       If this is a stuck uvicorn, consider: pkill -f 'uvicorn Pickleball:app'"
  fi

  log "Starting service"
  unset_svc_env
  if ! "$SVBIN" up "$SVC_PATH" 2>/dev/null; then
    echo "[!] sv up failed; trying restart"
    "$SVBIN" restart "$SVC_PATH" 2>/dev/null || true
  fi
  sleep 1
  sv_status || true

  if ex_probe_health_and_version; then
    ex_banner_alive
    printf "HEALTH:  %s\n" "${HEALTH_JSON:-{}}"
    printf "VERSION: %s\n" "${VERSION_JSON:-{}}"
    echo "[ok] Service started and healthy"
  else
    echo "[!] Health not ready; printing log tails"
    tails_quick
    return 1
  fi
}

restart_service() {
  need_termux_services
  fix_supervisor || true
  if ex_port_in_use; then echo "[warn] Port ${PORT:-8765} appears busy."; ex_port_who || true; fi

  log "Restarting service"
  unset_svc_env
  "$SVBIN" restart "$SVC_PATH" 2>/dev/null || "$SVBIN" up "$SVC_PATH" 2>/dev/null || true
  sleep 1
  sv_status || true

  if ex_probe_health_and_version; then
    ex_banner_alive
    printf "HEALTH:  %s\n" "${HEALTH_JSON:-{}}"
    printf "VERSION: %s\n" "${VERSION_JSON:-{}}"
    echo "[ok] Service restarted and healthy"
  else
    tails_quick
    return 1
  fi
}

cmd="${1:-doctor}"
case "$cmd" in
  doctor) doctor ;;
  start) robust_start ;;
  restart) restart_service ;;
  status) need_termux_services; sv_status || true ;;
  stop) need_termux_services; unset_svc_env; "$SVBIN" down "$SVC_PATH" 2>/dev/null || true; kill_uvicorn ;;
  disable) need_termux_services; unset_svc_env; "$SVBIN" disable "$SVC_PATH" 2>/dev/null || true; rm -rf "$VAR_LINK" 2>/dev/null || true ;;
  purge) kill_uvicorn; need_termux_services; unset_svc_env; "$SVBIN" down "$SVC_PATH" 2>/dev/null || true; "$SVBIN" disable "$SVC_PATH" 2>/dev/null || true; rm -rf "$VAR_LINK" "$DEF_DIR" 2>/dev/null || true; fix_supervisor || true ;;
  fix-supervisor) fix_supervisor ;;
  -h|--help|help) usage ;;
  *) usage; exit 1 ;;
esac

