/-
  DyadicRiccati.lean — Tier A: why the dyadic regularity threshold is exactly `α = 1/2`
  =====================================================================================
  Formalises the exponent chain of `docs/designs/ALPHA_HALF_FORMALISATION.md`, which was
  hand-derived first (LL-5) and machine-checked in exact rationals
  (`tests/tier_b_riccati_exponents.py`) before any Lean was written.

  SCOPE — READ THIS BEFORE CITING THE FILE. This is **not** a formalisation of Cheskidov's
  Theorem 4.4 (arXiv:math/0601074). It formalises the *reason the theorem's threshold is 1/2*,
  which is a self-contained statement about exponents and integrability:

      the Riccati blow-up rate `(t*−t)^{−ρ(α)}` fails to be integrable  ⟺  α ≥ 1/2.

  Since the energy inequality supplies `‖u‖² ∈ L¹_loc`, that non-integrability is exactly what
  refutes a finite-time enstrophy blow-up — so `α ≥ 1/2` is an **integrability threshold**, not
  an artifact of technique. What this file does NOT contain: the bilinear estimate itself (it
  is an input, quoted from the source and declared sharp there), local existence, Galerkin
  approximation, or the passage to the limit. Those are where the real formalisation cost of
  Thm 4.4 sits. Claiming the theorem whole on the strength of this file would be exactly the
  D1-class overstatement the external audit of 2026-08-13 killed this programme's headline for.

  THE CHAIN (α carried symbolically throughout; `α ≥ 1/2` is used in exactly one lemma,
  `rhoExp_one_le_iff`, and everything upstream of it is α-general by construction):

    pExp α = 1/α − 1      exponent of |Au| in  |(B(u,u),Au)| ≤ c_b |Au|^p ‖u‖^q   [source]
    qExp α = 4 − 1/α      exponent of ‖u‖ there;  pExp + qExp = 3  (homogeneity)
    Young absorption against −ν|Au|² is possible  ⟺  pExp α < 2  ⟺  α > 1/3       [source]
    rExp α = 2·qExp/(2 − pExp) = (8α−2)/(3α−1)    post-Young exponent of ‖u‖      [source]
    sExp α = rExp/2 = (4α−1)/(3α−1)               Riccati:  y′ ≤ C y^s,  y = ‖u‖²
    rhoExp α = 1/(sExp − 1) = 3 − 1/α             rate:  y ≥ c (t*−t)^{−ρ}        [derived]

  The barrier below 1/2 is the same statement read backwards: refuting blow-up from a bound
  `‖u‖^θ ∈ L¹_loc` needs `θ ≥ 2/ρ(α)`, and `2/ρ(α) > 2 ⟺ α < 1/2` (`thetaStar_two_lt_iff`).
  The energy inequality gives exactly `θ = 2`, so the deficit is a single scalar.

  Gate: `#print axioms` for every theorem must name no axiom outside
  {propext, Classical.choice, Quot.sound}.
-/
import Mathlib.Analysis.SpecialFunctions.Integrability.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

namespace MechanicaFluidorum.DyadicRiccati

open MeasureTheory Set

/-! ## The exponents (α-general) -/

/-- Exponent of `|Au|` in the bilinear estimate. -/
noncomputable def pExp (a : ℝ) : ℝ := 1 / a - 1

/-- Exponent of `‖u‖` in the bilinear estimate. -/
noncomputable def qExp (a : ℝ) : ℝ := 4 - 1 / a

/-- Post-Young exponent of `‖u‖`. -/
noncomputable def rExp (a : ℝ) : ℝ := 2 * qExp a / (2 - pExp a)

/-- Riccati exponent: `y' ≤ C y ^ sExp a` for `y = ‖u‖²`. -/
noncomputable def sExp (a : ℝ) : ℝ := rExp a / 2

/-- Blow-up rate exponent: `y ≥ c (t* − t) ^ (−rhoExp a)`. -/
noncomputable def rhoExp (a : ℝ) : ℝ := 3 - 1 / a

/-! ## Step 1 — the exponent algebra -/

/-- Homogeneity of `B(·,·)·A`: the two exponents always sum to 3. -/
theorem pExp_add_qExp (a : ℝ) : pExp a + qExp a = 3 := by
  unfold pExp qExp; ring

/-- `2 − pExp a` is exactly the rate exponent — the algebraic coincidence that makes the whole
chain collapse to a single quantity. -/
theorem two_sub_pExp (a : ℝ) : 2 - pExp a = rhoExp a := by
  unfold pExp rhoExp; ring

