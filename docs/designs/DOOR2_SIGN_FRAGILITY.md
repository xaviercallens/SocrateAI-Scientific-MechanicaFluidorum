# Direction spec — Door #2: where does positivity actually do the work?

**Status:** `[top]` **direction specification only. Nothing here is implemented, and nothing
here may be implemented before the owner arbitrates §6.** This document states a question, the
pre-registration that governs any answer, and the kill criteria — in that order, deliberately,
because in this programme the order has been the difference between a result and an artifact.
**Author:** orchestrator. **Date:** 2026-08-25.
**Depends on:** `lean_src/DyadicRiccati.lean` (Tier A), `docs/designs/ALPHA_HALF_FORMALISATION.md`,
`docs/escalations/2026-08-15-E3b-band-is-narrower.md`.

---

## 1. Why this is the only door left

`DyadicRiccati.thetaStar_two_lt_iff` (Tier A) reduces the band below `α = 1/2` to a single
scalar deficit: refuting finite-time enstrophy blow-up needs `‖u‖^θ ∈ L¹_loc` with
`θ ≥ 2/(3 − 1/α)`, and the energy inequality supplies exactly `θ = 2`. Two doors follow.

**Door #1 — raise `θ` — is closed** for banded polynomial quartic invariants
(`docs/designs/QUARTIC_INVARIANT_SEARCH.md`): identity (Q1) shows energy is the *unique*
conserved weighted quadratic, and the exact search returns nullspace dimension zero in every
banded class.

**Door #2 — leave the Riccati route — is open, and this document is about it.**

## 2. The observation that makes Door #2 concrete rather than a slogan

Identity (Q1), derived and machine-checked:

```
d/dt H_γ  =  −2ν H_{γ+α}  +  2(λ^{2γ} − 1) · Σ_n λ^{(2γ+1)n+1} u_n² u_{n+1}
```

For `γ < 0` the prefactor `2(λ^{2γ} − 1)` is **negative**, so `d/dt H_γ ≤ 0` — a monotone family
of a priori bounds — **provided the sum `Σ λ^{(2γ+1)n+1} u_n² u_{n+1}` is non-negative**. It is,
for positive data, because `u_n² ≥ 0` and `u_{n+1} ≥ 0`. For sign-changing data `u_{n+1}` may be
negative and the sum has no sign at all.

**That single sign is where positivity does its work**, at least in this family. And it is not a
coincidence of our derivation: both theorems that bound the band assume positivity —
Cheskidov's blow-up theorem (Thm 5.3: `u_n(0) ≥ 0` **and** large data) and Barbato–Morandin–
Romito's regularity theorem (Thm A: `x_n ≥ 0` in `ℓ²`), the latter explicitly abandoning energy
methods for an *invariant-region* argument on the pair `(X_n, X_{n+1})` — a construction that
reads the signs directly.

> **The Door #2 question, stated once:** *is the positivity hypothesis load-bearing for the
> conclusion, or merely for the proof?* Equivalently: does the blow-up mechanism itself require
> coherent signs, or does it survive sign alternation?

Either answer is a result. If the mechanism is sign-fragile, the sign-changing band is
structurally different from the positive one and the literature's silence there is not an
accident. If it is sign-robust, then the positivity hypotheses are artifacts of technique and
the band is narrower than currently recorded.

## 3. Deliverable 1 — the theory memo (`[top]`, hand-derived first, LL-5)

**Target:** a line-by-line audit of the blow-up argument, answering for each inequality:
*does this step use `u_n ≥ 0`, and if so, how?* Three outcomes per step, and the memo must
classify every step into exactly one:

| Class | Meaning |
|---|---|
| **sign-free** | the step holds verbatim for sign-changing data |
| **sign-repairable** | positivity can be replaced by `\|u_n\|` or a Cauchy–Schwarz bound at a stated cost |
| **sign-critical** | the step genuinely fails, with an explicit sign-alternating counter-configuration |

**Definition of done:** every step classified; each *sign-critical* step accompanied by the
configuration that breaks it; the memo ends either with a sign-robust variant of the argument or
with the precise list of cancellation points that block one. **A memo that ends "it seems hard"
is not done.**

**Constraint (SPEC):** this audit may not invent a definition. Cheskidov's system, spaces, and
the exact statements of Thm 4.3 / 4.4 / 5.3 are quoted in
`docs/escalations/2026-08-15-E3b-band-is-narrower.md`; anything needed beyond them is an E-1
blocker to escalate, not a gap to fill.

