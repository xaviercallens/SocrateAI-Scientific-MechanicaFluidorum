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

/-- `hOf N s k = (N × k) + i s |k| N`, i.e. `|N| |k|` times Waleffe's `h^s(k)` when `N ⊥ k`.

Carrying the scale factor removes every division, so no `k ≠ 0` witness is needed until step 2.

**Parametrised by `ν`** (2026-09-10, D-3 step 2 groundwork). The facts need only `ν ⊥ k`, so they
are proved for an arbitrary such `ν` and specialised to `nuInt`. This is not tidiness: the closed
form of the memo's §4 is derived in the triad's OWN planar frame, so stating it at all requires a
basis that can be handed a different `ν` — the crucible measured a pure phase difference between
conventions, and a statement that hard-codes one convention cannot express it. -/
noncomputable def hOf (N : Wavevector) (s : ℝ) (k : Wavevector) : Fin 3 → ℂ :=
  fun i => ((crossZ N k i : ℤ) : ℂ)
            + Complex.I * (s : ℂ) * ((kNorm k : ℝ) : ℂ) * (((N i : ℤ) : ℂ))

/-- The basis with this file's own canonical choice of `ν`. -/
noncomputable def hRaw (s : ℝ) (k : Wavevector) : Fin 3 → ℂ := hOf (nuInt k) s k

theorem hRaw_eq (s : ℝ) (k : Wavevector) : hRaw s k = hOf (nuInt k) s k := rfl

/-- Bilinear complex dot, no conjugation — the same convention as `FourierStateZ3.fourier_dot`. -/
noncomputable def cdot (v w : Fin 3 → ℂ) : ℂ := ∑ i : Fin 3, v i * w i

theorem cdot_expand (v w : Fin 3 → ℂ) : cdot v w = v 0 * w 0 + v 1 * w 1 + v 2 * w 2 := by
  simp [cdot, Fin.sum_univ_three]

/-! ### 5. The five facts -/

/-- **H3 — transversality**, for an arbitrary `ν ⊥ k`. -/
theorem hOf_transverse {N k : Wavevector} (hN : dotZ k N = 0) (s : ℝ) :
    fourier_dot k (hOf N s k) = 0 := by
  have hA : dotZ k (crossZ N k) = 0 := dotZ_crossZ_right N k
  rw [dotZ_expand] at hA hN
  unfold fourier_dot hOf
  rw [Fin.sum_univ_three]
  have hA' : ((k 0 : ℂ)) * ((crossZ N k 0 : ℤ) : ℂ)
      + ((k 1 : ℂ)) * ((crossZ N k 1 : ℤ) : ℂ)
      + ((k 2 : ℂ)) * ((crossZ N k 2 : ℤ) : ℂ) = 0 := by
    exact_mod_cast congrArg (fun z : ℤ => ((z : ℂ))) hA
  have hN' : ((k 0 : ℂ)) * ((N 0 : ℤ) : ℂ)
      + ((k 1 : ℂ)) * ((N 1 : ℤ) : ℂ)
      + ((k 2 : ℂ)) * ((N 2 : ℤ) : ℂ) = 0 := by
    exact_mod_cast congrArg (fun z : ℤ => ((z : ℂ))) hN
  linear_combination hA' + Complex.I * (s : ℂ) * ((kNorm k : ℝ) : ℂ) * hN'

/-- **H3** for the canonical choice. -/
theorem hRaw_transverse (s : ℝ) (k : Wavevector) : fourier_dot k (hRaw s k) = 0 :=
  hOf_transverse (nuInt_orthogonal k) s

/-- **H5 — reality becomes chirality**, for any `ν`; no orthogonality needed. -/
theorem hOf_conj (N : Wavevector) (s : ℝ) (k : Wavevector) (i : Fin 3) :
    conj (hOf N s k i) = hOf N (-s) k i := by
  unfold hOf
  simp only [map_add, map_mul, Complex.conj_I, Complex.conj_ofReal, map_intCast,
    Complex.ofReal_neg, Complex.ofReal_ratCast]
  push_cast
  ring

/-- **H5** for the canonical choice. -/
theorem hRaw_conj (s : ℝ) (k : Wavevector) (i : Fin 3) :
    conj (hRaw s k i) = hRaw (-s) k i := hOf_conj (nuInt k) s k i

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
  unfold hRaw hOf
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
  unfold hRaw hOf
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

