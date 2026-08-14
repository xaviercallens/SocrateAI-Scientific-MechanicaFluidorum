# OP-2-lite — candidate implementations of the Sym² lock in shell space

**Status: Tier C authoring, AWAITING HUMAN AUDIT.** Under `PLAN.md` §6, authorship never
unblocks a track — only audit does. Nothing here may be implemented, cited, or measured until a
row below is marked AUDITED in `LEDGER.md`. This document is that audit's *input*.
**Author:** orchestrator (`[top]`, not delegated — `LL.md` LL-5: agents asked to *derive* rather
than *execute* do worse, and this is derivation).
**Date:** 2026-08-14. **Responds to:** the owner's review item 2.

---

## 1. Why a 1-D version of the lock is possible at all

Track T1 has been blocked on OP-2 — an embedding of the Sym² lock into 3-D Fourier dynamics on
`𝕋³` — which does not exist in this programme or, as far as we know, in the literature. The
owner's observation removes the need to wait for it:

> In the dyadic model `k_n = 2ⁿ`, so the spectral map `λ ↦ λ²` acts on **indices** as `n ↦ 2n`.

This is exact, not analogical. The Sym² lock (proven, Tier A, `sym2_recurrence`) sends
characteristic roots `{λ, μ} ↦ {λ², λμ, μ²}`. Under `k_n = 2ⁿ`, squaring a wavenumber doubles
its index: `k_n² = 4ⁿ = k_{2n}`. So in shell space the lock is a constraint coupling shell `n`
to shell `2n`.

**Why that is interesting, and the O1 compliance note nearly for free.** Generic cascade models
— including the shell models this programme studies — couple only *neighbouring* shells
(`n−1, n, n+1`). A constraint coupling `n` to `2n` is **non-local in scale**. Tao's construction
(obstruction O1) works by choreographing *local* cascade steps so that energy is handed
upward in a coordinated way; a rigid non-local constraint is exactly the kind of structure such
a choreography must fight. That is the honest form of the O1 answer: *the mechanism uses a
scale-non-local algebraic constraint, which is not available to an averaged system built from
local transfer alone.*

**What this is NOT.** It is not OP-2. It does not embed anything into `ℤ³`, does not recover
angular structure, and says nothing about 3-D. It is a lock for the *dyadic target the programme
now actually has* (post-pivot). If it works, OP-2 remains open; if it fails, OP-2 is not thereby
refuted.

---

## 1a-BIS. ⚠ A BLOCKING objection, found on paper 2026-08-14 — read before §1b

**The shell-space constraint is blind to the spectral slope, which is the quantity blow-up is
made of.**

Take any pure power law `aₙ = A·rⁿ` (with `r = 2^{-θ}`, so `θ` is the spectral slope; K41 is
`θ = 1/3`). Then

```
aₙ²  = A² r^{2n}          a₂ₙ = A r^{2n}          ⟹   a₂ₙ / aₙ²  =  1/A
```

The ratio is `1/A` — **constant in `n`, and independent of `r`, hence of `θ`.** Verified
numerically across `θ ∈ {0.05, 0.10, 0.20, 1/3, 0.5}` and `A ∈ {1, 2}`: the ratio is exactly
`1/A` in every case.

**Consequence.** The functional equation `a₂ₙ = c·aₙ²` restricted to geometric sequences has as
its solution set the *entire one-parameter family of power laws* with amplitude `A = 1/c`. It
imposes **one** condition on a **two**-parameter family, and the parameter it fixes is the
**amplitude**, not the slope.

Finite-time blow-up in dyadic models is characterised by the *slope* — self-similar solutions
`aₙ ∼ kₙ^{-θ}` with `θ` below a critical value, so that nonlinear transfer outruns dissipation.
**A constraint that leaves `θ` entirely free cannot, at leading order, prevent such a blow-up.**
It is satisfied identically along the whole blow-up family.

**Honest limits of this objection.** It is a leading-order, self-similar argument, not a theorem:
(i) real blow-up profiles carry corrections to pure power-law scaling, and the lock does act on
those deviations; (ii) fixing the amplitude `A = 1/c` is not vacuous and could matter
dynamically; (iii) the constraint is imposed at all `n` simultaneously, whereas the argument
above checks a single family. So this does not *prove* the lock is inert — but it removes the
mechanism by which it was hoped to work.

**Recommendation to the auditor: treat this as a kill unless it can be answered.** The cheapest
possible answer is analytic, not computational: exhibit a blow-up profile the constraint
excludes, or show the constraint bounds `θ` from below. If neither can be produced, OP-2-lite
should be killed on paper, at zero compute cost — which is the outcome the pre-registered
protocol was designed to make possible.

---

