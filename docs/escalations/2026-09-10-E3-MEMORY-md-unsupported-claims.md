# E-3 — `MEMORY.md` (committed in `d980c18`) states results that were never computed, and one that this repository's own data contradicts

**Rule triggered:** E-3 (contradiction with the record) — *"This is a discovery: report it prominently,
do not bury it."* Also SPEC §0 (honesty clause), §2.4 (narrative quarantine), §7.6 (honest difficulty
language), and PLAN §9.4 / LL-1 (the broad-`add` race).
**Filed by:** orchestrator, 2026-09-10. **Status:** ESCALATED — no file of another author was deleted
or rewritten; a correction banner points here.

---

## 1. What happened, mechanically

While this session was running the two gates, a concurrent process staged and committed the whole
working tree as `d980c18`, including files this session had not finished verifying and files it did
not write. This is precisely the `git add -A` race recorded in PLAN §9.4 after it happened twice on
2026-08-12. It happened a third time.

Two consequences beyond the race itself:

- **The commit subject is factually wrong.** It reads *"integrate FourierStateZ3 v2.1"*. The v2.1
  submission was **REJECTED**: compiled as submitted it produces **16 errors** (kernel log:
  `docs/proposals/2026-09-09-FourierStateZ3-v2.1-kernel-log.txt`; review:
  `docs/proposals/2026-09-09-review.md`). Nothing from it was merged. What is in `lean_src/` is the
  pre-existing active file with one import change.
- **`MEMORY.md` was created at the repository root**, outside `docs/narrative/`, carrying untiered
  claims presented as established fact, including the global status line *"100% CERTIFIÉ"*.

## 2. The claims that were never computed

`MEMORY.md` §1.C is titled **"Validation de la Contre-Détonation Empirique (Rust Tier B)"** and states:

| claim as written | status |
|---|---|
| *"Tir de Calibration (α′ = 0) : Divergence violente (blow-up) répliquée fidèlement à t ≈ 0.38 – 0.40"* | **No Euler solver exists in this repository, and none was run.** No such trajectory, dataset, or harness is present. |
| *"Alignement Vitesse/Vorticité : cos(u, ω) → 1.0"* | never computed |
| *"Annihilation du terme de Lamb : ‖u × ω‖ → 0"* | never computed |
| *"formation d'un flot de Beltrami stationnaire et régulier pour tout t ≥ T\*"* | never computed |
| the section's tier label **"Rust Tier B"** | **category error**: SPEC §2 bars floating point from Tier B entirely. A float computation is Tier C in any language. |

The only Rust in this repository is `exploration/triad_frustration_rs/`, which computes a static
lattice quantity on prescribed fields. **It integrates nothing in time.** It carries a
`TIER C — EXPLORATORY, NO CLAIMS` banner precisely so that it cannot be read as the above.

## 3. The claim this repository's own committed data contradicts

`MEMORY.md` §1.C also lists, as a validated outcome of switching the T-dual shield on:

> *"Explosion de l'Indice de Frustration Triadique 𝒟(M)"*

**The measurement says the opposite about what that growth means.** From
`data/triad_frustration/dm_readings.csv` (committed in the same commit) and
`docs/designs/TRIAD_FRUSTRATION_DM.md`:

- 𝒟 grows only for **random independent phases** — which is the *null model*, and the growth is the
  null model's own arithmetic (a random walk over the same number of terms);
- a **phase-coherent** field on the same lattice, with the same envelope, gives 𝒟 **flat in M**
  (slope −0.20 at γ = 11/6; 𝒟 ≈ 1.6 × 10² from M = 12 through M = 20);
- so the growth is a property of the phases put in, **not** of the arithmetic rigidity of ℤ³, and it
  is not evidence that any cascade is stifled;
- separately, two of the three coherent comparators are degenerate (one has zero net flux across
  every sphere; one has identically zero transfer by parity), so 𝒟 is **not a robust instrument**.

Nothing in the run involved α′, a T-dual cutoff, or a "shield": no field computed here solves any
equation, and α′ never enters the computation.

## 4. Why this matters more than a wording slip

Stream 0 ranks **narrative → publication** as the programme's highest-consequence surface: *"A claim
that reaches a video has left the system entirely, and the retraction, if one is ever needed, is
public."* `MEMORY.md` describes itself as the **"Registre de redémarrage instantané pour Claude Code,
Gemini CLI, et les agents autonomes"** — that is, a file written to be read *as fact* by the next
agent, at the root of the repository, ahead of `SPEC.md`. An agent restarting from it would inherit
a replicated Euler blow-up and a Beltrami attractor as settled results.

This is LL-11's failure mode (a number that looks like a mechanism because it was never compared to
chance) compounded by LL-2's (a self-report substituted for the artifact).

## 5. What was done, and what was deliberately NOT done

**Done:** this file; a correction banner at the top of `MEMORY.md` pointing here, changing no other
line of it; `LEDGER.md` already records the 𝒟(M) findings and the v2.1 rejection at their true tiers.

**NOT done, deliberately:** no deletion or rewriting of another author's file, no history rewrite of
`d980c18`, no attempt to "fix" the commit message. Those are the owner's calls.

## 6. Smallest questions whose answers unblock — **ANSWERED 2026-09-10 (owner)**

1. **Does `MEMORY.md` stay at the repository root?** → **Yes, it stays**, as the restart register it
   is, carrying the reading notice at its head. It remains untiered and gate-free, and says so.
2. **Is §1.C deleted or rewritten as a plan?** → **Rewritten as a plan** (owner instruction,
   verbatim: *"réécrit comme plan"*). Done in `3bb2d31`: §1.C now states what must be measured, the
   two blocking prerequisites, and the decisive control that separates the damping term from the
   T-dual metric.
3. **How is the erroneous `d980c18` subject handled?** → **`git notes` annotation**, attached
   2026-09-10. History is not rewritten; the note travels with the commit and names the erratum, the
   evidence, and the PLAN §9.4 race. (`git log --notes` to see it.)

## 7. Follow-on, same day: the source of the §1.C claims was audited

The owner then pointed at the solver those claims came from (*"j'ai travaillé sur un solver dual
scale cf xdev folder LeanFlow, vérifie leurs résultats"*). It was read at source level; the review is
`docs/proposals/2026-09-10-leanflow-counterdetonation-review.md` and its verdict is summarised in
`LEDGER.md` at Tier C.

**The claims fail for reasons internal to the code, not merely for lack of a run here.** The
Beltrami attractor is produced by an explicit damping term on the negative-helicity amplitudes,
and the reported alignment is a monotone function of that damping; the frustration index returns
`INFINITY` on a frozen flow because only its denominator is tested; and the enstrophy threshold is
crossed by an ordinary cascade into a 20-shell truncation. One genuine asset was found and adopted:
`leanflow-core::r_eff` reimplements `max(R, α/R)` and agrees exactly with this repository's Tier A
`Reff`.
