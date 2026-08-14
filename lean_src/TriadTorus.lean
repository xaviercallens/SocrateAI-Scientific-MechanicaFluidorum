/-
  TriadTorus.lean — Tier A: the resonant-triad 2-section on a torus, solved exactly
  ==================================================================================
  Formalises `docs/designs/TRIAD_TORUS_THEOREM.md` (hand-derived first, per LL-5; verified
  numerically entry-by-entry at `(ℤ_3)³` before any Lean was written).

  THE OBJECT. `G` a finite additive abelian group (intended instance `(ℤ_m)³`), `Λ = G \ {0}`.
  Ordered resonant triads `(a, b, c)` with `a + b = c`, all in `Λ`, represented as pairs
  `(a, c)` with `b := c − a` — the exact representation `symbolic/triad_hypergraph.py` uses.
  The 2-section weight `A(u,v)` between distinct modes counts (triad, slot-pair) INCIDENCES:
  each ordered triad contributes 1 for each of its three slot-pairs {1,2}, {1,3}, {2,3} whose
  value set is `{u, v}`.

  Incidences — not "triads containing the pair" — is the load-bearing choice: at `v = 2u` the
  single ordered triad `(u, u, 2u)` carries TWO slot-pairs with values `{u, v}`, and the
  incidence count absorbs this degeneracy so the final formula is uniform with NO genericity
  hypothesis. See the memo §1.

  THE THEOREM.  For `u ≠ v`, both nonzero:      A(u,v) = 6 − 2·[u + v = 0]
  i.e. `A = 6(J − I) − 2P` with `P` the mode-reversal involution. Spectral corollary, stated as
  sum identities (no matrix library): on zero-sum vectors, even vectors have eigenvalue −8 and
  odd vectors −4; the degree is `6n − 8`. Hence the normalised spectrum is
  `{1, −4/(6n−8), −8/(6n−8)}` and the torus spectral gap tends to 1 — so the ≈ 5/6 gap measured
  on the BALL truncation (M = 2..5) is a pure boundary invariant. That 5/6 conjecture is
  deliberately NOT in scope here.

  The no-2-torsion hypothesis in the spectral lemmas is genuinely needed: at a 2-torsion point
  `u = −u` the antipodal column coincides with the diagonal, the row of `A` is constant 6 and
  the degree formula changes. `(ℤ_m)³` with `m` odd satisfies the hypothesis.

  Gate: `#print axioms` for every theorem must name no axiom outside
  {propext, Classical.choice, Quot.sound}.
-/
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Piecewise
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Real.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Abel
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

namespace MechanicaFluidorum.TriadTorus

open Finset

variable {G : Type*} [AddCommGroup G] [Fintype G] [DecidableEq G]

/-- The nonzero modes `Λ = G \ {0}`. -/
def lam : Finset G := Finset.univ.erase 0

theorem mem_lam {x : G} : x ∈ (lam : Finset G) ↔ x ≠ 0 := by
  simp [lam]

/-- Ordered triads in the `(a, c)` representation: `a, c, c − a` all nonzero (`b := c − a`). -/
def triadPairs : Finset (G × G) :=
  ((lam ×ˢ lam)).filter (fun p => p.2 - p.1 ≠ 0)

theorem mem_triadPairs {p : G × G} :
    p ∈ (triadPairs : Finset (G × G)) ↔ p.1 ≠ 0 ∧ p.2 ≠ 0 ∧ p.2 - p.1 ≠ 0 := by
  simp [triadPairs, lam, and_assoc]

/-! ## The three incidence counts, by slot-pair type -/

/-- Type {1,2}: the first two slots carry `{u, v}` — triads `(u, v, u+v)`, `(v, u, u+v)`,
i.e. pairs `(u, u+v)`, `(v, u+v)` in the `(a, c)` representation. -/
def w12 (u v : G) : ℕ :=
  (triadPairs.filter (fun p => (p.1 = u ∧ p.2 - p.1 = v) ∨ (p.1 = v ∧ p.2 - p.1 = u))).card

