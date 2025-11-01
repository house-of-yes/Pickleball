#!/usr/bin/env bash
# Lint a bash patch/script for Pickleball protocol:
#  - First executable line must be an exigent cd (absolute or $HOME-anchored; never "cd .")
#  - Must contain a "CHANGE LOG" block *before* the first real command after the cd line
#  - Must NOT contain a bare literal "PATCH" line (rc=127 risk)
set -euo pipefail

cd "$HOME/Pickleball"

file="${1:-}"
if [[ -z "$file" || ! -f "$file" ]]; then
  echo "Usage: tools/pickleball_guard.sh <path-to-script-or-patch>" >&2
  exit 2
fi

fail() { echo "❌ $*"; exit 1; }
ok()   { echo "✅ $*"; }

# Extract first non-empty, non-comment line (the cd line we require)
first_exec_line="$(awk '
  /^[[:space:]]*#/ {next}
  /^[[:space:]]*$/ {next}
  {print; exit}
' "$file")"

[[ -n "$first_exec_line" ]] || fail "Empty script: no executable lines found."

# Ex Rule: first executable line must be cd with an exigent path
if [[ "$first_exec_line" =~ ^[[:space:]]*cd[[:space:]]+(.+)$ ]]; then
  cd_arg="${BASH_REMATCH[1]}"
  # Strip simple quotes for checks
  cd_arg_clean="$(printf '%s' "$cd_arg" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")"
  [[ "$cd_arg_clean" != "." ]] || fail "Ex Rule: 'cd .' is not exigent."
  if [[ "$cd_arg_clean" != "$HOME/"* && "$cd_arg_clean" != /* ]]; then
    fail "Ex Rule: cd must be absolute or \$HOME-anchored (got: $cd_arg_clean)."
  fi
else
  fail "Ex Rule: first executable line must be 'cd <path>' (got: $first_exec_line)."
fi
ok "Ex Rule satisfied: $first_exec_line"

# Verify a CHANGE LOG comment line appears before the first *real* command after cd
# We allow any number of comments/blank lines between cd and CHANGE LOG.
saw_cd=0
saw_change_log=0
while IFS= read -r line; do
  # Skip shebang
  [[ "$line" =~ ^#!/ ]] && continue

  # Identify the cd line (first executable)
  if [[ $saw_cd -eq 0 ]]; then
    # Skip leading comments/blank until first non-comment
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    saw_cd=1
    continue
  fi

  # After cd, collect comments/blank and require CHANGE LOG before first real command
  if [[ "$line" =~ ^[[:space:]]*# ]]; then
    [[ "$line" =~ CHANGE[[:space:]]+LOG ]] && saw_change_log=1
    continue
  fi
  [[ "$line" =~ ^[[:space:]]*$ ]] && continue

  # If we see a code fence before change log, that's also a fail (patch-style files)
  if [[ "$line" =~ ^\`\`\` ]]; then
    [[ $saw_change_log -eq 1 ]] || fail "CHANGE LOG must precede code fences."
  fi

  # First real command after cd:
  [[ $saw_change_log -eq 1 ]] || fail "CHANGE LOG must appear before the first command after cd."
  break
done < "$file"
ok "CHANGE LOG present before first command"

# Bare "PATCH" literal causes rc=127 if executed
if grep -qE '^[[:space:]]*PATCH[[:space:]]*$' "$file"; then
  fail "Literal 'PATCH' line detected — remove or comment it out (# PATCH)."
fi
ok "No rc=127 footguns detected"

echo "🎾 Guard PASS: $file"
