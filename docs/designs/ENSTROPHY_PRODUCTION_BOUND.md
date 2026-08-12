# Design Note — Sqrt-Free Local Bound on the Enstrophy Production Term

**Author:** Fable 5 (top-tier derivation, per PLAN.md's own rule that inequality selection is
a mathematical-judgment task, not delegable). **Decided by human owner, 2026-08-12:** pursue
the analytical route on the enstrophy-production identity in parallel with numerical steering,
in response to the D5 digit-blowup escalation.

## What this derives

Starting from `EnstrophyProduction.lean`'s proven identity (the nonlinear part of `dΩ_N/dt`
equals `3·S_N` where `S_N := Σ_{n=0}^{N-1} k_n³a_n²a_{n+1}`), a purely algebraic, **square-free
of nothing but also introducing no square roots** bound:

**Main inequality: `S_N² ≤ 2·Ω_N³`.**

This is the shell-model analogue of the classical local-in-time NSE estimate — Ω growing no
faster than a supercritical `3/2`-power ODE. It is provable **now**, entirely from what is
already in the repo, and it needs no new definitions (satisfying PLAN.md's E-1 ban).

## Derivation (three elementary steps, no Mathlib inner-product Cauchy-Schwarz needed)

**Step 1 (pure algebra, no inequality).** Reindexing `m=n+1` and using the doubling
`k_{n} = k_{n+1}/2` (equivalently `k_{m-1}=k_m/2`):
```
Σ_{n=0}^{N-1} k_n² a_{n+1}²  =  Σ_{m=1}^{N} (k_m/2)² a_m²  =  (1/4) Σ_{m=1}^{N} k_m² a_m²  ≤  Ω_N / 2
```
(the last step drops the missing `m=0` term, which is `≥0`, and uses `Ω_N=(1/2)Σ_{n=0}^N k_n²a_n²`).

**Step 2 (pointwise, no Cauchy-Schwarz machinery).** For `x_n := k_n²a_n² ≥ 0`:
```
Σ x_n²  ≤  (Σ x_n)²        [cross terms 2·Σ_{i<j}x_ix_j are ≥0]
```
so `Σ_{n=0}^{N-1} k_n⁴a_n⁴ ≤ Σ_{n=0}^{N} k_n⁴a_n⁴ = Σx_n² ≤ (Σx_n)² = (2Ω_N)² = 4Ω_N²`.

**Step 3 (Cauchy–Schwarz on the two sequences `(k_n²a_n²)` and `(k_n a_{n+1})`).**
```
S_N² = (Σ (k_n²a_n²)(k_n a_{n+1}))²  ≤  (Σ k_n⁴a_n⁴) · (Σ k_n²a_{n+1}²)  ≤  4Ω_N² · (Ω_N/2)  =  2Ω_N³
```

## Numerical sanity check (before dispatch — same instance as the identity's own witness)

`N=2, k=(1,2,4), a=(1,2,3)`: `S_N = 98` (from the identity's own worked example), `Ω_N = 80.5`.
- Step 1: `Σk_n²a_{n+1}² = 40 ≤ Ω_N/2 = 40.25` ✓ (tight — expected, only 2 terms)
- Step 2: `Σx_n² = 20993 ≤ (Σx_n)² = 25921` ✓
- Main: `S_N² = 9604 ≤ 2Ω_N³ = 1043320.25` ✓ (loose here; Cauchy–Schwarz is rarely tight on
  arbitrary data — this checks the *direction* and absence of a sign error, not sharpness)

## What this bound honestly does NOT give

**It is a LOCAL bound only.** `dΩ_N/dt ≤ 3S_N ≤ 3√(2Ω_N³)` (dropping `−νP_N ≤ 0`, i.e.
*discarding* the beneficial dissipation) gives, via the standard Bernoulli/Riccati ODE
comparison, a **finite blow-up-time estimate depending on `Ω_N(0)`** — exactly the structure
of NSE's own local existence theory, reproduced honestly at the dyadic level. It does **not**
address:
- **Global-in-time** boundedness (that requires actually using `−νP_N`, which this bound
  discards);
- **Uniformity in `N`** (Hypothesis U's dyadic analogue) at all.

Closing either requires relating palinstrophy `P_N=Σk_n⁴a_n²` back to `Ω_N` in a way that
accounts for *where across the shells* the energy sits — production pushes energy toward
higher shells (where viscosity is strongest), so a naive Grönwall closure does not fall out
for free from this bound alone. This is genuinely the hard part of the problem, not a
formality.

## Relevant prior work (verified 2026-08-12, precise scope — do not cite more broadly)

**Barbato, Morandin, Romito, "Smooth solutions for the dyadic model," arXiv:1007.3401 (2010).**
Verified abstract (WebFetch, 2026-08-12): proves well-posedness of **positive** solutions of
the *viscous* dyadic model "in the relevant scaling range which corresponds to Navier-Stokes."
**This is a real, precisely-scoped result, not unconditional global regularity** — the
positivity restriction and the specific scaling range are load-bearing, not incidental. I have
read only the abstract, not the proof technique; the full paper's closing argument (and
whether the "relevant scaling range" matches this program's fixed-`ν`, `k_n=2^n` setup, and
whether our profiles P1/P2/P3 — which are non-negative but not obviously *preserved*
non-negative by the flow — satisfy the positivity hypothesis) is **future work, not resolved
here.** Flagging this precisely, per SPEC's Stage 1 rule that literature claims must be
re-verified before being relied on, rather than citing loosely as "shell models are known to
be globally regular."

## Dispatch plan

1. **Tier B**: exact-ℚ certification of the three-step chain (`tests/tier_b_production_bound.py`),
   with a negative control showing the bound is genuinely tight-in-direction (e.g. fails if the
   doubling structure is broken, mirroring the existing negative-control style).
2. **Tier A**: Lean proof in a new file building on `EnstrophyProduction.lean`'s `prodOut` and
   `enstrophy_production_dyadic_NL`.
3. Not dispatched yet, explicitly future work: adapting Barbato–Morandin–Romito's technique to
   close the global/uniform question. This design note is scoped to the *local* bound only.
