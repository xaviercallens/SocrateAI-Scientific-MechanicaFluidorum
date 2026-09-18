# CROSS_STREAM_INTEGRATION.md — an implementation plan for adopting the tools and progress of Mathesis (Stream 0), Agora-LeanMaster, and Mensura

**Tier: C (proposal).** Nothing here is installed, adopted or decided. This is a design memo in
the programme's standing practice: derive and hand-check first, hand a fully specified skeleton
to an executing agent second. Every task below carries a Definition of Done and a kill
criterion. Several items are **owner decisions** and are marked as such; a session may not take
them (`PLAN.md` §3 E-1/E-4, `LL-23`).

**Authored** 2026-09-18 from a full read of the three repositories via the GitHub API, this
repository's own `docs/briefs/2026-08-25-cross-stream-alignment.md`, Stream 0's
`docs/STREAM_MAP.md`, and direct verification of every claim made below about *this*
repository. Where a statement is about another repository it is a **Tier C report of what that
repository's files say**, never an endorsement — the convention Stream 0 uses and this
repository adopted on 2026-08-25.

---

## 0. The one-paragraph summary

Three sibling repositories have built, independently, the three things this programme has been
doing by hand: a **machine-checkable claim ledger with a proved soundness theorem** (Mathesis),
a **kernel-truth declaration graph plus a statement lock** (Agora-LeanMaster), and a
**documented chain of adversarial decisive experiments on our own scientific target**
(Mensura). Two of the three also run a **five**-tier notation that this repository adopted only
four fifths of. The plan below adopts what is portable and already tested, declines what is
not, and records the two places where a sibling's record about us is stale and needs correcting
in the other direction.

---

## 1. The three repositories, as they actually are

Names mislead here; each entry is what the files show.

### 1.1 `SocrateAI-Scientific-Mathesis` — Stream 0, the notation and the gate

Pushed 2026-08-25, 751 KB. Its object of study is the record: "the first theorem here is about
ledgers, not about geometry." It ships:

- **A five-tier order**, `X < C < L < B < A`, with an orthogonal *evidence kind* that **caps**
  the tier (`lean_axioms`→A, `exact_harness`→B, `citation`→L, `argument`→C,
  `numeric`/`llm_output`→X). Our own Tier B definition is quoted verbatim in its
  `docs/TIER_CALCULUS.md` as one half of the collision that motivated the whole notation.
- **A kernel-proved soundness theorem.** `lean/Mathesis/TierCalculus.lean` proves
  `tier_le_of_depends` (soundness on direct citation edges propagates through the entire
  transitive closure) and its corollary `no_kernel_claim_rests_on_weaker`. Axiom footprint of
  the theory declarations: **empty** — not even `propext`. It ships positive *and*
  `decide`-checked negative witnesses.
- **`tools/mathesis-gate/mathesis_gate.py`** — one 21 KB file, Python 3.9+ standard library
  only, no dependency on Mathesis itself. Four independently switchable checks: axiom hygiene
  (indentation-, attribute- and nested-comment-proof), **vacuity**, per-declaration-class
  footprints, and **transitive** ledger soundness. 13 parser self-tests run before any file is
  examined; if they fail the gate declares *itself* broken and exits 1.
- **`ledger.jsonl` + `schemas/ledger.schema.json`** — the machine-readable claim record. The
  tier letter is **inside the identifier** (`MF-A-0007`), so a promotion changes the id and a
  stale citation elsewhere becomes lexically wrong rather than silently wrong. `MF` is already
  a reserved stream code in the schema's regex and in both checkers.
- **Two independent ledger checkers**, Python and Rust, written against the specification and
  not against each other, compared byte-for-byte on a 30-case hand-enumerated corpus. The Rust
  crate has an empty `[dependencies]` and a hand-written JSON parser, on the stated ground that
  "a differential gate whose two sides call the same JSON library tests that library once and
  the ledger logic zero times."
- **`HARDNESS.md`** (ten invariants, each naming the mechanical check that fails when it is
  violated, plus a section on what is deliberately *not* an invariant) and **`FRONTIER.md`**
  (TODO / **NOTODO** / Frontier). This repository has no equivalent of either.

### 1.2 `SocrateAI-Scientific-Agora-LeanMaster` — the large Lean corpus and its tooling

Pushed 2026-09-18, 47 MB, 207 Lean files across nine libraries, toolchain
`leanprover/lean4:v4.33.1` with Mathlib pinned by tag. Builds green (3787 jobs, 0 errors; 485
theorems audited, 0 failing). **It has no CI of any kind** — every number is a human or agent
session writing a result into a markdown file.

It is a string-theory formalization, not a fluids one. What matters here is its tooling and two
of its admissions:

