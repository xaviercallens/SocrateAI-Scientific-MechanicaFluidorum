/-
=============================================================================
HelicalBasis.lean — D-3 / OP-6b, STEP 1: Waleffe's helical basis on ℤ³
=============================================================================
Status  : Tier A target. Owner approved `docs/designs/WALEFFE_HELICAL_MEMO.md`
          on 2026-09-10 and cleared step 1 of its §7.
Scope   : THE BASIS AND ITS FIVE FACTS, and nothing else. No interaction
          coefficient, no dynamics, no bound, no Hypothesis U.

WHAT IS PROVED HERE
  nuInt        a TOTAL integer-valued map with `nuInt k ⊥ k` and `nuInt k ≠ 0`
               for `k ≠ 0` — the arbitrary choice the memo requires, made once.
  hRaw s k     the (unnormalised) helical vector `(N × k) + i s |k| N`.
  H1  hRaw · hRaw = 0                    self-null
  H2  hRaw · conj hRaw = 2 |N|² |k|²     the normalisation, unnormalised form
  H3  k · hRaw = 0                       transversality
  H4  i (k × hRaw) = s |k| · hRaw        THE CURL EIGENVECTOR PROPERTY
  H5  conj (hRaw s k) = hRaw (-s) k      reality ↔ chirality

WHY THE *UNNORMALISED* VECTOR. The memo (§1) records the obstruction: `|k| = √(k_sq k)` is
irrational at almost every lattice point, so a normalised basis drags a square root through every
proof and forces a division whose side condition must be witnessed (Lean's `x/0 = 0` otherwise
proves the wrong theorem silently). Working with `hRaw = |N| |k| · h` removes every division: the
square root then survives only where it is genuinely needed, inside `H2` and `H4`, and only through
`(√(k_sq k))² = k_sq k`. The normalised statements follow by scaling and are deferred to step 2,
where the coefficient's `1/|k|` appears anyway and the witness is needed once, in one place.

NEGATIVE CONTROLS (SPEC §7.3, mandatory and run on scratch copies before merge):
  * `hRaw_curl_eigen` with the sign of the `i s |k| N` term flipped — must FAIL;
  * `hRaw_self_null` with `hsq` (the `s * s = 1` hypothesis) dropped — must FAIL;
  * `nuInt_ne_zero` with the `k ≠ 0` hypothesis dropped — must FAIL.
Each was run and each failed as required; see the LEDGER row.

NOT DONE HERE, deliberately: the owner's instruction to "isolate a tarpit in a lemma with `sorry`"
is incompatible with this repository's Gate 2, which fails on any `sorry`, and with `#print axioms`,
because a `sorry`'d theorem still DEFINES ITS NAME and so pollutes every downstream footprint with
`sorryAx`. The supported substitute is a `Prop` with an inhabited quantifier domain.
=============================================================================
-/

import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import FourierStateZ3

set_option autoImplicit false

namespace MechanicaFluidorum.FourierZ3

open ComplexConjugate

/-! ### 1. Integer vector algebra on the lattice -/

/-- Integer dot product on `ℤ³`. -/
def dotZ (a b : Wavevector) : ℤ := ∑ i : Fin 3, a i * b i

/-- Integer cross product on `ℤ³`. Stays in `ℤ`, which is what keeps §2's proofs free of casts. -/
def crossZ (a b : Wavevector) : Wavevector :=
  ![a 1 * b 2 - a 2 * b 1, a 2 * b 0 - a 0 * b 2, a 0 * b 1 - a 1 * b 0]

@[simp] theorem crossZ_apply_zero (a b : Wavevector) : crossZ a b 0 = a 1 * b 2 - a 2 * b 1 := rfl
@[simp] theorem crossZ_apply_one (a b : Wavevector) : crossZ a b 1 = a 2 * b 0 - a 0 * b 2 := rfl
@[simp] theorem crossZ_apply_two (a b : Wavevector) : crossZ a b 2 = a 0 * b 1 - a 1 * b 0 := rfl

theorem dotZ_expand (a b : Wavevector) : dotZ a b = a 0 * b 0 + a 1 * b 1 + a 2 * b 2 := by
  simp [dotZ, Fin.sum_univ_three]

