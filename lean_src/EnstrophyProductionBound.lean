/-
  EnstrophyProductionBound.lean — Tier A: sqrt-free local bound `S_N² ≤ 2·Ω_N³`
  =============================================================================
  Formalizes `docs/designs/ENSTROPHY_PRODUCTION_BOUND.md`, which builds on the
  proven production identity of `lean_src/EnstrophyProduction.lean`:

      Σ_{n=0}^{N} k_n² a_n NL_n  =  3 · S_N ,
      S_N := Σ_{n=0}^{N-1} k_n³ a_n² a_{n+1} = Σ_{n=0}^{N-1} prodOut k a n .

  The bound proven here is

      S_N²  ≤  2 · Ω_N³ ,      Ω_N := ½ Σ_{n=0}^{N} k_n² a_n² ,

  under the dyadic doubling hypothesis `k_{n+1} = 2 k_n` on the active shells.
  No boundary condition `a_{N+1} = 0` is needed: the bound is unconditional in `a`.

  ---------------------------------------------------------------------------
  BUILD NOTE (read before asking why `EnstrophyProduction` is not imported).
  ---------------------------------------------------------------------------
  `scripts/verify.sh` compiles every file in `lean_src/` STANDALONE via
  `lake env lean` against an external Mathlib build; `lean_src` is NOT on
  `LEAN_PATH` and no `.olean` is produced for the project's own modules, so
  `import EnstrophyProduction` fails with

      error: unknown module prefix 'EnstrophyProduction'

  (verified 2026-08-12 with the mandated command).  Accordingly this file does
  NOT import that module and — deliberately — does NOT redefine `prodOut` under
  any name.  Instead the production sum is written in the LITERALLY IDENTICAL
  expanded form `(k n)^3 * (a n)^2 * a (n+1)` that `EnstrophyProduction.lean`
  itself uses in the statement of `enstrophy_production_dyadic_NL`, so the two
  files' production sums are the same expression, term for term.

  Exact-ℚ certification: `tests/tier_b_production_bound.py` (Tier B, Fraction
  only, 240 (N,p,q) cases for each of Step 1 / Step 2 / Step 3 / MAIN over
  N = 1..12 × 20 states with k_n = 2^n; Step-1 negative control confirmed to
  FAIL genuinely for k_n = n+1 (211/240 cases) and k_n = 1 (230/240 cases)).

  Gate: `#print axioms` for every theorem below must report exactly
  [propext, Classical.choice, Quot.sound].
-/
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.BigOperators.Ring.Finset
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Finset.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum

namespace MechanicaFluidorum.EnstrophyProductionBound

/-! ### The enstrophy functional

`Ω_N = ½ Σ_{n=0}^{N} k_n² a_n²` — PLAN.md §5's "enstrophy analogue", indexed so
that the sum runs over `Finset.range (N+1)`, i.e. shells `0 … N` inclusive,
matching the convention of `EnstrophyProduction.lean`. -/

/-- Enstrophy of the truncated dyadic state: `Ω_N = ½ Σ_{n=0}^{N} k_n² a_n²`. -/
noncomputable def Omega (k a : ℕ → ℝ) (N : ℕ) : ℝ :=
  (1/2) * (Finset.range (N+1)).sum (fun n => (k n)^2 * (a n)^2)

/-- `Ω_N ≥ 0`: it is a half-sum of products of squares. -/
theorem Omega_nonneg (k a : ℕ → ℝ) (N : ℕ) : 0 ≤ Omega k a N := by
  unfold Omega
  have h : (0:ℝ) ≤ (Finset.range (N+1)).sum (fun n => (k n)^2 * (a n)^2) :=
    Finset.sum_nonneg (fun i _ => mul_nonneg (sq_nonneg _) (sq_nonneg _))
  linarith

/-- The unhalved enstrophy sum is `2 Ω_N`.  Used to convert the design note's
    `Σ x_n = 2 Ω_N` step. -/
theorem sum_sq_eq_two_mul_Omega (k a : ℕ → ℝ) (N : ℕ) :
    (Finset.range (N+1)).sum (fun n => (k n)^2 * (a n)^2) = 2 * Omega k a N := by
  unfold Omega; ring

