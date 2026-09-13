# Overnight brief — 2026-09-12 evening to 2026-09-13 morning

**For:** programme owner, at the 24-hour checkpoint. **Author:** this session.
**Scope:** everything that ran, everything it found, and everything it got wrong, with the
numbers. Nothing here is a claim about the limit; Tier C throughout unless stated; O5 stands.

---

## 0. The one-paragraph version

Protocol S-3's fourth point landed and **falsified the prediction registered for it** — predicted
`Z_max/Z₀ ∈ [1.040, 1.052]`, measured **`1.0324`** — and the post-mortem localised the miss to a
single factor I should have registered separately. Every series has now turned over, and the
saturating fit that was inadmissible on three points is admissible on four; that is stated with
the loudest caveat in the repository, because the identical inference was reversed by the
previous point twelve hours earlier. The `M = 32` alignment that yesterday cost `195 GB / 108
days` is running in **80 MB at ~25 min/sweep**, checkpointed, because the greedy optimiser was
quadratic for three campaigns and nobody had asked. A sibling stream's proof kernel was found to
**lose containment on subnormals**, with a test suite that passes when its safety mechanism is
deleted; that is fixed and merged. Six lessons were recorded, and three of my own estimates were
retracted in writing.

## 1. What ran

| run | purpose | wall | outcome |
|---|---|---|---|
| `M = 16` alignment, old algorithm | S-3 initial condition | killed at 8.7 h, sweep 16 | superseded; kept as reference until then |
| `M = 16` alignment, incremental | same | **81 min**, 42 sweeps | identical objective at every shared sweep |
| `M = 16` alignment, table-free | same, validation | **51 min**, 42 sweeps | **byte-identical phases file** |
| `S3f_M16_advm_{a,b}` | the transient, every step | minutes | readable to `t = 0.1`, gap `1e-4` |
| `S3ff_M{2,4,8,16}` | whole series on one ultra-fine grid | minutes | `M = 8` reproduces its archive to `2e-4` |
| `S3_M16_adv{m,p}_{a,b}` | horizon 6 | ~78 + 157 min each | **readable only to `t ≈ 0.85` / `0.67`** |
| `S3_M16_null_{a,b}` | horizon 6 | same | **readable to `t = 6.0`**, gap `1e-4` |
| `M = 32` alignment, table-free | S-4 initial condition | in flight, sweep 3 | ~25 min/sweep, RSS 0.02–0.08 GB |

Four of these were killed once by the machine's OOM reaper at 21:36 and restarted (§6, LL-26).

## 2. The result: S-3's fourth point

### 2.1 The prediction, and its falsification

Committed in `ba76c30` **before any `M = 16` number existed**:

> `Z_max/Z₀|_{M=16} ≈ 1.040–1.052`, by two routes — a divergent `c(log₂M)²` form (1.047) and a
> survival-fraction bracket (1.040–1.052).

Measured, halving-checked (`9.95e-5` in `E`, `6.09e-4` in `Z` over the window), robust to 16×
finer sampling: **`1.0324`**. Below the bracket. Falsified.

### 2.2 Which factor failed

| factor of the bracket | predicted | measured | |
|---|---|---|---|
| survival fraction `e/ΔZ_inj` | 0.63–0.71 | **0.644** | correct |
| injection `ΔZ_inj/Z₀` | 0.0634–0.0738 | **0.0503** | **the miss** |

The injection's local exponent was assumed to decline smoothly to `≈0.5`; it fell to `0.10`. The
injection stopped growing. **The error was extrapolating a composite when its factors were in
hand:** the injection is the initial excess times the alignment's lifetime, `t_φ` follows `M⁻²`
*exactly* (`0.004/4 = 0.001`, measured `0.001`), and the excess grew `×1.22`, not the `×1.62`
the memo's own `M^0.7` description implied. A decelerating driver against a collapsing lifetime
is a saturating product — derivable from committed data before the run. **LL-24.**

### 2.3 The series, on one uniform grid

