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

## LL-8 — The gate itself can be wrong, and a gate that rejects *better* proofs is dangerous

**What happened (2026-08-13).** `TriadConservation.lean`'s `swap3_involutive` is proved by pure
computation and reports the axiom footprint `[propext]` — a **strict subset** of the permitted
set `{propext, Classical.choice, Quot.sound}`, i.e. *cleaner* than required. `scripts/verify.sh`
failed it. The Tier A check was implemented as a string match against the exact three-axiom
list (`grep -v "propext, *Classical.choice, *Quot.sound]"`), so any footprint that wasn't
character-for-character that list was flagged as non-clean — including strictly better ones.

**Why this is more than a cosmetic bug.** A gate with this false positive quietly teaches the
wrong lesson: the cheapest way to make it pass is to *add* an unnecessary dependency (e.g.
invoke `Classical.choice` where constructive reasoning sufficed) so the footprint matches the
expected string. That is precisely backwards — the gate would be training proofs to get worse
in exactly the dimension it exists to measure. SPEC §5.1's wording ("footprint exactly
[propext, Classical.choice, Quot.sound]") admits the literal reading the script implemented;
the intended meaning is *no axiom outside that set*.

**Fix.** The check is now a **membership test**: split the reported footprint, and flag any
axiom not in the permitted set. Re-verified against six cases before rerunning the real gate —
full clean footprint passes; `[propext]` alone passes; `sorryAx` mixed in fails; `sorryAx`
alone fails; a custom axiom (`alpha_prime_pos`) fails; and a multi-line mix of clean and dirty
correctly flags only the dirty one. **The permissive direction of this change is why it needed
adversarial testing rather than a spot check**: loosening a verification gate is exactly where
a plausible-looking edit can silently stop catching what it was built to catch.

**Second-order lesson, from the same edit.** The first version of the fix used
`[ -n "$offending" ] && echo ...` inside a pipeline. Under the script's own `set -euo pipefail`
that returns non-zero in the *normal* (clean) case, which aborted `verify.sh` mid-Gate-2 with
exit 1 — a green-looking Gate 1 followed by silence. Caught only by checking the **exit code**
rather than reading the tail of the log, which showed nothing alarming. Reinforces LL-1: read
the status the machine reports, not the output that looks reassuring.

**Rule produced.** When editing `scripts/verify.sh`'s gate logic, (a) test the new predicate
against a table of cases that includes at least one that *must* fail, before trusting a real
run; (b) confirm the script's **exit code**, never just its trailing output.

---

## LL-9 — A subagent's `git stash` is a repo-wide operation; treat it like `git add -A`

**What happened (2026-08-13).** A background subagent was dispatched to update the LaTeX report
while the orchestrator concurrently wrote a design memo and edited `PLAN.md`. To compare
"before/after" typesetting the subagent ran `git stash` … `git stash pop` on the shared
working tree. `git stash` is not scoped to the files an agent is working on: it swallowed the
orchestrator's **tracked** edits (`PLAN.md`) along with the agent's own `.tex` work. Only the
untracked new files (the memo, the snippet) were unaffected, and only because plain `git stash`
skips untracked files by default — luck, not design.

**Outcome.** No loss: the agent's `pop` completed before the orchestrator's second check, and
everything was verified present afterwards file-by-file. But the window between `stash` and
`pop` is a window in which an unrelated failure (agent killed, crash, conflict) strands another
worker's committed-nothing-yet edits inside a stash entry they did not create and may not know
to look for.

**Rule produced.** LL-1's rule was scoped to `git add -A`. Generalise it: **while any
background worker may be writing to the repo, no agent may run a git command whose blast radius
is the whole working tree** — `stash`, `checkout .`, `reset`, `clean`. Dispatch prompts for
concurrent agents should say so explicitly. If an agent needs a before/after comparison, it
should copy the file aside (`cp x /tmp/x.bak`) rather than move the entire tree through a
stash.

**Second-order note.** The orchestrator caught this only because it inspected the subagent's
live transcript rather than waiting for the final report. The final report would have said
"done, compiles clean" — truthfully — and never mentioned the stash.

---

## LL-10 — A workaround that becomes a convention outlives the constraint that caused it

