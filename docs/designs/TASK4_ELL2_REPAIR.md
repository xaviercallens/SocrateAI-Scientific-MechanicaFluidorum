# Design memo — Task 4: eradicating the `Prop` placeholders (ℓ² repair of the reduction)

**Status:** design, `[top]`-authored, **awaiting human decision on D1–D3 below before dispatch.**
Per PLAN.md's D5 rule, the `[any]` implementation half may not start before this memo exists
and its open decisions are settled.
**Responds to:** `docs/Memo 1.md` §4 Task 4 + audit verdicts **B1** (NO — placeholders) and
**B4** (REVISE — no specialisation), recorded in `LEDGER.md` "External audit 2026-08-13".
**Author:** orchestrator. **Date:** 2026-08-13.

---

## 1. What the audit actually demanded (and what it did *not*)

Verdict B1, verbatim: *"Implementing Aubin-Lions and Prodi-Serrin as bare `Prop → Prop` arrows
completely bypasses PDE theory. The Lean kernel is merely verifying a logical tautology
(A → B → C). This violates your Definition of Done requirement for bona fide statements."*

Two things follow, and the second is easy to get wrong:

- **The complaint is about *empty types*, not about hypothesis parameters.** Parking undischarged
  analysis in a named hypothesis parameter rather than an `axiom` is the pattern
  `docs/REVIEW-2026-08-12.md` finding L7 explicitly *prescribes*, so that the kernel tracks the
  debt in the type. That pattern stays. What must change is that the types currently mention no
  analytic object at all: `HypothesisU → HasGlobalBoundedLimit` is inhabited by any function
  whatsoever between two `Prop`s, so nothing constrains what a supplier of `hAL` would have to
  actually prove.
- **The repair is therefore to give the parameters real content, not to prove them.** Proving a
  compactness theorem is out of scope for Task 4 and is not what the audit asked for. The
  deliverable is types that a competent analyst would recognise as the correct statements.

---

## 2. A material change in what is possible (found while scoping this task)

Every previous version of these files carries a scope exclusion of the form *"no
`tsum`/summability — those Mathlib modules are not built in this toolchain"*, and that exclusion
is why the enstrophy bound is currently written as *"every finite partial sum is ≤ C"* instead
of as a statement about an infinite series.

**That constraint no longer holds.** The Stage-0 cold build (2026-08-13) fetched the full
Mathlib cache: 8308 `.olean` files are present locally, and the following are all built and
importable in the pinned toolchain — verified by direct probe, not assumed:

| Module | Provides |
|---|---|
| `Mathlib.Topology.Algebra.InfiniteSum.Basic` / `.Order` / `.NatInt` | `Summable`, `tsum` (`∑'`), order lemmas |
| `Mathlib.Analysis.Normed.Lp.lpSpace` | `lp`, `Memℓp`, `Memℓp.summable` |
| `Mathlib.Analysis.InnerProductSpace.l2Space` | the Hilbert `ℓ²` structure |
| `Mathlib.Analysis.PSeries`, `Mathlib.Topology.Sequences` | convergence infrastructure |

