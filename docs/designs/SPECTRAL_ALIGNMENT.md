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

**Cost — MEASURED (2026-09-14, `gradcheck`, this workstation, solo):**

| `M` | grid | one gradient | ratio per doubling | `O(N log N)` predicts | one exact greedy sweep | ratio |
|---|---|---|---|---|---|---|
| 8 | 32³ | **0.021 s** | | | 0.5 s | 24× |
| 16 | 64³ | **0.195 s** | 9.3× | 9.6× | 11 s | 56× |
| 32 | 128³ | **1.750 s** | 9.0× | 9.3× | 12 min | **410×** |
| 64 | 256³ | ~16 s (extrapolated on the confirmed model) | | 9.1× | ~13 h | ~3 000× |

The model was written down first and the two measured doublings sit on it; the `M = 64` row is
the only extrapolation and is labelled as one. (The memo's earlier pre-measurement guess was
~5 s at `M = 32`; the measured figure is 1.75 s, since the adjoint reuses transforms rather than
costing three full RHS evaluations.)

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

**(C) How the optimiser is chosen — a fixed-budget screen, not a deep dive (added 2026-09-14
on the owner's recommendation, after karpathy/autoresearch).** (A) was implemented first and
works (§4 item 3), but "the first thing that worked" is not a design decision. The autoresearch
discipline is: *one* metric, *one* fixed budget per experiment so runs are directly comparable
whatever was changed, an evaluator the experimenter may not touch, every result logged
whatever its outcome, a written keep/discard rule, and many cheap hypotheses screened before
any of them is deepened. Adapted here:

| autoresearch | this screen |
|---|---|
| `val_bpb`, lower is better | exact `i128` `\|S\|` of the returned signs *before* polish, higher is better, as a ratio to the greedy's `\|S\|` at the same `M` |
| 5-minute training budget | `60 s` wall at `M = 16`, solo on this workstation (the baseline needs ~19 s; the greedy needed 468 s) |
| `prepare.py` is untouchable | the evaluator is the Tier-B-ported exact greedy (`--align free --phases-start`), which prints the seed's exact `\|S\|` and then polishes it; the screen never edits it |
| `results.tsv` with keep/discard/crash | `results.tsv`: id, status (`converged` / `budget` / `crash`), iterations, flips, wall, float `\|P\|`, exact `\|S\|`, ratio, polish sweeps, polished `\|S\|`, decision |
| keep iff improved, else `git reset` | `keep` iff converged within budget **and** exact `\|S\|` strictly above the baseline row's; `tie` iff identical (then fewer iterations wins); else `discard` — written here before the first run |
| ~100 experiments overnight, one change each | ten one-change hypotheses off the baseline, then only the `keep`/`tie` rows advance to a `30 min` budget at `M = 32`, and only that stage's winner to `M = 64` |

**How the design was fixed (2026-09-14, before any screen row ran).** A first list of ten was
written by the main session, then refined by three independent proposers (Sonnet; lenses:
optimisation theory, cost at `M = 64`, controls/experimental design), each given the same
facts and no repository access, and a judge (Opus) given their three outputs plus seven binding
implementation facts the main session verified against the code. That verification step
mattered: it found that **`--rank delta` is a known null** (for every single flip `|δ_j| ≪ |P|`,
so gain = `|δ_j|` and the ranking is identical — two proposers had predicted an effect), that
**annealing does not remove halving retries** (one proposer's cost argument assumed it did),
and **a real bug**: tabu filtered improvers *before* the convergence test, so a tabu run could
report `converged` while improving flips existed. Fixed (tabu now filters candidates only; if
all improvers rest, tabu is ignored that iteration), and a second stop-reason bug fixed with it
(the float-floor stop reported `iterations = max_iter`; it is now its own status, LL-18).

**Goal.** Choose the single optimiser configuration run at `M = 32` and then `M = 64`. At
`M = 64` the deciding quantity is **cost** — objective evaluations in the search (gradients +
objective calls, failed retries included) plus exact polish sweeps (~13 h each there).
**Quality is a gate, not the objective**: exact `|S|` *after* polish may not fall below `B0`'s
by more than `ε = 10⁻⁵`; beyond `ε` it breaks cost ties but never buys cost. `B0` wins by default.

**The ten rows** (one change each off `B0`; roles: candidate / control / variance):

| id | flags | role | falsifiable prediction (vs C1: `Q0`, `E0`, `F0`) |
|---|---|---|---|
| H1 | `--rank delta` | control | byte-identical to C1 (signs, `Q`, iterations, evaluations, trace); else the screen is void |
| H2 | `--rho 0.02` | candidate | tie; iterations 72–85; `C ∈ [1.0, 1.15]·E0` |
| H3 | `--rho-max 0.15` | candidate | tie or better; failures ≤ 2; `C ≤ 1.0·E0` (falsified if `> 1.1·E0` or failures `> 3`) |
| H4 | `--rho-grow 1.1` | candidate | tie; failures ≤ 3; `C ∈ [0.85, 1.05]·E0` |
| H5 | `--rho-max 1.0` | control | must degrade (failures ≥ 8 and `C ≥ 1.1·E0`, or worse); if not, the damping premise is falsified and H3/H4 become INCONCLUSIVE |
| H6 | `--tabu 3` | candidate | tie or better; failures ≤ 2; iterations 55–75; `C ≤ 0.95·E0` |
| H7 | `--init random:1` | variance | tie or worse; `C ≥ E0`; with H8 and all-`+1`, three starts |
| H8 | `--init random:2` | variance | as H7; if `|Q_H7 − Q_H8| > ε·Q0`, every "better" is downgraded to "tie" |
| H9 | `--init lift:<M=8 optimum>` | candidate | two-sided: good prior 20–50 iterations and `C ≤ 0.7·E0` (M=8 evaluations charged ÷8), bad prior > 71 iterations |
| H10 | `--anneal-tau 1e-3 --anneal-decay 0.9` | candidate | tie or better, the one row with a real chance of `> +ε`; `C ∈ [0.95, 1.3]·E0` |

**Controls that void the screen**: C1 (B0 at `M = 16` reproduces `Q0 = 17 175 910 896 716 672`, 0
polish flips, 71 iterations); C2 (B0 re-run after the batch, byte-identical to C1); C3 (`M = 8`
evaluator known value `822 566 075 728`, signs identical to the greedy); C4 (C1 signs with 40
flipped: must score below `Q0`, need polish flips, never be labelled KEEP); C5 (float `|P|` /
exact `|S|` constant to `10⁻⁹` on every row); C6 (the criterion code labels a synthetic table
correctly — **demonstrated able to fail**: a mutant using `≥` at the `ε` edge mislabels 2 rows);
C7 (1-min load logged per row; wall is a cross-check only, never a decision).

**Criterion (mechanical, `screen.py` `label()`)**: status `crash` / `invalid` (C5) /
`false-converged` (converged but polish flips `> 0`) / `budget` / `thrashing` (failures `> 3·max(F0,1)`
or `> 50 %` of evaluations) / `converged`. Quality on post-polish integers: better iff
`10⁵(Q−Q0) > Q0`, worse iff `10⁵(Q0−Q) > Q0`, else tie. Cost: cheaper iff `C ≤ 0.9·E0` and polish
sweeps `≤ P0`; costlier iff `C > 1.1·E0` or sweeps `> P0`. Labels: INCONCLUSIVE (status not
converged) · DISCARD (worse, or tie and costlier) · KEEP (tie/better and cheaper, or better and
cost-tie) · TIE (the rest). **Advancement**: at most three candidates to `M = 32` (top two KEEP by
`C/E0`, then `Q`; third slot their combination if they change different flags), each 30 min, with
a B0 `M = 32` reference; the criterion is re-applied there, and exactly one row goes to `M = 64`
subject to a transfer check (`C/E0` at 32 ≤ `C/E0` at 16 + 0.15); if none, B0 goes.

Rejected, with reasons, in the judge's record: `ρ₀ = 0.5` (inert after 9 iterations), growth 2.0
(same mechanism as the H5 control), anneal `10⁻⁴/0.5` (τ < 10⁻⁸ before the first failure at
iteration 34: predicted null), three or more seeds (slot budget; random starts cannot advance),
pre-polish quality (favours B0), iterations or wall as the cost metric (hide retries / depend on load).

**Result of the `M = 16` screen (2026-09-14, run as registered; `exploration/scout_runs/screen_M16/`).**
No void: C1, C2 (byte-identical re-run), C3, C4 (corrupted signs: 40 polish flips, DISCARD), C5
and C6 pass; H1 identity PASS. Reference `Q0 = 17 175 910 896 716 672`, `E0 = 163` evaluations
(71 gradients + 92 objective calls), 21 failed steps, 1 polish sweep.

| row | C/E0 | failed steps | exact `Q` (post-polish) | `Q/Q0 − 1` | signs ≠ greedy | label (as registered) |
|---|---|---|---|---|---|---|
| H1 rank delta | 1.000 | 21 | = `Q0` | 0 | 40 | control PASS |
| H2 `ρ₀ 0.02` | 1.031 | 24 | `17 176 873 794 444 224` | +5.6×10⁻⁵ | **0** | TIE |
| H3 cap 0.15 | 0.988 | 17 | `17 176 873 794 444 224` | +5.6×10⁻⁵ | **0** | TIE |
| H4 growth 1.1 | 0.982 | 18 | `17 176 873 794 444 224` | +5.6×10⁻⁵ | **0** | TIE |
| H5 cap 1.0 | 1.006 | 22 | = `Q0` | 0 | 40 | control NEITHER |
| H6 tabu 3 | 0.908 | **0** | = `Q0` | 0 | 40 | TIE |
| H7 random:1 | 1.521 | 34 | `15 099 681 966 297 824` | −1.2×10⁻¹ | | variance |
| H8 random:2 | 0.834 | 24 | `10 513 309 742 220 224` | −3.9×10⁻¹ | | variance |
| H9 lift M=8 | 1.142 | 19 | `17 176 872 607 246 832` | +5.6×10⁻⁵ | | DISCARD (costlier) |
| H10 anneal | 1.000 | 21 | = `Q0` | 0 | 40 | TIE (null: identical to B0) |

What it says, plainly:
1. **Three one-flag changes land exactly on the greedy's optimum** — H2, H3, H4 return the
   greedy's sign vector bit for bit at `M = 16`, at B0's cost. B0's 40-sign miss was a property of
   its schedule, not of Jacobi.
2. **The registered criterion misfired on them.** `+5.6×10⁻⁵` exceeds `ε`, but the seed-spread
   rule ("if `|Q_H7 − Q_H8| > ε·Q0`, downgrade every better to tie") fired, because the random
   starts are *catastrophically* worse (−12 %, −39 %) — a rugged landscape, not the near-degenerate
   noise the rule was written for. Under the registered rule H2–H4 are TIE and the advancing set
   is **H6, H4, H3** (the TIE rows by `C/E0`). Had the rule not misfired, H2–H4 would be KEEP and
   the set would be H4, H3 and their combination. The registered set is run as registered; the
   combination **H3+H4 is added as an explicitly post-hoc row, not eligible for `M = 64`** under
   this screen. Lesson recorded: a downgrade rule must test the premise it encodes (spread of
   *converged near-optima*), not a proxy that a different phenomenon can trip.
3. **H5, the damping negative control, was vacuous — and the reason is a finding about B0.** The
   cap never binds: in 59 of B0's 70 accepted steps `⌈ρn⌉` exceeded the number of improvers, so
   *every* improver flipped. B0 is effectively "flip all improvers, halve on failure"; the only
   damping that acts is the halving. The judge's control was built on the documented mechanism,
   not the operative one — LL-19 again: a perturbation must be demonstrated to bite. H3's cap 0.15
   did bind in early iterations, which is plausibly what moved it onto the greedy's basin.
4. **Random starts are a bad idea on this objective**, and all-`+1` is not an arbitrary start —
   worth knowing independently of the optimiser choice.
5. **H6 (tabu) eliminates failed steps entirely** (21 → 0) at the same `Q`, missing "cheaper" by
   1.3 evaluations (148 vs 146.7).
6. **C7 was an unusable instrument**: the 1-min load average at the start of a row in a
   sequential screen measures the *previous* row's 8-core polish (load 9–11 on every row, no
   foreign process). Wall times are void for decisions anyway (C2 drifted 20 %); evaluation
   counts are deterministic and carry the result.

Where this departs from autoresearch, deliberately: the loop does
**not** run unattended overnight and does not mutate its own code — the hypotheses are fixed
in advance because the thing being protected is the comparability of the rows, and the
scientific claims downstream (S-5) stay under the pre-registration rule (LL-24), which the
screen does not replace. The screen chooses an *optimiser*; it does not choose a *result*.

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

**Status 2026-09-14 — items 1, 2, 4 done; item 3 done at `M = 8, 16` (`M = 32` running); 5
pending.** The gradient is implemented
(`grad_p_fft`, `gradcheck` in the scout). Control 1: at `M = 8` on the random pattern, the ratio
`dP/dσ_j ÷ dS/dσ_j` is **one constant over all 1 054 classes to `8.4×10⁻¹³` relative**, mean
`8.858612370757×10⁻⁸` — the §2 constant to every digit. Control 2: dropping the adjoint makes
the ratio wildly non-constant (all 1 054 classes off, spread `±5×10⁻⁵`) — **fails as required**.
The reflection control as first designed was **vacuous on the sign family** (`u_{−k} = −u_k`, so
the reflection is a sign flip that every adjoint term contains twice) — caught, and replaced by a
slot-wise Euler check `T1/P, T2/P, T3/P` with `h = u` on a genuinely complex field (`--ic
null`): all three read `1` to `8×10⁻¹⁵` with the full gradient; dropping the reflection gives
`T2/P = −0.84`, `T3/P = −8.3`; dropping the adjoint gives `T2 = T3 = 0`. Item 4: measured, table
in §3.1. Reproduction: `exploration/alignment_spectral/README.md`.

**Item 3, measured (`--align jacobi`, `ρ₀ = 0.1`, from all-`+1`, then `--align free
--phases-start` for the exact polish):**

| `M` | Jacobi iterations | wall | `|P|` Jacobi | `|P|` greedy | `|S|` exact, Jacobi | `|S|` greedy | ratio | signs differing | polish sweeps |
|---|---|---|---|---|---|---|---|---|---|
| 8 | 16 | 0.4 s | `7.286794014×10⁴` | `7.286794014×10⁴` | `822 566 075 728` | `822 566 075 728` | **1** | 0 / 1 054 | 1 (0 flips) |
| 16 | 71 | 18.9 s | `1.474065676×10⁶` | `1.474148314×10⁶` | `17 175 910 896 716 672` | `17 176 873 794 444 224` | **0.999 944** | 40 / 8 538 | 1 (0 flips) |
| 32 | 210 | 528 s | `3.147221027×10⁷` | `3.147224672×10⁷` | `455 471 158 672 505 926 960` | `455 471 686 189 347 441 312` | **0.999 998 84** | 49 / 68 532 | 1 (0 flips, 827 s) |

Read plainly: at `M = 8` the damped Jacobi lands on **the same sign vector** as the
Gauss–Seidel greedy — not merely the same objective — so §3.3's warning that the two need not
agree was, at `M = 8`, too cautious. At `M = 16` they differ in 40 of 8 538 signs and the Jacobi
optimum is **0.0056 % weaker**; it is nevertheless already a strict local optimum of the exact
objective (the polish sweep finds no improving flip), so the residual risk named in §3.3 — that
the polish reintroduces the sweep wall — **did not materialise at `M ≤ 16`**: the polish is one
verification sweep. The exact `|S|` of the Jacobi seed and the float `|P|` agree in ratio to the
greedy to all six printed digits (`0.999944` both ways), which is the §2 constant doing its job
end-to-end. Cost at `M = 16`: 18.9 s where the greedy took 8 min (25×). At `M = 32` the
Jacobi converged in **210 iterations, 528 s (8.8 min)**, where the greedy took ~22 h under
contention (§4.3.6): **~150×**, and its float `|P|` is within `1.2×10⁻⁶` of the greedy's. The
iteration count grows sub-geometrically (`16 → 71 → 210`: ×4.4 then ×3.0), so `M = 64` at
`~500–600` iterations × ~20 s ≈ **3 h** on this workstation is the current extrapolation —
still an extrapolation, labelled as one, and not a claim until the `M = 64` clock is read
(LL-22). The exact polish at `M = 32` then ran one verification sweep (827 s) and found **no
improving flip**: the Jacobi optimum is a strict local optimum of the exact objective at every
`M` measured, so the polish-wall risk of §3.3 has not materialised at `M = 8, 16, 32`. At
`M = 64` a single verification sweep is ~13 h (extrapolated), which is why the screen charges
polish sweeps as cost.
Artifacts: `exploration/scout_runs/S5_M{8,16}_phases_jacobi.txt`, `S5_M16_align_jacobi.log`,
`S5_M16_polish.log`.

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
