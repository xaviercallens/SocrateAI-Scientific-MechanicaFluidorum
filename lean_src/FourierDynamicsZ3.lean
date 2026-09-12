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
Task 2.2 CLOSED 2026-09-10: `energy_conservation` proves
`EnergyConservationStatement M` for every `M`, zero `sorry`, clean footprint.
Steps 2–5 (the Leray drop, the reindexing bijection, the out-of-ball vanishing,
and the assembly) are §8. The three negative controls that
`docs/designs/TASK22_ENERGY_IDENTITY.md` §8 mandates were run on scratch copies
and each FAILS as required.
=============================================================================
-/

import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.Group.Subgroup.Basic
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Complex.BigOperators
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
/-! ### 8. Task 2.2 steps 2–5: the bridge to `triad_sum_zero`

`docs/designs/TASK22_ENERGY_IDENTITY.md` establishes that the mathematics of energy conservation is
already Tier A here, as `AbstractAlgebraicConservation.triad_sum_zero`, and that what remains is an
*instantiation*. Step 4 of its implementation order, the closure lemma, is `triadSet_swap3_closed`
above. This section supplies the rest. -/

/-- The ball is closed under negation — `k_sq` does not see the sign. Needed by the reindexing,
because the third member of the triad is `−(p+q)`. -/
theorem neg_mem_ball {M : ℕ} {k : Wavevector} : -k ∈ ball M ↔ k ∈ ball M := by
  rw [mem_ball_iff, mem_ball_iff, k_sq_neg]

/-- Conjugation passes through `fourier_dot`, because the wavevector entries are integers and so
are fixed by it. -/
theorem fourier_dot_conj (k : Wavevector) (v : Fin 3 → ℂ) :
    fourier_dot k (fun i => conj (v i)) = conj (fourier_dot k v) := by
  unfold fourier_dot
  rw [map_sum]
  exact Finset.sum_congr rfl fun i _ => by rw [map_mul, map_intCast]

/-- **Step A — the Leray projector drops out of the outer pairing.**

`⟨u, P(k)x⟩ = ⟨u, x⟩` whenever `u` is divergence-free at `k`. The projector is real symmetric,
hence self-adjoint for this pairing, so it moves onto the left argument; and `conj u` is
divergence-free at `k` exactly when `u` is, so the projector fixes it.

The memo routes this through the conjugate-symmetry `conj(u_k) = u_{−k}`. That is not needed: the
integer wavevector is fixed by conjugation, so divergence-freeness transfers to `conj u` directly,
and the proof holds for **any** divergence-free `u`, not only for a `FourierState`. -/
theorem pairing_leray_drop {k : Wavevector} {u : Fin 3 → ℂ}
    (hu : fourier_dot k u = 0) (x : Fin 3 → ℂ) :
    pairing u (applyLeray k x) = pairing u x := by
  have hconj : fourier_dot k (fun i => conj (u i)) = 0 := by
    rw [fourier_dot_conj, hu, map_zero]
  have hfix : applyLeray k (fun i => conj (u i)) = fun i => conj (u i) :=
    applyLeray_eq_self hconj
  unfold pairing applyLeray at *
  calc ∑ i : Fin 3, conj (u i) * ∑ j : Fin 3, LerayProjector k i j * x j
      = ∑ i : Fin 3, ∑ j : Fin 3, conj (u i) * LerayProjector k i j * x j := by
        refine Finset.sum_congr rfl fun i _ => ?_
        rw [Finset.mul_sum]
        exact Finset.sum_congr rfl fun j _ => by ring
    _ = ∑ j : Fin 3, ∑ i : Fin 3, conj (u i) * LerayProjector k i j * x j := Finset.sum_comm
    _ = ∑ j : Fin 3, (∑ i : Fin 3, LerayProjector k j i * conj (u i)) * x j := by
        refine Finset.sum_congr rfl fun j _ => ?_
        rw [Finset.sum_mul]
        refine Finset.sum_congr rfl fun i _ => ?_
        rw [leray_symm k i j]
        ring
    _ = ∑ j : Fin 3, conj (u j) * x j := by
        exact Finset.sum_congr rfl fun j _ => by rw [congrFun hfix j]

/-- The wavevector map of `triad_sum_zero`, as a complex-valued field on the lattice. -/
noncomputable def kmap (a : Wavevector) : Fin 3 → ℂ := fun i => ((a i : ℤ) : ℂ)

theorem dot_kmap (q : Wavevector) (v : Fin 3 → ℂ) :
    AbstractAlgebraicConservation.dot (kmap q) v = fourier_dot q v := rfl

/-- `hkadd` of `triad_sum_zero`: the wavevector map is additive, because `Int.cast` is. -/
theorem kmap_add (a b : Wavevector) (i : Fin 3) : kmap (a + b) i = kmap a i + kmap b i := by
  unfold kmap
  rw [Pi.add_apply]
  push_cast
  ring