/-- `a ⊥ a × b`. -/
theorem dotZ_crossZ_left (a b : Wavevector) : dotZ a (crossZ a b) = 0 := by
  rw [dotZ_expand]; simp only [crossZ_apply_zero, crossZ_apply_one, crossZ_apply_two]; ring

/-- `b ⊥ a × b`. -/
theorem dotZ_crossZ_right (a b : Wavevector) : dotZ b (crossZ a b) = 0 := by
  rw [dotZ_expand]; simp only [crossZ_apply_zero, crossZ_apply_one, crossZ_apply_two]; ring

/-- **Lagrange's identity**, the one algebraic fact the self-null property rests on. -/
theorem dotZ_crossZ_self (a b : Wavevector) :
    dotZ (crossZ a b) (crossZ a b) = dotZ a a * dotZ b b - dotZ a b * dotZ a b := by
  rw [dotZ_expand, dotZ_expand, dotZ_expand, dotZ_expand]
  simp only [crossZ_apply_zero, crossZ_apply_one, crossZ_apply_two]
  ring

theorem dotZ_self_eq_k_sq (a : Wavevector) : dotZ a a = k_sq a := by
  rw [dotZ_expand, k_sq, Fin.sum_univ_three]; ring

/-! ### 2. The choice of `ν`, made once and totally -/

def ex : Wavevector := ![1, 0, 0]
def ey : Wavevector := ![0, 1, 0]

/-- **The arbitrary choice the memo demands, made total.** `k × x̂`, falling back to `k × ŷ` on the
one line where the first degenerates. Integer-valued, so no normalisation is forced yet. -/
def nuInt (k : Wavevector) : Wavevector :=
  if crossZ k ex = 0 then crossZ k ey else crossZ k ex

/-- `ν(k) ⊥ k`, unconditionally — it is a cross product with `k`. -/
theorem nuInt_orthogonal (k : Wavevector) : dotZ k (nuInt k) = 0 := by
  unfold nuInt
  split_ifs with h
  · exact dotZ_crossZ_left k ey
  · exact dotZ_crossZ_left k ex

/-- Totality's real content: the choice never degenerates on a nonzero lattice point. -/
theorem nuInt_ne_zero {k : Wavevector} (hk : k ≠ 0) : nuInt k ≠ 0 := by
  unfold nuInt
  split_ifs with h
  · -- `k × x̂ = 0` forces `k 1 = k 2 = 0`, so `k 0 ≠ 0`, and `k × ŷ` has that in its last slot.
    have h1 : k 1 = 0 := by
      have := congrFun h 2
      simpa [ex, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons] using this
    have h2 : k 2 = 0 := by
      have := congrFun h 1
      simpa [ex, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons] using this
    have h0 : k 0 ≠ 0 := by
      intro hz
      apply hk
      funext i
      fin_cases i
      · simpa using hz
      · simpa using h1
      · simpa using h2
    intro hcontra
    have h20 := congrFun hcontra 2
    simp only [crossZ_apply_two, ey, Matrix.cons_val_zero, Matrix.cons_val_one,
      Matrix.head_cons, Pi.zero_apply, mul_one, mul_zero, sub_zero] at h20
    exact h0 h20
  · exact h

/-! ### 3. The real magnitude, and the only square root in the file -/

/-- `|k|`, as a real number. -/
noncomputable def kNorm (k : Wavevector) : ℝ := Real.sqrt ((k_sq k : ℝ))

theorem kNorm_nonneg (k : Wavevector) : 0 ≤ kNorm k := Real.sqrt_nonneg _

/-- The square root's defining property, in the only form the proofs below need. -/
theorem kNorm_sq (k : Wavevector) : kNorm k * kNorm k = (k_sq k : ℝ) :=
  Real.mul_self_sqrt (by exact_mod_cast k_sq_nonneg k)

/-! ### 4. The helical vector, unnormalised -/

/-- `hRaw s k = (ν(k) × k) + i s |k| ν(k)`, i.e. `|ν| |k|` times Waleffe's `h^s(k)`.

Carrying the scale factor removes every division, so no `k ≠ 0` witness is needed until step 2. -/
noncomputable def hRaw (s : ℝ) (k : Wavevector) : Fin 3 → ℂ :=
  fun i => ((crossZ (nuInt k) k i : ℤ) : ℂ)
            + Complex.I * (s : ℂ) * ((kNorm k : ℝ) : ℂ) * (((nuInt k i : ℤ) : ℂ))

