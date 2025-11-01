#!/usr/bin/env bash
# Pickleball service doctor for Linux hosts (defaults to systemd)
set -euo pipefail

ROOT="$(dirname "$0")/.."
. "$ROOT/lib/ui.sh"
. "$ROOT/lib/common.sh"

SERVICE_NAME="Pickleball.service"

usage() {
  cat <<EOF
Usage: $(basename "$0") <doctor|start|restart|status|stop|logs>

This script assumes systemd by default.
Override SERVICE_NAME if your service unit has a different name.
EOF
}

doctor() {
  echo "[i] systemctl status:"
  systemctl status "$SERVICE_NAME" || true

  echo "[i] Port check:"
  ex_port_who

  echo "[i] Health probe:"
  if ex_probe_health_and_version 10 1; then
    ex_banner_alive
    echo "HEALTH:  $HEALTH_JSON"
    echo "VERSION: $VERSION_JSON"
  fi
}

case "${1:-doctor}" in
  doctor) doctor ;;
  start) sudo systemctl start "$SERVICE_NAME" ;;
  restart) sudo systemctl restart "$SERVICE_NAME" ;;
  status) systemctl status "$SERVICE_NAME" ;;
  stop) sudo systemctl stop "$SERVICE_NAME" ;;
  logs) journalctl -u "$SERVICE_NAME" -n 50 --no-pager ;;
  *) usage ;;
esac