- **A kernel-truth declaration graph already exists**, twice. `tools/lean_depgraph.lean` runs
  inside the elaborated environment and emits, per constant, the constants its *type* uses and
  the constants its *proof body* uses — "an edge exists exactly when the kernel term really
  mentions the other constant." `tools/theorem_atlas.py` consumes it and produces, among other
  things, a ranked list of **unification candidates**: statements proved independently in two
  libraries that ought to be one theorem with a corollary. A second, weaker, regex-based
  extractor (`leangraph/`) also exists; that repository's own skill file says to prefer the
  kernel one.
- **`tools/statement_lock.py`** — SHA-256 of each theorem's statement text up to the top-level
  `:=`, so replacing a `sorry` with a proof does not change the hash but weakening a hypothesis
  does. Its rationale is exactly this programme's open problem: "The kernel checks that a proof
  proves its statement. It does not check that the statement is still the one that was
  reviewed."
- **`tools/axiom_audit.py`** — already parameterised by `LEAN_PROJECT_ROOT` for reuse,
  catches `sorryAx` transitively and `Lean.ofReduceBool` (i.e. `native_decide`), and
  distinguishes "could not check" from "checked and failed" because a stale `.olean` once made
  it report "89 theorems audited, 89 failing" — an infrastructure failure wearing the costume of
  a proof result.
- **The same five-tier order, formalized in Lean** (`DualScaleM24Formalization/Epistemic/`),
  with `Sound`, `Depends`, `tier_le_of_depends` and a `decide`-checked negative control witness
  — arrived at independently of Mathesis.
- **"Conditional Tier A" / hypothesis smuggling**, its own name for the sharpest finding in the
  repository: a theorem that compiles with a clean axiom footprint while taking an unproved
  hypothesis (there, `Summable`) as given. Its `docs/RIGOR_ROADMAP.md`: "a hypothesis-smuggling
  pattern invisible to both a sorry-grep and a bare axiom check. Any theorem like this should be
  reported as **conditional Tier A** … never folded into a plain 'verified' count."
- **An honest preamble.** An earlier README described the project as "the first fully certified
  String Theory"; an audit found headline claims holding only for much narrower Lean statements
  (a bound over ℕ presented as holding over ℝ), no "zero free parameters" theorem anywhere, and
  one real bug. Its `ROADMAP.md` opens "Vision document, not a status report… has not been built
  or attempted." Its `LL.md` opens by labelling its own headline metrics a known overclaim.

Two things there are *not* what their names suggest, and this memo's earlier
`NEURO_SYMBOLIC_HARNESS.md` §4 must be corrected accordingly (§3.6 below):
`StringTheoryFoundation/PhysLib/` is a single 4.9 KB file of `Int` arithmetic that imports
nothing from the real `physlib` and says so in its own scope note; `FluidDynamics/` is one
5.6 KB file of `Nat` arithmetic in which `energy_dissipation_monotonic` is `Nat.sub_le`. The
only substantive Navier–Stokes Lean there is `StringTheoryFormalization/NSMath/` (five
Mathlib-backed files: fractional Sobolev, energy bounds, mild solutions, Fourier multipliers),
and it is the material its own roadmap flags as conditional Tier A.

### 1.3 `SocrateAI-Scientific-Mensura` (internal name SOCRATES) — the parallel attack on our target

Pushed 2026-08-25, 4.5 MB. It is the closest repository to us scientifically and the one whose
*record* is worth more than its results. Its dual-scale and Navier–Stokes track stopped at a
commit dated 2026-08-13; everything after is hypergraph work. **Its CI has been disabled since
2026-08-15** — the workflow was moved to `.github/workflows-disabled/`, which GitHub does not
read — so no gate has run there in five weeks. Our `scripts/verify.sh` is strictly ahead.

**The headline result, and what it is not.** Its README reports that the shell-model analogue of
Hypothesis U fails in the bare model, peak enstrophy diverging as `α'^-0.672` against
Kolmogorov's `-2/3`. Filed Tier B. Three qualifications matter before anyone here cites it:

- **It is inviscid.** The simulator's default is `viscosity = 0.0` and the generating script
  never passes one. A measurement at `ν = 0` cannot contradict a regularity theorem that
  requires dissipation, so any sentence of the form "SOCRATES measured that the dyadic model
  fails Hypothesis U, contradicting Cheskidov" is false. Our own `OP2_LITE_CANDIDATES.md` §3
  already says the sharper thing: at `ν = 0`, finite-time blow-up for the inviscid dyadic model
  is a published theorem, so a result proving regularity there is presumptively wrong.
  Divergence at `ν = 0` is the expected outcome, not a discovery.
