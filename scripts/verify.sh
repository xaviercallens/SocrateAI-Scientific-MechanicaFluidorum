#!/usr/bin/env bash
# Two-gate verification (spec v0.2 §5).
#  Gate 1 (Tier B): exact rational arithmetic harnesses — no floats.
#  Gate 2 (Tier A): Lean 4 kernel compile, zero sorry, and the #print axioms
#                   footprint must be exactly [propext, Classical.choice, Quot.sound].
#
# LEAN_ENV_DIR points at a Lake project with a built Mathlib matching
# lean_src/lean-toolchain.  Interim default: the shared local build below.
# A cold standalone build is: cd lean_src && lake exe cache get && lake build.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"

echo "== Gate 1: Tier B exact-arithmetic harnesses =="
for h in tests/tier_b_exact_checks.py tests/tier_b_dyadic_checks.py tests/tier_b_enstrophy_production.py tests/test_percolation.py; do
  echo "-- $h"
  python3 "$h" >/tmp/gate1.$$ 2>&1 || { cat /tmp/gate1.$$; rm -f /tmp/gate1.$$; echo "TIER B GATE: FAIL ($h)"; exit 1; }
  tail -2 /tmp/gate1.$$; rm -f /tmp/gate1.$$
done
echo "TIER B GATE: PASS"

echo
echo "== Gate 2: Lean 4 kernel (Tier A) =="
LEAN_ENV_DIR="${LEAN_ENV_DIR:-$HOME/xdev/SocrateAI-Scientific-RajMathRecovery/dualscale/lean}"
# HypothesisU_Statements.lean is a DRAFT awaiting human statement-adequacy audit
# (PLAN.md F2); it is gated for compilation so it cannot rot, but its claims are
# NOT ledgered until the audit passes.
FAILED=0
for f in CallensDualScale DyadicShells HypothesisU_Statements EnstrophyProduction; do
  echo "-- lean_src/$f.lean"
  OUT=$(cd "$LEAN_ENV_DIR" && lake env lean "$ROOT/lean_src/$f.lean" 2>&1)
  if echo "$OUT" | grep -qiE "^.*error|sorry"; then
    echo "$OUT"; echo "TIER A GATE: FAIL ($f: errors or sorry)"; FAILED=1; continue
  fi
  BAD=$(echo "$OUT" | grep "depends on axioms" | tr '\n' ' ' | grep -o "'[^']*' depends on axioms: \[[^]]*\]" | grep -v "propext, *Classical.choice, *Quot.sound\]" || true)
  if [ -n "$BAD" ]; then
    echo "TIER A GATE: FAIL ($f: non-clean axiom footprint):"; echo "$BAD"; FAILED=1; continue
  fi
  echo "$OUT" | grep -c "depends on axioms" | xargs -I{} echo "   {} theorems, all footprints clean"
done
[ "$FAILED" -eq 0 ] || exit 1
echo "TIER A GATE: PASS (clean 3-axiom footprints, zero sorry)"
