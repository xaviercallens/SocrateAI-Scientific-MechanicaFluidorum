# Manuscript audit — `verifier_in_the_loop.tex` (draft of 2026-09-18)

**Method.** The draft was audited by an Opus 5 agent following
`docs/harness/agent-manuscript-auditor.md`: every repository statistic recounted with git/ls/wc;
every number traced to `LL.md`, `SPEC.md`, `CORE_TAIL_CAP.md` or the sister project's
`CHANGELOG.md` / paper source; every claim about Terence Tao's views checked against the cited
pages; bibliography spot-checked against Crossref and the live URLs; tone and jargon screened.
The drafting session (Fable 5.1) then applied every finding. This file records the verdict, the
findings, and what changed, in the claim-auditor format the procedure requires.

`VERDICT: 5 blocking, 12 substantive, 11 notes` — the auditor's second pass; its first pass
scored the same findings 4 / 14 / 12, the difference being that the mis-attributed Tao page
(below) was promoted from substantive to blocking. All resolved before release.

## Blocking

**The `taoviews2026` bibliography entry was credited to "T. Tao"; the page states it was
compiled and drafted by an AI assistant and reviewed and corrected by him.** In a paper arguing
that AI-generated text must be labelled, that is the one error a referee would single out, and
the Disclosure's "every reference confirmed" sentence was false as stated. *Fixed:* provenance
stated in the entry; the quoted rule is now Tao's own formulation from that page ("only rely on
AI where you are able to red-team its output").