- **It is not the α-parametrised family.** Coupling exponent `1`, dissipation exponent `2`,
  neither a free parameter anywhere in the code, and no dissipation sweep exists. The repository
  therefore cannot speak to an `α ≥ 1/2` threshold at all.
- **"Diverges" means as the cutoff is removed**, not in finite time. Every run completes. With
  energy conserved and a Kolmogorov spectrum, `Ω ~ k_max^{4/3}` is close to arithmetic.

It also survived a real attack: a sibling predicted the exponent was a fixed-horizon transient
that would drift toward `-1` at longer horizons. Measured across an eightfold horizon range the
drift was `-0.0001` and the seed spread `0.0006`. **The prediction was retracted in the
predictor's own document**, which is the behaviour this programme asks for.

**What is worth taking is the W1 chain, and it is a negative result five rounds deep.** The
question W1 exists to answer — does a symmetric-square lock move the exponent off `-2/3`? — has
**never once been measured.** Every round was consumed by instrument defects, and the record of
that is the most instructive artefact in any of the three repositories:

| Round | Claimed | Outcome |
|---|---|---|
| 1 | A locked sweep yields an exponent | **Anomaly.** 0 of 9 runs met the gate. The tempting regression over the censored points is printed in the findings *only so nobody re-derives it and mistakes it for the measurement* |
| 2a | The energy-oracle defect is fixed | **Refuted on completeness.** Every number reproduced digit for digit; a real branch point was found and kept; but the step rule still flipped sign, and the new regression test was pinned where it passes rather than where the claim lives |
| 2b | A step-doubling estimator makes drift flat | **Confirmed, then refuted on generalization** — at a point the round itself had named in advance as its own attack surface |
| 2c | A curvature term repairs the seed dependence | **Confirmed, then refuted a third time.** The diagnosis is excellent: every term of the old rate vanishes at a turning point of a lock parameter, which is exactly where truncation error is largest |
| 2d | — | **Never started** |

The structural question left open is the one worth carrying across: after three rounds of
"sweep twice as many seeds, get refuted by a skeptic who sampled one density level higher", the
findings ask whether **finite seed sampling is the wrong validation strategy for this rule
family**, and name two alternatives that would change the argument rather than repeat it. That
is a programme reasoning about its own method, and it is rarer than any result in these trees.

**The two things there that we should adopt** are in §5 Phase P3 below: the
`decisive-experiment` skill, a six-phase adversarial workflow whose most valuable content is
four accumulated lessons about auditing the auditor; and the **compensated-flatness gate**,
which asserts no sign flip, every halving at least eightfold, and bounded spread, *instead of* a
fitted convergence order — because that repository has a worked example of a scan fitting to
`≈3.95` while individual halvings got worse and flipped sign. That is our own LL-20 (report the
trend in the units the claim is about) rediscovered independently in numerics.

**One thing there must not be copied.** Its `.claude/settings.json` sets auto-accept for all
tools with `rm`, `curl`, `wget` and `docker` on the allow-list. That is `LL-23` in a sibling
tree: an allow-list containing general-purpose commands does not deny anything. Flagging it is
owed; copying it is not an option.

---

## 2. What the prior record already decided, and what has gone stale

`docs/briefs/2026-08-25-cross-stream-alignment.md` is this repository's own review of the
sibling streams, arbitrated by the owner on the day. Its six proposed actions stand as follows:

| # | Action (2026-08-25) | Status today | Evidence |
|---|---|---|---|
| 1–3 | Send Stream 6 the Leray theorems, the corrected gap inventory, the depletion screen | ✅ done, memo transmitted | `docs/proposals/2026-08-25-MEMO-sent-to-Stream6.md` |
| 4 | Adopt Tier **L** and re-letter the literature rows | ✅ partly — **L adopted, X was not** (§3.1) | `SPEC.md` §0 cites `MX-C-0007` |
| 5 | Decide the `Reff` migration (move / keep as a second independent proof / both) | ⬜ **open owner decision, 24 days** | `MX-C-0011` |
| 6 | Write "Mathlib only, from other streams" into `SPEC.md` | ✅ done | `SPEC.md` §7.2b (axiomatic quarantine) |

Two entries in Stream 0's own records about us are now **stale in our favour**, and the
correction owes in the other direction:

- `docs/STREAM_MAP.md` surface #2 records "Stream 1's gate depends on Stream 5's working tree"
  as a live fragility, and `HARDNESS.md` H10 names it as the failure mode Stream 0 is avoiding.
  **We fixed it ourselves on 2026-08-13**: `lean_src/` is a standalone Lake project with Mathlib
  pinned by revision and the lockfile tracked; Gate 2 prefers the local `.lake` and falls back
  only if absent. Mathesis's own Gate 2 now lists *our* `lean_src` as its first Mathlib
  provider, so the dependency currently runs the other way.
