# Design memo — door #1 of the barrier: is there a *quartic* invariant?

**Status:** `[top]` hand-derivation per LL-5, written **before** the search it specifies.
**Owner decision, 2026-08-25:** option B — change the observable rather than the integrator,
and attack the barrier's first door algebraically.
**Author:** orchestrator (Fable). **Date:** 2026-08-25.
**Prerequisite:** `lean_src/DyadicRiccati.lean` (Tier A) and
`docs/designs/ALPHA_HALF_FORMALISATION.md`, which state the barrier this memo attacks.

---

## 1. Why a *quartic*, precisely

`DyadicRiccati.thetaStar_two_lt_iff` says: refuting finite-time enstrophy blow-up by the
Riccati route needs `‖u‖^θ ∈ L¹_loc` with `θ ≥ θ*(α) = 2/(3−1/α)`, i.e. **`θ ≥ 4` at
`α = 2/5`**. The energy inequality supplies exactly `θ = 2`.

`‖u‖² = H_α` is **quadratic** in `u`; `‖u‖⁴ = H_α²` is **quartic**. Energy methods produce
`L¹` control of quadratic quantities — that is what they are. So door #1 is not "find a better
estimate"; it is the sharply posed algebraic question:

> **Does the truncated dyadic system possess a quartic conserved (or monotone) quantity whose
> dissipation dominates `H_α²`?**

If the answer is no for every quartic in a stated ansatz class, that class of route is closed,
and the closure is a recorded negative result rather than an unexamined hope.

## 2. The exact evolution of every weighted quadratic (derived here; generalises the repo's
`shellB_energy_conservation`)

System (Cheskidov eq. 3.1 truncated at `N`, `λ = 2`, `g = 0`, `u_0 = u_{N+1} = 0`):
```
du_n/dt = −ν λ^{2αn} u_n + λ^n u²_{n−1} − λ^{n+1} u_n u_{n+1}.
```
Put `H_γ = Σ_n λ^{2γn} u_n²`, so `H_0 = |u|²` (energy) and `H_α = ‖u‖²` (enstrophy).

Differentiate and split. The dissipative part gives `−2ν H_{γ+α}` immediately. For the
nonlinear part, set
```
b_n := λ^{2γn + n + 1} u_n² u_{n+1} .
```
The out-flux term contributes `−2 Σ_n b_n` directly. The in-flux term is
`2 Σ_n λ^{2γn+n} u_n u²_{n−1}`, and since
`b_{n−1} = λ^{2γn − 2γ + n} u²_{n−1} u_n`, we have `λ^{2γn+n} = λ^{2γ}·λ^{2γn−2γ+n}`, so that
term equals `2λ^{2γ} Σ_n b_{n−1}`. With `b_0 = 0` (from `u_0 = 0`) and `b_N = 0` (from
`u_{N+1} = 0`) the two index ranges coincide, giving

> **Identity (Q1).**  `d/dt H_γ = −2ν H_{γ+α} + 2(λ^{2γ} − 1) Σ_{n=1}^{N} λ^{(2γ+1)n+1} u_n² u_{n+1}`

**Consequences, all immediate and all checkable:**
- `γ = 0`: the prefactor `λ^0 − 1` vanishes, recovering exact energy conservation of the
  nonlinearity — the repo's `shellB_energy_conservation`, now as one instance of a family.
- **`γ = 0` is the *only* conserved weighted quadratic** (the prefactor vanishes only there),
  so the energy inequality's `θ = 2` is not an accident of technique: it is the whole quadratic
  supply. This is the precise sense in which door #1 requires leaving degree 2.
- `γ < 0` and **positive** data: `λ^{2γ} − 1 < 0` and `Σ b_n ≥ 0`, so `d/dt H_γ ≤ 0` — a
  monotone family. It is *unavailable* for sign-changing data, because `u_{n+1}` may be
  negative and `Σ b_n` then has no sign. **This is exactly where positivity does its work in
  the literature**, and it is why BMR's route is closed to us.

Identity (Q1) is exact, finite, and rational for rational data: it belongs in Tier B, and its
`γ = 0` case is already Tier A.

## 3. The search (what will actually be run)

Search for polynomial invariants of the **inviscid** truncated system (`ν = 0`) — dissipation
only helps, so a quantity conserved by the nonlinearity is the right target, and any monotone
candidate must first survive this test.

Let `Q(u)` be a homogeneous polynomial. Require `dQ/dt = 0` **identically as a polynomial in
`u_1,…,u_N`**, which is a *linear* system in `Q`'s coefficients — solvable in exact rational
arithmetic, with a definite answer (a basis of the solution space, or `{0}`).

**Ansatz classes, in order:**
- **A2 — weighted quadratics** `Σ c_n u_n²`. *Known answer* (§2): a one-dimensional space,
  spanned by energy. This is the **positive control**: a search that fails to find energy here
  is broken and no other result from it may be read.
- **A4d — diagonal quartics** `Σ c_n u_n⁴`.
- **A4n — neighbour quartics** `Σ c_n u_n² u_{n+1}²`.
- **A4g — general banded quartics**: all monomials `u_i u_j u_k u_l` with indices inside a
  window of width `w` (`w = 3`, then `4` if affordable). Contains A4d and A4n, so it subsumes
  them; run the narrow ones first because they are cheap and interpretable.

**Controls (both mandatory, LL-12):**
- **POSITIVE:** A2 must return exactly a 1-dimensional space = energy.
- **NEGATIVE:** the same search on a *perturbed* system (change the in-flux exponent `λ^n` to
  `λ^{n+1}`, which destroys the telescoping) must return `{0}` for A2. A search that finds an
  invariant for a system with none would certify anything.

**Pre-registered kill criterion (LL-15 — named before any number is seen):** if A4g at
`w = 3` and `w = 4` returns only the trivial space and the multiples of `E²` (which is
quartic but carries no new information — its `L¹` control is *not* control of `∫H_α²`), then
**door #1 is closed for banded polynomial invariants of degree 4**, and that is the result.
The programme records it and does not revisit degree-4 polynomial invariants without a new
idea.

## 4. What a negative result would and would not close

Would close: banded polynomial quartic **conserved** quantities — the natural home of an
"energy-like" improvement, and the only place an energy method could find one.

Would **not** close: (i) quartics that are *monotone* but not conserved with no polynomial
certificate; (ii) non-polynomial quantities; (iii) quantities that are conserved only
asymptotically or on invariant subsets; (iv) door #2 of the barrier — leaving the Riccati route
altogether. Any write-up must state this scope. A closed door is not a closed problem, and the
distinction is exactly what the four dead Sym² mechanisms failed to observe.
