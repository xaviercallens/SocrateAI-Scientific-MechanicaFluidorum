/-
  CallensDualScale.lean — Tier A core of the Dual-Scale program (v0.2)
  =====================================================================
  Repaired foundation file. Differences from the v0.1 specification draft:

  1. NO custom axioms.  v0.1 declared `axiom alpha_prime : ℝ` and
     `axiom alpha_prime_pos`, violating the spec's own §5.1 ("Axioms are
     Forbidden") and falsifying its expected `#print axioms` footprint.
     Here α' enters every statement as an explicit hypothesis `0 < α`.
  2. `lattice_det` is `M → ℤ` (v0.1 had a bare constant `ℤ` applied to a
     point, a type error).
  3. The four Reff theorems claimed as "proven in Lean" in v0.1 did not
     exist in any prior tree.  They are proven here.
  4. Every class is inhabited by an explicit instance (§5.5 non-vacuity).

  Gate: `#print axioms` for every theorem below must report a subset of
  [propext, Classical.choice, Quot.sound].
-/
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum

namespace CallensDualScale
universe u

/-! ### Pillar 1: the T-dual effective radius

`Reff α R = max R (α / R)` — the effective scale seen by the dual-scale
geometry.  The four theorems below are the exact statements of spec §2.1. -/

/-- T-dual effective radius for fundamental area `α > 0` and scale `R`. -/
noncomputable def Reff (α R : ℝ) : ℝ := max R (α / R)

/-- The effective radius is positive (replaces v0.1 `genesis_no_singularity`,
    now axiom-free). -/
theorem Reff_pos {α R : ℝ} (_hα : 0 < α) (hR : 0 < R) : 0 < Reff α R :=
  lt_of_lt_of_le hR (le_max_left _ _)

/-- T-dual bound: `Reff α R ≥ √α`.  The scale `√α` is a universal minimum. -/
theorem Reff_ge_sqrt {α R : ℝ} (hα : 0 < α) (hR : 0 < R) :
    Real.sqrt α ≤ Reff α R := by
  have hdiv : 0 < α / R := div_pos hα hR
  have hmax : 0 < Reff α R := Reff_pos hα hR
  have hsq : α ≤ Reff α R ^ 2 := by
    have h1 : R * (α / R) ≤ Reff α R * Reff α R :=
      mul_le_mul (le_max_left _ _) (le_max_right _ _) hdiv.le hmax.le
    have h2 : R * (α / R) = α := by field_simp
    calc α = R * (α / R) := h2.symm
      _ ≤ Reff α R * Reff α R := h1
      _ = Reff α R ^ 2 := by ring
  calc Real.sqrt α ≤ Real.sqrt (Reff α R ^ 2) := Real.sqrt_le_sqrt hsq
    _ = Reff α R := Real.sqrt_sq hmax.le

/-- Bounce: below the fundamental length the scale is reflected to `α / R`. -/
theorem Reff_bounce {α R : ℝ} (hα : 0 < α) (hR : 0 < R)
    (h : R < Real.sqrt α) : Reff α R = α / R := by
  have hs : (0:ℝ) ≤ Real.sqrt α := Real.sqrt_nonneg α
  have hsq : R ^ 2 < α := by
    have h2 : R ^ 2 < Real.sqrt α ^ 2 := by nlinarith
    rwa [Real.sq_sqrt hα.le] at h2
  have hlt : R < α / R := by
    rw [lt_div_iff₀ hR]; nlinarith
  exact max_eq_right hlt.le

/-- Inertial invisibility: at or above the fundamental length the metric is
    classical, `Reff α R = R`. -/
theorem Reff_inertial {α R : ℝ} (hα : 0 < α) (hR : 0 < R)
    (h : Real.sqrt α ≤ R) : Reff α R = R := by
  have hs : (0:ℝ) ≤ Real.sqrt α := Real.sqrt_nonneg α
  have hsq : α ≤ R ^ 2 := by
    have h2 : Real.sqrt α ^ 2 ≤ R ^ 2 := by nlinarith
    rwa [Real.sq_sqrt hα.le] at h2
  have hle : α / R ≤ R := by
    rw [div_le_iff₀ hR]; nlinarith
  exact max_eq_left hle

/-- T-duality: the effective geometry cannot distinguish `R` from `α / R`. -/
theorem Reff_tdual {α R : ℝ} (hα : 0 < α) (hR : 0 < R) :
    Reff α (α / R) = Reff α R := by
  have h : α / (α / R) = R := by
    field_simp
  unfold Reff
  rw [h, max_comm]

/-- Numeric witness (non-vacuity, §5.5): with `α = 4`, the scale `R = 1`
    sits below `√α = 2` and bounces to `4`. -/
example : Reff 4 1 = 4 := by unfold Reff; norm_num [max_def]

/-! #### Sharpness of the minimal scale

