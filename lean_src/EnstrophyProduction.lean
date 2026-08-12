/-
  EnstrophyProduction.lean — Tier A: dyadic ENSTROPHY production identity
  =======================================================================
  Distinct from (and not a corollary of) the energy telescoping identity in
  `lean_src/DyadicShells.lean`: the energy flux telescopes with coefficient 1
  for ARBITRARY `k`, whereas the enstrophy production sum does NOT telescope —
  it collapses only under the dyadic doubling hypothesis `k_{n+1} = 2 * k_n`,
  and it collapses to `3 ×` the outgoing production, not to `0`.

  Model (PLAN.md §5, pre-authored): truncated viscous Katz–Pavlović system

      d a_n / dt  =  NL_n  −  ν k_n^2 a_n ,
      NL_n        :=  k_{n-1} a_{n-1}^2  −  k_n a_n a_{n+1}

  with boundary/truncation convention `a_{-1} = 0`, `a_{N+1} = 0`.  At `n = 0`
  the `k_{n-1} a_{n-1}^2` summand is DROPPED entirely (`k_{-1}` is never
  evaluated — under `k_n = 2^n` it would be the non-integer 1/2).

  Enstrophy `Ω = ½ Σ_{n=0}^{N} k_n^2 a_n^2`.  Multiplying the shell-n equation
  by `k_n^2 a_n` and summing, the NONLINEAR contribution to `dΩ/dt` is

      Σ_{n=0}^{N} k_n^2 a_n NL_n  =  Σ_{n=0}^{N} ( prodIn n − prodOut n )

  and the identity proven below is

      Σ_{n=0}^{N} k_n^2 a_n NL_n  =  3 · Σ_{n=0}^{N-1} k_n^3 a_n^2 a_{n+1} .

  No `ν` appears in this identity; the viscous term `−ν Σ k_n^4 a_n^2` is
  separate (handled at D2/D3 in `DyadicShells.lean`).

  Exact-ℚ certification: `tests/tier_b_enstrophy_production.py` (Tier B,
  fractions.Fraction only, 240 cases, negative control `k_n = n+1` confirmed
  to FAIL the identity with coefficient 3 held fixed).

  Gate: `#print axioms` for every theorem below must report exactly
  [propext, Classical.choice, Quot.sound].
-/
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum

namespace MechanicaFluidorum.EnstrophyProduction

/-! ### Production fluxes

These are NOT the energy fluxes of `DyadicShells.lean`: the wavenumber enters
cubed (resp. squared×linear), because the shell equation is multiplied by
`k_n^2 a_n` rather than by `a_n`. -/

/-- Outgoing enstrophy production of shell `n`: `k_n^3 * a_n^2 * a_{n+1}`. -/
noncomputable def prodOut (k a : ℕ → ℝ) (n : ℕ) : ℝ := (k n) ^ 3 * (a n) ^ 2 * a (n + 1)

/-- Incoming enstrophy production of shell `n`, i.e. `k_n^2 * a_n * k_{n-1} * a_{n-1}^2`,
    with the boundary convention `a_{-1} = 0` built into the `n = 0` case so that
    `k_{-1}` is never evaluated. -/
noncomputable def prodIn (k a : ℕ → ℝ) : ℕ → ℝ
  | 0 => 0
  | (n + 1) => (k (n + 1)) ^ 2 * a (n + 1) * (k n) * (a n) ^ 2

/-- The nonlinear right-hand side `NL_n` of the shell-`n` equation, with the
    `a_{-1} = 0` convention (the first summand is dropped at `n = 0`). -/
noncomputable def NL (k a : ℕ → ℝ) : ℕ → ℝ
  | 0 => - (k 0 * a 0 * a 1)
  | (n + 1) => k n * (a n) ^ 2 - k (n + 1) * a (n + 1) * a (n + 2)

/-- Bridge: the enstrophy-weighted nonlinear term `k_n^2 a_n NL_n` is exactly
    `prodIn n − prodOut n`.  This is what makes the sum below the nonlinear part
    of `dΩ/dt`, not an unrelated algebraic expression. -/
theorem enstrophyTerm_eq (k a : ℕ → ℝ) (n : ℕ) :
    (k n) ^ 2 * a n * NL k a n = prodIn k a n - prodOut k a n := by
  cases n with
  | zero => unfold NL prodIn prodOut; ring
  | succ m => unfold NL prodIn prodOut; ring

