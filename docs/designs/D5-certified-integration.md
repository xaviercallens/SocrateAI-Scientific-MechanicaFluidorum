# D5 Design Memo — Rational IMEX-Euler for the Dyadic Cutoff-Uniformity Measurement

**Author:** Fable 5 (top-tier, per PLAN.md D5 requirement — "do not start the `[any]` half
before the design memo exists"). **Decided by human owner:** 2026-08-12 (rational IMEX-Euler,
over cutoff-independent explicit stepping or accepting small-N only).
**Responds to:** `docs/escalations/2026-08-12-D4-sweep-gap.md` (D4's explicit RK4 sweep was
58% infeasible; `dt ∼ 1/k_N²` collapses as N grows).

## The scheme

Split the right-hand side into its stiff linear part (viscosity) and its nonlinear part
(the flux), and treat them differently — implicit Euler on the linear term, explicit Euler
on the nonlinear term:

```
a_n^{(t+dt)} = ( a_n^{(t)} + dt * NL_n^{(t)} ) / ( 1 + ν k_n² dt )
NL_n^{(t)}  = k_{n-1} (a_{n-1}^{(t)})² − k_n a_n^{(t)} a_{n+1}^{(t)}
```

Every quantity is a `Fraction`: `k_n = 2^n` (exact integer), `ν`, `dt` chosen rational,
`a_n` rational throughout. **Zero floating point** — this is a Tier B instrument, not Tier C.

## Why this fixes the D4 blocker

The explicit scheme's stability requires `ν k_N² dt ≲ 1`, forcing `dt ∼ 1/(ν k_N²)`, which
collapsed at `N = 12` under `ν = 0.1` (the D4 escalation). The implicit treatment of the
viscous term is **unconditionally stable in that term alone**: the update divides by
`1 + ν k_n² dt`, which only damps faster (toward 0) as `k_n` grows — it can never blow up.
`dt` can therefore be chosen from the *nonlinear* time scale only, independent of `N`. This
is standard IMEX practice for stiff-linear/nonstiff-nonlinear systems (shell models are the
textbook case) and it stays entirely exact because dividing two rationals is a rational.

## What this scheme can and cannot certify

**Can certify (Tier B):** the enstrophy trajectory `Ω_N(t)` of the *exact rational IMEX-Euler
discretization*, for the full range `N ∈ {8, …, 24}` requested by the roadmap, at genuinely
comparable `dt` across all `N`.

**Cannot certify:** that this trajectory equals the true ODE solution's trajectory. IMEX-Euler
is first-order; its local truncation error is `O(dt²)` per step from splitting plus `O(dt²)`
from the explicit half. **Mandatory consistency check:** every configuration is run at `dt`
and `dt/2`; report both `sup_t Ω_N(t; dt)` and `sup_t Ω_N(t; dt/2)`, and flag any pair whose
ratio suggests the sequence has not entered its asymptotic regime (e.g. their difference is
not shrinking roughly like the step ratio). No claim of ODE-level uniformity may be drawn from
a single `dt` — only from step-halving agreement, and even then, honestly, only as **evidence
for the discrete scheme**, not a proof about the continuous shell model.

## Deliverable for the `[any]` run

`data/dyadic_omega_sup_imex.csv`, columns: `N,nu,profile,dt,dt_half,sup_Omega_dt,
sup_Omega_dt_half,ratio_check,steps,status`. Same three fixed profiles P1/P2/P3 as D4.
`N ∈ {8, 12, 16, 20, 24}`, `ν ∈ {0.1, 0.01, 0.001}` (as `Fraction`), `T = 10` (rational).
Choose `dt` from the nonlinear scale: `dt = 1 / (4 * max(|a_n^{(0)}|) * k_{n_max_excited})`,
hardcoded per profile (documented in the script). No adjectives in the report — table only;
the uniformity verdict remains reserved to the human owner (PLAN.md §8).

**Status:** design complete; `[any]` implementation task is now unblocked and may be dispatched.
