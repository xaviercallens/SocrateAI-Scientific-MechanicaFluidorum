# Brief — what still runs locally, and the one thing that does not

**For:** programme owner. **Author:** Fable. **Date:** 2026-09-13.
**Question answered:** when does this programme need a large-CPU GCP machine, at what cost and
for how long? **Short answer:** not yet, and for one of the two candidates, never — because it
is an algorithmic wall, not a compute wall.

All timings below are **measured on this machine** (8-core i7, 31 GB, CPU only), most of them
while other jobs were running, so they are conservative. Nothing here is a scientific claim.

---

## 1. Measured throughput

| workload | size | measured | note |
|---|---|---|---|
| Tier B exact forcing evaluator (`tests/core_forcing_rs`) | `M = 8`, 2 109 modes, 4.4 × 10⁶ mode-evaluations | **32 ms** | fixed-point `i128`, `rayon` |
| same | `M = 16`, 17 077 modes, 2.9 × 10⁸ | **1.85 s** | `O(n²)`, ≈ 1.6 × 10⁸ eval/s |
| Tier C scout, RK4 pseudo-spectral | `M = 16`, grid 64³, per RK4 step | **0.196 s** (was 0.473 s) | after the fix in §1.1 |
| Tier C scout | `M = 8`, grid 32³, 24 000 steps | ≈ 45 min contended | three runs sharing 8 cores |
| Tier C scout | `M = 2, 4`, full S-2 (12 runs + 6 fine) | **≈ 25 min** total | |
| greedy adversarial alignment | `M = 8`, ≈ 1 054 sign classes | **minutes**, after parallelisation | was tens of minutes serial |
| Lean Gate 2 | 12 files, 258 theorems | unchanged | |

### 1.1 A parallel-scaling fix worth more than a VM, made before asking for one

The first honest measurement of the scout was bad news for the idea of renting cores: at
`M = 16` one thread took `0.559 s` per step and **eight threads took `0.473 s` — a speedup of
1.18×**. The code was, in effect, serial. The cause was structural, not incidental:
`fft3` parallelised only the contiguous axis and ran the two strided axes as a single serial
gather/scatter, and the fifteen transforms that make up one right-hand side were executed one
after another.

The fix inverts the decomposition — each transform runs **serially**, and the twelve mutually
independent inverse transforms (three velocity components, nine gradients `∂_j v_i`) run in
**one flat twelve-way parallel loop**, followed by the three forward transforms. Measured at
`M = 16`: `0.473 s → 0.196 s` per step, a **2.4× wall-clock gain**, with core utilisation up
from 1.37 to 4.5 of 8. The output is **bit-identical** to the pre-change runs, and the exact
eight-step calibration still reproduces to `2.348e-16 / 2.389e-16 / 2.397e-16 / 2.389e-16` —
the same digits as before, on both engines.

**The lesson for the GCP question, and it is the main finding of this brief: the scout's
scaling limit is memory bandwidth and the twelve-way transform structure, not core count.**
Beyond about twelve busy threads there is nothing left to hand a core. A 64-vCPU VM would be
mostly idle; a 16-vCPU instance with high memory bandwidth is the right shape if a VM is ever
wanted at all.

## 2. What is local, and stays local

- **The whole Tier B certificate.** The directive's ceiling is `M_core ≤ 8`; that is
  **32 milliseconds**. Even `M = 32` (≈ 137 000 modes) extrapolates to ≈ 2 minutes. The
  Core-Tail certificate is not, and will not become, a compute problem. Whatever blocks it is
  the mathematics of the self-consistency closure.
- **Every Tier C scout up to `M = 8`.** Protocol S-2 in full — three initial conditions, two
  step sizes, plus every-step transient runs — cost about two hours of wall clock here.
- **`M = 16`, both halving pairs.** See §3: overnight, not a VM.

## 3. `M = 16` — the next decision-relevant point, and it is an overnight local job

The one number that would change the reading of S-2 is the fourth point in the transient
amplification series `Z_max/Z₀ = 1.0023, 1.0122, 1.0265` at `M = 2, 4, 8`: the increments are
decelerating (×5.3 then ×2.2), which three points cannot separate from a slow power law.

Cost, from the **measured** `0.196 s` per step at `M = 16`: **78 min** for the 24 000-step run
at `dt = 0.00025` and **157 min** for its 48 000-step halving partner — **≈ 4 h per initial
condition**, on this machine, after the §1.1 fix (it was ≈ 9.5 h before). Memory, not time, is
the local constraint: the greedy alignment's triad table at `M = 16` is ≈ 10⁸ entries (≈ 3 GB)
and this machine currently has ~11 GB free.

