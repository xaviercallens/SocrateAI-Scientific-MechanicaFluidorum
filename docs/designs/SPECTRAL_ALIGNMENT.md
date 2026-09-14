# Design memo — the adversarial alignment as a spectral optimisation (`M = 64` and beyond)

**Status:** PROPOSED, 2026-09-14. Nothing here is implemented beyond the grounding experiment
in §2. Tier C throughout: the object is an initial condition for the floating-point scout, and
nothing in this memo bears on Hypothesis U. **Read `CORE_TAIL_CAP.md` §4.3.9 first** — it records
why the obvious optimisation of the current search does not work, which is the reason this
memo exists.

---

## 1. The problem, and why it is not a compute problem

The adversarial family is defined by a sign vector `σ ∈ {±1}ⁿ` on the `n` rep classes of the
half-ball, chosen by greedy first-improvement sweeps to maximise

> `|S(σ)|`,  `S(σ) = Σ_{triads (a,b,c)} σ_a σ_b σ_c g_{abc}`,

with `g` an exact integer built from the wavevector geometry (`tests/tier_b_adversarial_
alignment.py`, ported to `exploration/dual_scale_scout_rs`). Measured costs of that search:

| `M` | classes `n` | triads | sweeps to converge | wall (solo) |
|---|---|---|---|---|
| 8 | 1 054 | 2.0×10⁶ | 9 | 0.5 min |
| 16 | 8 538 | 1.35×10⁸ | 42 | 8 min |
| 32 | 68 532 | 8.7×10⁹ | 113 | ~22 h |
| 64 (extrapolated) | ~5.5×10⁵ | ~5.6×10¹¹ | ~300 | **~80 days on 16 vCPU** |

Two things compound. Each sweep must look at every triad once (`O(#triads) ∝ M⁶`), and the
number of sweeps grows with `M` (`9 → 42 → 113`). Neither is a parallelism problem — the sweep
is already `rayon`-parallel and memory-light (1.4 MB of state at `M = 32`).

**The natural fix has been tried and is a net loss.** Dirty-tracking (skip a class's re-check
unless something that could change its answer flipped) is provably exact and was validated
against the full recorded `M = 16` sweep sequence — and is **5.5 % slower**, because even the
final sweep's handful of flips dirties over half the class set (§4.3.9). The triad co-occurrence
structure is close to dense. Worklist tricks that win on locally-sparse problems do not apply.
So the per-sweep cost is essentially `O(#triads)` for *any* exact coordinate method, and `M = 64`
needs a different algorithm, not a faster implementation of this one.

## 2. The grounding fact: the objective is the scout's production, and the scout computes it by FFT

The greedy's `S(σ)` was derived as the enstrophy production of the state `u_k = iλ σ_k (k × d_k)`
at `t = 0`. That derivation is now **measured, not assumed.** At `M = 8`, three sign patterns
spanning three orders of magnitude in `|S|` and both signs — all `+1`, the converged greedy,
and an LCG random vector — were evaluated two ways: `S` in exact integers (Python,
`tier_b_adversarial_alignment.geometric_table`), and `P(t = 0)` by the scout's FFT engine with
the pattern loaded through `--phases-in`:

| pattern | `S` (exact) | `P(t=0)` (scout, FFT) | `P/S` |
|---|---|---|---|
| all `+1` | `240 311 609 680` | `2.128827398×10⁴` | `8.858612369×10⁻⁸` |
| greedy | `822 566 075 728` | `7.286794014×10⁴` | `8.858612371×10⁻⁸` |
| random | `−4 745 311 664` | `−4.203687661×10²` | `8.858612371×10⁻⁸` |

**One constant, to the last printed digit of `P`, sign included**; and `E`, `D`, `D₂` are
identical across the three (the energy normalisation `f = √(E₀/E)` is sign-independent, so it
cannot spoil the proportionality). Reproducible: `exploration/alignment_spectral/s_vs_p.py`.

Consequently: **maximising `|S(σ)|` is maximising `|P(u(σ))|`, and `P` — together with its
gradient — is computable in `O(N log N)` by the machinery the scout already has**, instead of
`O(#triads) ∝ M⁶` by triad enumeration. The convolution structure `p + q + r = 0` that makes the
triad table dense is exactly the structure the FFT diagonalises.

## 3. The design

### 3.1 Objective and gradient by FFT

`P(u) = Σ_k |k|² Re⟨u_k, B_k(u)⟩`, `B = Leray[N]`, `N_k(u) = −i Σ_{p+q=k} (q·u_p) u_q`. `P` is a
cubic form in `σ` (each `σ_j` enters linearly through `u_j` and `u_{−j}`). Its gradient is

> `∂P/∂u_j = |j|² B_j(u) + Σ_k |k|² ⟨u_k, ∂B_k/∂u_j⟩`,

the second term being the **adjoint** of the bilinear map `N` contracted with `|k|² u` — itself
two convolutions (one for the `u_p` slot, one for the `u_q` slot), each an FFT pass of the same
shape the scout's RHS already performs (15 transforms per RHS). The Leray projection is
self-adjoint, so it commutes through. One gradient ≈ 3 RHS-equivalents ≈ **45 FFTs**.
`∂P/∂σ_j` follows by the chain rule through `u_j` and `u_{−j} = conj(u_j)`.