- The stream map lists seven streams as of 2026-08-13 and contains **neither Agora-LeanMaster
  nor Mensura**, both of which exist and one of which is the largest Lean corpus in the
  programme. The map has no row for them and therefore no record of the surfaces where their
  claims cross ours.

---

## 3. Findings that change something here

Each is verified against this repository, with the command that verified it.

### 3.1 We adopted four fifths of an owner decision

`MX-C-0007` (owner, 2026-08-14) adopted **five tiers** as programme notation. `SPEC.md` §0
records the decision and implements **four**: C, L, B, A. `grep -c "TIER X" SPEC.md` → `0`. All
22 files in `exploration/` open with `# TIER C — EXPLORATORY, NO CLAIMS`; the programme banner
is `TIER X`.

Why it matters beyond a letter. Under the five-tier notation, **C is *conjecture* and X is
*exploratory output that may steer a search but may never support a claim*.** Our single letter
C carries both. Concretely, the entire adversarial transient series `Z_max/Z₀` at `M = 2..64` is
`numeric` evidence, which caps at X; we letter it C, the same letter our design memos use for
mathematical conjectures. Our *usage* has been correct throughout — the report says explicitly
that the series is not a verdict and bounds one constructed family's transient — but the letter
does not distinguish "a conjecture we might later prove" from "a float we may never cite."

**This is a notation alignment, not a re-verification.** Nothing changes about what is true.

### 3.2 Gate 2 walks a hand-maintained list of twelve filenames

`scripts/verify.sh:55` is `for f in LocalDualScale DyadicShells … HelicalBasis; do`. Our own
`LL.md` records the "unwired file rots silently" failure mode, and `CLAUDE.md` instructs every
session to remember to add new files to this list. Mathesis's Gate 1 discovers harnesses by
glob **specifically so that the failure requires actively misnaming a file rather than merely
forgetting a line**, and fails loudly on an empty result because "an empty gate is not a gate."
Our Gate 1 already globs `tests/`; Gate 2 does not.

### 3.3 We have no vacuity check, and the motivating example names our own hypothesis

`mathesis_gate.py`'s vacuity check catches `def P : Prop := True`, theorems concluding such a
predicate, and `def Real := Float` type shadowing. Its README states the shape was "found in the
wild while building this tool". Mathesis's `MX-C-0006` locates it: a file in Stream 5's tree
containing `Real := Float`, `Prop := True`, and

```lean
theorem hypothesis_U_bound (D : EnstrophyFunctional) : uniformBoundedness D := by trivial
```

with a docstring claiming to prove Hypothesis U. That file is imported by nothing, and our
axiomatic quarantine (`SPEC.md` §7.2b) means it can never reach us. But it is a vacuous claim
of **our** hypothesis, by name, sitting in a sibling tree, and we have no mechanical check that
would catch the same shape if it were written here.

Good news, verified: `grep -rnE ":\s*Prop\s*:=\s*True|def (Real|Complex|Rat|Int|Nat)\s*:=" lean_src/*.lean`
returns **nothing**. The check would pass today. That is the moment to adopt it — not after it
would fail.

### 3.4 We have no statement lock, and we have four files waiting on a human audit

Our honesty clause reserves *statement adequacy* to human audit, and `LEDGER.md` carries files
marked DRAFT pending exactly that. Nothing in the repository detects a statement changing after
its audit. `tools/statement_lock.py` hashes each theorem's statement up to the top-level `:=`,
so a proof repair does not disturb the lock but weakening a hypothesis does. For a programme
whose central epistemic move is "the kernel checks the proof; the human checks the statement",
this is the missing half of the pair.

### 3.5 Our own headline counts are stale in the ledger, again

`LEDGER.md`'s header reads "Last verified: 2026-08-13 … 70 Lean theorems kernel-compiled, of
which 63 carry Tier A claims". The gate certifies **193**, of which 186 carry Tier A. This is
`LL-34` (a count is a convention that drifts silently) recurring in the one file that is
normative about claims. It is also exactly what `mathesis_gate.py --ledger` plus a
regenerate-from-source discipline is designed to prevent.

### 3.6 Correction to `NEURO_SYMBOLIC_HARNESS.md` §4 (written earlier today)

That memo proposed building **LeanGraph** from scratch, with a milestone of reproducing our
per-file footprint counts. That was written from a read of the LeanMaster *simulator*
repository, where the name does not appear. In Agora-LeanMaster a kernel-truth declaration
graph **already exists** (`tools/lean_depgraph.lean` + `tools/theorem_atlas.py`), with DAG
verification, transitive reduction, PageRank, unification-candidate detection, five export
formats and an interactive explorer. **Task L1 in that memo is therefore withdrawn and replaced
by a port** (task `X4` below). The memo's other two components (LeanRAG, leanDataStore) stand as
proposals; nothing under those names exists in any of the three repositories.

