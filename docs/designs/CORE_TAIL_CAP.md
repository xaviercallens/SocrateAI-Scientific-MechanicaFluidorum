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
