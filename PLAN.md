# PLAN.md — Agent Execution Plan for the Hypothesis U Campaign (v1.0)

**Audience:** implementation agents of any capability tier. Written so a low-tier model can
execute tasks mechanically and *safely* — every task states exactly what to do, what "done"
means, how it is validated, and when to stop and escalate.
**Authored & reviewed:** Fable 5, 2026-08-12. **Human owner:** Xavier Callens.
**Normative companions:** `SPEC.md` (rules), `LEDGER.md` (claims), `docs/HYPOTHESIS_U_SPECIFICATION.md`
(mathematics), `docs/ROADMAP_6_MONTHS.md` (calendar — aspirational; this file is operational).

---

## 0. How to use this plan

1. Pick the lowest-numbered task in your phase whose **Prereqs** are satisfied and whose
   **Status** is OPEN. Tasks marked `BLOCKED-ON-DEFINITION` may not be started by anyone.
2. Follow the **Steps** literally. Do not improvise mathematics. Do not "fix" a statement
   that will not prove — escalate (§3).
3. A task is finished only when every line of its **Definition of Done (DoD)** is
   mechanically true. Run `./scripts/verify.sh` before every commit; both gates must pass.
4. Report using the template in §9. Update `LEDGER.md` in the same commit as the artifact.
5. **Effort tier** tells you who may run the task: `[any]` = safe for low-tier models;
   `[top]` = requires Fable/Opus-class judgment; `[human]` = requires the human owner.

---

## 1. Goals

- **G1 — Dyadic verdict.** A kernel-verified energy identity for the truncated Katz–Pavlović
  system, plus a measured answer to: *is the enstrophy bound uniform in the cutoff?*
- **G2 — Formal reduction skeleton.** Lean statements of Hypothesis U and Proposition 5.1
  with the equation and initial data as genuine constraints, unproven infrastructure as
  hypothesis parameters, zero custom axioms.
- **G3 — Track datasets.** For every track that is definitionally unblocked: the milestone
  measurement, delivered as raw data + generating script + checksum — no interpretation.
- **G4 — Definitions authored.** The three missing definitions (§6) written by a top-tier
  author and human-audited, unblocking tracks T1–T4.
- **G5 — Ledger integrity.** Every artifact tier-tagged; no claim exists outside `LEDGER.md`.

**Explicit NON-goals:** "prove Hypothesis U by a date"; any publication or venue claim;
any verdict on whether the Millennium problem is solved. Verdicts are issued only by the
human owner after external audit.

---

## 2. Frontier — DO / DO NOT (hard rules, no exceptions)

### DO NOT
- **DO NOT invent a mathematical definition or theorem statement.** If a task requires an
  object not already defined in `SPEC.md`, `docs/HYPOTHESIS_U_SPECIFICATION.md`, or this
  file's §5–§6, STOP and escalate (E-1). This is the single most important rule: a
  hallucinated definition poisons everything downstream.
- **DO NOT use floating point in any Tier B artifact.** Floats are permitted only inside
  `exploration/` with a `# TIER C — EXPLORATORY, NO CLAIMS` header.
- **DO NOT add `axiom` or `sorry`, and DO NOT trust "no sorry in the source".** The only
  evidence is `#print axioms` output: exactly `[propext, Classical.choice, Quot.sound]`.
- **DO NOT weaken or edit a theorem statement to make a proof close.** Escalate (E-4).
- **DO NOT issue milestone verdicts or scientific conclusions.** Deliver data and gate
  outputs; verdicts belong to the human owner (§8).
- **DO NOT create versioned file copies** (`_v2`, `_final`) or scratch `.lean` files in
  `lean_src/`. One active file per module; git history is the archive.
- **DO NOT fix α′ (or the cutoff N) as a global constant** in any formal statement. It is
  always a quantified parameter — Hypothesis U is a statement *about the family*.
- **DO NOT report adjectives.** No "strong", "promising", "clear". Numbers, file paths,
  and gate outputs only.