Recording this as a correction rather than quietly editing the earlier memo is the standing
rule (`SPEC.md`; the sister project's "corrections are recorded, not silently rewritten").

### 3.7 Three inbound defect reports about **this** repository, unactioned

Mensura's `docs/QUANTUMFLUIDS_RETROFIT.md` contains three findings aimed at us. They have been
sitting in a sibling repository for three weeks and nothing here records them. Two I verified
today; the third I cannot verify without a run and is recorded as inbound, not accepted.

**(a) `data/dyadic_omega_sup.csv` puts two different quantities in one column. Confirmed, and
it is worse-specified than the report says.** Verified: the file has 15 rows with
`status=OK` and 21 with `status=INFEASIBLE`. Every INFEASIBLE row has `steps=0`, `t_stop=0.0`
and `E_final = E_initial`, so nothing was integrated — and `sup_Omega` is populated anyway, with
`0.5`, `6.5`, `1.0`. Those are the enstrophy at `t = 0`, not a supremum over a trajectory. The
`.meta` sidecar does say INFEASIBLE configurations are "NOT integrated", so a careful reader is
warned; the column name is still wrong for 21 of 36 rows, and any tool reading the column
without filtering on `status` inherits a silent error. This is `LL-18` exactly — one field
covering two meanings — in a committed dataset rather than in a running instrument.

**(b) `OP2_LITE_CANDIDATES.md` presents `β = −2/3` under a "pre-registered" heading. Partially
confirmed, and it is a clarity defect rather than a falsehood.** Line 264 reads
"**Thresholds, pre-registered:** `β = −2/3` ⇒ no effect (the measured control value)". The
parenthetical is honest and the practice is right: you pre-register a threshold whose value came
from a prior measurement. What is missing is the attribution — *whose* measurement, in *which*
model, at *which* viscosity. Given §1.3 above, the distinction is load-bearing: a threshold
imported from an inviscid model into a viscous question would be the `LL-16` failure (a control
encoding a premise that does not hold where it is applied). One clause naming the source fixes
it.

**(c) Our `ν = 0` control may be measuring the cutoff rather than the dynamics. Inbound,
unverified.** The report states that against our dyadic model with raw `k_n = 2^n` and no dual
cap, `sup_t Ω` reaches 51.7%, 95.0%, 99.6% and 99.90% of the trivial ceiling `k_N² E` at
`T = 2, 8, 32, 64`, with energy drift below `2.7e-13`. If that reproduces, our inviscid control
is saturating an arithmetic bound and is not a control on anything dynamical. **This is the
highest-value item in the entire integration**, because it is a potential defect in an
instrument we have used, reported by someone else, and it costs one run to check. It is not
accepted until we reproduce it — a sibling's measurement is `evidence_kind: numeric` and caps at
X until our own harness fires.

---

## 4. What must not be integrated

The quarantine is not softened by any of this.

1. **`lean_src/` imports Mathlib and nothing else from any other stream's tree** (`SPEC.md`
   §7.2b). Every item adopted below is a *script*, a *schema*, or a *file we write ourselves*.
   No `import` line crosses a repository boundary. Agora-LeanMaster pins Lean `v4.33.1`; we pin
   our own revision; a shared `import` would couple the two and neither of us controls the
   other.
2. **A sibling's theorem enters only as an archived submission** — compiled as received, its
   kernel log saved as the evidentiary record (`SPEC.md` §7.1b, `LL-2`). This applies to
   Agora-LeanMaster's `NSMath/` files if we ever want them, and it applies with extra force
   because that repository's own roadmap flags them as conditional Tier A.
3. **No sibling's claim is cited without its tier and its evidence kind.** A `citation` row caps
   at L; an `llm_output` or `numeric` row caps at X. Agora-LeanMaster's single Tier B ledger row
   cites `tests/exact_arithmetic_ladder.py`, a file that **does not exist in that repository**;
   its three Tier L rows cite sources without theorem numbers, one of them a path not in the
   tree. Those rows are not citable here as they stand.
4. **We do not adopt another repository's headline numbers.** Agora-LeanMaster's `LL.md` says so
   about itself in its first paragraph.

---

## 5. The plan

Five phases. P0 and P1 are cheap, reversible, and close failure modes we have already suffered.
P2 is the notation alignment and needs an owner decision first. P3 and P4 are larger and are
sequenced behind them. Tasks are in `PLAN.md` format: **tier** `[any]`/`[top]`/`[human]`,
Definition of Done, kill criterion.

