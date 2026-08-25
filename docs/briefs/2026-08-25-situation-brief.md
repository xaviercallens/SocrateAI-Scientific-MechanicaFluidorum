# Situation brief — 25 August 2026 (release v1.4.0)

**Audience:** the human owner and any external auditor picking the programme up cold.
**Status of this document:** summary only. It creates no claim; every statement below is
sourced to a `LEDGER.md` row, a Lean file, or a harness, and where it says *open* it means no
tier has been granted. **Author:** orchestrator. **Verified against:** commit `15f9a23`,
both gates exit 0.

---

## 1. One paragraph

The programme's formal core is healthy and growing: **93 kernel-verified theorems across nine
Lean files**, all with clean axiom footprints, plus **twelve Gate-1 harnesses** in exact
arithmetic. Since the external audit of 13 August the target has been the truncated viscous
Katz–Pavlović dyadic shell model rather than Navier–Stokes itself, and that pivot is holding.
This cycle produced two genuine mathematical results — *why* the dyadic regularity threshold sits
at `α = 1/2`, and half of the 5/6 ball-gap conjecture — and **closed two lines of attack with
evidence**: the OP-2′ planar-confinement mechanism (owner verdict) and door #1 of the barrier
below `α = 1/2` (exact search). One line remains open and is the natural next target. The
cycle's most transferable output may be methodological: three separate publishable-looking
numbers were each caught as artifacts, none by review, all by pre-registered controls.

## 2. Verified state

| Artifact | Content | Tier | Thms |
|---|---|---|---|
| `CallensDualScale.lean` | T-dual `Reff` laws, Sym² lock, sharpness | A | 14 |
| `DyadicShells.lean` | Energy-flux telescoping, monotonicity | A | 3 |
| `DyadicShell_Statements.lean` | Shell-model Hypothesis U; concrete `shellB` (**draft**) | A | 16 |
| `EnstrophyProduction.lean` | Exact enstrophy-production identity | A | 11 |
| `EnstrophyProductionBound.lean` | Local bound `S_N² ≤ 2Ω_N³` | A | 15 |
| `AbstractAlgebraicConservation.lean` | Abstract triad conservation, transversality | A | 7 |
| `TriadTorus.lean` | Triad 2-section on a torus: `A = 6(J−I) − 2P`, spectrum | A | 7 |
| `DyadicRiccati.lean` | The `α = 1/2` threshold as an integrability threshold | A | 13 |
| `MillenniumReduction.lean` | Conditional reduction skeleton (**demoted**, audit B1) | C | 7 |

**86 Tier A + 7 demoted = 93**, no axiom outside `{propext, Classical.choice, Quot.sound}`,
zero `sorry`. Gate 1: `controls.py` self-test plus eleven exact-arithmetic harnesses, each with
a control demonstrated to fail.

## 3. What was settled this cycle

### 3.1 Why the threshold is `1/2` (new, Tier A)

Carrying `α` symbolically through Cheskidov's argument instead of fixing the constant shows it
is used **once**, and that what it buys is not an estimate but an *integrability threshold*:

```
¬ IntegrableOn (fun x => x ^ (−ρ(α))) (Ioo 0 T)   ↔   α ≥ 1/2 ,      ρ(α) = 3 − 1/α
```

The energy inequality supplies `‖u‖² ∈ L¹_loc` and nothing more, so a finite-time enstrophy
blow-up is refuted exactly when the Riccati rate is non-integrable. Above `1/2` it is; below it
the rate is integrable, the energy inequality sees nothing, and there is no contradiction to be
had. **Scope, stated in the file header and the ledger: this is not Cheskidov's Theorem 4.4** —
no bilinear estimate, no local existence, no Galerkin approximation, no limit passage.

### 3.2 The barrier, quantified — and door #1 closed

Refuting blow-up needs `‖u‖^θ ∈ L¹_loc` with `θ ≥ 2/(3 − 1/α)`; the energy inequality gives
exactly `2`, and the deficit opens precisely below `α = 1/2` (`θ = 4` at `α = 2/5`; `θ = 14` at
`α = 7/20`). Two doors: raise `θ`, or leave the Riccati route.

**Door #1 is closed.** Identity (Q1),
`d/dt H_γ = −2ν H_{γ+α} + 2(λ^{2γ} − 1)·Σ λ^{(2γ+1)n+1} u_n² u_{n+1}`,
has a nonlinear prefactor vanishing only at `γ = 0`: **energy is the unique conserved weighted
quadratic**, so `θ = 2` is the entire quadratic supply and raising it genuinely requires leaving
degree 2. An exact rational search for conserved quartics — diagonal, neighbour, and all banded
classes up to 75 monomials — returns **nullspace dimension zero everywhere**.

*Closure scope:* it does not reach quartics that are monotone without a polynomial certificate,
non-polynomial quantities, quantities conserved only on invariant subsets, or door #2.

A side-consequence of (Q1) matters strategically: for `γ < 0` with **positive** data the
prefactor is negative and the sum non-negative, giving a monotone family. That is exactly where
positivity does its work in the published literature, and exactly what sign-changing data lacks.

### 3.3 The 5/6 ball conjecture — half proved