/-! ### Step 1 — the doubling step (pure algebra, no inequality machinery)

Design note Step 1: reindexing `m = n+1` and using `k_n = k_{n+1}/2`,

    Σ_{n=0}^{N-1} k_n² a_{n+1}²  =  ¼ Σ_{m=1}^{N} k_m² a_m²  ≤  Ω_N / 2 ,

the last step discarding the missing `m = 0` term, which is `≥ 0`. -/

/-- **Step 1 (design-note constant).**  Under dyadic doubling on the active
    shells, `Σ_{n<N} k_n² a_{n+1}² ≤ Ω_N / 2`.  This is the tight constant of
    `docs/designs/ENSTROPHY_PRODUCTION_BOUND.md`; the witness below shows it is
    near-saturated (40 ≤ 161/4) and that `Ω_N / 4` would be FALSE. -/
theorem step1_flux_bound_half (k a : ℕ → ℝ) (N : ℕ)
    (hdouble : ∀ n, n < N → k (n+1) = 2 * k n) :
    (Finset.range N).sum (fun n => (k n)^2 * (a (n+1))^2) ≤ Omega k a N / 2 := by
  -- Rewrite each `k n` as `k (n+1) / 2` via the doubling hypothesis.
  have key : (Finset.range N).sum (fun n => (k n)^2 * (a (n+1))^2)
      = (1/4) * (Finset.range N).sum (fun n => (k (n+1))^2 * (a (n+1))^2) := by
    rw [Finset.mul_sum]
    refine Finset.sum_congr rfl ?_
    intro i hi
    rw [hdouble i (Finset.mem_range.mp hi)]
    ring
  -- Peel the `n = 0` term off the enstrophy sum (the reindexing `m = n+1`).
  have hsplit : (Finset.range (N+1)).sum (fun n => (k n)^2 * (a n)^2)
      = (Finset.range N).sum (fun n => (k (n+1))^2 * (a (n+1))^2) + (k 0)^2 * (a 0)^2 :=
    Finset.sum_range_succ' (fun n => (k n)^2 * (a n)^2) N
  have hT : (0:ℝ) ≤ (Finset.range N).sum (fun n => (k (n+1))^2 * (a (n+1))^2) :=
    Finset.sum_nonneg (fun i _ => mul_nonneg (sq_nonneg _) (sq_nonneg _))
  have h0 : (0:ℝ) ≤ (k 0)^2 * (a 0)^2 := mul_nonneg (sq_nonneg _) (sq_nonneg _)
  unfold Omega
  rw [key, hsplit]
  linarith

/-- **Step 1 (looser form, exactly as stated in the task dispatch).**  Immediate
    from `step1_flux_bound_half` and `Omega_nonneg`.  Kept so that the dispatched
    statement literally exists in the kernel; the MAIN theorem uses the *half*
    version, which is what yields the design note's constant `2`. -/
theorem step1_flux_bound (k a : ℕ → ℝ) (N : ℕ)
    (hdouble : ∀ n, n < N → k (n+1) = 2 * k n) :
    (Finset.range N).sum (fun n => (k n)^2 * (a (n+1))^2) ≤ Omega k a N := by
  have h := step1_flux_bound_half k a N hdouble
  have h2 := Omega_nonneg k a N
  linarith

/-! ### Step 2 — the quartic sum (`Σ x_n² ≤ (Σ x_n)²` for `x_n ≥ 0`)

Design note Step 2, with `x_n := k_n² a_n² ≥ 0`.  Mathlib's
`Finset.sum_sq_le_sq_sum_of_nonneg` is exactly this statement; no hypothesis on
`a` is needed since `x_n` is a product of squares. -/

/-- **Step 2.**  `Σ_{n<N} k_n⁴ a_n⁴ ≤ 4 Ω_N²`.  The restricted range `n < N` is
    the quantity Step 3's Cauchy–Schwarz literally consumes; it is bounded by
    the full-range `n ≤ N` sum because every summand is `≥ 0`. -/