/-- Bilinear complex dot, no conjugation — the same convention as `FourierStateZ3.fourier_dot`. -/
noncomputable def cdot (v w : Fin 3 → ℂ) : ℂ := ∑ i : Fin 3, v i * w i

theorem cdot_expand (v w : Fin 3 → ℂ) : cdot v w = v 0 * w 0 + v 1 * w 1 + v 2 * w 2 := by
  simp [cdot, Fin.sum_univ_three]

/-! ### 5. The five facts -/

/-- **H3 — transversality.** `k · hRaw = 0`, for every `s` and every `k`, no hypothesis. -/
theorem hRaw_transverse (s : ℝ) (k : Wavevector) : fourier_dot k (hRaw s k) = 0 := by
  have hA : dotZ k (crossZ (nuInt k) k) = 0 := dotZ_crossZ_right (nuInt k) k
  have hN : dotZ k (nuInt k) = 0 := nuInt_orthogonal k
  rw [dotZ_expand] at hA hN
  unfold fourier_dot hRaw
  rw [Fin.sum_univ_three]
  have hA' : ((k 0 : ℂ)) * ((crossZ (nuInt k) k 0 : ℤ) : ℂ)
      + ((k 1 : ℂ)) * ((crossZ (nuInt k) k 1 : ℤ) : ℂ)
      + ((k 2 : ℂ)) * ((crossZ (nuInt k) k 2 : ℤ) : ℂ) = 0 := by
    exact_mod_cast congrArg (fun z : ℤ => ((z : ℂ))) hA
  have hN' : ((k 0 : ℂ)) * ((nuInt k 0 : ℤ) : ℂ)
      + ((k 1 : ℂ)) * ((nuInt k 1 : ℤ) : ℂ)
      + ((k 2 : ℂ)) * ((nuInt k 2 : ℤ) : ℂ) = 0 := by
    exact_mod_cast congrArg (fun z : ℤ => ((z : ℂ))) hN
  linear_combination hA' + Complex.I * (s : ℂ) * ((kNorm k : ℝ) : ℂ) * hN'

/-- **H5 — reality becomes chirality.** -/
theorem hRaw_conj (s : ℝ) (k : Wavevector) (i : Fin 3) :
    conj (hRaw s k i) = hRaw (-s) k i := by
  unfold hRaw
  simp only [map_add, map_mul, Complex.conj_I, Complex.conj_ofReal, map_intCast,
    Complex.ofReal_neg, Complex.ofReal_ratCast]
  push_cast
  ring

/-- The algebra behind H1, isolated over an arbitrary commutative ring so that the combination
stays linear in the hypotheses. `A` is `ν × k`, `N` is `ν`, `K` is `k`, `n` is `|k|`, `S` is `s`. -/
theorem self_null_algebra
    (A0 A1 A2 N0 N1 N2 K0 K1 K2 n S I : ℂ)
    (hlag : A0 * A0 + A1 * A1 + A2 * A2
        = (N0 * N0 + N1 * N1 + N2 * N2) * (K0 * K0 + K1 * K1 + K2 * K2))
    (hAN : N0 * A0 + N1 * A1 + N2 * A2 = 0)
    (hs : S * S = 1)
    (hn : n * n = K0 * K0 + K1 * K1 + K2 * K2)
    (hI : I * I = -1) :
    (A0 + I * S * n * N0) * (A0 + I * S * n * N0)
      + (A1 + I * S * n * N1) * (A1 + I * S * n * N1)
      + (A2 + I * S * n * N2) * (A2 + I * S * n * N2) = 0 := by
  linear_combination hlag + (2 * I * S * n) * hAN
    + ((N0 * N0 + N1 * N1 + N2 * N2) * S * S * n * n) * hI
    - (N0 * N0 + N1 * N1 + N2 * N2) * hn
    - ((N0 * N0 + N1 * N1 + N2 * N2) * n * n) * hs

