# OP-2′ — the Sym² lock's exact 3-D content: planar confinement, not depletion

**Status: Tier C authoring, `[top]`, AWAITING HUMAN AUDIT.** Per PLAN §6 authorship never
unblocks anything. Unlike its three dead predecessors, this candidate was **screened before
submission** (LL-11 test, depletion screen, and an exact closure computation) and its central
classical ingredient is flagged for source verification (LL-6) rather than asserted.
**Author:** orchestrator (Fable tier). **Date:** 2026-08-14.

---

## 1. The diagnosis that produces the candidate

Three translations of the Sym² lock died on 2026-08-14 — pointwise (`a₂ₙ = c·aₙ²`), recurrence
signature, radial embedding. The post-mortem is not that the lock is empty. It is that **all
three searched for a *scarcity* mechanism (fewer resonances, smaller exponents) while the
lock's exact content is a *closure* mechanism.** The depletion screen quantifies the mismatch:
additively structured sets score `D > 1` — closure under addition **enriches** resonance
(sublattice `(2ℤ)³`: `D = 7.25`; a plane: `D = 1.87`). Hunting for depletion inside a closure
statement was looking for the mechanism with the wrong sign.

## 2. The exact 3-D statement (a Fourier identity, not a model)

Squaring a velocity field is the Sym² operation on its spectrum:

```
(e^{ik₁·x} + e^{ik₂·x})² = e^{2ik₁·x} + 2e^{i(k₁+k₂)·x} + e^{2ik₂·x}
⟹  Sym²{k₁, k₂} = {2k₁, k₁+k₂, 2k₂}
```

This is the *vector* statement whose radial shadow (`{2i, i+j, 2j}` on shell indices) was
measured to be a parity artifact. The radial projection is exactly where the content leaked out.

**Computed, exact (this repo, 2026-08-14):** the closure of a mode pair `{k₁, k₂}` under
repeated triadic interaction — 6 rounds, 2144 modes generated — contains **zero** modes outside
the 2-plane `⟨k₁, k₂⟩`. Trivially provable (`m·k₁ + n·k₂` stays in the plane), and now also
machine-checked on an instance.

> **The Sym² lock in 3-D is confinement of the spectrum to a two-dimensional sublattice.**
> A flow whose spectrum lies in a plane is a 2.5-D flow.

## 3. Why this is the first translation with actual content

- **It connects to a true theorem instead of a hoped-for estimate.** 2-D Navier–Stokes is
  globally regular (classical; Ladyzhenskaya lineage), and z-independent "2.5-D" flows form an
  invariant subspace of 3-D NSE on which vortex stretching vanishes. **[LL-6 flag: both facts
  are textbook-level but MUST be source-verified with exact statements before entering SPEC —
  in particular whether *every* plane sublattice, not just coordinate planes, yields an
  invariant subspace of the truncated Galerkin system. For coordinate planes it is standard;
  for tilted planes it should be checked by direct computation on `shellB`'s 3-D analogue, and
  that check is part of Step 1 below.]**