/-- Cross product of two complex vectors, used to build the geometric factor `g`. -/
noncomputable def crossRC' (v w : Fin 3 → ℂ) : Fin 3 → ℂ :=
  ![v 1 * w 2 - v 2 * w 1, v 2 * w 0 - v 0 * w 2, v 0 * w 1 - v 1 * w 0]

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
    fin_cases j <;> simp [crossRC, hRaw, hOf, crossZ] <;> push_cast <;> ring
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
  unfold hRaw hOf
  have halg := curl_eigen_algebra ((crossZ (nuInt k) k j : ℤ) : ℂ) ((nuInt k j : ℤ) : ℂ)
    ((kNorm k : ℝ) : ℂ) ((s : ℝ) : ℂ) Complex.I hs hI
  linear_combination halg

/-! ### 7. The resonance condition, and why it carries no content

`docs/designs/WALEFFE_HELICAL_MEMO.md` §4bis. The closed form's middle vanishing condition is the
**Waleffe resonance condition** `s_k|k| + s_p|p| + s_q|q| = 0`. Established here at Tier A, having
first been established in exact integers over 558 090 lattice triads
(`tests/tier_b_helical_resonance.py`), is that it collapses into the *third* condition: it holds
**exactly when the triad is collinear**, and collinear triads carry no transfer anyway.

**This part is deliberately basis-free.** It mentions no `ν`, so it is immune to the phase ambiguity
that makes the closed form itself frame-dependent — the reason step 2 of the memo's §7 needs the
basis parametrised by `ν` before it can be stated, and the reason this part could be done first. -/

/-- A vector with vanishing self-dot is zero. Over `ℤ` this is the sum-of-three-squares argument. -/
theorem eq_zero_of_dotZ_self_eq_zero {v : Wavevector} (h : dotZ v v = 0) : v = 0 := by
  rw [dotZ_expand] at h
  have h0 : v 0 * v 0 = 0 := by
    nlinarith [mul_self_nonneg (v 0), mul_self_nonneg (v 1), mul_self_nonneg (v 2)]
  have h1 : v 1 * v 1 = 0 := by
    nlinarith [mul_self_nonneg (v 0), mul_self_nonneg (v 1), mul_self_nonneg (v 2)]
  have h2 : v 2 * v 2 = 0 := by
    nlinarith [mul_self_nonneg (v 0), mul_self_nonneg (v 1), mul_self_nonneg (v 2)]
  funext i
  fin_cases i
  · simpa using mul_self_eq_zero.mp h0
  · simpa using mul_self_eq_zero.mp h1
  · simpa using mul_self_eq_zero.mp h2

/-- `|p+q|² = |p|² + 2 p·q + |q|²`, in integers. -/
theorem k_sq_add (p q : Wavevector) : k_sq (p + q) = k_sq p + 2 * dotZ p q + k_sq q := by
  simp only [k_sq, dotZ_expand, Fin.sum_univ_three, Pi.add_apply]
  ring

/-- **Equality in the triangle inequality forces collinearity** — the whole content of the
resonance condition, in the form the lattice needs.

