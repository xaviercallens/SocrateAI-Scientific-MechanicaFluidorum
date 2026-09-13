# Design memo — the Core-Tail computer-assisted proof: objects defined exactly, and one correction

**Status: acknowledgement of the 2026-09-13 adjudication, with the pivot's objects PROPOSED in
exact form for owner adoption (rule E-1) and one epistemic correction that must be adopted
before any Lean is written against the "Tail".** **Author:** Fable. Nothing here is a bound; O5
stands until a certificate and a theorem together say otherwise.

---

## 1. Acknowledgements, in one line each

- **D-1 adopted**: `disparity`, `productionFiber`, `enstrophy_production_decomposition` (Tier A)
  and the trajectory ratio `P/(νD)` are the core observables.
- **D-2 authorized**: Tier C scouts, floating point, long horizons, calibrated against the exact
  eight rational steps (`exploration/calibration/exact_steps_M2.json`).
- **D-3 confirmed**: L-9, L-10 adopted with the F-NAME caveat.
- **D-4 executed**: worktree `../MechanicaFluidorum-concurrent` on `concurrent-stream`; policy
  in `CLAUDE.md`.
- **Hardware**: local i7, 32 GB, CPU only. **Strategy confirmed**: Tier C by pseudo-spectral
  FFT (`rustfft` 6.4, reachable from this host) with exact 2/3 de-aliasing (`N ≥ 3M+1`, so every
  aliased product lands outside the retained band), `rayon` for the contiguous-axis transforms
  and the physical-space products, `M ≤ 32`; Tier B certification by direct `O(M⁶)` convolution
  in interval arithmetic with directed rounding, `M_core ≤ 8`, `rayon` over the outer wavevector
  loop. No FFT inside an interval computation — wrapping bounds through a transform are useless.

## 1bis. Integration note on LeanFlow, read at source before any leverage

