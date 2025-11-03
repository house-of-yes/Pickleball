#!/usr/bin/env bash
# Constitution checks for Pickleball repo (Green Stream mode, aggregated rule check)
set -uo pipefail
pass=0; fail=0

ok(){ echo "✅ $1"; ((pass++)) || true; }
bad(){ echo "❌ $1"; ((fail++)) || true; }

# 1) Root structure
[ -d context ] && ok "context/ present" || bad "context/ missing"

# 2) Quartet presence
for f in RIOT.act DYADS.yaml PHOENIX.ops MEMORY.state; do
  [ -f "context/$f" ] && ok "context/$f present" || bad "context/$f missing"
done

# 3) Constitutional rules (aggregate check without calling out numbers)
if [ -f context/RIOT.act ]; then
  need_all=true
  grep -q '<<RULE M-1:' context/RIOT.act || need_all=false
  grep -q '<<RULE P-7:' context/RIOT.act || need_all=false
  grep -q '<<RULE P-8:' context/RIOT.act || need_all=false
  grep -q '<<CLARIFICATION — P-8:' context/RIOT.act || need_all=false

  if $need_all; then
    ok "constitutional rules present"
  else
    bad "constitutional rules incomplete (expect: law, patch-safety, sequential-discipline, sequential-clarification)"
  fi
else
  bad "RIOT.act not found"
fi

# 4) Phoenix validator present
if [ -f context/PHOENIX.ops ]; then
  grep -q 'VALIDATION ROUTINE — Exigent Context Check' context/PHOENIX.ops \
    && ok "Phoenix validator present" || bad "Phoenix validator missing"
else
  bad "PHOENIX.ops not found"
fi

# 5) Root docs
[ -f README.md ] && ok "README.md present" || bad "README.md missing"
[ -f LICENSE ]   && ok "LICENSE present"   || bad "LICENSE missing"
[ -f NOTICE ]    && ok "NOTICE present"    || bad "NOTICE missing"

# 6) Authorship strings
if [ -f README.md ]; then
  grep -q 'HOY POLLOI 1.0 (Anima & Clem)' README.md && ok "README authorship ok" || bad "README authorship missing"
fi
if [ -f NOTICE ]; then
  grep -q 'HOY POLLOI 1.0 (Anima & Clem)' NOTICE && ok "NOTICE authorship ok" || bad "NOTICE authorship missing"
fi

# Exit: full pass prints only green lines; any ❌ leads to nonzero exit.
[ "$fail" -eq 0 ]