- **It explains all three deaths at once.** No depletion (planes are `D > 1`: the mechanism was
  never about triad counts — T1's frame was wrong, which is *why* T1 died); no dyadic shadow
  (a radial quotient of a planar confinement statement retains nothing — the plane's identity
  lives in the angular variables the quotient discards); no spontaneous Sym² structure in the
  cascade (see next point).
- **It explains the S-measurement.** The natural cascade showed no Sym² structure (`S ∼ O(1)`),
  and the lock's confinement reading predicts exactly that: 2-D invariant manifolds in 3-D
  turbulence are dynamically **unstable** at high Reynolds number, so generic trajectories flee
  the locked set. The lock is real and *repulsive* — present as geometry, avoided by dynamics.

## 4. The honest research question this produces

Not "does the lock deplete triads" (dead) but:

> **Q(OP-2′): is the planar-locked manifold dynamically attractive, neutral, or repulsive under
> the truncated 3-D Galerkin flow — and can any admissible modification make it attractive?**

The expected answer to the first half is *repulsive* (classical 3-D instability of 2-D flows).
That expectation is a feature: the experiment has a pre-registered null with a control on each
side —

- **positive control (theorem-backed):** exactly-planar data must remain exactly planar under
  the truncated flow (invariance); any drift is integrator error, measurable and boundable;
- **negative control:** generic 3-D data must show the planar distance growing.

The measurement is the growth rate `σ` of the out-of-plane energy fraction from near-planar
data. `σ > 0` uniformly ⇒ the lock is repulsive and the mechanism, as a route to regularity for
*generic* data, is *dead honestly* — with a number. `σ ≤ 0` anywhere in parameter space would be
a genuine discovery. Either outcome is a completed scientific result, per the charter.

## 5. Kill criteria and screen results (pre-registered, per LL-15: controls that can force a negative)

| # | Test | Kill condition |
|---|---|---|
| K1 | Invariance check: is every plane sublattice invariant under the truncated nonlinearity? | **PASSED 2026-08-14, exact arithmetic**: a field supported on the *tilted* plane `⟨(1,0,0),(0,1,2)⟩` has `N(u) = 0` on all 322 out-of-plane modes (Leray-projected nonlinearity, Gaussian-rational, `tier_b_nse_triad_convolution` machinery); in-plane dynamics alive on 20 modes; negative control (generic field) leaks on 322 modes, so the check can fail. Invariance holds for tilted planes, not only coordinate planes. |
| K2 | Positive control: planar data stays planar to integrator tolerance | fails ⇒ instrument broken, no measurement may be reported |
| K3 | The attractivity measurement (σ), across the regime map's bands, grid passed through `tier_b_grid_adequacy` | `σ > 0` everywhere incl. all admissible modifications tested ⇒ mechanism killed *for generic data*; record and stop |
| K4 | The LL-11 vacuity test, already run | **passed**: the constraint's solution set (plane sublattices) is a measure-zero, codimension-∞ subfamily of spectra — it is *not* satisfied by generic power laws, unlike all three dead forms |

## 6. What this is NOT

- Not a claim that 3-D NSE is regular, nor a step toward it for generic data unless K3 surprises.
- Not new mathematics in its invariance half — 2.5-D invariance is classical **[verify + cite]**;
  the candidate's novelty is only the *identification* of the Sym² closure with that manifold,
  plus the attractivity question asked quantitatively in the truncated system.
- Not exempt from audit. This document is the audit's input, structured so the audit can kill it
  at K1 without any computation being run.

---

# Companion result (separate, unconditional): the triad 2-section spectrum

While screening this candidate, the unconstrained triad hypergraph's 2-section was solved
**exactly on the torus** `(ℤ_m)³ \ {0}` (all sums stay in the group, so the ball-boundary
effects vanish):

```
A = 6(J − I) − 2P        (verified entry-by-entry at m=3)
```

`J` all-ones, `P` the involution `u ↦ −u`. Since `J` and `P` commute, the full spectrum is
three eigenvalues: Perron `6n−8`, then `−4` (odd vectors) and `−8` (even vectors). Normalised:
`{1, −4/(6n−8), −8/(6n−8)}` — **the torus gap tends to 1.**

Consequently the measured ball gap (M=2..5: 0.834985, 0.833575, 0.833419, **0.833392** —
deviations from 5/6 strictly decreasing: 1.7e-3, 2.4e-4, 8.6e-5, 5.9e-5)
is a **pure boundary invariant** of the sphere truncation — conjecturally the second eigenvalue
`1/6` of the continuum kernel `K(x,y) = 2·1_B(x+y) + 4·1_B(x−y)` on the unit ball. Open,
falsifiable (compute at larger `M`), and the torus half is **immediately Lean-able**: a finite
combinatorial identity plus commuting-operator linear algebra, no analysis required. It would be
the programme's first Tier A statement about the genuine `ℤ³` resonance structure.