/-- **Young absorption is possible iff `α > 1/3`.** This is the content of the *local*
regularity theorem, and it is emphatically NOT where the threshold `1/2` comes from. -/
theorem absorbable_iff {a : ℝ} (ha : 0 < a) : pExp a < 2 ↔ 1 / 3 < a := by
  unfold pExp
  rw [sub_lt_iff_lt_add, div_lt_iff₀ ha, div_lt_iff₀ (by norm_num : (0:ℝ) < 3)]
  constructor <;> intro h <;> linarith

/-- `rhoExp` with the fraction cleared. -/
theorem rhoExp_eq_div {a : ℝ} (ha : a ≠ 0) : rhoExp a = (3 * a - 1) / a := by
  unfold rhoExp; field_simp

theorem rhoExp_ne_zero {a : ℝ} (ha : a ≠ 0) (h3 : 3 * a - 1 ≠ 0) : rhoExp a ≠ 0 := by
  rw [rhoExp_eq_div ha]; exact div_ne_zero h3 ha

/-- `qExp = rhoExp + 1`: the algebraic fact that collapses the whole chain onto one quantity. -/
theorem qExp_eq_rhoExp_add_one (a : ℝ) : qExp a = rhoExp a + 1 := by
  unfold qExp rhoExp; ring

/-- The post-Young exponent in the closed form the source displays: `(8α−2)/(3α−1)`. -/
theorem rExp_eq {a : ℝ} (ha : 0 < a) (h3 : 3 * a - 1 ≠ 0) :
    rExp a = (8 * a - 2) / (3 * a - 1) := by
  have ha' : a ≠ 0 := ne_of_gt ha
  have hd : rhoExp a ≠ 0 := rhoExp_ne_zero ha' h3
  unfold rExp qExp
  rw [two_sub_pExp, div_eq_div_iff hd h3]
  unfold rhoExp
  field_simp
  ring

/-- **`sExp − 1` is exactly the reciprocal of the rate exponent** — the derived identity behind
the blow-up rate, and the reason `rhoExp` is the only quantity that matters. -/
theorem sExp_sub_one_eq_inv_rhoExp {a : ℝ} (ha : a ≠ 0) (h3 : 3 * a - 1 ≠ 0) :
    sExp a - 1 = 1 / rhoExp a := by
  have hd : rhoExp a ≠ 0 := rhoExp_ne_zero ha h3
  unfold sExp rExp
  rw [two_sub_pExp, qExp_eq_rhoExp_add_one]
  field_simp
  ring

theorem rhoExp_eq_inv_sExp_sub_one {a : ℝ} (ha : a ≠ 0) (h3 : 3 * a - 1 ≠ 0) :
    rhoExp a = 1 / (sExp a - 1) := by
  rw [sExp_sub_one_eq_inv_rhoExp ha h3, one_div_one_div]

/-! ## Step 2 — the threshold, arithmetic half -/

/-- **The single use of `α ≥ 1/2` in the whole development.** -/
theorem rhoExp_one_le_iff {a : ℝ} (ha : 0 < a) : 1 ≤ rhoExp a ↔ 1 / 2 ≤ a := by
  unfold rhoExp
  constructor
  · intro h
    have h1 : 1 / a ≤ 2 := by linarith
    rw [div_le_iff₀ ha] at h1
    linarith
  · intro h
    have h1 : 1 / a ≤ 2 := by
      rw [div_le_iff₀ ha]
      linarith
    linarith

/-- Above the local-existence threshold the rate exponent is positive. -/
theorem rhoExp_pos {a : ℝ} (ha : 0 < a) (h : 1 / 3 < a) : 0 < rhoExp a := by
  unfold rhoExp
  rw [sub_pos, div_lt_iff₀ ha]
  rw [div_lt_iff₀ (by norm_num : (0:ℝ) < 3)] at h
  linarith

/-! ## Step 3 — the threshold, integrability half (genuine measure theory) -/

/-- The rate `x ↦ x^(−ρ)` is integrable near the singularity iff `ρ < 1`. Direct consequence of
Mathlib's characterisation of integrability of real powers on `Ioo 0 t`. -/
theorem rate_integrableOn_iff (ρ : ℝ) {T : ℝ} (hT : 0 < T) :
    IntegrableOn (fun x : ℝ => x ^ (-ρ)) (Ioo 0 T) ↔ ρ < 1 := by
  rw [intervalIntegral.integrableOn_Ioo_rpow_iff hT]
  constructor <;> intro h <;> linarith

/-! ## Step 4 — the theorem this file exists for -/

/-- **The dyadic regularity threshold is an integrability threshold.**