### DO
- **DO run the counterexample search first** (§5, D2-neg pattern): before proving any
  identity, perturb it and confirm the checker rejects the perturbed version. A checker
  that cannot fail is not a checker.
- **DO quantify over initial data** in every existence/boundedness statement. `∃ u, P u`
  with a trivial witness is banned (SPEC §7.5).
- **DO attach a non-vacuity witness** (`example` block) beside every new Lean definition.
- **DO pin determinism:** no wall-clock, no randomness without a fixed seed written into
  the script; every dataset ships with its generating command and `sha256sum`.
- **DO commit atomically:** artifact + ledger row + report in one commit, message format §9.

---

## 3. Escalation protocol

Create `docs/escalations/<date>-<taskID>.md` (template §9.2), set the task Status to
ESCALATED in your report, and stop. Escalate when:

- **E-1 Missing definition:** the task needs an object this plan does not define.
- **E-2 Gate failure ×3:** `verify.sh` fails after three genuinely different repair attempts.
- **E-3 Contradiction:** your result contradicts a `LEDGER.md` row. (This is a *discovery* —
  report it prominently, do not bury it.)
- **E-4 Statement judgment:** you are tempted to change what a theorem says. Any question
  of *what should be proven* (vs. *how*) is above the executing tier by definition.
- **E-5 Anomaly:** exact-arithmetic denominator blow-up, runtime > 2× estimate, or output
  that looks qualitatively unlike the task description.

---

## 4. Phase F — Formal skeleton (OPEN, runs in parallel with Phase D)

### F1 — Migrate the variable-coefficient Sym² proof  `[any]`
- **Objective:** Port `sym2_recurrence_variable` from the prior tree into the active core.
- **Inputs:** `~/xdev/SocrateAI-Scientific-RajMathRecovery/dualscale/lean/DualScale/K3Lock/Basic.lean`
  (lines 50–70); target `lean_src/CallensDualScale.lean`.
- **Steps:** copy the theorem + proof; rename to project conventions; add a non-vacuity
  `example` (aₙ = n+1, bₙ = 1 works — verify in ℚ first with a 5-line script); add
  `#print axioms` line; run `./scripts/verify.sh`.
- **DoD:** verify.sh both gates PASS; footprint line for the new theorem is clean; ledger
  row moved from "Tier B (migration pending)" to Tier A; B2 harness check still passes.
- **Validation:** the Tier B check B2 already mirrors this theorem — no new science.

### F2 — Statement-level Hypothesis U file  `[top]` then `[any]` to verify
- **Objective:** `lean_src/HypothesisU_Statements.lean`: Fourier-side definitions of the
  truncated system on 𝕋³ (divergence-free trigonometric polynomials, Galerkin ODE), the
  enstrophy functional, and `HypothesisU : Prop` **with the equation and initial data as
  constraints** — repairing the prior tree's vacuity (any-smooth-field) defect.
- **Split:** statements are authored by a top-tier agent and **human-audited before merge**
  (this is the "audit the question" half of the oversight paradigm). A low-tier agent then
  verifies compilation, adds witnesses where prescribed, and runs the gates.
- **DoD:** compiles clean; zero axioms/sorry; every `def` has a witness or an explicit
  `-- WITNESS DEFERRED: <reason>` note approved in the audit; ledger rows added at Tier A
  (definitions compile) with the *statement-adequacy* box ticked by the human.
- **Status:** OPEN for the top-tier authoring step.

### F3 — Conditional Millennium Reduction skeleton  `[top]` — DONE 2026-08-12, awaiting audit
- **Objective:** `theorem millennium_reduction (hU : HypothesisU …) (hAL : AubinLionsStatement …)
  (hPS : ProdiSerrinStatement …) : GlobalRegularityStatement …` — the implication chain with
  unproven analysis as named hypothesis parameters (never axioms).
