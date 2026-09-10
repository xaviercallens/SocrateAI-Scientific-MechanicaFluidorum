# Review — LeanFlow's "Counter-Detonation" results (owner request, 2026-09-10)

**Artifact reviewed:** `SocrateAI-Numeric-DualScale-Solver/SocrateAI-Numeric-DualScale-Solver`
(the LeanFlow solver), specifically
`crates/leanflow-solver/src/euler_counterdetonation.rs` and `crates/leanflow-core/src/lib.rs`,
read in full at the source level on 2026-09-10.
**Requested:** *"vérifie leurs résultats et intègre-les."*
**Method:** source audit. **The test suite could not be executed from this session** (the shell is
confined to this repository), so nothing below rests on a claimed pass or fail — every finding is
read off the code itself, which is the stronger evidence anyway (LL-2: a self-report is not the
artifact).

## Verdict

**The three headline claims are not supported by the code that produces them.** Each fails for a
reason this repository has already recorded as a named lesson. **Integrated as a review, not as
results**; `MEMORY.md` §1.C is rewritten as a *plan* accordingly (owner decision, 2026-09-10).

What *is* sound and is adopted below: `leanflow-core::r_eff` implements `max(R, α/R)` and agrees
exactly with this repository's Tier A `Reff`, including the bounce branch — an independent
re-implementation that matches, which is worth having.

---

## ⚠ CORRECTION TO FINDING 1, after the decisive control was run (2026-09-10, same day)

**The control partly refutes my own Finding 1, and that is reported here rather than quietly
amended.** The owner ordered the decoupling run; `exploration/beltrami_decoupling_control.py`
executes it as a 2×2 factorial (metric on/off × damping on/off), because the instruction as given
("damping = 16, alpha_prime = 0") cannot be run literally — in the reviewed source the damping is
*derived from* `alpha`, so zeroing `alpha` also zeroes the damping.

| run | metric | damping | terminal alignment | max Ω/Ω₀ | outcome |
|---|---|---|---|---|---|
| A | `k_eff` | on | 0.9888 | 14.9 | bounded |
| B | bare `k` | on | — | 8.9e31 | **DIVERGED — inadmissible** |
| C | `k_eff` | **off** | 0.9805 | 15.0 | bounded |
| D | bare `k` | off | — | 4.1e10 | **DIVERGED — inadmissible** |

**What this changes.** Finding 1 said the Beltrami state is produced by the damping term. That is
**wrong about boundedness**: the metric alone (run C) keeps the run bounded and reaches alignment
0.9805, while the damping alone (run B) **diverges**. Boundedness is supplied by `k_eff`, not by
the hand-added damping. The damping contributes `+0.0084` of alignment on top of the metric.

**What survives, and is now sharper.** The alignment observable was never far from 1 to begin with:
the initial condition sets `u⁻ = 0.15 u⁺`, so it starts at **0.9560** by construction. The claimed
"topological conversion of kinetic energy into a Beltrami flow" is a move of **+0.0329**. A
statement that the flow *becomes* Beltrami, from a state that is already 95.6 % Beltrami by choice
of `epsilon_cross`, is not supported by that delta — and the Lamb-norm decay, being a function of
the same alignment, adds no independent evidence. Findings 2, 3, 4, 5 and 6 of this review are
untouched by the control.

**A defect in my own control, caught by the control itself and recorded (LL-19).** The first run
printed a conclusion from run B, which had diverged; and its N2 negative control read exactly
`0.00e+00` because the perturbation indexed the same shell on both branches, making it inert. Both
are fixed: diverged cells are now marked inadmissible and refuse interpretation (LL-18), and the
perturbation now mis-indexes the influx wavenumber and fires at `4.85e-01`.

---

## Finding 1 (as originally written, 2026-09-10 morning) — superseded in part by the correction above

`euler_counterdetonation.rs` adds a term that exists only when the shield is on:

```rust
let wall_factor = if alpha > 0.0 { (1.0 - k_star / kn).max(0.0) * 16.0 } else { 0.0 };
du_minus[i] = transfer_minus + cross_term - wall_factor * um_curr;
```

This is **linear damping applied to the negative-helicity amplitudes only**, with strength up to
16. It is not a consequence of any metric: `k_eff` enters the triad rates separately, and this term
is added on top of them.

The reported observable is

```rust
beltrami_alignment = |Σ κₙ(uₙ₊² − uₙ₋²)| / Σ κₙ(uₙ₊² + uₙ₋²)
```

which tends to 1 **identically** as `u⁻ → 0`. So the code damps `u⁻`, then measures a quantity that
is a monotone function of `u⁻` being small, and reports the result as the topological formation of
a Beltrami flow. The test `test_t_dual_shield_defuses_blowup_and_forms_beltrami_flow` asserts
`final_alignment > 0.98` — an assertion on the damping constant, not on the fluid.

