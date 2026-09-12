# TIER C — EXPLORATORY, NO CLAIMS

Archived output of `exploration/dual_scale_scout_rs` (floating point, RK4, pseudo-spectral FFT with
exact 2/3 de-aliasing). Every file's first line is the exact run configuration. Nothing here is a
claim: a number is *readable* only where its step-halving partner (`_a` = dt, `_b` = dt/2) agrees on
`E` and `Z` within 2% — see `python3 exploration/scout_summary.py halving A B`.

## Protocol S-2 (registered in `docs/designs/CORE_TAIL_CAP.md` §4 before the runs)

`E0 = 144`, `ν = 0.05`, horizon `t = 6`, sampled every `t = 0.01`, `|λ| = 0.05`.

| file stem | M | ic | λ | dt (`_a` / `_b`) |
|---|---|---|---|---|
| `S2_M2_advp` | 2 | adversarial (greedy) | +0.05 | 0.001 / 0.0005 |
| `S2_M2_advm` | 2 | adversarial (greedy) | −0.05 (production-positive) | 0.001 / 0.0005 |
| `S2_M2_null` | 2 | random phases, seed 1 | +0.05 | 0.001 / 0.0005 |
| `S2_M4_*` | 4 | same three | same | 0.001 / 0.0005 |
| `S2_M8_*` | 8 | same three | same | 0.0005 / 0.00025 |
| `S2f_M{2,4,8}_advm` | 2, 4, 8 | adversarial, λ = −0.05 | horizon **0.1**, **every step** (`_a`: dt 0.0005 every 1; `_b`: dt 0.00025 every 2) | 0.0005 / 0.00025 |

The `S2f_*` runs exist because the registered sampling interval (0.01) turned out to be coarser
than the dephasing time at `M = 8` (0.004) and equal to the peak time at `M = 4`; the transient
observables (`Z_max/Z₀`, `t_peak`, `t_φ`) are read from them, the long-horizon ones from `S2_*`.
Same initial states (the greedy alignment is deterministic; `S2f_*_b` row 0 equals `S2_*_b` row 0).

## Protocol S-3 (registered in `docs/designs/CORE_TAIL_CAP.md` §4.3 before the runs)

Same normalisation as S-2 (`E0 = 144`, `ν = 0.05`, `|λ| = 0.05`). The `M = 16` adversarial
alignment is expensive and deterministic, so it is computed once and cached:
`S3_M16_phases.txt` (one sign per half-ball wavevector, in half-ball order), replayed by every
adversarial run with `--phases-in`. Converged at sweep 42, `best = 17176873794444224`.

| file stem | M | ic | horizon / sampling | dt (`_a` / `_b`) |
|---|---|---|---|---|
| `S3f_M16_advm` | 16 | adversarial, λ = −0.05 | 0.1, **every step** (`_a` every 1; `_b` every 2) | 0.00025 / 0.000125 |
| `S3ff_M{2,4,8,16}_advm` | 2,4,8,16 | adversarial, λ = −0.05 | **uniform ultra-fine**: `dt = 6.25e-5`, every step, horizon 0.05/0.03/0.02/0.02 | single dt |

The `S3ff_*` runs exist because `t_peak` at `M = 16` is `0.001` — only **four** samples even on
the `S3f` every-step grid — so the §4.2 sampling amendment was re-applied one level deeper and
the *whole series* re-measured on one uniform grid, so the four points are comparable. Result:
`Z_max/Z₀` is unchanged at `M = 16` under 16× finer sampling and `M = 8` reproduces its archived
`S2f` value to `2e-4`; only the `M = 16` injection integral was under-integrated, by 4 %. The
`S3ff_*` values are the ones read in `CORE_TAIL_CAP.md` §4.3.4.

Columns: `step,t,E,D,D2,P_re,P_im,ratio_energy,ratio_enstrophy` with `D = Z = Σ|k|²|u_k|²`,
`D2 = Σ|k|⁴|u_k|²`, `P` the enstrophy production, `ratio_energy = P/(νD)`,
`ratio_enstrophy = P/(νD2)` (`> 1` ⟺ enstrophy increasing).

Summaries: `python3 exploration/scout_summary.py {summary,transient,halving} …`.