`Reff_ge_sqrt` alone leaves open whether `√α` is actually attained.  It is, at
exactly one point — the self-dual radius `R = √α`.  This upgrades the bound from
"a lower barrier exists" to "the barrier is the self-dual scale and nothing
below it is reachable", which is the statement the physical narrative needs. -/

/-- Away from the self-dual radius the inequality of `Reff_ge_sqrt` is strict. -/
theorem Reff_gt_sqrt_of_ne {α R : ℝ} (hα : 0 < α) (hR : 0 < R)
    (hne : R ≠ Real.sqrt α) : Real.sqrt α < Reff α R := by
  have hs : 0 < Real.sqrt α := Real.sqrt_pos.mpr hα
  have hsq : Real.sqrt α * Real.sqrt α = α := Real.mul_self_sqrt hα.le
  rcases lt_or_gt_of_ne hne with h | h
  · rw [Reff_bounce hα hR h, lt_div_iff₀ hR]
    nlinarith
  · rw [Reff_inertial hα hR h.le]
    exact h

/-- The minimal scale is attained exactly at the self-dual radius `R = √α`. -/
theorem Reff_eq_sqrt_iff {α R : ℝ} (hα : 0 < α) (hR : 0 < R) :
    Reff α R = Real.sqrt α ↔ R = Real.sqrt α := by
  constructor
  · intro h
    by_contra hne
    have hlt := Reff_gt_sqrt_of_ne hα hR hne
    rw [h] at hlt
    exact lt_irrefl _ hlt
  · intro h
    rw [h]
    unfold Reff
    rw [Real.div_sqrt, max_self]

/-! #### The piecewise presentation, and why the side condition `0 < R` is real