**Cost, from the scout's measured RHS time** (0.196 s at `M = 16`, `64³` grid):

| `M` | grid | one gradient | one exact greedy sweep | ratio |
|---|---|---|---|---|
| 16 | 64³ | ~0.6 s | 11 s | 18× |
| 32 | 128³ | ~5 s | 12 min | 150× |
| 64 | 256³ | ~40 s | ~13 h | **~1 000×** |

Memory at `M = 64`: `256³` complex `f64` = 268 MB per array, ~20 arrays ≈ **5–6 GB**. Fits the
workstation; comfortable on a 64 GB VM.

### 3.2 The optimiser

Two candidates, in order of preference, both driven by the FFT gradient:

**(A) Damped Jacobi sign ascent.** From `σ⁰`, compute all `n` first-order deltas at once
(`δ_j = −2 σ_j ∂_j P`, the exact change in `P` if `j` alone flips — one gradient), flip a damped
subset of the improving classes (largest `|δ|` first, at most a fraction `ρ` of `n`, `ρ ≈ 0.1`
initially, halved whenever the objective fails to increase), repeat until no class improves.
This is the greedy's decision rule applied simultaneously rather than sequentially; damping is
what prevents the oscillation that undamped Jacobi produces on dense couplings. Iterations to
converge: **unknown — to be measured at `M = 8, 16, 32`** (hypothesis: 50–300).

**(B) Tensor power iteration then rounding.** Relax to the sphere, iterate
`x ← ∇P(x)/‖∇P(x)‖` (the power method for a cubic form), round `σ = sign(x)`, then polish with
(A). Fewer iterations, but rounding a continuous optimum can lose a lot; its value is as an
*initialiser*.

Either way the search runs in floating point and the **final sign vector's objective is
recomputed exactly** — in `i128` by the existing scout code (loading the signs through the
checkpoint path with `--steps 0`), or in Python exact integers at small `M`. The recorded `S` is
exact regardless of anything the float optimiser did; float error can only make the search
worse, never the record wrong.

### 3.3 What this is and is not

It is **a different adversarial family**: a different local optimum of the same objective.
Gauss–Seidel greedy from all-`+1` and damped-Jacobi from all-`+1` do not converge to the same
`σ`. So it is **not** a drop-in replacement for the `M = 2…32` series already on record, and it
must not be reported as one. The series is re-run under the new family (cheap: minutes at
`M ≤ 16`, an hour at `M = 32`) and reported as a **second series**, with the greedy series
kept intact. The interesting comparisons are then explicit: does the new family reach higher
`|S|` (a stronger adversary), and does the `M`-trend of `Z_max/Z₀` differ between families?

If the new family reaches *lower* `|S|` than the greedy at `M ≤ 32`, it is a weaker adversary
and its role collapses to "initialiser for the exact greedy polish" — which may still be the
thing that makes `M = 64` reachable, if the polish from a good start needs few sweeps. **That
polish sweep count is the residual risk** and is measured at `M = 8, 16, 32` before anything is
claimed about `M = 64`.

## 4. Validation, all fixed before implementation

1. **Arithmetic control.** At `M = 8`, for a random `σ`: the FFT gradient's `δ_j` must equal the
   exact `−2·contrib(j)` (already computed in `i128` by the scout) scaled by the §2 constant, for
   *every* `j`, to `≲ 10⁻¹²` relative. This checks the adjoint, the chain rule, and the phase
   convention in one shot.
2. **Negative control, demonstrated to fail.** Drop the adjoint term (keep only `|j|² B_j`) and
   show control 1 fails; use the wrong sign convention for `u_{−j}` and show it fails. A control
   that cannot fail is not a control (LL-19).
3. **Optimiser quality.** `|S_new| / |S_greedy|` at `M = 8, 16, 32`, and the number of exact
   greedy polish sweeps the new optimum needs (target: single digits). Reported whatever they are.
4. **Cost.** Wall time per gradient at `M = 8, 16, 32`, checked against the `O(N log N)` model
   *before* extrapolating to 64 (LL-22, LL-27: a clock, not a model).
5. **Registration.** Only after 1–4: register protocol S-5 (the new family's series and its
   `M = 64` point) with factor-by-factor predictions per LL-24 and the standing warning that this
   family has reversed every three-point trend so far.

## 5. What it would change

If (A) converges in `O(100)` iterations, `M = 64`'s alignment is **~1–3 h** on this workstation
and the transient ~1 h — a local afternoon, where this morning it was 80 days of rented CPU.
`M = 128` (`512³`, ~45 GB) becomes a VM question rather than an impossibility. None of that is
claimed; §4 decides it.

## 6. Risks, stated plainly

- The damped Jacobi may need far more iterations than hoped on a dense coupling; measured first.
- Rounding/polish may reintroduce the sweep wall; measured first.
- The adjoint is the one piece of new numerics; it has an exact integer oracle to be checked
  against at `M = 8`, and it is not trusted before that check passes and its negative control
  fails.
- The new family is a new family. Comparability with S-2…S-4 is by explicit second series, not
  by substitution.