/-- **Step C — the out-of-ball terms vanish.** The Galerkin cutoff kills `u q`, and the summand
carries `u q` as a factor. This is what lets the sum be restricted from the reindexed set, which is
*not* `swap3`-closed, to `triadSet M`, which is. -/
theorem summand_eq_zero_of_notMem_ball {M : ℕ} (s : GalerkinState M)
    {pq : Wavevector × Wavevector} (h : pq.2 ∉ ball M) :
    AbstractAlgebraicConservation.summand kmap s.toFourierState.u pq = 0 := by
  unfold AbstractAlgebraicConservation.summand AbstractAlgebraicConservation.dot
  rw [s.eq_zero_of_notMem_ball h]
  simp

/-- **Step B — the reindexing.** `(k, p) ↦ (p, k − p)` carries the double sum over the ball onto
`triadSet M`, once the terms whose middle member leaves the ball have been discarded by step C.

The inverse is `(p, q) ↦ (p + q, p)`; it lands back in the ball because `triadSet` constrains
`−(p+q)`, and the ball is negation-closed. -/
theorem sum_double_eq_sum_triadSet_weighted {M : ℕ} (s : GalerkinState M)
    (w : Wavevector → ℂ) :
    ∑ k ∈ ball M, ∑ p ∈ ball M,
        AbstractAlgebraicConservation.wsummand kmap s.toFourierState.u w (p, k - p)
      = ∑ pq ∈ triadSet M,
          AbstractAlgebraicConservation.wsummand kmap s.toFourierState.u w pq := by
  classical
  set u := s.toFourierState.u with hudef
  set F : Wavevector × Wavevector → ℂ :=
    fun kp => AbstractAlgebraicConservation.wsummand kmap u w (kp.2, kp.1 - kp.2) with hF
  have hprod : ∑ k ∈ ball M, ∑ p ∈ ball M,
      AbstractAlgebraicConservation.wsummand kmap u w (p, k - p)
        = ∑ kp ∈ (ball M) ×ˢ (ball M), F kp := by
    rw [Finset.sum_product]
  rw [hprod]
  -- discard the pairs whose middle member has left the ball
  set T : Finset (Wavevector × Wavevector) :=
    ((ball M) ×ˢ (ball M)).filter (fun kp => kp.1 - kp.2 ∈ ball M) with hT
  have hsub : T ⊆ (ball M) ×ˢ (ball M) := Finset.filter_subset _ _
  have hdrop : ∀ kp ∈ (ball M) ×ˢ (ball M), kp ∉ T → F kp = 0 := by
    intro kp hmem hnot
    have hq : kp.1 - kp.2 ∉ ball M := by
      intro hc
      exact hnot (Finset.mem_filter.mpr ⟨hmem, hc⟩)
    show AbstractAlgebraicConservation.wsummand kmap u w (kp.2, kp.1 - kp.2) = 0
    unfold AbstractAlgebraicConservation.wsummand
    rw [summand_eq_zero_of_notMem_ball s hq, mul_zero]
  rw [← Finset.sum_subset hsub hdrop]
  -- and reindex what is left
  refine Finset.sum_nbij' (i := fun kp => (kp.2, kp.1 - kp.2))
    (j := fun pq => (pq.1 + pq.2, pq.1)) ?_ ?_ ?_ ?_ ?_
  · intro kp hkp
    rw [hT, Finset.mem_filter, Finset.mem_product] at hkp
    obtain ⟨⟨hk, hp⟩, hq⟩ := hkp
    rw [mem_triadSet]
    refine ⟨hp, hq, ?_⟩
    have : -(kp.2 + (kp.1 - kp.2)) = -kp.1 := by abel
    rw [this]
    exact neg_mem_ball.mpr hk
  · intro pq hpq
    rw [mem_triadSet] at hpq
    obtain ⟨hp, hq, hr⟩ := hpq
    rw [hT, Finset.mem_filter, Finset.mem_product]
    refine ⟨⟨?_, hp⟩, ?_⟩
    · exact neg_mem_ball.mp (by simpa using hr)
    · simpa using hq
  · intro kp _
    have : kp.2 + (kp.1 - kp.2) = kp.1 := by abel
    simp [this]
  · intro pq _
    have : pq.1 + pq.2 - pq.1 = pq.2 := by abel
    simp [this]
  · intro kp _
    rfl

/-- The unweighted reindexing, which Task 2.2 consumes, as the constant-weight case. -/
theorem sum_double_eq_sum_triadSet {M : ℕ} (s : GalerkinState M) :
    ∑ k ∈ ball M, ∑ p ∈ ball M,
        AbstractAlgebraicConservation.summand kmap s.toFourierState.u (p, k - p)
      = ∑ pq ∈ triadSet M, AbstractAlgebraicConservation.summand kmap s.toFourierState.u pq := by
  have h := sum_double_eq_sum_triadSet_weighted s (fun _ => (1 : ℂ))
  simpa only [AbstractAlgebraicConservation.wsummand_one] using h

