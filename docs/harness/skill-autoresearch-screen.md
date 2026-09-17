---
name: autoresearch-screen
description: Choose between several candidate designs (an optimiser's settings, a search variant, a small set of implementation options) with a fixed-budget, pre-registered screen instead of deepening one hand-picked choice — after karpathy/autoresearch, adapted for this programme's controls discipline. Use when there are several plausible variants of something and no principled reason yet to prefer one, before spending real time or compute deepening any single one.
tools: Read, Write, Edit, Bash, Agent
---

# Fixed-budget, pre-registered screen — how to choose between several plausible designs

Used to pick a search-optimiser's schedule before an expensive run at scale
(`docs/designs/SPECTRAL_ALIGNMENT.md` §3.2(C), `LL-28`). The result: three independent proposer
agents plus a judge produced ten one-change hypotheses and a mechanical decision rule; checking
those proposals against the actual code — not the panel — caught a real convergence bug before
the screen ran; the screen itself later misfired on one registered rule and was reported exactly
as registered rather than silently corrected. Generalise this pattern rather than re-derive it
each time a design choice needs settling.

## When to use this, and when not to

Use it when: there are on the order of five to twenty plausible one-change variants of a design;
each variant is cheap enough to test at a small scale even though the real target is expensive;
and there is no already-strong reason to prefer one over the others. Do **not** use it as a
substitute for understanding the mechanism — a screen chooses an *implementation*, never a
*scientific result*, and its winner must never be reported as evidence for anything beyond "this
setting is cheaper/better at the settings tested."

## The five steps

### 1. State the goal and what "winning" means, in writing, before any hypothesis exists

One paragraph: what quantity does the eventual choice need to optimise, and does quality or cost
dominate when they trade off? (In the origin case: cost decided, and quality was a gate — a
candidate could not fall more than a fixed tolerance below the baseline's exact objective value,
but beyond that tolerance a cheaper-but-equal-quality candidate beat a marginally-better,
costlier one. Get this ordering explicit and written down before results exist to bias it.)

### 2. Propose from independent lenses, in parallel, from a description alone

Spawn several independent agents (three worked well), each given the **same** facts about the
system (measured costs, the baseline's behaviour, the knobs available) but a **different lens**
— e.g. one focused on the mechanism/theory, one on cost, one on controls and experimental
validity. Each proposes a fixed number of one-change hypotheses (ten worked well) with a
falsifiable prediction per hypothesis. Give them no access to the actual code or repository —
this is deliberate: it is what makes the next step catch real defects rather than rubber-stamp
plausible-sounding proposals.

### 3. Check every proposal against the actual code before it becomes binding — this is the step that catches real bugs

The authoring session (not another agent) reads the code path each proposal presumes to describe
and checks it directly. In the origin case this single step found: two proposals that assumed a
mechanism the code provably does not have; and a genuine, previously-unknown convergence bug in
the software being screened (a tabu-search variant could report convergence while an improving
move still existed) — caught only because a proposal's assumption prompted a direct read of the
exact loop it was reasoning about. **A panel review is a review of a description, not of the
code**; do not let a plausible-sounding multi-agent consensus substitute for this check.

### 4. Judge synthesises the final list and a mechanical decision rule, then it is committed before any row runs

One judge agent (a stronger model tier than the proposers, if available) is given the corrected
facts and all proposals, and produces: the final fixed list of hypotheses (including any
determinism/identity control — a variant provably identical to the baseline is worth keeping as
a check that the harness itself works, not as a candidate), a handful of **control rows** that
must pass or the whole screen is void (a baseline reproducibility check, a known-value check
against an independent oracle, a deliberately-corrupted input that must be rejected), and a
**mechanical decision rule** — one a script can apply without judgment calls, stated precisely
enough to handle exact-integer ties. Write this whole design to version control **before running
the first row** — this is what makes "run it as registered even when a rule misfires" possible
later, instead of quietly revising after seeing the table.

Build a self-test for the decision rule itself: a synthetic table covering every status and every
label the rule can produce, including edge cases exactly at any threshold, and confirm the script
labels every synthetic row correctly. Demonstrate the self-test can fail — mutate the rule
slightly and confirm the mutant is caught — the same standard this programme holds every other
control to.

### 5. Run under the fixed budget, apply the rule exactly as registered, report a misfire rather than hide it

Every row is logged whatever its outcome — a row that failed, hit budget, or tied is data, not
noise to discard. If a registered rule fires in an unintended way on real results (in the origin
case, a rule meant to catch noisy near-ties between converged optima instead fired because two
random-seed controls were catastrophically worse — a different phenomenon than the one the rule
was written for), **run it as registered anyway**, report both the registered reading and what
the reading would have been without the misfire, and add the alternative as an explicitly
post-hoc, ineligible row. The lesson from a misfire is that the rule's premise needs to be tested
more directly next time — not that this run's result should be silently corrected.

Only the screen's winner(s) advance to a deeper, more expensive validation stage; nothing from
the screen itself is cited as a scientific finding.

## What this deliberately does not do, versus the original autoresearch pattern

The loop does not run unattended indefinitely and does not rewrite its own hypotheses or code —
the hypotheses are fixed in advance, because what is being protected is the comparability of the
rows and the pre-registration discipline this programme applies to scientific claims (`LL-24`);
a screen that could revise its own design after seeing early results would defeat that. This
also is not a scientific pre-registration — it chooses a setting, not a hypothesis about the
world, and its winner still needs the programme's ordinary controls before anything downstream
cites it.

Origin: `docs/designs/SPECTRAL_ALIGNMENT.md` §3.2(C), `exploration/alignment_spectral/
screen.py`, `LL-28`.