### Phase P0 — adopt the portable gate, in report-only mode (half a day, no risk)

**Rehearsed 2026-09-18, in the session scratchpad, without touching this repository.** The
numbers below are measured, not estimated, and X1–X3 are therefore already answered; what
remains is the owner's decision to vendor the file and the wiring in X4.

- **X1 (done, in scratchpad).** `mathesis_gate.py`, 21,161 bytes, sha256
  `c5d1fe50af3639ea70aeea25723505becfbe128f01eeca15c1fd4f7e6dffa04a`.
  `--self-test` → `PASS mathesis-gate self-test (1.0.0) — 13 controls`.
- **X2 (done).** `mathesis_gate.py <repo> --lean-src lean_src --skip-footprints --report-only`
  → **13 Lean files scanned, `PASS` axiom hygiene, `PASS` vacuity, ALL CHECKS PASS. Zero
  findings.** We are clean against this gate today, which is precisely the moment to adopt it:
  a gate adopted while green can only ever report a regression, and there is nothing to
  grandfather.
- **X3 (done).** A probe file containing a planted `sorry`, a `def uniformBoundedness (D : Nat)
  : Prop := True`, and `theorem hypothesis_U_bound (D : Nat) : uniformBoundedness D := by
  trivial` was rejected with **exit 1** and three findings, correctly diagnosed:

  ```
  FAIL  axiom hygiene (1 finding(s))
    - lean_src/Probe.lean:6: `sorry` — open proof
  FAIL  vacuity (2 finding(s))
    - lean_src/Probe.lean:1: `uniformBoundedness ... : Prop := True` — a predicate that is
      identically true. Any theorem concluding it is vacuous.
    - lean_src/Probe.lean:4: theorem `hypothesis_U_bound` concludes the vacuous predicate
      `uniformBoundedness` — it establishes nothing.
  ```

  That is the `MX-C-0006` shape — a vacuous claim of *our* hypothesis by name — caught by
  the check we do not currently have.

| ID | Task | Tier | Definition of Done | Kill |
|---|---|---|---|---|
| X4 | Vendor the pinned file into `tools/mathesis-gate/` with its sha256 in `LEDGER.md`, and wire hygiene + vacuity into `scripts/verify.sh` as **Gate 1c** | `[any]` | `verify.sh` runs it and still exits 0; the planted-probe rejection of X3 is reproduced from the vendored copy before the gate is trusted (`LL-3`) | A false positive on the clean tree → fix or drop; a gate with false positives gets disabled and stops protecting anything (`HARDNESS.md` H3) |

Cost: one 21 KB vendored file. No install, no network at run time, no Mathlib needed for these
two checks, no change to the existing gates. Buys the one defect class that survives both of
our gates today.

### Phase P1 — close the gaps we found in ourselves, and the ones a sibling found for us

**X21 is the highest-value task in this memo.** It is one run, it checks an instrument we have
already used, and the defect was reported to us three weeks ago by someone else.

| ID | Task | Tier | Definition of Done | Kill |
|---|---|---|---|---|
| X21 | Reproduce the inbound `ν = 0` saturation report (§3.7c): measure `sup_t Ω / (k_N² E)` on our dyadic model at `T = 2, 8, 32, 64` | `[top]` designs, `[any]` runs | The four ratios, with energy drift, in `data/` with a `.meta` sidecar; and a written answer to "is our inviscid control measuring the cutoff?" | Ratios stay well below the ceiling → the report does not reproduce; say so plainly and tell them |
| X22 | Fix `data/dyadic_omega_sup.csv` (§3.7a): either split `sup_Omega` into two columns or blank it on `INFEASIBLE` rows, and regenerate the sidecar | `[any]` | No column holds two quantities; the generating script is amended so it cannot recur; the old checksum is superseded in the sidecar, not deleted | — |
| X23 | Attribute the `β = −2/3` threshold in `OP2_LITE_CANDIDATES.md` (§3.7b): name whose measurement, which model, which viscosity | `[top]` | One clause; and if the source is an inviscid model, an explicit note that it is being imported into a viscous question | The source cannot be established → the threshold is withdrawn from the protocol, not left ambiguous |
| X5 | Replace Gate 2's hand-maintained twelve-name list with a glob over `lean_src/*.lean`, failing loudly on an empty result | `[any]` | A new Lean file is picked up with no edit to `verify.sh`; a renamed-away file makes the gate fail, demonstrated | The glob changes the set of files checked in any way other than adding ones we forgot → investigate before adopting |
| X6 | Port `tools/statement_lock.py`, generate `docs/statement_lock.json`, wire `--check` into `verify.sh` | `[any]` | A proof repair leaves the lock unchanged (demonstrated); weakening a hypothesis breaks it (demonstrated) | Cannot demonstrate both polarities → not a lock, do not ship it |
| X7 | Port `tools/axiom_audit.py` as a **second, independent** implementation of the footprint check, and compare its verdict with Gate 2's on every file | `[any]` | Both agree on all twelve files; a disagreement is an E-3 escalation and **neither is trusted** until a human adjudicates | They agree trivially because one calls the other → rewrite or drop; a differential gate whose sides share an implementation tests nothing (`HARDNESS.md` H4) |
| X8 | Refresh `LEDGER.md`'s stale header from the gate transcript, and add the counting convention footnote | `[any]` | Header matches the gate's own per-file numbers; `LL-34`'s rule is cited in the file | — |

