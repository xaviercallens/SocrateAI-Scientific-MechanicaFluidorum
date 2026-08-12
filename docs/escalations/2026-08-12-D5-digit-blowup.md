# E-5 Anomaly — D5's rational IMEX-Euler diverges by representation, not magnitude

**Filed by:** orchestrator (Fable 5), 2026-08-12, after independently reproducing the finding.
**Task:** D5 (Tier B certified cutoff-uniformity run), executed exactly per
`docs/designs/D5-certified-integration.md`.
**Ownership of the error:** the design memo is mine. Its physical reasoning (implicit viscous
term is unconditionally stable) is correct; its **feasibility claim** ("very feasible in exact
Fraction arithmetic … small state vectors") was wrong, and this is on the design, not the
executing agent, who implemented it faithfully, ran the mandated guard, and escalated exactly
as PLAN.md prescribes rather than improvising a fix.

## What happened, independently confirmed

All 45 requested configurations (`N∈{8,12,16,20,24} × ν∈{1/10,1/100,1/1000} × 3 profiles`,
each at `dt` and `dt/2`) hit the memo's own 200-decimal-digit guard within **2–6 steps**, far
short of the 40–160 needed to reach `T=10`. I re-ran the negative-control self-test (passes)
and inspected the raw CSV myself: the `N=8, ν=1/10, P1` row's numerator and denominator are
each several hundred digits long after 6 steps. The agent's own diagnostic (bit-length
roughly doubling per step: 2, 6, 14, 32, 70, 147, 308, 634, 1294, 2626 decimal digits over
steps 1–10) is consistent with what I see in the delivered CSV.

**This is not the magnitude blow-up the digit guard was written to catch.** Several diverging
rows have small `sup_Ω` values (9/2, 13/2, 25/2) at the moment they trip the guard — the
*state* is not exploding, only its **exact representation** is. This is the well-known
pathology of iterating a genuinely nonlinear rational map in exact arithmetic: each step's
numerator/denominator are polynomial in the previous ones (the IMEX division does not undo
this — dividing by `1+νk_n²dt` just adds another large denominator), so bit-length grows
roughly geometrically with step count regardless of whether the underlying dynamics is stable.
**Implicit-vs-explicit splitting was the wrong axis to redesign on; the actual obstruction is
that "exact rational time integration" and "many time steps" are close to mutually exclusive
for a nonlinear recurrence**, independent of stiffness.

## Why this matters, and why I am not silently redesigning again

I have now proposed two designs for this measurement (D4's explicit float RK4, D5's rational
IMEX-Euler) and both failed their feasibility premise, for different underlying reasons. A
third redesign chosen unilaterally would repeat the same failure mode this rule exists to
prevent — picking a *methodology* is exactly the class of decision PLAN.md §2/E-4 reserves to
the human owner, and here it is doubly so: SPEC's Tier B gate explicitly bars floating point,
so any fix that reintroduces floats (even high-precision ones) is a **standards-level**
question, not a mechanical one. I am asking rather than choosing.

## Options for the human owner, sketched with actual tradeoffs

1. **Short-horizon exact certification.** Keep exact IMEX-Euler, but certify only to the
   number of steps that stays within the digit guard (empirically ~5–8 steps for the current
   configurations), and report `sup_{t≤t_max} Ω_N(t)` at that honest, short `t_max` instead of
   `T=10`. Fully rigorous, Tier B, but answers a different (much weaker) question than
   uniformity "up to a fixed horizon T" as Hypothesis U's statement requires.
2. **Bounded/interval rational arithmetic.** After each step, round each `a_n` to a fixed
   denominator `D` (e.g. `D = 2^64`) and track a rigorous error interval using interval
   arithmetic propagated through the (Lipschitz, on bounded sets) IMEX map. This is still
   "exact" in the sense of *certified* — the true trajectory is bracketed, not approximated
   blindly — but it is a materially larger implementation than the current script and needs
   its own design memo and its own Lipschitz-constant derivation.
3. **Demote to Tier C with an explicit, permanent caveat**, and accept that no rigorous
   long-horizon uniformity measurement is currently reachable by this program's own standards.
   Use a stability-controlled float scheme (e.g. `mpmath` at high but finite precision) purely
   as steering data, exactly as D4 already does, and stop trying to certify D5 in ℚ.
4. **Reduce `T`.** Ask whether Hypothesis U's own `T` needs to be large — if the scientifically
   relevant horizon is short (e.g. a handful of eddy-turnover times), option 1 might already
   suffice honestly, without needing option 2's extra machinery.

## What is NOT in question

The **identity work is unaffected** — `EnstrophyProduction.lean`'s exact algebraic identity
does not depend on time-stepping at all; it is a statement about instantaneous rates, proven
for arbitrary states. This escalation only blocks the *numerical trajectory* measurement, not
the analytical attack, which is arguably now the more promising route (see
`docs/designs/TRACK_DEFINITIONS_DRAFT.md`'s note that Track T3 collapses into exactly this
production/dissipation competition).

## Smallest question that unblocks the `[any]` rerun

Which of options 1–4 above (or a combination — e.g. 1 now, 2 as a later Stage-1 deliverable)?

## Resolution — human owner decision, 2026-08-12

**Option 3 accepted.** D5's exact-rational certification is closed; no further attempt will be
made to certify the trajectory measurement in ℚ. Steering data (`exploration/dyadic_imex_dual_
precision.py`) is retained as permanent Tier C.

**Accepted follow-up before drawing any conclusion from the dual-precision divergences:**
re-run the diverging low-ν configurations at successively finer `dt` and check whether the
divergence survives refinement. Done: `exploration/dyadic_imex_dt_refinement.py`,
`data/dyadic_imex_dt_refinement.csv`. Result: all 4 distinct `(ν, profile)` pairs that diverged
flip to `status=OK` at a finite refinement level and stay `OK` at every finer level tested, with
`sup_Omega` decreasing (not diverging) as `dt` shrinks further — the signature of a
discretization artifact resolving under refinement, not a fixed-time genuine blow-up. Full
numbers and the standard reporting-discipline caveat (no verdict asserted; see PLAN.md §8): the
new LEDGER.md entry adjacent to the dual-precision row.

This escalation is now CLOSED. It does not need to be reopened unless a genuinely new
long-horizon Tier B measurement is attempted by some other method.
