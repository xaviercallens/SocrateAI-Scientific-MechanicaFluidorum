/- STATUS: v3 — PIVOTED TO THE DYADIC SHELL MODEL per the external audit of 2026-08-13
   (docs/Memo 1.md; verdicts in LEDGER.md). The audit KILLED the claim that this file
   restates the 3-D Millennium problem: with a 1-D index cutoff (verdict A2: NO), the
   exponential weight 4^n (A3: NO), and an unconstrained interaction term B (A5: NO,
   "authenticating a mathematically empty envelope"), what this file actually describes is a
   dyadic shell hierarchy. The accepted resolution is to EMBRACE that: the programme's formal
   target is now the truncated viscous Katz-Pavlovic shell model, for which the index cutoff,
   the weight k_n^2 = 4^n, and the concrete nonlinearity `shellB` below are not proxies but
   THE objects themselves. A2/A3 dissolve under the pivot; A5 is resolved by section 1c
   (`shellB` + its Tier A energy-conservation theorem, per Memo Task 2). The abstract-B
   scaffolding is RETAINED below only because the refutation theorems (section 3) and the
   inhabitation witnesses quantify over it — it no longer carries any headline claim.

   Earlier decisions Q1, Q2, DECIDED BY THE HUMAN OWNER on 2026-08-12, remain in force:
     Q1 -> initial data is PROJECTED at each cutoff (`truncate N u0`), mirroring the continuum
           definition u(0) = J_{sqrt(alpha')} u0 and closing the vacuity leak at every N.
     Q2 -> the enstrophy weight is CONCRETE: w n = (k n)^2 = 4^n with dyadic k n = 2^n
           (`dyadicWeight`), making enstrophy provably nonnegative (`enstrophy_nonneg_dyadic`).
   Remaining audit: overall statement adequacy (does `HypothesisU` below mean what
   docs/HYPOTHESIS_U_SPECIFICATION.md section I means). Not yet cited by LEDGER.md as a claim. -/

import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Data.Finset.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Pow.Real

/-!
# Hypothesis U — statement-level formalization (Galerkin shape)

## What this file is

A formal, **non-vacuous** statement of Hypothesis U (`docs/HYPOTHESIS_U_SPECIFICATION.md` §I)
at the level of a finite-dimensional Galerkin truncation. It contains **statements and
non-vacuity lemmas only**; it proves no analytic content about Navier–Stokes.

## The defect this file repairs (REVIEW-2026-08-12, finding L3)

In the prior tree (`NS/HypothesisU.lean`) the truncated flow `TruncatedFlow a` was defined as
*an arbitrary smooth vector field*: no equation, no initial datum, no dependence on the cutoff
`a`. The resulting `HypothesisU` therefore quantified over **all** smooth fields and is
**provably false** — scaling any field by `λ` scales enstrophy by `λ²`, which is unbounded.
Theorems `enstrophy_smul`, `enstrophy_unbounded_under_scaling` and `unconstrained_bound_false`
below are the machine-checked form of exactly that refutation, so the defect is recorded here
as a proved fact rather than as prose.

**How `IsGalerkinSolution` blocks the scaling counterexample.** The scaling map
`u ↦ (fun s n => c * u s n)` sends the initial condition `u 0 = truncate N u₀` to
`c • truncate N u₀ ≠ truncate N u₀` (for `c ≠ 1` and `u₀` not identically `0` on modes `≤ N`),
so a rescaled solution no longer satisfies clause (i) with the *same* fixed data. It also
fails clause (ii): the drift term `B n (u t)` is a fixed given function of the state, not
assumed homogeneous, while the viscous term `- ν · w n · u t n` is linear, so
`c · (dependence)` cannot in general reproduce the right-hand side at the rescaled state. The
family being bounded is thus the (single) orbit of one *projected* datum under one evolution
law, indexed by the cutoff `N` — not a linear space closed under dilation.

## Scope — deliberately modest (declared for the audit)

INCLUDED: the finite-dimensional Galerkin *shape* — cutoff `N : ℕ`, state `ℝ → (ℕ → ℝ)`,
an **abstract** mode-interaction term `B` supplied as a parameter, a weight function `w`
supplied as a parameter, the enstrophy functional, `HypothesisU` with `C` quantified **before**
`N`, and non-vacuity lemmas.

DELIBERATELY EXCLUDED (would require improvisation or unavailable Mathlib, hence out of scope
per PLAN.md rule E-1 and the instruction to reduce scope rather than admit an unproved step):
  * Real Fourier analysis on 𝕋³: divergence-free trigonometric polynomials, the Leray
    projection, the actual `L²(𝕋³)` enstrophy norm.
  * Any concrete instantiation of `B` by the 3-D Navier–Stokes convolution nonlinearity.
    **This is where the real mathematical content lives and it is deferred**; every theorem
    below is therefore about the shape of the statement, never about fluids.
  * Any proof (or disproof) of `HypothesisU` itself, and any ODE existence/uniqueness theory
    (no Picard–Lindelöf, no Grönwall — those Mathlib modules are not built in this toolchain).
  * The identification `N ≈ 1/√α'`: `N` is left as a bare cutoff index; the correspondence to
    the T-dual parameter `α'` is narrative and is not asserted formally here.

## Two questions raised by the v1 draft — DECIDED by the human owner, 2026-08-12

  Q1 (was open). `HypothesisU` fixes one `u₀ : ℕ → ℝ` across all cutoffs `N`; clause (iii)
      forces `u t n = 0` for `n > N`. The v1 draft used the *literal* `u 0 = u0`, which is
      empty (vacuous) at any `N` below `u₀`'s support. **Decision: project `u₀` at each
      cutoff.** Clause (i) is now `u 0 = truncate N u0` (see `truncate` below), mirroring the
      continuum definition `u(0) = J_{√α'} u₀` in `docs/HYPOTHESIS_U_SPECIFICATION.md` §I. A
      solution family now exists at *every* `N` for *every* `u₀` — `truncate_zero` witnesses
      this is not itself a vacuity trick (the zero-flow instance still needs `hB`, unchanged).
  Q2 (was open). **Decision: `w` is fixed concretely to `dyadicWeight n = (2^n)²`** — the
      squared dyadic wavenumber, morally `k_n²` from the Katz–Pavlović model in
      `lean_src/DyadicShells.lean`. `enstrophy_nonneg_dyadic` below proves the resulting
      functional is genuinely a sum of squares (nonnegative), so "enstrophy" is not merely a
      name. The general (abstract-`w`) definitions are kept — `HypothesisU_dyadic` is the
      concrete specialization built from them, not a replacement.
-/

namespace MechanicaFluidorum

/-! ## 1. The truncated (Galerkin) system

Conventions, all of which are **quantified parameters, never global constants** (PLAN.md §2:
"DO NOT fix α′ (or the cutoff N) as a global constant"; SPEC §7.1):

* `N : ℕ`      — the truncation level (morally `1/√α'`). Quantified in every statement.
* `nu : ℝ`     — viscosity.
* `w : ℕ → ℝ`  — the mode weight (morally `k n ^ 2`). Given, not constructed.
* `B : ℕ → (ℕ → ℝ) → ℝ` — the mode-interaction (nonlinear) term: `B n v` is the `n`-th
  component of the interaction evaluated at the state `v`. Given as a parameter.
  **The true 3-D Navier–Stokes nonlinearity is NOT written here**; instantiating `B` with it
  is deferred, and that instantiation is where the entire mathematical content of the program
  resides. Inventing a specific convolution at this point is banned by PLAN.md rule E-1. -/

/-- Projection of an initial datum `u0` onto the modes retained at cutoff `N`: identity below
(and at) the cutoff, zero above. This is the discrete analogue of the continuum projection
`J_{√α'}` applied to the initial data (`docs/HYPOTHESIS_U_SPECIFICATION.md` §I). -/
def truncate (N : ℕ) (u0 : ℕ → ℝ) : ℕ → ℝ := fun n => if n ≤ N then u0 n else 0

/-- The zero datum truncates to the zero datum, at every cutoff. Non-vacuity check that
`truncate` is not itself hiding a vacuity trick: it acts as the identity on the only case that
matters for the `zero_isGalerkinSolution` witness below. -/
theorem truncate_zero (N : ℕ) : truncate N (fun _ => (0 : ℝ)) = fun _ => (0 : ℝ) := by
  funext n; unfold truncate; split_ifs <;> rfl

/-- `IsGalerkinSolution N nu B w u0 u` says the time-dependent mode-amplitude vector
`u : ℝ → (ℕ → ℝ)` is a solution of the `N`-truncated system with initial datum `u0`:

1. **initial condition** `u 0 = truncate N u0` — the datum *projected onto the retained
   modes*, decided 2026-08-12 (Q1 above) to close the vacuity leak of the v1 draft: with the
   literal `u 0 = u0`, any `u0` carrying a mode above `N` made the hypothesis set at that `N`
   empty, so `HypothesisU` held there vacuously;
2. **evolution law** for every time `t` and every retained mode `n ≤ N`,
   `d/ds (u s n) |_{s = t} = B n (u t) - nu * w n * u t n`;
3. **truncation** every discarded mode `n > N` vanishes identically in time.

Clauses (1) and (2) are precisely what the prior formalization omitted (finding L3); they are
what makes the family in `HypothesisU` a genuine constraint rather than "all smooth fields". -/
def IsGalerkinSolution (N : ℕ) (nu : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ)
    (u0 : ℕ → ℝ) (u : ℝ → ℕ → ℝ) : Prop :=
  u 0 = truncate N u0
  ∧ (∀ t : ℝ, ∀ n : ℕ, n ≤ N →
      HasDerivAt (fun s : ℝ => u s n) (B n (u t) - nu * w n * u t n) t)
  ∧ (∀ t : ℝ, ∀ n : ℕ, N < n → u t n = 0)

/-- Enstrophy of the truncated state at time `t`: the `w`-weighted square sum over the
retained modes `0, …, N`. Modes above the cutoff are absent from the sum by construction, in
agreement with clause (3) of `IsGalerkinSolution`. -/
def enstrophy (N : ℕ) (w : ℕ → ℝ) (u : ℝ → ℕ → ℝ) (t : ℝ) : ℝ :=
  ∑ n ∈ Finset.range (N + 1), w n * (u t n) ^ 2

/-- **Hypothesis U (Galerkin form).**

There is a *single* constant `C > 0` such that for **every** cutoff `N`, every solution `u`
of the `N`-truncated system with the **same** fixed data `u0` and the same parameters
`nu, B, w`, and every time `t ∈ [0, T]`, the enstrophy is at most `C`.

**The quantifier order is the entire point.** `∃ C, ∀ N, …` — `C` is chosen before `N` and so
cannot depend on the cutoff. Swapping to `∀ N, ∃ C, …` would be the trivial statement that
each finite-dimensional truncation is bounded on its own, which carries no information about
the `α' → 0` limit; that swap is the failure mode this ordering exists to exclude. -/
def HypothesisU (nu T : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ) (u0 : ℕ → ℝ) : Prop :=
  ∃ C : ℝ, 0 < C ∧
    ∀ N : ℕ, ∀ u : ℝ → ℕ → ℝ, IsGalerkinSolution N nu B w u0 u →
      ∀ t : ℝ, 0 ≤ t → t ≤ T → enstrophy N w u t ≤ C

-- WITNESS DEFERRED for `HypothesisU`: exhibiting a parameter tuple for which `HypothesisU`
-- *holds* requires knowing that the constrained family is nonempty AND controlled, i.e. ODE
-- existence/uniqueness (Picard–Lindelöf) plus a Grönwall estimate. Neither module is built in
-- this toolchain, and supplying either by hand would be improvised mathematics (E-1). What is
-- proved below instead is that the *constraint set* `IsGalerkinSolution` is inhabited
-- (`zero_isGalerkinSolution`), which is the non-vacuity obligation of SPEC §7.5 for the
-- definitions this file introduces.

/-! ## 1b. The concrete dyadic weight (Q2, decided 2026-08-12)

`enstrophy` above is parametric in `w`, so it is not provably nonnegative in general — a
functional called "enstrophy" that could be negative is a name with no content. The general
form is kept (it is the honest level of abstraction while `B`'s instantiation is open), and
the concrete instance intended by the program — matching the Katz–Pavlović wavenumbers of
`lean_src/DyadicShells.lean` — is fixed here. -/

/-- Dyadic wavenumber `k n = 2ⁿ`, matching `lean_src/DyadicShells.lean`. -/
noncomputable def dyadicWavenumber (n : ℕ) : ℝ := (2 : ℝ) ^ n

/-- The concrete enstrophy weight: squared dyadic wavenumber, `w n = 4ⁿ`. -/
noncomputable def dyadicWeight (n : ℕ) : ℝ := (dyadicWavenumber n) ^ 2

/-- The dyadic weight is strictly positive at every mode. -/
theorem dyadicWeight_pos (n : ℕ) : 0 < dyadicWeight n := by
  unfold dyadicWeight dyadicWavenumber; positivity

/-- **General nonnegativity.** For any weight bounded below by `0`, `enstrophy` is a
nonnegative sum of squares — the minimal fact that makes the name "enstrophy" honest. -/
theorem enstrophy_nonneg (N : ℕ) (w : ℕ → ℝ) (hw : ∀ n, 0 ≤ w n)
    (u : ℝ → ℕ → ℝ) (t : ℝ) : 0 ≤ enstrophy N w u t := by
  unfold enstrophy
  exact Finset.sum_nonneg (fun n _ => mul_nonneg (hw n) (sq_nonneg _))

/-- Specialization to the concrete dyadic weight: enstrophy is genuinely nonnegative for the
weight the program actually uses. -/
theorem enstrophy_nonneg_dyadic (N : ℕ) (u : ℝ → ℕ → ℝ) (t : ℝ) :
    0 ≤ enstrophy N dyadicWeight u t :=
  enstrophy_nonneg N dyadicWeight (fun n => (dyadicWeight_pos n).le) u t

/-- **Hypothesis U (dyadic-concrete form).** `HypothesisU` specialized to the weight the
program actually studies — the same statement as `HypothesisU` with `w := dyadicWeight`
pinned. This is the object `docs/HYPOTHESIS_U_SPECIFICATION.md` §I refers to informally as
"the enstrophy of the regularized velocity field"; the connection to the true `L²(𝕋³)` norm
remains outside this file's scope (declared exclusion, above). -/
def HypothesisU_dyadic (nu T : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (u0 : ℕ → ℝ) : Prop :=
  HypothesisU nu T B dyadicWeight u0

/-! ## 1c. The concrete nonlinearity (Memo 1 Task 2, 2026-08-13): `B` is no longer abstract

The external audit's A5 verdict: certifying a bound for an unconstrained `B` is
"authenticating a mathematically empty envelope" — a generic truncated sequence simply blows
up. The fix directed by the owner: instantiate `B` as the physical Katz–Pavlović shell
nonlinearity and prove, at Tier A, that it satisfies exact energy conservation
`Σ u_n B_n(u) = 0`. That is done here. Note the viscous term of `IsGalerkinSolution`,
`-nu * dyadicWeight n * u n = -nu * k_n² * u_n`, already matches the shell model exactly, so
`DyadicShellHypothesisU` below is a statement about precisely the truncated viscous
Katz–Pavlović system — the same model whose enstrophy-production identity is proven in
`lean_src/EnstrophyProduction.lean`. -/

/-- The Katz–Pavlović shell nonlinearity: `B_0(v) = −k_0 v_0 v_1` (no influx at the bottom
shell — `k_{-1}` is never evaluated) and `B_{m+1}(v) = k_m v_m² − k_{m+1} v_{m+1} v_{m+2}`. -/
noncomputable def shellB (k : ℕ → ℝ) : ℕ → (ℕ → ℝ) → ℝ
  | 0,     v => -(k 0 * v 0 * v 1)
  | m + 1, v => k m * v m ^ 2 - k (m + 1) * v (m + 1) * v (m + 2)

/-- `shellB` vanishes at the zero state — the hypothesis `hB` of
`zero_isGalerkinSolution`, so the inhabitation witness applies to the CONCRETE model. -/
theorem shellB_zero (k : ℕ → ℝ) (n : ℕ) : shellB k n (fun _ => (0 : ℝ)) = 0 := by
  cases n <;> simp [shellB]

/-- **Telescoping** (hand-derived before formalisation): with `out_m := k_m v_m² v_{m+1}`,
each summand is `v_n · B_n(v) = out_{n-1} − out_n` (reading `out_{-1} = 0`), so the energy
pairing telescopes to `−out_N`. -/
theorem sum_mul_shellB (k v : ℕ → ℝ) :
    ∀ N : ℕ, ∑ n ∈ Finset.range (N + 1), v n * shellB k n v
      = -(k N * v N ^ 2 * v (N + 1))
  | 0 => by
      rw [Finset.sum_range_one]
      show v 0 * -(k 0 * v 0 * v 1) = _
      ring
  | N + 1 => by
      rw [Finset.sum_range_succ, sum_mul_shellB k v N]
      simp only [shellB]
      ring

/-- **Exact energy conservation (Memo 1 Task 2, Tier A).** Under the truncation boundary
condition `v_{N+1} = 0`, the shell nonlinearity conserves energy exactly:
`Σ_{n≤N} v_n · B_n(v) = 0`. This is the structural constraint whose absence the audit called
fatal (A5); it is now a kernel-checked property of the concrete `B` this file quantifies over. -/
theorem shellB_energy_conservation (k v : ℕ → ℝ) (N : ℕ) (hbc : v (N + 1) = 0) :
    ∑ n ∈ Finset.range (N + 1), v n * shellB k n v = 0 := by
  rw [sum_mul_shellB, hbc]; ring

/-- **The programme's formal target after the pivot**: uniform-in-cutoff enstrophy control of
the truncated viscous Katz–Pavlović shell model — `HypothesisU` with `B := shellB k_n`,
`w := k_n²`, both concrete. Nothing abstract remains in this statement. -/
def DyadicShellHypothesisU (nu T : ℝ) (u0 : ℕ → ℝ) : Prop :=
  HypothesisU nu T (shellB dyadicWavenumber) dyadicWeight u0

/-! ## 1d. The dissipation degree α as a quantified parameter (E-3, 2026-08-14)

`docs/escalations/2026-08-14-E3-target-is-a-solved-case.md`: matching Cheskidov's equation (1.1)
`d/dt uₙ + ν λ^{2αn} uₙ − λⁿ u²ₙ₋₁ + λ^{n+1} uₙuₙ₊₁ = gₙ` shows this programme's dissipation
`ν kₙ² = ν 2^{2n}` corresponds to **α = 1**, inside the regime `α ≥ 1/2` where global regularity
is a published theorem. The live band is `1/3 ≤ α < 1/2`. So `α` must be a *quantified parameter*,
never a baked-in constant — the same rule `SPEC.md` §7.1 already imposes on `α'` and the cutoff.

**A conflation this exposes, invisible at α = 1.** `HypothesisU` above uses a single weight `w`
in BOTH roles: as the dissipation coefficient inside `IsGalerkinSolution` (`−ν·w n·u`) and as the
weight defining the quantity bounded (`enstrophy N w`). At `α = 1` both are `kₙ²` and the
conflation is invisible. **They are different objects:** enstrophy is *by definition* the
`kₙ²`-weighted square sum, whatever the dissipation is, while the dissipation coefficient is
`kₙ^{2α}`. The α-parametrised statement below keeps them separate. -/

/-- Dissipation coefficient at dissipation degree `a`: `kₙ^{2a}` (real exponent, so any
`a > 0` is expressible — the live band `1/3 ≤ a < 1/2` is not integral). -/
noncomputable def dissipationWeight (a : ℝ) (n : ℕ) : ℝ := (dyadicWavenumber n) ^ (2 * a)

theorem dissipationWeight_pos (a : ℝ) (n : ℕ) : 0 < dissipationWeight a n := by
  unfold dissipationWeight dyadicWavenumber
  exact Real.rpow_pos_of_pos (by positivity) _

/-- **The conflation, made explicit and proved.** At `a = 1` the dissipation coefficient equals
the enstrophy weight, which is exactly why the single-weight formulation went unnoticed. -/
theorem dissipationWeight_one : dissipationWeight 1 = dyadicWeight := by
  funext n
  unfold dissipationWeight dyadicWeight
  rw [show (2:ℝ) * 1 = ((2:ℕ):ℝ) by norm_num, Real.rpow_natCast]

/-- **Hypothesis U at dissipation degree `a`**, with the two roles separated: the dynamics
dissipate at `kₙ^{2a}`, while the bounded quantity is the enstrophy `Σ kₙ² aₙ²`. This is the
statement whose truth is a theorem for `a ≥ 1/2` (Cheskidov), false for `a < 1/3`, and OPEN in
between. -/
def DyadicShellHypothesisU_alpha (a nu T : ℝ) (u0 : ℕ → ℝ) : Prop :=
  ∃ C : ℝ, 0 < C ∧
    ∀ N : ℕ, ∀ u : ℝ → ℕ → ℝ,
      IsGalerkinSolution N nu (shellB dyadicWavenumber) (dissipationWeight a) u0 u →
        ∀ t : ℝ, 0 ≤ t → t ≤ T → enstrophy N dyadicWeight u t ≤ C

/-- The α-parametrised statement specialises at `a = 1` to the programme's existing target,
so nothing already proven is orphaned by the generalisation. -/
theorem dyadicShellHypothesisU_alpha_one (nu T : ℝ) (u0 : ℕ → ℝ) :
    DyadicShellHypothesisU_alpha 1 nu T u0 ↔ DyadicShellHypothesisU nu T u0 := by
  unfold DyadicShellHypothesisU_alpha DyadicShellHypothesisU HypothesisU
  rw [dissipationWeight_one]


/-- Every Galerkin solution of the concrete model satisfies exact energy conservation at
every time: clause (iii) of `IsGalerkinSolution` supplies the boundary condition
`u t (N+1) = 0`. Connects the algebraic identity to the actual solution family. -/
theorem galerkin_shellB_conservation (N : ℕ) (nu : ℝ) (u0 : ℕ → ℝ) (u : ℝ → ℕ → ℝ)
    (h : IsGalerkinSolution N nu (shellB dyadicWavenumber) dyadicWeight u0 u) (t : ℝ) :
    ∑ n ∈ Finset.range (N + 1), u t n * shellB dyadicWavenumber n (u t) = 0 :=
  shellB_energy_conservation _ _ _ (h.2.2 t (N + 1) (Nat.lt_succ_self N))

/-! ## 2. Non-vacuity: `IsGalerkinSolution` is inhabited -/

/-- The zero flow solves the truncated system with zero data, provided the interaction term
vanishes at the zero state (`hB`). This is the SPEC §7.5 inhabitation witness for
`IsGalerkinSolution`: the constraint is satisfiable, so statements quantifying over it are not
vacuous by construction. Note it does **not** make `HypothesisU` trivial — `HypothesisU`
quantifies over *all* solutions with the given data, not merely over one. -/
theorem zero_isGalerkinSolution (N : ℕ) (nu : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ)
    (hB : ∀ n : ℕ, B n (fun _ => (0 : ℝ)) = 0) :
    IsGalerkinSolution N nu B w (fun _ => (0 : ℝ)) (fun _ _ => (0 : ℝ)) := by
  refine ⟨(truncate_zero N).symm, ?_, ?_⟩
  · intro t n _
    have h : B n (fun _ => (0 : ℝ)) - nu * w n * 0 = 0 := by rw [hB n]; ring
    rw [h]
    exact hasDerivAt_const t (0 : ℝ)
  · intro t n _
    rfl

/-- Concrete instance of `zero_isGalerkinSolution`: cutoff `3`, viscosity `1`, zero
interaction, weights `w n = n²`. Kept as an `example` so the definition is exercised at a
closed parameter tuple, not only under a universally quantified `hB`. -/
example : IsGalerkinSolution 3 1 (fun _ _ => (0 : ℝ)) (fun n => (n : ℝ) ^ 2)
    (fun _ => (0 : ℝ)) (fun _ _ => (0 : ℝ)) :=
  zero_isGalerkinSolution 3 1 (fun _ _ => (0 : ℝ)) (fun n => (n : ℝ) ^ 2) (fun _ => rfl)

/-! ## 3. Enstrophy algebra, and why the equation constraint is load-bearing

The three results below are the machine-checked refutation of the old (vacuous) statement.
`enstrophy_smul` shows the functional is homogeneous of degree 2; `enstrophy_unbounded_under_scaling`
turns that into unboundedness along a dilation orbit; `unconstrained_bound_false` concludes
that "for all fields `u`, enstrophy ≤ C" is **false**, so any Hypothesis-U-shaped statement
which forgets the equation and the initial datum is false, not merely weak. -/

/-- Enstrophy of the zero flow is zero (any cutoff, any weights, any time). -/
theorem enstrophy_zero (N : ℕ) (w : ℕ → ℝ) (t : ℝ) :
    enstrophy N w (fun _ _ => (0 : ℝ)) t = 0 := by
  unfold enstrophy
  refine Finset.sum_eq_zero ?_
  intro n _
  ring

/-- **Degree-2 homogeneity.** Scaling the state by `c` scales the enstrophy by `c²`. This is
the identity that made the prior "arbitrary smooth field" formulation provably false. -/
theorem enstrophy_smul (N : ℕ) (w : ℕ → ℝ) (u : ℝ → ℕ → ℝ) (c t : ℝ) :
    enstrophy N w (fun s n => c * u s n) t = c ^ 2 * enstrophy N w u t := by
  unfold enstrophy
  rw [Finset.mul_sum]
  refine Finset.sum_congr rfl ?_
  intro n _
  ring

/-- **Unboundedness along the dilation orbit.** If some state has strictly positive enstrophy,
then for every proposed bound `C` there is a rescaling of that state whose enstrophy exceeds
`C`. Explicit witness: `c = max 1 ((C + 1) / enstrophy N w u t)`. -/
theorem enstrophy_unbounded_under_scaling (N : ℕ) (w : ℕ → ℝ) (u : ℝ → ℕ → ℝ) (t : ℝ)
    (hpos : 0 < enstrophy N w u t) (C : ℝ) :
    ∃ c : ℝ, C < enstrophy N w (fun s n => c * u s n) t := by
  set E := enstrophy N w u t with hE
  refine ⟨max 1 ((C + 1) / E), ?_⟩
  rw [enstrophy_smul]
  set m : ℝ := max 1 ((C + 1) / E) with hm
  have h1 : (1 : ℝ) ≤ m := le_max_left _ _
  have h2 : (C + 1) / E ≤ m := le_max_right _ _
  have h3 : C + 1 ≤ m * E := by
    rw [div_le_iff₀ hpos] at h2
    linarith
  have hmpos : (0 : ℝ) < m := lt_of_lt_of_le one_pos h1
  have h4 : (0 : ℝ) ≤ (m - 1) * (m * E) :=
    mul_nonneg (by linarith) (le_of_lt (mul_pos hmpos hpos))
  nlinarith [h3, h4]

/-- **The old statement is false.** Dropping the equation and the initial datum — i.e.
quantifying over *all* fields `u`, which is exactly what `TruncatedFlow` did in the prior tree
(REVIEW-2026-08-12, finding L3) — yields a statement with no upper bound at all, as soon as a
single retained mode carries positive weight. -/
theorem unconstrained_bound_false (N : ℕ) (w : ℕ → ℝ) (t : ℝ) (hw : 0 < w 0) :
    ¬ ∃ C : ℝ, ∀ u : ℝ → ℕ → ℝ, enstrophy N w u t ≤ C := by
  rintro ⟨C, hC⟩
  have hbase : enstrophy N w (fun _ n => if n = 0 then (1 : ℝ) else 0) t = w 0 := by
    unfold enstrophy
    rw [Finset.sum_eq_single (0 : ℕ)]
    · norm_num
    · intro b _ hb
      simp [hb]
    · intro hcontra
      exact absurd (Finset.mem_range.mpr (Nat.succ_pos N)) hcontra
  obtain ⟨c, hc⟩ :=
    enstrophy_unbounded_under_scaling N w (fun _ n => if n = 0 then (1 : ℝ) else 0) t
      (by rw [hbase]; exact hw) C
  exact absurd (hC _) (not_le.mpr hc)

/-! ## 4. Axiom-footprint gate (SPEC §5.1 / PLAN.md §2)

Every theorem in this file must report exactly `[propext, Classical.choice, Quot.sound]`.

**Negative controls run on 2026-08-12** (PLAN.md §2 "a checker that cannot fail is not a
checker"). Three perturbed copies of this file were compiled in a scratch directory; each was
required to FAIL, and each did. Recorded here so the audit can reproduce them:

| # | perturbation | observed failure |
|---|---|---|
| NC1 | `enstrophy_smul` exponent `c ^ 2` → `c ^ 3` | `error: unsolved goals ⊢ w n * c ^ 2 * u t n ^ 2 = w n * c ^ 3 * u t n ^ 2`; footprint of `enstrophy_smul` becomes `[propext, sorryAx, Classical.choice, Quot.sound]` |
| NC2 | hypothesis `hB : ∀ n, B n 0 = 0` deleted from `zero_isGalerkinSolution` | `error: unsolved goals ⊢ (B n fun x => 0) = 0`; footprint of `zero_isGalerkinSolution` becomes `[propext, sorryAx, …]` |
| NC3 | side condition `hw : 0 < w 0` deleted from `unconstrained_bound_false` | `error: unsolved goals ⊢ 0 < w 0`; footprint of `unconstrained_bound_false` becomes `[propext, sorryAx, …]` |

NC1 checks that the scaling law is the *actual* degree of homogeneity and not an artifact of a
tactic that would close anything. NC2 checks that the inhabitation witness genuinely needs the
interaction term to vanish at the zero state (it is not a free lunch). NC3 checks that the
refutation of the unconstrained statement is not vacuous: it really needs one retained mode to
carry positive weight. -/

#print axioms truncate_zero
#print axioms zero_isGalerkinSolution
#print axioms dyadicWeight_pos
#print axioms enstrophy_nonneg
#print axioms enstrophy_nonneg_dyadic
#print axioms enstrophy_zero
#print axioms enstrophy_smul
#print axioms enstrophy_unbounded_under_scaling
#print axioms unconstrained_bound_false
#print axioms shellB_zero
#print axioms sum_mul_shellB
#print axioms shellB_energy_conservation
#print axioms galerkin_shellB_conservation
#print axioms dissipationWeight_pos
#print axioms dissipationWeight_one
#print axioms dyadicShellHypothesisU_alpha_one

end MechanicaFluidorum
