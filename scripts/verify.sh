#!/usr/bin/env bash
# Two-gate verification (spec v0.2 §5).
#  Gate 1 (Tier B): exact rational arithmetic harness — no floats.
#  Gate 2 (Tier A): Lean 4 kernel compile, zero sorry, and the #print axioms
#                   footprint must be exactly [propext, Classical.choice, Quot.sound].
#
# LEAN_ENV_DIR points at a Lake project with a built Mathlib matching
# lean_src/lean-toolchain.  Interim default: the shared local build below.
# A cold standalone build is: cd lean_src && lake exe cache get && lake build.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== Gate 1: Tier B exact-arithmetic harness =="
python3 tests/tier_b_exact_checks.py

echo
echo "== Gate 2: Lean 4 kernel (Tier A) =="
LEAN_ENV_DIR="${LEAN_ENV_DIR:-$HOME/xdev/SocrateAI-Scientific-RajMathRecovery/dualscale/lean}"
OUT=$(cd "$LEAN_ENV_DIR" && lake env lean "$OLDPWD/lean_src/CallensDualScale.lean" 2>&1)
echo "$OUT"
if echo "$OUT" | grep -qiE "error|sorry"; then
  echo "TIER A GATE: FAIL (errors or sorry present)"; exit 1
fi
BAD=$(echo "$OUT" | grep "depends on axioms" | grep -v "\[propext, Classical.choice, Quot.sound\]" || true)
if [ -n "$BAD" ]; then
  echo "TIER A GATE: FAIL (non-clean axiom footprint):"; echo "$BAD"; exit 1
fi
echo "TIER A GATE: PASS (clean 3-axiom footprint, zero sorry)"