The dual-scale geometry is often written piecewise ("bounce below `√α`, stay
classical above").  `tDualRadius` is that form.  It agrees with `Reff` — but
*only* for `R > 0`, and the failure off that range is not a technicality: it is
Lean's junk-value discipline (SPEC §7.5) catching a genuine mismatch. -/

/-- Piecewise ("bounce") presentation of the effective radius. -/
noncomputable def tDualRadius (α R : ℝ) : ℝ :=
  if R < Real.sqrt α then α / R else R

/-- The piecewise and `max` presentations coincide on the physical range. -/
theorem tDualRadius_eq_Reff {α R : ℝ} (hα : 0 < α) (hR : 0 < R) :
    tDualRadius α R = Reff α R := by
  unfold tDualRadius
  split_ifs with h
  · exact (Reff_bounce hα hR h).symm
  · exact (Reff_inertial hα hR (not_lt.mp h)).symm

/-- Genesis bounce: the effective radius never collapses to zero.  Axiom-free
    restatement of the proposal's `genesis_no_singularity`, with `α'` a
    hypothesis rather than a global constant. -/
theorem genesis_no_singularity {α R : ℝ} (hα : 0 < α) (hR : 0 < R) :
    0 < tDualRadius α R := by
  rw [tDualRadius_eq_Reff hα hR]
  exact Reff_pos hα hR

/-- Witnessed necessity of `0 < R` (§7.5): the two presentations genuinely
    disagree for negative `R` (α = 4, R = −1 gives −4 vs −1), so the side
    condition in `tDualRadius_eq_Reff` cannot be dropped. -/
example : tDualRadius 4 (-1) ≠ Reff 4 (-1) := by
  have h4 : Real.sqrt 4 = 2 := by
    rw [show (4:ℝ) = 2 ^ 2 by norm_num, Real.sqrt_sq (by norm_num : (0:ℝ) ≤ 2)]
  unfold tDualRadius Reff
  rw [h4]
  norm_num [max_def]

/-! ### Pillar 2: the symmetric-square lock (discrete shadow)

If `u` satisfies the 2nd-order recurrence `L2 : u_{n+2} = a u_{n+1} + b u_n`,
then `v_n = u_n²` satisfies the 3rd-order recurrence `L3 = Sym²(L2)`. -/

/-- Discrete Sym² lock, spec §2.2 (Clausen's identity at recurrence level). -/
theorem sym2_recurrence (a b : ℝ) (u : ℕ → ℝ)
    (hu : ∀ n, u (n + 2) = a * u (n + 1) + b * u n) (n : ℕ) :
    u (n + 3) ^ 2 =
      (a ^ 2 + b) * u (n + 2) ^ 2 + b * (a ^ 2 + b) * u (n + 1) ^ 2
        - b ^ 3 * u n ^ 2 := by
  have h1 : u (n + 2) = a * u (n + 1) + b * u n := hu n
  have h2 : u (n + 3) = a * u (n + 2) + b * u (n + 1) := hu (n + 1)
  rw [h2, h1]; ring

/-- Non-vacuity witness (§5.5): `u n = 2ⁿ` satisfies the `L2` hypothesis with
    `(a, b) = (1, 2)`, so `sym2_recurrence` is not vacuously true. -/
example : ∀ n : ℕ, ((2:ℝ) ^ (n + 2)) = 1 * 2 ^ (n + 1) + 2 * 2 ^ n := by
  intro n; ring

/-- Sequence-level interface for the Sym² lock: the macroscopic sequence `v` is
    supplied separately and only *related* to `u` by `hv`.  This is the form a
    downstream user wants (adopted from the 2026-08-12 proposal, which
    introduced it) — `v` can be any sequence proven to be the squares, not
    syntactically `fun n => u n ^ 2`. -/
theorem sym2_recurrence_seq (a b : ℝ) (u v : ℕ → ℝ)
    (hu : ∀ n, u (n + 2) = a * u (n + 1) + b * u n)
    (hv : ∀ n, v n = u n ^ 2) (n : ℕ) :
    v (n + 3) =
      (a ^ 2 + b) * v (n + 2) + b * (a ^ 2 + b) * v (n + 1) - b ^ 3 * v n := by
  rw [hv (n + 3), hv (n + 2), hv (n + 1), hv n]
  exact sym2_recurrence a b u hu n

/-- Spectral reading of the lock (§2.2): the `L3` coefficients are the
    elementary symmetric functions of `{λ², λμ, μ²}` when `L2` has roots
    `{λ, μ}`, i.e. `x² = a·x + b` has roots `λ, μ` with `λ + μ = a`, `λμ = −b`.
    Verifying this is what makes `L3 = Sym²(L2)` more than a lucky identity. -/
theorem sym2_symmetric_functions (a b lam mu : ℝ)
    (hsum : lam + mu = a) (hprod : lam * mu = -b) :
    lam ^ 2 + lam * mu + mu ^ 2 = a ^ 2 + b
    ∧ lam ^ 2 * (lam * mu) + lam ^ 2 * mu ^ 2 + lam * mu * mu ^ 2
        = -(b * (a ^ 2 + b))
    ∧ lam ^ 2 * (lam * mu) * mu ^ 2 = -(b ^ 3) := by
  subst hsum
  refine ⟨by nlinarith [hprod], by nlinarith [hprod], ?_⟩
  rw [show lam ^ 2 * (lam * mu) * mu ^ 2 = (lam * mu) ^ 3 by ring, hprod]
  ring

/-! ### Pillar 3: abstract operator geometry (with inhabitation witnesses) -/

class QuantumFiber (F : Type u) where
  L2_op : F → F

class MacroManifold (M : Type u) where
  L3_op : M → M
  lattice_det : M → ℤ

class DualScaleSpace (F M : Type u) [QuantumFiber F] [MacroManifold M] where
  proj : F → M
  sym2_lock : ∀ q : F,
    MacroManifold.L3_op (proj q) = proj (QuantumFiber.L2_op (QuantumFiber.L2_op q))

class CosmicWave (W : Type u) where
  wave_mass : W → ℝ

class WaveCoupling (M W : Type u) [MacroManifold M] [CosmicWave W] where
  to_wave : M → W
  resonance_law : ∀ m : M,
    CosmicWave.wave_mass (to_wave m) * (MacroManifold.lattice_det m : ℝ) = 1

/-- Spec Theorem 1.  NOTE (review): this follows from `resonance_law` alone in
    one step; it is kept as a sanity lemma, not presented as a deep result. -/
theorem wave_mass_nonzero {M W : Type u} [MacroManifold M] [CosmicWave W]
    [c : WaveCoupling M W] (m : M) :
    CosmicWave.wave_mass (c.to_wave m) ≠ 0 := by
  intro h0
  have h := c.resonance_law m
  rw [h0, zero_mul] at h
  exact zero_ne_one h

/-! Inhabitation instances (§5.1: "construct explicit, kernel-accepted models
    to prove that the axiomatic definitions are inhabited").
    Witness: `F = M = W = ℝ`, `L2 = (2·)`, `L3 = (4·)`, `proj = id`. -/

instance : QuantumFiber ℝ := ⟨fun x => 2 * x⟩
instance : MacroManifold ℝ := ⟨fun x => 4 * x, fun _ => 1⟩
instance : CosmicWave ℝ := ⟨fun _ => 1⟩

instance : DualScaleSpace ℝ ℝ where
  proj := id
  sym2_lock := by
    intro q
    show (4:ℝ) * q = 2 * (2 * q)
    ring

instance : WaveCoupling ℝ ℝ where
  to_wave := id
  resonance_law := by
    intro m
    show (1:ℝ) * ((1:ℤ) : ℝ) = 1
    norm_num

/-! ### Axiom-footprint gate (§5.1) -/

#print axioms Reff_pos
#print axioms Reff_ge_sqrt
#print axioms Reff_bounce
#print axioms Reff_inertial
#print axioms Reff_tdual
#print axioms Reff_gt_sqrt_of_ne
#print axioms Reff_eq_sqrt_iff
#print axioms tDualRadius_eq_Reff
#print axioms genesis_no_singularity
#print axioms sym2_recurrence
#print axioms sym2_recurrence_seq
#print axioms sym2_symmetric_functions
#print axioms wave_mass_nonzero

end CallensDualScale
