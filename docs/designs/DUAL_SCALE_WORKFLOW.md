# The dual-scale programme: work packages, model tiers, and the human gates

**Status: PROPOSAL, for the owner's approval.** Requested 2026-09-10 ("propose a workflow with
appropriate model tier — Haiku, Opus, Fable — and say when human / Deep Think discussion is needed
to progress"). **Author:** Fable. Nothing below overrides `SPEC.md`, `PLAN.md`, or rule E-1.

---

## 0. The one clarification that shapes everything

`docs/HYPOTHESIS_U_SPECIFICATION.md` §3.1 identifies the T-dual regularization at the PDE level
with the frequency projection `J_{√α′}` onto `|k| ≤ 1/√α′`. **So the Galerkin system this
repository has been formalising IS the α′-regularized system**, under the correspondence
`M ↔ 1/√α′`, and Hypothesis U is exactly the statement that the enstrophy bound is **uniform in
that correspondence**. Two consequences:

1. Everything proved about the truncated system (energy conservation, the enstrophy production in
   closed form) is *already* about the regularized object. No separate "regularized operator"
   needs inventing — which is good, because E-1 would forbid inventing it.
2. The entire remaining difficulty is **uniformity in `M`**. SPEC obstruction O5 is the standing
   guard: at fixed `M` the system is regular by an elementary argument, so any result that does
   not control the `M`-dependence uniformly proves nothing about the limit.

## 1. The goal chain, honestly stated

```
   [DONE]  the regularized (truncated) operator B, Tier A, with witnesses
   [DONE]  energy conservation of B — global-in-time energy bound at each fixed M
   [DONE]  enstrophy production in exact closed form — the obstruction localised to (|r|²−|q|²)
   [WP-1]  the viscous balance laws: energy dissipation, enstrophy balance   ← unblocked, formal
   [WP-2]  how the production actually scales with M, measured with controls ← unblocked, empirical
   [WP-3]  a uniform-in-M mechanism                                          ← BLOCKED on ideas,
                                                                               not on effort
   [WP-4]  Millennium reduction (spec §II): compactness, Prodi–Serrin, blow-up criterion
                                                                             ← classical PDE, paper
                                                                               mathematics first
```

WP-3 is the Millennium-hard step. No workflow makes it routine; what a workflow can do is make
sure everything around it is exact, audited, and does not quietly overclaim.

## 2. Model tiers — who does what, and why

The assignment principle: **the cost of a wrong statement is what sets the tier, not the size of
the task.** A failed proof is cheap (the kernel catches it); a wrong statement is expensive (only
a human audit catches it); a wrong definition is fatal (everything downstream is about the wrong
object).