/-- Type {1,3}: slots 1 and 3 carry `{u, v}` — pairs `(u, v)`, `(v, u)`. -/
def w13 (u v : G) : ℕ :=
  (triadPairs.filter (fun p => (p.1 = u ∧ p.2 = v) ∨ (p.1 = v ∧ p.2 = u))).card

/-- Type {2,3}: slots 2 and 3 carry `{u, v}` — pairs `(v−u, v)`, `(u−v, u)`. -/
def w23 (u v : G) : ℕ :=
  (triadPairs.filter (fun p => (p.2 - p.1 = u ∧ p.2 = v) ∨ (p.2 - p.1 = v ∧ p.2 = u))).card

/-- The 2-section incidence weight, exactly as `symbolic/triad_hypergraph.py` builds it. -/
def A (u v : G) : ℕ := w12 u v + w13 u v + w23 u v

/-! ## The counting lemmas -/

theorem w13_eq {u v : G} (hu : u ≠ 0) (hv : v ≠ 0) (huv : u ≠ v) : w13 u v = 2 := by
  have hfil :
      (triadPairs.filter (fun p : G × G => (p.1 = u ∧ p.2 = v) ∨ (p.1 = v ∧ p.2 = u)))
        = {(u, v), (v, u)} := by
    ext ⟨x, y⟩
    simp only [mem_filter, mem_triadPairs, mem_insert, mem_singleton, Prod.mk.injEq]
    constructor
    · rintro ⟨_, h⟩
      exact h
    · rintro (⟨rfl, rfl⟩ | ⟨rfl, rfl⟩)
      · exact ⟨⟨hu, hv, sub_ne_zero.mpr (Ne.symm huv)⟩, Or.inl ⟨rfl, rfl⟩⟩
      · exact ⟨⟨hv, hu, sub_ne_zero.mpr huv⟩, Or.inr ⟨rfl, rfl⟩⟩
  have hne : ((u, v) : G × G) ∉ ({(v, u)} : Finset (G × G)) := by
    simp only [mem_singleton, Prod.mk.injEq, not_and]
    intro h
    exact absurd h huv
  rw [w13, hfil, card_insert_of_notMem hne, card_singleton]

theorem w23_eq {u v : G} (hu : u ≠ 0) (hv : v ≠ 0) (huv : u ≠ v) : w23 u v = 2 := by
  have hfil :
      (triadPairs.filter
          (fun p : G × G => (p.2 - p.1 = u ∧ p.2 = v) ∨ (p.2 - p.1 = v ∧ p.2 = u)))
        = {(v - u, v), (u - v, u)} := by
    ext ⟨x, y⟩
    simp only [mem_filter, mem_triadPairs, mem_insert, mem_singleton, Prod.mk.injEq]
    constructor
    · rintro ⟨_, (⟨h1, h2⟩ | ⟨h1, h2⟩)⟩
      · refine Or.inl ⟨?_, h2⟩
        rw [← h2, ← h1]
        abel
      · refine Or.inr ⟨?_, h2⟩
        rw [← h2, ← h1]
        abel
    · rintro (⟨rfl, rfl⟩ | ⟨rfl, rfl⟩)
      · refine ⟨⟨sub_ne_zero.mpr (Ne.symm huv), hv, ?_⟩, Or.inl ⟨by abel, rfl⟩⟩
        rw [sub_sub_cancel]
        exact hu
      · refine ⟨⟨sub_ne_zero.mpr huv, hu, ?_⟩, Or.inr ⟨by abel, rfl⟩⟩
        rw [sub_sub_cancel]
        exact hv
  have hne : ((v - u, v) : G × G) ∉ ({(u - v, u)} : Finset (G × G)) := by
    simp only [mem_singleton, Prod.mk.injEq, not_and]
    intro _ h
    exact absurd h (Ne.symm huv)
  rw [w23, hfil, card_insert_of_notMem hne, card_singleton]