theorem step2_quartic_bound (k a : ℕ → ℝ) (N : ℕ) :
    (Finset.range N).sum (fun n => (k n)^4 * (a n)^4) ≤ 4 * (Omega k a N)^2 := by
  -- (a) restricted range ≤ full range, all summands nonneg
  have hnn : ∀ i, (0:ℝ) ≤ (k i)^4 * (a i)^4 := by
    intro i
    have h : (k i)^4 * (a i)^4 = ((k i)^2 * (a i)^2)^2 := by ring
    rw [h]; exact sq_nonneg _
  have hsubset : Finset.range N ⊆ Finset.range (N+1) := by
    intro x hx
    rw [Finset.mem_range] at hx ⊢
    exact Nat.lt_succ_of_lt hx
  have hsub : (Finset.range N).sum (fun n => (k n)^4 * (a n)^4)
      ≤ (Finset.range (N+1)).sum (fun n => (k n)^4 * (a n)^4) :=
    Finset.sum_le_sum_of_subset_of_nonneg hsubset (fun i _ _ => hnn i)
  -- (b) full range: Σ x_n² ≤ (Σ x_n)² with x_n = k_n² a_n² ≥ 0
  have hx : ∀ i ∈ Finset.range (N+1), (0:ℝ) ≤ (k i)^2 * (a i)^2 :=
    fun i _ => mul_nonneg (sq_nonneg _) (sq_nonneg _)
  have hCS := Finset.sum_sq_le_sq_sum_of_nonneg
      (s := Finset.range (N+1)) (f := fun n => (k n)^2 * (a n)^2) hx
  have hEq : (Finset.range (N+1)).sum (fun n => (k n)^4 * (a n)^4)
      = (Finset.range (N+1)).sum (fun n => ((k n)^2 * (a n)^2)^2) :=
    Finset.sum_congr rfl (fun i _ => by ring)
  have hRHS : ((Finset.range (N+1)).sum (fun n => (k n)^2 * (a n)^2))^2
      = 4 * (Omega k a N)^2 := by
    rw [sum_sq_eq_two_mul_Omega]; ring
  rw [hEq] at hsub
  have := le_trans hsub hCS
  rw [hRHS] at this
  exact this

/-! ### Step 3 — Cauchy–Schwarz

Design note Step 3, on the two sequences `f_n := k_n² a_n²` and `g_n := k_n a_{n+1}`,
whose product is `f_n g_n = k_n³ a_n² a_{n+1}` — i.e. exactly the summand of
`EnstrophyProduction.lean`'s `enstrophy_production_dyadic_NL` right-hand side. -/

/-- **Step 3 (Cauchy–Schwarz).**  `S_N² ≤ (Σ_{n<N} k_n⁴ a_n⁴) · (Σ_{n<N} k_n² a_{n+1}²)`.
    No hypothesis on `k` or `a` at all. -/
theorem step3_cauchy_schwarz (k a : ℕ → ℝ) (N : ℕ) :
    ((Finset.range N).sum (fun n => (k n)^3 * (a n)^2 * a (n+1)))^2
      ≤ ((Finset.range N).sum (fun n => (k n)^4 * (a n)^4))
        * ((Finset.range N).sum (fun n => (k n)^2 * (a (n+1))^2)) := by
  have h := Finset.sum_mul_sq_le_sq_mul_sq (Finset.range N)
      (fun n => (k n)^2 * (a n)^2) (fun n => (k n) * a (n+1))
  have e1 : (Finset.range N).sum (fun n => (k n)^3 * (a n)^2 * a (n+1))
      = (Finset.range N).sum (fun n => ((k n)^2 * (a n)^2) * ((k n) * a (n+1))) :=
    Finset.sum_congr rfl (fun i _ => by ring)
  rw [e1]
  refine le_trans h (le_of_eq ?_)
  congr 1
  · exact Finset.sum_congr rfl (fun i _ => by ring)
  · exact Finset.sum_congr rfl (fun i _ => by ring)

/-! ### Main theorem -/

