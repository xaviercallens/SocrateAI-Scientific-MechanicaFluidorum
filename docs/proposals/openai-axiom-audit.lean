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

/- ====================================================================
   OWNER'S THREE PROBES (adjudication Q5, 2026-09-10), in sharp form.

   PROBE 3, "sorry creep": already discharged by the four prints above —
   axiom footprints are TRANSITIVE, so a hidden `sorryAx` or custom axiom
   anywhere in the dependency tree of a headline theorem appears in its
   footprint. Clean prints above = no sorry creep, full stop.

   Discriminating signals: `sorryAx`, any custom axiom, `Lean.ofReduceBool`
   (native_decide). `Classical.choice` is NOT a red flag: this programme's
   own Tier A admits it, as does all of Mathlib's analysis.

   PROBE 1, "limit topology": the packet-scale sequences
   (Euler/PacketSourceScaleSequence.lean) are explicit exponential formulas,
   verified by direct read. What remains is whether the INFINITE packet
   limit's convergence is a theorem in the footprint-clean closure. The
   prints below put the initial-datum construction itself under the lamp;
   if the names differ in their tree, correct them from Solution.lean's
   imports (EulerPacketInduction / InitialDataBridge namespaces).      -/

-- PROBE 1 targets — adjust namespaces if elaboration fails:
-- #print axioms Euler.initialDatum
-- #print axioms EulerPacketInduction.initialDatum_finite_lifespan

/- PROBE 2, "vacuity of the forcing": their theorems conclude
   ¬ ∃ v p, NavierStokesExistenceAndSmoothness… If that predicate were
   self-contradictory, the negation would be VACUOUSLY true and the
   theorems empty. Sharp test: the predicate must be SATISFIABLE in the
   trivial positive case — zero force, zero datum, zero solution. Attempt:

     example (ν : ℝ) (hν : 0 < ν) :
         ∃ v p, Comparator.NavierStokesExistenceAndSmoothnessPeriodic
           ν (fun _ => 0) (fun _ _ => 0) v p := by
       refine ⟨fun _ => 0, fun _ => 0, ?_⟩
       ...

   If the zero solution cannot be made to satisfy their predicate, read
   the predicate's definition and determine WHY before any citation: a
   failure here is either an audit finding (mis-stated predicate) or a
   hypothesis of the predicate the zero field genuinely violates (e.g. a
   normalisation) — which must then be named in the audit report.       -/