## 1b. A prediction the auditor should know BEFORE approving any run (added 2026-08-14)

The constraint `a_{2n} = c·a_n²` is **not arbitrary — it is exactly Kolmogorov-compatible.**
Under K41, `a_n ∼ k_n^{-1/3} = 2^{-n/3}`, hence

```
a_n²    ∼ 2^{-2n/3}
a_{2n}  ∼ 2^{-(2n)/3} = 2^{-2n/3}      ← the same exponent
```

so a K41 cascade *already satisfies the Sym² relation*, with an O(1) constant. Measured on this
programme's own shell runs (`ν=0.001`, profile P1, inertial range): peak amplitudes track
`2^{-n/3}` to within 15–20% for `n = 2..6`, and `a_4 / a_2² ≈ 1.31`, i.e. `c ≈ 1.3`.

**Why this must be settled before the experiment, not after.** It cuts both ways and determines
what the measurement can possibly show:

- **If the natural cascade already satisfies the constraint**, a penalty term (Candidate C) is
  near-zero on physical states, and `β(γ)` will come out **flat — for a reason that has nothing
  to do with the lock being powerless.** Reading that flatness as "the lock buys no exponent"
  would be a false negative, and the pre-registered kill criterion in §3 would fire wrongly.
- Conversely, the lock's real content cannot be in the mean inertial-range scaling, which it
  reproduces by construction. It must be in the **deviations** — intermittent excursions where
  `a_{2n}` departs from `c·a_n²`. That is precisely where finite-time blow-up would live in a
  shell model, and precisely what a rigid algebraic constraint would suppress.

**OWNER DECISION 2026-08-14: measure BOTH.** `β(γ)` serves as the *expected negative control* —
if the K41 analysis above is right it must come out flat, so a non-flat `β(γ)` would indicate the
implementation is perturbing something other than the lock. `D(t)` carries the actual signal.
Agreement between the two validates the instrument; disagreement invalidates the run rather than
producing a finding.

**Consequence for the protocol.** The primary observable should not be the mean exponent
`β(γ)` alone. It should include a measure of the *deviation* the lock actually acts on, e.g.
`D(t) = max_n |a_{2n} − c·a_n²|` and its excursions, recorded at `γ = 0` (control) and under
each candidate. **Recommend the auditor rule on this before any run is dispatched**, since it
changes the kill criterion from "β flat ⇒ kill" to "β flat AND deviations unsuppressed ⇒ kill".

---

## 2. The three candidates

Notation: shells `n = 0..N`, wavenumbers `k_n = 2ⁿ`, amplitudes `a_n(t)`, the unmodified
dynamics `da_n/dt = shellB_n(a) − ν k_n² a_n` (`DyadicShell_Statements.shellB`, Tier A energy
conservation `shellB_energy_conservation`).

### Candidate A — hard constraint (`a_{2n} = c · a_n²`)

Impose `a_{2n}(t) = c · a_n(t)²` for all `n` with `2n ≤ N`, for a fixed constant `c`, as an
*exact* algebraic constraint on the state manifold; evolve only the free coordinates
(odd indices and those `n` with `2n > N`), deriving the constrained coordinates' motion by
differentiating the constraint.

- **Faithful to:** the lock as literally proven — `v_n = u_n²` is exactly the Sym² relation.
- **Cost:** the constrained system is *not* the shell model any more. Energy conservation
  (`shellB_energy_conservation`) is destroyed unless the constraint happens to be compatible
  with it, which it is not in general. **This is the candidate's principal danger**: it changes
  the dynamics rather than restricting the state, so a measured change in `β` could be caused by
  the loss of energy conservation rather than by the lock.
- **Kill criterion:** if the constrained system violates `Σ a_n · (da_n/dt)|_nonlinear = 0` by
  more than round-off in exact arithmetic, this candidate is measuring the wrong thing —
  **kill**, do not "repair" by adding a compensating term (that would be inventing dynamics).
- **Recommended:** implement the energy check *first*, as a Tier B harness, before any
  trajectory is run.

### Candidate B — projection onto the Sym² manifold

Evolve the unmodified shell model for one step, then project the state onto the manifold
`M = { a : a_{2n} = c·a_n² }` in the enstrophy norm, and repeat (a Lie–Trotter splitting between
the dynamics and the constraint).

- **Faithful to:** "the lock restricts which states are reachable", without rewriting the vector
  field.
- **Cost:** the projection is a *numerical* operation with no derivation behind it; the result
  depends on the splitting step size in a way that is not a discretisation error of any
  continuum system. It is honest only as an *instrument*, never as a model.
- **Kill criterion:** if the measured exponent depends on the splitting step `Δt_proj` in the
  limit `Δt_proj → 0` (i.e. does not converge), the construction has no continuum meaning —
  **kill**.