/-- **Enstrophy production bound (dyadic, local).**

      `S_N² ≤ 2 Ω_N³` ,  `S_N = Σ_{n=0}^{N-1} k_n³ a_n² a_{n+1}` ,
      `Ω_N = ½ Σ_{n=0}^{N} k_n² a_n²` ,

    under dyadic doubling `k_{n+1} = 2 k_n` on the active shells `n < N`.
    The summand `(k n)^3 * (a n)^2 * a (n+1)` is literally
    `EnstrophyProduction.prodOut k a n`, so combined with
    `enstrophy_production_dyadic_NL` this bounds the nonlinear part of `dΩ_N/dt`
    by `3 √(2 Ω_N³)`.

    **Scope (design note, "What this bound honestly does NOT give"):** this is a
    LOCAL bound.  It discards the dissipation `−ν P_N ≤ 0` and says nothing about
    global-in-time boundedness or uniformity in `N`. -/
theorem enstrophy_production_bound (k a : ℕ → ℝ) (N : ℕ)
    (hdouble : ∀ n, n < N → k (n+1) = 2 * k n) :
    ((Finset.range N).sum (fun n => (k n)^3 * (a n)^2 * a (n+1)))^2
      ≤ 2 * (Omega k a N)^3 := by
  have h3 := step3_cauchy_schwarz k a N
  have h2 := step2_quartic_bound k a N
  have h1 := step1_flux_bound_half k a N hdouble
  have hg : (0:ℝ) ≤ (Finset.range N).sum (fun n => (k n)^2 * (a (n+1))^2) :=
    Finset.sum_nonneg (fun i _ => mul_nonneg (sq_nonneg _) (sq_nonneg _))
  have hb : (0:ℝ) ≤ 4 * (Omega k a N)^2 := by
    have := sq_nonneg (Omega k a N); linarith
  have hmul := mul_le_mul h2 h1 hg hb
  have hring : (4 * (Omega k a N)^2) * (Omega k a N / 2) = 2 * (Omega k a N)^3 := by ring
  rw [hring] at hmul
  exact le_trans h3 hmul

/-! ### Non-vacuity witness (SPEC §7.5)

The Tier B / design-note instance: `N = 2`, `k n = 2^n` (so `k = 1, 2, 4`),
`a = (1, 2, 3, 0, 0, …)`.  Certified values (exact ℚ, Tier B report):

    S_N = 98 ,  S_N² = 9604 ,  Ω_N = 161/2 ,  2 Ω_N³ = 4173281/4 ,
    Step 1 LHS = 40 ≤ Ω_N/2 = 161/4 ,  Step 2 (restricted) LHS = 257 ≤ 4Ω_N² = 25921 .

Every one of these numbers is reproduced in the kernel below. -/

/-- Witness wavenumbers `k n = 2^n` (same data as `EnstrophyProduction.kW`). -/
noncomputable def kWit : ℕ → ℝ := fun n => (2:ℝ) ^ n

/-- Witness state `a = (1, 2, 3, 0, 0, …)` (same data as `EnstrophyProduction.aW`). -/
noncomputable def aWit : ℕ → ℝ :=
  fun n => if n = 0 then 1 else if n = 1 then 2 else if n = 2 then 3 else 0

/-- The witness wavenumbers satisfy dyadic doubling at every shell. -/
theorem kWit_double (n : ℕ) : kWit (n + 1) = 2 * kWit n := by
  unfold kWit; ring

/-- Witness: `Ω_2 = 161/2` (Tier B: `Omega_N = 161/2`). -/
theorem witness_Omega : Omega kWit aWit 2 = 161/2 := by
  unfold Omega
  rw [Finset.sum_range_succ, Finset.sum_range_succ, Finset.sum_range_succ,
      Finset.sum_range_zero]
  unfold kWit aWit
  norm_num

/-- Witness: `S_2 = Σ_{n<2} k_n³ a_n² a_{n+1} = 98` (Tier B: `S_N = 98`). -/
theorem witness_S : (Finset.range 2).sum (fun n => (kWit n)^3 * (aWit n)^2 * aWit (n+1)) = 98 := by
  rw [Finset.sum_range_succ, Finset.sum_range_succ, Finset.sum_range_zero]
  unfold kWit aWit
  norm_num