So Task 4 was unblocked as a **side effect** of an infrastructure chore that was undertaken for
an unrelated reason (removing Gate 2's dependency on an external checkout). Recording this
because it is a real, and slightly lucky, causal link — not a plan we executed.

### 2.1 The current formulation is not wrong — it is the constructive shadow of the right one

Before proposing a rewrite, the honest question is whether the finite-partial-sum formulation is
*inadequate* or merely *unfashionable*. It is adequate, and Mathlib supplies the equivalence:

```
summable_of_sum_range_le          : (∀ n, 0 ≤ f n) → (∀ n, ∑ i ∈ range n, f i ≤ c) → Summable f
Summable.tsum_le_of_sum_range_le  : Summable f → (∀ n, ∑ i ∈ range n, f i ≤ c) → ∑' n, f n ≤ c
```

**De-risking step already performed** (per LL-5: derive and check before dispatching): the bridge
lemma has been *written and compiled* against the pinned Mathlib, footprint
`[propext, Classical.choice, Quot.sound]`:

```lean
theorem bridge (f : ℕ → ℝ) (C : ℝ) (hf : ∀ n, 0 ≤ f n)
    (hbd : ∀ M : ℕ, ∑ n ∈ Finset.range (M + 1), f n ≤ C) :
    Summable f ∧ ∑' n, f n ≤ C
```

Consequence for the dispatch: the upgrade is a **conservative extension**, not a rewrite that
risks invalidating existing results. Every current statement remains derivable from the new one,
with a proof that is known to close. An implementing agent is therefore not being asked to
gamble.

---

## 3. Proposed formalisation

All of this is for the **dyadic shell model** (post-pivot target), so the wavenumber is
`k n = 2ⁿ` and the enstrophy weight is `k n ^ 2 = 4ⁿ` — concrete throughout, per verdicts
A2/A3 dissolving under the pivot and A5 being fixed by `shellB`.

### 3.1 The two spaces

```lean
/-- Finite energy: the state is in ℓ². -/
def HasFiniteEnergy (u : ℕ → ℝ) : Prop := Summable (fun n => (u n) ^ 2)

/-- Finite enstrophy: the state is in the weighted space ℓ²(k²) — the shell-model analogue
    of H¹. This is the space Hypothesis U is a statement about. -/
def HasFiniteEnstrophy (u : ℕ → ℝ) : Prop := Summable (fun n => (k n) ^ 2 * (u n) ^ 2)

noncomputable def energy    (u : ℕ → ℝ) : ℝ := (1/2) * ∑' n, (u n) ^ 2
noncomputable def enstrophy (u : ℕ → ℝ) : ℝ := (1/2) * ∑' n, (k n) ^ 2 * (u n) ^ 2
```

The `1/2` matches `EnstrophyProduction.lean`'s `Ω = ½ Σ k_n² a_n²` exactly, so the new
definitions agree with the already-proven production identity rather than forking the convention.

### 3.2 `AubinLionsStatement` — with content

The shell-model compactness step, stated so that a supplier must actually produce the analytic
object. Three clauses, each carrying real information:

```lean
def AubinLionsStatement (nu : ℝ) (u0 : ℕ → ℝ) : Prop :=
  -- GIVEN: a uniform-in-cutoff enstrophy bound on the Galerkin family …
  (∃ C > 0, ∀ N, ∀ u, IsGalerkinSolution N nu (shellB k) (fun n => (k n)^2) u0 u →
      ∀ t ∈ Set.Icc (0:ℝ) T, enstrophy (u t) ≤ C) →
  -- … THERE IS a single limit trajectory, with three genuine properties:
  ∃ ulim : ℝ → ℕ → ℝ,
      -- (i) it is a solution of the untruncated system
      IsFullSolution nu (shellB k) (fun n => (k n)^2) u0 ulim
      -- (ii) it inherits the bound: finite enstrophy at every time, uniformly bounded
    ∧ (∀ t ≥ (0:ℝ), HasFiniteEnstrophy (ulim t))
    ∧ (∃ C > 0, ∀ t ≥ (0:ℝ), enstrophy (ulim t) ≤ C)
      -- (iii) it is the limit of the Galerkin family, modewise, locally uniformly in t
    ∧ (∀ n, ∀ t ≥ (0:ℝ), Filter.Tendsto (fun N => galerkinSol N t n) Filter.atTop
          (nhds (ulim t n)))
```

Clause (iii) is what makes this Aubin–Lions rather than an assertion that *some* bounded solution
exists — it says the limit is *the* limit of the approximating family, which is the entire content
of a compactness argument. Clause (ii) is where Fatou / weak-lower-semicontinuity lives.

### 3.3 The regularity criterion — and why the pivot makes it *tractable*

In the 3-D setting this step is Prodi–Serrin, a deep PDE theorem. **In the shell setting it is a
continuation criterion for an ODE system**, which is a materially easier object, and this is a
genuine dividend of the pivot that should be stated rather than glossed:

```lean
def RegularityCriterionStatement (nu : ℝ) (u0 : ℕ → ℝ) : Prop :=
  ∀ ulim, IsFullSolution nu (shellB k) (fun n => (k n)^2) u0 ulim →
    (∃ C > 0, ∀ t ≥ (0:ℝ), enstrophy (ulim t) ≤ C) →
      ∀ t ≥ (0:ℝ), IsSpatiallySmooth k ulim t
```

**Naming decision (D2 below):** calling this `ProdiSerrinStatement` in the shell setting is a
borrowed name for a different (easier) theorem, and the audit has just penalised exactly that
class of imprecision. Recommend renaming.

### 3.4 What is genuinely gained

| | before | after |
|---|---|---|
| Inhabitants of `AubinLionsStatement` | any function `Prop → Prop` | must exhibit a trajectory with three stated analytic properties |
| Enstrophy bound | finite partial sums ≤ C | `Summable` + `∑' ≤ C` (equivalent, but now stated in the standard vocabulary) |
| Limit uniqueness across horizons | one per `T` (audit B2) | **already fixed**: one `ulim` for all `T` |
| Specialisation (audit B4) | generic `B`, `w` | `shellB`, `k n ^ 2` — concrete |

---

## 4. What must NOT be claimed after this repair

Stating these now so the eventual ledger row cannot drift:

- **This does not prove compactness or the continuation criterion.** They remain undischarged
  hypothesis parameters. The file stays **Tier C** until and unless one of them is proven; the
  repair makes the debt *legible*, it does not pay it.
- **`millennium_reduction`'s proof remains a one-line composition.** That is correct and is not
  the defect — the defect was that the composed types said nothing.
- **Nothing here approaches 3-D Navier–Stokes.** The ℤ³ bridge is untouched and remains open
  (OP-2 / OP-6-D1).
- The theorem should probably be renamed away from `millennium_reduction`, for the same reason
  as §3.3 (decision D2).

---

## 5. Negative controls (mandatory, hand-derived before implementation)

A checker that cannot fail is not a checker; the same applies to a statement that cannot be
violated. Each of these must be shown to break the build:

| # | Perturbation | Must fail because |
|---|---|---|
| NC1 | Delete clause (iii) from `AubinLionsStatement` | the statement would no longer say the limit is the Galerkin limit; the *proof* still composes, so this must be caught by **review**, not the kernel — flag explicitly as a review-only control |
| NC2 | Replace `Summable (fun n => (k n)^2 * (u n)^2)` with `Summable (fun n => (u n)^2)` in `HasFiniteEnstrophy` | conflates ℓ² with the weighted space; `enstrophy` would no longer be the quantity Hypothesis U bounds |
| NC3 | Drop the nonnegativity hypothesis in the bridge lemma | `summable_of_sum_range_le` does not apply; unsolved goal |
| NC4 | Weaken `∃ C, ∀ t` to `∀ t, ∃ C` in clause (ii) | destroys uniformity in time exactly as `∀N ∃C` would destroy uniformity in cutoff (the A1 failure mode, one level down) |

NC1 deserves emphasis: **part of this repair is not kernel-checkable.** Whether the clauses say
the right thing is a statement-adequacy question, i.e. it goes back to human audit. That is the
honest cost of the repair and should be scheduled, not discovered later.

---

## 6. Decisions required from the human owner before dispatch

**D1 — Scope of the enstrophy upgrade.** Replace the finite-partial-sum formulation with
`Summable`/`tsum` throughout, or *add* the `tsum` form alongside and prove the bridge
(recommended: **add + bridge**, since it is a conservative extension whose proof is already
known to compile, and it keeps every existing result intact).

**D2 — Naming.** Rename `ProdiSerrinStatement` → `EnstrophyContinuationCriterion` (or similar)
and `millennium_reduction` → `dyadicShell_regularity_reduction`? The current names assert a
3-D pedigree the statements no longer have, which is the exact defect verdict D1 killed.
Recommended: **yes, rename**.

**D3 — Does clause (iii) go in now, or later?** It requires naming the Galerkin family as a
function of `N` inside the statement, which is a moderate amount of additional structure. It is
also the clause that makes the statement genuinely Aubin–Lions. Recommended: **now** — without
it, B1 is only half-fixed.

---

## 7. Dispatch plan (after D1–D3)

1. `[any]` — bridge lemma + the two spaces + `energy`/`enstrophy` (`tsum` form), with the
   agreement lemma tying `enstrophy` to `EnstrophyProduction.lean`'s `Ω`. **Known to compile.**
2. `[any]` — restate `AubinLionsStatement` and the criterion per §3.2–3.3, specialised to
   `shellB` (closes B4).
3. `[any]` — re-derive `millennium_reduction`; the composition should still be one line.
4. `[top]` — NC1–NC4, then a ledger row explicitly scoped per §4.
5. `[human]` — statement-adequacy audit of the new clauses (see NC1).

**Estimated risk:** low for steps 1–3 (the API is verified present and the hardest lemma already
compiles), moderate for step 5, which is judgment rather than engineering.