- **Prereq:** F2 merged. **DoD:** compiles clean; the hypothesis parameters are *bona fide
  statements* (audited), not `Prop` placeholders; ledger row at Tier A explicitly scoped as
  "conditional skeleton — the analytic content remains open".
- **Implemented:** `lean_src/MillenniumReduction.lean` (5 theorems, clean footprints, wired
  into `scripts/verify.sh` Gate 2). Design: `docs/designs/F3_MILLENNIUM_REDUCTION_SKELETON.md`.
  Compilation and 3 negative controls independently verified by the top-tier author itself
  before commit. **Remaining:** human statement-adequacy audit (this task's `[top]` authoring
  step does not itself license the claim — see LEDGER.md's entry for the same posture as F2's
  pre-audit `HypothesisU_Statements.lean`).

---

## 5. Phase D — Dyadic Laboratory (OPEN — the definitions are pre-authored here)

**Pre-authored model (agents implement exactly this; do not modify).**
Truncated viscous Katz–Pavlović system with N shells, wavenumbers `k n = 2^n`, viscosity
`ν > 0` (rational), state `a : ℕ → ℚ` supported on `0 ≤ n ≤ N` (boundary convention
`a₋₁ = 0`, `a_{N+1} = 0`):

```
d a_n / dt  =  k_{n-1} · a_{n-1}²  −  k_n · a_n · a_{n+1}  −  ν · k_n² · a_n
```

Energy `E = ½ Σ a_n²`; enstrophy analogue `Ω = ½ Σ k_n² a_n²`.
**Key algebraic fact (the Tier B/A target):** the nonlinear part telescopes —

```
Σ_{n=0}^{N} a_n · ( k_{n-1} a_{n-1}² − k_n a_n a_{n+1} )  =  0
```

so `dE/dt = −ν Σ k_n² a_n² ≤ 0` exactly. The **dyadic Hypothesis U analogue** is:
for fixed data and ν, is `sup_t Ω_N(t)` bounded *uniformly in N*?

### D1 — Exact telescoping check (Tier B)  `[any]`
- **Steps:** new file `tests/tier_b_dyadic_checks.py` in the style of the existing harness
  (Fraction only, deterministic). Check the telescoping identity for N ∈ {1,…,12} on ≥20
  exact rational states (enumerate small numerators/denominators; no randomness).
  **Negative control:** flip one coefficient sign (`k_n → −k_n` in a single term) and assert
  the checker FAILS. Wire the file into `scripts/verify.sh` Gate 1.
- **DoD:** harness passes; negative control demonstrably fails when enabled; verify.sh green;
  ledger row "Dyadic energy flux telescopes (N ≤ 12, exact ℚ)" at Tier B.

### D2 — Telescoping identity in Lean (Tier A)  `[any]` with the skeleton below
- **Statement to prove (as given — escalate rather than alter):**
  ```lean
  theorem dyadic_energy_flux (N : ℕ) (a : ℕ → ℝ) (h0 : a 0 * (2:ℝ)^0 * 0 = 0)
      (hbc : a (N+1) = 0) :
      ∑ n ∈ Finset.range (N+1),
        a n * ((2:ℝ)^(n-1) * (a (n-1))^2 - (2:ℝ)^n * a n * a (n+1)) = 0
  ```
  *Note to implementer:* the `n−1` at `n = 0` needs the boundary convention; the audited
  final form (with `if n = 0 then 0 else …`) is in the F2 audit packet — use that form.
  Proof route: induction on N; the inductive step is `ring` after unfolding the sum.
- **DoD:** verify.sh green with clean footprint; ledger row at Tier A.

### D3 — Energy monotonicity corollary (Tier A)  `[any]`
- From D2: `dE/dt ≤ 0` for the truncated flow (statement over the ODE right-hand side as a
  finite sum — no ODE existence theory needed at this rung). DoD as D2.