**What happened (2026-08-13/14).** Because `lean_src/` was originally not a Lake project, Gate 2
compiled each file standalone and cross-file `import` failed. The workaround — each file
re-declares its neighbours' definitions verbatim — was correct at the time, documented in every
file's header, and hardened into a convention. It was then cited as a *reason* in later design
work: the Task-4 memo planned around it, and the first Task-4 implementation duplicated
`shellB`, `dyadicWavenumber` and `dyadicWeight` into a second file with a hand-sync note.

The constraint had already been removed. The Stage-0 cold build made `lean_src/` a real Lake
project days earlier; nobody re-tested the import assumption because it had become background
knowledge rather than a checked fact. A single probe (`import DyadicShell_Statements`, then
`#check`) settled it in under a minute.

**What the workaround was costing.** Duplicated definitions are the worst class of silent
defect this repo can carry: a fix applied to one copy and not the other leaves **both** files
compiling cleanly, **both** gates green, and the mathematics divergent — and no gate can see it,
because each file is individually correct. It is precisely the failure mode the tier system
exists to prevent, reintroduced through the back door of a build-system limitation.

**Rule produced.** When a documented constraint is load-bearing in a *design decision* (not just
in code), re-verify that the constraint still holds before designing around it. Cheap probes
beat inherited assumptions. Concretely for this repo: the "standalone compile, so re-declare"
note is now void, and `scripts/verify.sh` builds the dependency graph then re-elaborates each
file with the project's build directory on `LEAN_PATH`.

**Implementation detail worth keeping, because getting it wrong is invisible.** The gate must
re-elaborate with `lean`, not rely on `lake build` alone: a *cached* build target emits no
`#print axioms` output, so the footprint check would silently pass over files it never actually
checked. Verified by injecting a `sorry` into a gated file and confirming the gate exits 1.

---

## LL-11 — A translated theorem can lose its content and still look faithful

**What happened (2026-08-14).** The Sym² lock is proven for scalar recurrences
(`sym2_recurrence`, Tier A). To use it on the dyadic shell model it had to be translated into
shell space. The translation adopted — and written into a design memo, with candidate
implementations, kill criteria and a pre-registered protocol — was the pointwise constraint
`a_{2n} = c·a_n²`, justified by the exact observation that `k_n = 2ⁿ` makes `λ ↦ λ²` act on
indices as `n ↦ 2n`.

That observation is correct. The translation built on it is nearly vacuous. For **any** pure
power law `a_n = A·rⁿ`:

```
a_n² = A²r^{2n},   a_{2n} = A r^{2n}   ⟹   a_{2n}/a_n² = 1/A
```

constant in `n` and **independent of `r`**. So the constraint's solution set is the entire
one-parameter family of power laws with amplitude `1/c`: it imposes one condition on a
two-parameter family and fixes the **amplitude**, leaving the **slope** free. Since finite-time
blow-up in these models is characterised by the slope, the constraint was blind to exactly the
thing it was supposed to control.

**What it almost cost.** A full experimental campaign — three candidate implementations, a
penalty parameter sweep, `dt` refinement, controls — measuring a quantity that could not move.
Every gate in the repository would have passed: nothing was false, nothing was unproven, no
tier was overstated. The design was simply about the wrong object.

**Why the pointwise form lost the content.** `sym2_recurrence` concerns a **two-root** recurrence
and its squared sequence, `{λ,μ} ↦ {λ²,λμ,μ²}`. The pointwise translation kept the *squaring*
and discarded the *two-root structure* — and the slope information lives in the second root, not
in the squaring. The real content is that the three macroscopic roots are in geometric
progression, which at coefficient level is the exact signature `c₂³ + c₁³c₃ = 0`. That form
**is** discriminating: it separates a Sym²-by-construction sequence from a generic one by
fourteen orders of magnitude.

**Rule produced.** Before implementing a constraint translated from a proven theorem into a new
setting, **compute its solution set in the new setting and check it is smaller than intended.**
A translation that admits everything the original excluded has lost the theorem's content, no
matter how faithfully each symbol was carried across. Cheap test: substitute the simplest family
the new setting supports (here, a power law) and see whether the constraint restricts it.

---

## LL-12 — Negative controls prove a checker can fail; only positive controls prove it can succeed

**What happened (2026-08-14).** The corrected Sym² detector tests `c₂³ + c₁³c₃ = 0` on the
recurrence coefficients fitted to a shell profile. It was first implemented as
`e₂³ = e₁³e₃`, taken from the elementary symmetric functions as recorded in `SPEC.md` and
`LEDGER.md` (`e₁=a²+b`, `e₂=−b(a²+b)`, `e₃=−b³`).

