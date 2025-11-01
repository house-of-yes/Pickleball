#!/data/data/com.termux/files/usr/bin/bash
# BASH PATCH — force injection through FIFO (not queue append)
set -euo pipefail
cd "$HOME/HouseOfYes/Pickleball"

FIFO="var/run/hotdrop_in.fifo"
[ -p "$FIFO" ] || { echo "fifo missing"; exit 1; }

cat <<'HOT' > "$FIFO"
### HOTDROP-BEGIN docs/active_test.md
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
cd "$HOME/HouseOfYes/Pickleball"

mkdir -p docs
{
  echo "# Active Hotdrop Test"
  echo
  echo "Executed at:"
  date -Is
  echo
  echo "PWD: $(pwd)"
  echo "User: $(whoami)"
} > docs/active_test.md

echo "HOTDROP complete: docs/active_test.md"
### HOTDROP-END docs/active_test.md
HOT