/-- **H1 — self-null.** The basis is isotropic: `hRaw · hRaw = 0`. Needs `s² = 1`. -/
theorem hRaw_self_null {s : ℝ} (hsq : s * s = 1) (k : Wavevector) :
    cdot (hRaw s k) (hRaw s k) = 0 := by
  have hlag : dotZ (crossZ (nuInt k) k) (crossZ (nuInt k) k)
      = dotZ (nuInt k) (nuInt k) * dotZ k k := by
    rw [dotZ_crossZ_self]
    have : dotZ (nuInt k) k = 0 := by
      have h := nuInt_orthogonal k
      rw [dotZ_expand] at h ⊢
      linarith [h]
    rw [this]; ring
  have hAN : dotZ (nuInt k) (crossZ (nuInt k) k) = 0 := dotZ_crossZ_left (nuInt k) k
  rw [dotZ_expand] at hlag hAN
  rw [dotZ_expand, dotZ_expand] at hlag
  have hk2 : (kNorm k : ℂ) * (kNorm k : ℂ) = ((k_sq k : ℤ) : ℂ) := by
    have := kNorm_sq k
    exact_mod_cast congrArg (fun r : ℝ => ((r : ℂ))) this
  have hksq : ((k_sq k : ℤ) : ℂ) = (k 0 : ℂ) * (k 0 : ℂ) + (k 1 : ℂ) * (k 1 : ℂ)
      + (k 2 : ℂ) * (k 2 : ℂ) := by
    have : k_sq k = k 0 * k 0 + k 1 * k 1 + k 2 * k 2 := by
      rw [k_sq, Fin.sum_univ_three]; ring
    exact_mod_cast congrArg (fun z : ℤ => ((z : ℂ))) this
  unfold hRaw
  rw [cdot_expand]
  have hI : Complex.I * Complex.I = -1 := Complex.I_mul_I
  have hs : (s : ℂ) * (s : ℂ) = 1 := by exact_mod_cast congrArg (fun r : ℝ => ((r : ℂ))) hsq
  have hlagC : ((crossZ (nuInt k) k 0 : ℤ) : ℂ) * ((crossZ (nuInt k) k 0 : ℤ) : ℂ)
      + ((crossZ (nuInt k) k 1 : ℤ) : ℂ) * ((crossZ (nuInt k) k 1 : ℤ) : ℂ)
      + ((crossZ (nuInt k) k 2 : ℤ) : ℂ) * ((crossZ (nuInt k) k 2 : ℤ) : ℂ)
      = (((nuInt k 0 : ℤ) : ℂ) * ((nuInt k 0 : ℤ) : ℂ)
         + ((nuInt k 1 : ℤ) : ℂ) * ((nuInt k 1 : ℤ) : ℂ)
         + ((nuInt k 2 : ℤ) : ℂ) * ((nuInt k 2 : ℤ) : ℂ))
        * ((k 0 : ℂ) * (k 0 : ℂ) + (k 1 : ℂ) * (k 1 : ℂ) + (k 2 : ℂ) * (k 2 : ℂ)) := by
    exact_mod_cast congrArg (fun z : ℤ => ((z : ℂ))) hlag
  have hANC : ((nuInt k 0 : ℤ) : ℂ) * ((crossZ (nuInt k) k 0 : ℤ) : ℂ)
      + ((nuInt k 1 : ℤ) : ℂ) * ((crossZ (nuInt k) k 1 : ℤ) : ℂ)
      + ((nuInt k 2 : ℤ) : ℂ) * ((crossZ (nuInt k) k 2 : ℤ) : ℂ) = 0 := by
    exact_mod_cast congrArg (fun z : ℤ => ((z : ℂ))) hAN
  exact self_null_algebra
    ((crossZ (nuInt k) k 0 : ℤ) : ℂ) ((crossZ (nuInt k) k 1 : ℤ) : ℂ)
    ((crossZ (nuInt k) k 2 : ℤ) : ℂ)
    ((nuInt k 0 : ℤ) : ℂ) ((nuInt k 1 : ℤ) : ℂ) ((nuInt k 2 : ℤ) : ℂ)
    ((k 0 : ℤ) : ℂ) ((k 1 : ℤ) : ℂ) ((k 2 : ℤ) : ℂ)
    ((kNorm k : ℝ) : ℂ) ((s : ℝ) : ℂ) Complex.I
    hlagC hANC hs (by rw [hk2]; exact hksq) hI

