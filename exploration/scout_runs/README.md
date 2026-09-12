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

Columns: `step,t,E,D,D2,P_re,P_im,ratio_energy,ratio_enstrophy` with `D = Z = Σ|k|²|u_k|²`,
`D2 = Σ|k|⁴|u_k|²`, `P` the enstrophy production, `ratio_energy = P/(νD)`,
`ratio_enstrophy = P/(νD2)` (`> 1` ⟺ enstrophy increasing).

Summaries: `python3 exploration/scout_summary.py {summary,transient,halving} …`.