/-- The outer pairing against the convective term, written as a sum of `summand`s. This is where
the conjugate symmetry `conj(u_k) = u_{−k}` is used, and the only place it is needed: it turns the
Hermitian outer pairing into the **bilinear** `dot` that `triad_sum_zero` is stated for. -/
theorem pairing_convective_expand {M : ℕ} (s : GalerkinState M) (k : Wavevector) :
    pairing (s.toFourierState.u k) (convective M s.toFourierState.u s.toFourierState.u k)
      = ∑ p ∈ ball M, (-Complex.I) *
          AbstractAlgebraicConservation.summand kmap s.toFourierState.u (p, k - p) := by
  classical
  set u := s.toFourierState.u with hudef
  have hcs : ∀ (a : Wavevector) (i : Fin 3), u (-a) i = conj (u a i) :=
    s.toFourierState.conj_sym
  have hneg : ∀ p : Wavevector, -(p + (k - p)) = -k := fun p => by abel
  unfold pairing convective AbstractAlgebraicConservation.summand
    AbstractAlgebraicConservation.dot
  calc ∑ i : Fin 3, conj (u k i) * ∑ p ∈ ball M,
          (-Complex.I) * fourier_dot (k - p) (u p) * u (k - p) i
      = ∑ i : Fin 3, ∑ p ∈ ball M,
          conj (u k i) * ((-Complex.I) * fourier_dot (k - p) (u p) * u (k - p) i) :=
        Finset.sum_congr rfl fun i _ => Finset.mul_sum _ _ _
    _ = ∑ p ∈ ball M, ∑ i : Fin 3,
          conj (u k i) * ((-Complex.I) * fourier_dot (k - p) (u p) * u (k - p) i) :=
        Finset.sum_comm
    _ = ∑ p ∈ ball M, (-Complex.I) *
          (fourier_dot (k - p) (u p) * ∑ i : Fin 3, u (k - p) i * u (-(p + (k - p))) i) := by
        refine Finset.sum_congr rfl fun p _ => ?_
        rw [hneg p]
        have hR : (-Complex.I) *
            (fourier_dot (k - p) (u p) * ∑ i : Fin 3, u (k - p) i * u (-k) i)
              = ∑ i : Fin 3,
                  (-Complex.I) * fourier_dot (k - p) (u p) * (u (k - p) i * u (-k) i) := by
          rw [← mul_assoc, Finset.mul_sum]
        rw [hR]
        refine Finset.sum_congr rfl fun i _ => ?_
        rw [hcs k i]
        ring

/-- **Task 2.2 — energy conservation for the Galerkin-truncated nonlinearity.**

`Re Σ_{k ∈ Λ_M} ⟨u_k, B(u,u)_k⟩ = 0` for every Galerkin state, every `M`, with no smallness, no
genericity, and no hypothesis beyond the `GalerkinState` structure.

The mathematics is the two-element symmetry proved abstractly in
`AbstractAlgebraicConservation.triad_sum_zero`, which had been Tier A here since 2026-08-13. All
this proof does is instantiate it: drop the projector, reindex, discard the terms the cutoff kills,
and apply the theorem.

**Scope, and audit verdict D1 still binds.** This is the *finite-dimensional* identity: the Galerkin
ODE conserves energy exactly. It is a prerequisite for global existence of the truncated system. It
is not evidence about the `α′ → 0` limit, about Hypothesis U, or about Navier–Stokes. A truncation
is a truncation. -/
theorem energy_conservation (M : ℕ) : EnergyConservationStatement M := by
  intro s
  have h2 : ∀ x : ℂ, 2 * x = 0 → x = 0 := by
    intro x hx
    rcases mul_eq_zero.mp hx with h | h
    · exact absurd h (by norm_num)
    · exact h
  have hdiv : ∀ pq ∈ triadSet M,
      AbstractAlgebraicConservation.dot (kmap pq.1) (s.toFourierState.u pq.1) = 0 :=
    fun pq _ => s.toFourierState.div_free pq.1
  have key : ∑ k ∈ ball M, pairing (s.toFourierState.u k)
      (B M s.toFourierState.u s.toFourierState.u k) = 0 := by
    have hA : ∀ k ∈ ball M, pairing (s.toFourierState.u k)
        (B M s.toFourierState.u s.toFourierState.u k)
          = ∑ p ∈ ball M, (-Complex.I) *
              AbstractAlgebraicConservation.summand kmap s.toFourierState.u (p, k - p) := by
      intro k _
      rw [B, pairing_leray_drop (s.toFourierState.div_free k), pairing_convective_expand]
    rw [Finset.sum_congr rfl hA]
    have hpull : ∑ k ∈ ball M, ∑ p ∈ ball M, (-Complex.I) *
        AbstractAlgebraicConservation.summand kmap s.toFourierState.u (p, k - p)
          = (-Complex.I) * ∑ k ∈ ball M, ∑ p ∈ ball M,
              AbstractAlgebraicConservation.summand kmap s.toFourierState.u (p, k - p) := by
      rw [Finset.mul_sum]
      exact Finset.sum_congr rfl fun k _ => (Finset.mul_sum _ _ _).symm
    rw [hpull, sum_double_eq_sum_triadSet s,
      AbstractAlgebraicConservation.triad_sum_zero kmap s.toFourierState.u (triadSet M)
        h2 kmap_add (triadSet_swap3_closed M) hdiv]
    ring
  rw [key]
  simp