**The headline empirical claim was contradicted by the paper's own table.** The draft said
"Not one entry was caught by a verification gate, and not one is a proof error"; three rows of
Table 1 (the two `sorryAx` incidents, and the gate's own false positive) were caught by, or
were, the gate. `LL.md`'s synthesis makes the scoped claim ("LL-20 through LL-27 … both gates
green"), not the general one. *Fixed:* "Of the twenty-two entries, nineteen occurred with both
gates green and are not proof errors; the three exceptions …" in §9.1, §9.3, the abstract and
the introduction.

**Palomar was described as having three automated checks; the announcement enumerates two.**
The disclosure audit is part of the language-model check (b), not a third check. *Fixed* in §2.

**The molecular-dynamics pre-registration numbers were stale.** The registered value was a
point ("near 0.6", commit `de1f539`, 2026-09-17, ten hours before the first MD data), not a
range; "0.56–0.62" were two estimators, since corrected at the sister project's HEAD to a fitted
$0.538 \pm 0.011$ (0.61 dense/smooth) against 0.54; "within the registered range" had no
referent. *Fixed* in §9.2, with the correction itself now cited as the discipline working.

**The "interception theorem" was said to have been kernel-checked; its file does not compile
(17 errors against the current toolchain, per the sister project's own README).** *Fixed:* the
example now carries both rules — a self-reported kernel check is not one, and a kernel would
not have noticed the circular antecedent.

## Substantive

- "found still live on a public dataset weeks later" — same day (both changelog entries are
  dated 2026-09-15). *Fixed.*
- The withdrawn-claims taxonomy was stated as four values; the appendix has six headings.
  *Fixed:* six headings quoted.
- Peer-review adjudication mis-scored as 2/2; it was one extraction artefact, one genuine
  defect, two rebuilt for robustness. *Fixed.*
- Lean line count 5,559 included `lakefile.lean`; the twelve mathematical files total 5,498.
  *Fixed.*
- The abstract did not say what the paper does not address. *Fixed:* last sentence added.
- §7 stated the sister project's physical finding in the paper's own voice and dropped the
  working-fluid dependence. *Fixed:* "Its current position … picoseconds for water, nanoseconds
  for air."
- "every real catch by a control came from a published theorem" widened `SPEC.md`'s "in the
  2026-08 cycle". *Fixed:* scoped to the August cycle.
- "A broad add twice swept a mid-edit proof" — only the second was a proof. *Fixed.*
- The permission-boundary paragraph conflated two episodes and asserted a "terminal" routing
  not in the repository record. *Fixed:* rewritten to the overnight-run episode as the report
  records it; the unrecorded clause dropped.
- "converging independently on parts of it [the proof]" — the sister project re-derives no
  part of the proof; it converged on two instruments. *Fixed* in the abstract.
- Version 5.6.0 vs 5.6.1: at audit time the archived (Zenodo) version was 5.6.0 and the
  working source said 5.6.1. *Fixed:* "archived version 5.6.0 … working source has since moved
  to 5.6.1". *Superseded the same day:* the sister project archived 5.6.1 as
  10.5281/zenodo.22828106 nine minutes after this paper's first version was published; the
  citation was updated to 5.6.1 and this paper republished as a new Zenodo version
  (10.5281/zenodo.22829767; all versions 10.5281/zenodo.22827933) at release v1.10.2.
- "twenty-eight design memos" — the directory holds 29 files, two of which are decision
  records. *Fixed:* "twenty-seven design memos and two decision records".
- `lean4` and `mathlib` were in the bibliography but never cited. *Fixed:* cited in §3.

## Notes (all applied)

193 theorems now given with the top-tier count (186; seven demoted); the ledger checker's
positive control named; "three mechanisms killed" → "at least four"; "sixteen-hour" →
"sixteen-and-a-half-hour"; Table 1's LL column explained in its caption and the repository URL
added to Reproducibility; the model-role mapping moved into the Disclosure (drafting: Fable 5.1;
report review and this audit: Opus 5; screen proposers: Sonnet 5; judge: Opus 5); lens names
matched to `LL-28` ("optimisation, cost, controls"); the sister project's CI described
precisely (stale enforced pipeline; current check on demand); "85 declarations" → "85
declarations with verified axiom footprints"; the "lock" template quoted with the sister
project's own term rather than generalised; the sister project's withdrawn tool named by its own
term (a `physlib` world model, not a "physics engine"); "both verification gates" in the
abstract expanded to "both mechanical gates (the kernel and the exact-arithmetic harness)";
three self-framing phrases trimmed; common ownership of the two laboratories stated in §9.2's
opening; the orphan `\label{sec:disclosure}` removed.

## What the audit did not find

Every repository statistic reproduced on recount (first commit 2026-08-12; 167 commits; 13
active days; 11 tags; 12 Lean files; 193 `#print axioms` footprints summing exactly per file;
9 escalations; 31 lessons with no gaps; 22 float-free harnesses plus `controls.py`). Every
number the brief asked for reproduced against its source: 6.6×, 2846, $1.35\times10^{8}$,
5.5 %, 1.5 h, ×5.3/×2.2 and +0.0099/+0.0143, "under a second", $2.4\times10^{-16}$ (worst
calibration error 2.397e-16), twelve orders of magnitude, 4,694 laws, and the 258-vs-193 pair.
The three registered brackets on one series reproduce from `CORE_TAIL_CAP.md`: $M=16$
[1.040, 1.052] measured 1.0324 (below); $M=32$ [1.0300, 1.0377] measured 1.0386 (above);
$M=64$ [1.041, 1.047] measured 1.043082 (inside), with the two falsifications localised to the
injection and the survival fraction respectively. §4 is a sentence-for-sentence rendering of
`SPEC.md` §7.3. Every spot-checked bibliographic record resolved and matched (Notices
72(1) 2025; Bull. AMS 61 (2024) 211–224; Nature 651 (2025) 607–613; Found. Comput. Math. 1
(2001) 255–288; Forum Math. Pi 5 (2017) e2; PNAS 115 (2018) 2600–2606; Nature 625 (2024)
468–475; arXiv:2512.07087; both GitHub repositories, with `openai/NavierStokesAndEuler`
created 8 September 2026 on Lean 4.34.0-rc2). The sister project's withdrawn claims, DOIs,
page count, the four-declaration `LerayAlphaLinearization.lean`, the 0.86λ→0.96λ benchmark
catch, the "45 theorems"→36 convention audit, the two forecasts not borne out, the 15 September
upload-script near-miss and the same-day dataset discovery all verified. No overselling
vocabulary and no internal protocol codes were found in the external prose.
