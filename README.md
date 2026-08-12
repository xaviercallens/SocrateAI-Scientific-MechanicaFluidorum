# MechanicaFluidorum — AgoraAI-Agentic-Core

A staged, verifier-in-the-loop scientific program on 3D Navier–Stokes global regularity,
organized around **Hypothesis U** (uniform enstrophy control of the frequency-truncated
system). Human intuition audits the questions; the Lean 4 kernel checks the proofs; exact
rational arithmetic checks everything in between.

**Read `SPEC.md` first.** It is the normative rulebook (epistemic tiers, obstruction ledger,
rules), not background material. `PLAN.md` is the agent-executable task list with escalation
protocol. `LEDGER.md` is the claim inventory — **a claim not listed there has no tier and may
not be cited.** `CLAUDE.md` covers build/verify commands and file architecture. `LL.md` is a
running lessons-learned log — the *why* behind the process rules, with evidence.

## Current state (2026-08-12)

**52 Lean 4 theorems** across five files, **5 exact-arithmetic (Tier B) harnesses**, all
independently re-verified and gated — every theorem's `#print axioms` footprint is exactly
`[propext, Classical.choice, Quot.sound]` (zero custom axioms, zero `sorry`).

| File | Theorems | Content |
|---|---|---|
| `lean_src/CallensDualScale.lean` | 14 | T-dual effective-radius laws (`Reff`), the Symmetric-Square recurrence lock, sharpness |
| `lean_src/DyadicShells.lean` | 3 | Energy-flux telescoping identity, truncated dyadic shell model |
| `lean_src/HypothesisU_Statements.lean` | 9 | Non-vacuous statement-level formalization of Hypothesis U (draft, awaiting statement-adequacy audit) |
| `lean_src/EnstrophyProduction.lean` | 11 | Exact enstrophy-production identity — the dyadic vortex-stretching analogue |
| `lean_src/EnstrophyProductionBound.lean` | 15 | Local production bound `S_N² ≤ 2Ω_N³` (Cauchy–Schwarz, sqrt-free) |

Two numerical measurement attempts (D4: explicit float, D5: exact-rational IMEX) both hit
genuine, different obstructions before reaching a useful horizon — documented honestly in
`docs/escalations/`, not smoothed over. The program pivoted to an analytical attack on the
same question (the local bound above) plus dual-precision float steering, kept strictly
Tier C. The four analytical tracks (T1–T4) remain correctly blocked pending human audit of
draft definitions in `docs/designs/TRACK_DEFINITIONS_DRAFT.md` — authorship never unblocks a
track by itself.

## Verify everything

```bash
./scripts/verify.sh
```

Gate 1 runs every `tests/tier_b_*.py` / `test_*.py` harness (exact arithmetic only — no
floats, ever, in a gated file). Gate 2 kernel-compiles every listed Lean file and enforces the
clean axiom footprint on every theorem. Both must pass before anything is committed.

## Repository map

```
SPEC.md            rules — epistemic tiers, obstruction ledger, mathematical foundations
PLAN.md             agent execution plan — tasks, Definition of Done, escalation protocol
LEDGER.md           normative claim inventory (the only source of truth for "is this proven")
LL.md               lessons learned — why each process rule exists, with evidence
CLAUDE.md           build/verify commands and architecture, for Claude Code sessions
lean_src/           one active Lean file per object; imports chained; no versioned copies
tests/               Tier B exact-arithmetic harnesses, wired into Gate 1
symbolic/           exact-Fraction numerical/algebraic tooling
exploration/        the only place floating point is allowed (Tier C, banner-labeled)
docs/designs/        derivation/design memos, written and hand-verified before dispatch
docs/escalations/     genuine blockers filed rather than worked around unilaterally
docs/proposals/       externally submitted artifacts, archived verbatim with compiled output
data/                every CSV ships a .meta sidecar (command, tool version, sha256sum)
```

## Program status

Stage 0 (scale geometry) and the Stage 1 dyadic laboratory's core identities are complete and
Tier A. The current frontier is the local production bound's closure to a global-in-time,
uniform-in-cutoff result — the actual content of Hypothesis U's dyadic analogue — plus the
human audit that would unblock the four analytical tracks. See `PLAN.md` for the concrete
next tasks and `docs/HYPOTHESIS_U_SPECIFICATION.md` for the full mathematical program.