Given `p + q = k` and `|k| = |p| + |q|`, the two vectors are parallel: `p × q = 0`.
The proof is Cauchy–Schwarz through Lagrange's identity, and every step after the single squaring
is integer arithmetic. -/
theorem crossZ_eq_zero_of_kNorm_add {p q k : Wavevector} (hpq : p + q = k)
    (h : kNorm k = kNorm p + kNorm q) : crossZ p q = 0 := by
  -- square the hypothesis: |k|² = |p|² + 2|p||q| + |q|²
  have hsq : (k_sq k : ℝ) = (k_sq p : ℝ) + 2 * (kNorm p * kNorm q) + (k_sq q : ℝ) := by
    have hk := kNorm_sq k
    rw [h] at hk
    nlinarith [kNorm_sq p, kNorm_sq q, hk]
  -- but also |k|² = |p|² + 2 p·q + |q|², so p·q = |p||q|
  have hdot : ((dotZ p q : ℤ) : ℝ) = kNorm p * kNorm q := by
    have hk : k_sq k = k_sq p + 2 * dotZ p q + k_sq q := by rw [← hpq]; exact k_sq_add p q
    have hkR : (k_sq k : ℝ) = (k_sq p : ℝ) + 2 * ((dotZ p q : ℤ) : ℝ) + (k_sq q : ℝ) := by
      exact_mod_cast congrArg (fun z : ℤ => ((z : ℝ))) hk
    linarith [hsq, hkR]
  -- squaring that gives (p·q)² = |p|²|q|², i.e. Lagrange's identity has a zero left-hand side
  have hsquare : ((dotZ p q : ℤ) : ℝ) * ((dotZ p q : ℤ) : ℝ) = (k_sq p : ℝ) * (k_sq q : ℝ) := by
    rw [hdot]
    have := kNorm_sq p
    have := kNorm_sq q
    nlinarith [kNorm_sq p, kNorm_sq q]
  have hsquareZ : dotZ p q * dotZ p q = k_sq p * k_sq q := by exact_mod_cast hsquare
  have hlag : dotZ (crossZ p q) (crossZ p q) = 0 := by
    rw [dotZ_crossZ_self, dotZ_self_eq_k_sq, dotZ_self_eq_k_sq, hsquareZ]
    ring
  exact eq_zero_of_dotZ_self_eq_zero hlag

/-- **The resonance condition implies collinearity.** Stated for the sign pattern in which the
odd-one-out is `k`; the other two patterns are the same statement after relabelling, since
`p + q = k` may be rewritten as `p = k − q` or `q = k − p`. -/
theorem resonance_implies_collinear {p q k : Wavevector} (hpq : p + q = k)
    (h : -kNorm k + kNorm p + kNorm q = 0) : crossZ p q = 0 :=
  crossZ_eq_zero_of_kNorm_add hpq (by linarith)

/-- Non-vacuity (SPEC §7.5): a genuine lattice triad on which the hypothesis holds, so the theorem
above is not a statement about the empty set. `p = q = (1,0,0)`, `k = (2,0,0)`, `2 = 1 + 1`. -/
theorem resonance_witness :
    (![1,0,0] : Wavevector) + (![1,0,0] : Wavevector) = (![2,0,0] : Wavevector) := by
  funext i
  fin_cases i <;> simp

/-! ### 8. The triad's own frame, and the first non-degenerate vanishing condition

D-3 step 2 needs all three members of a triad expanded in **one common** `ν`, namely the normal to
the triad plane. On the lattice that normal is available **as an integer vector**: `p × q`. It is
orthogonal to `p`, to `q`, and — because `k = p + q` — to `k` as well, so one `hOf` frame serves the
whole triad with no normalisation and no division. -/

/-- The triad plane's normal, integer-valued. -/
def triadNormal (p q : Wavevector) : Wavevector := crossZ p q

theorem triadNormal_orthogonal_left (p q : Wavevector) : dotZ p (triadNormal p q) = 0 :=
  dotZ_crossZ_left p q

theorem triadNormal_orthogonal_right (p q : Wavevector) : dotZ q (triadNormal p q) = 0 :=
  dotZ_crossZ_right p q

/-- **One frame for the whole triad.** The plane normal is orthogonal to `k = p + q` too. -/
theorem triadNormal_orthogonal_sum (p q : Wavevector) : dotZ (p + q) (triadNormal p q) = 0 := by
  have hp := triadNormal_orthogonal_left p q
  have hq := triadNormal_orthogonal_right p q
  rw [dotZ_expand] at hp hq ⊢
  simp only [Pi.add_apply]
  linarith [hp, hq]

/-- The triad frame degenerates exactly on collinear triads — which, by §7, are exactly the
resonant ones. So the frame is available precisely where the coefficient has content. -/
theorem triadNormal_eq_zero_iff_collinear (p q : Wavevector) :
    triadNormal p q = 0 ↔ crossZ p q = 0 := Iff.rfl

/-! ### 9. The interaction coefficient, and the condition that genuinely kills it -/