**Recommendation: run it locally — the adversarial pair is an afternoon, not a night.** A VM
here would save a few hours and cost more in provisioning and data movement than it returns.

> **Correction, same day, before any S-3 run.** The paragraph above counts the *trajectories*
> and silently omits the greedy alignment that produces the adversarial initial condition, which
> at `M = 16` is the larger half of the job: ≈ 30 min per sweep and ≈ 4–5 h for the nine sweeps
> the `M = 8` run needed (extrapolated from a measured `M = 8` alignment, see
> `docs/designs/CORE_TAIL_CAP.md` §4.3.1). **S-3 is an overnight job, not an afternoon.** The
> memory sentence below was also wrong by 6.6×: the table as coded cost 80 bytes an entry, not
> 24, with a further 9.8 GB transient — a peak of ≈ 20 GB against ≈ 14 GB available, i.e. the
> run would have failed. The scout has since been changed to build the table in index form only
> (3.06 GB, refactor verified bit-identical on the archived `M = 8` run) and to cache the
> alignment via `--phases-out` / `--phases-in`, so it is paid once instead of six times. The
> conclusion that a VM does not help is unchanged and is, if anything, strengthened: the
> alignment is serial-depth bound.

## 4. `M = 32` — a VM does NOT solve this, and that is the important finding

The hardware directive permits `M ≤ 32` for Tier C. Two separate obstacles, only one of which
money can remove:

- **Trajectories (compute).** ≈ 137 000 modes, grid 128³. Scaling the measured `M = 16` step
  cost by mode count and `N³ log N` gives ≈ 9.4×, so ≈ **1.8 s per step**; with the step halved
  again for accuracy, a halving pair to `t = 6` is 48 000 + 96 000 steps ≈ **73 h on this
  machine**, i.e. three days. On a VM the honest gain is **not** proportional to vCPU count —
  per §1.1 the code saturates around twelve busy threads and is then memory-bandwidth bound. A
  16-vCPU compute-optimised instance with better memory bandwidth is worth perhaps 2× over this
  i7, so **≈ 35–40 h wall**. At indicative GCP on-demand pricing (≈ $0.04–0.06 per vCPU-hour;
  **confirm before provisioning, prices move**) that is **≈ $25–40 on-demand, ≈ $10–15 on
  spot**. Renting 64 vCPUs instead would roughly quadruple the bill and return almost nothing.
- **The initial condition (algorithmic — money does not help).** The *null* initial condition
  at `M = 32` is reachable. The **adversarial** one is not: the greedy alignment builds a triad
  table of ≈ 6 × 10⁹ entries (**≈ 200 GB**) and improves it by sequential sweeps over ≈ 68 000
  sign classes, each sweep re-evaluating the whole table. That is a memory and a serial-depth
  wall, not a core-count wall — a 64-vCPU VM does not fix either.

**And the null initial condition is the uninformative one.** S-2 already shows the random-phase
null is neutral at every `M` measured (no amplification, production below dissipation at `t = 0`).
Spending 30 VM-hours to extend the *null* series answers no open question.

**Recommendation: do not provision for `M = 32` yet.** If the `M = 32` adversarial point is
wanted, the first task is algorithmic, not infrastructural — a streaming or shell-restricted
alignment whose table is never materialised, or a randomized local search. That design is
cheap to do and should precede any VM.

## 5. Summary for the owner

| item | needs GCP? | duration | cost |
|---|---|---|---|
| Tier B certificate, `M_core ≤ 8` | **no** | 32 ms | — |
| Remaining S-2 analysis, paper, Lean | **no** | minutes | — |
| `M = 16` adversarial + null pairs | **no** — local | ≈ 4 h per initial condition | — |
| `M = 32` **null** trajectories | optional | 73 h local, or ≈ 35–40 h on **16** vCPU | ≈ $25–40 on-demand, ≈ $10–15 spot |
| `M = 32` **adversarial** trajectories | **a VM does not help** | blocked | needs a new alignment algorithm first |

**The ask, if any: none right now.** I will flag it the moment a workload genuinely needs the
machine — the trigger would be the owner wanting the `M = 32` adversarial point *after* the
alignment algorithm is redesigned, or a decision to run many seeds at `M = 16` for statistics.
