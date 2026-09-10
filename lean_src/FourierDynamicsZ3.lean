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
          hypothesis — so the sublattice theorem applies to a CONCRETE B — and
          (iii) an explicit witness that this B is NOT the zero map, which is
          what makes that invariance statement non-vacuous.
          §7 opens Task 2.2: the `swap3`-closed index set, step 1 of 5 of
          `docs/designs/TASK22_ENERGY_IDENTITY.md`.
Formula : the convective term is the CORRECTED Tier B formula of
          tests/tier_b_nse_triad_convolution.py, `N(u)_k = −i Σ P(k)[(q·u_p) u_q]`
          (q dotted with u_p, times the vector u_q). The variant with q·(u_p·u_q)
          is identically zero (erratum recorded there) and is NOT used.
Owner memorandum 2026-09-09, Task 2.1 asks for exactly this operator.
Audit flags — BOTH CLOSED 2026-09-10:
  F1' — a witness that `B` is not identically zero. Closed by `B_witness_ne_zero`
        and `B_not_identically_zero` (§6).
  F4  — `ball M` is cube-then-filter while `GalerkinState.cutoff` is stated with
        `M² < k_sq k`. Closed by `mem_ball_iff`: the cube is IMPLIED, since each
        `(k_i)²` is one non-negative term of `k_sq k`.
Still owed on this file: steps 2–5 of Task 2.2 (the Leray drop, the reindexing
bijection, the out-of-ball vanishing, and the assembly).
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
import Mathlib.Tactic.Linarith
import FourierStateZ3
import AbstractAlgebraicConservation

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

/-- **Audit flag F4, closed.** `ball M` is built as cube-then-filter, while
`GalerkinState.cutoff` is stated as `M² < k_sq k → u k = 0`. The two descriptions agree, and the
non-obvious direction is this one: `k_sq k ≤ M²` already forces every coordinate into `[-M, M]`,
because each `(kᵢ)²` is one non-negative term of the sum `k_sq k`. So the cube in the definition
is not an extra restriction — it is implied. -/
theorem mem_ball_iff {M : ℕ} {k : Wavevector} : k ∈ ball M ↔ k_sq k ≤ (M : ℤ) ^ 2 := by
  refine ⟨k_sq_le_of_mem_ball, fun h => ?_⟩
  rw [ball, Finset.mem_filter, Fintype.mem_piFinset]
  refine ⟨fun i => ?_, h⟩
  rw [Finset.mem_Icc]
  have hMnn : (0 : ℤ) ≤ (M : ℤ) := Int.natCast_nonneg M
  have hi : (k i) ^ 2 ≤ (M : ℤ) ^ 2 := by
    have hle : (k i) ^ 2 ≤ ∑ j : Fin 3, (k j) ^ 2 :=
      Finset.single_le_sum (f := fun j : Fin 3 => (k j) ^ 2)
        (fun j _ => sq_nonneg (k j)) (Finset.mem_univ i)
    exact le_trans hle h
  constructor
  · nlinarith [hi, hMnn, sq_nonneg (k i + (M : ℤ))]
  · nlinarith [hi, hMnn, sq_nonneg (k i - (M : ℤ))]

/-- The Galerkin cutoff, restated on `ball M`: a state's amplitude vanishes off the ball. This is
the form the Task 2.2 bridge consumes (step C: terms with `q ∉ Λ_M` carry a zero factor). -/
theorem GalerkinState.eq_zero_of_notMem_ball {M : ℕ} (s : GalerkinState M) {k : Wavevector}
    (hk : k ∉ ball M) : s.toFourierState.u k = 0 :=
  s.cutoff k (lt_of_not_ge fun hle => hk (mem_ball_iff.mpr hle))

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

/-! ### 6. Non-vacuity of `B` — audit flag F1′, now CLOSED

`sublattice_invariance` is conditional on `htriad`, which the zero map satisfies trivially, so the
theorem is true but possibly empty until some `B` both satisfies `htriad` and is *not* identically
zero. `B_triad` supplied the first half. This section supplies the second: an explicit `u`, `v`, `k`
with `B M u v k ≠ 0`. That is the LL-11 discipline applied to a theorem rather than to a
measurement — an invariance statement about nothing is not an invariance statement. -/

/-- A field supported on the single mode `p₀`, with amplitude `a`. -/
noncomputable def deltaField (p₀ : Wavevector) (a : Fin 3 → ℂ) : Wavevector → Fin 3 → ℂ :=
  fun p => if p = p₀ then a else 0