### D4 — Exploratory cascade runs (Tier C, floats permitted)  `[any]`
- **Steps:** `exploration/dyadic_cascade.py` with the Tier C header. RK4 in float64,
  N ∈ {8, 12, 16, 20, 24}, ν ∈ {1/10, 1/100, 1/1000}, fixed seed list for initial data
  (documented in-file), horizon T = 10. Record `sup_t Ω_N(t)` per (N, ν, seed) to
  `data/dyadic_omega_sup.csv` with generating command and `sha256sum` in a sidecar `.meta`.
- **DoD:** CSV + meta committed; **no claims in the report beyond the table itself.**
- **Purpose:** locate the interesting (ν, data) regimes for D5. Float results steer, never gate.

### D5 — Cutoff-uniformity measurement (Tier B core question)  `[top]` designs, `[any]` runs
- **Objective:** in the regime D4 identifies, certify (exact or interval-over-ℚ arithmetic)
  whether `sup_t Ω_N` grows with N or saturates. Exact long-horizon ℚ integration is
  infeasible (denominators explode — E-5 if you hit this); the top-tier design will specify
  a per-step certified inequality scheme. **Do not start the `[any]` half before the design
  memo exists** (`docs/designs/D5-certified-integration.md`).
- **DoD (run half):** dataset + meta as in D4, produced by the certified scheme; escalation
  E-3/E-5 filed if anomalies. **Verdict on uniformity: human owner only.**

---

## 6. Phase T — Tracks: what is blocked and what is executable

**BLOCKED-ON-DEFINITION (E-1 applies; only a `[top]`+`[human]` authoring task unblocks):**

