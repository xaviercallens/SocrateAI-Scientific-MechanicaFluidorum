/-
=============================================================================
FourierDynamicsZ3.lean — OP-6b (first slice): the Leray-projected bilinear
operator B(u,v) on the Galerkin ball, and the energy-conservation STATEMENT
=============================================================================
Status  : DRAFT, Tier A target for the theorems below; the energy identity is
          posed as a `Prop` (statement level, SPEC §7.2 / §7.5), NOT as a
          theorem with `sorry` — a `sorry`'d theorem would define the name and
          pollute every downstream `#print axioms` with `sorryAx`.
Scope   : DYNAMICS, first slice. Defines
            ball M          — the Galerkin index set as a Finset,
            convective M u v k = −i Σ_{p ∈ ball M} ((k−p)·u_p) v_{k−p},
            B M u v k        = P(k)[convective M u v k],
          and proves (i) transversality of B, (ii) the triad-support property
          `htriad` that `FourierStateZ3.sublattice_invariance` takes as a
          hypothesis — so the sublattice theorem now applies to a CONCRETE B,
          which is the first half of audit flag F1 (the second half, a witness
          that B is not identically zero, is still owed and is flagged below).
Formula : the convective term is the CORRECTED Tier B formula of
          tests/tier_b_nse_triad_convolution.py, `N(u)_k = −i Σ P(k)[(q·u_p) u_q]`
          (q dotted with u_p, times the vector u_q). The variant with q·(u_p·u_q)
          is identically zero (erratum recorded there) and is NOT used.
Owner memorandum 2026-09-09, Task 2.1 asks for exactly this operator.
Flags for the human audit (not resolved here):
  F1' — non-vacuity witness `B ≠ 0` not yet supplied (see §5).
  F4  — `ball M` uses the cube-then-filter construction; `GalerkinState.cutoff`
        uses `M² < k_sq k → u k = 0`. These agree (k ∈ ball M ↔ k_sq k ≤ M² for
        k in the cube; and k_sq k ≤ M² forces |k_i| ≤ M), but the equivalence
        is not proved here.
=============================================================================
-/

import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.Group.Subgroup.Basic
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Int.Interval
import Mathlib.Tactic.Abel
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import FourierStateZ3

set_option autoImplicit false

namespace MechanicaFluidorum.FourierZ3

open ComplexConjugate

/-! ### 1. The Galerkin ball as a finite index set -/

/-- `Λ_M = {k ∈ ℤ³ : |k|² ≤ M²}` as a `Finset` (the zero mode is included; every
field of interest vanishes there by `FourierState.zero_mean`). -/
def ball (M : ℕ) : Finset Wavevector :=
  (Fintype.piFinset fun _ : Fin 3 => Finset.Icc (-(M : ℤ)) (M : ℤ)).filter
    (fun k => k_sq k ≤ (M : ℤ) ^ 2)

theorem k_sq_le_of_mem_ball {M : ℕ} {k : Wavevector} (hk : k ∈ ball M) :
    k_sq k ≤ (M : ℤ) ^ 2 :=
  (Finset.mem_filter.mp hk).2

/-- Non-vacuity of the index set (SPEC §7.5): the witness mode lies in the unit ball. -/
theorem k0_mem_ball_one : k0 ∈ ball 1 := by
  rw [ball, Finset.mem_filter, Fintype.mem_piFinset]
  refine ⟨fun i => ?_, by rw [k_sq_k0]; norm_num⟩
  rw [Finset.mem_Icc]
  fin_cases i <;> simp [k0, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons,
    Matrix.cons_val_two, Matrix.tail_cons]

/-! ### 2. The convective term and the projected bilinear operator -/

/-- `convective M u v k = −i Σ_{p ∈ Λ_M} ((k−p)·u_p) · v_{k−p}`, componentwise. -/
noncomputable def convective (M : ℕ) (u v : Wavevector → Fin 3 → ℂ) (k : Wavevector) :
    Fin 3 → ℂ :=
  fun i => ∑ p ∈ ball M, (-Complex.I) * fourier_dot (k - p) (u p) * v (k - p) i

/-- **The operator of Task 2.1:** `B(u,v)_k = P(k)[ −i Σ_{p+q=k} (q·u_p) v_q ]`. -/
noncomputable def B (M : ℕ) (u v : Wavevector → Fin 3 → ℂ) (k : Wavevector) : Fin 3 → ℂ :=
  applyLeray k (convective M u v k)

/-! ### 3. Transversality — inherited from the projector (DoD-1 of OP-6a) -/

