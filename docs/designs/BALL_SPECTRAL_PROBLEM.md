# Design memo — the 5/6 ball gap as a continuum spectral problem, and half of it proved

**Status:** `[top]` hand-derivation per LL-5/LL-7, written **before** any implementation it
specifies. Every identity below was hand-derived first and *then* checked in exact integer /
rational arithmetic; the checks and their negative controls are named inline.
**Author:** orchestrator (Fable). **Date:** 2026-08-15.
**Companion to:** `docs/designs/TRIAD_TORUS_THEOREM.md` (its torus half, now Tier A in
`lean_src/TriadTorus.lean`).

---

## 0. What this memo changes

Before it, the "5/6 conjecture" was a numerical observation: the normalised-Laplacian gap of
the ball-truncated triad 2-section sits at ≈ 0.8333 and creeps toward 5/6 (deviations
2.4e-4 → 1.5e-5 over M=3..7). It named no operator, so it could not be attacked.

After it: the gap's *upper* half is **proved exactly, at every M and in the continuum**, by an
explicit eigenfunction; the conjecture is reduced to a single sharp converse statement about
one classical integral operator; and the reduction identifies **which sector** (odd) carries
the whole question, killing the even-sector branch that a naive attack would have spent effort
on.

## 1. The exact ball weight (theorem — the boundary analogue of the torus formula)

`Λ_M = {k ∈ ℤ³ \ {0} : |k|² ≤ M²}`; triads and the incidence-counted 2-section exactly as in
the torus memo §1 (the `(a,c)` representation, incidences not triads, so the `(u,u,2u)`
degeneracy is absorbed).

> **Theorem 1.** For distinct `u, v ∈ Λ_M`:
> `A_M(u,v) = 2·[u+v ∈ Λ_M] + 4·[u−v ∈ Λ_M]`.

*Derivation* — the torus §2 count, with the ball's admissibility conditions kept:
- **type {1,2}**: triads `(u,v,u+v)`, `(v,u,u+v)` — admissible iff the third slot `u+v` lies in
  `Λ_M`. Contributes `2·[u+v ∈ Λ_M]`.
- **type {1,3}**: `(u, v−u, v)`, `(v, u−v, u)` — need the middle slot in `Λ_M`, i.e.
  `u−v ∈ Λ_M` (nonzero automatically as `u ≠ v`, and `|u−v| = |v−u|`). Contributes `2·[u−v ∈ Λ_M]`.
- **type {2,3}**: `(v−u, u, v)`, `(u−v, v, u)` — same condition. Contributes `2·[u−v ∈ Λ_M]`.

*Checked*: exact integer comparison against `symbolic/triad_hypergraph.py`'s independently
built `two_section` at M=2,3,4 — **81 034 ordered pairs, 0 mismatches**.

*Torus consistency*: when every nonzero sum stays in the index set, `[u+v ∈ Λ] = [u+v ≠ 0]` and
`[u−v ∈ Λ] = 1`, giving `2·[u+v≠0] + 4 = 6 − 2·[u+v=0]` — exactly `TriadTorus.A_eq`. The two
theorems are one theorem with two boundary conditions, which is the right way to hold them.

**Consequence.** Rescaling `x = u/M`, `y = v/M`, the conditions `|u ± v| ≤ M` become
`x ± y ∈ B` (unit ball). The continuum kernel is therefore **not a guess**:
`K(x,y) = 2·1_B(x+y) + 4·1_B(x−y)`, exactly as previously conjectured, now derived.

## 2. The sector splitting (theorem)

Let `C` have kernel `[u−v ∈ Λ_M]` (its diagonal vanishes since `0 ∉ Λ_M`) and `S` have kernel
`[u+v ∈ Λ_M]`. Off the diagonal `S = C∘R` with `R` the reflection `f(u) ↦ f(−u)`, since
`Λ_M = −Λ_M`. Hence `A_M` commutes with `R` and the spectrum splits, with

> **Theorem 2.** On even vectors `A_M` acts as `(2+4)·C = 6C`; on odd vectors as `(4−2)·C = 2C`
> — modulo the diagonal defect `Δ = diag(2·[2u ∈ Λ_M])`.

`Δ` carries `O(n)` entries against the matrix's `O(n²)` mass and vanishes in the continuum
limit; **it is the entire reason the finite-M numbers approach 5/6 from above rather than
sitting on it** (measured `μ₂` at M=6 is 0.166641, just under `1/6`). This is stated, not
hidden: a memo that quietly dropped `Δ` would have made the finite-M data look like a
discrepancy instead of an explained offset.

Write `d(u) = Σ_v A_M(u,v)`, `Q = D^{-1/2} C D^{-1/2}`, `P = D^{-1/2} A_M D^{-1/2}`. Then
`P_even = 6Q`, `P_odd = 2Q`, and in the continuum `d(x) = 6V(|x|)` with `V` the **lens volume**
`V(r) = vol(B ∩ (B + r e)) = (π/12)(4+r)(2−r)²`, `0 ≤ r ≤ 2` (checks: `V(0) = 4π/3`, `V(2) = 0`).
The Perron pair is exact: `Q √V = (1/6)√V`, so `P` has top eigenvalue 1 as it must.

Therefore
```
μ₂  =  max( 6·ν₂^even(Q) ,  2·ν₁^odd(Q) ).
```

