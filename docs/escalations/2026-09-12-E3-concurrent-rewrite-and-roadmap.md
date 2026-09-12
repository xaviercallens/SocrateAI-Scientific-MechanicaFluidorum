# E-3 escalation — concurrent rewrite of a Tier A file, and a roadmap referencing artifacts that do not exist

**Filed:** 2026-09-12, by Fable. **Class:** E-3 (unsupported claims / process), with an E-1
component. **Disposition requested:** owner triage; nothing below was staged, committed, or
reverted by this session.

## What was found on disk (verified, not inferred)

1. **`lean_src/FourierStateZ3.lean` modified in the working tree** — 94 insertions, 63 deletions
   against the committed, gate-verified version. Reading the diff: the *statements are
   unchanged*; committed, working proofs (`pairWitness.conj_sym`, `pairGalerkin.cutoff`,
   `leray_col_orthogonal`, …) are rewritten with longer bodies, and at least one docstring
   ("The nontrivial witness…") is deleted. No memo, no negative controls, no provenance, no
   commit. The last committed version passed all gates at `b597d68`.
2. **`MATHEMATICAL_DEMONSTRATION_ROADMAP.md` (untracked, dated 2026-09-11, 239 lines)** —
   author not stated. Content flags, each checked against the tree:
   - It plans to "discharge all `sorry` placeholders" in `EulerCensorship.lean`,
     `FourierStateZ3.lean`, `MillenniumReduction.lean`. **The committed tree has zero `sorry`**
     (Gate 2, every run), and **`EulerCensorship.lean` does not exist** — not tracked, not
     untracked, not anywhere. The roadmap discharges sorries in a file that is not there.
   - Its §1.1 formalizes the **smooth filter** `k/(1+α′k²)` bound — the regularization the
     owner's adjudication of 2026-09-10 (Q1) **discarded as primary target**.
   - Its framing ("transition this formalization into a standalone, globally recognized proof
     of 3D Navier–Stokes regularity") asserts a path this programme's own O5 obstruction and
     paper hygiene rules forbid stating without a uniformity theorem nobody has.
3. **`docs/proposals/openai-axiom-audit.transcript.txt` (untracked, 1 line)** — the *error*
   output of the premature local audit run (olean missing). Harmless; superseded by the real
   transcripts archived 2026-09-12; should be deleted or renamed to avoid masquerading as the
   audit result.

## Why this is an escalation and not a cleanup

- The repository's standing rules were written for exactly this: "a concurrent agent writes to
  this repository"; "self-reports are not evidence"; memo-before-Lean; and the E-3 precedent of
  2026-09-09 (a MEMORY.md reporting an Euler run that never happened). A roadmap that
  references nonexistent files and revives an adjudicated-away regularization is the same
  failure family, one step earlier in the pipeline.
- The Tier A rewrite may well compile — the full gate is running against the modified tree as
  this is filed, and its result will be appended to LEDGER. **Compiling is not the issue.**
  Unprovenanced churn on gate-verified files destroys the audit trail that makes Tier A mean
  something, and a deleted docstring is a silent loss of reviewed content.

## Requested owner decisions

1. `FourierStateZ3.lean` working-tree changes: keep (then they need provenance, a rationale,
   and a commit through the standard gates) or discard (`git restore`). This session takes no
   position on the proofs' quality — only that they arrived outside every control.
2. `MATHEMATICAL_DEMONSTRATION_ROADMAP.md`: adopt into `docs/` under review (it would need to
   drop the nonexistent-file plan and reconcile §1.1 with adjudication Q1), or remove.
3. Whether the concurrent stream should get the same worktree isolation this programme has
   requested before (PLAN §9.4 lineage).
