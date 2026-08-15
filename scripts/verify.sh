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
for h in tests/tier_b_exact_checks.py tests/tier_b_dyadic_checks.py tests/tier_b_enstrophy_production.py tests/tier_b_production_bound.py tests/test_percolation.py tests/tier_b_nse_triad_convolution.py tests/tier_b_grid_adequacy.py tests/tier_b_regime_adequacy.py tests/tier_b_ball_2section.py; do
  echo "-- $h"
  python3 "$h" >/tmp/gate1.$$ 2>&1 || { cat /tmp/gate1.$$; rm -f /tmp/gate1.$$; echo "TIER B GATE: FAIL ($h)"; exit 1; }
  tail -2 /tmp/gate1.$$; rm -f /tmp/gate1.$$
done
echo "TIER B GATE: PASS"

echo
echo "== Gate 1b: LEDGER consistency + single-active-file lint (SPEC §5.1 item 3) =="
python3 "$ROOT/scripts/ledger_check.py" || { echo "LEDGER GATE: FAIL"; exit 1; }

echo
echo "== Gate 2: Lean 4 kernel (Tier A) =="
# Gate 2 uses the SELF-CONTAINED Lake project in lean_src/ (Stage-0 cold build, 2026-08-13),
# with cross-file imports enabled (2026-08-13).
#
# Two things this buys, both learned the hard way:
#  1. No dependency on an external Mathlib checkout this repo does not control. That coupling
#     was not hypothetical: an unrelated `lake build` in the shared checkout rebuilt its .olean
#     files mid-run and failed Gate 2 on a file this repo had not touched.
#  2. Cross-file `import` resolves, so lean_src/ files no longer re-declare each other's
#     definitions verbatim. That duplication was a silent-drift hazard: a fix applied to one
#     copy and not the other left BOTH files compiling cleanly while the mathematics diverged,
#     and no gate could see it.
#
# Mechanism: `lake build` first (so every dependency olean is current), then re-elaborate each
# file with `lean` -- NOT `lake build` alone, because lake caches and a cached target emits no
# `#print axioms` output at all, which would make the footprint check silently vacuous.
# `lean` always re-elaborates, so the footprints are always actually re-checked.
if [ -d "$ROOT/lean_src/.lake/packages/mathlib/.lake/build/lib" ]; then
  echo "   (self-contained lean_src/.lake, cross-file imports enabled)"
  ( cd "$ROOT/lean_src" && lake build 2>&1 | tail -1 )
  LEAN_PATH_EXT="$(cd "$ROOT/lean_src" && lake env printenv LEAN_PATH):$ROOT/lean_src/.lake/build/lib/lean"
  LEAN_CMD_DIR="$ROOT/lean_src"
else
  echo "   ERROR: lean_src/.lake absent. Cross-file imports require the local build."
  echo "   Build it with: cd lean_src && lake exe cache get && lake build"
  exit 1
fi
FAILED=0
for f in CallensDualScale DyadicShells DyadicShell_Statements EnstrophyProduction EnstrophyProductionBound MillenniumReduction AbstractAlgebraicConservation TriadTorus; do
  echo "-- lean_src/$f.lean"
  OUT=$(cd "$LEAN_CMD_DIR" && LEAN_PATH="$LEAN_PATH_EXT" lean "$f.lean" 2>&1)
  if echo "$OUT" | grep -qiE "^.*error|sorry"; then
    echo "$OUT"; echo "TIER A GATE: FAIL ($f: errors or sorry)"; FAILED=1; continue
  fi
  # Footprint check: every axiom named must lie in the permitted set
  # {propext, Classical.choice, Quot.sound}.  A footprint that is a strict SUBSET of the
  # permitted set (e.g. a purely computational lemma reporting just [propext]) is MORE
  # constrained than required and must PASS -- the previous implementation string-matched
  # the exact three-axiom list and so rejected such theorems as if they were unsound
  # (a false positive, found 2026-08-13 by AbstractAlgebraicConservation.swap3_involutive).
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
echo "TIER A GATE: PASS (no axiom outside {propext, Classical.choice, Quot.sound}, zero sorry)"