/-! ### 9. The enstrophy production, in exact closed form

`docs/HYPOTHESIS_U_SPECIFICATION.md` Definition 1.1 states Hypothesis U for the **enstrophy**
`E = ‖∇u‖²_{L²}`, which on the lattice is `Σ_k |k|² |u_k|²`. Its production under the truncated
nonlinearity is therefore the *same sum* as the energy identity, weighted by `|k|²` — and since
`k = −r`, the weight lands on the triad's third member. So this is exactly the situation
`AbstractAlgebraicConservation.weighted_triad_sum` describes, and the bridge of §8 carries over
verbatim once it is stated with a weight.

Derivation and scope: `docs/designs/WEIGHTED_TRIAD_IDENTITY.md` (DRAFT, awaiting the owner's
statement-adequacy audit).

**Read the scope note on `enstrophy_production_identity` before citing it.** It is an identity, not
a bound. -/

/-- The enstrophy weight, as a complex-valued function on the lattice. -/
noncomputable def ksqC (a : Wavevector) : ℂ := ((k_sq a : ℤ) : ℂ)

theorem ksqC_neg (a : Wavevector) : ksqC (-a) = ksqC a := by
  unfold ksqC
  rw [k_sq_neg]

/-- The weight seen by the reindexed triad is the weight at the outer index, because the triad's
third member is `−k`, and `k_sq` is even. -/
theorem ksqC_third (k p : Wavevector) : ksqC (-(p + (k - p))) = ksqC k := by
  have h : -(p + (k - p)) = -k := by abel
  rw [h, ksqC_neg]

/-- `Σ_k |k|² ⟨u_k, B(u,u)_k⟩`. The physical enstrophy production is the **real part** of this;
the identity below is stated for the complex quantity, from which the real statement follows by
taking `.re` of both sides. -/
noncomputable def enstrophyProduction (M : ℕ) (u : Wavevector → Fin 3 → ℂ) : ℂ :=
  ∑ k ∈ ball M, ksqC k * pairing (u k) (B M u u k)

/-- **The enstrophy production in exact closed form — vortex stretching, algebraically.**

```
    2 · Σ_k |k|² ⟨u_k, B(u,u)_k⟩  =  −i · Σ_{triads}  ( |r|² − |q|² ) · (q·u_p) · (u_q·u_r)
```

Compare `energy_conservation`, which is the same computation with the weight removed and whose
right-hand side is therefore **zero**. Everything separating the two sits in the single factor
`|r|² − |q|²`: the two orderings of a triad differ in the weight and in nothing else. So a triad
transfers enstrophy in proportion to how **unequal in wavenumber** its two swapped members are, and
a triad whose two swapped members share a sphere transfers none.

**SCOPE, and it matters more than the theorem.** This is an **identity, not a bound**. It gives no
estimate on the production, and it says **nothing** about uniformity in the truncation `M`, which is
the entire content of Hypothesis U. SPEC obstruction **O5** stands untouched: at fixed truncation
the system is regular by an elementary argument, so a result that does not use the limit uniformly
proves nothing about the limit — and this one does not use the limit at all. It is also not new
mathematics; the enstrophy production of the Fourier–Galerkin system is classical. What is new is
only that it is kernel-checked in the same abstract form as the energy identity.

