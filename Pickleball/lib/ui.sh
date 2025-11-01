#!/data/data/com.termux/files/usr/bin/bash
# UI primitives and artwork for Pickleball (portable POSIX-friendly)

# Colors (fallback to no-color if not a TTY)
EC_RESET="\033[0m"
EC_GREEN="\033[1;32m"
if [ ! -t 1 ]; then EC_RESET=""; EC_GREEN=""; fi

ex_banner_alive() {
  printf "%b" "$EC_GREEN"
  cat <<'EOF'
┌──────────────────────────────────────────┐
│                                          │
│        ⚔️  Pickleball IS ALIVE ⚔️         │
│                                          │
│            🟢  Service Healthy           │
│                                          │
└──────────────────────────────────────────┘
EOF
  printf "%b" "$EC_RESET"
}
