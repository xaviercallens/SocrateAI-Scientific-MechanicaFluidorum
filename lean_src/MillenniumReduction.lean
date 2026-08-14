/-
  MillenniumReduction.lean — TIER C (DRAFT), demoted 2026-08-13 by external audit
  ================================================================================
  DEMOTION NOTICE (docs/Memo 1.md §2; verdicts in LEDGER.md). The external audit's B1 verdict:
  `AubinLionsStatement` and `ProdiSerrinStatement` as bare `Prop → Prop` arrows "completely
  bypass PDE theory. The Lean kernel is merely verifying a logical tautology (A → B → C)."
  Accepted. This file remains kernel-compiled and gated (so it cannot rot) but its claims are
  TIER C until repaired per Memo 1 Task 4 (real sequence-space topology, PLAN.md §10).

  Audit round 2 changes already applied (B2 REVISE, Memo 1 Task 3): the existential is HOISTED
  — `HasGlobalBoundedLimit` fixes ONE limit trajectory `ulim` across ALL horizons `T`, instead
  of permitting a different limit per horizon. The Cantor diagonalisation that produces such a
  single trajectory is now exactly where it belongs: inside `AubinLionsStatement`'s TYPE, as
  part of the undischarged analytic content, rather than silently absent.

  Original header follows.
  ================================================================================
  (was) MillenniumReduction.lean — conditional Millennium Reduction skeleton (PLAN.md §4, F3)
  ================================================================================================
  Formalizes `docs/designs/F3_MILLENNIUM_REDUCTION_SKELETON.md`. Encodes the LOGICAL SHAPE of
  Proposition 5.1 (SPEC.md §1.1, `docs/HYPOTHESIS_U_SPECIFICATION.md` §II): "Hypothesis U ⇒
  global regularity", via named `Prop`-valued hypothesis parameters for the two undischarged
  analytic steps (Aubin–Lions compactness, Prodi–Serrin regularity criterion) — never axioms,
  per `docs/REVIEW-2026-08-12.md` finding L7. This file proves NO analytic content about
  Navier–Stokes: it proves that the implication chain type-checks given those two steps as
  hypotheses, nothing more. The mathematical content of the reduction remains exactly where
  SPEC.md says it lives: inside Aubin–Lions compactness and the Prodi–Serrin criterion.

  ---------------------------------------------------------------------------
  BUILD NOTE — SUPERSEDED 2026-08-13: this file now IMPORTS instead of re-declaring.
  ---------------------------------------------------------------------------
  Historically `lean_src` was not a Lake project, so Gate 2 compiled each file standalone and
  cross-file `import` failed (`unknown module prefix`); every file therefore re-declared the
  vocabulary it needed, VERBATIM, and those copies had to be kept in sync BY HAND.

  That is fixed. `lean_src` is a Lake project (Stage-0 cold build), and `scripts/verify.sh`
  now runs `lake build` first and then checks each file with `LEAN_PATH` extended to include
  the project's own `.lake/build/lib/lean`. Cross-file imports resolve, so this file imports
  `DyadicShell_Statements` and the duplication is GONE — with it the silent-drift hazard where
  a fix applied to one copy and not the other leaves both files compiling cleanly while the
  mathematics diverges.

  ---------------------------------------------------------------------------
  REVISION 2026-08-12 (audit round 1 — human owner's decisions, recorded here per the F2 Q1/Q2
  precedent): the first version of this file was reviewed by its own author against SPEC.md's
  actual Proposition 5.1 text and three adequacy gaps were found and accepted for repair:
  ---------------------------------------------------------------------------
  Q3 (was: `GlobalRegularityStatement` only required each mode `HasDerivAt` in time — no
      constraint across modes at a fixed time, so it captured "no finite-time amplitude
      blow-up" but NOT spatial smoothness). DECISION: extend. New `IsSpatiallySmooth` requires
      the untruncated solution to lie in the Fourier-side Sobolev class `H^s` — i.e. every
      finite partial sum of `k_n^{2s} u(t,n)^2` stays bounded — for EVERY `s : ℕ`, at every
      `t ≥ 0`. This is the standard textbook characterization of `C^∞` on a torus (Fourier
      coefficients decaying faster than every polynomial ⟺ membership in every `H^s`), not
      invented content. Requires a genuine wavenumber `k : ℕ → ℝ` as a new parameter, related
      to the existing enstrophy weight `w` by `w n = (k n)²` (`hwk`) — this is literally what
      `HypothesisU_Statements.lean`'s own docstring already asserts informally ("w : the mode
      weight (morally k n ^ 2)"); this file only makes that relation an explicit hypothesis.
  Q4 (was: `millennium_reduction` took a single fixed `T`, yet its conclusion was `T`-
      independent — silently smuggling SPEC.md's "for all T" into `ProdiSerrinStatement`'s
      undischarged content without saying so). DECISION: quantify explicitly. `hU` is now
      `∀ T, HypothesisU nu T B w u0`; `AubinLionsStatement`/`ProdiSerrinStatement` correspondingly
      traffic in `∀ T, HasBoundedFullLimit …` rather than a single-`T` instance. Matches
      SPEC.md §1.1 ("Hypothesis U holds for … all T") in the theorem's own hypothesis list,
      not buried inside a hypothesis parameter's type.
  Q5 (was: `HasGlobalBoundedLimit` bounded finite partial sums of `w n * u(t,n)²` without
      requiring `w ≥ 0`, unlike `HypothesisU_Statements.lean`'s own `enstrophy_nonneg`, which
      requires it explicitly — for signed `w`, "partial sums bounded" does not mean "enstrophy
      controlled"). DECISION: add `hw : ∀ n, 0 ≤ w n` as an explicit parameter of
      `HasGlobalBoundedLimit`, threaded through `AubinLionsStatement`/`ProdiSerrinStatement`/
      `millennium_reduction`.

  Scope (declared, matches `HypothesisU_Statements.lean`'s own exclusions): no real Fourier
  analysis on 𝕋³ (the wavenumber `k` is an abstract parameter, not literally the torus dual
  group), no ODE existence/uniqueness theory, no `tsum`/summability (finite partial sums only,
  for every cutoff — the honest no-new-import avatar of a possibly-infinite sum, valid here
  because every summand `k_n^{2s} u(t,n)^2` is nonnegative regardless of `k`'s sign, since the
  exponent `2s` is even — bounded finite partial sums of nonnegative terms is exactly
  equivalent to the (possibly-infinite) series converging with sum `≤ C`).

  Gate: `#print axioms` for every theorem below must report exactly
  [propext, Classical.choice, Quot.sound].
-/
import DyadicShell_Statements
import Mathlib.Topology.Algebra.InfiniteSum.Order
import Mathlib.Topology.Algebra.InfiniteSum.NatInt
import Mathlib.Analysis.PSeries

namespace MechanicaFluidorum.MillenniumReduction

/-! ## 1. Vocabulary — IMPORTED from `DyadicShell_Statements`, no longer re-declared

`truncate`, `IsGalerkinSolution`, `enstrophy`, `HypothesisU`, `dyadicWavenumber`,
`dyadicWeight`, `shellB` and its energy-conservation theorems all come from
`lean_src/DyadicShell_Statements.lean` via the import above. There is exactly one definition of
each in the repository. -/

open MechanicaFluidorum

/-! ## 2. New: the untruncated (`N → ∞`) solution family -/

/-- `IsFullSolution nu B w u0 u`: `u` solves the SAME evolution law as `IsGalerkinSolution`,
but with NO cutoff — every mode is retained (no clause analogous to `IsGalerkinSolution`'s
clause (3)), the initial datum is `u0` directly (nothing to project: there is no discarded
mode to truncate away), and the evolution clause is required at every `t ≥ 0`, unbounded. A
solution failing to exist past some finite `t*` is exactly the failure of `HasDerivAt` at `t*`;
requiring it for all `t ≥ 0` is the honest ODE-theoretic content of "no finite-time blow-up" —
the TIME-regularity half of "globally smooth" (SPEC.md §1.1); the SPACE half is
`IsSpatiallySmooth` below (Q3). -/
def IsFullSolution (nu : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ) (u0 : ℕ → ℝ)
    (u : ℝ → ℕ → ℝ) : Prop :=
  u 0 = u0
  ∧ ∀ t : ℝ, 0 ≤ t → ∀ n : ℕ,
      HasDerivAt (fun s : ℝ => u s n) (B n (u t) - nu * w n * u t n) t

/-- The zero flow solves the untruncated system with zero data, provided the interaction term
vanishes at the zero state — the untruncated analogue of
`HypothesisU_Statements.zero_isGalerkinSolution`, and this file's non-vacuity witness that
`IsFullSolution` is an inhabited (satisfiable) constraint, not an empty type. -/
theorem zero_isFullSolution (nu : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ)
    (hB : ∀ n : ℕ, B n (fun _ => (0 : ℝ)) = 0) :
    IsFullSolution nu B w (fun _ => (0 : ℝ)) (fun _ _ => (0 : ℝ)) := by
  refine ⟨rfl, ?_⟩
  intro t _ n
  have h : B n (fun _ => (0 : ℝ)) - nu * w n * 0 = 0 := by rw [hB n]; ring
  rw [h]
  exact hasDerivAt_const t (0 : ℝ)

/-! ## 3. Spatial regularity (Q3): the Fourier-side `H^s`-for-every-`s` characterization of `C^∞`

`k : ℕ → ℝ` is the genuine wavenumber (as opposed to `w`, the enstrophy WEIGHT — related by
`w n = (k n)²`, matching `HypothesisU_Statements.lean`'s own docstring). `sobolevWeight k s n :=
(k n) ^ (2*s)` generalizes the enstrophy weight (the `s = 1` case: `sobolevWeight k 1 n = (k n)^2
= w n` under `hwk`) to an arbitrary finite regularity order. On a torus, `u ∈ C^∞` iff its
Fourier coefficients decay faster than every polynomial iff `u ∈ H^s` for every `s ∈ ℕ` — this
is textbook Fourier analysis (Katznelson; standard on 𝕋^d), not new content. -/

/-- The Sobolev-level-`s` weight at mode `n`: `k_n^{2s}`. Automatically nonnegative for ANY
`k` (not just nonnegative `k`) because the exponent `2*s` is even — no side condition on `k`'s
sign is needed for this file's purposes, only the relation to `w` (`hwk`, used at the call
site, not here). -/
def sobolevWeight (k : ℕ → ℝ) (s n : ℕ) : ℝ := (k n) ^ (2 * s)

theorem sobolevWeight_nonneg (k : ℕ → ℝ) (s n : ℕ) : 0 ≤ sobolevWeight k s n := by
  unfold sobolevWeight
  rw [mul_comm, pow_mul]
  positivity

/-- `u` is spatially smooth at time `t`: for EVERY finite Sobolev order `s`, every finite
partial sum of `k_n^{2s} u(t,n)²` stays bounded by some (possibly `s`-dependent) `C`. Requiring
this for every `s`, not just `s = 1` (which is all `HasGlobalBoundedLimit` below tracks), is what
distinguishes genuine spatial smoothness from a bare `H¹` bound — the promotion from one to the
other is exactly the content SPEC.md §II Step 3 (Prodi–Serrin) is responsible for, parked in
`ProdiSerrinStatement`'s type, not proved here. -/
def IsSpatiallySmooth (k : ℕ → ℝ) (u : ℝ → ℕ → ℝ) (t : ℝ) : Prop :=
  ∀ s : ℕ, ∃ C : ℝ, ∀ M : ℕ, ∑ n ∈ Finset.range (M + 1), sobolevWeight k s n * (u t n) ^ 2 ≤ C

/-- The zero flow is spatially smooth at every time, for any wavenumber `k` — needed for the
non-vacuity witness `zero_global_regularity` below. -/
theorem zero_isSpatiallySmooth (k : ℕ → ℝ) (t : ℝ) :
    IsSpatiallySmooth k (fun _ _ => (0 : ℝ)) t := by
  intro s
  refine ⟨1, fun M => ?_⟩
  have : ∀ n ∈ Finset.range (M + 1), sobolevWeight k s n * ((0:ℝ)) ^ 2 = 0 :=
    fun n _ => by ring
  rw [Finset.sum_congr rfl this, Finset.sum_const_zero]
  exact zero_le_one

/-! ## 3b. Concrete objects — imported

`dyadicWavenumber`, `dyadicWeight`, `shellB` and `shellB_zero` now come from
`DyadicShell_Statements`. Audit verdicts **A5** (`B` must carry structure) and **B4** (specialise
to the concrete object) are met against the *canonical* definitions rather than against copies
of them. -/

theorem dyadicWeight_nonneg : ∀ n, 0 ≤ dyadicWeight n :=
  fun n => (dyadicWeight_pos n).le

/-! ## 3c. The ℓ² upgrade (decision D1: ADD + BRIDGE, localised)

**Where the upgrade is needed, and where it is not.** `HypothesisU` quantifies over *Galerkin*
solutions, whose clause (iii) forces `u t n = 0` for `n > N`. So `enstrophy N w u t`, a sum over
`range (N+1)`, already captures **every nonzero mode**: the finite sum there is exact, not an
approximation, and rewriting it as a `tsum` would change nothing mathematically while disturbing
the convention `EnstrophyProduction.lean` shares. The genuine `tsum` objects are the ones with
**no cutoff**: the untruncated limit and its Sobolev regularity. The upgrade is therefore
localised to those, per decision D1.

Design memo: `docs/designs/TASK4_ELL2_REPAIR.md`; the bridge below is the compiled snippet
`docs/designs/snippets/task4_bridge.lean`. -/

/-- Finite enstrophy for an untruncated state: the weighted square-sum is summable. This is the
shell-model analogue of `H¹`, and is a genuine ℓ²-type condition rather than a partial-sum
bound — there is no cutoff to make the sum finite. -/
def HasFiniteEnstrophy (w : ℕ → ℝ) (u : ℝ → ℕ → ℝ) (t : ℝ) : Prop :=
  Summable (fun n => w n * (u t n) ^ 2)

/-- Enstrophy of an untruncated state as an infinite series. -/
noncomputable def enstrophyTsum (w : ℕ → ℝ) (u : ℝ → ℕ → ℝ) (t : ℝ) : ℝ :=
  ∑' n, w n * (u t n) ^ 2

/-- **The bridge (D1).** For a nonnegative weight, the finite-partial-sum bound used throughout
the earlier formulation yields summability together with the corresponding `tsum` bound. This is
what makes the ℓ² upgrade a *conservative extension*: every statement previously proven in the
partial-sum form still holds, and nothing already verified is invalidated. -/
theorem hasFiniteEnstrophy_of_bounded (w : ℕ → ℝ) (hw : ∀ n, 0 ≤ w n)
    (u : ℝ → ℕ → ℝ) (t : ℝ) (C : ℝ) (hbd : ∀ M : ℕ, enstrophy M w u t ≤ C) :
    HasFiniteEnstrophy w u t ∧ enstrophyTsum w u t ≤ C := by
  have hf : ∀ n, 0 ≤ w n * (u t n) ^ 2 := fun n => mul_nonneg (hw n) (sq_nonneg _)
  have hall : ∀ M : ℕ, ∑ n ∈ Finset.range M, w n * (u t n) ^ 2 ≤ C := by
    intro M
    cases M with
    | zero => simpa using le_trans (Finset.sum_nonneg (fun i _ => hf i)) (hbd 0)
    | succ m => exact hbd m
  have hs : Summable (fun n => w n * (u t n) ^ 2) := summable_of_sum_range_le hf hall
  exact ⟨hs, hs.tsum_le_of_sum_range_le hall⟩

/-! ## 4. The two undischarged analytic steps — now with content (audit verdict B1)

Verdict B1 (NO): bare `Prop → Prop` arrows "completely bypass PDE theory. The Lean kernel is
merely verifying a logical tautology." Accepted. The repair is **not** to prove these steps —
parking undischarged analysis in a named hypothesis parameter rather than an `axiom` is the
pattern `docs/REVIEW-2026-08-12.md` L7 prescribes, and it stays. The repair is to give the
types real analytic content, so that a supplier of `hAL` must actually produce the object a
compactness argument produces, instead of any function whatsoever between two `Prop`s. -/

/-- **What a compactness argument actually delivers** (audit B1 + decision D3). `ulim` is the
limit of the Galerkin family, and the four clauses are all load-bearing:

1. it solves the untruncated system;
2. it has **finite enstrophy** at every time (an ℓ² statement, D1);
3. that enstrophy is **bounded on every horizon**, with `∃C` *inside* `∀T` — the honest form,
   since compactness gives no uniformity in `T`;
4. **(decision D3)** it is genuinely the limit of the family, modewise, along a
   **subsequence** `φ`. Clause 4 is what makes this Aubin–Lions rather than the far weaker
   assertion that *some* bounded solution exists. The subsequence is not a technicality: a
   compactness argument extracts one, and claiming convergence of the full sequence would
   overstate what the analysis gives. -/
def IsGalerkinLimit (nu : ℝ) (u0 : ℕ → ℝ)
    (galerkin : ℕ → ℝ → ℕ → ℝ) (ulim : ℝ → ℕ → ℝ) : Prop :=
  IsFullSolution nu (shellB dyadicWavenumber) dyadicWeight u0 ulim
  ∧ (∀ t : ℝ, 0 ≤ t → HasFiniteEnstrophy dyadicWeight ulim t)
  ∧ (∀ T : ℝ, ∃ C : ℝ, 0 < C ∧
      ∀ t : ℝ, 0 ≤ t → t ≤ T → enstrophyTsum dyadicWeight ulim t ≤ C)
  ∧ (∃ φ : ℕ → ℕ, StrictMono φ ∧
      ∀ n : ℕ, ∀ t : ℝ, 0 ≤ t →
        Filter.Tendsto (fun j => galerkin (φ j) t n) Filter.atTop (nhds (ulim t n)))

/-- **Aubin–Lions compactness for the dyadic shell model**, as a hypothesis parameter with
genuine content. A supplier must, from a uniformly-enstrophy-bounded family of Galerkin
solutions, produce a limit satisfying all four clauses of `IsGalerkinLimit`. Specialised to
`shellB`/`dyadicWeight` throughout, closing audit verdict B4. NOT proved here. -/
def AubinLionsStatement (nu : ℝ) (u0 : ℕ → ℝ) : Prop :=
  ∀ galerkin : ℕ → ℝ → ℕ → ℝ,
    (∀ N : ℕ, IsGalerkinSolution N nu (shellB dyadicWavenumber) dyadicWeight u0 (galerkin N)) →
    (∀ T : ℝ, ∃ C : ℝ, 0 < C ∧
        ∀ N : ℕ, ∀ t : ℝ, 0 ≤ t → t ≤ T →
          enstrophy N dyadicWeight (galerkin N) t ≤ C) →
    ∃ ulim : ℝ → ℕ → ℝ, IsGalerkinLimit nu u0 galerkin ulim

/-- Global regularity of the untruncated dyadic shell system: a solution that is global in time
and spatially smooth (in every Sobolev class) at every time. -/
def GlobalRegularityStatement (nu : ℝ) (u0 : ℕ → ℝ) : Prop :=
  ∃ u : ℝ → ℕ → ℝ,
    IsFullSolution nu (shellB dyadicWavenumber) dyadicWeight u0 u
    ∧ ∀ t : ℝ, 0 ≤ t → IsSpatiallySmooth dyadicWavenumber u t

/-- **The regularity criterion**, as a hypothesis parameter: a bounded-enstrophy limit of the
Galerkin family is globally regular.

**Naming note (decision D2, 2026-08-13):** the owner elected to rename only the main theorem,
keeping `ProdiSerrinStatement` as a marker of the criterion's intellectual lineage. That
lineage is a *motivation*, not a claim: in the shell setting this is an ODE continuation
criterion, materially weaker than the Prodi–Serrin theorem for 3-D Navier–Stokes, and it must
not be cited as the latter. -/
def ProdiSerrinStatement (nu : ℝ) (u0 : ℕ → ℝ) : Prop :=
  ∀ (galerkin : ℕ → ℝ → ℕ → ℝ) (ulim : ℝ → ℕ → ℝ),
    IsGalerkinLimit nu u0 galerkin ulim → GlobalRegularityStatement nu u0

/-! ## 5. The reduction itself

Still a composition — correctly so; the analytic weight lives in the hypotheses' TYPES, which
is exactly what verdict B1 said was missing and what §4 now supplies. What has changed is that
the composed types now say something: `hAL` cannot be satisfied without exhibiting a genuine
Galerkin limit, and `hPS` cannot be applied without one in hand.

**Renamed (decision D2)** from `millennium_reduction`: that name asserted a 3-D pedigree the
statement does not have, which is precisely the imprecision audit verdict D1 killed. -/

/-- **Conditional regularity reduction for the truncated viscous Katz–Pavlović shell model.**
Given a family of Galerkin solutions whose enstrophy is bounded uniformly in the cutoff on every
horizon, plus the compactness and continuation steps as hypothesis parameters, the untruncated
shell system has a globally regular solution.

**This proves no analytic content.** `hAL` and `hPS` carry it, and both remain undischarged;
the file is Tier C until one of them is proven. What is certified is that the chain composes
with the concrete `shellB` dynamics and with statements that have real content. -/
theorem dyadicShell_regularity_reduction (nu : ℝ) (u0 : ℕ → ℝ)
    (galerkin : ℕ → ℝ → ℕ → ℝ)
    (hgal : ∀ N : ℕ,
      IsGalerkinSolution N nu (shellB dyadicWavenumber) dyadicWeight u0 (galerkin N))
    (hU : ∀ T : ℝ, ∃ C : ℝ, 0 < C ∧
      ∀ N : ℕ, ∀ t : ℝ, 0 ≤ t → t ≤ T → enstrophy N dyadicWeight (galerkin N) t ≤ C)
    (hAL : AubinLionsStatement nu u0)
    (hPS : ProdiSerrinStatement nu u0) :
    GlobalRegularityStatement nu u0 :=
  let ⟨ulim, hlim⟩ := hAL galerkin hgal hU
  hPS galerkin ulim hlim

/-! ## 6. Non-vacuity (SPEC §7.5), scoped to what this file can honestly discharge

Proving the hypothesis parameters ACHIEVABLE would require ODE existence theory this file
excludes. What is proved is that the new definitions are genuinely satisfiable — in particular
that `IsGalerkinLimit`, with all four clauses including the subsequence, is inhabited. -/

/-- **`IsGalerkinLimit` is inhabited**, with the zero family and the identity subsequence — so
the four-clause conclusion of `AubinLionsStatement` is not vacuously unsatisfiable. -/
theorem zero_isGalerkinLimit (nu : ℝ) :
    IsGalerkinLimit nu (fun _ => (0 : ℝ)) (fun _ _ _ => (0 : ℝ)) (fun _ _ => (0 : ℝ)) := by
  refine ⟨zero_isFullSolution nu _ _ (shellB_zero dyadicWavenumber), ?_, ?_, ⟨id, strictMono_id, ?_⟩⟩
  · intro t _
    simpa [HasFiniteEnstrophy] using (summable_zero (f := fun _ : ℕ => (0:ℝ)))
  · intro T
    exact ⟨1, one_pos, fun t _ _ => by simp [enstrophyTsum]⟩
  · intro n t _
    simpa using tendsto_const_nhds

/-- `GlobalRegularityStatement` is satisfiable: the zero flow. -/
theorem zero_global_regularity (nu : ℝ) :
    GlobalRegularityStatement nu (fun _ => (0 : ℝ)) :=
  ⟨_, zero_isFullSolution nu _ _ (shellB_zero dyadicWavenumber),
    fun t _ => zero_isSpatiallySmooth dyadicWavenumber t⟩

/-! ## 7. Axiom-footprint gate (SPEC §5.1 / PLAN.md §2)

Every theorem below must report exactly `[propext, Classical.choice, Quot.sound]`.

**Negative controls (hand-derived, actually run against scratch perturbed copies 2026-08-12; see
`docs/designs/F3_MILLENNIUM_REDUCTION_SKELETON.md` for the full table with confirmed outcomes):**
NC1 — inlining `AubinLionsStatement`'s conclusion with the `0 ≤ t →` guard dropped (instead of
using the shared `HasGlobalBoundedLimit` name) breaks the type-identity `hPS (hAL hU)` relies on.
NC2 — replacing the proof body with `hAL hU` alone (dropping `hPS`) is a type error: expected
`GlobalRegularityStatement …`, got `∀ T, HasBoundedFullLimit …`. NC3 — deleting `hB` from
`zero_isFullSolution`'s signature: `unknown identifier hB`, cascading into every non-vacuity
call site. NC4 (new, Q3) — dropping the `∀ s :` quantifier from `IsSpatiallySmooth` (fixing
`s := 1`) would make `GlobalRegularityStatement` provable directly from `HasGlobalBoundedLimit`
alone (no genuine promotion needed), collapsing `ProdiSerrinStatement` into something with far
less content than Prodi–Serrin's actual bootstrap — this is a statement-adequacy risk, not a
compile-time-checkable one, which is exactly why the quantifier order was audited by hand
rather than left to the type-checker alone. -/

#print axioms zero_isFullSolution
#print axioms sobolevWeight_nonneg
#print axioms zero_isSpatiallySmooth
#print axioms dyadicShell_regularity_reduction
#print axioms zero_isGalerkinLimit
#print axioms hasFiniteEnstrophy_of_bounded
#print axioms zero_global_regularity

end MechanicaFluidorum.MillenniumReduction
