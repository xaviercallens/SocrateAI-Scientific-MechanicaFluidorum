/-
WP-0b — axiom audit of the OpenAI Navier–Stokes/Euler tree.

RUN FROM THEIR PROJECT ROOT, under THEIR toolchain, AFTER `lake build` succeeds:

  cd /home/xavkal/xdev/OpenAINavierStokesEuler/NavierStokesAndEuler && \
    lake env lean /home/xavkal/xdev/SocrateAI-Scientific-MechanicaFluidorum/docs/proposals/openai-axiom-audit.lean \
    | tee /home/xavkal/xdev/SocrateAI-Scientific-MechanicaFluidorum/docs/proposals/openai-axiom-audit.transcript.txt

ACCEPTANCE CRITERION (this repo's Tier A convention, applied to a foreign tree):
each footprint below must be exactly [propext, Classical.choice, Quot.sound].
Anything else — `sorryAx` above all, but also any custom axiom — fails the audit
for that theorem, and LEDGER may then cite only what passed.

Context: their `ComparatorTheorem.lean` says "No result here uses any of the
comparator's unproved statements", and their `ProblemStatement.lean` marks
`candidateStatement` as stated-not-proved. This file is how such self-reports
stop being self-reports.
-/

import NavierStokes.ComparatorR3Theorem
import NavierStokes.ComparatorTheorem
import Euler.Solution

-- Statement C (whole space, forced)
#print axioms NavierStokes.ComparatorBridge.navier_stokes_breakdown_R3

-- Statement D (torus, forced)
#print axioms NavierStokes.ComparatorBridge.navier_stokes_breakdown_periodic

-- Euler breakdown (constructed compact datum)
#print axioms Euler.euler_breakdown_R3

-- The detailed Euler singularity package
#print axioms Euler.exists_compact_smooth_euler_singularity
