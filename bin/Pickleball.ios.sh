#!/usr/bin/env sh
# Lean iOS adapter. Uses launchctl if present; else runs foreground.
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
[ -f "$ROOT/lib/ui.sh" ] && . "$ROOT/lib/ui.sh" || ex_banner_alive(){ printf "Pickleball IS ALIVE\n"; }
[ -f "$ROOT/lib/common.sh" ] && . "$ROOT/lib/common.sh" || {
  CURL="$(command -v curl || true)"; JQ="$(command -v jq || true)"
  ex_probe_health_and_version(){ HEALTH_JSON="$([ -n "$CURL" ] && "$CURL" -fsS "http://127.0.0.1:${PORT:-8765}/health" || echo '{}')"; VERSION_JSON="{}"; }
  ex_port_who(){ :; }
}

PLIST="${PLIST:-com.Pickleball.daemon.plist}"
PORT="${PORT:-8765}"
RUN_CMD="${RUN_CMD:-uvicorn Pickleball:app --host 127.0.0.1 --port $PORT --no-access-log}"

is_launchctl(){ command -v launchctl >/dev/null 2>&1; }
usage(){ echo "Usage: $(basename "$0") {doctor|start|restart|status|stop|logs|fg}"; }

doctor(){
  if is_launchctl; then launchctl list | grep -i Pickleball || true; fi
  echo "[i] Port check:"; ex_port_who || true
  if ex_probe_health_and_version 2>/dev/null; then ex_banner_alive; printf "HEALTH: %s\n" "$HEALTH_JSON"; fi
}

start(){
  if is_launchctl; then
    AGENT="$HOME/Library/LaunchAgents/$PLIST"
    [ -f "$AGENT" ] || { echo "[err] Missing $AGENT"; exit 1; }
    launchctl load "$AGENT" || true; sleep 1; doctor
  else
    exec sh -c "$RUN_CMD"
  fi
}

restart(){
  if is_launchctl; then
    AGENT="$HOME/Library/LaunchAgents/$PLIST"
    [ -f "$AGENT" ] || { echo "[err] Missing $AGENT"; exit 1; }
    launchctl unload "$AGENT" || true; sleep 0.5; launchctl load "$AGENT" || true; sleep 1; doctor
  else
    pkill -f "$RUN_CMD" 2>/dev/null || true
    exec sh -c "$RUN_CMD"
  fi
}

status(){ is_launchctl && launchctl list | grep -i Pickleball || echo "[i] no launchctl; use fg"; }
stop(){ is_launchctl && launchctl unload "$HOME/Library/LaunchAgents/$PLIST" || pkill -f "$RUN_CMD" 2>/dev/null || true; }
logs(){ is_launchctl && log show --predicate 'process == "uvicorn"' --style compact --last 1h 2>/dev/null || echo "[i] foreground logs show here"; }
fg(){ exec sh -c "$RUN_CMD"; }

case "${1:-doctor}" in
  doctor) doctor ;;
  start) start ;;
  restart) restart ;;
  status) status ;;
  stop) stop ;;
  logs) logs ;;
  fg) fg ;;
  *) usage; exit 1 ;;
esac