### Phase P2 — the notation alignment (owner decision first)

**Owner decision D-X: adopt Tier X.** Five tiers were the programme notation as of
`MX-C-0007`; we implemented four. Adopting X means: a new row in `SPEC.md` §0; the banner in 22
`exploration/` files changes from `TIER C` to `TIER X`; float-derived rows in `LEDGER.md`
re-letter C→X; and X acquires the rule *may never support a claim, may steer a search*.

If adopted:

| ID | Task | Tier | Definition of Done | Kill |
|---|---|---|---|---|
| X9 | Add the Tier X row to `SPEC.md` §0 with the evidence-kind cap table | `[top]` | The table matches Mathesis's verbatim; the difference from C is stated in one sentence | — |
| X10 | Re-banner the 22 `exploration/` files; add an AST-walk float check (`tests/tier_b_no_floats.py` pattern) covering `tests/`, `symbolic/`, `scripts/` | `[any]` | Banner uniform; the float check fails on a planted `x = 1.5` and passes on `"version 1.5"` and `# 1.5x faster` | The check produces a false positive → fix before landing (`HARDNESS.md` H3) |
| X11 | Re-letter float-derived `LEDGER.md` rows C→X; leave conjecture rows at C | `[top]` | Every re-lettered row names the file that produced its number | A row cannot be classified without re-reading the artefact → that is the finding, record it |

### Phase P3 — the machine-readable ledger

This is the largest item and the one Mathesis itself expects to break: its `PLAN.md` A3
("Export one stream's ledger") is blocked on an owner conversation, with the expected outcome
stated as *"the schema breaks. That is the deliverable."* We would be the first real adopter,
and our ledger is the hard case — hundreds of rows of prose with an external audit, a pivot, a
retraction table and demoted files.

| ID | Task | Tier | Definition of Done | Kill |
|---|---|---|---|---|
| X12 | Pilot: express **ten** representative `LEDGER.md` rows as `ledger.jsonl` rows under the `MF` prefix — one Tier A, one demoted, one Tier B with its control, one Tier L threshold, one conjecture, one float series, one retracted, one DRAFT-pending-audit, one cross-stream, one with dependencies | `[top]` | `mathesis_gate.py --ledger` exits 0, or the failure is a **finding about the schema**, reported upstream | Fewer than eight of the ten can be expressed without inventing a field → report that; do not extend the schema unilaterally |
| X13 | Decide `audited_by` for our DRAFT files | `[human]` | Each DRAFT file's row carries `audited_by: null` and the fact is visible in the ledger rather than in prose | — |
| X14 | Only if X12 succeeds: migrate the full ledger, keeping `LEDGER.md` as the human mirror with a bidirectional id cross-check | `[top]` | Both directions checked; a planted id in one and not the other fails the gate, demonstrated | X12's findings say the schema does not fit → stop, and the pilot is the deliverable |

### Phase P4 — the declaration graph and the reuse audit

| ID | Task | Tier | Definition of Done | Kill |
|---|---|---|---|---|
| X15 | Port `tools/lean_depgraph.lean` + `tools/theorem_atlas.py`, editing only the roots/libraries lists | `[any]` | Emits a per-constant type-dep/body-dep graph for `lean_src/`; the declaration count reconciles with the gate's, or the discrepancy is explained | Cannot reconcile → the counting convention is ambiguous and `X8` must land first |
| X16 | Run the **unification-candidate** report against `lean_src/` | `[top]` | A ranked list of statements proved more than once; each is triaged as *duplicate to merge*, *deliberate second proof*, or *false positive* | — |
| X17 | Answer the reuse question the graph exists for: does any open `PLAN.md` task restate something already proved? | `[top]` | A written answer with declaration names | — |

`X16`/`X17` have a specific precedent: Task 2.2 stalled for two weeks and turned out to be an
instantiation of a theorem that had been Tier A here since 13 August. That is the failure this
tooling detects mechanically.

### Phase P4b — the two protocols worth adopting from Mensura