/-- **H2 — the normalisation, in unnormalised form.** `hRaw · conj hRaw = 2 |ν|² |k|²`. Dividing
through by `|ν|²|k|²` is the statement `h · conj h = 2` of the memo; the division is deferred to
step 2, where its `k ≠ 0` witness is needed once. -/
theorem hRaw_norm {s : ℝ} (hsq : s * s = 1) (k : Wavevector) :
    cdot (hRaw s k) (fun i => conj (hRaw s k i))
      = 2 * ((dotZ (nuInt k) (nuInt k) : ℤ) : ℂ) * ((k_sq k : ℤ) : ℂ) := by
  have hlag : dotZ (crossZ (nuInt k) k) (crossZ (nuInt k) k)
      = dotZ (nuInt k) (nuInt k) * dotZ k k := by
    rw [dotZ_crossZ_self]
    have hz : dotZ (nuInt k) k = 0 := by
      have h := nuInt_orthogonal k
      rw [dotZ_expand] at h ⊢; linarith [h]
    rw [hz]; ring
  have hAN : dotZ (nuInt k) (crossZ (nuInt k) k) = 0 := dotZ_crossZ_left (nuInt k) k
  have hkk : dotZ k k = k_sq k := dotZ_self_eq_k_sq k
  rw [hkk] at hlag
  have hNC : ((dotZ (nuInt k) (nuInt k) : ℤ) : ℂ)
      = ((nuInt k 0 : ℤ) : ℂ) * ((nuInt k 0 : ℤ) : ℂ)
        + ((nuInt k 1 : ℤ) : ℂ) * ((nuInt k 1 : ℤ) : ℂ)
        + ((nuInt k 2 : ℤ) : ℂ) * ((nuInt k 2 : ℤ) : ℂ) := by
    exact_mod_cast congrArg (fun z : ℤ => ((z : ℂ))) (dotZ_expand (nuInt k) (nuInt k))
  rw [hNC]
  simp only [dotZ_expand] at hlag hAN
  simp only [hRaw_conj]
  unfold hRaw
  rw [cdot_expand]
  -- `((-s : ℝ) : ℂ)` must become `-(s : ℂ)` or the cross terms cannot cancel
  push_cast
  have hI : Complex.I * Complex.I = -1 := Complex.I_mul_I
  have hs : (s : ℂ) * (s : ℂ) = 1 := by exact_mod_cast congrArg (fun r : ℝ => ((r : ℂ))) hsq
  have hk2 : ((kNorm k : ℝ) : ℂ) * ((kNorm k : ℝ) : ℂ) = ((k_sq k : ℤ) : ℂ) := by
    exact_mod_cast congrArg (fun r : ℝ => ((r : ℂ))) (kNorm_sq k)
  have hlagC : ((crossZ (nuInt k) k 0 : ℤ) : ℂ) * ((crossZ (nuInt k) k 0 : ℤ) : ℂ)
      + ((crossZ (nuInt k) k 1 : ℤ) : ℂ) * ((crossZ (nuInt k) k 1 : ℤ) : ℂ)
      + ((crossZ (nuInt k) k 2 : ℤ) : ℂ) * ((crossZ (nuInt k) k 2 : ℤ) : ℂ)
      = (((nuInt k 0 : ℤ) : ℂ) * ((nuInt k 0 : ℤ) : ℂ)
         + ((nuInt k 1 : ℤ) : ℂ) * ((nuInt k 1 : ℤ) : ℂ)
         + ((nuInt k 2 : ℤ) : ℂ) * ((nuInt k 2 : ℤ) : ℂ)) * ((k_sq k : ℤ) : ℂ) := by
    exact_mod_cast congrArg (fun z : ℤ => ((z : ℂ))) hlag
  have hANC : ((nuInt k 0 : ℤ) : ℂ) * ((crossZ (nuInt k) k 0 : ℤ) : ℂ)
      + ((nuInt k 1 : ℤ) : ℂ) * ((crossZ (nuInt k) k 1 : ℤ) : ℂ)
      + ((nuInt k 2 : ℤ) : ℂ) * ((crossZ (nuInt k) k 2 : ℤ) : ℂ) = 0 := by
    exact_mod_cast congrArg (fun z : ℤ => ((z : ℂ))) hAN
  linear_combination hlagC
    + (((nuInt k 0 : ℤ) : ℂ) * ((nuInt k 0 : ℤ) : ℂ)
       + ((nuInt k 1 : ℤ) : ℂ) * ((nuInt k 1 : ℤ) : ℂ)
       + ((nuInt k 2 : ℤ) : ℂ) * ((nuInt k 2 : ℤ) : ℂ))
      * ((kNorm k : ℝ) : ℂ) * ((kNorm k : ℝ) : ℂ) * hs
    + (((nuInt k 0 : ℤ) : ℂ) * ((nuInt k 0 : ℤ) : ℂ)
       + ((nuInt k 1 : ℤ) : ℂ) * ((nuInt k 1 : ℤ) : ℂ)
       + ((nuInt k 2 : ℤ) : ℂ) * ((nuInt k 2 : ℤ) : ℂ)) * hk2
    - ((s : ℂ) * (s : ℂ) * ((kNorm k : ℝ) : ℂ) * ((kNorm k : ℝ) : ℂ)
       * (((nuInt k 0 : ℤ) : ℂ) * ((nuInt k 0 : ℤ) : ℂ)
          + ((nuInt k 1 : ℤ) : ℂ) * ((nuInt k 1 : ℤ) : ℂ)
          + ((nuInt k 2 : ℤ) : ℂ) * ((nuInt k 2 : ℤ) : ℂ))) * hI

