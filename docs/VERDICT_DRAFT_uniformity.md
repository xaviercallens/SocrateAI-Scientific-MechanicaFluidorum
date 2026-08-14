# DRAFT verdict — cutoff-uniformity of the dyadic enstrophy bound

> ## ⚠ RECOMMENDATION CHANGED 2026-08-14 — DO NOT SIGN AS DRAFTED
>
> Reservation 3 below was tested and **confirmed as a blocking defect**, not a caution. Direct
> measurement of shell amplitudes shows the cascade never populates the shells the grid varies:
> the highest shell with `peak |a_n| > 1e-12` is **n=8** at `ν=0.01` and **n=10** at `ν=0.001`,
> while the grid tests `N ∈ {8,12,16,20,24}`. The added shells are numerically **zero**, so
> "flat in `N`" is close to a tautology and the bit-identical agreement is the signature of a
> measurement with no power rather than of a strong result. See `LEDGER.md`'s correction block.
> **The experiment must be redesigned (cutoffs *below* the dissipation shell) before any verdict
> is meaningful.** §3's candidate text is retained only as a record of what was almost signed.

**Status: DRAFT, prepared by the executing agent for the human owner. NOT a verdict.**
Under `SPEC.md` §8 and `PLAN.md` §2, verdicts are issued by the human owner only; agents deliver
data. This file exists so the owner edits or rejects a concrete paragraph rather than composing
one from raw CSVs. **Nothing here may be cited until the owner signs and moves it into
`LEDGER.md` with a date.**

---

## 1. Why this verdict is worth more after the pivot than before

Before the audit, the dyadic runs measured a toy model used as a *proxy* for 3-D Navier–Stokes;
any verdict would have carried the proxy's whole epistemic discount. After the pivot
(`docs/Memo 1.md` §3), the truncated viscous Katz–Pavlović system **is** the programme's formal
target. **The same data now bears directly on the object of study.** No computation was redone;
the interpretation changed under it because the claim it supports got smaller and honest.

## 2. The evidence, as it stands

| Source | Finding |
|---|---|
| `data/dyadic_omega_sup.csv` (D4, float RK4) | Every completed `(ν, profile)` pair agrees between `N=8` and `N=12` to ≲0.1% (e.g. `ν=0.001,P1`: 70.8796 vs 70.8859). 21/36 configs were computationally infeasible (stiffness). |
| `data/dyadic_imex_dual_precision.csv` (float64 + mpmath-50) | Full grid `N∈{8,12,16,20,24}`. 44 of 45 configurations **bit-identical** in `sup Ω` across every `N`. |
| `data/dyadic_imex_dt_refinement.csv` | All 4 diverging low-ν pairs flip to `OK` at finite `dt` refinement and stay `OK`, with `sup Ω` *decreasing* as `dt→0` (e.g. 45.1 → 21.8 → 17.3 → 15.8) — the signature of a discretisation artifact resolving, not a fixed-time blow-up. |
| The one apparent exception | `ν=0.1, P2` appeared to grow linearly in `N` (4.5, 6.5, …, 12.5). Traced by hand: this equals `½(N+1)`, profile P2's **analytic initial** enstrophy — P2 excites every retained mode by construction, so a larger cutoff starts with more enstrophy independent of any dynamics. The trajectory collapses immediately from `t=0` and decays thereafter. **An initial-data artifact, not dynamical growth.** |

## 3. Candidate verdict text (edit or reject)

> **Verdict U-1 (cutoff-uniformity, dyadic shell model), issued <DATE> by <OWNER>.**
> Across every configuration tested — `N ∈ {8,12,16,20,24}`, `ν ∈ {0.1, 0.01, 0.001}`, three
> fixed initial profiles, horizon `T=10` — the measured `sup_t Ω_N(t)` of the truncated viscous
> Katz–Pavlović system shows **no growth with the cutoff `N`** once step-size resolution is
> adequate and initial-data effects are accounted for. The single apparent exception is
> explained as an initial-data artifact of profile P2 and is not dynamical.
>
> **Tier C.** This is a floating-point measurement of a *specific discrete IMEX-Euler scheme*,
> not of the continuum shell model and not of Navier–Stokes. It is consistent with the dyadic
> analogue of Hypothesis U and constitutes **no evidence whatsoever** for Hypothesis U in 3-D.
> It does not distinguish "uniformly bounded" from "growing too slowly to detect on this grid".
>
> **What would overturn it:** a configuration outside the tested grid — larger `N`, smaller `ν`,
> or an initial profile concentrating energy at high shells — exhibiting `sup Ω` growth that
> survives `dt` refinement.

## 4. Reservations the owner should weigh before signing

These are reasons to *weaken or refuse* the verdict, stated because a draft that only argues
for itself is useless:

1. **`ν` and `N` are not independent in the tested grid.** The low-ν configurations are exactly
   the ones that needed `dt` refinement. "Flat in `N`" is best supported where dissipation is
   strong — which is also where flatness is least surprising and least informative.
2. **`T=10` is short**, and uniformity is an asymptotic-in-`N` claim. Nothing here probes
   `N > 24`. The exponential wavenumber `k_n = 2ⁿ` means `N=24` already spans a huge range, but
   "no growth over 5 values of `N`" is a weak base for an asymptotic statement.
3. **Bit-identical results across `N` deserve suspicion, not comfort.** 44/45 configurations
   agreeing *exactly* is consistent with genuine `N`-independence (modes above the active range
   contribute nothing), but it is also what a bug that silently ignores high modes would
   produce. *Recommended before signing:* confirm that high shells are genuinely populated and
   dynamically active in at least one run, rather than numerically zero throughout.
4. **The positive control has not been run** (the owner's own instrument principle): the
   Cheskidov regime with dissipation degree ≥ 1/2, where global regularity is known, should read
   as bounded. An instrument that has never been shown to register a known-bounded case cannot
   be fully trusted when it reports boundedness.

**Recommendation:** reservation 4 is cheap to close and materially strengthens the verdict;
reservation 3 is cheap and would close a real failure mode. Both are worth doing *before*
signing rather than after. Reservations 1–2 are inherent scope limits and belong in the
verdict's text, which the draft above already does.