| ID | Task | Tier | Definition of Done | Kill |
|---|---|---|---|---|
| X24 | Port the **compensated-flatness gate** into `tests/`: assert no sign flip, every halving at least eightfold, and bounded `\|drift\|/cfl⁴` spread, *instead of* a fitted convergence order | `[any]` | Fires on a scan that fits cleanly while individual halvings flip sign, demonstrated on a constructed case; passes on a genuinely convergent one | Cannot construct the failing case → the gate is not demonstrated and does not ship (`LL-19`) |
| X25 | Adapt the `decisive-experiment` skill into `docs/harness/`, rewriting its examples to the Core–Tail certificate and keeping its four "audit the auditor" lessons intact | `[top]` | A skill file whose phase 6 carries all four lessons, each with the incident that produced it | — |
| X26 | Port the **validation-ladder** pattern for our own instruments, and enforce in code the rule that repository only stated in prose: a new rung never edits an old rung's gate | `[any]` | Rungs: exact triad identity → helical vanishing locus → `M = 2` transient → `M = 64` transient; `climb()` halts on the first failure; editing an old gate fails a test | — |

The four lessons in X25 are the payload, and two of them are ones we have not hit yet: a
reviewer scrutinises its own favourable verdicts less than its critical ones, and a
"I made the comparison fairer" correction applied in only the direction that removes wins is
itself the signal to dig further.

### Phase P5 — reciprocity

Adoption runs both ways, and three corrections are owed outward.

| ID | Task | Tier | Definition of Done |
|---|---|---|---|
| X18 | Tell Stream 0 that surface #2 is closed: our Gate 2 is standalone, Mathlib pinned by revision, lockfile tracked — and that its own Gate 2 now lists our `lean_src` as its first Mathlib provider | `[any]` | A short memo in `docs/proposals/`, transmitted, copy retained |
| X19 | Ask Stream 0 to add Agora-LeanMaster and Mensura to `docs/STREAM_MAP.md`, with their crossing surfaces | `[any]` | Same |
| X20 | Offer Agora-LeanMaster the two things we have that it lacks: a single `verify.sh` that runs every gate and returns an exit code, and demonstrated-failing Tier B negative controls. Note, without editing their tree, that `Tests/Main.lean` contains `native_decide` and is unregistered in the lakefile, so the audit never sees it | `[top]` | Same; framed as an offer, with our own `LL-8` (unwired files rot) as the reason we noticed |
| X27 | Answer Mensura's three defect reports, whatever X21–X23 find. A report that goes unanswered for three weeks teaches the sender not to send the next one | `[top]` | A reply naming, per item: reproduced / did not reproduce / fixed, with the data |
| X28 | Tell Mensura that its CI has not run since 2026-08-15 (the workflow sits in `.github/workflows-disabled/`, which GitHub does not read), and that its `.claude/settings.json` auto-accepts all tools with `rm`, `curl`, `wget` and `docker` allow-listed | `[top]` | Same, framed with our own `LL-23`: we found the identical class of hole in our own allow-list and reported it rather than using it |

---

### Sequencing

`X21` first, alone if necessary: it is one run and it tests an instrument we have used. Then
P0 and the rest of P1, which are cheap and close failure modes already suffered. P2 waits on an
owner decision. P3 is the largest and the upstream expects its own schema to break on us. P4,
P4b and P5 follow. Nothing in P3–P5 is decision-relevant to Hypothesis U.

## 6. Owner decisions this plan needs

1. **D-X — adopt Tier X?** (§3.1, Phase P2.) Five tiers were decided in `MX-C-0007`; we
   implemented four.
2. **The `Reff` migration**, open since 2026-08-25 (action 5): move to Stream 0's
   `Scale/Reff.lean`, keep ours as a second independent proof per `MX-C-0011`, or both.
3. **Does the machine-readable ledger get piloted?** (Phase P3.) Cheap as ten rows, expensive as
   a migration, and the upstream expects its schema to break on us.
4. **Install `docs/harness/`** — still open from the previous release; unchanged by this memo.

## 7. Obstruction compliance note (`SPEC.md` §1.3)

This memo proposes bookkeeping and tooling, not a strategy for Hypothesis U, so O1–O4 do not
apply. O5 applies to one temptation it creates: adopting a sibling's Navier–Stokes Lean would be
adopting material whose own repository flags it as conditional Tier A, and a conditional theorem
whose hypothesis is the hard part is exactly how an Euler-blind argument gets written. The
control is §4.2 — archived submission, compiled as received, kernel log kept — plus the
standing requirement that every strategy file its own compliance note.

**Nothing in this plan licenses a scientific claim.** Stream 0 states the same limit about
itself: "A green Stream 0 gate says a stream's records are internally consistent. It says
nothing whatsoever about Navier–Stokes."