/-! ### 6. H4 — the curl eigenvector property, the reason the basis exists -/

/-- Complex cross product with a real (integer) vector on the left. -/
noncomputable def crossRC (a : Wavevector) (v : Fin 3 → ℂ) : Fin 3 → ℂ :=
  ![(a 1 : ℂ) * v 2 - (a 2 : ℂ) * v 1,
    (a 2 : ℂ) * v 0 - (a 0 : ℂ) * v 2,
    (a 0 : ℂ) * v 1 - (a 1 : ℂ) * v 0]

/-- **The triple product**, in integers: `k × (ν × k) = |k|² ν` when `k ⊥ ν`. This is what turns the
curl into a scalar multiplication, and it is pure lattice algebra — no square root.
Stated one component at a time on purpose: `fin_cases` emits indices as `⟨0, ⋯⟩`, which the
`crossZ_apply_*` simp lemmas — stated for the literals — do not see through. That is the failure
mode already recorded in this repository, and the fix is the same one: never mention a `Fin`
literal produced by `fin_cases`. -/
theorem crossZ_triple_zero {k N : Wavevector} (h : dotZ k N = 0) :
    crossZ k (crossZ N k) 0 = k_sq k * N 0 := by
  rw [dotZ_expand] at h
  have hks : k_sq k = k 0 * k 0 + k 1 * k 1 + k 2 * k 2 := by
    rw [k_sq, Fin.sum_univ_three]; ring
  simp only [crossZ_apply_zero, crossZ_apply_one, crossZ_apply_two, hks]
  linear_combination (-(k 0)) * h

theorem crossZ_triple_one {k N : Wavevector} (h : dotZ k N = 0) :
    crossZ k (crossZ N k) 1 = k_sq k * N 1 := by
  rw [dotZ_expand] at h
  have hks : k_sq k = k 0 * k 0 + k 1 * k 1 + k 2 * k 2 := by
    rw [k_sq, Fin.sum_univ_three]; ring
  simp only [crossZ_apply_zero, crossZ_apply_one, crossZ_apply_two, hks]
  linear_combination (-(k 1)) * h

theorem crossZ_triple_two {k N : Wavevector} (h : dotZ k N = 0) :
    crossZ k (crossZ N k) 2 = k_sq k * N 2 := by
  rw [dotZ_expand] at h
  have hks : k_sq k = k 0 * k 0 + k 1 * k 1 + k 2 * k 2 := by
    rw [k_sq, Fin.sum_univ_three]; ring
  simp only [crossZ_apply_zero, crossZ_apply_one, crossZ_apply_two, hks]
  linear_combination (-(k 2)) * h

/-- The componentwise algebra of H4, isolated so the combination stays linear in the hypotheses.
Reading: `(k × hRaw)_j = |k|² ν_j − i s |k| (ν×k)_j`, and multiplying by `i` returns `s|k|` times
`hRaw`. Both `s² = 1` and `i² = −1` are consumed, and nothing else. -/
theorem curl_eigen_algebra (Aj Nj n S I : ℂ) (hs : S * S = 1) (hI : I * I = -1) :
    I * (Nj * (n * n) - I * S * n * Aj) = S * n * (Aj + I * S * n * Nj) := by
  linear_combination (-(S * n * Aj)) * hI - (I * n * n * Nj) * hs