## 4. Deliverable 2 — the companion experiment, **pre-registered here before it exists**

**Question, in one sentence:** at `α = 2/5` with sign-alternating data, does the cascade's
coherence — the thing a blow-up needs — survive a sign flip?

**Observable:** to be fixed *in the memo of §3*, not chosen after seeing data. The natural
candidate is the flux-alignment `Σ_n λ^{(2γ+1)n+1} u_n² u_{n+1}` itself, whose sign is the object
of the whole question, measured against its positive-data counterpart at matched enstrophy.

### 4.1 Controls — three, and the design is not admissible without them

- **POSITIVE, theorem-backed:** the positive-data column at `α = 2/5` is proved regular at
  *every* amplitude by BMR. It must read as regular however large the data. *This is the control
  that caught the last experiment's failure*, and it is not optional.
- **NEGATIVE, theorem-backed:** `α = 1/4` with large positive data must show blow-up.
- **NULL MODEL, computed before interpretation:** whatever the observable, its value under a
  structure-free surrogate at matched density/energy must be computed *first*. The σ experiment's
  apparent discovery was a linear spectral artifact caught exactly here.

### 4.2 Three hard requirements, each purchased with a real loss

These are not style notes. Each corresponds to a measurement this programme lost.

1. **Hypothesis guard (`require_hypothesis`, LL-17).** The run must **refuse to start** if the
   seed violates `u₀ ∈ V` — the enstrophy of `u_n = A·2^{−βn}` is finite only for `β > α`. A
   theorem-backed control is void when the run violates the theorem's hypotheses, and the failure
   then looks like a code defect.
2. **Stop-reason separation (`StopReason`/`Aggregate`, LL-18).** Physical divergence and
   compute-budget exhaustion must carry different names, and any aggregate containing a budget
   stop must **refuse to be interpreted**. The θ probe's entire large-amplitude sweep was lost to
   this exact conflation, and it announced blow-up in a column that is a *theorem*.
3. **Null model first (LL-14/LL-15).** No number is interpreted before its surrogate is computed.

### 4.3 Pre-registered kill criteria

- **Sign-robust:** if the observable behaves indistinguishably under sign alternation, across
  amplitudes, with all three controls green — Door #2 is *closed by this route*, positivity is an
  artifact of technique, and that is recorded as a negative result.
- **Sign-fragile:** if it differs materially where the positive column stays regular — that is a
  **candidate signal**, and it is **escalated, not concluded**. It becomes a theory question for
  §3's memo, never a claim on its own.
- **Inadmissible:** any run touching a compute-budget stop, or a positive control that fails,
  voids the block entirely. Report the void; do not repair and re-read.

## 5. What Door #2 is **not**

Not a claim that a route into the band exists. §2 states what a route would have to do; it does
not assert one is available. Not a revival of confinement: `FourierStateZ3.lean`'s
`sublattice_invariance` is geometry, the 2D3C manifold is *repulsive* by owner verdict, and
phase-space landmarks are bookkeeping, not mechanism. Not a Millennium claim: the object is a
dyadic shell model, and per `SPEC.md` a result here is about hypo-dissipative shell models and
**may never be reported as a step toward 3-D Navier–Stokes**.

And a scoping fact that must travel with any write-up: the residual *positive-data* band
`[1/3, 2/5)` sits at intermittency dimension `d ∈ [−1, 0)`, outside the physically relevant
range — the field's own survey says BMR settles the 3-D-relevant case. **The sign-changing band
is where the room is, and it is open below `1/2` because both bounding theorems assume
positivity — not because anyone has probed it and failed.**

## 6. Owner arbitration required before any work starts

1. **Go / no-go on §3** (the theory memo). It is the cheap half and it gates §4 — the experiment
   has no observable until the memo fixes one.
2. **Effort split.** The standing recommendation is 40 % Door #2 / 40 % the 5/6 paper / 20 %
   OP-6b, with OP-6b's first deliverable being the non-vacuity witness `B` (flag F1), not the
   vector field.
3. **Whether a candidate signal in §4 may be shared cross-stream before audit.** Stream 0 ranks
   narrative → publication as the highest-consequence surface in the programme; a sign-fragility
   result would be exactly the kind of finding that travels faster than its tier.
