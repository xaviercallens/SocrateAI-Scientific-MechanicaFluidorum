# LL.md — Lessons Learned

A repo-resident log of process failures, near-misses, and confirmed-good practices from
running this program. Distinct from `PLAN.md` (which encodes the *rules* these lessons
produced) and `CLAUDE.md` (which encodes *how* to operate here) — this file is the *why*,
kept so the reasoning behind a rule isn't lost the next time someone is tempted to shortcut it.

Format: what happened (with evidence), what it cost or almost cost, the rule it produced,
and where that rule now lives.

---

## LL-1 — Self-reports, including your own tool's status field, are not evidence

**What happened.** Twice in one session, `git add -A` was run while a background Workflow
was still writing to the repo. Both times it staged a file mid-edit:
- A Tier B Python harness that happened to already be correct when swept in (lucky — no
  actual damage, but pure luck).
- `lean_src/EnstrophyProduction.lean`, mid-fix on a failing tactic. The committed version
  (`f279312`) carried `sorryAx` in five theorem footprints. It sat in `git log` as if
  verified, because the commit message (written before the concurrent workflow's true final
  state was known) said "both gates PASS" — true for the files actually checked, false for
  the one incidentally captured.

**How it was caught, both times.** Not by process — by luck the first time, and the second
time only because the authoring agent's *own next report* happened to diff its working-tree
file against `git log` and flag the mismatch explicitly. Had it not done that unprompted
check, the broken proof would likely have sat in the repo, gate-covered or not, until someone
next tried to build on it and hit a wall.

**Cost.** Nothing repo-breaking in the end — both were caught and fixed same-day — but it is
the exact failure mode the project's own Tier A discipline exists to prevent (a theorem name
existing in the environment is not the same as the theorem being proven), now demonstrated
against ourselves rather than an external submission.

**Rule produced.** `git add` by explicit path only, never `-A`/`.`, whenever a background
agent might be writing to the repo; re-verify the *exact* file about to be staged immediately
before staging, not on a cached belief from a few tool-calls earlier. Codified in `PLAN.md`
§9.4 and `CLAUDE.md`.

**Generalizes beyond this repo.** Recorded as a standing cross-session practice, not just a
rule for this project — see the assistant's own memory system, `feedback_git-add-a-with-
background-workflows.md`.

---

## LL-2 — "Verified, no sorry" claims must be checked against the compiled artifact, not the source text

**What happened.** An external proposal for `CallensDualScale.lean` claimed all four theorems
were proven with "no sorry placeholders." Compiling it as submitted: one theorem
(`sym2_recurrence`) was genuinely correct; another (`genesis_no_singularity`) compiled but
carried a custom axiom in its footprint, contradicting its own stated expectation; the third
(`Reff_ge_sqrt`) **did not compile at all** — four real Lean-idiom errors, and the resulting
environment state had `sorryAx` in its footprint despite there being no literal `sorry` token
anywhere in the source file.

**Why this is the sharp version of LL-1.** The source-level claim ("no `sorry` in the text")
was true and the compiled-artifact claim ("proven") was false, simultaneously. A reviewer who
only reads source, or trusts a natural-language summary of what a file contains, cannot
distinguish these two states. Only `#print axioms` on the compiled result can.

**Rule produced.** Every submitted or agent-written Lean file is archived verbatim, compiled
exactly as received (before any repair), and its kernel output is saved as the evidentiary
record — see `docs/proposals/` for the archival pattern and `SPEC.md` §7.1b for the rule.
Never accept "no sorry in the source" as a substitute for a pasted `#print axioms` transcript.

---

## LL-3 — Fixing a stability problem does not fix a representation-size problem

**What happened.** Two numerical designs for the same measurement (dyadic cutoff-uniformity)
failed for what looked like the same symptom — "diverges before reaching useful step counts"
— but for genuinely different reasons:
- **D4** (explicit float RK4): a real stability problem. `dt ∼ 1/k_N²` from the stiff viscous
  term forced infeasibly many steps as the cutoff `N` grew; 21 of 36 configurations never ran.
- **D5** (exact rational IMEX-Euler, redesigned specifically to fix D4's stiffness via an
  implicit viscous term): the implicit treatment worked exactly as intended — stability was
  no longer the constraint — and it diverged anyway, within 2–6 of the needed 40–160 steps,
  for all 45 configurations. Inspection showed the *magnitude* of the diverging quantities was
  small (`sup Ω` values like 9/2, 13/2) while the exact rational representation's digit count
  had grown to hundreds of digits: a representation blowup, invisible to a stability fix
  because it isn't a stability problem.

**Cost.** A second design iteration that addressed the wrong diagnosis, because the symptom
("diverges") was the same for two unrelated causes and the fix for one (implicit stepping)
gave no signal about the other.

**Rule produced.** Before redesigning a numerical scheme that "diverges," check whether the
diverging quantity's *magnitude* is actually large (stability) or its *exact representation
size* is what's exploding while the magnitude stays modest (representation blowup — a
property of iterating a nonlinear map in exact arithmetic, independent of the scheme's
stability properties). See `feedback_exact-arithmetic-iteration-blowup.md` for the general
form of this lesson and `docs/escalations/2026-08-12-D5-digit-blowup.md` for the specific
instance and the redesign options it produced (none picked unilaterally — see LL-4).

---

## LL-4 — A repeated failed design is a signal to ask, not to try a third variant alone

**What happened.** After D4 and D5 both failed their feasibility premise for different
reasons (LL-3), the instinct would be to immediately propose a third numerical scheme.
Instead: the failure was written up with the actual evidence (not a guess), four concrete
options were laid out with honest tradeoffs, and the choice was deliberately left to the human
owner rather than picked unilaterally — because SPEC's own float-ban makes any precision
tradeoff here a *standards* question, not a mechanical one, and because a third unilateral
redesign attempt would repeat exactly the pattern that produced the first two failures.

