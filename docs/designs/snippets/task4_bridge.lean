/-
  task4_bridge.lean — de-risking snippet for docs/designs/TASK4_ELL2_REPAIR.md §2.1

  NOT part of Gate 2 (it is a design artifact, not a claim). Its purpose is to prove, before
  any implementation is dispatched, that the proposed ell^2 upgrade is a CONSERVATIVE EXTENSION:
  the current "every finite partial sum <= C" formulation and the proposed "Summable + tsum <= C"
  formulation are equivalent for nonnegative terms, and the equivalence closes against the
  pinned Mathlib with a clean axiom footprint.

  Verified 2026-08-13 against lean_src/'s pinned Mathlib (footprint
  [propext, Classical.choice, Quot.sound]).  Reproduce with:
      cd lean_src && lake env lean ../docs/designs/snippets/task4_bridge.lean
-/
import Mathlib.Topology.Algebra.InfiniteSum.Order
import Mathlib.Topology.Algebra.InfiniteSum.NatInt
import Mathlib.Analysis.PSeries
import Mathlib.Algebra.BigOperators.Group.Finset.Basic

namespace MechanicaFluidorum.Task4Design

/-- **The bridge.** For nonnegative terms, the finite-partial-sum bound used throughout the
current formalisation implies summability together with the corresponding `tsum` bound.
Stated with `range (M+1)` to match `enstrophy N w u t`'s indexing convention exactly. -/
theorem bounded_partial_sums_iff (f : ℕ → ℝ) (C : ℝ) (hf : ∀ n, 0 ≤ f n)
    (hbd : ∀ M : ℕ, ∑ n ∈ Finset.range (M + 1), f n ≤ C) :
    Summable f ∧ ∑' n, f n ≤ C := by
  have hall : ∀ M : ℕ, ∑ n ∈ Finset.range M, f n ≤ C := by
    intro M
    cases M with
    | zero => simpa using le_trans (Finset.sum_nonneg (fun i _ => hf i)) (hbd 0)
    | succ m => exact hbd m
  have hs : Summable f := summable_of_sum_range_le hf hall
  exact ⟨hs, hs.tsum_le_of_sum_range_le hall⟩

/-- Converse direction: summability plus a `tsum` bound gives back every finite partial sum
bound, so nothing already proven is lost by adopting the `tsum` form. -/
theorem tsum_le_gives_partial (f : ℕ → ℝ) (C : ℝ) (hf : ∀ n, 0 ≤ f n)
    (hs : Summable f) (h : ∑' n, f n ≤ C) :
    ∀ M : ℕ, ∑ n ∈ Finset.range (M + 1), f n ≤ C :=
  fun M => le_trans (hs.sum_le_tsum _ (fun i _ => hf i)) h

#print axioms bounded_partial_sums_iff
#print axioms tsum_le_gives_partial

end MechanicaFluidorum.Task4Design