/-- Witness for Step 1: `Σ_{n<2} k_n² a_{n+1}² = 40`, and `Ω_2/2 = 161/4`, so the
    Step-1 inequality holds as `40 ≤ 161/4` (Tier B: `LHS = 40`, `bound = 161/4`).
    The final conjunct records **sharpness**: the constant `1/2` cannot be
    replaced by `1/4`, since `40 ≤ 161/8` is FALSE. -/
theorem witness_step1 :
    (Finset.range 2).sum (fun n => (kWit n)^2 * (aWit (n+1))^2) = 40
    ∧ Omega kWit aWit 2 / 2 = 161/4
    ∧ (Finset.range 2).sum (fun n => (kWit n)^2 * (aWit (n+1))^2) ≤ Omega kWit aWit 2 / 2
    ∧ ¬ ((Finset.range 2).sum (fun n => (kWit n)^2 * (aWit (n+1))^2) ≤ Omega kWit aWit 2 / 4) := by
  have hl : (Finset.range 2).sum (fun n => (kWit n)^2 * (aWit (n+1))^2) = 40 := by
    rw [Finset.sum_range_succ, Finset.sum_range_succ, Finset.sum_range_zero]
    unfold kWit aWit
    norm_num
  refine ⟨hl, by rw [witness_Omega]; norm_num, ?_, ?_⟩
  · rw [hl, witness_Omega]; norm_num
  · rw [hl, witness_Omega]; norm_num

/-- Witness for Step 2 (restricted range, the quantity Step 3 consumes):
    `Σ_{n<2} k_n⁴ a_n⁴ = 257 ≤ 4 Ω_2² = 25921` (Tier B: `257`, `25921`). -/
theorem witness_step2 :
    (Finset.range 2).sum (fun n => (kWit n)^4 * (aWit n)^4) = 257
    ∧ 4 * (Omega kWit aWit 2)^2 = 25921
    ∧ (Finset.range 2).sum (fun n => (kWit n)^4 * (aWit n)^4) ≤ 4 * (Omega kWit aWit 2)^2 := by
  have hl : (Finset.range 2).sum (fun n => (kWit n)^4 * (aWit n)^4) = 257 := by
    rw [Finset.sum_range_succ, Finset.sum_range_succ, Finset.sum_range_zero]
    unfold kWit aWit
    norm_num
  have hr : 4 * (Omega kWit aWit 2)^2 = 25921 := by rw [witness_Omega]; norm_num
  exact ⟨hl, hr, by rw [hl, hr]; norm_num⟩

/-- **Non-vacuity of the MAIN theorem.**  On the witness data the hypotheses are
    satisfied and BOTH SIDES are the Tier B numbers: `S_2² = 9604` and
    `2 Ω_2³ = 4173281/4`, with `9604 ≤ 4173281/4` a true and non-degenerate
    (nonzero-production) instance. -/
theorem witness_main :
    ((Finset.range 2).sum (fun n => (kWit n)^3 * (aWit n)^2 * aWit (n+1)))^2 = 9604
    ∧ 2 * (Omega kWit aWit 2)^3 = 4173281/4
    ∧ ((Finset.range 2).sum (fun n => (kWit n)^3 * (aWit n)^2 * aWit (n+1)))^2
        ≤ 2 * (Omega kWit aWit 2)^3 := by
  have hl : ((Finset.range 2).sum (fun n => (kWit n)^3 * (aWit n)^2 * aWit (n+1)))^2 = 9604 := by
    rw [witness_S]; norm_num
  have hr : 2 * (Omega kWit aWit 2)^3 = 4173281/4 := by rw [witness_Omega]; norm_num
  refine ⟨hl, hr, ?_⟩
  exact enstrophy_production_bound kWit aWit 2 (fun n _ => kWit_double n)

/-! ### Negative controls

Mirrors Tier B check PB.5(a): Step 1 is the doubling-dependent step, and it
genuinely FAILS when the doubling structure is broken.  (PB.5(b) recorded that
the MAIN bound itself was not violated by the non-doubling states searched, so
no negative control is claimed at the MAIN level — only at Step 1, which is
where the hypothesis `hdouble` actually does work.) -/

/-- Negative-control wavenumbers `k n = n + 1` (arithmetic, not doubling). -/
noncomputable def kNegA : ℕ → ℝ := fun n => (n : ℝ) + 1

