---
name: goal-management
description: Load, apply and maintain the programme's goal register (docs/GOALS.md) — at session start, before proposing any new work, and whenever a milestone closes, a status changes, or the owner decides something. Use it to answer "what are we trying to do right now, and what would make us stop?" before any tool is spent. Drawn from a month in which the goals lived in five documents and several sessions' memories, and a standing owner decision was rediscovered three times.
---

# Goal management — one page, loaded first, edited in the same commit

The programme externalises rules (`SPEC.md`), tasks (`PLAN.md`), claims (`LEDGER.md`) and
reasons (`LL.md`). What it did not externalise until 2026-09-18 was the **goal stack**: which
goals are live, what each is waiting on, what would kill it. That lived in the memory files of
individual sessions, and it showed: the three Door #2 owner decisions of 2026-08-25 were
re-derived as "pending" by at least three later sessions, and the question "is M = 128 worth it"
was asked twice. `docs/GOALS.md` is the register; this skill is how it is used.

## At session start

1. Read `docs/GOALS.md` in full. It is one page by design; if it is longer, that is a finding.
2. Read the "Standing owner decisions" list and **do not re-derive any of them**. If a task needs
   one, say so in one line and route around it or stop — do not solve it.
3. Check "Last refreshed" against the newest tag (`git describe --tags`). If the register is
   older than the last release, refresh it before doing anything else (step "Refresh" below).

## Before proposing new work

Every proposal names the goal row it serves. If none does, one of three things is true: the
proposal is a new goal (write the row first — with a kill criterion, or it is not a goal); it is
housekeeping (say so; it needs no row); or it is scope drift (stop). "It seemed interesting" is
the third case.

Then check the row's **kill criterion** against the current state before spending compute. The
pre-registration skill's discrimination check is the same question one level down.

## When something changes

Edit the row **in the same commit as the artefact** — a milestone closed, a status moved, a
kill criterion tripped, an owner decision received. Bump "Last refreshed". A register updated
in a separate later commit is a register nobody trusts, because the gap is where the stale
reading lives (LL-25: never summarise a file a job is still writing — the same for goals).

## Refresh

A refresh is not a rewrite. For each row: is the status sentence still true of `LEDGER.md`? Is
the milestone still the *next* one? Has the kill criterion been met without anyone saying so?
Move closed items to "Recently closed" with the ledger pointer; do not delete them.

## What must never be in the register

- A verdict. Verdicts are the owner's, after external audit (`PLAN.md` §8).
- An adjective. "Promising" is not a status; a number or a ledger row is.
- A goal without a kill criterion.
- A task. Tasks are `PLAN.md`'s, with their Definition of Done.

## Definition of done for this skill, per session

- [ ] Register read before the first tool call that spends compute.
- [ ] Every proposal in the session named its goal row (or was declared housekeeping).
- [ ] Every status change landed in the same commit as its artefact.
- [ ] "Last refreshed" is at or after the last tag at session end.

Origin: `docs/GOALS.md` (2026-09-18); the rediscovered Door #2 decisions (memory files
2026-08-25 → 2026-09-17); `LL-25`.