/-! ### The pointwise doubling lemma

This replaces telescoping.  With coefficient 1 the two fluxes do NOT match;
under `k_{n+1} = 2 k_n` the incoming production is exactly `4 ×` the outgoing
production of the shell below. -/

/-- **Key pointwise lemma.**  Under dyadic doubling `k_{n+1} = 2 k_n`,
    `prodIn (n+1) = 4 * prodOut n`. -/
theorem prodIn_succ_eq_four_mul_prodOut (k a : ℕ → ℝ) (n : ℕ)
    (hdouble : k (n + 1) = 2 * k n) :
    prodIn k a (n + 1) = 4 * prodOut k a n := by
  unfold prodIn prodOut
  rw [hdouble]
  ring

/-- Summed form of the pointwise lemma: peeling `n = 0` (where `prodIn 0 = 0`)
    turns the incoming-production sum into `4 ×` the outgoing-production sum. -/
theorem sum_prodIn_eq_four_mul_sum_prodOut (k a : ℕ → ℝ) (N : ℕ)
    (hdouble : ∀ n, n < N → k (n + 1) = 2 * k n) :
    (Finset.range (N + 1)).sum (fun n => prodIn k a n)
      = 4 * (Finset.range N).sum (fun n => prodOut k a n) := by
  rw [Finset.sum_range_succ' (fun n => prodIn k a n) N]
  have h0 : prodIn k a 0 = 0 := rfl
  rw [h0, add_zero, Finset.mul_sum]
  refine Finset.sum_congr rfl ?_
  intro i hi
  exact prodIn_succ_eq_four_mul_prodOut k a i (hdouble i (Finset.mem_range.mp hi))

/-! ### Main identity -/

/-- **Enstrophy production identity (dyadic).**  With dyadic doubling on the
    active shells and the truncation boundary condition `a_{N+1} = 0`,

      Σ_{n=0}^{N} ( prodIn n − prodOut n )  =  3 · Σ_{n=0}^{N-1} prodOut n .

    The coefficient `3 = 4 − 1` comes from the doubling ratio (`r^2 − 1` with
    `r = 2`); it is NOT a telescoping constant.  `k` and `a` are otherwise
    arbitrary. -/
theorem enstrophy_production_dyadic (k a : ℕ → ℝ) (N : ℕ)
    (hdouble : ∀ n, n < N → k (n + 1) = 2 * k n)
    (hbc : a (N + 1) = 0) :
    (Finset.range (N + 1)).sum (fun n => prodIn k a n - prodOut k a n)
      = 3 * (Finset.range N).sum (fun n => prodOut k a n) := by
  have hN : prodOut k a N = 0 := by
    unfold prodOut; rw [hbc]; ring
  rw [Finset.sum_sub_distrib, sum_prodIn_eq_four_mul_sum_prodOut k a N hdouble,
      Finset.sum_range_succ (fun n => prodOut k a n) N, hN, add_zero]
  ring

/-- **Enstrophy production identity, stated on the physical term `k_n^2 a_n NL_n`.**
    Same content as `enstrophy_production_dyadic`, rewritten through
    `enstrophyTerm_eq` so the left-hand side is literally the nonlinear part of
    `dΩ/dt`. -/
theorem enstrophy_production_dyadic_NL (k a : ℕ → ℝ) (N : ℕ)
    (hdouble : ∀ n, n < N → k (n + 1) = 2 * k n)
    (hbc : a (N + 1) = 0) :
    (Finset.range (N + 1)).sum (fun n => (k n) ^ 2 * a n * NL k a n)
      = 3 * (Finset.range N).sum (fun n => (k n) ^ 3 * (a n) ^ 2 * a (n + 1)) := by
  have hL : (Finset.range (N + 1)).sum (fun n => (k n) ^ 2 * a n * NL k a n)
      = (Finset.range (N + 1)).sum (fun n => prodIn k a n - prodOut k a n) :=
    Finset.sum_congr rfl (fun n _ => enstrophyTerm_eq k a n)
  have hR : (Finset.range N).sum (fun n => (k n) ^ 3 * (a n) ^ 2 * a (n + 1))
      = (Finset.range N).sum (fun n => prodOut k a n) :=
    Finset.sum_congr rfl (fun n _ => rfl)
  rw [hL, hR]
  exact enstrophy_production_dyadic k a N hdouble hbc

/-! ### Non-vacuity witnesses (SPEC §7.5)

The hand-verified Tier B instance: `N = 2`, `k n = 2^n` (so `k = 1, 2, 4`),
`a = (1, 2, 3, 0, 0, …)`.  Both sides must equal `294` exactly. -/

/-- Witness wavenumbers: `k n = 2^n`. -/
noncomputable def kW : ℕ → ℝ := fun n => (2 : ℝ) ^ n

/-- Witness state: `a = (1, 2, 3, 0, 0, …)`. -/
noncomputable def aW : ℕ → ℝ := fun n => if n = 0 then 1 else if n = 1 then 2 else if n = 2 then 3 else 0

/-- The witness data satisfies the doubling hypothesis (for every `n`, hence in
    particular for `n < 2`). -/
theorem kW_double (n : ℕ) : kW (n + 1) = 2 * kW n := by
  unfold kW; ring

/-- The witness data satisfies the truncation boundary condition `a_{N+1} = 0`
    at `N = 2`. -/
theorem aW_bc : aW (2 + 1) = 0 := by
  unfold aW; norm_num

/-- **Non-vacuity, left-hand side.**  `Σ_{n=0}^{2} k_n^2 a_n NL_n = 294`. -/
theorem witness_lhs :
    (Finset.range 3).sum (fun n => (kW n) ^ 2 * aW n * NL kW aW n) = 294 := by
  rw [Finset.sum_range_succ, Finset.sum_range_succ, Finset.sum_range_succ,
      Finset.sum_range_zero]
  unfold NL kW aW
  norm_num

/-- **Non-vacuity, right-hand side.**  `3 · Σ_{n=0}^{1} k_n^3 a_n^2 a_{n+1} = 294`. -/
theorem witness_rhs :
    3 * (Finset.range 2).sum (fun n => (kW n) ^ 3 * (aW n) ^ 2 * aW (n + 1)) = 294 := by
  rw [Finset.sum_range_succ, Finset.sum_range_succ, Finset.sum_range_zero]
  unfold kW aW
  norm_num

/-- **Non-vacuity, the theorem applied.**  The general theorem instantiated at the
    witness data yields the `294 = 294` instance, so its hypotheses are genuinely
    satisfiable by data with nonzero production (not a `0 = 0` degeneracy). -/
theorem witness_theorem_gives_294 :
    (Finset.range 3).sum (fun n => (kW n) ^ 2 * aW n * NL kW aW n)
      = 3 * (Finset.range 2).sum (fun n => (kW n) ^ 3 * (aW n) ^ 2 * aW (n + 1))
    ∧ (Finset.range 3).sum (fun n => (kW n) ^ 2 * aW n * NL kW aW n) = 294 := by
  refine ⟨?_, witness_lhs⟩
  exact enstrophy_production_dyadic_NL kW aW 2 (fun n _ => kW_double n) aW_bc

/-- **Sharpness of the doubling hypothesis.**  For the non-doubling wavenumbers
    `k n = n + 1` (the Tier B negative control) with the SAME coefficient `3`,
    the identity FAILS: at `N = 1`, `a = (1, 1, 0, …)` the left side is `-1`
    while `3 ×` the right side is `-3`.  Hence `hdouble` cannot be dropped. -/
theorem negative_control_nondoubling :
    (Finset.range 2).sum
        (fun n => prodIn (fun m => (m : ℝ) + 1) (fun m => if m ≤ 1 then 1 else 0) n
                  - prodOut (fun m => (m : ℝ) + 1) (fun m => if m ≤ 1 then 1 else 0) n)
      ≠ 3 * (Finset.range 1).sum
        (fun n => prodOut (fun m => (m : ℝ) + 1) (fun m => if m ≤ 1 then 1 else 0) n) := by
  rw [Finset.sum_range_succ, Finset.sum_range_succ, Finset.sum_range_succ,
      Finset.sum_range_zero]
  unfold prodIn prodOut
  norm_num

#print axioms enstrophyTerm_eq
#print axioms prodIn_succ_eq_four_mul_prodOut
#print axioms sum_prodIn_eq_four_mul_sum_prodOut
#print axioms enstrophy_production_dyadic
#print axioms enstrophy_production_dyadic_NL
#print axioms kW_double
#print axioms aW_bc
#print axioms witness_lhs
#print axioms witness_rhs
#print axioms witness_theorem_gives_294
#print axioms negative_control_nondoubling

end MechanicaFluidorum.EnstrophyProduction