The Lamb-vector norm inherits the same circularity: it is computed as
`2√(E·Ω·(1 − cos²θ))`, i.e. **derived from the alignment**, not from `u × ω`. Its decay to zero is
the same statement told twice.

*This is LL-11's failure mode: a number that looks like a mechanism because it was never compared
to a null. The null here is trivial — run the identical damping with `k_eff` replaced by `k`.*

## Finding 2 — The frustration index diverges as 0/0, with no liveness guard

`leanflow-core`:

```rust
let denom = sum_signed.abs();
let d_m = if denom < 1e-12 { f64::INFINITY } else { sum_abs / denom };
```

When the shield freezes the flow, **both** sums go to zero, and `𝒟` is reported as `INFINITY`
because only the denominator is tested. A dead flow scores maximal frustration.

This session hit precisely this artifact in its own harness on 2026-09-09: an all-real field gives
`Σ|T| = 0` identically by parity, and the control passed vacuously until a liveness guard
(`sum_abs_t > 1e-12`) was added. See `exploration/triad_frustration_rs/src/main.rs` (control P2b)
and `docs/designs/TRIAD_FRUSTRATION_DM.md` §5. **LeanFlow needs the same guard**; the one-line fix
is to require `sum_abs > ε` before interpreting `d_m`, and to return a distinct
`FrustrationUndefined` state otherwise (LL-18: distinct causes get distinct names).

Until then, `max_frustration_index > 100.0` in the test is satisfiable by the flow stopping.

## Finding 3 — The "Euler blow-up" is a cascade into a truncated grid, not a singularity

The calibration run is a **20-shell helical dyadic model**, not the Euler equations. Blow-up is
declared when enstrophy exceeds `initial_enstrophy × 1e6`.

In a truncation at `N = 20` shells with `κₙ = 2ⁿ` (so `κ_N = 2¹⁹`), enstrophy obeys the a priori
bound `Ω = ½Σκₙ²(uₙ₊² + uₙ₋²) ≤ ½κ_N²·2E = κ_N²·E ≈ 2.7 × 10¹¹ · E`. Energy merely reaching the
upper shells therefore crosses a `10⁶` threshold **with no singularity anywhere**. The detector cannot separate "finite-time blow-up" from
"the cascade arrived at the cutoff", which is the exact defect this programme documented in D5/D6
and mechanised as `StopReason`/`Aggregate` in `tests/controls.py` (LL-18). The published D6 design
memo requires the shell-population profile and the cutoff flux `F_N` to be reported with every run
for this reason; neither is recorded here.

Two further points on the same run:

- **The α′ = 0 run does not conserve energy**, so it is not an inviscid Euler surrogate. The
  homochiral transfers telescope correctly (energy-conserving, as they should), but the added
  `cross_term` contributes `Σ cross_n (uₙ⁻ − uₙ⁺) ≠ 0`. An unforced inviscid model with an energy
  source is not evidence about Euler.
- **The two records disagree on the number.** The test asserts `t* < 0.3`; `MEMORY.md` §1.C reports
  `t ≈ 0.38 – 0.40`. Both cannot describe the same passing run.

## Finding 4 — Two different "T-dual metrics" coexist in one crate

| object | formula | status here |
|---|---|---|
| `r_eff(α, R)` | `max(R, α/R)` | **matches our Tier A `Reff`** exactly |
| `k_eff(k, α′)` | `k / (1 + α′k²)` | a *different* function — not the Fourier image of `Reff` |

The Fourier-side image of `Reff` is `min(k, 1/(α′k))` (as the owner's own memorandum writes it).
`k/(1+α′k²)` shares its large-`k` asymptotics (`~1/(α′k)`) and is smooth, which may well be the
better numerical choice — but it is a **different object**, and no result proved about `Reff`
transfers to it without an argument. Recommend renaming it (e.g. `k_eff_pade`) and stating the
relationship, so that a future reader cannot cite a `Reff` theorem for a `k_eff` computation.

## What to do with this (recommended, owner's call)

1. **Adopt** `r_eff` as an independent cross-check of Tier A `Reff` (two implementations agreeing).
2. **Add the liveness guard** to `compute_frustration_index_from_transfers`; it is one line and it
   removes Finding 2 outright.
3. **Re-run the shield with the damping term and `k_eff` decoupled** — the decisive control. If
   `wall_factor` with `k_eff → k` (shield "off" but damping on) also produces alignment > 0.98, the
   Beltrami result belongs to the damping, not to T-duality.
4. **Report the shell-population profile and the cutoff flux** with every calibration run, per the
   D6 design memo, before the word "blow-up" is used again.
5. **Do not describe any of this as reproducing OpenAI's Euler result.** External audit verdict D1
   (2026-08-13, accepted by the owner) killed the equivalence between a dyadic shell hierarchy and
   the unreduced 3-D equations for this programme. The same rule binds here.

**Not reviewed:** the ETD-RK4 / Leray-projection CFD core, the JHTDB benchmarks, and the
enterprise/GPU claims. Those are a separate audit and nothing above bears on them.