- **Note:** this is the only candidate for which the "positive control" discipline is
  immediately available: with `c = 0` the projection kills all even shells, which should
  *increase* dissipation and give a clearly bounded result. If it does not, the instrument is
  broken.

### Candidate C — soft penalty (recommended for the first measurement)

Add a restoring term pulling the state toward the Sym² manifold:
`da_{2n}/dt ⊃ −γ (a_{2n} − c·a_n²)`, with penalty strength `γ ≥ 0`.

- **Faithful to:** nothing exactly — it is a deformation, and must be labelled as one.
- **Why it is nonetheless the best first experiment:** it is the only candidate with a
  **continuous knob**. At `γ = 0` it is *exactly* the unmodified shell model, whose behaviour is
  already measured; as `γ` grows the constraint tightens. So it yields a *curve* `β(γ)` rather
  than a single number, and the question "does the lock buy exponent?" becomes "is `dβ/dγ ≠ 0`
  near `γ = 0`?" — which is far more robust than comparing two separately-implemented systems,
  because the `γ = 0` end is a built-in control that shares every line of code with the
  measurement.
- **Kill criterion:** `β(γ)` flat in `γ` across the whole tested range ⇒ the lock buys nothing
  in shell space ⇒ **kill OP-2-lite** (and report it; a negative here is informative about the
  mechanism, not merely about the implementation).
- **Cost:** `γ` is a free parameter with no principled value; results must be reported as a
  curve, never at a single hand-picked `γ`.

---

## 3. Pre-registered protocol (per the owner's review item 1 — fixed *before* any run)

Stated now so the fit cannot be tuned after seeing the data:

- **Exponent definition:** `β` from `sup_t Ω ∝ α'^β` (equivalently in `N`, via `α' ≈ 4^{−N}`).
- **Fit window:** the largest contiguous range of `N` in which *all* configurations completed
  without tripping the magnitude guard. Fixed before the run; **no post-hoc trimming.**
- **Inclusion criterion:** a configuration enters the fit only if it reaches the full horizon at
  two successive `dt` refinements with `sup Ω` agreeing to within 1%. Configurations failing
  this are reported as excluded, **with their count**, never silently dropped.
- **Thresholds, pre-registered:** `β = −2/3` ⇒ no effect (the measured control value).
  Any `β > −2/3` beyond fit uncertainty ⇒ real signal. `β ≈ 0` ⇒ compatible with the dyadic
  Hypothesis U. **Amended 2026-08-14:** per §1b, `β` flat is now the *predicted* outcome and is
  not by itself a kill; the kill criterion is `β` flat **AND** `D(t)` excursions unsuppressed.
- **Grid adequacy is a precondition** (added 2026-08-14): any grid used here must pass
  `tests/tier_b_grid_adequacy.py`. The uniformity campaign's grid had **zero** detection power
  and this must not recur — see `docs/designs/D6_CUTOFF_BITING_MEASUREMENT.md`.
- **O5 (Euler test), mandatory:** re-run at `ν = 0`. **If the lock alone yields `β = 0` at
  `ν = 0`, treat the result as presumptively wrong** — it would "prove" regularity for the
  inviscid dyadic model, where finite-time blow-up is a published theorem (Katz–Pavlović 2005).
  This is a falsification trap deliberately set for our own mechanism.
- **Positive control, mandatory before any headline number:** the Cheskidov regime (dissipation
  degree ≥ 1/2, regularity known) must read as bounded. An instrument never shown to register a
  known-bounded case cannot be believed when it reports boundedness.

---

## 4. Recommendation to the auditor

**Audit Candidate C first and, if approved, run only C for the first measurement.** Reasons:
its `γ = 0` end is a control sharing all code with the measurement; it produces a curve rather
than a point; and it cannot silently destroy energy conservation the way A can.

**Candidate A should be audited but not run until its energy check passes** — it is the most
faithful to the proven lock and therefore the most interesting if it survives, but it is also
the one where a positive result would be most likely to be an artifact of broken conservation.

**Candidate B is the weakest scientifically** (no continuum meaning) and is recommended only as
a cross-check on C, not as a primary measurement.

**A negative result from C is a publishable, programme-relevant finding** and should be treated
as a successful outcome, per the campaign's Definition of Done.

---

## 5. What this document does not do

No code is written. No definition here is implemented, and none may be until audited. No claim
is made that any candidate *is* the Sym² lock in the sense of `sym2_recurrence` — A is exact on
the constraint but changes the dynamics, B is an instrument, C is an explicit deformation. That
distinction is the single most important thing for the auditor to rule on: **which, if any, of
these is entitled to be called "the lock" in a reported result.**
