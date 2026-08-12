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
  it needs, verbatim, under this file's own namespace.

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
  Q5 (was: `HasBoundedFullLimit` bounded finite partial sums of `w n * u(t,n)²` without
      requiring `w ≥ 0`, unlike `HypothesisU_Statements.lean`'s own `enstrophy_nonneg`, which
      requires it explicitly — for signed `w`, "partial sums bounded" does not mean "enstrophy
      controlled"). DECISION: add `hw : ∀ n, 0 ≤ w n` as an explicit parameter of
      `HasBoundedFullLimit`, threaded through `AubinLionsStatement`/`ProdiSerrinStatement`/
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

/-- Enstrophy of the zero flow is zero at any cutoff, any weights, any time — needed for the
non-vacuity witnesses below. Verbatim copy of `HypothesisU_Statements.enstrophy_zero`. -/
theorem enstrophy_zero (N : ℕ) (w : ℕ → ℝ) (t : ℝ) :
    enstrophy N w (fun _ _ => (0 : ℝ)) t = 0 := by
  unfold enstrophy
  exact Finset.sum_eq_zero (fun n _ => by ring)

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
this for every `s`, not just `s = 1` (which is all `HasBoundedFullLimit` below tracks), is what
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

/-! ## 4. The two undischarged analytic steps, as named hypothesis parameters -/

/-- **Compactness-step output.** `HasBoundedFullLimit nu T B w hw u0` says: there is an
untruncated solution `ulim` of the same evolution law and data, and a bound `C > 0`, such that
EVERY finite partial enstrophy sum of `ulim` (cutoff `M`, arbitrary) stays `≤ C` on `[0, T]`.
This is the finite-partial-sum avatar of "the limit inherits a uniform `H¹`-type bound" — the
combined content of SPEC.md §II Steps 1–2. `hw` (Q5) makes "enstrophy controlled" honest: for
nonnegative `w`, bounded finite partial sums IS equivalent to the (possibly infinite) sum
converging with value `≤ C`. Named separately from `AubinLionsStatement`/`ProdiSerrinStatement`
so their two types are SYNTACTICALLY identical at the join point — see NC1/NC2 below for why
that identity is load-bearing. -/
def HasBoundedFullLimit (nu T : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ) (hw : ∀ n, 0 ≤ w n)
    (u0 : ℕ → ℝ) : Prop :=
  ∃ (ulim : ℝ → ℕ → ℝ) (C : ℝ), 0 < C ∧
    IsFullSolution nu B w u0 ulim ∧
    ∀ M : ℕ, ∀ t : ℝ, 0 ≤ t → t ≤ T → enstrophy M w ulim t ≤ C

/-- **Aubin–Lions compactness (SPEC.md §II Steps 1–2), as a hypothesis parameter.**
`docs/REVIEW-2026-08-12.md` L7: the prior tree's `axiom aubin_lions_compactness` is replaced by
this named `Prop`, supplied by the caller of `millennium_reduction` rather than asserted
unconditionally. Quantifies over `T` explicitly (Q4): SPEC.md §1.1 requires Hypothesis U "for
… all T", not one fixed horizon. NOT proved in this file — this is exactly the undischarged
analytic content the reduction is conditional on. -/
def AubinLionsStatement (nu : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ) (hw : ∀ n, 0 ≤ w n)
    (u0 : ℕ → ℝ) : Prop :=
  (∀ T : ℝ, HypothesisU nu T B w u0) → (∀ T : ℝ, HasBoundedFullLimit nu T B w hw u0)

/-- **Global regularity of the untruncated system.** Existence of a genuine solution that is
BOTH globally-in-time defined (`IsFullSolution`'s `∀ t ≥ 0` clause) AND spatially smooth at
every time (`IsSpatiallySmooth`, Q3) — the honest two-axis (time × space) translation of
"globally smooth", not merely the time axis alone. `T`-independent by construction, matching
SPEC.md §1.1's "for all T" hypothesis producing a `T`-independent conclusion. -/
def GlobalRegularityStatement (nu : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ) (k : ℕ → ℝ)
    (u0 : ℕ → ℝ) : Prop :=
  ∃ u : ℝ → ℕ → ℝ, IsFullSolution nu B w u0 u ∧ ∀ t : ℝ, 0 ≤ t → IsSpatiallySmooth k u t

/-- **Prodi–Serrin regularity criterion (SPEC.md §II Step 3), as a hypothesis parameter.**
Promotes the compactness-step's family of bounded limits (`H¹`-type control at every `T`, via
`HasBoundedFullLimit`) to global regularity in BOTH time and space (`u ∈ L^∞_t L^6_x` via
Sobolev embedding, then Prodi–Serrin's parabolic bootstrap to full smoothness). `hwk` ties the
wavenumber `k` used in the conclusion's `IsSpatiallySmooth` to the weight `w` used in the
hypothesis's `HasBoundedFullLimit` (`w n = (k n)²`) — without it `k` would be an unrelated,
meaningless parameter. NOT proved in this file, for the same reason as `AubinLionsStatement`. -/
def ProdiSerrinStatement (nu : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ) (hw : ∀ n, 0 ≤ w n)
    (k : ℕ → ℝ) (hwk : ∀ n, w n = (k n) ^ 2) (u0 : ℕ → ℝ) : Prop :=
  (∀ T : ℝ, HasBoundedFullLimit nu T B w hw u0) → GlobalRegularityStatement nu B w k u0

/-! ## 5. The reduction itself

Pure logical composition — `hPS (hAL hU)` — by design: all mathematical weight is parked in
`hAL`/`hPS`'s TYPES (§4), matching `docs/REVIEW-2026-08-12.md` L7's prescription exactly. This
is not a weaker proof standing in for a real one; it is the entire honest content of "the
reduction chain type-checks", which is all F3 (PLAN.md §4) asks for. `hwk` is not consumed by
the proof term itself (the composition works regardless) but is essential to the STATEMENT's
adequacy (Q3) — without it, nothing would force `k` to have anything to do with the dynamics
governed by `w`. -/

/-- **Conditional Millennium Reduction.** If the truncated system satisfies Hypothesis U at
`(nu, T, B, w, u0)` for EVERY horizon `T`, and the Aubin–Lions compactness step and the
Prodi–Serrin promotion step both hold for the same parameters, then the untruncated system has
a genuine solution matching `u0` that is global in time AND spatially smooth (lies in every
Sobolev class `H^s`) at every time. Proves no PDE content: `hAL` and `hPS` carry the entire
analytic weight of Proposition 5.1 (SPEC.md §1.1); this theorem only certifies that the chain
composes, with the parameters honestly related (`hw`, `hwk`). -/
theorem millennium_reduction (nu : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ) (hw : ∀ n, 0 ≤ w n)
    (k : ℕ → ℝ) (hwk : ∀ n, w n = (k n) ^ 2) (u0 : ℕ → ℝ)
    (hU : ∀ T : ℝ, HypothesisU nu T B w u0)
    (hAL : AubinLionsStatement nu B w hw u0)
    (hPS : ProdiSerrinStatement nu B w hw k hwk u0) :
    GlobalRegularityStatement nu B w k u0 :=
  hPS (hAL hU)

/-! ## 6. Non-vacuity (SPEC §7.5), scoped to what this file can honestly discharge

Proving `HypothesisU`/`AubinLionsStatement`/`ProdiSerrinStatement` themselves ACHIEVABLE would
require ODE existence/uniqueness theory this toolchain excludes (already deferred in F2 via its
own `WITNESS DEFERRED` comment on `HypothesisU`). What is proved below, matching exactly the
scope of F2's `zero_isGalerkinSolution`, is that the TARGET objects of this file's new
definitions are genuinely satisfiable (inhabited types), not vacuous by construction. -/

/-- `HasBoundedFullLimit` is satisfiable: the zero flow, bound `C = 1`. -/
theorem zero_has_bounded_full_limit (nu T : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ)
    (hw : ∀ n, 0 ≤ w n) (hB : ∀ n : ℕ, B n (fun _ => (0 : ℝ)) = 0) :
    HasBoundedFullLimit nu T B w hw (fun _ => (0 : ℝ)) := by
  refine ⟨_, 1, one_pos, zero_isFullSolution nu B w hB, ?_⟩
  intro M t _ _
  rw [enstrophy_zero]
  exact zero_le_one

/-- `GlobalRegularityStatement` is satisfiable: the zero flow, for any wavenumber `k`. -/
theorem zero_global_regularity (nu : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ) (k : ℕ → ℝ)
    (hB : ∀ n : ℕ, B n (fun _ => (0 : ℝ)) = 0) :
    GlobalRegularityStatement nu B w k (fun _ => (0 : ℝ)) :=
  ⟨_, zero_isFullSolution nu B w hB, fun t _ => zero_isSpatiallySmooth k t⟩

/-! ## 7. Axiom-footprint gate (SPEC §5.1 / PLAN.md §2)

Every theorem below must report exactly `[propext, Classical.choice, Quot.sound]`.

**Negative controls (hand-derived, actually run against scratch perturbed copies 2026-08-12; see
`docs/designs/F3_MILLENNIUM_REDUCTION_SKELETON.md` for the full table with confirmed outcomes):**
NC1 — inlining `AubinLionsStatement`'s conclusion with the `0 ≤ t →` guard dropped (instead of
using the shared `HasBoundedFullLimit` name) breaks the type-identity `hPS (hAL hU)` relies on.
NC2 — replacing the proof body with `hAL hU` alone (dropping `hPS`) is a type error: expected
`GlobalRegularityStatement …`, got `∀ T, HasBoundedFullLimit …`. NC3 — deleting `hB` from
`zero_isFullSolution`'s signature: `unknown identifier hB`, cascading into every non-vacuity
call site. NC4 (new, Q3) — dropping the `∀ s :` quantifier from `IsSpatiallySmooth` (fixing
`s := 1`) would make `GlobalRegularityStatement` provable directly from `HasBoundedFullLimit`
alone (no genuine promotion needed), collapsing `ProdiSerrinStatement` into something with far
less content than Prodi–Serrin's actual bootstrap — this is a statement-adequacy risk, not a
compile-time-checkable one, which is exactly why the quantifier order was audited by hand
rather than left to the type-checker alone. -/

#print axioms zero_isFullSolution
#print axioms enstrophy_zero
#print axioms sobolevWeight_nonneg
#print axioms zero_isSpatiallySmooth
#print axioms millennium_reduction
#print axioms zero_has_bounded_full_limit
#print axioms zero_global_regularity

end MechanicaFluidorum.MillenniumReduction