/-- On single-mode inputs the convolution collapses to its one surviving triad `p₀ + q₀ = k`. -/
theorem convective_delta {M : ℕ} (p₀ q₀ : Wavevector) (a b : Fin 3 → ℂ)
    (hp₀ : p₀ ∈ ball M) (i : Fin 3) :
    convective M (deltaField p₀ a) (deltaField q₀ b) (p₀ + q₀) i
      = (-Complex.I) * fourier_dot q₀ a * b i := by
  have hsub : p₀ + q₀ - p₀ = q₀ := by abel
  unfold convective
  rw [Finset.sum_eq_single p₀]
  · rw [hsub]
    unfold deltaField
    rw [if_pos rfl, if_pos rfl]
  · intro p _ hp
    unfold deltaField
    rw [if_neg hp]
    simp [fourier_dot]
  · intro hmem
    exact absurd hp₀ hmem

/-- The witness modes: `p₀ = (1,0,0)`, `q₀ = (0,1,0)`, so `k = p₀ + q₀ = (1,1,0)`. -/
def wq : Wavevector := ![0, 1, 0]

/-- Amplitude carried by `u` at `p₀`; chosen so that `q₀ · a = 1`. -/
noncomputable def wa : Fin 3 → ℂ := ![0, 1, 0]

/-- Amplitude carried by `v` at `q₀`; chosen transverse to neither `k` nor its complement, so the
Leray projection does not annihilate it. -/
noncomputable def wb : Fin 3 → ℂ := ![1, 0, 0]

theorem fourier_dot_wq_wa : fourier_dot wq wa = 1 := by
  norm_num [fourier_dot, wq, wa, Fin.sum_univ_three, Matrix.cons_val_zero, Matrix.cons_val_one,
    Matrix.head_cons, Matrix.cons_val_two, Matrix.tail_cons]

theorem k_sq_witness : k_sq (k0 + wq) = 2 := by
  norm_num [k_sq, k0, wq, Fin.sum_univ_three, Matrix.cons_val_zero, Matrix.cons_val_one,
    Matrix.head_cons, Matrix.cons_val_two, Matrix.tail_cons]

theorem k0_mem_ball_two : k0 ∈ ball 2 := by
  rw [ball, Finset.mem_filter, Fintype.mem_piFinset]
  refine ⟨fun i => ?_, by rw [k_sq_k0]; norm_num⟩
  rw [Finset.mem_Icc]
  fin_cases i <;> simp [k0, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons,
    Matrix.cons_val_two, Matrix.tail_cons]

/-- **F1′ — the non-vacuity witness.** `B` is not the zero map: at `k = (1,1,0)`, on single-mode
inputs, its first component is `−i/2`. Concretely `convective` returns `−i·(q₀·a)·b = −i·(1,0,0)`
and `P(k)` sends `(1,0,0)` to `(½,−½,0)`. -/
theorem B_witness_ne_zero :
    B 2 (deltaField k0 wa) (deltaField wq wb) (k0 + wq) 0 ≠ 0 := by
  have hval : B 2 (deltaField k0 wa) (deltaField wq wb) (k0 + wq) 0
      = -Complex.I / 2 := by
    unfold B applyLeray
    have hconv : ∀ j : Fin 3,
        convective 2 (deltaField k0 wa) (deltaField wq wb) (k0 + wq) j
          = (-Complex.I) * wb j := by
      intro j
      rw [convective_delta k0 wq wa wb k0_mem_ball_two j, fourier_dot_wq_wa, mul_one]
    rw [Finset.sum_congr rfl (fun j _ => by rw [hconv j])]
    unfold LerayProjector
    -- `k_sq (k0+wq)` sits under the `∑ j` binder, so rewrite it by simp (not `rw`), after which
    -- the guard `(2 : ℤ) = 0` is decidably false and the `if` collapses.
    simp only [k_sq_witness]
    norm_num [wb, k0, wq, Pi.add_apply, Fin.sum_univ_three, Matrix.cons_val_zero,
      Matrix.cons_val_one, Matrix.head_cons, Matrix.cons_val_two, Matrix.tail_cons]
    ring
  rw [hval]
  intro h
  rw [div_eq_zero_iff] at h
  rcases h with h | h
  · exact Complex.I_ne_zero (neg_eq_zero.mp h)
  · norm_num at h

/-- Therefore `sublattice_invariance` is **not** vacuous: it constrains an operator that genuinely
moves amplitude between modes. -/
theorem B_not_identically_zero :
    ∃ (M : ℕ) (u v : Wavevector → Fin 3 → ℂ) (k : Wavevector), B M u v k ≠ 0 := by
  refine ⟨2, deltaField k0 wa, deltaField wq wb, k0 + wq, ?_⟩
  intro h
  exact B_witness_ne_zero (by rw [h]; rfl)

