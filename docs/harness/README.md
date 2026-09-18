# Proposed harness artifacts — skills and agents, authored 2026-09-13

These are **proposals, not installed configuration.** They live here rather than in `.claude/`
because the session that wrote them is denied write access to `.claude/` — skills and agent
definitions are harness config, and an agent that can install its own instructions or widen its
own tool grants has no boundary at all (`LL.md` LL-23). The owner installs them; the agent
drafts them.

## Install

```bash
mkdir -p .claude/skills/preregister .claude/skills/cost-model .claude/skills/resilient-job \
         .claude/skills/autoresearch-screen .claude/skills/publish-gate \
         .claude/skills/goal-management .claude/agents
cp docs/harness/skill-preregister.md         .claude/skills/preregister/SKILL.md
cp docs/harness/skill-cost-model.md          .claude/skills/cost-model/SKILL.md
cp docs/harness/skill-resilient-job.md       .claude/skills/resilient-job/SKILL.md
cp docs/harness/skill-autoresearch-screen.md .claude/skills/autoresearch-screen/SKILL.md
cp docs/harness/skill-publish-gate.md        .claude/skills/publish-gate/SKILL.md
cp docs/harness/skill-goal-management.md     .claude/skills/goal-management/SKILL.md
cp docs/harness/agent-claim-auditor.md       .claude/agents/claim-auditor.md
cp docs/harness/agent-manuscript-auditor.md  .claude/agents/manuscript-auditor.md
```

Then `/preregister`, `/cost-model`, `/resilient-job`, `/autoresearch-screen`, `/publish-gate`,
`/goal-management`, and the `claim-auditor` and `manuscript-auditor` subagents become available.

**Hooks.** The event-driven form of these skills — footprint check on every Lean edit, git
blast-radius guard, ledger pre-commit check, publish gate on release commands, manuscript audit
on paper edits — is specified with installable JSON in
`docs/designs/NEURO_SYMBOLIC_HARNESS.md` §2, together with a local open-weights tier, the Lean
tooling (LeanGraph, LeanRAG, leanDataStore) and a gated self-improvement loop. All of it is a
Tier C proposal; the owner installs, and each hook command ships a self-test run by Gate 1. Review the files first: each one is an instruction
set that will shape how future sessions behave. Each is written to be portable — none of them
name this project's specific files as anything but an illustrative origin, so they can be
installed in another project's `.claude/` unchanged.

## What each is for, and which failure it comes from

| Artifact | Encodes | Origin |
|---|---|---|
| `skill-preregister.md` | Register a measurement's predicted outcome, and check it can discriminate, before spending the compute | `LL-20` — three points called "decelerating" from ratios while differences grew; the registered decisive point was not decisive |
| `skill-cost-model.md` | State a computation's cost model and count its bytes before scaling it to a new size | `LL-21` (a declared memory risk 6.6× optimistic), `LL-22` (a quadratic optimiser that survived three campaigns because its answers were correct) |
| `skill-resilient-job.md` | Checkpoint inside every expensive pass, proof text search against binary-detection false negatives, give success/failure detection its own negative control, distinguish "corrupt" from "my reader failed", recover the backed-up value instead of blindly re-spending compute | `LL-29`, `LL-30`, `LL-31` — a fully-converged 34-hour cloud computation was reported failed twice by its own verification code, and its "discard and restart" policy began an unnecessary full recompute twice, before both bugs were found by reading raw bytes directly |
| `skill-autoresearch-screen.md` | Choose between several plausible designs with a fixed-budget, pre-registered screen (independent proposers from different lenses → check every proposal against the actual code → a judge fixes the list and a mechanical rule → run as registered, report a misfire rather than hide it) | `LL-28` — a multi-agent panel's proposals were checked against the code before running and a real convergence bug was found; the screen itself later misfired on one rule and was reported exactly as registered |
| `agent-claim-auditor.md` | Adversarially audit a claim against the things neither gate can see: cost, interpretation, the harness itself, and — as of `LL-29`/`LL-30`/`LL-31` — whether the *verification tooling* deciding success or failure has been tested against its own failure modes | `LL.md` synthesis, *the three blind spots of a two-gate system*, extended 2026-09-17 |
| `agent-manuscript-auditor.md` | Review a paper against the Lean statements, source files and retrieved literature it rests on — every theorem's hypotheses diffed against its formal signature, every number traced past the ledger to its producing file, every novelty claim checked against the paper that introduced the object | `docs/paper/REVIEW.md` (2026-09-17): the external paper's first draft, written by the session that proved the results, carried two blocking defects — a novelty overclaim against Waleffe 1992 and a theorem missing a hypothesis its own Lean proof requires |
| `skill-goal-management.md` | Load the one-page goal register (`docs/GOALS.md`) before spending compute; name the goal row every proposal serves; never re-derive a standing owner decision; edit the register in the same commit as the artefact; no goal without a kill criterion | A month in which the goal stack lived in sessions' memories: the three Door #2 owner decisions of 2026-08-25 were rediscovered as "pending" by at least three later sessions |
| `skill-publish-gate.md` | Gate any permanent identifier (a DOI, a public dataset) behind what the verification gates do not cover: author of record supplied not inferred, artefact matched to the tag by checksum, metadata read against the withdrawn-claims list, draft before publish, live record verified without credentials, exposed secrets rotated | 2026-09-18: the paper was one flag from a permanent DOI with a placeholder author on every page and an inferred creator name; and the sister project's upload script (`OpenAI-NSE-Verification/CHANGELOG.md` v5.1.0) would have re-published withdrawn claims under a DOI |

## Why these and not more

Both machine gates were green through every failure in the 2026-09-13 cycle, and none of those
failures was a proof error. The gates bound what may be **claimed**; they say nothing about what
should be **asked**, what it should **cost**, or whether the **instrument** is sound. A second
incident cycle (2026-09-15..17, a real cloud computation) added a fourth gap of the same shape:
the code that decides *whether a long-running job succeeded* is itself an unaudited instrument,
and needs the same controls as everything it reports on. These artifacts target exactly those
gaps and nothing else. A skill that restates what `scripts/verify.sh` already enforces would add
ceremony, not rigour.
