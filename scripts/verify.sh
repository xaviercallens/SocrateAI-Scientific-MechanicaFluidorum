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
for h in tests/tier_b_exact_checks.py tests/tier_b_dyadic_checks.py tests/tier_b_enstrophy_production.py tests/tier_b_production_bound.py tests/test_percolation.py tests/tier_b_nse_triad_convolution.py; do
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
for f in CallensDualScale DyadicShells HypothesisU_Statements EnstrophyProduction EnstrophyProductionBound MillenniumReduction TriadConservation; do
  echo "-- lean_src/$f.lean"
  OUT=$(cd "$LEAN_ENV_DIR" && lake env lean "$ROOT/lean_src/$f.lean" 2>&1)
  if echo "$OUT" | grep -qiE "^.*error|sorry"; then
    echo "$OUT"; echo "TIER A GATE: FAIL ($f: errors or sorry)"; FAILED=1; continue
  fi
  # Footprint check: every axiom named must lie in the permitted set
  # {propext, Classical.choice, Quot.sound}.  A footprint that is a strict SUBSET of the
  # permitted set (e.g. a purely computational lemma reporting just [propext]) is MORE
  # constrained than required and must PASS -- the previous implementation string-matched
  # the exact three-axiom list and so rejected such theorems as if they were unsound
  # (a false positive, found 2026-08-13 by TriadConservation.swap3_involutive).
  # sorryAx, or any other axiom outside the permitted set, is still caught: the test is
  # membership, not equality.
  BAD=$(echo "$OUT" | grep "depends on axioms" | tr '\n' ' ' \
        | grep -o "'[^']*' depends on axioms: \[[^]]*\]" \
        | while IFS= read -r line; do
            axioms=$(echo "$line" | sed "s/.*depends on axioms: \[//; s/\]$//")
            offending=$(echo "$axioms" | tr ',' '\n' | sed 's/^ *//; s/ *$//' \
                        | grep -v -x -e 'propext' -e 'Classical.choice' -e 'Quot.sound' \
                        | grep -v -x '' || true)
            if [ -n "$offending" ]; then
              echo "$line  <-- offending: $(echo "$offending" | tr '\n' ' ')"
            fi
          done)
  if [ -n "$BAD" ]; then
    echo "TIER A GATE: FAIL ($f: non-clean axiom footprint):"; echo "$BAD"; FAILED=1; continue
  fi
  echo "$OUT" | grep -c "depends on axioms" | xargs -I{} echo "   {} theorems, all footprints clean"
done
[ "$FAILED" -eq 0 ] || exit 1
echo "TIER A GATE: PASS (clean 3-axiom footprints, zero sorry)"
