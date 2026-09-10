#!/usr/bin/env bash
# WP-0b — the axiom-footprint audit, to be run ON THE BUILD VM after `lake build` succeeds.
# Self-contained: writes both audit files itself, so the VM needs nothing from our repo.
#
# Usage, from the project root (the directory containing lakefile and lean-toolchain):
#     bash openai-audit-vm.sh
# then upload the two transcripts and the import scan next to build.log in the bucket, e.g.:
#     gsutil cp audit-*.transcript.txt import-scan.txt \
#       gs://socrateai-datalake-gen-lang-client-0625573011/formal_verification/navierstokes_euler/
#
# ACCEPTANCE CRITERION (per LEDGER):
#   audit-main:         every footprint EXACTLY [propext, Classical.choice, Quot.sound]
#   audit-placeholders: every footprint CONTAINS sorryAx (the built-in negative control —
#                       if these come back clean, the tooling is broken)
#   import-scan:        NO file under NavierStokes/ or Euler/ imports ComparatorChallenges
#                       (seals finding F-NAME: the challenge discharge is meta-level)

set -euo pipefail

cat > audit-main.lean <<'EOF'
import NavierStokes.ComparatorR3Theorem
import NavierStokes.ComparatorTheorem
import Euler.Solution

#print axioms NavierStokes.ComparatorBridge.navier_stokes_breakdown_R3
#print axioms NavierStokes.ComparatorBridge.navier_stokes_breakdown_periodic
#print axioms Euler.euler_breakdown_R3
#print axioms Euler.exists_compact_smooth_euler_singularity
EOF

cat > audit-placeholders.lean <<'EOF'
import ComparatorChallenges.NavierStokes
import ComparatorChallenges.Euler

#print axioms NavierStokes.Comparator.navier_stokes_breakdown_R3
#print axioms NavierStokes.Comparator.navier_stokes_breakdown_periodic
#print axioms Euler.euler_breakdown_R3
#print axioms Euler.exists_compact_smooth_euler_singularity
EOF

echo "== audit-main (proof tree; expect clean footprints) =="
lake env lean audit-main.lean | tee audit-main.transcript.txt

echo
echo "== audit-placeholders (challenge modules; expect sorryAx everywhere) =="
lake env lean audit-placeholders.lean | tee audit-placeholders.transcript.txt

echo
echo "== import scan (expect NO hits: no proof module imports the challenges) =="
grep -rn "import ComparatorChallenges" NavierStokes Euler | tee import-scan.txt || true

echo
echo "Done. Upload audit-main.transcript.txt, audit-placeholders.transcript.txt,"
echo "and import-scan.txt to the bucket next to build.log."
