# TIER C — EXPLORATORY, NO CLAIMS

Experiments behind `docs/designs/SPECTRAL_ALIGNMENT.md`: computing the adversarial alignment's
objective and gradient with the scout's FFT engine instead of by triad enumeration.

| file | what |
|---|---|
| `s_vs_p.py` | Memo §2. Exact-integer `S(σ)` for three sign patterns at `M = 8`, written as scout phases files; the scout's `P(t=0)` on each gives `P/S = 8.858612371e-8` for all three. |
| `gradcheck.py` | Memo §4 control 1. Reads `dual_scale_scout gradcheck` output and the exact `dS/dσ_j` from the Tier B table; the ratio must be one constant over `j`. |

Reproduce (from the repo root, scout built):

```bash
python3 exploration/alignment_spectral/s_vs_p.py /tmp/out          # writes M8_{ones,greedy,random}_phases.txt
cargo run --quiet --release --manifest-path exploration/dual_scale_scout_rs/Cargo.toml -- \
  gradcheck --M 8 --phases-in /tmp/out/M8_random_phases.txt > /tmp/out/grad.txt
python3 exploration/alignment_spectral/gradcheck.py 8 /tmp/out/M8_random_phases.txt /tmp/out/grad.txt
# negative controls, each must FAIL:
#   --drop-adjoint            (on any field)
#   --no-reflect --ic null    (needs a COMPLEX field: on the sign family the reflection is a
#                              sign flip squared and this control is vacuous -- see the memo)
```

`gradcheck` also prints the slot-wise Euler identity `T1/P, T2/P, T3/P` with `h = u`, which
needs no oracle and separates the three gradient terms; all three must read `1`.
