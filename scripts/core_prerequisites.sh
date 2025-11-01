#!/data/data/com.termux/files/usr/bin/bash
# Idempotent core prerequisites for Pickleball

set -euo pipefail

REPO="$HOME/Pickleball"

# --- choose a single RC file (most-recent if multiple; else ~/.bashrc) ---
pick_target_rc() {
  local c=("$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile" "$HOME/.bashrc")
  local e=()
  for f in "${c[@]}"; do [ -f "$f" ] && e+=("$f"); done
  if [ "${#e[@]}" -gt 0 ]; then
    printf '%s\n' "${e[@]}" | xargs -I{} stat -c '%Y:%n' {} 2>/dev/null \
      | sort -nr | head -n1 | cut -d: -f2-
  else
    echo "$HOME/.bashrc"
  fi
}

# --- ensure PATH lines exist in the chosen RC (idempotent) ---
rc_update_path() {
  local rc="$1"; local changed=0
  [ -f "$rc" ] || : > "$rc"

  local L1='[ -d "$HOME/Pickleball/bin" ] && case ":$PATH:" in *":$HOME/Pickleball/bin:"*) ;; *) PATH="$HOME/Pickleball/bin:$PATH";; esac'
  local L2='[ -d "$HOME/Pickleball/tools" ] && case ":$PATH:" in *":$HOME/Pickleball/tools:"*) ;; *) PATH="$HOME/Pickleball/tools:$PATH";; esac'
  local L3='export PATH'

  grep -Fqx "$L1" "$rc" 2>/dev/null || { printf '%s\n' "$L1" >> "$rc"; changed=1; }
  grep -Fqx "$L2" "$rc" 2>/dev/null || { printf '%s\n' "$L2" >> "$rc"; changed=1; }
  grep -Fqx "$L3" "$rc" 2>/dev/null || { printf '%s\n' "$L3" >> "$rc"; changed=1; }

  if [ "$changed" -eq 1 ]; then
    printf '[OK] updated PATH lines in %s\n' "$rc"
  else
    printf '[OK] PATH lines already present in %s\n' "$rc"
  fi
}

# --- runtime guard: add to current shell PATH without duplicates ---
path_add_runtime() {
  local d="$1"
  [ -d "$d" ] || return 0
  case ":$PATH:" in *":$d:"*) : ;; *) PATH="$d:$PATH";; esac
}

# --- minimal filesystem prereqs ---
RT="$HOME/var/Pickleball"; RUN="$RT/run"; LOG="$RT/logs"
mkdir -p "$REPO/bin" "$REPO/tools" "$REPO/scripts" "$REPO/docs" "$RUN" "$LOG"
[ -f "$RUN/live_queue.sh" ] || : > "$RUN/live_queue.sh"
[ -f "$RUN/live_offset_bytes" ] || printf '0' > "$RUN/live_offset_bytes"

# --- ensure key executables (if present) ---
for f in \
  "$REPO/bin/hotdrop_subscribe" \
  "$REPO/bin/live_runner" \
  "$REPO/bin/hotdrop_send" \
  "$REPO/bin/hotdrop_injector" \
  "$REPO/bin/hotping" \
  "$REPO/bin/diag" \
  "$REPO/bin/throughput_log"
do
  [ -f "$f" ] && chmod +x "$f" || true
done

# --- optional Termux nicety ---
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock || true

# --- update RC (one file) and live PATH (no duplicates) ---
RC_TARGET="$(pick_target_rc)"
rc_update_path "$RC_TARGET"
path_add_runtime "$HOME/Pickleball/bin"
path_add_runtime "$HOME/Pickleball/tools"
export PATH

# --- quick sanity if available ---
[ -x "$REPO/bin/preflight" ] && "$REPO/bin/preflight" || true

printf '[OK] core prerequisites complete (RC=%s, rt=%s)\n' "$RC_TARGET" "$RT"