/-- Negative-control state `a = (0, 0, 1, 0, …)`. -/
noncomputable def aNegA : ℕ → ℝ := fun n => if n = 2 then 1 else 0

/-- **Negative control 1 (`k n = n+1`).**  The doubling hypothesis fails, and so
    does Step 1's conclusion: at `N = 2` the left side is `4` while `Ω_2/2 = 9/4`.
    Hence `hdouble` is load-bearing in `step1_flux_bound_half` and cannot be
    dropped — the checker CAN fail. -/
theorem negative_control_arith :
    ¬ (kNegA (1 + 1) = 2 * kNegA 1)
    ∧ (Finset.range 2).sum (fun n => (kNegA n)^2 * (aNegA (n+1))^2) = 4
    ∧ Omega kNegA aNegA 2 = 9/2
    ∧ ¬ ((Finset.range 2).sum (fun n => (kNegA n)^2 * (aNegA (n+1))^2)
          ≤ Omega kNegA aNegA 2 / 2) := by
  have hk : ¬ (kNegA (1 + 1) = 2 * kNegA 1) := by
    unfold kNegA; norm_num
  have hl : (Finset.range 2).sum (fun n => (kNegA n)^2 * (aNegA (n+1))^2) = 4 := by
    rw [Finset.sum_range_succ, Finset.sum_range_succ, Finset.sum_range_zero]
    unfold kNegA aNegA
    norm_num
  have ho : Omega kNegA aNegA 2 = 9/2 := by
    unfold Omega
    rw [Finset.sum_range_succ, Finset.sum_range_succ, Finset.sum_range_succ,
        Finset.sum_range_zero]
    unfold kNegA aNegA
    norm_num
  exact ⟨hk, hl, ho, by rw [hl, ho]; norm_num⟩

/-- Negative-control wavenumbers `k n = 1` (constant, not doubling). -/
noncomputable def kNegB : ℕ → ℝ := fun _ => 1

/-- Negative-control state `a = (0, 1, 0, …)`. -/
noncomputable def aNegB : ℕ → ℝ := fun n => if n = 1 then 1 else 0

/-- **Negative control 2 (`k n = 1`).**  Same failure at `N = 1`: left side `1`,
    `Ω_1/2 = 1/4`.  Mirrors Tier B PB.5(a)'s `k_n = 1` branch. -/
theorem negative_control_const :
    ¬ (kNegB (0 + 1) = 2 * kNegB 0)
    ∧ (Finset.range 1).sum (fun n => (kNegB n)^2 * (aNegB (n+1))^2) = 1
    ∧ Omega kNegB aNegB 1 = 1/2
    ∧ ¬ ((Finset.range 1).sum (fun n => (kNegB n)^2 * (aNegB (n+1))^2)
          ≤ Omega kNegB aNegB 1 / 2) := by
  have hk : ¬ (kNegB (0 + 1) = 2 * kNegB 0) := by
    unfold kNegB; norm_num
  have hl : (Finset.range 1).sum (fun n => (kNegB n)^2 * (aNegB (n+1))^2) = 1 := by
    rw [Finset.sum_range_succ, Finset.sum_range_zero]
    unfold kNegB aNegB
    norm_num
  have ho : Omega kNegB aNegB 1 = 1/2 := by
    unfold Omega
    rw [Finset.sum_range_succ, Finset.sum_range_succ, Finset.sum_range_zero]
    unfold kNegB aNegB
    norm_num
  exact ⟨hk, hl, ho, by rw [hl, ho]; norm_num⟩

#print axioms Omega_nonneg
#print axioms sum_sq_eq_two_mul_Omega
#print axioms step1_flux_bound_half
#print axioms step1_flux_bound
#print axioms step2_quartic_bound
#print axioms step3_cauchy_schwarz
#print axioms enstrophy_production_bound
#print axioms kWit_double
#print axioms witness_Omega
#print axioms witness_S
#print axioms witness_step1
#print axioms witness_step2
#print axioms witness_main
#print axioms negative_control_arith
#print axioms negative_control_const

end MechanicaFluidorum.EnstrophyProductionBound