| tier | work it should do | work it must NOT do |
|---|---|---|
| **Haiku** | mechanical, verifiable-by-gate: run `verify.sh` and report; LaTeX builds; ledger/count refreshes; data `.meta` sidecars; formatting; re-running existing harnesses on new parameters; porting a finished exact algorithm to Rust for scale | anything that writes a claim, a proof, a definition, or prose that could be cited |
| **Opus** | implementation from a **fully-specified memo**: Lean proofs whose derivation is written and hand-checked (the Task 2.2 pattern); new Tier B harnesses from a written spec; negative-control mechanics; reindexing bridges; exploration solvers | authoring statements or definitions; deciding what a result means; amending a memo it is implementing (deviations get reported, as Task 2.2's Leray-drop simplification was) |
| **Fable** | derivations and memo authorship; statement design; cross-tier consistency audits (the resonance quantifier gap was exactly this); refutation-sensitive readings; adversarial review of incoming claims; deciding *what to check* | inventing definitions the spec lacks (E-1 binds every tier); issuing verdicts (owner-only); force-pushing (D-1) |
| **Human owner** | definitions (E-1); statement-adequacy audits; arbitration; verdicts and tier promotions; strategy | — |
| **Deep Think** | adversarial review of memos before Lean is written (the existing review-packet channel); the WP-3 strategy discussion; independent derivation of anything Fable derived alone | — |

Standing rules that already exist and continue to bind every tier: memo before Lean; negative
controls demonstrated to fail; null models before interpretation; self-reports are not evidence;
`git add` by explicit path; no `sorry`, ever, including "temporarily".

## 3. The work packages

### WP-1 — the viscous balance laws (Opus-tier execution, this memo is the derivation)

The truncated Navier–Stokes right-hand side is `F_k = −ν|k|² u_k + B(u,u)_k` — the dissipation of
spec Definition 1.1 plus the Task 2.1 operator; the pattern mirrors `DyadicShells.energyRate`,
already Tier A for the shell model. The two balance laws are one-line corollaries of what is now
proved, and putting them in the kernel completes the "fixed-M laboratory":

* **Energy dissipation.** `Re Σ_k ⟨u_k, F_k⟩ = −ν Σ_k |k|² ‖u_k‖²  ≤ 0` for `ν ≥ 0` — by
  `energy_conservation`, the nonlinearity contributes nothing, so the energy of the regularized
  system can only fall. (Derivation: pairing is additive in its second argument; the dissipation
  term pulls out as `−ν|k|²·‖u_k‖²` with `‖u_k‖² = Σᵢ normSq`, real and nonnegative; the `B` term
  has vanishing real part by Task 2.2.)
* **Enstrophy balance.** `Re Σ_k |k|²⟨u_k, F_k⟩ = −ν Σ_k |k|⁴ ‖u_k‖² + Re Σ_k |k|²⟨u_k, B_k⟩` —
  dissipation against production, with the production now in exact closed form. **Nothing bounds
  the production term.** That sentence is the entire open problem, and the theorem should carry it
  in its docstring.

Negative controls: flip the sign of `ν` (nonpositivity must fail); replace the weight `|k|²` by
`|k|⁴` in the balance (the split must fail); assert the enstrophy rate is `≤ 0` like the energy
rate (must fail to be provable — checked at Tier B on the state where production is `−18`, which
note is *negative* there; a state with positive production is also exhibited, or the sign-freedom
is documented).

### WP-2 — how the production scales with `M` (Fable designs, Opus implements, Haiku runs)

The uniformity question, made empirical and exact: on families of Galerkin states (deterministic,
seeded, with the null models LL-11 demands), how does `Σ(|r|²−|q|²)(q·u_p)(u_q·u_r)` grow as `M`
rises with the physical field held fixed vs. rescaled? Tier B where exact, Tier C where floats are
needed, **conclusions only ever about the truncated systems computed** — O5 forbids reading a
trend as a limit statement. Output: a measured scaling with controls, as input to WP-3, not as
evidence of anything.

### WP-3 — the uniformity mechanism (Fable + Deep Think + owner; THE human gate)

Blocked on mathematics that does not exist yet, and on two E-1 definitions only the owner can
author (Task 2.3's bounded object; Task 3.1's invariant region). The spec's §V offers four
candidate tracks. **This is where the Deep Think discussion is needed** — see §4.

### WP-4 — the Millennium reduction (owner + Fable on paper; Lean later)

Spec §II is classical PDE work (Aubin–Lions compactness, Prodi–Serrin, the blow-up criterion).
`MillenniumReduction.lean` was demoted to Tier C precisely because the analytic content was not
formalisable yet. This stays paper-first: derivation memos, hand-checked, Deep-Think-reviewed,
before any Lean.

## 4. What I need from the human / Deep Think, stated as decisions

**Now, from the owner (blocking items already on the table):**

1. **Audit the weighted-identity memo** (`WEIGHTED_TRIAD_IDENTITY.md`) — accept, amend, or reject
   the statement. Everything in WP-1/WP-2 builds on it.
2. **Approve or amend this workflow**, in particular the WP-1 definitions (`galerkinRHS`, the two
   rates) which mirror the dyadic precedent but are formally new definitions under E-1.
3. The standing items: the three Door #2 decisions, and the toolchain pin.

**Soon, from a Deep Think session (the WP-3 strategy discussion) — proposed agenda:**

1. Given that resonance = collinearity killed the "arithmetic rigidity" route, and the production
   is now localised to the factor `|r|² − |q|²`: **which of the spec's four tracks attacks that
   factor?** Bourgain–Demeter (few near-isoceles triads carry weight?), phase mixing, entropy, or
   percolation — pick one, or reject all four with reasons.
2. **Author the E-1 definitions** for Task 2.3 (the object bounded `∝|p|`) and Task 3.1 (the
   invariant region), or formally retire those tasks.
3. Decide whether WP-2's measured scaling is worth the compute before a mechanism candidate
   exists, or after.

Until those land, Fable-tier work continues on WP-1/WP-2 and on audit-hardening, and **will not**
start WP-3: inventing the missing definitions is forbidden, and correctly so.
