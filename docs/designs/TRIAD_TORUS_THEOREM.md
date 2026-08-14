# Design memo — the triad 2-section on the torus, solved exactly (pre-formalisation derivation)

**Status:** `[top]` hand-derivation per LL-5, written **before** the Lean file it specifies.
**Target:** `lean_src/TriadTorus.lean` — the programme's first Tier A statement about the
genuine `ℤ³`-type resonance structure (owner decision 2026-08-14: torus theorem first, ball
conjecture second, in sequence).
**Author:** orchestrator (Fable). **Date:** 2026-08-14.

---

## 1. Setting and definitions (matching `symbolic/triad_hypergraph.py` exactly)

`G` a finite additive abelian group (intended instance `(ℤ_m)³`, `m` odd), `Λ = G \ {0}`.
Ordered resonant triads: `T = {(a,b,c) ∈ Λ³ : a+b=c}`, represented as pairs `(a,c)` with
`b := c−a` (the Python representation). The 2-section weight between distinct `u,v ∈ Λ` is the
**incidence count**: each ordered triad contributes 1 for each of its three slot-pairs
`{1,2}, {1,3}, {2,3}` whose values equal `{u,v}` as a set.

**Why incidences and not triads — the degeneracy this absorbs.** If `v = 2u`, the single
ordered triad `(u, u, 2u)` has *two* slot-pairs with values `{u, v}` (slots `{1,3}` and
`{2,3}`), and the naive "count triads containing both" would undercount relative to the generic
case. Counting (triad, slot-pair) incidences makes the formula uniform with **no** genericity
hypothesis, which is exactly what the entry-by-entry numerical verification at `m=3` confirmed
(where pairs like `(u, 2u)` do occur).

## 2. The theorem, derived

Fix `u ≠ v`, both `≠ 0`. Partition incidences by slot-pair type; each type is an independent
count over `T`:

**Type {1,2}** — triads with `{k₁,k₂} = {u,v}`: exactly `(u,v,u+v)` and `(v,u,u+v)`, admissible
iff `u+v ∈ Λ`, i.e. `u+v ≠ 0`. Each has exactly one `{1,2}` slot-pair. Count = `2·[u+v ≠ 0]`.

**Type {1,3}** — triads with `{k₁,k₃} = {u,v}`: `(u, v−u, v)` and `(v, u−v, u)`. Middle entries
`v−u, u−v ≠ 0` automatically (`u ≠ v`), so both always admissible. Count = `2`.

**Type {2,3}** — `(v−u, u, v)` and `(u−v, v, u)`: likewise always admissible. Count = `2`.

> **Theorem (torus 2-section).** For `u ≠ v` in `Λ`:
> `A(u,v) = 6 − 2·[v = −u]`, i.e. `A = 6(J − I) − 2P` with `P` the involution `u ↦ −u`.

(Degenerate coincidences like `v = 2u` merge the type-{1,3} and type-{2,3} triads into one
ordered triad carrying two incidences — the counts per *type* are unaffected. This is the whole
point of §1's definition.)

## 3. Spectral corollary (to be stated as sum identities — no matrix library needed)

Assume additionally **no 2-torsion** (`x + x = 0 → x = 0`; holds in `(ℤ_m)³`, `m` odd — this
hypothesis is genuinely needed: at a 2-torsion point `u = −u` the row of `A` is constant 6 and
the degree formula changes). Then for `f : G → ℝ` with `Σ_{v∈Λ} f(v) = 0`:

- `f` **even** (`f(−x) = f(x)`):  `Σ_{v ∈ Λ, v≠u} A(u,v)·f(v) = −8·f(u)`
  — derivation: `6·(0 − f(u)) − 2·f(−u) = −6f(u) − 2f(u)`.
- `f` **odd**  (`f(−x) = −f(x)`): `… = −6f(u) + 2f(u) = −4·f(u)`.
- Row sum (degree): `Σ_{v≠u} A(u,v) = 6(n−1) − 2 = 6n − 8` (`n = |Λ|`).

Normalised spectrum `{1, −4/(6n−8), −8/(6n−8)}` → **torus spectral gap → 1**. Hence the
measured ball gap (M=2..5: deviations from 5/6 of 1.7e-3, 2.4e-4, 8.6e-5, 5.9e-5) is a pure
boundary invariant — the separate, open **5/6 conjecture** (second eigenvalue `1/6` of the
kernel `2·1_B(x+y) + 4·1_B(x−y)` on the unit ball), deliberately *not* part of the Lean scope.

## 4. Lean formalisation plan (dispatch-ready)

File `lean_src/TriadTorus.lean`, `{G} [AddCommGroup G] [Fintype G] [DecidableEq G]`:

1. `Λfin : Finset G := univ.erase 0`; the three counts as `Finset.filter … .card` over
   `(Λfin ×ˢ Λfin).filter (fun p => p.2 - p.1 ∈ Λfin)` in the `(a,c)` representation.
2. Three lemmas `w12_eq / w13_eq / w23_eq` by proving each filter equals an explicit doubleton
   (or `∅` for w12 when `u+v=0`) via `Finset.ext`, then `card`.
3. `A := w12 + w13 + w23` (definition — the bridge to the code's construction is documented
   here, §1, and verified empirically at `m=3`); main theorem
   `A u v = if u + v = 0 then 4 else 6`.
4. Eigen-lemmas as the sum identities of §3 with hypotheses `hf0`, `heven`/`hodd`, `h2t`.
5. Non-vacuity witnesses; negative controls: dropping `u ≠ v`, or the no-2-torsion hypothesis
   in the eigen-lemmas, must break the proofs (2-torsion counterexample: any group with an
   element of order 2).

**Mathlib needs (to verify built before dispatch):** `Finset.filter`, `Finset.card_insert_of_not_mem`,
`Finset.sum_erase`, `Finset.sum_ite_eq'` — all in the core BigOperators/Finset modules already
used by this repo. No analysis imports.