`SocrateAI-Numeric-DualScale-Solver/crates/leanflow-core/src/lib.rs` (read 2026-09-13; the tree is
outside this session's shell, so it can be read but not run here) implements the dual scale as
**smooth operators**: a bi-Helmholtz effective wavenumber `k_eff = k/(1+α′k²)²` and a
hyperviscous dissipation rate `ν k² · max(1, α k²)`. **Neither is the sharp projection** that the
owner's Q1 adjudication of 2026-09-10 fixed as the theory, and its central observable is the
frustration index `𝒟(M)`, refuted here as a random-phase artifact. Consequences for D-2:

- the scout **cannot** import LeanFlow's operators without silently re-introducing the
  discarded regularization; what is leveraged is its *engineering* (Rust, spectral state
  layout), not its dynamics;
- the scout therefore implements the adopted system directly — sharp ball truncation, the
  Task 2.1 operator `B`, viscous damping `ν|k|²` — with its discretisation matched line by line
  to `tests/tier_b_fourier_enstrophy.py`, so that the exact calibration is a real test;
- any future merge of LeanFlow's operators into a Tier B certificate needs an owner decision,
  since it would change the object being certified.

## 2. The correction: what the "Tail" theorem can and cannot say

The directive asks Opus to "formally prove the super-exponential energy decay of the tail
`|k| > M_core`, assuming the core `|k| ≤ M_core` is bounded." **As phrased this is not a theorem
for 3-D.** A bounded core does not make the tail decay: tail modes are *forced* by the core
through the disparate triads (`|r|² − |q|²` large — the very factor isolated as the
vulnerability), and by tail–tail interactions. That forcing is the cascade. Nothing about the
core's boundedness alone controls it.

**What is provable is a *self-consistent* tail bound**, the standard structure of rigorous
numerics for dissipative PDEs (Zgliczyński–Mischaikow for Kuramoto–Sivashinsky; the
self-consistent a-priori-bounds method): *assume* an explicit tail envelope, show that the linear
dissipation `ν|k|²` dominates the nonlinear forcing of every tail mode by the boxed core plus
the enveloped tail, and conclude the envelope is forward-invariant. Three consequences the
programme must accept:

1. **The rate is exponential in `|k|` (Gevrey class), not super-exponential.** Gaussian-in-`k`
   decay is a property of the *linear* semigroup `e^{−ν|k|²t}` alone; the nonlinear forcing of
   the tail supports, and typically only supports, an envelope `|u_k| ≤ C e^{−a|k|}` (or a
   polynomial one). The word "super-exponential" should be retired from the target statement.
2. **The constants come from the certificate.** Whether `ν|k|²` dominates the forcing at
   `|k| > M_core` depends quantitatively on the core box and the envelope parameters `(C, a)`;
   the Rust certificate must supply them, and the Lean theorem is *conditional* on them.
3. **The virtue is exactly the one wanted against O5.** The tail inequality is stated for all
   `|k| > M_core` with no reference to the outer truncation `M`; a closed envelope is therefore
   **uniform in `M`**. That is the first object in this programme whose shape could beat O5 —
   for the *specific* solutions the certificate covers, which is what computer-assisted proofs
   deliver and all they deliver.

## 3. The objects, proposed exactly

Fix `M_core ∈ ℕ`. For a Galerkin state `u` on `ball M` with `M > M_core`:

- **Core / tail split.** `core(u) := u restricted to k_sq k ≤ M_core²`;
  `tail(u) := u restricted to k_sq k > M_core²`.
- **Core box.** A set `𝒞 ⊆ (core states)` given by componentwise bounds `|u_k^i| ≤ β_k^i` for
  `k_sq k ≤ M_core²` — the object the interval evaluator certifies inward-bounded.
- **Tail envelope.** `ℰ(C, a) := { tail : |u_k^i| ≤ C·e^{−a·√(k_sq k)} for all k_sq k > M_core² }`,
  with `C, a > 0` rational (for the certificate) — exponential in `|k|`, per §2.
- **Per-mode balance (Tier A target T-1, unconditional).** For every mode `k` and every state,
  `d/dt ‖u_k‖² = −2ν k_sq k ‖u_k‖² + 2 Re⟨u_k, B(u,u)_k⟩`. Algebraic, in the same rate sense as
  the balance laws of `FourierDynamicsZ3` §10; provable now.
- **Forcing bound (Tier A target T-2, unconditional).** `‖B(u,u)_k‖ ≤ Σ_{p+q=k} |q|·‖u_p‖·‖u_q‖`
  — the convolution bound, from `|(q·u_p)| ≤ |q|‖u_p‖`, the triangle inequality, and the Leray
  projector being a contraction. Pure algebra plus norms; provable now.
- **Self-consistency inequality (the theorem shape, conditional).** For all `k` with
  `k_sq k > M_core²`: if `core(u) ∈ 𝒞` and `tail(u) ∈ ℰ(C, a)`, then
  `ν k_sq k · C e^{−a|k|} > Σ_{p+q=k} |q| · bound(u_p) · bound(u_q)`, where `bound` is `β` on
  the core and the envelope on the tail. This is what makes `ℰ` forward-invariant on the faces,
  and it is **the statement to formalise, with `(M_core, β, C, a)` as parameters** and the
  inequality's truth supplied by the certificate.

**What is NOT proposed:** any claim that a box `𝒞` exists, any value of `(C, a)`, or any
statement about the limit. Those are outputs of the scouts and the certificate, in that order.

## 4. What the Tier C scouts are for, and their registration

Observables along trajectories: `E`, `D`, `P`, and the adopted ratio `P/(νD)`. Questions, in
the adjudication's words: does the adversarial alignment saturate; does the energy reach a
natural ceiling. Registered readings: the ratio's long-time behaviour from the adversarial and
null initial conditions at `M ∈ {2, 4, 8, 16}`; step-halving agreement required before any
number is read; the exact eight-step calibration must be reproduced to round-off at `M = 2`
(forward Euler mode) before the RK4 long-horizon mode is trusted; and the FFT convolution must
agree with the direct convolution to round-off at `M ≤ 4` before the FFT is trusted at all.

**Scope.** Floating point, Tier C, `exploration/`. Nothing a scout shows is a claim; it is a
candidate for a certificate.

> **Calibration result (2026-09-13):** both engines reproduce the exact eight-step trajectory
> to `2.4e-16` relative for both initial conditions; FFT and direct agree to round-off at
> `M = 4`. Details: `exploration/calibration/CALIBRATION_RESULT.md`.
>
> **First scouts (λ = 0.05, `M = 2, 4`, horizon 40, sampled every `t = 2`) and what they
> forced.** Energy decays monotonically in every run (as `energy_conservation` requires), so
> "energy ceiling" is trivially `E₀`; the late-time trajectory ratio settles at a small positive
> level (`0.01–0.1`) in every run, adversarial or null. Two defects, fixed before protocol S-2:
> the sampling missed the early transient entirely, and the halving check at `M = 4`,
> `dt = 0.005` gives a **readable horizon of `t ≤ 6`** (energy and enstrophy within 2%), which
> happens to cover the whole transient. The printed dissipation was the energy one; the
> enstrophy balance is decided against `D₂ = Σ|k|⁴|u_k|²`, now also printed.
>
> **Protocol S-2, registered before its runs.** Observables: the transient enstrophy
> amplification `Z_max/Z₀` and its time, `P/(νD₂)` (`> 1` ⟺ enstrophy increasing), `E`, `Z`.
> Normalisation: `E₀ = 144` (the earlier `M = 4` value) and `ν = 0.05` at every `M`, so runs are
> comparable. Horizon `t = 6`, sampled every `t = 0.01`. Every run has a step-halving partner;
> a number is read only up to the horizon where both `E` and `Z` agree within 2%. Families:
> adversarial with both signs (the greedy search fixes only the magnitude; the negative sign
> is the production-positive one), and the random-phase null. `M = 2, 4` foreground
> (`dt = 0.001 / 0.0005`); `M = 8` (`dt = 0.0005 / 0.00025`) and `M = 16` null
> (`dt = 0.00025 / 0.000125`) in the background. The question S-2 answers: **does the
> transient enstrophy amplification of adversarial states grow with `M` at fixed energy** —
> the only scout-level quantity that bears on uniformity.

### 4.1 Protocol S-2 outcome — `M = 2, 4` (2026-09-13; data, no verdict)

All twelve runs pass the halving check over the **entire** horizon: worst relative disagreement
in `E` and `Z` at `t = 6` is `1.3e-5` (`M = 4`, adversarial, `dt = 0.001` vs `0.0005`), four
orders below the 2% threshold. Every number below is therefore read from the fine run and is
insensitive to the step. Archive: `exploration/scout_runs/S2_*.csv`; table by
`python3 exploration/scout_summary.py transient …`.

| `M` | ic | λ | `P/(νD₂)` at `t=0` | dephasing time `t_φ` (first sign change of `P`) | `Z_max/Z₀` | `t_peak` | `ΔZ_inj/Z₀` (production integrated to `t_φ`) | `Z(1)/Z₀` |
|---|---|---|---|---|---|---|---|---|
| 2 | adversarial | −0.05 | **+1.604** | 0.060 | **1.0022** | 0.020 | +0.015 | 0.627 |
| 2 | adversarial | +0.05 | −1.604 | 0.180 | 1.0000 | 0 | −0.101 | 0.621 |
| 2 | null (seed 1) | +0.05 | +0.007 | 0.010 | 1.0000 | 0 | 0.000 | 0.630 |
| 4 | adversarial | −0.05 | **+2.840** | 0.020 | **1.0122** | 0.010 | +0.025 | 0.314 |
| 4 | adversarial | +0.05 | −2.840 | 0.230 | 1.0000 | 0 | −0.244 | 0.292 |
| 4 | null (seed 1) | +0.05 | +0.192 | 0.010 | 1.0000 | 0 | 0.000 | 0.304 |

What the fine sampling shows, as data:

1. **The production-positive adversarial state starts above the enstrophy balance** (`P > νD₂`
   at `t = 0`: ratio 1.6 at `M = 2`, 2.8 at `M = 4`) **and loses it within a fraction of a
   time unit**: the production changes sign at `t_φ = 0.06` (`M = 2`) and `0.02` (`M = 4`),
   then oscillates with decaying amplitude (`M = 4`: sign changes near `t ≈ 0.02, 0.15, 0.17,
   0.29, …`, the first negative excursion reaching ratio `−2.1` at `t = 0.05`). The alignment
   the greedy search builds is a *kinematic* coincidence of triad phases; the nonlinear phase
   rotation destroys it on the time scale `t_φ ~ 1/(|u| M)`, which shrinks with `M` at fixed
   energy — and that shrinkage outruns the growth of the initial ratio, so the transient
   enstrophy gain is small: **0.2% at `M = 2`, 1.2% at `M = 4`**. It does grow with `M`; what
   S-2 at `M = 8` must show is whether the growth is the geometric `×5` seen here or saturates.
2. **The asymmetry between the two signs is large and persistent.** The production-negative
   twin (`λ = +0.05`, the same amplitudes with `P → −P` at `t = 0`) keeps its sign three to ten
   times longer (`t_φ = 0.18, 0.23`) and *removes* 10% / 24% of `Z₀` through production before
   dephasing. Time-reversal of the inviscid part maps one twin to the other; viscosity breaks
   the symmetry in the direction that spends coherence to *lower* enstrophy. This is the
   sweeping-suppression question in dynamical form and is recorded as the observable to
   quantify next, not as a mechanism.
3. **The null is neutral**: production is `< 20%` of dissipation at `t = 0` at both `M` and
   changes sign within one sample; no amplification at all.
4. **After the transient, all three initial conditions at a given `M` decay alike**
   (`Z(1)/Z₀ = 0.63 ± 0.01` at `M = 2`, `0.30 ± 0.01` at `M = 4`): by `t = 1` the memory of the
   initial phase configuration is gone from the enstrophy, and the late trajectory ratio is
   `O(0.1–1)` for all of them (§4, first scouts).

**Scope.** Tier C, `|λ| = 0.05` (the qualified weakly-nonlinear regime of amendment 7),
`ν = 0.05`, `E₀ = 144`, two values of `M`. Nothing here bears on the limit or on Hypothesis U;
O5 stands. What it supplies to the Core-Tail programme is the *shape* a certificate must cover:
a transient of duration `≲ 0.3` in which the enstrophy can exceed `Z₀` by a factor that is
small but **increasing in `M`** on the two points measured.

### 4.2 The transient resolved at every step, and the `M = 8` point (2026-09-13; data, no verdict)

**Sampling amendment, recorded before the numbers were read.** The registered interval (0.01)
is coarser than the `M = 8` dephasing time and equal to the `M = 4` peak time, so the transient
observables of §4.1 were on the sampling grid. They are re-read from short runs sampled at
**every step** (horizon 0.1, `dt = 0.0005` and `0.00025`, `exploration/scout_runs/S2f_*`),
each pair agreeing to `≤ 2e-7` in `E` and `Z` over the whole window. The long-horizon
observables of §4.1 are unaffected. The greedy alignment is deterministic, so these are the
same initial states.

| `M` | modes | `P/(νD₂)` at `t=0` | `t_φ` | `Z_max/Z₀` | `t_peak` | `ΔZ_inj/Z₀` | `Z(1)/Z₀` (from `S2_*`) |
|---|---|---|---|---|---|---|---|
| 2 | 33 | +1.604 | 0.059 | **1.0023** | 0.022 | +0.016 | 0.627 |
| 4 | 257 | +2.840 | 0.017 | **1.0122** | 0.011 | +0.029 | 0.314 |
| 8 | 2109 | +4.115 | 0.004 | **1.0265** | 0.003 | +0.046 | 0.019 |

Read as data, on three points at fixed `E₀`, `ν`:

- the initial excess of production over enstrophy dissipation grows with `M`
  (`1.6 → 2.8 → 4.1`, ratios `1.77`, `1.45` per doubling — sub-linear, roughly `M^{0.7}`);
- the lifetime of the alignment collapses with `M` (`0.059 → 0.017 → 0.004`, factors `3.5`,
  `4.2` per doubling — close to `M^{−2}`, i.e. faster than the `1/(|u|M)` guess of §4.1;
  at fixed energy the aligned modes' amplitudes fall as the mode count grows, and the phase
  rotation rate is set by the *fastest* triads, `~ M²·|u_k|`);
- the transient gain `Z_max/Z₀ − 1` grows with `M` (`0.0023 → 0.0122 → 0.0265`) but the
  growth **decelerates**: `×5.3` for `2 → 4`, `×2.2` for `4 → 8`; the injected fraction
  `ΔZ_inj/Z₀` grows `×1.8`, `×1.6`. On these three points the sequence is consistent with
  saturation and also with a slow power law; a fourth point (`M = 16`, adversarial, which
  needs the greedy alignment on ~17 000 modes) would separate them and is **not** part of
  S-2 as registered;
- once the alignment is spent, the enstrophy at `M = 8` collapses (`Z(1)/Z₀ = 0.019`): with
  `E₀` fixed and `Z₀` sixteen times larger than at `M = 2`, dissipation `2νD₂` dominates
  immediately.

**The three initial conditions at `M = 8`, long horizon** (`S2_M8_*`, halving readable over the
whole horizon, worst disagreement `2.8e-4`). Only one of the three ever *injects* enstrophy:

| `M = 8` initial condition | `P/(νD₂)` at `t=0` | `t_φ` | `ΔZ_inj/Z₀` | `Z(1)/Z₀` |
|---|---|---|---|---|
| adversarial, production-positive | **+4.115** | 0.004 | **+0.046** | 0.019 |
| adversarial, production-negative twin | −4.115 | 0.030 | −0.182 | 0.020 |
| random-phase null (seed 1) | −0.123 | 0.170 | −0.109 | 0.019 |

Across every `M` measured, the **only** run whose production adds enstrophy is the
production-positive adversarial one, and it adds `1.6 %`, `2.9 %`, `4.6 %` of `Z₀` at
`M = 2, 4, 8`. The null at `M = 8` happens to draw a seed whose production is negative and
long-lived, removing `11 %` — which is a reminder that a single seed is not a null *model*:
the null's sign and magnitude vary with the draw, and only its inability to *inject* has been
consistent. Multi-seed nulls are not part of S-2 as registered.

**What this does and does not say.** It says that on the greedy-aligned family, at fixed
energy in the weakly-nonlinear regime, the dynamics converts an initial production excess that
grows with `M` into an enstrophy excursion that grows more slowly than the excess, because the
alignment's lifetime shrinks faster than the excess grows — the *dynamical* form of the
sweeping-suppression question, measured rather than asserted. It says nothing about states
that the dynamics itself builds (the exact contact of `DYNAMIC_ACCESS.md` §3 showed it does
build alignment), nothing about strong nonlinearity, nothing about the limit. O5 stands.

### 4.3 Protocol S-3, registered here before any of its runs

S-2 as registered stops at `M = 8` for the adversarial family and includes `M = 16` for the
null only. The series it produced — `Z_max/Z₀ = 1.0023, 1.0122, 1.0265` with increments `×5.3`
then `×2.2` — is exactly three points, which cannot separate saturation from a slow power law.
**S-3 adds the fourth point, and nothing else.**

- **The question, fixed in advance:** does the transient enstrophy amplification of the
  greedy-aligned state continue to grow from `M = 8` to `M = 16`, and does the increment
  continue to fall? A third consecutive fall (`×5.3, ×2.2, ×<2.2`) is consistent with
  saturation; an increment that stops falling is consistent with a power law. **Neither
  outcome is a verdict** — verdicts are the owner's, and nothing here bears on the limit.
- **Runs:** adversarial `λ = −0.05` and its production-negative twin `λ = +0.05`, plus the
  `M = 16` null that S-2 already registered. Same normalisation as S-2 (`E₀ = 144`,
  `ν = 0.05`), horizon 6, step `dt = 0.00025` with a `0.000125` halving partner; plus
  every-step runs to `t = 0.1` for the transient observables, as amended in §4.2.
- **Reading rule, unchanged:** no number is read past the horizon where both `E` and `Z` agree
  within 2 % between the halving pair.
- **Declared risk:** the greedy alignment at `M = 16` materialises a triad table of order `10⁸`
  entries (≈ 3 GB) and the machine has ≈ 10 GB free. If it does not fit, S-3's adversarial arm
  is **reported as not run**, not silently replaced by a smaller family.

#### 4.3.1 The declared risk was real, and was removed before the runs (2026-09-13)

The triad table was counted exactly rather than estimated, by FFT autocorrelation of the ball
indicator: `426` entries at `M = 2`, `30 360` at `M = 4`, `2.08 × 10⁶` at `M = 8`,
**`1.367 × 10⁸` at `M = 16`** (counts before the `g ≠ 0` filter, which removes a few per cent —
the scout reports `1.997 × 10⁶` at `M = 8` after it).

The order of magnitude in the declared risk was right and the **byte count was not**. As the
scout was written, one entry cost 80 bytes (`(K, K, K, i64)`, three 24-byte wavevectors), so the
table alone was **10.2 GB**, and the class list was built by `flat_map` over the whole table
*before* its `dedup` — a further **9.8 GB** transient standing at the same time. Peak ≈ 20 GB
against ≈ 14 GB available: **S-3's adversarial arm would have died in the allocator**, and the
`≈ 3 GB` figure would have made that look like a surprise rather than an arithmetic slip.

The fix is the one §4 of the compute brief prescribed for `M = 32`, applied a level earlier:
the wavevector form of the table is never built. Pass 1 discovers which rep classes occur and
counts the entries; pass 2 writes the table already in index form into a vector reserved to
that exact count. One entry is then 24 bytes — **3.06 GB at `M = 16`**, a 6.6× reduction, and
no transient. The objective is also accumulated in `i128`: a single `g` reaches `~6 × 10¹¹` at
`M = 16` and there are `1.4 × 10⁸` of them, so an `i64` accumulator could silently wrap on a
badly-cancelling sign pattern.

**This is a refactor, and it is held to a refactor's standard.** The class set, its sorted
order and the greedy sweep order are untouched, so the alignment returned is the same one. The
check is not an argument: re-running the archived `M = 8` fine adversarial run reproduces
`exploration/scout_runs/S2f_M8_advm_a.csv` **byte for byte**, alignment included (9 sweeps,
`best = 822 566 075 728`, 30 s on 8 cores).

**Cost of S-3, from measurement plus one clearly-labelled extrapolation.** The `M = 8`
alignment is 9 sweeps over `1 054` classes and `2.0 × 10⁶` triads in 30 s. At `M = 16` the
table is 68× larger and there are 8.1× more classes to flip, so a sweep costs ≈ 555× more:
**≈ 30 min per sweep, and ≈ 4–5 h if it again takes nine sweeps** — an extrapolation, not a
measurement, and the sweep-by-sweep progress is now printed to stderr so it can be watched
rather than guessed. **The compute brief's §3 estimate of "≈ 4 h per initial condition, an
afternoon" counted the trajectories only and omitted this entirely; S-3 is an overnight job.**
Because the alignment is deterministic and all six adversarial runs need the same phases, the
scout now takes `--phases-out` / `--phases-in`, so it is paid once rather than six times.

#### 4.3.2 The extrapolation above was optimistic twice over, and the cause was algorithmic

Recorded because the correction runs in both directions, which is the whole reason to log an
extrapolation as an extrapolation. Measured: the old algorithm ran **23 min per sweep** at
`M = 16` (close to the predicted 30) but needed **19+ sweeps, not 9** — `M = 16`'s landscape
admits far more small improvements than `M = 8`'s, and the sweep count is data, not a constant.
True cost of the run as launched: ≈ 7.5 h, not 4–5.

That number is now irrelevant, because the cost model itself was wrong. **The greedy re-summed
all `1.35 × 10⁸` triad terms for each of the `8 538` candidate flips, every sweep** —
`O(classes × triads)`, unquestioned across three campaigns because the answers were correct and
`M ≤ 8` finished in thirty seconds. But flipping one class's sign leaves the other terms alone.
Maintain the signed total and update it,

> `S  ↦  S − 2 · (sum of the terms that flip)`,

where the terms that flip are exactly those whose triad contains that class an **odd** number of
times — a class occurring twice multiplies its term by `(−1)² = 1` and does not move. A sweep
becomes `O(3 × triads)`: a factor `classes/3`, **2846** at `M = 16` and `22 876` at `M = 32`.

**Held to a refactor's standard, not argued.** Same integer arithmetic, same visit order, same
strict-improvement test, therefore the same alignment — and checked as such: the archived `M = 8`
run reproduces digit for digit on all nine sweep values and byte for byte in its CSV, and at
`M = 16` the incremental run reproduces the pre-change run's sweep-by-sweep objective exactly,
the slow run having been deliberately kept alive alongside the fast one for that comparison.
Measured gain **~12× under contention** — well short of the operation-count ratio, because random
gathers into a 3 GB table are much less efficient per byte than the sequential scan they replace.
Reported as measured, per LL-18; the 2846× is the arithmetic, not the clock.

**The `i128` accumulator was necessary, not defensive — confirmed by measurement at `M = 32`.**
When it was introduced the justification was hypothetical ("a badly-cancelling sign pattern
*could* wrap"), and at `M = 16` the converged objective is `1.718×10¹⁶`, a comfortable `537×`
*below* `i64::MAX`, so an `i64` accumulator would in fact have survived there. At `M = 32` the
objective after a single sweep is

> `371 214 251 287 064 965 664 ≈ 3.71×10²⁰`, which is **40× ABOVE `i64::MAX`**.

An `i64` sum would have wrapped silently on the first sweep and the entire `M = 32` alignment
would have optimised a meaningless wrapped quantity — while still converging, still producing a
phases file, and still passing every gate in this repository. Recorded as a case where a cheap
defensive choice, taken on an argument rather than a number, turned out to be load-bearing two
sizes later; and as a reminder that the failure it prevented would have been **silent**.

**Corrected S-3 cost: ≈ 40 min alignment + ≈ 6 h trajectories.** And a retraction of §4 of the
compute brief: the `M = 32` adversarial arm was costed at `195 GB` and `≈ 108 days` and declared
to need "a new alignment algorithm before a machine". It does — this is that algorithm, and with
per-class enumeration off the lattice replacing the stored table, `M = 32` needs negligible
memory and an estimated 1–2 h. The brief's conclusion that a VM does not help stands; its
reasoning is withdrawn. The obstacle was never compute.

> **✅ MEASURED, and both earlier estimates were wrong — see §4.3.5. The figure below is
> superseded.** The `M = 16` table-free run converged at sweep 42 in `3 087 s` (`73.5 s`/sweep)
> and is **byte-identical to the table version's phases file**, all 42 sweep values included.
>
> **⚠ The "1–2 h" in the paragraph above is an UNMEASURED extrapolation and is flagged as such
> pending the `M = 16` measurement now running.** The memory claim is solid — the table-free
> algorithm is built (`--align free`), holds `O((2M+1)³)` bytes, and is **bit-identical to the
> archived `M = 8` run**, all nine sweep values and the output CSV. The *time* claim is not: the
> only cost measurement in hand is at `M = 8`, where the inner parallel loop runs over just
> 2 109 elements and rayon overhead dominates, so it over-states the per-unit cost by an unknown
> factor. Scaling that measurement naively (cost ∝ classes × |ball|) gives ~6 h **per sweep** at
> `M = 32`, not 1–2 h in total — a disagreement of three orders of magnitude that can only be
> settled by measuring at a size where the loop is long enough to amortise. **This is LL-22
> recurring against its own author: a cost quoted from a model rather than a clock.** The
> `M = 16` run will supply the number, and it doubles as the correctness check against the
> table version's 42-sweep sequence. No `M = 32` commitment — and no VM request — before it lands.

#### 4.3.3 Pre-registration: what S-3 is predicted to return, and why it may not decide anything

Written **while the `M = 16` alignment is still running and before any S-3 trajectory exists**,
so that the reading of §4.3 can be checked against a prediction rather than fitted to a result.
Everything here is arithmetic on the three archived points; nothing is a claim.

**First, a correction to how §4.2 reads its own series.** §4.2 reports that the increments of
`Z_max/Z₀ − 1` *decelerate* (`×5.3` then `×2.2`) and calls the result "consistent with
saturation". Those are **ratios**. In absolute terms the same three points are

> `e(M) = Z_max/Z₀ − 1 = 0.0023, 0.0122, 0.0265`, increments **`+0.0099` then `+0.0143`**,

i.e. the increments are **growing, not shrinking** — and so are the injection's
(`ΔZ_inj/Z₀ = 0.0157, 0.0292, 0.0464`, increments `+0.0135`, `+0.0172`). Saturation requires the
increments to turn over, and **nothing in the data has turned over**. Concretely: fitting the
three-parameter family `e(M) = e_∞ − A·M^{−β}`, which is the generic approach-to-a-ceiling
shape, returns **`β = −0.53`** — the exponent has the wrong sign, so the only member of that
family through these points is a *divergent* one. The honest statement is therefore weaker than
§4.2's: the ratios falling is compatible with saturation, but **no saturating form actually fits
the three points**, and the "consistent with saturation" reading rests entirely on the ratios.

**A structural reason the ratios fall, which is not evidence of saturation.** The fraction of
the injected enstrophy that survives to the peak, `e/ΔZ_inj`, is `0.147, 0.418, 0.571` — it is
climbing toward a hard ceiling of `1`. At small `M` dissipation eats most of the injection
before the peak; at larger `M` the injection is over sooner (`t_peak = 0.022, 0.011, 0.003`) and
more of it survives. So `e` had to grow faster than `ΔZ_inj` early and must decelerate to
`ΔZ_inj`'s own rate as the fraction saturates — which is most of the way done. **The ratio
deceleration is largely this bookkeeping effect, not a statement about the enstrophy.**

**The prediction.** Two independent routes:

| route | predicted `e(16)` | `Z_max/Z₀` |
|---|---|---|
| `e ≈ c(log₂M)²`, `c = 0.00294` fixed at `M = 8` (a **divergent** form; it reproduces the growing increments) | `0.047` | **`1.047`** |
| survival-fraction bracket: `e(16) = (e/ΔZ_inj)(16) · ΔZ_inj(16)`, fraction `0.63–0.71`, injection ratio `1.37–1.59` from its falling exponent | `0.040–0.052` | **`1.040–1.052`** |

So S-3 is predicted to return **`Z_max/Z₀ ≈ 1.040–1.052`**, a third consecutive fall in the
ratio (`×5.3`, `×2.2`, then `≈×1.6–1.9`).

**And that is the point: the fourth point is predicted not to decide the question §4.3 poses
it to decide.** §4.3 says a third falling increment is "consistent with saturation" and a
non-falling one with a power law. But the divergent `(log₂M)²` model *also* predicts a third
falling ratio (`×1.78`), and lands inside the same bracket as the saturating reading. **At
`M = 16` the two hypotheses are predicted to differ by less than the spread of either
estimate.** They separate at `M = 32` (`(log₂M)²` gives `e ≈ 0.073` against roughly `0.055` for
a turnover) and cleanly at `M = 64`.

**What S-3 is still worth, stated without inflation.** It is a falsification test of the
bookkeeping model above, not of Hypothesis U: a return outside `1.040–1.052` refutes the
survival-fraction reading and is the informative outcome. A return inside it confirms the model
and leaves the saturation question exactly where §4.2 left it. **If the owner's purpose is to
separate saturation from slow divergence, the registered `M = 16` point is predicted to be
insufficient and `M = 32` is the first one that bites** — and per §4 of the compute brief, the
`M = 32` adversarial arm needs a new alignment algorithm before it needs a machine.

#### 4.3.4 S-3's first result: the prediction of §4.3.3 is FALSIFIED (2026-09-13; data, no verdict)

The `M = 16` greedy alignment converged at sweep 42 (`best = 17176873794444224`, 81 min with the
incremental objective of §4.3.2; phases archived as `exploration/scout_runs/S3_M16_phases.txt`),
and the every-step transient pair ran immediately. **The pre-registered bracket was
`Z_max/Z₀ ≈ 1.040–1.052`, committed in `ba76c30` before any S-3 number existed. The measured
value is `1.0324`. The prediction is falsified, below the bracket.**

**Readability, and a sampling amendment the `M = 16` point needed.** The halving pair
(`S3f_M16_advm_a/_b`, `dt = 2.5e-4 / 1.25e-4`) agrees over the whole window — worst disagreement
`9.95e-5` in `E` and `6.09e-4` in `Z`, both far inside the 2 % rule — and both members return
identical transient observables. But `t_peak` at `M = 16` is `0.001`, i.e. **four samples**, so
the §4.2 amendment was re-applied one level deeper: the whole series was re-measured on a uniform
ultra-fine grid (`dt = 6.25e-5`, every step, `S3ff_M{2,4,8,16}_advm`). `Z_max/Z₀` is unchanged
at `M = 16` (`1.0324`, robust to 16× finer sampling) and `M = 8` reproduces its archived value to
`2×10⁻⁴`, so the archived sampling was adequate below `M = 16`; only the `M = 16` **injection**
needed the finer grid (`0.0484 → 0.0503`, a 4 % under-integration on four samples). All numbers
below are from the uniform grid.

| `M` | `P/(νD₂)` at `t=0` | `t_φ` | `Z_max/Z₀` | `t_peak` | `ΔZ_inj/Z₀` |
|---|---|---|---|---|---|
| 2 | +1.604 | 0.059 | 1.0023 | 0.022 | +0.0154 |
| 4 | +2.840 | 0.017 | 1.0122 | 0.011 | +0.0292 |
| 8 | +4.115 | 0.004 | 1.0267 | 0.003 | +0.0468 |
| **16** | **+5.016** | **0.001** | **1.0324** | **0.001** | **+0.0503** |

**Every series has now turned over**, which is what §4.2's reading and §4.3.3's correction to it
were both waiting on:

```
                        differences
Z_max/Z₀ − 1 :  +0.0099, +0.0145, +0.0057
ΔZ_inj/Z₀    :  +0.0138, +0.0176, +0.0035
P/(νD₂) at 0 :  +1.236,  +1.275,  +0.901
t_φ          :  follows M^-2 exactly (0.004/4 = 0.001, measured 0.001)
```

**The LL-20 admissibility test, redone.** Fitting `e(M) = e_∞ − A·M^(−β)` to the last three
points (`M = 4, 8, 16`) now returns **`β = +1.347`** for `Z_max/Z₀ − 1` and **`+2.330`** for the
injection — **admissible**, where the same fit on `M = 2, 4, 8` returned `β = −0.53` and was
inadmissible. Implied ceilings `Z_max/Z₀ → 1.0361` and `ΔZ_inj/Z₀ → 0.0512`.

**This is stated with the loudest possible caveat, because it is the same shape of evidence that
was wrong one point ago.** `β = +1.347` is an exact three-parameter fit to three points. Twelve
hours ago the identical procedure on the identical observable returned an inadmissible exponent
and a confident divergent reading, and the fourth point overturned it. **It is not a verdict, it
is not a tier promotion, and `M = 32` is the test.** Tier C throughout; O5 stands.

##### Post-mortem of the falsified prediction, recorded because the diagnosis is a better model

The registered bracket had two factors. One was right and one was wrong:

- **survival fraction `e/ΔZ_inj`: predicted 0.63–0.71, measured 0.6441** — correct;
- **injection `ΔZ_inj/Z₀`: predicted 0.0634–0.0738, measured 0.0503** — wrong, and this is the
  whole miss. Its local exponent was assumed to fall to `≈0.50`; it fell to `0.104`, i.e. the
  injection stopped growing.

**The error was extrapolating the composite when the components were in hand.** `ΔZ_inj` is
driven by the initial excess times the alignment's lifetime, and both were separately measurable
in the archive: `t_φ` follows `M^-2` *exactly*, and the excess grows `×1.219`, not the `×1.62`
that §4.2's own `M^0.7` description implies. A decelerating driver multiplied by a lifetime
collapsing as `M^-2` gives a saturating product — **derivable before the run, from data already
committed.** The prediction instead extrapolated `ΔZ_inj`'s own local exponent and assumed it
would decline smoothly.

The standing amendment, now `LL.md` LL-24: **when an observable is a product of separately
measurable factors, pre-register the factors and multiply; never extrapolate the composite.**
The pre-registration did its job — it converted a comfortable reading into a test, the test
failed, and the failure localised to one factor rather than leaving a vague disagreement.

#### 4.3.5 `M = 32` costed from a clock, and it is reachable — but not the way anyone assumed

**The table-free alignment is validated and it is the better algorithm outright.** At `M = 16` it
converged at sweep 42 with **all 42 objective values identical** to the table version and a
**byte-identical phases file**, in `3 087 s` (`73.5 s`/sweep) on `0.2 MB` of state — against the
table version's `117 s`/sweep on `3.03 GB`. It is smaller *and* faster, because a 0.2 MB dense
state lives in cache while a 3 GB table is a random-gather graveyard. The table version is
retained only as the independent check.

**Three estimates of the `M = 32` alignment have now been made in this memo; the first two were
wrong in opposite directions and are both retracted.**

| estimate | basis | verdict |
|---|---|---|
| `195 GB`, `~108 days` | the quadratic algorithm | correct for that algorithm, obsolete |
| `negligible memory, 1–2 h` | a cost model, no clock | **too optimistic** |
| `~6 h per sweep` (the worry) | the `M = 8` clock, rayon-overhead-dominated | **too pessimistic** |
| **`20 min`/sweep, `1.4 MB`** | **the `M = 16` clock, cost ∝ classes × \|ball\|** | **measured basis** |

Sweep count is data, not a constant — 9 at `M = 8`, 42 at `M = 16` — so the total is bracketed,
not predicted: **`20–50 h` locally** for 60–150 sweeps, or **`10–25 h` on 16 vCPU**.

**And the cost picture changes shape once the readability finding below is taken seriously.** The
discriminating observable is `Z_max/Z₀`, which peaks at `t_peak = 0.022, 0.011, 0.003, 0.001` —
roughly `M^{-1.5}` — so at `M = 32` it peaks near `4×10⁻⁴` and needs a horizon of `~0.01`, not 6.
At the brief's measured `~1.8 s`/step that is **~400 steps ≈ 12 min, plus a halving partner ≈ 24
min total.** The horizon-6 trajectories costed at `~73 h` in the compute brief are for the
long-horizon observables — which S-3 does not need, and which §4.3.4 has just shown are *not even
readable* at `M = 16`.

> **Therefore: `M = 32` costs its alignment and essentially nothing else.** On 16 vCPU that is
> ~10–25 h ≈ **\$3–8 at spot pricing** (confirm before provisioning), against an authorised \$50.
> The trajectory arm that made `M = 32` look like a three-day job was answering a question the
> protocol does not ask.

##### The long-horizon arm at `M = 16` is NOT READABLE past `t ≈ 0.85`, and is reported as such

The horizon-6 halving pairs completed (`S3_M16_adv{m,p}_{a,b}`, `dt = 2.5e-4 / 1.25e-4`, 601 rows
each) and **fail the reading rule beyond `t ≈ 0.85`**:

| pair | readable horizon | disagreement at `t = 6` |
|---|---|---|
| `advm` (λ = −0.05) | **`t ≤ 0.85`** | `5.3 %` in `E`, `4.4 %` in `Z` |
| `advp` (λ = +0.05) | **`t ≤ 0.67`** | `9.0 %` in `E`, `2.1 %` in `Z` |

The disagreement accumulates smoothly — `1e-4` at `t = 0.1`, `1.4e-2` by `t = 0.67`, crossing the
2 % rule near `t = 0.85` — so this is ordinary RK4 error accumulating over tens of thousands of
steps, not an instability. But it means the registered step sizes, which were adequate over the
*whole* horizon at `M = 8` (worst disagreement `2.8e-4`), are adequate at `M = 16` only for the
transient. At fixed `dt` the truncation error grows with `M`, and halving `dt` from the `M = 8`
protocol was not enough to compensate.

**Consequences, applied rather than argued around.**

- **S-3's registered question is unaffected and answered.** It asks about `Z_max/Z₀`, which peaks
  at `t = 0.001` inside a window where the pair agrees to `1e-4`. §4.3.4 stands in full.
- **The `Z(1)/Z₀` column of §4.2 cannot be filled at `M = 16`.** `t = 1` lies outside the readable
  horizon, so it is **reported as not readable**, not quoted with a caveat. The `M = 2, 4, 8` rows
  of that column remain as archived.
- **No unilateral refinement.** Recovering the horizon would need `dt = 6.25e-5 / 3.125e-5`, i.e.
  96 000 + 192 000 steps, ≈ 15 h for the pair. Since S-3's question is already answered, spending
  that is an owner decision, not a gap to quietly close. Flagged here as the cost if the
  long-horizon row is wanted.

**And a methodological note that belongs with LL-21.** The protocol registered a step size but
never registered a *readability criterion for the step size itself* — the reading rule was stated
for the data and silently assumed of the integrator. The rule caught it anyway, which is the
system working; the amendment is that a protocol extending to a new `M` should predict its
own step-halving disagreement, not just its physical observables.

---

## 5. The certificate's arithmetic, built and measured (Tier B)

The whole Core-Tail construction rests on one primitive: a **rigorous upper bound on the
nonlinear forcing of a single mode**, computable without floating point. That primitive is now
built and checked — `tests/tier_b_core_forcing_bound.py`, wired into Gate 1.

### 5.1 How "interval arithmetic" and "no floating point in Tier B" are both satisfied

The standing constraint forbids floating point in any Tier B artifact; rigorous numerics
normally means intervals with directed rounding, which *is* floating point. The two are
reconciled by rounding in **exact rationals** instead of in floats:

> `sqrt_upper(a/b)` returns `(isqrt(a·b·4ⁿ) + 1) / (b·2ⁿ)`, a rational whose square exceeds
> `a/b` because `(isqrt N + 1)² > N` for every integer `N ≥ 0`. Integers only; the bound
> certifies itself by one exact comparison.

Every irrational the bound needs — `|q|`, `|k|`, `‖u_p‖` — is replaced by such a certified
rational, and every comparison in the certificate is then between two exact `Fraction`s. The
`n` (currently 24) buys tightness, never validity: a wrong `n` gives a weaker true bound, never
a false one. This is the design the `M_core ≤ 8` Rust evaluator will implement on `i128`/bignum
with `rayon`, and it is why that evaluator can produce a Tier B certificate at all.

### 5.2 Proposed amendment T-2′ — replace the varying `|q|` by the fixed `|k|`

On a divergence-free state, `p · u_p = 0`, so for `q = k − p`

> **`q · u_p = k · u_p`, exactly.**

Checked as an exact Gaussian-rational identity at every `(k, p)` pair of every tested state.
Consequently the forcing bound may be written

> **T-2′.**  `‖B(u,u)_k‖ ≤ |k| · Σ_{p+q=k} ‖u_p‖ ‖u_q‖`.

**Why this is the object the certificate wants, not a cosmetic rewrite.** In T-2 the weight
`|q|` varies over the sum and can reach `M`, so it cannot be taken outside; the
self-consistency inequality of §3 then compares `ν|k|²·Ce^{−a|k|}` against a *weighted*
convolution. In T-2′ the weight is constant in the summation variable, factors out, and the
inequality reduces to

> `ν |k| · C e^{−a|k|}  >  Σ_{p+q=k} bound(u_p) · bound(u_q)`,

an unweighted convolution of the envelope against itself — the form in which the exponential
envelope's summability can actually be used, and the form rigorous numerics for Navier–Stokes
uses. **T-2′ is proposed as an amendment to T-2 in §3 and awaits owner adoption (E-1); nothing
downstream may cite it until then.**

### 5.3 How tight is the bound? — measured, because the certificate's margin is its tightness

Tightness is reported as `‖B_k‖² / bound²`; `1` would be equality. Two strata, because random
states cannot measure a bound of this shape.

| stratum | `M` | worst tightness, T-2 | worst tightness, T-2′ |
|---|---|---|---|
| random genuine states | 2 | 0.0729 | — |
| | 3 | 0.0336 | — |
| | 4 | 0.0104 | 0.0095 |
| coherent two-wavevector states | 2 | **0.2500** | 0.2500 |
| | 3 (outer shell) | **0.1111** | **0.2125** |

On random states the bound is slack by a factor that *grows* with `M` — and that is an artifact
of the states, not of the bound: an incoherent sum of `N ~ M³` terms has magnitude `~√N` while
the bound has `~N`, so the tightness should fall like `M^{−3}`; observed `0.073 → 0.034 → 0.010`
across `M = 2, 3, 4` matches that to within the sampling. Measuring the bound therefore requires
the **coherent** stratum: states supported on two wavevectors and their conjugates, where the
sum has a handful of terms that can align. There the tightness is exactly `1/4` at `M = 2` and
`1/9` at `M = 3` for T-2, and T-2′ nearly doubles it at `M = 3`.

**The consequence the programme must plan for: even at its tightest the forcing bound loses a
factor of 2 to 3 in norm.** A self-consistency argument compounds that loss, so the envelope
parameters `(C, a)` must be chosen with at least that margin, and the certificate will cover
correspondingly fewer states. This is a quantitative obstacle, identified before any Lean was
written against T-2, and it is the reason T-2′ is worth adopting first.

### 5.4 A negative control that failed to fail, recorded as a measurement

Three structural controls — drop the `|q|` factor, use `|p|` in its place, round the roots the
wrong way — do **not** break the inequality at either stratum. That is not a defect: each
removes a factor smaller than the bound's own slack, so a true inequality stays true. The
control that certifies the checker can fail is **NC-E**, which quarters the bound and is
violated on 864 modes at `M = 2` and 240 at `M = 3`; its constant was fixed *after* the
tightness was measured, because a sensitivity control must be calibrated to the measured slack
to be able to fail at all. NC-D (reversing the inequality) fails everywhere, as the comparison
logic requires. This follows the LL-12 precedent: a control that fails to fail is kept and
reported as information, never quietly replaced.

### 5.5 The scaled evaluator, built and validated — and it is not a compute problem

`tests/core_forcing_rs` (Rust, `rayon`, `serde_json`) is the evaluator the certificate will
use. Every quantity is a non-negative fixed-point rational `n / 2^40` on `i128` and **every
operation rounds in a declared direction** — `mul_up` for an upper bound, `sqrt_up` via exact
integer square root, addition exact with a checked overflow. There is no floating point in the
crate, by construction rather than by convention.

**It is validated, not trusted.** `python3 tests/tier_b_core_forcing_bound.py --export ref.json 4`
writes the ball, `‖u_k‖²` per mode, and a **two-sided** exact-rational bracket on the T-2′ sum
(rounding the square roots down for the lower, up for the upper). `core_forcing verify ref.json`
recomputes independently and checks it lands inside that bracket. At `M = 4`, 257 modes: **0
results below the lower bracket, 0 above the upper bracket, and 0 modes where the round-down sum
exceeds the round-up sum** — the rounding direction is doing real work and in the right
direction.

**Sizing, measured on the local 8-core i7 while three scouts were running:**

| `M` | modes | mode-evaluations (`n²`) | wall |
|---|---|---|---|
| 8 (`M_core` ceiling) | 2 109 | 4.4 × 10⁶ | **32 ms** |
| 16 | 17 077 | 2.9 × 10⁸ | **1.85 s** |

`O(n²)` throughput is ~1.6 × 10⁸ mode-evaluations per second. **The certificate's forcing
evaluation is therefore not a compute problem at any `M` this programme contemplates** — the
directive's `M_core ≤ 8` is thirty milliseconds, and extrapolating the measured scaling puts
`M = 32` (≈ 137 000 modes) at about two minutes. Whatever blocks the Core-Tail certificate, it
is the mathematics of the self-consistency closure, not the arithmetic.

**Placement, flagged for ratification.** The crate sits under `tests/` because the rule that
governs it — exact arithmetic, no floating point — is the `tests/` rule, and that needs no new
top-level concept. It is deliberately **not** wired into `scripts/verify.sh`: doing so would
make `cargo` a hard dependency of Gate 1, which is an owner decision, not mine. The gate-wired
Tier B artifact remains the Python checker; the Rust crate is validated against it on demand.