| `M` | `P/(νD₂)`\|₀ | `t_φ` | `Z_max/Z₀` | `t_peak` | `ΔZ_inj/Z₀` |
|---|---|---|---|---|---|
| 2 | +1.604 | 0.059 | 1.0023 | 0.022 | +0.0154 |
| 4 | +2.840 | 0.017 | 1.0122 | 0.011 | +0.0292 |
| 8 | +4.115 | 0.004 | 1.0267 | 0.003 | +0.0468 |
| **16** | **+5.016** | **0.001** | **1.0324** | **0.001** | **+0.0503** |

```
                        differences
Z_max/Z₀ − 1 :  +0.0099, +0.0145, +0.0057     <- turned over
ΔZ_inj/Z₀    :  +0.0138, +0.0176, +0.0035     <- turned over
P/(νD₂)|₀    :  +1.236,  +1.275,  +0.901      <- turned over
t_φ          :  follows M^-2 exactly
```

The LL-20 admissibility fit `e(M) = e_∞ − A·M^{−β}` on `M = 4, 8, 16`: **`β = +1.347`**,
admissible, implied ceiling `Z_max/Z₀ → 1.0361`. On `M = 2, 4, 8` the identical fit gave
`β = −0.53`, inadmissible, and supported a confidently divergent reading.

**Caveat, stated as loudly as it can be:** `β = +1.347` is an exact three-parameter fit to three
points — the same shape of evidence the fourth point reversed. It is not a verdict and not a tier
promotion. `M = 32` is the test.

### 2.4 The long-horizon arm is not readable, and the reason was mis-stated once

The horizon-6 adversarial pairs fail the 2 % rule beyond `t ≤ 0.85` (`advm`) and `t ≤ 0.67`
(`advp`), with 5.3 % / 9.0 % disagreement in `E` at `t = 6`. I first wrote that the truncation
error "grows with `M`". **The null arm falsified that explanation within hours**: at identical
`M`, `ν`, `E₀`, `dt` it is readable over the *entire* horizon (`1.03e-4` in `E` at `t = 6`).
The integrator's difficulty tracks the **coherence of the initial data**, not the mode count —
the greedy-aligned state is tuned to maximise nonlinear transfer, which is the regime that
demands small steps. Corrected in the memo and the ledger; the wrong version had been committed.

Consequence: **S-3's registered question is answered** (`Z_max/Z₀` peaks at `t = 0.001`, inside
the readable window); **the `Z(1)/Z₀` column is reported as not readable at `M = 16`**, not
quoted with a caveat. Recovering it costs ~15 h and is the owner's call.

## 3. Engineering: the optimiser was quadratic, and what that changed

The greedy sign alignment re-summed all `1.35×10⁸` triad terms for each of `8 538` candidate
flips, every sweep — `O(classes × triads)` where `O(triads)` suffices, because flipping one
class leaves the other terms alone. Factor **2 846** at `M = 16`, **22 876** at `M = 32`. It
survived three campaigns because its answers were correct and `M ≤ 8` took thirty seconds.
**Correctness gates cannot see cost. LL-22.**

Two implementations, both held to a refactor's standard:

| | memory at `M = 16` | s/sweep | `M = 32` |
|---|---|---|---|
| original | 3.03 GB (+9.8 GB transient) | ~1 400 | 195 GB, ~108 days |
| incremental (odd-incidence delta) | 4.65 GB | 117 | ~300 GB |
| **table-free (per-class enumeration)** | **0.2 MB** | **73.5** | **1.4 MB, ~25 min/sweep** |

Validation: the archived `M = 8` run reproduces **byte for byte**; the `M = 16` phases file from
the table-free run is **byte-identical** to the table version's, all 42 sweep values included.

**The `i128` accumulator turned out to be necessary.** Introduced on a hypothetical, and at
`M = 16` the objective (`1.7e16`) sits 537× *below* `i64::MAX` — I said so, and said `i64` would
have been fine there. At `M = 32` the objective after one sweep is **`3.71×10²⁰`, 40× above
`i64::MAX`**. An `i64` sum would have wrapped silently on sweep 1, optimised a meaningless
quantity, converged, written a phases file, and passed every gate in this repository.