**What happened instead of a third patch.** The identity that the numerical trajectory was
trying to measure indirectly had *already been proven exactly* (`EnstrophyProduction.lean`).
Re-examining the actual open question revealed a classical energy-method attack (Cauchy-Schwarz
on the production term) was directly available and needed no time-stepping at all — a strictly
better route than any further numerical redesign, found only because the numerical failure
prompted stepping back rather than patching forward.

**Rule produced.** Two failed designs in a row on the same measurement is the threshold for
escalating the *methodology* to the human owner rather than attempting a third variant solo
(`PLAN.md` E-4: methodology is a statement-level decision, not delegable). Explicitly consider
whether the numerical measurement is even the right tool before proposing numerical variant #3.

---

## LL-5 — Derive and hand-verify the mathematics before writing an agent's proof skeleton

**What happened, positively.** Every Lean proof that closed cleanly on the first or second
attempt this session was preceded by: (a) a hand derivation, (b) a numeric sanity check
against a concrete instance, and (c) confirmation that the specific Mathlib lemmas the
skeleton would name actually exist and are built in this environment (checked via `ls` on the
`.olean` path, not assumed from Mathlib's general reputation). The enstrophy-production
identity (`3Σk_n³a_n²a_{n+1}`) and its local bound (`S_N²≤2Ω_N³`) both closed this way, with
the exact same N=2 numeric instance reused across three separate proofs as a running
cross-check.

**Contrast.** Tasks that asked an agent to *derive* which mathematical statement to prove
(rather than *execute* a fully-specified one) either escalated correctly (refusing to
improvise — the right outcome) or required a human decision partway through (Q1/Q2 on
`HypothesisU_Statements.lean`, correctly refused by the drafting agent itself).

**Rule produced.** Statement/theorem selection is top-tier, human-adjacent work, always done
before dispatch; executing a fully specified proof against confirmed-available lemmas is
delegable. Never reverse this order to save a step. See `PLAN.md` §2 (E-1, E-4) and `SPEC.md`
§7.1b.

---

## LL-6 — Verify literature precisely before citing, even a well-known author or result

**What happened.** Before writing a "prior work" citation for shell-model global regularity,
the actual abstract of the candidate paper (Barbato–Morandin–Romito, arXiv:1007.3401) was
fetched and read rather than cited from a general impression ("shell models are known to be
regular under enough dissipation"). The real scope was narrower and more specific: well-
posedness of *positive* solutions in a scaling range that matches Navier–Stokes — a
precisely-scoped, real result, not the loose paraphrase that would have been written from
memory.

**Rule produced.** Every literature claim entering `LEDGER.md` carries the tool call that
verified it (URL fetched, date, what was actually read — abstract vs. full paper) and states
the *precise* scope, flagged Tier C until re-verified against the full text if only the
abstract was checked. Already the project's stated Stage-1 policy (`SPEC.md`); this session
is the first time it was actually exercised against a real citation rather than deferred.

---

## LL-7 — A design memo's own worked example can be wrong; a good certifier catches it rather than silently absorbing it

**What happened.** The hand-derivation in `docs/designs/ENSTROPHY_PRODUCTION_BOUND.md`
(written top-tier, before any dispatch — the LL-5 practice) stated Step 2's worked example
over the *full* shell range (`n=0..N`, giving `20993` on the N=2 sanity instance) while
naming Step 2's bullet as the *restricted* range (`n=0..N-1`) that Step 3's Cauchy-Schwarz
combination actually needs. On the sanity instance these differ (`257` vs `20993`) — a real
bookkeeping error in the design note's own exposition, made by the same process LL-5
recommends, on the very derivation that process was meant to protect.

**How it was caught.** The Tier B certifying agent, tasked with reproducing the design note's
own quoted sanity numbers exactly before running the full sweep, found the mismatch,
**traced it to its source** (identified exactly which range each part of the note used and
why they disagreed) rather than silently picking whichever number let the task proceed,
determined that the discrepancy did not affect the bound's *validity* (a sub-sum of
nonnegative terms is trivially ≤ the full sum, so both quantities satisfy the needed
inequality), proceeded correctly using the range Step 3 actually requires, and reported the
whole chain of reasoning explicitly rather than quietly fixing it.

**Why this matters more than the error itself.** LL-5 says "derive and hand-verify before
dispatching" — true, and it still produced a genuine slip. The actual safeguard was never
"the top-tier derivation is right the first time" (it wasn't, here); it was that every
downstream step re-verifies against the *stated* numbers rather than trusting the *prior*
step's authority. A less careful certifier could easily have silently substituted whichever
range made the sanity check pass, or fabricated agreement, and nothing downstream would have
caught it — the corrected Lean proof and the corrected design-note erratum both trace back to
this one certifying agent refusing to paper over a mismatch.

**Rule produced.** No new mechanical rule beyond what already existed (LL-2's discipline
applies recursively: a design memo's claims need re-verification exactly like a submitted
proof's claims do) — but this is the concrete evidence that the discipline pays for itself
even against the orchestrator's own work, not only against external submissions, and is
recorded here so future sessions don't read LL-5 as "top-tier derivation removes the need for
downstream re-verification." It doesn't.

---

*Add new lessons above this line, most recent first is not required — group by theme as the
log grows. A lesson earns an entry here when it changed a rule somewhere else in the repo
(`PLAN.md`, `CLAUDE.md`, or a memory file) — if it didn't change a rule, it probably belongs
in an escalation file or a design memo instead, not here.*