The exact ball weight `A_M(u,v) = 2·[u+v ∈ Λ_M] + 4·[u−v ∈ Λ_M]` makes the continuum kernel
**derived rather than conjectured**, and specialises to `TriadTorus.lean`'s `A = 6(J−I) − 2P`
(torus gap → 1), so the ball value is a pure boundary invariant. The **odd sector** carries the
second eigenvalue, and linear functionals are *exact* eigenfunctions with eigenvalue `½` — hence
**the gap is ≤ 5/6 with an explicit witness**. Numerics: deviations from 5/6 fall monotonically
`1.7e-3 → 1.5e-5` over `M = 2..7`.

**Open half:** that `½` is the *largest* odd eigenvalue. Attack plan is dispatch-ready in
`docs/designs/BALL_SPECTRAL_PROBLEM.md` §5 (spherical-harmonic blocks, exact rational Rayleigh
upper bounds per block).

### 3.4 OP-2′ — killed by owner verdict (15 August)

The fourth translation of the Sym² lock: the lock's exact 3-D content is confinement of the
spectrum to a 2-plane, i.e. a 2D3C flow. K1 verified the invariance in exact arithmetic
including *tilted* planes. The attractivity measurement returned excess `σ − σ_lin > 0` at all
six points on both planes — the manifold is real, exactly invariant, and **repulsive**,
increasingly so as viscosity falls. The mechanism died *with a number and with its mechanism
understood*, unlike its three predecessors.

Not killed, and recorded as such so the verdict cannot be over-read: the geometric half (the
lattice/Galerkin form of the invariance appears unpublished), the torus theorem, and the 5/6
conjecture.

## 4. Corrections issued this cycle

Two of this repository's own statements were found wrong and retracted before they could
mislead. Both are recorded at the same prominence as the claims they replace.

- **E-3b — the open band was mis-stated.** Barbato–Morandin–Romito closed `α ∈ [2/5, 1/2)` in
  2011 for *positive* data. Both bounding theorems assume positivity, so there are **two** bands:
  positive data open on `[1/3, 2/5)` (which sits at intermittency `d ∈ [−1,0)`, outside the
  physically relevant range); **sign-changing data open below `1/2`, which is where the genuine
  room is**. The Tier B gate encoding the thresholds had the error inside its own *positive
  control*, and it passed cleanly for a day.
- **PRST 1994 scoped down.** A first-pass source report claimed the 2D3C manifold has a published
  global-regularity neighbourhood. A full read narrowed it: the threshold is Gronwall-exponential
  (not quantitatively usable), the 2-D application is ℝ² two-component only, and no periodic-`T³`
  case is treated.

## 5. Methodological finding

Three times in one cycle a pre-registered control turned a publishable-looking number into a
caught artifact:

1. a `σ` measurement whose negative sign was a **linear spectral artifact** (closed-form null
   model);
2. the mis-stated regime band (the wrong threshold lived inside the gate's own positive control);
3. a `θ` sweep whose "blow-up signature" was the integrator's **compute budget**, caught because
   the theorem-backed positive control — a column BMR proves regular — failed.

**None was caught by review; all three by controls — and two of those controls were themselves
defective at first.** In this domain the artifact rate for uncontrolled measurements appears
close to one.

The response was not another prose rule. `LL.md` now carries LL-16…LL-19 and a synthesis table
naming the four ways a passing control is still worthless (wrong premise; violated hypothesis;
ambiguous instrument state; undemonstrated perturbation), `SPEC.md` §7.3 was amended with the
five resulting normative rules, and the mechanisable half became code: `tests/controls.py`
(`require_hypothesis`, `StopReason`/`Aggregate`, `demonstrated_negative`, `cite_threshold`),
self-tested in both directions and running in Gate 1.

## 6. What is emphatically not established

Hypothesis U in any form; any statement about actual Navier–Stokes solutions; any claim that the
formalisation reduces or restates the Millennium problem (retracted 2026-08-13, verdict D1); the
Sym² lock's relevance to the NSE cascade (four translations proposed, four killed); statement
adequacy of the two `draft` files; and any bound in the band below `α = 1/2`. The θ probe
produced **no numerical evidence in either direction** there.

## 7. Live directions, in order of promise

1. **Door #2 — leave the Riccati route** for sign-changing data below `α = 1/2`. The only door
   still open, and the region the literature does not reach because both bounding theorems assume
   positivity. Cheskidov himself flags `α = 2/5` as carrying the *same* enstrophy estimate as
   3-D NSE.
2. **The 5/6 conjecture's remaining half** — self-contained, dispatch-ready, and independent of
   the NSE question.
3. **Thm 4.4's analytic half** — known mathematics; the real cost is infinite sums and the
   Galerkin existence theory, not the differential inequality.

## 8. Owner-side actions pending

- `IsGalerkinLimit` four-clause statement-adequacy audit.
- Statement-adequacy audits of the two files still marked **draft**.
- No verdict is outstanding: the K3/OP-2′ verdict was signed 15 August.

---

*Pointers:* `LEDGER.md` (claim inventory — a claim not listed there has no tier), `SPEC.md`
(normative rulebook), `LL.md` (lessons, with the control-failure synthesis), `docs/designs/`
(pre-implementation derivations), `docs/escalations/` (E-3b band correction),
`docs/report/mechanica_fluidorum_report.pdf` (full technical report).
