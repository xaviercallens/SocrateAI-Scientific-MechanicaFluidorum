/-
  DyadicShells.lean — Tier A: dyadic energy-flux telescoping + monotonicity
  ========================================================================
  Tasks D2 (telescoping identity) and D3 (energy monotonicity corollary).

  Model (PLAN.md §5, pre-authored): truncated viscous Katz–Pavlović system

      d a_n / dt  =  k_{n-1} a_{n-1}^2  −  k_n a_n a_{n+1}  −  ν k_n^2 a_n

  with boundary convention a_{-1} = 0.  Multiplying by a_n, the nonlinear
  contribution to dE/dt = d(½ Σ a_n^2)/dt is

      a_n k_{n-1} a_{n-1}^2  −  a_n k_n a_n a_{n+1}
        =  outFlux (n-1)  −  outFlux n
        =  inFlux n       −  inFlux (n+1)

  where `outFlux n = k n * (a n)^2 * a (n+1)` and `inFlux` carries the
  a_{-1} = 0 convention in its zero case.  The sum therefore telescopes.

  Generality note: `k` and `a` are ARBITRARY functions ℕ → ℝ.  The identity
  is purely algebraic, so it is proven here for every coefficient sequence,
  not only for k n = 2^n.  This is strictly stronger than the dyadic case.

  The corresponding exact-ℚ certification is `tests/tier_b_dyadic_checks.py`
  (Tier B, fractions.Fraction only, negative control confirmed to fail).

  Gate: `#print axioms` for every theorem below must report exactly
  [propext, Classical.choice, Quot.sound].
-/
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum

namespace MechanicaFluidorum.DyadicShells

/-! ### Shell fluxes -/

/-- Outgoing energy flux from shell `n`: `k n * (a n)^2 * a (n+1)`. -/
noncomputable def outFlux (k a : ℕ → ℝ) (n : ℕ) : ℝ := k n * (a n) ^ 2 * a (n + 1)

/-- Incoming energy flux to shell `n`, with the boundary convention
    `a_{-1} = 0` built into the `n = 0` case.  By construction
    `inFlux k a (n+1) = outFlux k a n` definitionally. -/
noncomputable def inFlux (k a : ℕ → ℝ) : ℕ → ℝ
  | 0 => 0
  | (n + 1) => outFlux k a n

/-! ### D2 — the telescoping identity -/

/-- **D2.** The net nonlinear energy flux over shells `0 … N` telescopes to
    minus the outgoing flux of the last shell. -/
theorem dyadic_flux_telescopes (k a : ℕ → ℝ) (N : ℕ) :
    (Finset.range (N + 1)).sum (fun n => inFlux k a n - inFlux k a (n + 1))
      = - outFlux k a N := by
  rw [Finset.sum_range_sub' (fun n => inFlux k a n) (N + 1)]
  simp [inFlux]

/-- **D2 (boundary form).** With the truncation convention `a_{N+1} = 0`
    the net nonlinear energy flux vanishes identically. -/
theorem dyadic_flux_zero_of_boundary (k a : ℕ → ℝ) (N : ℕ)
    (hbc : a (N + 1) = 0) :
    (Finset.range (N + 1)).sum (fun n => inFlux k a n - inFlux k a (n + 1)) = 0 := by
  rw [dyadic_flux_telescopes k a N, outFlux, hbc]
  ring

/-! ### D3 — energy monotonicity -/

/-- Full energy rate `dE/dt` of the truncated system: telescoping nonlinear
    flux minus the viscous dissipation `ν k_n^2 a_n^2`. -/
noncomputable def energyRate (k a : ℕ → ℝ) (nu : ℝ) (N : ℕ) : ℝ :=
  (Finset.range (N + 1)).sum (fun n => (inFlux k a n - inFlux k a (n + 1))
                                        - nu * (k n) ^ 2 * (a n) ^ 2)

/-- **D3.** For nonnegative viscosity and the truncation boundary condition,
    the energy rate is nonpositive: `dE/dt ≤ 0`. -/
theorem energyRate_nonpos (k a : ℕ → ℝ) (nu : ℝ) (N : ℕ)
    (hbc : a (N + 1) = 0) (hnu : 0 ≤ nu) :
    energyRate k a nu N ≤ 0 := by
  have hsplit : energyRate k a nu N
      = (Finset.range (N + 1)).sum (fun n => inFlux k a n - inFlux k a (n + 1))
        - (Finset.range (N + 1)).sum (fun n => nu * (k n) ^ 2 * (a n) ^ 2) := by
    rw [energyRate, Finset.sum_sub_distrib]
  have hvisc : 0 ≤ (Finset.range (N + 1)).sum (fun n => nu * (k n) ^ 2 * (a n) ^ 2) := by
    refine Finset.sum_nonneg ?_
    intro i _
    exact mul_nonneg (mul_nonneg hnu (sq_nonneg _)) (sq_nonneg _)
  rw [hsplit, dyadic_flux_zero_of_boundary k a N hbc]
  linarith

/-! ### Non-vacuity witnesses (SPEC §7.5) -/

/-- Witness 1: the flux definitions compute as intended — the boundary case
    `inFlux 0 = 0` and the shift `inFlux (n+1) = outFlux n` hold by `rfl`. -/
example (k a : ℕ → ℝ) (n : ℕ) :
    inFlux k a 0 = 0 ∧ inFlux k a (n + 1) = k n * (a n) ^ 2 * a (n + 1) :=
  ⟨rfl, rfl⟩

/-- Witness 2: a concrete instance where the hypotheses of `energyRate_nonpos`
    genuinely hold — dyadic wavenumbers `k n = 2^n`, single excited shell
    `a = (1, 0, 0, …)`, `ν = 1`, `N = 0`.  Here `a (N+1) = a 1 = 0`. -/
example :
    energyRate (fun n => (2 : ℝ) ^ n) (fun n => if n = 0 then (1 : ℝ) else 0) 1 0 ≤ 0 :=
  energyRate_nonpos _ _ 1 0 (by norm_num) (by norm_num)

/-- Witness 3: the conclusion of Witness 2 is NOT vacuous — the energy rate
    for that data equals `-1`, strictly negative, so `energyRate_nonpos` is
    not merely asserting `0 ≤ 0`. -/
example :
    energyRate (fun n => (2 : ℝ) ^ n) (fun n => if n = 0 then (1 : ℝ) else 0) 1 0 = -1 := by
  simp [energyRate, inFlux, outFlux]

#print axioms dyadic_flux_telescopes
#print axioms dyadic_flux_zero_of_boundary
#print axioms energyRate_nonpos

end MechanicaFluidorum.DyadicShells