theorem w12_eq {u v : G} (hu : u ≠ 0) (hv : v ≠ 0) (huv : u ≠ v) :
    w12 u v = if u + v = 0 then 0 else 2 := by
  by_cases hsum : u + v = 0
  · -- the required third slot `u+v` is zero: no admissible triad, the filter is empty
    have hfil :
        (triadPairs.filter
            (fun p : G × G => (p.1 = u ∧ p.2 - p.1 = v) ∨ (p.1 = v ∧ p.2 - p.1 = u)))
          = ∅ := by
      ext ⟨x, y⟩
      simp only [mem_filter, mem_triadPairs, notMem_empty, iff_false, not_and]
      rintro ⟨_, hy, _⟩ (⟨h1, h2⟩ | ⟨h1, h2⟩)
      · apply hy
        have hy' : y = v + x := by rw [← h2]; abel
        rw [hy', h1, add_comm]
        exact hsum
      · apply hy
        have hy' : y = u + x := by rw [← h2]; abel
        rw [hy', h1]
        exact hsum
    rw [w12, hfil, card_empty, if_pos hsum]
  · -- third slot `u+v ≠ 0`: exactly the two pairs `(u, u+v)`, `(v, u+v)`
    have hfil :
        (triadPairs.filter
            (fun p : G × G => (p.1 = u ∧ p.2 - p.1 = v) ∨ (p.1 = v ∧ p.2 - p.1 = u)))
          = {(u, u + v), (v, u + v)} := by
      ext ⟨x, y⟩
      simp only [mem_filter, mem_triadPairs, mem_insert, mem_singleton, Prod.mk.injEq]
      constructor
      · rintro ⟨_, (⟨h1, h2⟩ | ⟨h1, h2⟩)⟩
        · refine Or.inl ⟨h1, ?_⟩
          rw [← h2, h1]
          abel
        · refine Or.inr ⟨h1, ?_⟩
          rw [← h2, h1]
          abel
      · rintro (⟨h1, h2⟩ | ⟨h1, h2⟩)
        · refine ⟨⟨?_, ?_, ?_⟩, Or.inl ⟨h1, ?_⟩⟩
          · rw [h1]; exact hu
          · rw [h2]; exact hsum
          · rw [h1, h2]
            have hc : u + v - u = v := by abel
            rw [hc]; exact hv
          · rw [h1, h2]; abel
        · refine ⟨⟨?_, ?_, ?_⟩, Or.inr ⟨h1, ?_⟩⟩
          · rw [h1]; exact hv
          · rw [h2]; exact hsum
          · rw [h1, h2]
            have hc : u + v - v = u := by abel
            rw [hc]; exact hu
          · rw [h1, h2]; abel
    have hne : ((u, u + v) : G × G) ∉ ({(v, u + v)} : Finset (G × G)) := by
      simp only [mem_singleton, Prod.mk.injEq, not_and]
      intro h
      exact absurd h huv
    rw [w12, hfil, card_insert_of_notMem hne, card_singleton, if_neg hsum]

/-! ## The main theorem -/

/-- **Torus 2-section, solved.** For distinct nonzero modes the incidence weight is `6`, except
`4` for antipodal pairs (`u + v = 0`) — i.e. `A = 6(J − I) − 2P`. Uniform: no genericity
hypothesis; degenerate coincidences such as `v = 2u` are absorbed by the incidence count. -/
theorem A_eq {u v : G} (hu : u ≠ 0) (hv : v ≠ 0) (huv : u ≠ v) :
    A u v = if u + v = 0 then 4 else 6 := by
  rw [A, w12_eq hu hv huv, w13_eq hu hv huv, w23_eq hu hv huv]
  by_cases hsum : u + v = 0 <;> simp [hsum]

/-! ## Spectral corollary, as sum identities

Stated against the closed form (justified by `A_eq`), over ℝ so that eigenvalue equations make
sense. `h2t` (no 2-torsion) is genuinely needed — see the header note. -/

/-- The closed-form weight over ℝ (for `v` ranging over `Λ \ {u}`). -/
noncomputable def wR (u v : G) : ℝ := if u + v = 0 then 4 else 6

theorem wR_eq_A {u v : G} (hu : u ≠ 0) (hv : v ≠ 0) (huv : u ≠ v) :
    wR u v = (A u v : ℝ) := by
  rw [A_eq hu hv huv, wR]
  by_cases h : u + v = 0 <;> simp [h]

/-- `-u` lies in `Λ \ {u}` when `u ≠ 0` and the group has no 2-torsion. -/
theorem neg_mem_erase {u : G} (hu : u ≠ 0) (h2t : ∀ x : G, x + x = 0 → x = 0) :
    -u ∈ ((lam : Finset G).erase u) := by
  refine Finset.mem_erase.mpr ⟨?_, mem_lam.mpr (neg_ne_zero.mpr hu)⟩
  intro h
  apply hu
  apply h2t
  have h' : u + u = -u + u := by rw [h]
  rw [h', neg_add_cancel]

/-- The equivalence between the two natural forms of the antipodal condition. -/
theorem add_eq_zero_iff_eq_neg' {u v : G} : u + v = 0 ↔ v = -u := by
  constructor
  · intro h
    have := congrArg (fun t => -u + t) h
    simpa [← add_assoc, neg_add_cancel] using this
  · intro h
    rw [h, add_neg_cancel]

/-- Row sum (degree): `Σ_{v ∈ Λ, v ≠ u} w(u,v) = 6·|Λ| − 8`. -/
theorem row_sum {u : G} (hu : u ≠ 0) (h2t : ∀ x : G, x + x = 0 → x = 0) :
    ∑ v ∈ ((lam : Finset G).erase u), wR u v
      = 6 * ((lam : Finset G).card : ℝ) - 8 := by
  have hmem := neg_mem_erase hu h2t
  have hsplit : ∀ v ∈ ((lam : Finset G).erase u),
      wR u v = 6 + (if v = -u then (-2 : ℝ) else 0) := by
    intro v _
    rw [wR]
    by_cases h : v = -u
    · rw [if_pos (add_eq_zero_iff_eq_neg'.mpr h), if_pos h]
      norm_num
    · rw [if_neg (fun hs => h (add_eq_zero_iff_eq_neg'.mp hs)), if_neg h]
      norm_num
  rw [Finset.sum_congr rfl hsplit, Finset.sum_add_distrib, Finset.sum_const,
      Finset.sum_ite_eq' _ (-u) (fun _ => (-2 : ℝ)), if_pos hmem, nsmul_eq_mul,
      Finset.card_erase_of_mem (mem_lam.mpr hu)]
  have h1 : (1 : ℕ) ≤ (lam : Finset G).card :=
    Finset.card_pos.mpr ⟨u, mem_lam.mpr hu⟩
  push_cast [Nat.cast_sub h1]
  ring

/-- **Even eigenvector lemma**: a zero-sum even vector satisfies `(A f)(u) = −8·f(u)`. -/
theorem eigen_even {f : G → ℝ} {u : G} (hu : u ≠ 0)
    (h2t : ∀ x : G, x + x = 0 → x = 0)
    (hf0 : ∑ v ∈ (lam : Finset G), f v = 0)
    (heven : ∀ x, f (-x) = f x) :
    ∑ v ∈ ((lam : Finset G).erase u), wR u v * f v = -8 * f u := by
  have hmem := neg_mem_erase hu h2t
  have hsplit : ∀ v ∈ ((lam : Finset G).erase u),
      wR u v * f v = 6 * f v + (if v = -u then (-2 : ℝ) * f v else 0) := by
    intro v _
    rw [wR]
    by_cases h : v = -u
    · rw [if_pos (add_eq_zero_iff_eq_neg'.mpr h), if_pos h]
      ring
    · rw [if_neg (fun hs => h (add_eq_zero_iff_eq_neg'.mp hs)), if_neg h]
      ring
  have herase : ∑ v ∈ ((lam : Finset G).erase u), f v = -f u := by
    have hadd := Finset.add_sum_erase (lam : Finset G) f (mem_lam.mpr hu)
    rw [hf0] at hadd
    linarith
  rw [Finset.sum_congr rfl hsplit, Finset.sum_add_distrib, ← Finset.mul_sum, herase,
      Finset.sum_ite_eq' _ (-u) (fun v => (-2 : ℝ) * f v), if_pos hmem, heven]
  ring

/-- **Odd eigenvector lemma**: a zero-sum odd vector satisfies `(A f)(u) = −4·f(u)`. -/
theorem eigen_odd {f : G → ℝ} {u : G} (hu : u ≠ 0)
    (h2t : ∀ x : G, x + x = 0 → x = 0)
    (hf0 : ∑ v ∈ (lam : Finset G), f v = 0)
    (hodd : ∀ x, f (-x) = -f x) :
    ∑ v ∈ ((lam : Finset G).erase u), wR u v * f v = -4 * f u := by
  have hmem := neg_mem_erase hu h2t
  have hsplit : ∀ v ∈ ((lam : Finset G).erase u),
      wR u v * f v = 6 * f v + (if v = -u then (-2 : ℝ) * f v else 0) := by
    intro v _
    rw [wR]
    by_cases h : v = -u
    · rw [if_pos (add_eq_zero_iff_eq_neg'.mpr h), if_pos h]
      ring
    · rw [if_neg (fun hs => h (add_eq_zero_iff_eq_neg'.mp hs)), if_neg h]
      ring
  have herase : ∑ v ∈ ((lam : Finset G).erase u), f v = -f u := by
    have hadd := Finset.add_sum_erase (lam : Finset G) f (mem_lam.mpr hu)
    rw [hf0] at hadd
    linarith
  rw [Finset.sum_congr rfl hsplit, Finset.sum_add_distrib, ← Finset.mul_sum, herase,
      Finset.sum_ite_eq' _ (-u) (fun v => (-2 : ℝ) * f v), if_pos hmem, hodd]
  ring

/-! ## Non-vacuity (SPEC §7.5) -/

/-- The intended instance `(ℤ_3)³` inhabits every hypothesis: nontrivial, no 2-torsion. -/
example : ∃ x : (ZMod 3) × (ZMod 3) × (ZMod 3), x ≠ 0 := ⟨(1, 0, 0), by decide⟩

example : ∀ x : (ZMod 3) × (ZMod 3) × (ZMod 3), x + x = 0 → x = 0 := by decide

/-- The antipodal case genuinely differs: in `(ℤ_3)³`, `(1,0,0) + (2,0,0) = 0`, so the weight
is `4` — `A_eq`'s case split is not vacuous. -/
example :
    A ((1, 0, 0) : (ZMod 3) × (ZMod 3) × (ZMod 3)) (2, 0, 0) = 4 := by
  rw [A_eq (by decide) (by decide) (by decide), if_pos (by decide)]

/-! ## Axiom-footprint gate

**Negative controls (hand-derived; to run against scratch perturbed copies before commit):**
NC1 — drop `huv : u ≠ v` from `w13_eq`: the doubleton collapses (`(u,v) = (v,u)`) and
`card = 2` fails. NC2 — drop `h2t` from `eigen_even`: `neg_mem_erase` becomes unprovable
(at 2-torsion points `-u = u` is not excluded). NC3 — change `−8` to `−6` in `eigen_even`:
the final `ring` cannot close; the `−2` antipodal correction is load-bearing. -/

#print axioms A_eq
#print axioms w12_eq
#print axioms w13_eq
#print axioms w23_eq
#print axioms row_sum
#print axioms eigen_even
#print axioms eigen_odd

end MechanicaFluidorum.TriadTorus