| ID | Missing object | Why agents must not improvise |
|---|---|---|
| OP-2 | The **Sym²-constrained spectrum** of the 𝕋³ flow (T1's counting set) | The lock is proven for scalar recurrences; its embedding into 3-D Fourier dynamics is open research. Any invented embedding would make T1's count meaningless. |
| OP-3 | **"Enstrophy echo"** as a formula in the truncated system (T2) | Landau-damping echoes are defined in Vlasov phase space; no NSE analogue exists in the literature. |
| OP-4 | The **entropy functional h and reference state ū** (T3) | Choosing h *is* the mathematical content of the track. |
| OP-5 | The **coupling of the percolation field to Sym²** (T4) | Without it, T4 measures generic percolation, which cannot beat CKN. |

**Executable now (definition-independent tooling and baselines):**

### T0.1 — Lattice representation counts r₃(n) (Tier B)  `[any]`
- Compute `r₃(n) = #{k ∈ ℤ³ : |k|² = n}` exactly for n ≤ 10 000 by direct enumeration
  (bounded loops, integers only). Sanity anchors: r₃(0)=1, r₃(1)=6, r₃(2)=12, r₃(3)=8,
  r₃(7)=0 (escalate E-3 if any anchor fails). Output `data/r3_counts.csv` + meta.
- **Purpose:** baseline arithmetic data for T1 once OP-2 lands.

### T0.2 — Unconstrained triad-count baseline (Tier B)  `[any]`
- Exact count of triads `k₁ + k₂ = k₃`, all `|kᵢ|² ≤ M²`, for M ∈ {4, 8, 16} only
  (cost grows like M⁶ — do not exceed M = 16 without an E-5 design review). Method: loop
  k₁, k₃; set k₂ = k₃ − k₁; test norms. Output `data/triads_free.csv` + meta.

### T0.3 — Exact 3-D site-percolation toolkit (Tier B)  `[any]`
- `symbolic/percolation_exact.py`: cluster labeling (union-find, integers) on periodic
  n×n×n grids, n ≤ 16, over *given* boolean fields; unit tests with hand-checkable 3×3×3
  cases; negative control (a field with no crossing cluster must report none).
- **Purpose:** ready instrument for T4 once OP-5 lands. No physics claims.

---

## 7. Definition of Done — campaign level

The campaign (this plan, v1.0) is DONE when all of the following hold:

- [ ] F1–F3 merged: skeleton compiles, statements human-audited, footprints clean.
- [ ] D1–D3 at Tier A/B: telescoping + monotonicity kernel-verified; harness wired into CI.
- [ ] D4–D5 datasets delivered with meta + checksums; uniformity question has a
      human-issued verdict recorded in `LEDGER.md` (whatever the verdict is).
- [ ] OP-2…OP-5 either authored-and-audited (unblocking their tracks) or explicitly
      recorded in the ledger as open with a dated escalation.
- [ ] T0.1–T0.3 instruments delivered with passing negative controls.
- [ ] `LEDGER.md` audit: every row maps to a passing artifact; no orphan claims.

Note what is *absent* from this list: proving Hypothesis U. If the campaign produces a
negative dyadic verdict or kills tracks, **the campaign still counts as done and successful
as science** — that is what falsifiable structure means.

---

## 8. Criteria for scientific validation

| Artifact class | Validation requirement |
|---|---|
| Tier A (Lean) | `./scripts/verify.sh` green; `#print axioms` exactly `[propext, Classical.choice, Quot.sound]`; statement-adequacy box ticked by human for any *new* statement (F2/F3); non-vacuity witness present. |
| Tier B (exact) | Deterministic; `fractions.Fraction`/ints only; negative control included and shown to fail; wired into Gate 1; reproduces from a single documented command. |
| Tier C (exploratory) | Labeled header; lives in `exploration/`; may steer decisions, may never support a claim or appear in a ledger row above Tier C. |
| Dataset | Raw file + generating script + environment note + `sha256sum` sidecar; fixed seeds; no adjectives in the report. |
| Verdict (uniformity, milestone pass/kill, any "the mechanism works/fails") | **Human owner only**, informed by the data, recorded as a dated ledger row. Agents never issue verdicts. |
| Public claim of any kind | Kernel-verified proof + independent external expert audit. Until then, nothing leaves the repo. |

---

## 9. Reporting & commit protocol

### 9.1 Per-task report (end of your message, verbatim headings)
```
TASK: <ID> — <status: DONE | ESCALATED>
GATES: <last verify.sh line(s), pasted>
ARTIFACTS: <paths + sha256 for data>
LEDGER: <rows added/changed>
ANOMALIES: <none | E-# filed at path>
```

### 9.2 Escalation file template (`docs/escalations/<date>-<taskID>.md`)
```
Task / Rule triggered (E-1…E-5) / What I was doing / Exact blocker
(verbatim error or missing object) / What I did NOT do (no improvisation) /
Smallest question whose answer unblocks me
```

### 9.3 Commit message
`<taskID>: <one-line outcome>` + body listing DoD items satisfied + the standard
Co-Authored-By trailer. One task per commit. Artifact + ledger + report together.

### 9.4 The `git add -A` race (recorded 2026-08-12 after it happened twice in one session)

When a background workflow is writing files to the repo concurrently with the orchestrator's
own integration work, `git add -A` stages **whatever is on disk at that instant** — including
another agent's file mid-edit, before its own gate check ran. This produced two real broken
commits in one session: a Tier-B harness that happened to already be correct when swept in
(lucky), and a Lean proof that was mid-fix and carried `sorryAx` in five theorems (not lucky —
caught only because the authoring agent's own report flagged the discrepancy on its next run).

**Rule:** while any background workflow may still be writing to this repo, `git add` **by
path**, never `-A`/`.`, and re-run the relevant gate (`./scripts/verify.sh` or the specific
harness/`lake env lean` command) on the **exact file about to be staged** immediately before
staging it — not on a cached belief that it was checked a few tool-calls ago. If a workflow's
completion notification arrives with files already partially staged from a broad `add`, treat
every one of those files as unverified regardless of what the last gate run said, and re-check
each individually before the next commit. Full incident writeup: `LL.md` LL-1.

---

*This plan is the operational law of the campaign. Where it conflicts with the roadmap's
calendar, this plan wins; where it conflicts with `SPEC.md`'s rules, `SPEC.md` wins.*
