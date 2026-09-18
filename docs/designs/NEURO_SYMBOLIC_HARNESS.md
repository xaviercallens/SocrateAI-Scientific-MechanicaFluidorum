# NEURO_SYMBOLIC_HARNESS.md — a three-tier neuro-symbolic architecture inside Claude Code, with hooks, a local open-weights tier, Lean tooling, and a gated self-improvement loop

**Tier: C (proposal).** Nothing in this memo is installed, measured or verified. It is a design
memo in the programme's standing practice: derive and hand-check the design first, then hand a
fully specified skeleton to an executing agent — never the reverse. Every component below
carries a first falsifiable milestone and a kill criterion (SPEC §2.3 format), and the whole
memo is subject to the rule that made it necessary: **an agent may not install its own harness
(LL-23).** The owner installs; the agent drafts.

Authored 2026-09-18 by the session that ran the month's work, from `LL.md` (36 lessons),
`SPEC.md`, the two archived papers, the sister project's changelog, and a read of the LeanMaster
repository (`xaviercallens/SocrateAI-Scientific-DualScaleSimulator`, LeanFlow Phase 2).

---

## 0. What problem this solves, in one paragraph

The month showed that every substantive error occurred with both verification gates green, and
that the instruments which caught them — controls, pre-registration, cost models, adversarial
audits, publish checks — were applied **by hand, when someone remembered**. The lessons file
grew to 36 entries because each instrument was invented after the failure it would have
prevented. A harness turns those instruments from habits into hooks: things that run on an
event, cannot be forgotten, and are themselves auditable. The three-tier neuro-symbolic
framing (neural proposes, symbolic certifies, empirical measures and labels) is the right shape
for that harness because it names which tier is allowed to *decide* anything: only the symbolic
tier certifies, and only the human promotes a statement.

## 1. The three tiers, mapped onto what exists

The sister project's manifesto proposed Neural / Symbolic / Empirical pillars and then withdrew
its own "the physics engine discards implausible proofs" phrasing in favour of "label, do not
reject". This memo adopts the corrected form and maps it onto this repository's four epistemic
tiers, which are *not* the same axis: the three architectural tiers are **who acts**; the four
epistemic tiers (A/B/L/C) are **what a claim has earned**. The mapping:

| Architectural tier | What it does | Epistemic tier of its output | Existing components | Proposed additions |
|---|---|---|---|---|
| **Neural** | Proposes: statements, proof skeletons, hypotheses, code, prose | always **C** until certified | Claude Code sessions by model tier (owner → Fable: derivations/audits → Opus: implementation → Sonnet: proposers → Haiku: mechanics); the autoresearch screen | a **local open-weights tier** on a T4 for the cheapest, highest-volume tasks (§3) |
| **Symbolic** | Certifies: kernel proofs, exact identities, ledger consistency | **A** (kernel + footprint), **B** (exact harness + controls), gate 1b | `scripts/verify.sh` (Gates 1, 1b, 2), `tests/controls.py`, `scripts/ledger_check.py`, the `#print axioms` membership test | **LeanGraph**, **LeanRAG**, **leanDataStore** (§4), wired as read-only services to the neural tier and as evidence to the gates |
| **Empirical** | Measures and labels: simulations with controls, physical-validity predicates, cost and telemetry | **C**, with controls demonstrated and model-validity labelled | Rust scouts (`exploration/dual_scale_scout_rs`), calibration against exact steps (2.4e-16), `.meta` sidecars, GCP runner telemetry | LeanFlow's **dual-tier latency pattern** for in-loop guards + asynchronous kernel gate (§4.3); a validity predicate that *labels* which model a result is about |