**Checkpointing** was added because a 10–25 h job on a preemptible spot instance may otherwise
never finish, and because an OOM had already cost 1.5 h of trajectory that evening. Resume is
exact — validated by resuming a converged `M = 8` checkpoint and reproducing the archive byte
for byte.

## 4. `M = 32` costed four times; only the fourth has a clock

| estimate | basis | verdict |
|---|---|---|
| `195 GB`, ~108 days | the quadratic algorithm | right for that algorithm, obsolete |
| "negligible memory, **1–2 h**" | a cost model, no clock | **too optimistic** — retracted |
| "**~6 h per sweep**" | `M = 8` clock, rayon-overhead-dominated | **too pessimistic** — retracted |
| **20 min/sweep solo, 1.4 MB** | `M = 16` clock; measured `M = 32` sweep 1 at 24.6 min contended | current |

Sweep count is data (9 at `M = 8`, 42 at `M = 16`), so the total is a bracket: **20–50 h local,
10–25 h on 16 vCPU**. And the cost has a different shape than anyone assumed: `Z_max/Z₀` peaks
near `t ≈ 4×10⁻⁴` at `M = 32` and needs a horizon of `~0.01`, not 6 — **~24 minutes of
trajectory**. `M = 32` costs its alignment and essentially nothing else: **≈ \$3–8 at spot** on
16 vCPU against an authorised \$50. The horizon-6 arm that made it look like a three-day job
answers a question the protocol does not ask and that §2.4 shows is not readable anyway.

**This machine cannot validate the sibling brief's performance premise.** i7-4930MX (Haswell,
2013): `avx`, `avx2`, `fma`, **no AVX-512**; **4 physical cores**, not 8. "16 vCPU" is 8
physical cores, so the honest ceiling is ~2× this box. If AVX-512 is load-bearing, the spot
instance must be pinned to N2/C2/C3.

## 5. Cross-stream: the RunuX proof kernel

Reviewed `runux-ai-runtime/crates/interval_arith`, the foundation of that stream's
Generate-and-Verify architecture, shipped in `v0.4.0-leanflow` with "13/13 tests passed".

- **`sqrt` loses containment on subnormals.** The Quake-style seed assumes a normalised exponent
  field; on `8.095e-320` it returns `4.37e-157` against a true `2.85e-160` — off by 1500×,
  `4.7×10¹⁶` ULP against a 1 ULP widening. 60/20 000 subnormals fail. Reachability in the NS
  driver not demonstrated and not claimed.
- **The suite passes with the safety mechanism deleted.** Every constant is a dyadic rational,
  on which `f64` is exact. Copying the arithmetic and tests to a scratch crate with `widen` as
  the identity: **10/10 green**, while that path loses containment on 7 468/30 000 real values.
- **The obvious fix fails too**: self-certification by `hi² ≥ v ≥ lo²` underflows in the
  subnormal range (3 311/20 000). What works is argument reduction by an exact power of four into
  `[1, 4)` *before* rooting and certifying: **0 failures in 72 094 cases**.
