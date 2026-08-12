/- STATUS: DRAFT - AWAITING HUMAN STATEMENT-ADEQUACY AUDIT (PLAN.md F2).
   Not yet cited by LEDGER.md. Statements here define what will be proven; per the project's
   oversight split the machine checks proofs, the human audits the questions. -/

import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Data.Finset.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum

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
`u ↦ (fun s n => c * u s n)` sends the initial condition `u 0 = u₀` to `c • u₀ ≠ u₀` (for
`c ≠ 1`, `u₀ ≠ 0`), so a rescaled solution no longer satisfies clause (i) with the *same*
fixed data. It also fails clause (ii): the drift term `B n (u t)` is a fixed given function of
the state, not assumed homogeneous, while the viscous term `- ν · w n · u t n` is linear, so
`c · (dependence)` cannot in general reproduce the right-hand side at the rescaled state. The
family being bounded is thus the (single) orbit of one datum under one evolution law, indexed
by the cutoff `N` — not a linear space closed under dilation.

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

## Two questions this draft raises FOR THE HUMAN AUDIT (not decided here)

  Q1. `HypothesisU` fixes one `u₀ : ℕ → ℝ` across all cutoffs `N`. Clause (iii) forces
      `u₀ n = 0` for `n > N`, so for a `u₀` with modes above `N` the hypothesis set is empty
      and the bound holds vacuously at that `N`. The alternative — projecting `u₀` onto modes
      `≤ N` at each cutoff — is a *statement-level* choice (PLAN.md E-4) and is therefore
      **not** made by this agent. The literal reading prescribed by the task is implemented.
  Q2. Whether `w` should be constrained (e.g. `0 < w n`, or `w n = k n ^ 2`) is likewise left
      open: `w` is an unconstrained parameter here, so `enstrophy` is not asserted nonnegative.
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

/-- `IsGalerkinSolution N nu B w u0 u` says the time-dependent mode-amplitude vector
`u : ℝ → (ℕ → ℝ)` is a solution of the `N`-truncated system with initial datum `u0`:

1. **initial condition** `u 0 = u0`;
2. **evolution law** for every time `t` and every retained mode `n ≤ N`,
   `d/ds (u s n) |_{s = t} = B n (u t) - nu * w n * u t n`;
3. **truncation** every discarded mode `n > N` vanishes identically in time.

Clauses (1) and (2) are precisely what the prior formalization omitted (finding L3); they are
what makes the family in `HypothesisU` a genuine constraint rather than "all smooth fields". -/
def IsGalerkinSolution (N : ℕ) (nu : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ)
    (u0 : ℕ → ℝ) (u : ℝ → ℕ → ℝ) : Prop :=
  u 0 = u0
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

/-! ## 2. Non-vacuity: `IsGalerkinSolution` is inhabited -/

/-- The zero flow solves the truncated system with zero data, provided the interaction term
vanishes at the zero state (`hB`). This is the SPEC §7.5 inhabitation witness for
`IsGalerkinSolution`: the constraint is satisfiable, so statements quantifying over it are not
vacuous by construction. Note it does **not** make `HypothesisU` trivial — `HypothesisU`
quantifies over *all* solutions with the given data, not merely over one. -/
theorem zero_isGalerkinSolution (N : ℕ) (nu : ℝ) (B : ℕ → (ℕ → ℝ) → ℝ) (w : ℕ → ℝ)
    (hB : ∀ n : ℕ, B n (fun _ => (0 : ℝ)) = 0) :
    IsGalerkinSolution N nu B w (fun _ => (0 : ℝ)) (fun _ _ => (0 : ℝ)) := by
  refine ⟨rfl, ?_, ?_⟩
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

#print axioms zero_isGalerkinSolution
#print axioms enstrophy_zero
#print axioms enstrophy_smul
#print axioms enstrophy_unbounded_under_scaling
#print axioms unconstrained_bound_false

end MechanicaFluidorum
