# Scout calibration against the exact Tier B trajectory — RESULT (2026-09-13)

**Target:** `exact_steps_M2.json` — the adversarial and null initial conditions at `λ = 1/20`
and their eight exact forward-Euler steps at `dt = 1/64`, `ν = 1/20`, `M = 2`, rendered to 30
decimals by integer arithmetic from `tests/tier_b_dynamic_access.py`.

**Scout:** `exploration/dual_scale_scout_rs` (Rust, `rustfft` 6.4 + `rayon`), both engines, run
with `cargo run --release -- calibrate exploration/calibration/exact_steps_M2.json`.

| engine | initial condition | worst relative state error over the 9 exact states | E at step 8 (scout vs exact) | Re P at step 8 (scout vs exact) |
|---|---|---|---|---|
| direct | adversarial | **2.348e-16** | 2.993726936324 vs 2.993726936324 | −4.415241090e-1 vs −4.415241090e-1 |
| direct | null | **2.389e-16** | 2.993636181816 vs 2.993636181816 | −5.313989380e-2 vs −5.313989380e-2 |
| FFT (2/3 de-aliased, N=8) | adversarial | **2.397e-16** | identical to all printed digits | identical |
| FFT | null | **2.389e-16** | identical | identical |

**Reading.** Both engines reproduce the exact rational trajectory to machine epsilon for both
initial conditions, and agree with each other to round-off. The FFT engine's de-aliasing is
exact as designed (`N ≥ 3M+1` puts every aliased product outside the retained band); an
independent check on the `M = 4` adversarial state gives identical `E`, `D`, `Re P` between
engines to every printed digit (`Im P` 2.9e-13 vs 0, round-off).

**Consequence.** The scout's discretisation is the Tier B discretisation, verified rather than
asserted. Its long-horizon output is Tier C (floating point, RK4) and is readable only where the
step-halving check agrees; the calibration certifies the *right-hand side*, not any horizon.

*The full transcript was produced in the session scratchpad; the numbers above are copied from
it verbatim.*
