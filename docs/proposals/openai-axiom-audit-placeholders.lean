/-
WP-0b, part 2 — the CHALLENGE PLACEHOLDERS, audited separately.

This file must be run SEPARATELY from openai-axiom-audit.lean: the challenge modules
re-declare the same fully-qualified names as the proof tree (e.g. `Euler.euler_breakdown_R3`
exists sorried in ComparatorChallenges/Euler.lean AND proved in Euler/Solution.lean), so the
two module families cannot be imported together — which is itself audit finding F-NAME below.

EXPECTED RESULT: every print below contains `sorryAx`. This is the audit's built-in negative
control: the instrument must visibly distinguish the placeholders from the proofs. If any
print below comes back CLEAN, the audit tooling is broken and nothing else it says counts.

FINDING F-NAME (recorded here so the transcript carries it): because placeholder and proof
share fully-qualified names in never-co-importable modules, a KERNEL-LEVEL identification
"proved theorem ⟹ challenge statement" cannot even be stated for the Euler pair. The
discharge of the DeepMind-derived challenge statements is therefore META-level: a human must
compare the two statement sets side by side. The kernel certifies each side separately;
nothing certifies their equality of meaning.
-/

import ComparatorChallenges.NavierStokes
import ComparatorChallenges.Euler

-- The (C) and (D) challenge placeholders — expected footprint: sorryAx present
#print axioms NavierStokes.Comparator.navier_stokes_breakdown_R3
#print axioms NavierStokes.Comparator.navier_stokes_breakdown_periodic

-- The Euler challenge placeholders — expected footprint: sorryAx present
#print axioms Euler.euler_breakdown_R3
#print axioms Euler.exists_compact_smooth_euler_singularity