Those are **not** the recurrence coefficients. For a monic cubic `x³ − e₁x² + e₂x − e₃`, the
recurrence form `v_{n+3} = c₁v_{n+2} + c₂v_{n+1} + c₃v_n` has `c₂ = −e₂`. Feeding fitted `c`'s
into the `e`-form flips one sign and turns the residual into `c₂³ − c₁³c₃`, which on a sequence
satisfying the lock *by construction* evaluates to exactly **2.00** instead of 0.

**What caught it, and what would not have.** The **positive** control — a sequence built from an
order-2 recurrence, Sym² by construction, required to read `S < 10⁻⁶` — refused to read zero.
The **negative** control passed happily: generic sequences give `O(1)` under *both* the correct
and the inverted formula, because both are generically nonzero. So the negative control, which
this repository has always mandated, was blind to this defect.

**What it would have cost.** An inverted detector reports "no Sym² structure" **everywhere**,
including where the structure exists. That is a false negative that looks exactly like a clean
null result — the most expensive kind of wrong answer, because nothing about it invites
suspicion. It would have been reported as a finding about the cascade.

**Rule produced.** *A checker that cannot fail is not a checker* is **half** the requirement.
The other half is an input on which the harness must *fire*. Where that lives depends on the
harness kind, and getting this distinction right mattered:

- **Identity/inequality verifiers** already satisfy it by construction — their main sweep asserts
  the identity *holds* on many valid inputs ("240 cases, all exact LHS == RHS"), which an
  inverted implementation would fail. Auditing the repo's six older harnesses against a first,
  blunter version of this rule showed all six were already sound; the rule, not the harnesses,
  needed refining.
- **Classifiers, detectors and judgments** do **not**: their body returns a verdict, and an
  implementation that rejects *everything* passes the negative control unscathed. For these an
  explicit positive control is mandatory.

Recorded in `SPEC.md` §7.3 (with the harness-kind table) and in the Tier B row of §0's gate
table. Implemented in `exploration/sym2_signature_detector.py`,
`tests/tier_b_grid_adequacy.py` and `tests/tier_b_regime_adequacy.py`, each of which runs both
controls on every invocation and refuses to report if either fails.

**Second-order note.** The first draft of this rule was too blunt — it would have flagged six
working harnesses as non-compliant. Checking compliance *immediately after writing the rule*, on
the repo's real harnesses, is what exposed that. A rule adopted without auditing what it
condemns is a rule that will be quietly ignored.

**Note.** This is the human owner's own "instrument principle", arrived at independently from
the other direction: *"vos harnais adorent les contrôles négatifs; il manque le contrôle
positif."* It is now a rule rather than an observation.

---

## LL-13 — Check whether the answer is already a theorem before measuring it

**What happened (2026-08-14).** Two numerical campaigns measured whether the truncated viscous
dyadic system stays bounded. Retrieving Cheskidov's equation (1.1) and thresholds from the
primary source showed the programme's dissipation `ν k_n² = ν 2^{2n}` corresponds to dissipation
degree **α = 1**, inside the band `α ≥ 1/2` where global regularity is a **published theorem**.
The campaigns were confirming a theorem.

**Relation to the same day's grid defect.** They are the same failure at two levels. The grid
defect was *"varied a parameter over a range where it could have no effect"*; this is *"ran in a
regime where the answer is forced"*. Both are an instrument pointed where no signal can exist.

**Rule produced.** Before designing a measurement, classify the regime: is the answer **open**,
or is it already established? A proven regime is not forbidden — it is the correct place for a
control (a proven-regular regime is the only honest positive control for a boundedness
instrument; a proven-blow-up regime is the only place a proposed regularising mechanism can
demonstrate anything). What is forbidden is running in one and reporting the result as a
discovery. Mechanised as `tests/tier_b_regime_adequacy.py`, whose negative control is the
programme's own `α = 1`.

---

*Add new lessons above this line, most recent first is not required — group by theme as the
log grows. A lesson earns an entry here when it changed a rule somewhere else in the repo
(`PLAN.md`, `CLAUDE.md`, or a memory file) — if it didn't change a rule, it probably belongs
in an escalation file or a design memo instead, not here.*