/-- The geometric factor `g = (h^{s_p}(p) × h^{s_q}(q)) · conj(h^{s_k}(k))`, in one common frame
`N`. Unnormalised, so this is `|N|³|p||q||k|` times the memo's `g` — the scale is a nonzero factor
and so is irrelevant to every vanishing statement below. -/
noncomputable def gOf (N : Wavevector) (sk sp sq : ℝ) (k p q : Wavevector) : ℂ :=
  cdot (crossRC' (hOf N sp p) (hOf N sq q)) (fun i => conj (hOf N sk k i))

/-- **The interaction coefficient** of the memo's §3, in the same unnormalised frame:
`C = −¼ (s_p|p| − s_q|q|) · g`. -/
noncomputable def cOf (N : Wavevector) (sk sp sq : ℝ) (k p q : Wavevector) : ℂ :=
  (-(1 : ℂ) / 4) * (((sp : ℝ) : ℂ) * ((kNorm p : ℝ) : ℂ)
                    - ((sq : ℝ) : ℂ) * ((kNorm q : ℝ) : ℂ)) * gOf N sk sp sq k p q

/-- **The first vanishing condition, and the only non-degenerate one that survives §7.**
`C = 0` whenever `s_p|p| = s_q|q|`.

It needs no closed form and no frame: it is immediate from the antisymmetrisation factor. Its
content is that on the lattice it is *satisfied*, and often — every pair of modes on a common
sphere with equal chirality has `|p| = |q|`, and lattice spheres are heavily populated. That is
what distinguishes it from the resonance condition, which §7 shows to be empty. -/
theorem cOf_eq_zero_of_balanced (N : Wavevector) (sk sp sq : ℝ) (k p q : Wavevector)
    (h : sp * kNorm p = sq * kNorm q) : cOf N sk sp sq k p q = 0 := by
  unfold cOf
  have hz : ((sp : ℝ) : ℂ) * ((kNorm p : ℝ) : ℂ) - ((sq : ℝ) : ℂ) * ((kNorm q : ℝ) : ℂ) = 0 := by
    have : ((sp * kNorm p : ℝ) : ℂ) = ((sq * kNorm q : ℝ) : ℂ) :=
      congrArg (fun r : ℝ => ((r : ℂ))) h
    push_cast at this
    linear_combination this
  rw [hz]
  ring

/-- Non-vacuity (SPEC §7.5): the balanced condition is satisfiable on the lattice by a genuine,
NON-collinear triad — so `cOf_eq_zero_of_balanced` is not a restatement of §7's collinear case.
`p = (1,0,0)` and `q = (0,1,0)` share the unit sphere, `p × q = (0,0,1) ≠ 0`. -/
theorem balanced_witness_noncollinear :
    kNorm (![1,0,0] : Wavevector) = kNorm (![0,1,0] : Wavevector)
      ∧ crossZ (![1,0,0] : Wavevector) (![0,1,0] : Wavevector) ≠ 0 := by
  constructor
  · unfold kNorm
    congr 1
  · intro hc
    have hlast := congrFun hc 2
    simp only [crossZ_apply_two, Matrix.cons_val_zero, Matrix.cons_val_one,
      Pi.zero_apply] at hlast
    norm_num at hlast

/-! ### 10. Closing the chain: resonance ⟹ collinear ⟹ the coefficient vanishes

§7 proved that the resonance condition is exactly collinearity. §8 observed that the triad frame is
`p × q`, which is *zero* exactly on collinear triads. This section joins them: in the triad's own
frame a collinear triad has no frame at all, every helical vector degenerates, and the coefficient
vanishes for the second time — for a reason that has nothing to do with chirality.

The chain is what D-3 step 3 asked for, and its conclusion is the negative one: the resonance
condition kills the coefficient, but only by way of a degeneracy that kills it anyway. -/

theorem crossZ_zero_left (k : Wavevector) : crossZ 0 k = 0 := by
  funext i
  fin_cases i <;> simp [crossZ]

/-- With a degenerate frame every helical vector collapses. -/
theorem hOf_zero_normal (s : ℝ) (k : Wavevector) : hOf 0 s k = 0 := by
  funext i
  unfold hOf
  rw [crossZ_zero_left k]
  simp

/-- Hence the geometric factor vanishes. -/
theorem gOf_eq_zero_of_normal_zero (sk sp sq : ℝ) (k p q : Wavevector) :
    gOf 0 sk sp sq k p q = 0 := by
  unfold gOf
  rw [hOf_zero_normal sp p, hOf_zero_normal sq q]
  simp [crossRC', cdot, Fin.sum_univ_three]

/-- **A collinear triad carries no interaction**, in its own frame — the third vanishing locus of
the memo's §4, and the one the resonance condition turns out to reduce to. -/
theorem cOf_eq_zero_of_collinear (sk sp sq : ℝ) (k p q : Wavevector)
    (h : crossZ p q = 0) : cOf (triadNormal p q) sk sp sq k p q = 0 := by
  unfold cOf
  have hN : triadNormal p q = 0 := h
  rw [hN, gOf_eq_zero_of_normal_zero]
  ring

/-- **The chain, closed.** For a triad `p + q = k`, the Waleffe resonance condition implies that
the interaction coefficient vanishes — but by way of collinearity, so it selects nothing that the
degeneracy did not already select. This is the formal counterpart of the exact-arithmetic sweep
that found zero non-collinear resonant triads among 558 090. -/
theorem cOf_eq_zero_of_resonance (sk sp sq : ℝ) {k p q : Wavevector} (hpq : p + q = k)
    (hres : -kNorm k + kNorm p + kNorm q = 0) :
    cOf (triadNormal p q) sk sp sq k p q = 0 :=
  cOf_eq_zero_of_collinear sk sp sq k p q (resonance_implies_collinear hpq hres)

/-! ### 11. The chain, for ALL THREE sign patterns

§10 closed the chain for one sign pattern only — the one in which `k` is the odd one out. The
resonance condition `s_k|k| + s_p|p| + s_q|q| = 0` admits **three**, according to which member
carries the dissenting sign, and a theorem covering one of them is not the theorem. This section
closes the other two and then the general statement. -/

theorem crossZ_self (a : Wavevector) : crossZ a a = 0 := by
  funext i; fin_cases i <;> simp [crossZ] <;> ring

theorem crossZ_neg_right (a b : Wavevector) : crossZ a (-b) = -crossZ a b := by
  funext i; fin_cases i <;> simp [crossZ] <;> ring

theorem crossZ_sub_left (a b c : Wavevector) :
    crossZ (a - b) c = crossZ a c - crossZ b c := by
  funext i; fin_cases i <;> simp [crossZ] <;> ring

theorem crossZ_antisymm (a b : Wavevector) : crossZ a b = -crossZ b a := by
  funext i; fin_cases i <;> simp [crossZ] <;> ring

theorem kNorm_neg (k : Wavevector) : kNorm (-k) = kNorm k := by
  unfold kNorm; rw [k_sq_neg]

/-- Pattern 2: `|p| = |k| + |q|`. Rewrite `p + q = k` as `k + (−q) = p` and apply §7. -/
theorem resonance_pattern_p {p q k : Wavevector} (hpq : p + q = k)
    (h : kNorm p = kNorm k + kNorm q) : crossZ p q = 0 := by
  have hsum : k + (-q) = p := by rw [← hpq]; abel
  have hn : kNorm p = kNorm k + kNorm (-q) := by rw [kNorm_neg]; exact h
  have hkq : crossZ k (-q) = 0 := crossZ_eq_zero_of_kNorm_add hsum hn
  have hkq' : crossZ k q = 0 := by
    have := crossZ_neg_right k q
    rw [this] at hkq
    simpa using hkq
  have hp : p = k - q := by rw [← hpq]; abel
  rw [hp, crossZ_sub_left, hkq', crossZ_self]
  simp

/-- Pattern 3: `|q| = |k| + |p|`. Symmetric to pattern 2. -/
theorem resonance_pattern_q {p q k : Wavevector} (hpq : p + q = k)
    (h : kNorm q = kNorm k + kNorm p) : crossZ p q = 0 := by
  have hsum : k + (-p) = q := by rw [← hpq]; abel
  have hn : kNorm q = kNorm k + kNorm (-p) := by rw [kNorm_neg]; exact h
  have hkp : crossZ k (-p) = 0 := crossZ_eq_zero_of_kNorm_add hsum hn
  have hkp' : crossZ k p = 0 := by
    have := crossZ_neg_right k p
    rw [this] at hkp
    simpa using hkp
  have hq : q = k - p := by rw [← hpq]; abel
  rw [hq, crossZ_antisymm p (k - p), crossZ_sub_left, hkp', crossZ_self]
  simp

/-- **The resonance condition, in full generality, implies collinearity.**

`s_k, s_p, s_q ∈ {±1}` and `s_k|k| + s_p|p| + s_q|q| = 0` with all three magnitudes strictly
positive. The signs cannot all agree — a sum of three positive numbers is positive — so exactly one
dissents, and each of the three possibilities is one of §7's or §11's patterns. -/
theorem resonance_implies_collinear_full {p q k : Wavevector}
    {sk sp sq : ℝ} (hsk : sk = 1 ∨ sk = -1) (hsp : sp = 1 ∨ sp = -1) (hsq : sq = 1 ∨ sq = -1)
    (hpq : p + q = k)
    (hkpos : 0 < kNorm k) (hppos : 0 < kNorm p) (hqpos : 0 < kNorm q)
    (h : sk * kNorm k + sp * kNorm p + sq * kNorm q = 0) : crossZ p q = 0 := by
  rcases hsk with rfl | rfl <;> rcases hsp with rfl | rfl <;> rcases hsq with rfl | rfl <;>
    simp only [one_mul, neg_mul] at h
  · linarith                                            -- (+,+,+): impossible
  · exact resonance_pattern_q hpq (by linarith)          -- (+,+,−)
  · exact resonance_pattern_p hpq (by linarith)          -- (+,−,+)
  · exact resonance_implies_collinear hpq (by linarith)  -- (+,−,−)
  · exact resonance_implies_collinear hpq (by linarith)  -- (−,+,+)
  · exact resonance_pattern_p hpq (by linarith)          -- (−,+,−)
  · exact resonance_pattern_q hpq (by linarith)          -- (−,−,+)
  · linarith                                            -- (−,−,−): impossible

/-- **THE CHAIN, COMPLETE.** For every admissible sign pattern, the Waleffe resonance condition
forces the interaction coefficient to vanish — and does so through collinearity, so it selects
nothing that the degeneracy had not already selected. -/
theorem cOf_eq_zero_of_resonance_full {p q k : Wavevector} {sk sp sq : ℝ}
    (hsk : sk = 1 ∨ sk = -1) (hsp : sp = 1 ∨ sp = -1) (hsq : sq = 1 ∨ sq = -1)
    (hpq : p + q = k)
    (hkpos : 0 < kNorm k) (hppos : 0 < kNorm p) (hqpos : 0 < kNorm q)
    (h : sk * kNorm k + sp * kNorm p + sq * kNorm q = 0) :
    cOf (triadNormal p q) sk sp sq k p q = 0 :=
  cOf_eq_zero_of_collinear sk sp sq k p q
    (resonance_implies_collinear_full hsk hsp hsq hpq hkpos hppos hqpos h)

/-! ### 12. D-3 step 2: the closed form, and the converse

Everything so far has been *sufficient* conditions for the coefficient to vanish, proved one locus
at a time. This section proves the identity the memo's §4 derives, from which all three drop out at
once — and, because `ℂ` has no zero divisors, so does the **converse**: those three loci are the
*only* places the coefficient vanishes.

In the triad's own frame `N = p × q` the memo's `S_pq` and `|N|²` are the same integer, so the
memo's `(i S_pq / 4|k|)` becomes `(i/4)·(k_sq (p × q))²` in this file's unnormalised scaling. The
scale is a positive factor on non-collinear triads and so changes no vanishing statement.

The derivation needs three unconditional vector identities and two that hold because `p × q` is
orthogonal to both `p` and `q` — automatic here, since the frame *is* `p × q`. -/

/-- `(N × p) × (N × q) = (N · (p × q)) N`, for all `N, p, q`. This is what makes the leading,
chirality-free term drop out: it is parallel to `N`, while `N × k` is orthogonal to `N`. -/
theorem crossZ_crossZ_crossZ (N p q : Wavevector) :
    crossZ (crossZ N p) (crossZ N q) = fun i => dotZ N (crossZ p q) * N i := by
  funext i
  fin_cases i <;> simp [crossZ, dotZ, Fin.sum_univ_three] <;> ring

/-- The back-cab identity `N × (N × p) = (N · p) N − |N|² p`. With `N ⊥ p` it is the rotation by a
quarter turn in the plane that the whole collapse turns on. -/
theorem crossZ_crossZ_self (N p : Wavevector) :
    crossZ N (crossZ N p) = fun i => dotZ N p * N i - k_sq N * p i := by
  funext i
  fin_cases i <;> simp [crossZ, dotZ, k_sq, Fin.sum_univ_three] <;> ring

/-- **The closed form (memo §4), in the triad's own frame.**

`g = − i · (k_sq (p × q))² · (s_p|p| + s_q|q| + s_k|k|)`

Every dependence on the *shape* of the triad is carried by the single integer `k_sq (p × q)`, common
to all eight chirality classes; the chirality enters only through the sum of the **signed helical
wavenumbers**. That is the algebraic structure D-3 asked for.

The proof needs no `I² = −1`: the terms quadratic in `I` are each a triple product of the form
`(N × x) · N`, identically zero, so `I` survives only linearly. -/
theorem gOf_closed_form {p q k : Wavevector} (hpq : p + q = k) (sk sp sq : ℝ) :
    gOf (triadNormal p q) sk sp sq k p q
      = -Complex.I * ((k_sq (crossZ p q) : ℤ) : ℂ) ^ 2
        * (((sp : ℝ) : ℂ) * ((kNorm p : ℝ) : ℂ) + ((sq : ℝ) : ℂ) * ((kNorm q : ℝ) : ℂ)
            + ((sk : ℝ) : ℂ) * ((kNorm k : ℝ) : ℂ)) := by
  subst hpq
  simp only [gOf, cdot, crossRC', hOf, triadNormal, k_sq, Fin.sum_univ_three,
    map_add, map_mul, Complex.conj_I, Complex.conj_ofReal, map_intCast,
    Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons,
    Matrix.cons_val_two, Matrix.tail_cons, Pi.add_apply,
    crossZ_apply_zero, crossZ_apply_one, crossZ_apply_two]
  push_cast
  ring

/-- **The closed form for the coefficient itself** — the memo's boxed equation. Three factors, and
each is one of the memo's three vanishing conditions. -/
theorem cOf_closed_form {p q k : Wavevector} (hpq : p + q = k) (sk sp sq : ℝ) :
    cOf (triadNormal p q) sk sp sq k p q
      = (Complex.I / 4) * ((k_sq (crossZ p q) : ℤ) : ℂ) ^ 2
        * (((sp : ℝ) : ℂ) * ((kNorm p : ℝ) : ℂ) + ((sq : ℝ) : ℂ) * ((kNorm q : ℝ) : ℂ)
            + ((sk : ℝ) : ℂ) * ((kNorm k : ℝ) : ℂ))
        * (((sp : ℝ) : ℂ) * ((kNorm p : ℝ) : ℂ) - ((sq : ℝ) : ℂ) * ((kNorm q : ℝ) : ℂ)) := by
  unfold cOf
  rw [gOf_closed_form hpq]
  ring

/-- The same identity with each real factor packed into a single cast, which is the form the
converse needs. -/
theorem cOf_closed_form_packed {p q k : Wavevector} (hpq : p + q = k) (sk sp sq : ℝ) :
    cOf (triadNormal p q) sk sp sq k p q
      = (Complex.I / 4) * ((k_sq (crossZ p q) : ℤ) : ℂ) ^ 2
        * ((sp * kNorm p + sq * kNorm q + sk * kNorm k : ℝ) : ℂ)
        * ((sp * kNorm p - sq * kNorm q : ℝ) : ℂ) := by
  rw [cOf_closed_form hpq]
  push_cast
  ring

/-- **THE CONVERSE — and this is what the closed form buys that the vanishing theorems could not.**

Every result up to §11 was one-directional: *these* conditions kill the coefficient. None of them
excluded a fourth, unnoticed vanishing locus, and a programme looking for inert triads would have
had no way to know when it had found them all. Because `ℂ` has no zero divisors, the closed form
settles it: the coefficient vanishes **exactly** on the three loci and nowhere else.

For a triad `p + q = k`, `C = 0` if and only if one of

* `p × q = 0` — the triad is collinear and has no plane to transfer in;
* `s_p|p| + s_q|q| + s_k|k| = 0` — the Waleffe resonance condition, which §11 proves is the first
  condition again;
* `s_p|p| = s_q|q|` — the balance condition, the only non-degenerate one, with a non-collinear
  lattice witness in `balanced_witness_noncollinear`.

Read with §11, the inventory of inert triads is now **complete and consists of two items**, one of
which is empty of content. -/
theorem cOf_eq_zero_iff {p q k : Wavevector} (hpq : p + q = k) (sk sp sq : ℝ) :
    cOf (triadNormal p q) sk sp sq k p q = 0
      ↔ crossZ p q = 0
        ∨ sp * kNorm p + sq * kNorm q + sk * kNorm k = 0
        ∨ sp * kNorm p = sq * kNorm q := by
  rw [cOf_closed_form_packed hpq]
  have hI : (Complex.I / 4) ≠ 0 := div_ne_zero Complex.I_ne_zero (by norm_num)
  constructor
  · intro h
    rcases mul_eq_zero.mp h with h1 | h2
    · rcases mul_eq_zero.mp h1 with h3 | h4
      · rcases mul_eq_zero.mp h3 with h5 | h6
        · exact absurd h5 hI
        · refine Or.inl ((k_sq_eq_zero_iff _).mp ?_)
          exact_mod_cast sq_eq_zero_iff.mp h6
      · exact Or.inr (Or.inl (Complex.ofReal_eq_zero.mp h4))
    · exact Or.inr (Or.inr (sub_eq_zero.mp (Complex.ofReal_eq_zero.mp h2)))
  · rintro (h | h | h)
    · rw [(k_sq_eq_zero_iff _).mpr h]
      push_cast
      ring
    · rw [h]
      push_cast
      ring
    · rw [sub_eq_zero.mpr h]
      push_cast
      ring

/-! #### The closed form re-derives §10 and §11 — an independent check on its signs

The three vanishing theorems above were proved *geometrically*, by degenerating the frame. The
closed form is an *algebraic* derivation that never mentions a degenerate frame. Re-deriving the
same three statements from it is therefore a genuine cross-check, and one with teeth: had the
balance factor come out as `s_p|p| + s_q|q|`, or the geometric factor with any sign flipped, the
resonance corollary below would not close. This is precisely the check the memo's first draft
failed. -/

theorem cOf_eq_zero_of_collinear' {p q k : Wavevector} (hpq : p + q = k) (sk sp sq : ℝ)
    (h : crossZ p q = 0) : cOf (triadNormal p q) sk sp sq k p q = 0 :=
  (cOf_eq_zero_iff hpq sk sp sq).mpr (Or.inl h)

theorem cOf_eq_zero_of_balanced' {p q k : Wavevector} (hpq : p + q = k) (sk sp sq : ℝ)
    (h : sp * kNorm p = sq * kNorm q) : cOf (triadNormal p q) sk sp sq k p q = 0 :=
  (cOf_eq_zero_iff hpq sk sp sq).mpr (Or.inr (Or.inr h))

/-- The resonance condition, straight off the closed form, with **no appeal to §11's geometry**.
Two independent derivations of the same theorem. -/
theorem cOf_eq_zero_of_resonance_algebraic {p q k : Wavevector} (hpq : p + q = k) (sk sp sq : ℝ)
    (hres : sk * kNorm k + sp * kNorm p + sq * kNorm q = 0) :
    cOf (triadNormal p q) sk sp sq k p q = 0 :=
  (cOf_eq_zero_iff hpq sk sp sq).mpr (Or.inr (Or.inl (by linarith)))

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
#print axioms eq_zero_of_dotZ_self_eq_zero
#print axioms k_sq_add
#print axioms crossZ_eq_zero_of_kNorm_add
#print axioms resonance_implies_collinear
#print axioms resonance_witness
#print axioms hOf_transverse
#print axioms triadNormal_orthogonal_sum
#print axioms cOf_eq_zero_of_balanced
#print axioms balanced_witness_noncollinear
#print axioms hOf_zero_normal
#print axioms cOf_eq_zero_of_collinear
#print axioms cOf_eq_zero_of_resonance
#print axioms resonance_pattern_p
#print axioms resonance_pattern_q
#print axioms resonance_implies_collinear_full
#print axioms cOf_eq_zero_of_resonance_full
#print axioms crossZ_crossZ_crossZ
#print axioms crossZ_crossZ_self
#print axioms gOf_closed_form
#print axioms cOf_closed_form
#print axioms cOf_eq_zero_iff
#print axioms cOf_eq_zero_of_resonance_algebraic

end MechanicaFluidorum.FourierZ3
