/-
  MillenniumReduction.lean — Tier A: conditional Millennium Reduction skeleton (PLAN.md §4, F3)
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
  BUILD NOTE (same as `EnstrophyProductionBound.lean`).
  ---------------------------------------------------------------------------
  `lean_src` is not a Lake project of its own; `scripts/verify.sh` Gate 2 compiles every file
  standalone via `lake env lean` against an external Mathlib build, so cross-file `import` of
  another `lean_src/*.lean` module fails (`unknown module prefix`). Accordingly this file does
  NOT import `HypothesisU_Statements.lean`; it re-declares the minimal subset of its vocabulary
  it needs (`IsGalerkinSolution`, `enstrophy`, `HypothesisU`, and the two nonnegativity/zero
  lemmas used in the non-vacuity witnesses below), verbatim, under this file's own namespace.

  Scope (declared, matches `HypothesisU_Statements.lean`'s own exclusions): no real Fourier
  analysis on 𝕋³, no Sobolev spaces, no ODE existence/uniqueness theory, no `tsum`/summability.
  "Boundedness of the untruncated limit" is stated via arbitrarily-large FINITE partial sums
  (reusing `enstrophy`), not an infinite series — see the design memo for why this is the
  honest, no-new-import avatar of the continuum statement. "Global" (in "global regularity")
  is stated as: the evolution law's `HasDerivAt` clause holds for every `t ≥ 0`, unbounded — the
  precise ODE-theoretic meaning of "no finite-time blow-up" in this vocabulary.

  Gate: `#print axioms` for every theorem below must report exactly
  [propext, Classical.choice, Quot.sound].
-/
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Finset.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum

namespace MechanicaFluidorum.MillenniumReduction

/-! ## 1. Re-declared vocabulary from `HypothesisU_Statements.lean` (F2, audited 2026-08-12) -/

/-- Projection of an initial datum onto the modes retained at cutoff `N`. Verbatim copy of
`HypothesisU_Statements.truncate` (needed only to state `IsGalerkinSolution`). -/
def truncate (N : ℕ) (u0 : ℕ → ℝ) : ℕ → ℝ := fun n => if n ≤ N then u0 n else 0

/-- The `N`-truncated Galerkin system. Verbatim copy of
`HypothesisU_Statements.IsGalerkinSolution`. -/
def IsGalerkinSolution (N : ℕ) (nu : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ)
    (u0 : ℕ → ℝ) (u : ℝ → ℕ → ℝ) : Prop :=
  u 0 = truncate N u0
  ∧ (∀ t : ℝ, ∀ n : ℕ, n ≤ N →
      HasDerivAt (fun s : ℝ => u s n) (B n (u t) - nu * w n * u t n) t)
  ∧ (∀ t : ℝ, ∀ n : ℕ, N < n → u t n = 0)

/-- Weighted-ℓ² enstrophy of the truncated state. Verbatim copy of
`HypothesisU_Statements.enstrophy`. -/
def enstrophy (N : ℕ) (w : ℕ → ℝ) (u : ℝ → ℕ → ℝ) (t : ℝ) : ℝ :=
  ∑ n ∈ Finset.range (N + 1), w n * (u t n) ^ 2

/-- Hypothesis U (Galerkin form). Verbatim copy of `HypothesisU_Statements.HypothesisU`. -/
def HypothesisU (nu T : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ) (u0 : ℕ → ℝ) : Prop :=
  ∃ C : ℝ, 0 < C ∧
    ∀ N : ℕ, ∀ u : ℝ → ℕ → ℝ, IsGalerkinSolution N nu B w u0 u →
      ∀ t : ℝ, 0 ≤ t → t ≤ T → enstrophy N w u t ≤ C

/-! ## 2. New: the untruncated (`N → ∞`) solution family -/

/-- `IsFullSolution nu B w u0 u`: `u` solves the SAME evolution law as `IsGalerkinSolution`,
but with NO cutoff — every mode is retained (no clause analogous to `IsGalerkinSolution`'s
clause (3)), the initial datum is `u0` directly (nothing to project: there is no discarded
mode to truncate away), and the evolution clause is required at every `t ≥ 0`, unbounded. A
solution failing to exist past some finite `t*` is exactly the failure of `HasDerivAt` at `t*`;
requiring it for all `t ≥ 0` is the honest ODE-theoretic content of "no finite-time blow-up",
i.e. of "globally smooth" (SPEC.md §1.1). -/
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

/-- Enstrophy of the zero flow is zero at any cutoff, any weights, any time — needed for the
non-vacuity witnesses below. Verbatim copy of `HypothesisU_Statements.enstrophy_zero`. -/
theorem enstrophy_zero (N : ℕ) (w : ℕ → ℝ) (t : ℝ) :
    enstrophy N w (fun _ _ => (0 : ℝ)) t = 0 := by
  unfold enstrophy
  exact Finset.sum_eq_zero (fun n _ => by ring)

/-! ## 3. The two undischarged analytic steps, as named hypothesis parameters -/

/-- **Compactness-step output.** `HasBoundedFullLimit nu T B w u0` says: there is an untruncated
solution `ulim` of the same evolution law and data, and a bound `C > 0`, such that EVERY finite
partial enstrophy sum of `ulim` (cutoff `M`, arbitrary) stays `≤ C` on `[0, T]`. This is the
finite-partial-sum avatar of "the limit inherits a uniform bound in an appropriate norm" — the
combined content of SPEC.md §II Steps 1–2 (Aubin–Lions strong-L² limit is Leray–Hopf, then
weak-lower-semicontinuity of the H¹ norm gives it the same bound). Named separately from
`AubinLionsStatement`/`ProdiSerrinStatement` so their two types are SYNTACTICALLY identical at
the join point, not two independently-typed tuples that happen to agree — see NC1/NC2 below for
why that identity is load-bearing. -/
def HasBoundedFullLimit (nu T : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ) (u0 : ℕ → ℝ) : Prop :=
  ∃ (ulim : ℝ → ℕ → ℝ) (C : ℝ), 0 < C ∧
    IsFullSolution nu B w u0 ulim ∧
    ∀ M : ℕ, ∀ t : ℝ, 0 ≤ t → t ≤ T → enstrophy M w ulim t ≤ C

/-- **Aubin–Lions compactness (SPEC.md §II Steps 1–2), as a hypothesis parameter.**
`docs/REVIEW-2026-08-12.md` L7: the prior tree's `axiom aubin_lions_compactness` is replaced by
this named `Prop`, supplied by the caller of `millennium_reduction` rather than asserted
unconditionally. NOT proved in this file — this is exactly the undischarged analytic content
the reduction is conditional on. -/
def AubinLionsStatement (nu T : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ) (u0 : ℕ → ℝ) : Prop :=
  HypothesisU nu T B w u0 → HasBoundedFullLimit nu T B w u0

/-- **Global regularity of the untruncated system.** Existence of a genuine (globally-in-time)
solution matching the given data. Deliberately `T`-independent: a solution whose `HasDerivAt`
clause holds for every `t ≥ 0` is regular for all time by construction, matching SPEC.md §1.1
("Hypothesis U holds for … all T" ⇒ the conclusion does not carry a residual `T`). -/
def GlobalRegularityStatement (nu : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ)
    (u0 : ℕ → ℝ) : Prop :=
  ∃ u : ℝ → ℕ → ℝ, IsFullSolution nu B w u0 u

/-- **Prodi–Serrin regularity criterion (SPEC.md §II Step 3), as a hypothesis parameter.**
Promotes the compactness-step's bounded limit (`H¹`-type control, via `HasBoundedFullLimit`) to
global regularity (`u ∈ L^∞_t L^6_x` via Sobolev embedding, then Prodi–Serrin). NOT proved in
this file, for the same reason as `AubinLionsStatement`. -/
def ProdiSerrinStatement (nu T : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ) (u0 : ℕ → ℝ) : Prop :=
  HasBoundedFullLimit nu T B w u0 → GlobalRegularityStatement nu B w u0

/-! ## 4. The reduction itself

Pure logical composition — `hPS (hAL hU)` — by design: all mathematical weight is parked in
`hAL`/`hPS`'s TYPES (§3), matching `docs/REVIEW-2026-08-12.md` L7's prescription exactly. This
is not a weaker proof standing in for a real one; it is the entire honest content of "the
reduction chain type-checks", which is all F3 (PLAN.md §4) asks for. -/

/-- **Conditional Millennium Reduction.** If the `N`-truncated system satisfies Hypothesis U at
`(nu, T, B, w, u0)`, and the Aubin–Lions compactness step and the Prodi–Serrin promotion step
both hold for the same parameters, then the untruncated system has a genuine global-in-time
solution matching `u0`. Proves no PDE content: `hAL` and `hPS` carry the entire analytic weight
of Proposition 5.1 (SPEC.md §1.1); this theorem only certifies that the chain composes. -/
theorem millennium_reduction (nu T : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ) (u0 : ℕ → ℝ)
    (hU : HypothesisU nu T B w u0)
    (hAL : AubinLionsStatement nu T B w u0)
    (hPS : ProdiSerrinStatement nu T B w u0) :
    GlobalRegularityStatement nu B w u0 :=
  hPS (hAL hU)

/-! ## 5. Non-vacuity (SPEC §7.5), scoped to what this file can honestly discharge

Proving `HypothesisU`/`AubinLionsStatement`/`ProdiSerrinStatement` themselves ACHIEVABLE would
require ODE existence/uniqueness theory this toolchain excludes (already deferred in F2 via its
own `WITNESS DEFERRED` comment on `HypothesisU`). What is proved below, matching exactly the
scope of F2's `zero_isGalerkinSolution`, is that the TARGET objects of this file's new
definitions are genuinely satisfiable (inhabited types), not vacuous by construction. -/

/-- `HasBoundedFullLimit` is satisfiable: the zero flow, bound `C = 1`. -/
theorem zero_has_bounded_full_limit (nu T : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ)
    (hB : ∀ n : ℕ, B n (fun _ => (0 : ℝ)) = 0) :
    HasBoundedFullLimit nu T B w (fun _ => (0 : ℝ)) := by
  refine ⟨_, 1, one_pos, zero_isFullSolution nu B w hB, ?_⟩
  intro M t _ _
  rw [enstrophy_zero]
  exact zero_le_one

/-- `GlobalRegularityStatement` is satisfiable: the zero flow. -/
theorem zero_global_regularity (nu : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ)
    (hB : ∀ n : ℕ, B n (fun _ => (0 : ℝ)) = 0) :
    GlobalRegularityStatement nu B w (fun _ => (0 : ℝ)) :=
  ⟨_, zero_isFullSolution nu B w hB⟩

/-! ## 6. Axiom-footprint gate (SPEC §5.1 / PLAN.md §2)

Every theorem below must report exactly `[propext, Classical.choice, Quot.sound]`.

**Negative controls (hand-derived, actually run against scratch perturbed copies 2026-08-12; see
`docs/designs/F3_MILLENNIUM_REDUCTION_SKELETON.md` for the full table with confirmed outcomes):**
NC1 — inlining `AubinLionsStatement`'s conclusion with the `0 ≤ t →` guard dropped (instead of
using the shared `HasBoundedFullLimit` name) breaks the type-identity `hPS (hAL hU)` relies on:
confirmed `Application type mismatch`. NC2 — replacing the proof body with `hAL hU` alone
(dropping `hPS`) is a type error: confirmed, expected `GlobalRegularityStatement …`, got
`HasBoundedFullLimit …`. NC3 — deleting `hB` from `zero_isFullSolution`'s signature: confirmed
`unknown identifier hB`, cascading into both non-vacuity call sites. -/

#print axioms zero_isFullSolution
#print axioms enstrophy_zero
#print axioms millennium_reduction
#print axioms zero_has_bounded_full_limit
#print axioms zero_global_regularity

end MechanicaFluidorum.MillenniumReduction