The rule that ties them: **a neural output becomes load-bearing only by passing through the
symbolic tier**, and **an empirical result is never promoted, only labelled**. That is SPEC §0
restated for agents rather than claims, and it is the whole content of "neuro-symbolic" as used
here. Anything grander is a slogan (the sister project's phrase: a lock without a test).

## 2. Hooks: the instruments as events

Claude Code hooks (`PreToolUse`, `PostToolUse`, `SessionStart`, `Stop`, `PreCompact`) run a
command, a prompt, or an agent when an event fires. Below is the proposed set, each mapped to
the lesson it mechanises. All live in `.claude/settings.json`, which this session cannot and must
not edit; the JSON is given so the owner can install it, after pipe-testing each command with
a synthetic stdin payload (the harness's own documented procedure).

| Event / matcher | Hook | Mechanises | Cost |
|---|---|---|---|
| `SessionStart` | command: print `docs/GOALS.md` + the two `LL.md` syntheses + SPEC §0 tier table into context | context as an artefact; `goal-management` | ms |
| `PostToolUse` on `Edit\|Write` of `lean_src/*.lean` | command: `lake env lean <file>` and a membership test on every `#print axioms` line; inject the footprint as `additionalContext` | LL-2, LL-8, LL-10 (re-elaborate; never trust a cached build) | 5–60 s |
| `PostToolUse` on `Edit\|Write` of `tests/*.py` | command: run that harness; refuse to proceed silently if its controls do not both fire | SPEC §7.3, LL-12, LL-19 | s |
| `PreToolUse` on `Bash` matching `git commit` | command: `scripts/ledger_check.py` (fast Gate 1b) + refuse if a new `LEDGER.md` row cites a path or Lean name that does not exist | LL-1, honesty clause | s |
| `PreToolUse` on `Bash` matching `git add -A\|git add \.\|git stash\|git reset\|git checkout \.` | command: deny with the LL-1/LL-9 text | LL-1, LL-9 | ms |
| `PreToolUse` on `Bash` matching `git tag\|gh release\|zenodo_deposit.sh --publish` | agent: `publish-gate` checklist; `permissionDecision: ask` unless every item is satisfied | LL-33, LL-36 | min |
| `PreToolUse` on `Bash` matching `gcloud\|gsutil\|cargo run.*--release` with a large size flag | prompt: has the `cost-model` skill been applied (counted quantities, `sizeof`, peak vs free)? | LL-21, LL-22, LL-26 | ms |
| `PostToolUse` on `Edit\|Write` of `docs/paper/*.tex` | agent: `manuscript-auditor` (read-only) on the changed file; findings as `additionalContext` | LL-32 | min |
| `Stop` | agent: `claim-auditor` on the `LEDGER.md` diff of the session; report only | three blind spots | min |
| `PreCompact` | command: append the session's open goal changes to `docs/GOALS.md` draft area; write the memory file | LL-25 (never lose state a job is still writing) | ms |

Two design constraints, both from incidents. **Hooks must not widen permissions**: a hook that
runs a general-purpose file rewriter is an allow-list rule that subsumes the denials (LL-23);
each command is a fixed script under `scripts/hooks/`, reviewed like any artefact. **Hooks that
fail must fail loudly**: a hook whose command errors, or whose `grep` silently matches nothing
on a file containing a null byte (LL-29), is a verifier without a control; every hook script
ships a self-test that is run by Gate 1.

Example, the Lean footprint hook (owner installs; paths as in this repository):

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "jq -r '.tool_input.file_path' | { read -r f; case \"$f\" in *lean_src/*.lean) scripts/hooks/lean_footprint.sh \"$f\";; esac; }",
        "timeout": 120,
        "statusMessage": "Re-elaborating and checking the axiom footprint"
      }]
    }]
  }
}
```

`scripts/hooks/lean_footprint.sh` (to be written, `[any]`): `cd lean_src && lake env lean
"$f" 2>&1 | tee` a log; extract every `depends on axioms` line; exit non-zero and print the
offending line if any axiom is outside the permitted set or if `sorryAx` appears; emit
`{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"<footprint>"}}`.
Its self-test injects a `sorry` into a scratch copy and asserts exit 1 (LL-8's table of cases).

## 3. The local open-weights tier (GPU T4)

**Hardware fact first.** The workstation this programme runs on is an 8-core i7 with 31 GB and
**no CUDA** (adjudication 2026-09-13, D-2). A T4 (16 GB VRAM, Turing, no bf16) is therefore a
*separate* host — a second machine, a Colab runtime, or a cloud VM — and everything the
`resilient-job` skill says about unattended remote jobs applies to it (checkpoints, telemetry,
success detection with its own controls, cost measured from the job's own clock).

**Role: the cheapest tier, and nothing above it.** A 7–8B-parameter model at 4-bit fits a T4
with room for a few thousand tokens of context; that is enough for high-volume, low-stakes,
gate-verifiable work, which is exactly the `[any]` tier of `PLAN.md`:

- **premise retrieval** over Mathlib and `lean_src/` (LeanRAG, §4.2) — an embedding model
  plus a reranker; output is a candidate list, verified by whether the proof closes;
- **tactic suggestion** and **proof repair** on a fully specified skeleton — candidates from
  an open Lean prover (families to evaluate, not endorsements: DeepSeek-Prover-V2-7B,
  Goedel-Prover, Kimina-Prover; each must be verified against the T4's memory at 4-bit and
  against the pinned Mathlib revision before it is trusted with anything); output is a proof
  term, and the kernel decides;
- **autoformalisation drafts** of a *statement already written by the top tier* — never of a
  statement the model chooses (E-1, LL-5); output is a `DRAFT` file pending human adequacy
  audit;
- **embedding** of ledger rows, lessons and memos for LeanRAG and for the goal register's
  "does this proposal serve a goal row" check.

**Gating.** Every output of this tier is Tier C at birth and is promoted by nothing but the
kernel or a Tier B harness. The model never sees the permission file, never runs `git`, and
never writes into `lean_src/` directly: it writes into a scratch directory that the footprint
hook (§2) elaborates, and only a footprint-clean file is offered to the session for the single
active file. This is the LeanFlow pattern (§4.3) applied to a language model: cheap, fast,
uncertified proposals in the inner loop; the kernel in the outer loop.

**Serving.** vLLM or llama.cpp behind an OpenAI-compatible endpoint on the T4 host; Claude Code
reaches it through a tool the owner installs (an MCP server or a `scripts/t4/` client), never
through a hook that could be repurposed as a general command runner. Throughput is *measured*
before it is planned around (LL-22, LL-27): tokens/s at 4-bit on a T4 for a 7B model is a
number to obtain from the machine, not from a blog.

**First milestone.** One `[any]` task from `PLAN.md` — a proof against a fully specified
skeleton with confirmed-available lemmas — closed by a T4-served prover, its footprint verified
by Gate 2, at a measured cost in seconds and watts. **Kill:** if over ten such tasks the tier's
proposals close fewer than the same session closes unaided in the same wall-clock, the tier is
retired to retrieval-only.

## 4. Lean tooling: what LeanMaster has, and what LeanGraph, LeanRAG and leanDataStore would add

### 4.1 What the LeanMaster repository actually contains (read 2026-09-18)

`SocrateAI-Scientific-DualScaleSimulator` hosts **LeanFlow Phase 2** (PyPI `leanflow` 2.0.0, MIT):
a Python/PyTorch stiff integrator with a *dual-tier latency decoupling* design — microsecond
ahead-of-time invariant guards in the numerical inner loop, and an asynchronous outer-loop
Lean 4 verification gate over Unix-socket JSON-RPC (`leanflow/bridge/lean_ipc.py`,
`LeanVerificationClient`). It also holds `proofs/LeanscratchDB/*.lean` (scratch Lean files:
`DoubleScaleT2`, `EmergentCosmology`, `HoloAlg`, `QuantumEntanglement`, `TopologicalTDuality`)
and a 12-page engine preprint. The names **LeanGraph, LeanRAG and leanDataStore do not appear in
that repository**; they are specified below as the components this programme would build on
top of what is there.

Three cautions before any integration, each already a rule here:

- **Axiomatic quarantine (SPEC §7.2b).** `lean_src/` imports Mathlib and nothing from any other
  stream's tree. Stream 0's survey recorded 34 axioms and 2 `sorry` in the sister `DualScale/`
  Lean tree. Integration is by *kernel log*, never by `import`: a LeanMaster theorem enters this
  repository only as an archived submission compiled as received, with its footprint saved
  (SPEC §7.1b, LL-2).
- **Model mismatch.** LeanFlow's fluid regularisation is a smooth bi-Helmholtz filter with
  hyperviscosity, not the sharp Galerkin projection this programme adopted (Q1, 2026-09-10).
  Only its *engineering* — the latency decoupling, the IPC bridge — is leverageable; none of its
  physics is.
- **Where the check actually runs.** The head of `lean_ipc.py`'s tadpole check computes the
  neutrality predicate in Python (`is_neutral = (net_charge == 0)`) before dispatch. Any bridge
  adopted here must be audited for checks computed client-side and labelled as Lean-certified —
  the LL-2 pattern (a name in the environment is not a proof) in a new place. The audit is a
  `[top]` task before the bridge touches a claim.

### 4.2 The three proposed components

**LeanGraph — the declaration graph.** A directed graph over every declaration in `lean_src/`
and the pinned Mathlib: nodes are constants with their footprint, tier (from `LEDGER.md`), file,
and `DRAFT` status; edges are "uses". Built from `lake env lean --deps` / `#print axioms` output
and Mathlib's import graph, refreshed by the footprint hook on every edit. What it buys: the
reuse audit that took two weeks to do by hand (Task 2.2 was an instantiation of a theorem
already proved; `FORMALIZATION_WORKFLOW.md`) becomes a query — "which existing theorem has this
statement's shape?" — and a duplicated definition (LL-10) becomes a visible pair of nodes. It is
also the place the "gates don't compare tiers to each other" rule gets a tool: a Tier B harness
row and a Tier A theorem row that cite the same identity are linked, and their quantifiers can
be diffed. *Milestone:* the graph reproduces the report's per-file counts (14, 3, 16, 11, 15, 7,
11, 7, 13, 10, 33, 53) from the artefacts alone. *Kill:* if it cannot, the count convention is
ambiguous and must be fixed first (LL-34).

**LeanRAG — retrieval over formal and normative text.** Embeddings (served by the T4 tier) of
Mathlib docstrings and statements, `lean_src/` docstrings, `LEDGER.md` rows, `LL.md` entries and
design memos; a retriever that answers "what already exists that bears on this statement?"
before a skeleton is dispatched (LL-5 step (c): confirm the named lemmas exist and are built).
Strictly read-only, strictly advisory, and *never* a source of a definition (E-1). What it must
not do is what a registry's language-model check must not do either: certify adequacy. It
retrieves; the human and the kernel decide. *Milestone:* for the 20 most recent Tier A rows, the
retriever's top-5 contains the Mathlib lemma the proof actually used, measured against the
proof terms. *Kill:* below 50 % at top-5 it is noise and is retired.

**leanDataStore — the content-addressed evidence store.** Every compiled artefact keyed by the
hash of its source: kernel log, footprint, Mathlib revision, toolchain, date, tier, and the
`.meta` sidecar pattern already used for `data/`. This is `docs/proposals/` and the GCP
checkpoint discipline made systematic: LL-2's "archive verbatim, compile as received, keep the
log", LL-29's self-verifying checkpoints, and the publish gate's "artefact matches the tag by
checksum" all become lookups. The sister project's release check (every file's checksum against
the tagged commit, 66/66) is the same store by hand. *Milestone:* Gate 2 reads footprints from
the store when the source hash is unchanged and re-elaborates otherwise — with LL-10's trap
avoided by design: a cache hit is only accepted for an identical source hash *and* identical
Mathlib revision, and the store refuses to serve a footprint for anything else. *Kill:* one
false cache hit on the LL-8 six-case table.

### 4.3 The LeanFlow pattern, adopted for the empirical tier

LeanFlow's contribution that survives every caution above is architectural: **cheap guards in
the loop, the kernel out of the loop, asynchronously.** For this programme's scouts that means:
in-loop invariants that cost nothing (energy non-increasing at $\nu \ge 0$ — a Tier A theorem
here, `energyRateZ3_nonpos`; divergence-free to machine precision; the calibration residual
against the exact steps), and at milestones an asynchronous dispatch of a *discrete* claim to
the kernel — an exact rational identity at a checkpoint, a class-set saturation count, the
integer objective $S(\sigma)$ — whose footprint lands in leanDataStore. The physical-validity
predicate rides the same channel and **labels** the run ("this trajectory left the model's
validity range at $t = \dots$") rather than stopping it. A scout that reports its own departure
from the modelled regime is more useful than one that regularises it away; that sentence is the
sister project's and it is right.

## 5. Self-improvement as an energy-based model, and why it is gated

### 5.1 The framing

LeCun's energy-based view: a system holds an energy function $E(x, y)$ over (context, candidate),
low where the candidate is compatible with the context, and *inference* is finding low-energy
candidates while *learning* is shaping $E$ so that observed good pairs are low and bad ones are
high. The joint-embedding variant predicts in a representation space rather than in pixels, and
scores a prediction by how far the world turned out from it.

The laboratory already has an energy function; it has been calling it the tier system.
Define, for a claim $c$ with evidence $e$:

$$E(c, e) = \tau(c) + \sum_{\text{audit findings}} w_{\text{severity}} + \lambda_{\text{cost}} \cdot \frac{\text{measured}}{\text{modelled}} + \lambda_{\text{pred}} \cdot |\text{outcome} - \text{registered prediction}|$$

with $\tau = 0$ for Tier A with a clean footprint, $1$ for Tier B with both controls
demonstrated, $2$ for Tier L cited to a theorem statement, $3$ for Tier C, and $\infty$ for
anything not in the ledger. The audit terms are the claim-auditor's and manuscript-auditor's
findings (blocking $\gg$ substantive $\gg$ note); the cost term is LL-22's ratio; the prediction
term is pre-registration's surprise. *Inference* — a session's ordinary work — is lowering $E$
for the claims it makes: certify, control, register, count. That much is a restatement, and
useful only because it makes the next step precise.

### 5.2 Learning: the harness improves the harness — under a boundary that is not the agent's

*Learning* is changing the **harness** (hooks, skills, agent definitions, gate scripts) so that
future claims land at lower energy sooner. The month supplies the training signal: every LL
entry is a (context, bad candidate, what caught it) triple, and the gates plus the audit
procedures are an immutable evaluator — exactly the shape the autoresearch screen needs. The
proposed loop, run as a scheduled background session:

1. **Mine.** Read the new `LL.md` entries, audit records and escalations since the last run.
   Each is a labelled failure with its catching mechanism.
2. **Propose one change.** A single-hypothesis harness edit — a new hook, a stricter matcher, a
   new self-test, a changed skill step — with a falsifiable prediction: "this hook would have
   fired on LL-$n$ and on no clean commit". Proposers of a cheaper tier, without access to the
   live `.claude/`; a judge fixes the list (the `autoresearch-screen` skill, applied to the
   harness itself).
3. **Replay-test against the corpus.** A replay corpus of the 36 incidents as reproducible
   states (a commit with `sorryAx` swept in; a log with a null byte; a checkpoint in phase
   `done`; a three-point series with growing differences; a paper with a placeholder author) and
   of the clean history (every tagged release). The candidate hook must fire on its target
   incidents and on **none** of the clean states. False positives are measured, not argued
   (LL-8: a gate that rejects better proofs trains proofs to get worse).
4. **Emit a proposal, not an installation.** The change lands as a pull request into
   `docs/harness/` and `scripts/hooks/`, with the replay results as its evidence, and the owner
   installs it. **The agent never writes to `.claude/`, never widens an allow-list, never edits
   a gate predicate without the six-case table (LL-8), and never runs the loop on the machine
   whose permissions it proposes to change.** This is the whole of LL-23 and it is not
   negotiable; a self-improving harness whose boundary is the improver's restraint has no
   boundary.
5. **Record.** The proposal's energy delta — which incidents it would have caught, at what
   false-positive cost — goes into the goal register row G-M, and the loop's own misfires go
   into `LL.md` like anyone else's.

What this is *not*: it is not a model fine-tuning itself, not an agent rewriting its own
prompt at runtime, and not a claim that the loop converges. The JEPA analogy is kept to its
useful half — **predict the verification outcome before running it, and treat the surprise as
the signal** — which is pre-registration, already the programme's most productive rule (two of
three registered brackets falsified; every falsification localised to a named factor).

### 5.3 Goodhart, named

An energy the harness optimises is an energy the harness will game. Known failure modes and the
control for each: optimising the gate rather than the science (the gate is a membership test,
not an equality — LL-8 — and the audit terms are adversarial by construction); hooks that
suppress work rather than catch errors (the false-positive rate on clean history is the kill
criterion); model outputs laundered through Lean names (LL-2: footprints on compiled artefacts
only); the loop editing its own evaluator (the evaluator is the gates and the replay corpus,
both under the owner's review, both with self-tests in Gate 1). And the one control that cannot
be automated: statement adequacy stays human (SPEC §0; verdict D1). A harness that learned to
make every statement pass would be the D1 failure at machine speed.

## 6. What the month already validated of this design, and what it did not

Validated by incident: that hooks would have caught real failures (the footprint hook against
LL-1's swept `sorryAx`; the git-add guard against LL-1/LL-9; the publish gate against LL-33; the
manuscript audit against LL-32 — twice). Validated by practice: model tiers by cost of a wrong
statement (the screen's Sonnet proposers, Opus judge, Fable check against code; the Opus report
review and manuscript audit both found what the drafting session did not). Validated by the
sister project independently: the kernel gate and the append-only changelog, and the "label, do
not reject" correction.

Not validated, and stated as such: any T4 throughput number; any open prover's close rate on
this repository's skeletons; LeanGraph/LeanRAG/leanDataStore as running software; the
self-improvement loop's false-positive rate; that the energy function above is the right one.
Every one of these is a milestone with a kill criterion in the plan below, and none may be cited
before its row in `LEDGER.md` exists.

## 7. Plan — tasks in `PLAN.md` format (proposed; the owner adopts)

| ID | Task | Tier | Definition of done | Kill |
|---|---|---|---|---|
| H1 | `scripts/hooks/lean_footprint.sh` + self-test wired into Gate 1 | `[any]` | Injected `sorry` → exit 1; clean file → footprint in `additionalContext`; six-case table passes | — |
| H2 | git blast-radius guard hook + self-test | `[any]` | Denies `add -A`, `stash`, `reset`, `checkout .`; allows explicit-path add | — |
| H3 | Ledger pre-commit hook (Gate 1b) | `[any]` | Refuses a commit whose new ledger row cites a missing path or name | — |
| H4 | Publish-gate agent hook on `gh release\|--publish` | `[top]` prompt, `[any]` wiring | Asks unless all nine checklist items satisfied; pipe-tested | — |
| H5 | Replay corpus: 36 incidents as reproducible states + clean tagged history | `[top]` design, `[any]` build | Each incident reproduces its catching signal; each clean state is silent | An incident that cannot be reproduced is dropped from the corpus with a note, not faked |
| H6 | Manuscript-audit hook on `docs/paper/*.tex` | `[any]` | Runs the read-only auditor; findings surfaced, nothing edited | — |
| L1 | LeanGraph v0: declaration graph + per-file footprint counts | `[any]` | Reproduces `14,3,16,11,15,7,11,7,13,10,33,53` | Cannot → fix the convention first (LL-34) |
| L2 | leanDataStore v0: source-hash → kernel log/footprint, cache hit only on identical hash + Mathlib rev | `[any]` | LL-8 six-case table; LL-10 cached-target trap test | One false hit |
| L3 | LeanRAG v0 over Mathlib + `lean_src/` docstrings, T4-served embeddings | `[any]` after T1 | Top-5 recall ≥ 50 % on the 20 latest Tier A rows | Below 50 % → retrieval retired |
| L4 | Audit of `lean_ipc.py`-style bridges for client-side checks labelled as Lean-certified | `[top]` | Written finding per predicate; none adopted before audit | — |
| T1 | T4 host: serve one 7B prover + one embedding model at 4-bit; measure tokens/s and watts | `[any]` | Numbers from the machine, `.meta` sidecar | — |
| T2 | Ten `[any]` skeleton proofs attempted by the T4 tier, footprints gated | `[any]` | Close rate and wall-clock vs an unaided session, both measured | Fewer closes than unaided → retrieval-only |
| E1 | Energy function $E$ computed for every current ledger row; distribution reported | `[top]` | A table, no interpretation | — |
| E2 | One self-improvement iteration end to end: mine → propose → replay → PR | `[top]` judge, `[any]` proposers | PR in `docs/harness/` with replay evidence; **nothing installed by the agent** | False-positive rate on clean history > 0 for a blocking hook → rejected |
| O1 | Owner installs H1–H4 into `.claude/`; opens `/hooks` once | `[human]` | Hooks fire on a harmless test edit | — |

Order: H1–H3 first (cheap, mechanise the three oldest lessons), then H5 (the corpus is the
evaluator everything else needs), then L1/L2, then T1/T2, then E1/E2. Nothing in the L/T/E rows
is decision-relevant to Hypothesis U; they serve goal row G-M, and G-CT still waits on an owner
decision that no harness can make.

## 8. Obstruction compliance note (SPEC §1.3, as required of every strategy)

This memo proposes infrastructure, not a strategy for Hypothesis U, so O1–O4 do not apply. O5
applies to one thing it could tempt: a harness that made statements easier to pass could make an
Euler-blind argument easier to write. The controls are the human adequacy audit (SPEC §0) and
the requirement that every strategy still files its own compliance note; the harness checks
that the note exists, never that it is right.