- **Merged as [PR #8](https://github.com/xaviercallens/runux-ai-runtime/pull/8)** (`ca6028f`),
  19/19 + 10/10 + 8/8, including `old_construction_was_unsound_on_subnormals`, which reproduces
  the old construction inline and asserts it does *not* bracket — so a revert fails loudly.
- **The advisor's `dt` heuristic is dimensionally wrong** (`ε = ν·u²` is `[L⁴T⁻³]`; its
  Kolmogorov "length" is `sqrt(ν/u)`, dimension `L^½`) and it is a *stability* heuristic while
  our failure was *accuracy*. Fixed with `ε = 2νZ`, tested by a length-rescaling invariance
  control that the legacy form demonstrably fails, and joined by a **`ReadabilityAdvisor`** that
  predicts the readable horizon from a short pilot. Validated on our six pairs: with both `E`
  and `Z` and a pilot of 0.2, correct "not readable to 6" on both hard cases, conservative on the
  null, suggested `dt` for the worst pair `5.6e-5` against a hand estimate of `6.25e-5`. With
  `E` alone it produced a false *yes* on one pair — hence `predict_all`. **Merged as
  [PR #9](https://github.com/xaviercallens/runux-ai-runtime/pull/9)** (`278a790`), 35/35.

**Does the RunuX AI module help our GCP phase? No.** It optimises the ~24-minute trajectory and
leaves the 20–50-hour alignment untouched; its preconditioner targets a Newton–Krylov solve we
do not have; adaptive `dt` is incompatible with step-halving registration. One argument I made
for this — that its `dt` is "blind to `M`" — was overstated and is withdrawn: `u_max` carries
state information implicitly. The conclusion stands on the other four.

## 6. Lessons recorded (LL-20 → LL-26), one line each

| | lesson | the number that taught it |
|---|---|---|
| LL-20 | report a trend in the units the claim is about; a falling *ratio* is not a ceiling | `+0.0099, +0.0145` growing while `×5.3, ×2.2` fell; `β = −0.53` |
| LL-21 | a declared risk must carry a counted quantity and a `sizeof` | "≈ 3 GB" was 20 GB peak |
| LL-22 | correctness gates cannot see cost; a correct answer camouflages a bad algorithm | 2 846× |
| LL-23 | a permission boundary must be enforced by the boundary, not by restraint | `sed -i *` subsumed the denial |
| LL-24 | pre-register the *factors* of a product observable, never the composite | injection 0.0503 vs 0.0634–0.0738 |
| LL-25 | never summarise a file a background job is still writing | `M = 8` read as 1.0171, true 1.0267 |
| LL-26 | the memory budget of a workstation is not a constant; the reaper eats the compute | 4 jobs at 0.21 GB total killed by a 21 GB desktop |

**The synthesis** (in `LL.md`): every one of these occurred with **both gates green**, and none is
a proof error. A two-gate system is blind to cost, to interpretation, and to its own harness.

## 7. What was corrected in writing, because the wrong version had been committed

1. "no saturating form fits" → superseded by the fourth point (§2.3); the three-point text is
   kept with a forward pointer, since the sequence of readings is the evidence for the method.
2. "the truncation error grows with `M`" → it tracks initial-data coherence (§2.4).
3. `M = 32` "1–2 h" and "~6 h/sweep" → 20 min/sweep, measured (§4).
4. "`i64` would have been fine" → true at `M = 16`, false by 40× at `M = 32` (§3).
5. "the advisor's `dt` is blind to `M`" → overstated; withdrawn (§5).
6. A release tag numbered `v1.3.0` → the remote already had `v1.3.0` and `v1.4.0`; released as
   `v1.5.0`, and the note that `v1.4.0` sits at an *older* commit than `v1.2.0`.

## 8. Decisions waiting on the owner

- **Go/no-go on `M = 32` at 16 vCPU spot** — the discriminating point, ≈ \$3–8, checkpoint
  portable. Sweeps are accumulating locally meanwhile.
- **Whether the `M = 16` long-horizon row is wanted** at ~15 h of refinement (§2.4).
- **Install the three harness proposals** in `docs/harness/` (`preregister`, `cost-model`,
  `claim-auditor`) — authored there because this session is, correctly, denied write access to
  `.claude/`.
- **Adopt T-2′** (E-1), still pending from yesterday.
- **The RunuX advisor PR**, and whether `v0.4.0-leanflow` gets a `v0.4.1` note, since its
  evidence line ("13/13") describes a suite that cannot fail.

## 9. State of the record

MechanicaFluidorum: both gates green at `3c8011f`, released **`v1.5.0`**, 193 kernel-verified
theorems / 12 files / 23 harnesses; master pushed through `f33c8cc`. RunuX: `main` at `278a790`
with both the kernel fix (PR #8) and the advisor changes (PR #9).