Non-vacuity of the index set is `triadSet_nonempty_two`; non-vacuity of the right-hand side —
that it is genuinely nonzero for a non-constant weight — is established at Tier B in
`tests/tier_b_weighted_triad.py`. -/
theorem enstrophy_production_identity (M : ℕ) (s : GalerkinState M) :
    2 * enstrophyProduction M s.toFourierState.u
      = (-Complex.I) * ∑ pq ∈ triadSet M,
          (ksqC (-(pq.1 + pq.2)) - ksqC pq.2)
            * (AbstractAlgebraicConservation.dot (kmap pq.2) (s.toFourierState.u pq.1)
               * AbstractAlgebraicConservation.dot (s.toFourierState.u pq.2)
                   (s.toFourierState.u (-(pq.1 + pq.2)))) := by
  have hdiv : ∀ pq ∈ triadSet M,
      AbstractAlgebraicConservation.dot (kmap pq.1) (s.toFourierState.u pq.1) = 0 :=
    fun pq _ => s.toFourierState.div_free pq.1
  have hstep : enstrophyProduction M s.toFourierState.u
      = (-Complex.I) * ∑ pq ∈ triadSet M,
          AbstractAlgebraicConservation.wsummand kmap s.toFourierState.u ksqC pq := by
    unfold enstrophyProduction
    have hA : ∀ k ∈ ball M, ksqC k * pairing (s.toFourierState.u k)
        (B M s.toFourierState.u s.toFourierState.u k)
          = (-Complex.I) * ∑ p ∈ ball M,
              AbstractAlgebraicConservation.wsummand kmap s.toFourierState.u ksqC (p, k - p) := by
      intro k _
      rw [B, pairing_leray_drop (s.toFourierState.div_free k), pairing_convective_expand,
        Finset.mul_sum, Finset.mul_sum]
      refine Finset.sum_congr rfl fun p _ => ?_
      unfold AbstractAlgebraicConservation.wsummand
      rw [ksqC_third k p]
      ring
    rw [Finset.sum_congr rfl hA, ← Finset.mul_sum, sum_double_eq_sum_triadSet_weighted s ksqC]
  rw [hstep, ← mul_assoc, mul_comm (2 : ℂ) (-Complex.I), mul_assoc,
    AbstractAlgebraicConservation.weighted_triad_sum kmap s.toFourierState.u ksqC (triadSet M)
      kmap_add (triadSet_swap3_closed M) hdiv]

/-! ### 10. The viscous balance laws (WP-1 of `docs/designs/DUAL_SCALE_WORKFLOW.md`)

`docs/HYPOTHESIS_U_SPECIFICATION.md` §3.1 identifies the T-dual regularization at the PDE level
with the frequency projection onto `|k| ≤ 1/√α′` — so the truncated system below **is** the
α′-regularized system, under `M ↔ 1/√α′`. Its right-hand side is the dissipation of the spec's
Definition 1.1 plus the Task 2.1 operator, and the two balance laws are corollaries of
`energy_conservation` and `enstrophy_production_identity`. The pattern mirrors
`DyadicShells.energyRate`, Tier A for the shell model since August.

These are algebraic rate identities — no time variable, no ODE, exactly as in the dyadic
precedent. The rate is the pairing of the state against the right-hand side; when a trajectory
formalism exists it becomes `d/dt` of the energy along solutions, and not before. -/

theorem pairing_self_eq_ofReal (a : Fin 3 → ℂ) :
    pairing a a = ((∑ i : Fin 3, Complex.normSq (a i) : ℝ) : ℂ) := by
  unfold pairing
  rw [Complex.ofReal_sum]
  exact Finset.sum_congr rfl fun i _ => by rw [mul_comm, Complex.mul_conj]

/-- **The right-hand side of the regularized (truncated) Navier–Stokes system**:
`F_k = −ν|k|² u_k + B(u,u)_k`. -/
noncomputable def galerkinRHS (M : ℕ) (nu : ℝ) (u : Wavevector → Fin 3 → ℂ)
    (k : Wavevector) : Fin 3 → ℂ :=
  fun i => -(nu : ℂ) * ksqC k * u k i + B M u u k i

/-- The energy rate `Re Σ_k ⟨u_k, F_k⟩` — the dyadic `energyRate`, on `ℤ³`. -/
noncomputable def energyRateZ3 (M : ℕ) (nu : ℝ) (u : Wavevector → Fin 3 → ℂ) : ℝ :=
  (∑ k ∈ ball M, pairing (u k) (galerkinRHS M nu u k)).re

/-- The enstrophy rate `Re Σ_k |k|² ⟨u_k, F_k⟩`. -/
noncomputable def enstrophyRateZ3 (M : ℕ) (nu : ℝ) (u : Wavevector → Fin 3 → ℂ) : ℝ :=
  (∑ k ∈ ball M, ksqC k * pairing (u k) (galerkinRHS M nu u k)).re

/-- The pairing splits over the right-hand side, and the dissipation term is a real multiple. -/
theorem pairing_galerkinRHS (M : ℕ) (nu : ℝ) (u : Wavevector → Fin 3 → ℂ) (k : Wavevector) :
    pairing (u k) (galerkinRHS M nu u k)
      = -(nu : ℂ) * ksqC k * pairing (u k) (u k) + pairing (u k) (B M u u k) := by
  unfold galerkinRHS pairing
  rw [Finset.mul_sum, ← Finset.sum_add_distrib]
  exact Finset.sum_congr rfl fun i _ => by ring

