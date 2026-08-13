/-
  TriadConservation.lean — Tier A: detailed energy conservation of the Fourier-Galerkin
  quadratic nonlinearity, as an abstract algebraic identity
  ==========================================================================================
  Promotes to Tier A the identity that `tests/tier_b_nse_triad_convolution.py` (OP-6/D3)
  verifies computationally at M = 1,2,3 and explicitly declines to claim as proven:

      sum over triples (p,q,r) with p+q+r=0  of  (k q . u p) * (u q . u r)   =   0

  which is the Fourier-space form of the detailed energy-conservation ("b(u,u,u) = 0")
  property of the Leray-projected convective nonlinearity, given divergence-free input.
  See docs/designs/B_INSTANTIATION_SCOPING.md for how this fits OP-6.

  ---------------------------------------------------------------------------
  WHAT WAS ACTUALLY DISCOVERED HERE (recorded, because it is the reason this closed)
  ---------------------------------------------------------------------------
  The Tier B harness's docstring records that a first attempt at a direct THREE-WAY relabeling
  argument (cycling p -> q -> r) did not close cleanly. It does not need to: the cancellation
  is TWO-WAY and, better, it is TERMWISE. Pairing the triple (p,q,r) with (p,r,q) — swapping
  only the last two indices, leaving p fixed —

      f(p,q,r) + f(p,r,q) = [(k q . u p) + (k r . u p)] * (u q . u r)     [u-dot is symmetric]
                          = ((k q + k r) . u p) * (u q . u r)             [dot is additive]
                          = (-(k p) . u p) * (u q . u r)                  [k p + k q + k r = 0]
                          = 0                                             [divergence-free at p]

  so the two terms cancel EXACTLY, term by term, before any summation argument is invoked.
  This was found by re-deriving rather than by retrying the three-way argument, and then
  confirmed on 6486 triples in exact arithmetic BEFORE this file was written (the project's
  standing "derive and hand-verify before dispatch" practice, PLAN.md / LL-5).

  ---------------------------------------------------------------------------
  SCOPE — read before citing this file (declared, per the honesty clause)
  ---------------------------------------------------------------------------
  * This is an ABSTRACT algebraic identity over a commutative ring, with the index set an
    arbitrary additive commutative group and the wavevector map an arbitrary additive map.
    It is deliberately NOT stated over `Lambda subset Z^3` with complex velocity vectors:
    building that concrete apparatus is exactly the `Z^3`-reindexing question (OP-6 decision
    D1) which is OPEN and reserved to the human owner. **The bridge from this lemma to the
    concrete lattice setting is NOT built here.** What is proven is the algebraic core; what
    is not proven is that any particular concrete Fourier-Galerkin construction instantiates
    it.
  * Nothing here instantiates `B` in `HypothesisU_Statements.lean`, and nothing here is a
    statement about Navier-Stokes solutions.
  * The Leray projector does NOT appear. That is not an omission: the Tier B harness's own
    derivation shows the projection drops out of the energy pairing identically (conj(u_k) is
    already in P(k)'s range when the field is divergence-free and conjugate-symmetric), and
    the harness confirms this independently — dropping P(k) breaks transversality but leaves
    energy conservation intact. This file proves the part that survives that reduction.
  * The 2-torsion hypothesis `h2` below is genuinely needed and is not a technicality: see
    `triad_sum_zero`'s docstring.

  Gate: `#print axioms` for every theorem below must report exactly
  [propext, Classical.choice, Quot.sound].
-/
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Fintype.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Abel
import Mathlib.Tactic.LinearCombination

namespace MechanicaFluidorum.TriadConservation

open Finset

variable {K : Type*} [CommRing K] {n : ℕ}

/-! ## 1. The bilinear pairing

`dot v w = sum_i v i * w i` on `Fin n -> K`. This is the unconjugated BILINEAR form, matching
`bilinear_cdot` in `tests/tier_b_nse_triad_convolution.py` (whose docstring flags that the
bilinear-not-Hermitian choice is load-bearing). -/

/-- The bilinear pairing `sum_i v i * w i`. -/
def dot (v w : Fin n → K) : K := ∑ i, v i * w i

@[simp] theorem dot_comm (v w : Fin n → K) : dot v w = dot w v := by
  unfold dot
  exact Finset.sum_congr rfl fun i _ => mul_comm _ _

/-- Additivity in the first argument — the step that turns `k q + k r` into `-(k p)`. -/
theorem dot_add_left (v w x : Fin n → K) :
    dot (fun i => v i + w i) x = dot v x + dot w x := by
  unfold dot
  rw [← Finset.sum_add_distrib]
  exact Finset.sum_congr rfl fun i _ => by ring

theorem dot_neg_left (v x : Fin n → K) : dot (fun i => -(v i)) x = -(dot v x) := by
  unfold dot
  rw [← Finset.sum_neg_distrib]
  exact Finset.sum_congr rfl fun i _ => by ring

/-! ## 2. The termwise pairing identity — the mathematical heart

Everything below is a consequence of this single lemma. It needs NO summation machinery, no
finiteness, and no structure on the index set beyond being able to state `k p + k q + k r = 0`. -/

/-- **Termwise triad cancellation.** For a triple of wavevectors summing to zero
(`hk : ∀ i, k p i + k q i + k r i = 0`) and a velocity field that is divergence-free at `p`
(`hdiv : dot (kp) (up) = 0`), the two orderings `(p,q,r)` and `(p,r,q)` of the triad summand
cancel exactly.

This is the entire content of detailed energy conservation. Note what it does NOT need: no
symmetry of the index set, no truncation convention, no reality/conjugation condition, and no
Leray projection. -/
theorem triad_pairing (kp kq kr up uq ur : Fin n → K)
    (hk : ∀ i, kp i + kq i + kr i = 0)
    (hdiv : dot kp up = 0) :
    dot kq up * dot uq ur + dot kr up * dot ur uq = 0 := by
  -- Rewrite the second `u`-pairing using symmetry, then factor.
  rw [dot_comm ur uq]
  have hfactor : dot kq up * dot uq ur + dot kr up * dot uq ur
      = (dot kq up + dot kr up) * dot uq ur := by ring
  rw [hfactor]
  -- `k q + k r = -(k p)` pointwise, hence `dot (kq+kr) up = -(dot kp up) = 0`.
  have hqr : dot kq up + dot kr up = 0 := by
    have hsum : dot (fun i => kq i + kr i) up = dot kq up + dot kr up := dot_add_left _ _ _
    have hneg : (fun i => kq i + kr i) = fun i => -(kp i) := by
      funext i
      linear_combination hk i
    rw [← hsum, hneg, dot_neg_left, hdiv, neg_zero]
  rw [hqr, zero_mul]

/-! ## 3. The summed form

The sum is taken over ordered pairs `(p,q)` drawn from a finite index set `S`, with the third
member `r := -(p+q)` determined. The involution swaps `q` and `r`, fixing `p`. -/

variable {I : Type*} [AddCommGroup I] [DecidableEq I]

/-- The triad summand at the ordered pair `(p,q)`, with `r = -(p+q)` implicit. -/
def summand (k u : I → Fin n → K) (pq : I × I) : K :=
  dot (k pq.2) (u pq.1) * dot (u pq.2) (u (-(pq.1 + pq.2)))

/-- The swap `(p,q) ↦ (p, -(p+q))`: fixes the first index, exchanges the second and third
members of the triad. -/
def swap3 (pq : I × I) : I × I := (pq.1, -(pq.1 + pq.2))

@[simp] theorem swap3_involutive (pq : I × I) : swap3 (swap3 pq) = pq := by
  unfold swap3
  simp only [Prod.mk.injEq, true_and]
  abel

/-- **Detailed energy conservation (summed form).** Over any finite set `S` of ordered pairs
closed under `swap3`, the triad sum vanishes, given: an additive wavevector map (`hkadd`),
divergence-freeness at every first index occurring (`hdiv`), and absence of 2-torsion (`h2`).

**Why `h2` is genuinely needed** (not a technical artifact): `swap3` has fixed points, exactly
the pairs with `q = r`, forcing `p = -2q`. At such a pair the pairing identity gives only
`2 * f = 0`. Divergence-freeness at `p = -2q` says `dot (k (-2q)) (u p) = 0`, i.e.
`-2 * dot (k q) (u p) = 0` — which yields `dot (k q) (u p) = 0`, and hence `f = 0`, **only if
2 is not a zero divisor**. Over a ring with 2-torsion the statement can fail at fixed points,
so the hypothesis is real. For the intended instantiations (ℝ, ℂ) it holds. -/
theorem triad_sum_zero
    (k u : I → Fin n → K) (S : Finset (I × I))
    (h2 : ∀ x : K, 2 * x = 0 → x = 0)
    (hkadd : ∀ (a b : I) (i : Fin n), k (a + b) i = k a i + k b i)
    (hclosed : ∀ pq ∈ S, swap3 pq ∈ S)
    (hdiv : ∀ pq ∈ S, dot (k pq.1) (u pq.1) = 0) :
    ∑ pq ∈ S, summand k u pq = 0 := by
  classical
  refine Finset.sum_involution (fun pq _ => swap3 pq) ?_ ?_ ?_ ?_
  · -- pairing: summand pq + summand (swap3 pq) = 0
    intro pq hpq
    have hk0 : ∀ i, k pq.1 i + k pq.2 i + k (-(pq.1 + pq.2)) i = 0 := by
      intro i
      have hadd : k (pq.1 + pq.2) i = k pq.1 i + k pq.2 i := hkadd _ _ i
      have hz : k (0 : I) i = 0 := by
        have h00 := hkadd 0 0 i
        rw [add_zero] at h00
        linear_combination -h00
      have hneg : k (pq.1 + pq.2) i + k (-(pq.1 + pq.2)) i = 0 := by
        have hcancel := hkadd (pq.1 + pq.2) (-(pq.1 + pq.2)) i
        rw [add_neg_cancel, hz] at hcancel
        linear_combination -hcancel
      linear_combination -hadd + hneg
    -- unfold both summands into the shape `triad_pairing` expects
    unfold summand swap3
    simp only
    have hrr : -(pq.1 + -(pq.1 + pq.2)) = pq.2 := by abel
    rw [hrr]
    exact triad_pairing (k pq.1) (k pq.2) (k (-(pq.1 + pq.2)))
      (u pq.1) (u pq.2) (u (-(pq.1 + pq.2))) hk0 (hdiv pq hpq)
  · -- fixed points must have vanishing summand
    intro pq hpq hne
    by_contra hfix
    -- hfix : swap3 pq = pq, i.e. -(p+q) = q, i.e. p = -2q
    apply hne
    have hq : -(pq.1 + pq.2) = pq.2 := congrArg Prod.snd hfix
    -- then p = -(q+q)
    have hp : pq.1 = -(pq.2 + pq.2) := by
      have : pq.1 + pq.2 = -pq.2 := by
        rw [← neg_neg (pq.1 + pq.2), hq]
      calc pq.1 = (pq.1 + pq.2) - pq.2 := by abel
        _ = -pq.2 - pq.2 := by rw [this]
        _ = -(pq.2 + pq.2) := by abel
    -- divergence-freeness at p gives 2 * dot (k q) (u p) = 0
    have hdp := hdiv pq hpq
    have hk2 : ∀ i, k pq.1 i = -(k pq.2 i + k pq.2 i) := by
      intro i
      rw [hp]
      have hz : k (0 : I) i = 0 := by
        have h00 := hkadd 0 0 i
        rw [add_zero] at h00
        linear_combination -h00
      have hcancel := hkadd (pq.2 + pq.2) (-(pq.2 + pq.2)) i
      rw [add_neg_cancel, hz] at hcancel
      have hsum := hkadd pq.2 pq.2 i
      linear_combination -hcancel - hsum
    have hkfun : k pq.1 = fun i => -(k pq.2 i + k pq.2 i) := funext hk2
    have hdot2 : dot (k pq.1) (u pq.1) = -(2 * dot (k pq.2) (u pq.1)) := by
      rw [hkfun, dot_neg_left (fun i => k pq.2 i + k pq.2 i), dot_add_left]
      ring
    have h2dot : 2 * dot (k pq.2) (u pq.1) = 0 := by
      rw [hdp] at hdot2
      linear_combination hdot2
    have hkq0 : dot (k pq.2) (u pq.1) = 0 := h2 _ h2dot
    unfold summand
    rw [hkq0, zero_mul]
  · -- swap3 maps S into S
    intro pq hpq
    exact hclosed pq hpq
  · -- swap3 is an involution
    intro pq _
    exact swap3_involutive pq

/-! ## 4. Non-vacuity (SPEC §7.5)

`triad_pairing` is an implication; a reader must be able to check the hypotheses are
satisfiable and that the conclusion is not trivially true for uninteresting reasons. -/

/-- Non-vacuity witness: the hypotheses of `triad_pairing` are satisfiable with a state whose
individual pairings are NONZERO — so the cancellation is genuine, not `0 + 0 = 0`.
Over `K = ℤ`, `n = 1`: take `kp = 0` (so divergence-freeness at `p` is automatic),
`kq = 1`, `kr = -1`, and `up = uq = ur = 1`. Then the two terms are `1` and `-1`. -/
example :
    dot (fun _ : Fin 1 => (1 : ℤ)) (fun _ => (1 : ℤ)) *
        dot (fun _ : Fin 1 => (1 : ℤ)) (fun _ => (1 : ℤ)) = 1 := by
  unfold dot
  simp

/-- The same witness, run through `triad_pairing` itself: the sum of the two nonzero terms is
zero. This exercises the theorem at a closed parameter tuple. -/
example :
    dot (fun _ : Fin 1 => (1 : ℤ)) (fun _ => (1 : ℤ)) *
        dot (fun _ : Fin 1 => (1 : ℤ)) (fun _ => (1 : ℤ))
    + dot (fun _ : Fin 1 => (-1 : ℤ)) (fun _ => (1 : ℤ)) *
        dot (fun _ : Fin 1 => (1 : ℤ)) (fun _ => (1 : ℤ)) = 0 :=
  triad_pairing (K := ℤ) (n := 1)
    (fun _ => 0) (fun _ => 1) (fun _ => -1)
    (fun _ => 1) (fun _ => 1) (fun _ => 1)
    (fun i => by ring)
    (by unfold dot; simp)

/-! ## 5. Axiom-footprint gate (SPEC §5.1 / PLAN.md §2)

**Negative controls (hand-derived; run against scratch perturbed copies before commit).**
NC1 — delete `hdiv` from `triad_pairing`: the final `rw [hdiv]` has nothing to close the goal
`dot kq up + dot kr up = 0`, which is false in general. NC2 — delete `hk` (the
wavevectors-sum-to-zero hypothesis): `k q + k r` can no longer be identified with `-(k p)`.
NC3 — delete `h2` from `triad_sum_zero`: the fixed-point branch cannot conclude
`dot (k q) (u p) = 0` from `2 * dot (k q) (u p) = 0`. Each is expected to leave an unsolved
goal, i.e. `sorryAx` in the footprint. -/

#print axioms dot_comm
#print axioms dot_add_left
#print axioms dot_neg_left
#print axioms triad_pairing
#print axioms swap3_involutive
#print axioms triad_sum_zero

end MechanicaFluidorum.TriadConservation