/-- `k · B(u,v)_k = 0` for every `k`, every `u`, every `v` (Fact 1 of the Tier B harness). -/
theorem B_div_free (M : ℕ) (u v : Wavevector → Fin 3 → ℂ) (k : Wavevector) :
    fourier_dot k (B M u v k) = 0 :=
  applyLeray_div_free k _

/-! ### 4. Triad support — `B` satisfies the `htriad` hypothesis of `sublattice_invariance` -/

theorem convective_eq_zero_of_triad (M : ℕ) (u v : Wavevector → Fin 3 → ℂ) (k : Wavevector)
    (h : ∀ p q : Wavevector, p + q = k → u p = 0 ∨ v q = 0) :
    convective M u v k = 0 := by
  funext i
  unfold convective
  apply Finset.sum_eq_zero
  intro p _
  have hpq : p + (k - p) = k := by ext j; simp
  rcases h p (k - p) hpq with hu | hv
  · rw [hu]
    unfold fourier_dot
    simp
  · rw [hv]
    simp

/-- The triad-support property: if every pair `p + q = k` has `u_p = 0` or `v_q = 0`,
then `B(u,v)_k = 0`. This is exactly the hypothesis `htriad` of
`FourierStateZ3.sublattice_invariance`. -/
theorem B_triad (M : ℕ) (u v : Wavevector → Fin 3 → ℂ) (k : Wavevector)
    (h : ∀ p q : Wavevector, p + q = k → u p = 0 ∨ v q = 0) :
    B M u v k = 0 := by
  unfold B
  rw [convective_eq_zero_of_triad M u v k h, applyLeray_zero]

/-- Sublattice invariance, now for the CONCRETE operator: inputs supported in an additive
subgroup `Λ` give an output supported in `Λ`. (First half of audit flag F1.) -/
theorem B_sublattice_invariance (M : ℕ) (Λ : AddSubgroup (Fin 3 → ℤ))
    (u v : Wavevector → Fin 3 → ℂ)
    (hu : ∀ p, p ∉ Λ → u p = 0) (hv : ∀ q, q ∉ Λ → v q = 0)
    {k : Wavevector} (hk : k ∉ Λ) :
    B M u v k = 0 :=
  sublattice_invariance Λ (B M) (fun u v k h => B_triad M u v k h) u v hu hv hk

/-! ### 5. The energy identity — posed, not proved

`⟨B(u,u), u⟩ = 0` is the Fourier-Galerkin form of `b(u,u,u) = 0`. The Tier B harness certifies
it computationally at `M ∈ {1,2,3}` (fact 2) and records that a symbolic proof of the general
triad identity did not close there. It is therefore posed here as a `Prop`, with its quantifier
domain shown inhabited, and NOT asserted. Proving it is Task 2.2. -/

/-- Hermitian pairing on amplitudes. -/
noncomputable def pairing (a b : Fin 3 → ℂ) : ℂ := ∑ i : Fin 3, conj (a i) * b i

/-- **Task 2.2, statement level.** For every Galerkin state on the ball of radius `M`, the real
part of `Σ_k ⟨u_k, B(u,u)_k⟩` vanishes. -/
def EnergyConservationStatement (M : ℕ) : Prop :=
  ∀ s : GalerkinState M,
    (∑ k ∈ ball M, pairing (s.toFourierState.u k) (B M s.toFourierState.u s.toFourierState.u k)).re = 0

/-- The quantifier domain of the statement is inhabited (no vacuous universal). -/
noncomputable example : GalerkinState 1 := pairGalerkin

/-! F1' — STILL OWED: a witness `u, v, k` with `B M u v k ≠ 0`. Hand computation (to be
formalised): with `u` the pair state at `k₀ = (1,0,0)` with amplitude `(0,1,0)` and `v` the pair
state at `(0,1,0)` with amplitude `(1,0,0)`, the term `p = k₀, q = (0,1,0)` gives
`(q·u_p) = 1` and `v_q = (1,0,0)`, so `convective` at `k = (1,1,0)` is `−i(1,0,0)` plus the
mirror term, and `P(k)` maps `(1,0,0)` to `(½,−½,0) ≠ 0`. Not proved here. -/

/-! ### Audit certificates — expected on every line: no axiom outside
[propext, Classical.choice, Quot.sound]. -/
#print axioms k0_mem_ball_one
#print axioms B_div_free
#print axioms B_triad
#print axioms B_sublattice_invariance

end MechanicaFluidorum.FourierZ3