/-- Each dissipation term is the cast of an explicit real number. -/
theorem dissipation_term_ofReal (nu : ℝ) (u : Wavevector → Fin 3 → ℂ) (k : Wavevector) :
    -(nu : ℂ) * ksqC k * pairing (u k) (u k)
      = ((-nu * (k_sq k : ℝ) * ∑ i : Fin 3, Complex.normSq (u k i) : ℝ) : ℂ) := by
  rw [pairing_self_eq_ofReal]
  unfold ksqC
  push_cast
  ring

/-- **Energy dissipation.** `Re Σ_k ⟨u_k, F_k⟩ = −ν Σ_k |k|² ‖u_k‖²`: by `energy_conservation`
the nonlinearity contributes nothing, so the energy of the regularized system moves only by
viscosity. -/
theorem energyRateZ3_eq (M : ℕ) (nu : ℝ) (s : GalerkinState M) :
    energyRateZ3 M nu s.toFourierState.u
      = -nu * ∑ k ∈ ball M,
          (k_sq k : ℝ) * ∑ i : Fin 3, Complex.normSq (s.toFourierState.u k i) := by
  unfold energyRateZ3
  rw [Finset.sum_congr rfl fun k _ => pairing_galerkinRHS M nu s.toFourierState.u k,
    Finset.sum_add_distrib, Complex.add_re, energy_conservation M s, add_zero,
    Finset.sum_congr rfl fun k _ => dissipation_term_ofReal nu s.toFourierState.u k,
    ← Complex.ofReal_sum, Complex.ofReal_re, Finset.mul_sum]
  exact Finset.sum_congr rfl fun k _ => by ring

/-- **The energy of the regularized system cannot rise** (`ν ≥ 0`). With `energy_conservation`
this is global-in-time boundedness of the energy at each fixed `M` — and `SPEC` obstruction O5
is the standing reminder that fixed-`M` regularity was never in doubt. -/
theorem energyRateZ3_nonpos (M : ℕ) {nu : ℝ} (hnu : 0 ≤ nu) (s : GalerkinState M) :
    energyRateZ3 M nu s.toFourierState.u ≤ 0 := by
  rw [energyRateZ3_eq]
  have hS : (0 : ℝ) ≤ ∑ k ∈ ball M,
      (k_sq k : ℝ) * ∑ i : Fin 3, Complex.normSq (s.toFourierState.u k i) :=
    Finset.sum_nonneg fun k _ =>
      mul_nonneg (by exact_mod_cast k_sq_nonneg k)
        (Finset.sum_nonneg fun i _ => Complex.normSq_nonneg _)
  rw [neg_mul, neg_nonpos]
  exact mul_nonneg hnu hS

/-- **The enstrophy balance: dissipation against production, and NOTHING bounds the production.**

`Re Σ_k |k|²⟨u_k, F_k⟩ = −ν Σ_k |k|⁴ ‖u_k‖² + Re Σ_k |k|²⟨u_k, B_k⟩`.

The first term is nonpositive; the second is the vortex-stretching term of
`enstrophy_production_identity`, exhibited nonzero on a genuine Galerkin state
(`tests/tier_b_fourier_enstrophy.py`, value `−18` there — the sign is state-dependent). **The
absence of any bound on the second term against the first, uniformly in `M`, is precisely
Hypothesis U, and nothing in this file addresses it.** This theorem closes the fixed-`M`
bookkeeping; the open problem starts on its right-hand side. -/
theorem enstrophyRateZ3_eq (M : ℕ) (nu : ℝ) (s : GalerkinState M) :
    enstrophyRateZ3 M nu s.toFourierState.u
      = -nu * (∑ k ∈ ball M,
          ((k_sq k : ℝ)) ^ 2 * ∑ i : Fin 3, Complex.normSq (s.toFourierState.u k i))
        + (enstrophyProduction M s.toFourierState.u).re := by
  unfold enstrophyRateZ3 enstrophyProduction
  have hterm : ∀ k ∈ ball M, ksqC k * pairing (s.toFourierState.u k)
      (galerkinRHS M nu s.toFourierState.u k)
        = ((-nu * (k_sq k : ℝ) ^ 2 * ∑ i : Fin 3,
              Complex.normSq (s.toFourierState.u k i) : ℝ) : ℂ)
          + ksqC k * pairing (s.toFourierState.u k)
              (B M s.toFourierState.u s.toFourierState.u k) := by
    intro k _
    rw [pairing_galerkinRHS, mul_add]
    congr 1
    rw [pairing_self_eq_ofReal]
    unfold ksqC
    push_cast
    ring
  rw [Finset.sum_congr rfl hterm, Finset.sum_add_distrib, Complex.add_re,
    ← Complex.ofReal_sum, Complex.ofReal_re, Finset.mul_sum]
  congr 1
  exact Finset.sum_congr rfl fun k _ => by ring