/-- **H4 — the curl eigenvector property**, componentwise. `i (k × hRaw) = s |k| · hRaw`.

This is the fact the whole decomposition exists for: in this basis the curl, and with it the
vortex-stretching term, stops being a differential operator and becomes multiplication by the
**signed** wavenumber `s|k|`. -/
theorem hRaw_curl_eigen {s : ℝ} (hsq : s * s = 1) (k : Wavevector) (j : Fin 3) :
    Complex.I * (crossRC k (hRaw s k) j) = ((s : ℝ) : ℂ) * ((kNorm k : ℝ) : ℂ) * hRaw s k j := by
  have horth : dotZ k (nuInt k) = 0 := nuInt_orthogonal k
  have hI : Complex.I * Complex.I = -1 := Complex.I_mul_I
  have hs : ((s : ℝ) : ℂ) * ((s : ℝ) : ℂ) = 1 := by
    exact_mod_cast congrArg (fun r : ℝ => ((r : ℂ))) hsq
  -- the integer identity `k × (ν × k) = |k|² ν`, one component at a time
  have hT : ∀ m : Fin 3, crossZ k (crossZ (nuInt k) k) m = k_sq k * nuInt k m := by
    intro m
    fin_cases m
    · simpa using crossZ_triple_zero horth
    · simpa using crossZ_triple_one horth
    · simpa using crossZ_triple_two horth
  have hk2 : ((kNorm k : ℝ) : ℂ) * ((kNorm k : ℝ) : ℂ) = ((k_sq k : ℤ) : ℂ) := by
    exact_mod_cast congrArg (fun r : ℝ => ((r : ℂ))) (kNorm_sq k)
  -- `(k × hRaw)_j = |k|² ν_j − i s |k| (ν × k)_j`
  -- Step A: pure expansion. `(k × hRaw)_j = (k × (ν×k))_j + i s |k| (k × ν)_j`.
  have hexp : crossRC k (hRaw s k) j
      = ((crossZ k (crossZ (nuInt k) k) j : ℤ) : ℂ)
        + Complex.I * ((s : ℝ) : ℂ) * ((kNorm k : ℝ) : ℂ) * ((crossZ k (nuInt k) j : ℤ) : ℂ) := by
    -- unfold the definitions rather than routing through the `crossZ_apply_*` lemmas: `fin_cases`
    -- emits `⟨0, ⋯⟩`, which those literal-indexed lemmas do not match
    fin_cases j <;> simp [crossRC, hRaw, crossZ] <;> push_cast <;> ring
  -- Step B: the two integer identities that make it a scalar multiplication.
  have hanti : crossZ k (nuInt k) j = -crossZ (nuInt k) k j := by
    fin_cases j <;> simp [crossZ] <;> ring
  have hcross : crossRC k (hRaw s k) j
      = ((kNorm k : ℝ) : ℂ) * ((kNorm k : ℝ) : ℂ) * ((nuInt k j : ℤ) : ℂ)
        - Complex.I * ((s : ℝ) : ℂ) * ((kNorm k : ℝ) : ℂ)
          * ((crossZ (nuInt k) k j : ℤ) : ℂ) := by
    rw [hexp, hT j, hanti, hk2]
    push_cast
    ring
  rw [hcross]
  unfold hRaw
  have halg := curl_eigen_algebra ((crossZ (nuInt k) k j : ℤ) : ℂ) ((nuInt k j : ℤ) : ℂ)
    ((kNorm k : ℝ) : ℂ) ((s : ℝ) : ℂ) Complex.I hs hI
  linear_combination halg

/-! ### Audit certificates — no axiom outside [propext, Classical.choice, Quot.sound]. -/
#print axioms dotZ_crossZ_left
#print axioms dotZ_crossZ_self
#print axioms nuInt_orthogonal
#print axioms nuInt_ne_zero
#print axioms kNorm_sq
#print axioms hRaw_transverse
#print axioms hRaw_conj
#print axioms hRaw_self_null
#print axioms hRaw_norm
#print axioms crossZ_triple_zero
#print axioms hRaw_curl_eigen

end MechanicaFluidorum.FourierZ3
