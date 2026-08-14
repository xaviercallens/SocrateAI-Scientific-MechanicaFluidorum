# Design memo — D6: a cutoff-uniformity measurement that can actually detect non-uniformity

**Status:** design, `[top]`-authored, **awaiting owner approval before dispatch** (PLAN.md's D5
rule: no `[any]` implementation before the memo exists).
**Supersedes the measurement intent of:** D4, D5, and the dual-precision sweep — all of which
measured a grid with **zero detection power**, for the reason established below.
**Owner decision it implements:** *"Ne pas signer, redessiner"* (2026-08-14).
**Author:** orchestrator. **Date:** 2026-08-14.

---

## 1. What went wrong, quantitatively

The programme's own synthesis — *"44 of 45 configurations bit-identical in `sup Ω` across every
`N`"* — was written into `LEDGER.md` as the evidence base for a uniformity verdict. It is an
artifact of the grid.

Direct shell-amplitude profiling (profile P1, `T=10`, `N=24`, the programme's own IMEX scheme):

| `ν` | highest shell with peak `\|a_n\| > 1e-12` | grid actually tested |
|---|---|---|
| 0.01 | n = 8 | `N ∈ {8,12,16,20,24}` |
| 0.001 | n = 10 | `N ∈ {8,12,16,20,24}` |

And the enstrophy is not merely concentrated — it is **dominated by a single shell**. At
`ν=0.001`:

| shell | peak `\|a_n\|` | `k_n² a_n²` | share of `2Ω ≈ 140` |
|---|---|---|---|
| n = 8 | 4.5e-2 | **132.7** | **≈ 95 %** |
| n = 10 | 1.7e-6 | 3.0e-6 | 2e-8 |

**So the grid's smallest cutoff, `N=8`, sat exactly one shell above the decisive one.** Raising
`N` from 8 to 24 appended shells contributing `~1e-8` relative — literally nothing, to machine
precision, which is precisely why 44/45 configurations agreed *bit-identically*. Lowering to
`N=7` would have removed 95 % of the enstrophy.

**The experiment varied the one parameter along the one range in which it could have no effect.**

## 2. The criterion, now enforced mechanically

`tests/tier_b_grid_adequacy.py` (Tier B, wired into Gate 1) rejects such a grid *before it runs*,
on exact integer arithmetic — no floats, no logarithms. Balancing viscous against nonlinear rates
with the K41 amplitude `a_n ∼ k_n^{-1/3}` gives `k_d ∼ ν^{-3/4}`, so with `k_n = 2ⁿ` the cutoff
lies at or above the dissipation scale iff `2^(4N)·ν³ ≥ 1`, i.e. writing `ν = p/q`:

```
        2^(4N) · p³  ≥  q³            (pure integer comparison)
```

Its negative control is the historical grid itself: **0 of 15 configurations had a biting
cutoff.** Its positive control is a grid that does.

**Reconciliation with the measurement, stated honestly.** The exact criterion says the cutoff
bites only for `N ≤ 7` at `ν=1e-3`, while shells remain nominally nonzero up to `n=10`. These
agree in substance: the criterion carries an unknown `O(1)` prefactor, and the shells it
"misses" (n=9,10) contribute `2e-8` of the enstrophy. The criterion is used only in the
direction where the prefactor cannot matter — a rejected grid exceeds the dissipation scale by a
factor growing **geometrically** in `N`.

## 3. The redesigned measurement

### 3.1 Grid

For each `ν`, sweep `N` **across** the dissipation shell rather than above it:

| `ν` | dissipation cutoff `N_d` (largest biting `N`) | proposed sweep |
|---|---|---|
| 1/100 | 4 | `N ∈ {2,3,4,5,6}` |
| 1/1000 | 7 | `N ∈ {4,5,6,7,8,9}` |
| 1/10000 | 10 | `N ∈ {6,7,8,9,10,11,12}` |

Each sweep straddles `N_d`: below it truncation amputates an active part of the cascade and
`sup Ω` **must** respond; above it the curve should flatten. **The transition itself is the
observable** — its location is predicted by §2's criterion, so the measurement has a
pre-registered falsifiable structure rather than being an open-ended search.

Adding `ν = 1/10000` extends the lever arm; it is feasible precisely because the useful `N` are
*small*, which is also why the redesigned runs are far cheaper than the old ones.

### 3.2 The primary observable, and why it is not `sup Ω` alone

`sup_t Ω_N(T)` conflates two things: how much enstrophy the *retained* shells hold, and whether
the cascade is trying to push past the cutoff. Report all three:

1. `sup_t Ω_N(t)` — the historical quantity, for continuity.
2. **`F_N := sup_t k_N³ a_N(t)² a_{N+1}(t)`** — the production flux *at the cutoff*, which is
   exactly the term the truncation sets to zero (`EnstrophyProduction.lean`'s `prodOut` at
   `n=N`). If `F_N → 0` as `N` grows, the truncation is genuinely inert; if it does not, the
   cutoff is doing work and any flatness in `sup Ω` is suspect.
3. **The shell-population profile** `peak_n = sup_t |a_n(t)|` for every `n ≤ N`, reported with
   every run. Had this been recorded from the start, the defect in §1 would have been visible
   immediately rather than after two campaigns.

### 3.3 Mandatory controls, before any headline number

- **Positive control (Cheskidov regime).** Dissipation degree `≥ 1/2`, where global regularity
  is a published theorem, must read as bounded. An instrument never shown to register a
  known-bounded case cannot be believed when it reports boundedness.
- **Negative control (inviscid).** `ν = 0`, where finite-time blow-up is a published theorem for
  the dyadic model (Katz–Pavlović 2005). The instrument **must** report unbounded growth. If it
  reports boundedness at `ν=0`, it is broken — and this is the sharper of the two controls,
  because it is the one this programme's own hoped-for conclusion would predict wrongly.
- **Grid adequacy.** Gate 1 must pass `tier_b_grid_adequacy.py` for the proposed grid.
- **Step-size refinement.** Every reported configuration at `dt` and `dt/2`, agreeing to 1 %.

### 3.4 Pre-registered analysis (fixed before any run)

- Fit window: `N ≤ N_d` only (the biting regime). The flat regime `N > N_d` is reported but
  **excluded from the fit**, since §1 shows it carries no information.
- Exclusion: any configuration failing refinement agreement is reported *with its count*, never
  silently dropped.
- Interpretation, pre-committed: `sup Ω` **rising** as `N → N_d` from below and then flattening
  is the *expected* signature of an adequate instrument, not evidence for or against uniformity.
  The uniformity question is whether the flat level **grows with `ν → 0`**, and at what rate.

## 4. What this design still cannot settle

- It cannot distinguish "uniformly bounded" from "growing slower than the grid resolves".
- It is Tier C floating-point measurement of a discrete scheme, not of the continuum shell model.
- It says nothing about 3-D Navier–Stokes. The pivot means the shell model is now the target
  itself, not a proxy — but that makes the claim *smaller*, not stronger.
- A clean result here would **not** license any verdict on Hypothesis U.

## 5. Dispatch plan

1. `[any]` — extend the exploration harness to record the shell-population profile and `F_N`
   alongside `sup Ω`; re-run the historical grid to reproduce §1's table as committed data.
2. `[any]` — the redesigned sweeps of §3.1 with the §3.3 controls.
3. `[top]` — analysis per §3.4; no verdict.
4. `[human]` — verdict, if the owner judges the evidence base adequate.

**Estimated cost: lower than the campaigns it replaces**, since the informative cutoffs are
small (`N ≤ 12`) where the old grid ran to `N = 24`.