/-! ### 11. The parity kernel of the production sum

Discovered by the pre-registered measurement of `docs/designs/HELICAL_PRODUCTION_EXPANSION.md`
§4 (the coherent family's ratio came out EXACTLY zero, and the mechanism was then identified),
proved the same day. For **parity-even** states — `u(−k) = u(k)` — the production term sum
vanishes identically: global negation is an involution of `triadSet M` under which the weight
and the bilinear factor are even while the divergence contraction is odd, so the terms cancel
pairwise.

This is a *degeneracy class*, in the same family as the negation symmetry behind the retracted
Waleffe §6bis item 4: a state inside it shows perfect cancellation that carries **no
information about phase mixing**. Any mixing measurement must first show its test states are
outside this kernel — which is precisely what the memo's interpretation quarantine enforces. -/

theorem fourier_dot_neg_left (q : Wavevector) (v : Fin 3 → ℂ) :
    fourier_dot (-q) v = -fourier_dot q v := by
  unfold fourier_dot
  rw [← Finset.sum_neg_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [Pi.neg_apply]
  push_cast
  ring

/-- The negation involution preserves the triad index set. -/
theorem triadSet_neg_closed (M : ℕ) :
    ∀ pq ∈ triadSet M, (-(Prod.fst pq), -(Prod.snd pq)) ∈ triadSet M := by
  intro pq h
  rw [mem_triadSet] at h ⊢
  obtain ⟨hp, hq, hr⟩ := h
  refine ⟨neg_mem_ball.mpr hp, neg_mem_ball.mpr hq, ?_⟩
  have : -(-pq.1 + -pq.2) = -(-(pq.1 + pq.2)) := by abel
  rw [this]
  exact neg_mem_ball.mpr hr

/-- **The production sum vanishes identically on parity-even states.** -/
theorem production_terms_eq_zero_of_even (M : ℕ) (u : Wavevector → Fin 3 → ℂ)
    (heven : ∀ k, u (-k) = u k) :
    ∑ pq ∈ triadSet M,
        (ksqC (-(pq.1 + pq.2)) - ksqC pq.2)
          * (fourier_dot pq.2 (u pq.1)
             * AbstractAlgebraicConservation.dot (u pq.2) (u (-(pq.1 + pq.2)))) = 0 := by
  classical
  refine Finset.sum_involution (fun pq _ => (-pq.1, -pq.2)) ?_ ?_ ?_ ?_
  · -- pairing: the negated term is the negative of the original
    intro pq _
    have h1 : -(-pq.1 + -pq.2) = pq.1 + pq.2 := by abel
    simp only [h1]
    have hw : ksqC (pq.1 + pq.2) = ksqC (-(pq.1 + pq.2)) := (ksqC_neg _).symm
    have hfd : fourier_dot (-pq.2) (u (-pq.1)) = -fourier_dot pq.2 (u pq.1) := by
      rw [heven pq.1, fourier_dot_neg_left]
    have hbil : AbstractAlgebraicConservation.dot (u (-pq.2)) (u (pq.1 + pq.2))
        = AbstractAlgebraicConservation.dot (u pq.2) (u (-(pq.1 + pq.2))) := by
      rw [heven pq.2, ← heven (pq.1 + pq.2)]
    rw [hw, show ksqC (-pq.2) = ksqC pq.2 from ksqC_neg _, hfd, hbil]
    ring
  · -- a nonzero term is not a fixed point
    intro pq _ hne hfix
    apply hne
    have hq : -pq.2 = pq.2 := congrArg Prod.snd hfix
    have hq0 : pq.2 = 0 := by
      funext i
      have h := congrFun hq i
      rw [Pi.neg_apply] at h
      have hz : pq.2 i = 0 := by omega
      simpa using hz
    rw [hq0]
    have : fourier_dot (0 : Wavevector) (u pq.1) = 0 := by
      unfold fourier_dot
      simp
    rw [this]
    ring
  · exact triadSet_neg_closed M
  · intro pq _
    simp

/-! ### 12. The disparity decomposition — the pivot's first exact object

The kinematic track was killed (LEDGER, 2026-09-12) with the vulnerability isolated to the
factor `|r|² − |q|²`. The successor programme — dynamics restricting access to adversarial
states, and the **sweeping effect** — needs its objects defined before anything is proved about
them (rule E-1). This section defines the first one exactly and proves the two facts that are
free.

The **disparity** of a triad is the integer `δ(p,q) = |r|² − |q|²`, the weight that carries
the entire enstrophy obstruction. Grouping the production by disparity gives the
**disparity decomposition**: the production is a sum of fiber sums `P_δ`, one per integer value
the disparity takes on the ball. Two facts:

* **exact sweeping suppression** — the `δ = 0` fiber, the triads whose two swapped members share
  a sphere (same-shell advection, the discrete face of Kraichnan sweeping), contributes
  **exactly nothing**. Sweeping cannot produce enstrophy, by the algebra alone;
* the decomposition is a partition, so every unit of production is accounted to exactly one
  disparity — which is what makes "how much comes from large disparity" a well-posed question.

Proposed for owner adoption as the pivot's vocabulary (`docs/designs/DYNAMIC_ACCESS.md`). -/

/-- The disparity of an ordered triad: the integer weight `|r|² − |q|²` with `r = −(p+q)`. -/
def disparity (pq : Wavevector × Wavevector) : ℤ :=
  k_sq (-(pq.1 + pq.2)) - k_sq pq.2

/-- The production term of one ordered triad — the summand of `enstrophy_production_identity`. -/
noncomputable def productionTerm (u : Wavevector → Fin 3 → ℂ) (pq : Wavevector × Wavevector) :
    ℂ :=
  (ksqC (-(pq.1 + pq.2)) - ksqC pq.2)
    * (fourier_dot pq.2 (u pq.1)
       * AbstractAlgebraicConservation.dot (u pq.2) (u (-(pq.1 + pq.2))))

/-- The production fiber at disparity `δ`: the sum over triads of exactly that disparity. -/
noncomputable def productionFiber (M : ℕ) (u : Wavevector → Fin 3 → ℂ) (δ : ℤ) : ℂ :=
  ∑ pq ∈ (triadSet M).filter (fun pq => disparity pq = δ), productionTerm u pq

theorem productionTerm_eq (u : Wavevector → Fin 3 → ℂ) (pq : Wavevector × Wavevector) :
    productionTerm u pq
      = ((disparity pq : ℤ) : ℂ)
        * (fourier_dot pq.2 (u pq.1)
           * AbstractAlgebraicConservation.dot (u pq.2) (u (-(pq.1 + pq.2)))) := by
  unfold productionTerm disparity ksqC
  push_cast
  ring

/-- **Exact sweeping suppression.** A same-shell triad carries no enstrophy production: its
weight is zero, so its term is zero, whatever the amplitudes. -/
theorem productionTerm_eq_zero_of_same_shell (u : Wavevector → Fin 3 → ℂ)
    {pq : Wavevector × Wavevector} (h : disparity pq = 0) : productionTerm u pq = 0 := by
  rw [productionTerm_eq, h]
  simp

/-- The zero-disparity fiber vanishes identically. -/
theorem productionFiber_zero (M : ℕ) (u : Wavevector → Fin 3 → ℂ) :
    productionFiber M u 0 = 0 := by
  unfold productionFiber
  refine Finset.sum_eq_zero fun pq hpq => ?_
  exact productionTerm_eq_zero_of_same_shell u (Finset.mem_filter.mp hpq).2

/-- **The disparity decomposition.** The production is the sum of its fibers over the disparities
that actually occur on the ball — a partition, so nothing is counted twice or dropped. -/
theorem enstrophy_production_decomposition (M : ℕ) (s : GalerkinState M) :
    2 * enstrophyProduction M s.toFourierState.u
      = (-Complex.I) * ∑ δ ∈ (triadSet M).image disparity,
          productionFiber M s.toFourierState.u δ := by
  rw [enstrophy_production_identity M s]
  congr 1
  unfold productionFiber
  rw [Finset.sum_fiberwise_of_maps_to (s := triadSet M) (t := (triadSet M).image disparity)
    (g := disparity) (fun pq hpq => Finset.mem_image_of_mem disparity hpq)
    (productionTerm s.toFourierState.u)]
  exact Finset.sum_congr rfl fun pq _ => rfl

#print axioms neg_mem_ball
#print axioms fourier_dot_conj
#print axioms pairing_leray_drop
#print axioms pairing_convective_expand
#print axioms energy_conservation
#print axioms sum_double_eq_sum_triadSet_weighted
#print axioms ksqC_third
#print axioms enstrophy_production_identity
#print axioms fourier_dot_neg_left
#print axioms triadSet_neg_closed
#print axioms production_terms_eq_zero_of_even
#print axioms productionTerm_eq_zero_of_same_shell
#print axioms productionFiber_zero
#print axioms enstrophy_production_decomposition
#print axioms pairing_self_eq_ofReal
#print axioms pairing_galerkinRHS
#print axioms energyRateZ3_eq
#print axioms energyRateZ3_nonpos
#print axioms enstrophyRateZ3_eq
#print axioms kmap_add
#print axioms summand_eq_zero_of_notMem_ball
#print axioms sum_double_eq_sum_triadSet

#print axioms triadSet_nonempty_two
#print axioms mem_ball_iff
#print axioms GalerkinState.eq_zero_of_notMem_ball

end MechanicaFluidorum.FourierZ3