/-! ### 7. Task 2.2, step 1 of 5 — the `swap3`-closed index set

`docs/designs/TASK22_ENERGY_IDENTITY.md` shows that Task 2.2 is not a new proof but an
instantiation of the Tier A `AbstractAlgebraicConservation.triad_sum_zero`, whose `swap3` is
exactly the two-element symmetry that proves the identity. The memo also identifies the one place
the design was at risk, and orders it FIRST: the natural index set is **not** `swap3`-closed.

Reindexing `(k, p) ↦ (p, q = k − p)` sends `Λ_M × Λ_M` to `{(p,q) : p ∈ Λ_M, −(p+q) ∈ Λ_M}`, in
which `q` is unconstrained — so `swap3 (p,q) = (p, −(p+q))` can leave it. The repair is the
Galerkin cutoff: terms with `q ∉ Λ_M` carry a factor `u_q = 0`. Restricting to the set below, in
which **all three members of the triad** lie in the ball, is therefore free, and that set closes
because its defining condition is a property of the *unordered* triad while `swap3` merely
permutes it. -/

/-- Ordered pairs whose entire triad `{p, q, −(p+q)}` lies in `Λ_M`. -/
def triadSet (M : ℕ) : Finset (Wavevector × Wavevector) :=
  ((ball M) ×ˢ (ball M)).filter (fun pq => -(pq.1 + pq.2) ∈ ball M)

theorem mem_triadSet {M : ℕ} {pq : Wavevector × Wavevector} :
    pq ∈ triadSet M ↔ pq.1 ∈ ball M ∧ pq.2 ∈ ball M ∧ -(pq.1 + pq.2) ∈ ball M := by
  unfold triadSet
  rw [Finset.mem_filter, Finset.mem_product]
  tauto

/-- **The closure lemma** — the step the memo flags as the design's only real trap.
`swap3` permutes the triad `{p, q, r}` and fixes `p`; membership in `triadSet` is a condition on
all three members at once; hence closure. -/
theorem triadSet_swap3_closed (M : ℕ) :
    ∀ pq ∈ triadSet M, AbstractAlgebraicConservation.swap3 pq ∈ triadSet M := by
  intro pq h
  rw [mem_triadSet] at h
  obtain ⟨hp, hq, hr⟩ := h
  rw [mem_triadSet]
  refine ⟨hp, hr, ?_⟩
  -- the third member of the swapped triad is the original `q`
  have hback : -(pq.1 + -(pq.1 + pq.2)) = pq.2 := by abel
  rw [AbstractAlgebraicConservation.swap3]
  simpa [hback] using hq

/-- Sanity witness (SPEC §7.5): the index set is inhabited, so the closure lemma is not vacuous. -/
theorem triadSet_nonempty_two : ((k0, wq) : Wavevector × Wavevector) ∈ triadSet 2 := by
  rw [mem_triadSet]
  refine ⟨k0_mem_ball_two, ?_, ?_⟩
  · rw [ball, Finset.mem_filter, Fintype.mem_piFinset]
    refine ⟨fun i => ?_, ?_⟩
    · rw [Finset.mem_Icc]
      fin_cases i <;> simp [wq, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons,
        Matrix.cons_val_two, Matrix.tail_cons]
    · norm_num [k_sq, wq, Fin.sum_univ_three, Matrix.cons_val_zero, Matrix.cons_val_one,
        Matrix.head_cons, Matrix.cons_val_two, Matrix.tail_cons]
  · rw [ball, Finset.mem_filter, Fintype.mem_piFinset]
    refine ⟨fun i => ?_, ?_⟩
    · rw [Finset.mem_Icc]
      fin_cases i <;>
        simp [k0, wq, Pi.add_apply, Pi.neg_apply, Matrix.cons_val_zero, Matrix.cons_val_one,
          Matrix.head_cons, Matrix.cons_val_two, Matrix.tail_cons]
    · norm_num [k_sq, k0, wq, Pi.add_apply, Pi.neg_apply, Fin.sum_univ_three,
        Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, Matrix.cons_val_two,
        Matrix.tail_cons]

/-! ### Audit certificates — expected on every line: no axiom outside
[propext, Classical.choice, Quot.sound]. -/
#print axioms k0_mem_ball_one
#print axioms B_div_free
#print axioms B_triad
#print axioms B_sublattice_invariance
#print axioms convective_delta
#print axioms B_witness_ne_zero
#print axioms B_not_identically_zero
#print axioms triadSet_swap3_closed
#print axioms triadSet_nonempty_two
#print axioms mem_ball_iff
#print axioms GalerkinState.eq_zero_of_notMem_ball

end MechanicaFluidorum.FourierZ3