**Which branch carries it — measured, decisively** (`exploration/ball_sector_split.py`,
positive control: the even sector's leading eigenvalue must come out 1.000000, and does):

| M | even #2 | odd #1 | μ₂ | carrier |
|---|---|---|---|---|
| 3 | 0.158481 | 0.166425 | 0.166425 | **odd** |
| 4 | 0.134658 | 0.166581 | 0.166581 | **odd** |
| 5 | 0.144462 | 0.166608 | 0.166608 | **odd** |
| 6 | 0.147997 | 0.166641 | 0.166641 | **odd** |

The odd branch converges monotonically to `1/6`; the even branch is non-monotone and stays
clear below. **The 5/6 conjecture is a statement about the odd sector alone**, i.e. about
`ν₁^odd(Q) = 1/12`.

## 3. The linear eigenfunction — half the conjecture, proved

> **Theorem 3 (exact, every `M`, every linear functional).** For `h(u) = ⟨u, e⟩`:
> `(C h)(u) = ½·V(u)·h(u)`, where `V(u) = #{v ∈ Λ_M : u − v ∈ Λ_M}`.

*Proof.* Fix `u` and put `W(u) = {v ∈ Λ_M : u − v ∈ Λ_M}`. The map `v ↦ u − v` sends `W(u)` to
itself (`u − (u−v) = v`, and the two membership conditions swap), and is an involution. Hence
```
Σ_{v ∈ W(u)} h(v)  =  Σ_{v ∈ W(u)} h(u − v)  =  |W(u)|·h(u) − Σ_{v ∈ W(u)} h(v),
```
by linearity of `h`, so `2 Σ_{v∈W(u)} h(v) = V(u)·h(u)`. And `(Ch)(u) = Σ_{v ∈ W(u)} h(v)`. ∎

*Checked*: exact integer/rational, pointwise at every mode, M=3,4,5 — **0 mismatches**;
negative control `h(u) = u₁²` (even, not linear) mismatches at **all 122** modes at M=3, so the
check can fail.

**Consequences.** `h` is odd and is an exact eigenfunction of the generalised problem
`C h = λ V h` with `λ = ½` — hence `ν₁^odd(Q) ≥ 1/12`, therefore `μ₂ ≥ 1/6` and

> **the continuum gap is `≤ 5/6`, proved, with an explicit witness.**

The same involution proves the Rayleigh quotient identity directly:
`R[h] := ∫∫_{B×B, |x−y|≤1} h(x)h(y) / ∫_B V(x)h(x)² dx = ½` for every linear `h` — measured as
`0.500000` at M=4,5,6 (against 0.454 for `h = u₁/|u|` and 0.379 for `h = sign(u₁)`, so the
value is specific to linearity, not generic to odd functions).

## 4. What remains open — one sharp statement

> **Conjecture (all that is left of "5/6").** In the odd sector, `½` is the *largest*
> generalised eigenvalue: no odd `h` on the unit ball satisfies `R[h] > ½`. Equivalently
> `ν₁^odd(Q) = 1/12`, `μ₂ = 1/6`, and the normalised gap tends to exactly `5/6`.

Seven-point numerical support (deviations from 5/6: 1.7e-3, 2.4e-4, 8.6e-5, 5.9e-5, 2.5e-5,
1.5e-5 over M=2..7, strictly monotone) — Tier C evidence, not a proof, and by §2 it approaches
from the side the diagonal defect predicts.

## 5. Attack plan (dispatch-ready; do **not** start before the owner's go)

**Step A — block-diagonalise by spherical harmonics (analysis, `[top]`).** `1_B(x−y)` is a
radial kernel, so the operator commutes with `SO(3)` and decomposes over harmonic degree `ℓ`;
the odd sector is exactly `ℓ` odd. Linear functions span `ℓ = 1` with radial profile `r`.
Theorem 3 says that profile is an eigenfunction with eigenvalue `½` *inside its block*. The
conjecture then splits into two finite, checkable claims:
  - **A1**: within `ℓ = 1`, `½` is the top eigenvalue of the (one-dimensional, radial) block;
  - **A2**: every block with `ℓ ≥ 3` odd has top eigenvalue `< ½`.

**Step B — exact rational Rayleigh bounds (Tier B).** Each block is a 1-D integral operator in
`r ∈ [0,1]` with a kernel expressible through `V` and Legendre polynomials; discretising with
exact rationals gives *certified* two-sided bounds per block. Lower bounds are already exact
(`½`, Theorem 3); the work is the upper bounds, which is where a Tier B harness earns its
keep. Mandatory controls: a block whose top eigenvalue is *known* (the `ℓ = 1` case, `= ½`)
must be reproduced, and a perturbed kernel must break the bound.

**Step C — Lean (Tier A), only Theorems 1–3.** Theorem 3 is the natural first target: it is
a finite involution argument of exactly the shape already formalised twice in this repo
(`AbstractAlgebraicConservation.triad_sum_zero`, `TriadTorus.w23_eq`), needs no analysis, and
holds for any finite `R`-symmetric index set — so it should be stated at that generality, with
`Λ_M` an instance. Theorem 1 is the torus counting proof with two extra membership side
conditions; it would let `TriadTorus.A_eq` be re-derived as its corollary rather than kept as
a parallel proof. **Steps A/B are analysis and stay Tier B/C until and unless they close.**

## 6. What this memo does *not* claim

Not that the conjecture is proved — only its `≤` half, which is exactly the half an explicit
witness can give. Not that the ball gap bears on Navier–Stokes regularity: it is a property of
the *unconstrained* resonance geometry, and the mechanism it was originally screened for
(OP-2′) was killed by owner verdict on 2026-08-15. It is kept because it is a self-contained,
falsifiable, and now half-solved mathematical question that this programme's own instruments
raised — and because §5's Step C would put a second genuinely `ℤ³`-flavoured result in Tier A.
