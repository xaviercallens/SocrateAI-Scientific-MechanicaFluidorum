# Proposed harness artifacts — skills and agents, authored 2026-09-13

These are **proposals, not installed configuration.** They live here rather than in `.claude/`
because the session that wrote them is denied write access to `.claude/` — skills and agent
definitions are harness config, and an agent that can install its own instructions or widen its
own tool grants has no boundary at all (`LL.md` LL-23). The owner installs them; the agent
drafts them.

## Install

```bash
mkdir -p .claude/skills/preregister .claude/skills/cost-model .claude/agents
cp docs/harness/skill-preregister.md   .claude/skills/preregister/SKILL.md
cp docs/harness/skill-cost-model.md    .claude/skills/cost-model/SKILL.md
cp docs/harness/agent-claim-auditor.md .claude/agents/claim-auditor.md
```

Then `/preregister`, `/cost-model`, and the `claim-auditor` subagent become available. Review the
files first: each one is an instruction set that will shape how future sessions behave.

## What each is for, and which failure it comes from

| Artifact | Encodes | Origin |
|---|---|---|
| `skill-preregister.md` | Register a measurement's predicted outcome, and check it can discriminate, before spending the compute | `LL-20` — three points called "decelerating" from ratios while differences grew; the registered decisive point was not decisive |
| `skill-cost-model.md` | State a computation's cost model and count its bytes before scaling it to a new size | `LL-21` (a declared memory risk 6.6× optimistic), `LL-22` (a quadratic optimiser that survived three campaigns because its answers were correct) |
| `agent-claim-auditor.md` | Adversarially audit a claim against the three things neither gate can see: cost, interpretation, and the harness itself | `LL.md` synthesis, *the three blind spots of a two-gate system* |

## Why these three and not more

Both machine gates were green through every failure in the 2026-09-13 cycle, and none of those
failures was a proof error. The gates bound what may be **claimed**; they say nothing about what
should be **asked**, what it should **cost**, or whether the **instrument** is sound. These three
artifacts target exactly those gaps and nothing else. A skill that restates what
`scripts/verify.sh` already enforces would add ceremony, not rigour.