The Riccati blow-up rate `(t*−t)^{−ρ(α)}` fails to be locally integrable **exactly** when
`α ≥ 1/2`. Combined with the energy inequality — which supplies `‖u‖² ∈ L¹_loc` and is the
*only* a priori control available — this is precisely why a finite-time enstrophy blow-up is
refuted for `α ≥ 1/2` and why the argument says nothing below it. -/
theorem blowupRate_not_integrable_iff {a : ℝ} (ha : 0 < a) {T : ℝ} (hT : 0 < T) :
    ¬ IntegrableOn (fun x : ℝ => x ^ (-(rhoExp a))) (Ioo 0 T) ↔ 1 / 2 ≤ a := by
  rw [rate_integrableOn_iff _ hT, not_lt, rhoExp_one_le_iff ha]

/-- **The barrier below `1/2`, as a formal statement.** Refuting blow-up from an a priori bound
`‖u‖^θ ∈ L¹_loc` requires `θ ≥ 2/ρ(α)`; this says that requirement exceeds the `θ = 2` the
energy inequality supplies **exactly** below `α = 1/2`. The obstruction is a single scalar
deficit, and any route into the band must either raise `θ` or leave the Riccati argument. -/
theorem thetaStar_two_lt_iff {a : ℝ} (ha : 0 < a) (h13 : 1 / 3 < a) :
    2 < 2 / rhoExp a ↔ a < 1 / 2 := by
  have hpos := rhoExp_pos ha h13
  have key := rhoExp_one_le_iff ha
  rw [lt_div_iff₀ hpos]
  constructor
  · intro h
    have hr : rhoExp a < 1 := by linarith
    have hn : ¬ (1 / 2 ≤ a) := fun hc => absurd (key.mpr hc) (not_le.mpr hr)
    exact not_le.mp hn
  · intro h
    have hn : ¬ (1 ≤ rhoExp a) := fun hr => absurd (key.mp hr) (not_le.mpr h)
    have := not_le.mp hn
    linarith

/-! ## Non-vacuity (SPEC §7.5) — the characterisations are not trivially true or false -/

/-- At `α = 1/2` the rate exponent is exactly `1`: the borderline case. -/
example : rhoExp (1 / 2 : ℝ) = 1 := by unfold rhoExp; norm_num

/-- At `α = 2/5` — the case Cheskidov singles out as carrying the *same* enstrophy estimate as
3-D Navier–Stokes — the rate exponent is `1/2`, so the rate IS integrable and the argument
yields nothing. -/
example : rhoExp (2 / 5 : ℝ) = 1 / 2 := by unfold rhoExp; norm_num

/-- Both sides of `blowupRate_not_integrable_iff` are genuinely inhabited and genuinely
refutable: at `α = 1` the rate is non-integrable, at `α = 2/5` it is integrable. -/
example : (1:ℝ)/2 ≤ 1 := by norm_num

example : ¬ ((1:ℝ)/2 ≤ 2/5) := by norm_num

/-- The post-Young exponent at `α = 2/5` is `6`, reproducing the `‖u‖⁶` the source displays. -/
example : rExp (2 / 5 : ℝ) = 6 := by
  rw [rExp_eq (by norm_num) (by norm_num)]
  norm_num

/-- And at `α = 1/2` it is `4`, reproducing the source's `‖u‖⁴`. -/
example : rExp (1 / 2 : ℝ) = 4 := by
  rw [rExp_eq (by norm_num) (by norm_num)]
  norm_num

/-! ## Axiom-footprint gate

**Negative controls (hand-derived; to be run against scratch perturbed copies before commit):**
NC1 — replace `rhoExp a` by `3 - 2/a`: `rhoExp_one_le_iff`'s `1/2` characterisation must break.
NC2 — drop `1/3 < a` from `rhoExp_pos`: positivity becomes unprovable (it genuinely fails at
`a = 1/4`). NC3 — weaken `1/2 ≤ a` to `1/3 < a` in `blowupRate_not_integrable_iff`: the
equivalence must fail, since at `a = 2/5` the rate is integrable. -/

#print axioms pExp_add_qExp
#print axioms two_sub_pExp
#print axioms absorbable_iff
#print axioms rExp_eq
#print axioms rhoExp_eq_div
#print axioms qExp_eq_rhoExp_add_one
#print axioms sExp_sub_one_eq_inv_rhoExp
#print axioms rhoExp_eq_inv_sExp_sub_one
#print axioms rhoExp_one_le_iff
#print axioms rhoExp_pos
#print axioms rate_integrableOn_iff
#print axioms blowupRate_not_integrable_iff
#print axioms thetaStar_two_lt_iff

end MechanicaFluidorum.DyadicRiccati
