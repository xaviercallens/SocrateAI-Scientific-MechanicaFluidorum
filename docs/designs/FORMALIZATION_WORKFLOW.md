# The formalization workflow — how a claim gets from an idea to a kernel certificate

**Status:** `[top]`-authored process spec, 2026-09-10, at the owner's request
(*"crée un workflow pour atteindre ce goal de formalisation"*).
**Scope:** this is the *operating procedure* for the Lean track. It does not add mathematics; it
fixes the order of operations that the last three cycles show is the one that works, and names the
two orders that demonstrably do not.

---

## 0. The one-sentence version

**Derive on paper → check the abstract theorem is not already proved here → identify the single
riskiest step and implement THAT first → negative-control it → assemble → gate → commit by
explicit path.**

## 1. The five stages, and what each must produce

| # | Stage | Output | Done when |
|---|---|---|---|
| **S1** | **Hand derivation** | a memo in `docs/designs/` containing the proof in prose, the failure modes considered, and an explicit *implementation order* | a reader can reconstruct the proof without Lean |
| **S2** | **Reuse audit** | a paragraph in that memo naming what already exists in `lean_src/` and what is genuinely new | every abstract lemma the proof needs is either cited or declared missing |
| **S3** | **Riskiest-step-first** | the one lemma whose failure would invalidate the design, compiled alone | it compiles, and its negative control fails |
| **S4** | **Assembly** | the remaining lemmas, then the theorem | `#print axioms` shows exactly `[propext, Classical.choice, Quot.sound]` |
| **S5** | **Gate and record** | `./scripts/verify.sh` exit 0, a `LEDGER.md` row, a commit per task by explicit path | the row cites a name that `scripts/ledger_check.py` resolves |

### Why S2 is a separate stage and not a habit

Task 2.2 was scoped as "prove the energy identity", believed hard, and left as a `Prop` for two
weeks. **The abstract theorem had been Tier A in this repository since 2026-08-13**
(`AbstractAlgebraicConservation.triad_sum_zero`). The remaining work is a bridge, and the memo that
found this (`TASK22_ENERGY_IDENTITY.md`) took one reading pass. A reuse audit is cheap and its
absence is expensive.

### Why S3 exists, with its own evidence

In the same memo the design's single trap is the index set: the natural one is **not**
`swap3`-closed, and an implementation that discovered this at assembly time would have rewritten
everything upstream. Implementing the closure lemma first cost one compile and removed the risk
before any dependent code existed.

## 2. Two orders that do not work, recorded so they are not retried

- **Proof-first without a reuse audit** — see above.
- **A "sorry-first skeleton", iterated later.** The instruction to *"isole-la dans un lemme avec
  `sorry`, vérifie que le reste compile"* is a reasonable habit in most Lean projects and is
  **wrong here**: Gate 2 fails on any `sorry`, and worse, a `sorry`'d theorem still *defines its
  name*, so every downstream `#print axioms` silently carries `sorryAx`. The repository has caught
  this exact pattern twice. The supported substitute is what `EnergyConservationStatement` does:
  state the claim as a `Prop`, exhibit its quantifier domain as inhabited, and prove it later. A
  `Prop` cannot be mistaken for a theorem; a `sorry`'d theorem can.

## 3. The gate discipline that is not negotiable

1. **A self-report is not evidence.** Compile the artifact yourself. Four submissions have now
   claimed a clean gate; three did not compile. The kernel log goes in `docs/proposals/`.
2. **Both directions, always.** A theorem gets a negative control too: perturb the statement (a
   computed value, a hypothesis, a sign) and confirm the proof *breaks*. A proof that survives the
   removal of its hypothesis was proving something else.
3. **Non-vacuity is part of the theorem.** A conditional theorem whose hypothesis the zero object
   satisfies needs a witness that something non-zero satisfies it too. This closed flag F1.
4. **Stage by explicit path, re-verified immediately before staging.** A concurrent agent writes to
   this repository; `git add -A` has swept unverified files into commits three times.

## 4. The current queue

*Revised 2026-09-10.*

| item | state | next action |
|---|---|---|
| **Task 2.2** energy identity | **CLOSED** — `energy_conservation`, all five steps, three negative controls fail as required | — |
| **F4** `ball` vs `GalerkinState.cutoff` | **CLOSED** — `mem_ball_iff` | — |
| **weighted triad identity** (`WEIGHTED_TRIAD_IDENTITY.md`) | Lean + Tier B done; **memo is SELF-AUTHORED and awaits the owner's statement-adequacy audit** | owner to accept, amend or reject the statement. The proofs are machine-checked; whether the statement is the one the programme wants is not |
| **Task 2.3** sweeping cancellation | **blocked, E-1** | the memorandum states a bound "∝ \|p\|" with no definition of the object bounded. A definition must be authored and audited before any Lean |
| **Task 3.1/3.2** confinement ⇒ Hypothesis U | **blocked, E-1 and O5** | "invariant region" and "confinement guarantees U" are Tier C conjectures. Also: at fixed `α′` the truncated system is regular by an elementary argument, so a proof that does not use `α′ → 0` uniformly proves nothing (SPEC obstruction O5) |

**On the two blocked rows.** They are blocked on *definitions*, not on effort, and PLAN §3 rule E-1
forbids inventing them. That is the correct state for them to be in, and it is where the
programme's honesty lives: the queue above is short because most of the roadmap's later items are
not yet mathematics.

**On what closing Task 2.2 did and did not buy.** It proved the truncated system conserves energy —
a prerequisite for global existence *of that system*, which obstruction O5 says was never in doubt.
The follow-on work reached the object Hypothesis U is actually about, the enstrophy production, and
put it in exact closed form. That localises the three-dimensional difficulty to a single factor and
**is not a bound**. No row above moved from blocked to open as a result.
