# E-3 of 2026-09-12 — RESOLVED by owner acknowledgement

**Owner disposition, 2026-09-12:** *"I acknowledge a wrong update from another tool due to
parallel work. Acknowledge, solve the issue and continue."* Executed by Fable the same day.

## What was done, item by item

| item | action | recoverability |
|---|---|---|
| `lean_src/FourierStateZ3.lean` — 94/63-line unprovenanced rewrite of committed, gate-verified proofs | **stashed, then the committed version restored**: `git stash@{0}`, message `E3-2026-09-12: superseded concurrent rewrite…` | **fully recoverable** — `git stash pop` restores it verbatim; nothing was deleted |
| `MATHEMATICAL_DEMONSTRATION_ROADMAP.md` (repo root, untracked, 2026-09-11) | **moved verbatim** to `docs/escalations/2026-09-12-E3-ARCHIVED-roadmap-verbatim.md` | content preserved unchanged; see the reading note below |
| `docs/proposals/openai-axiom-audit.transcript.txt` — one-line *error* output of the premature local audit run | **moved** to `docs/escalations/2026-09-12-E3-stray-premature-audit-error.txt` | preserved; it no longer sits in `docs/proposals/` where it could be mistaken for the audit result |

The real audit transcripts remain where they belong, with provenance:
`docs/proposals/openai-audit-main.transcript.txt`,
`openai-audit-placeholders.transcript.txt`, `openai-audit-PROVENANCE.md`.

## Why restore rather than keep

The rewrite **compiled and passed every gate** — that was verified before this resolution, and it
is why this was filed as a process escalation, not a breakage. Two reasons it is still the wrong
artifact to keep:

1. **Provenance is the product.** A Tier A file's value is the audit trail attached to it — the
   memo, the negative controls, the review, the commit. Proofs that arrive without those are
   indistinguishable, to any later reader, from proofs that were never checked. The committed
   versions carry that trail; the rewrite does not.
2. **Nothing was gained.** The statements are identical and the footprints identical; the
   replacement proofs are longer, and one reviewed docstring was deleted. There is no result to
   preserve, only churn to undo.

## Reading note on the archived roadmap

Kept for the record, **not adopted**, and it should not be cited. Three specific defects, each
checked against the tree at the time of filing:

- it plans to discharge `sorry` placeholders in a tree that **has none** (Gate 2 is zero-`sorry`
  on every run), and names **`EulerCensorship.lean`, a file that does not exist** anywhere in the
  repository;
- its §1.1 formalises the **smooth Helmholtz filter**, which the owner's adjudication of
  2026-09-10 (Q1) discarded as a primary target in favour of the sharp projection;
- it frames the programme as near a "standalone, globally recognized proof of 3D Navier–Stokes
  regularity", which obstruction **O5** forbids stating without a uniformity theorem nobody has.

If any part of it is to be revived, it needs to re-enter through the normal route: a memo, gated,
with the adjudicated definitions.

## Preventive measure requested (unchanged, still open)

Worktree isolation for the concurrent stream, per the `PLAN.md` §9.4 lineage. This is the third
incident in this family (the August `git add -A` sweeps; the 2026-09-09 E-3 on a memory file
reporting a run that never happened; this one). Each was caught by a gate or a read, which is the
system working — but the cost is a full review cycle every time, and isolation removes the class.
