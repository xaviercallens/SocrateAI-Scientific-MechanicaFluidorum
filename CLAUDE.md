# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A staged, verifier-in-the-loop scientific program on 3D Navier–Stokes global regularity
("Hypothesis U" — uniform enstrophy control of the frequency-truncated system), conducted
with formal verification (Lean 4 / Mathlib), exact rational arithmetic, and a strict
three-tier epistemic gating system. Read `SPEC.md` before doing anything substantive here —
it is the normative rulebook, not background reading. `PLAN.md` is the agent-executable task
list with Definition-of-Done criteria and an escalation protocol. `LEDGER.md` is the
claim inventory: **a claim not listed there has no tier and may not be cited.**

## The tier system (governs everything)

- **Tier C** — conjecture/analogy/unverified. Anything here, including all floating-point
  code, lives in `exploration/` or is explicitly labeled and never gates a claim.
- **Tier B** — checkable: validated by **exact rational arithmetic** (`fractions.Fraction`
  or `int` only — floats are banned from `tests/`). Every Tier B checker ships a **negative
  control** that is demonstrated to actually fail; a checker that cannot fail is not a checker.
- **Tier A** — established: Lean 4 kernel-compiled, zero `sorry`, zero custom axioms. The
  gate is not "no sorry in the source" — a failed proof still defines the theorem name in
  the environment, and only `#print axioms` reveals a stray `sorryAx`. The required footprint
  for every theorem is exactly `[propext, Classical.choice, Quot.sound]`.

## Commands

Run the full two-gate verification (the only thing that counts as "it works"):
```bash
./scripts/verify.sh
```
This runs every harness under `tests/` (Gate 1) and kernel-compiles every file listed in the
`for f in ...` loop near the bottom of `scripts/verify.sh` (Gate 2) against a pre-built
Mathlib. **When you add a new Tier B harness or a new Lean file, wire it into
`scripts/verify.sh`'s file lists** — an unwired file can silently rot (this has happened;
see `LL.md`).

Run a single Tier B harness:
```bash
python3 tests/tier_b_exact_checks.py        # or any other tests/tier_b_*.py / test_*.py
```

Compile a single Lean file directly (bypasses Gate 1, useful while iterating):
```bash
cd ~/xdev/SocrateAI-Scientific-RajMathRecovery/dualscale/lean && \
  lake env lean /home/xavkal/xdev/SocrateAI-Scientific-MechanicaFluidorum/lean_src/<File>.lean
```
`lean_src/` **is** a standalone Lake project as of 2026-08-13 (see the cold-build note below).
Gate 2 prefers its local build; when `lean_src/.lake` is absent it falls back to the
already-built Mathlib checkout at `~/xdev/SocrateAI-Scientific-RajMathRecovery/dualscale/lean`
(override either with `LEAN_ENV_DIR`). Note that only a **subset** of Mathlib is built in that
*fallback* checkout — if you are relying on the fallback, check before importing a new module:
```bash
ls ~/xdev/SocrateAI-Scientific-RajMathRecovery/dualscale/lean/.lake/packages/mathlib/.lake/build/lib/lean/Mathlib/<Path>.olean
```
The umbrella `import Mathlib.Tactic` is **not** built; import narrow modules
(`Mathlib.Tactic.Ring`, `Mathlib.Tactic.Linarith`, etc.).

**The standalone cold build is DONE (2026-08-13)** — `lean_src/` is now a real Lake project
with Mathlib pinned (`lean_src/lakefile.lean` + the tracked `lean_src/lake-manifest.json`) to
the same revision the external checkout uses. `scripts/verify.sh` Gate 2 now **prefers**
`lean_src/.lake` when present and falls back to `LEAN_ENV_DIR` otherwise, so a fresh clone
still verifies without first paying for the ~8 GB build. Rebuild it with:
```bash
cd lean_src && lake exe cache get && lake build
```
Why this matters and is not just tidiness: Gate 2 previously always used the external
checkout, which this repo does not control — an unrelated `lake build` there rebuilt its
`.olean` files mid-run and Gate 2 failed on a file this repo had not touched. The local build
removes that coupling. `lean_src/.lake/` is gitignored (7.9 GB); the **manifest is not**, and
must stay tracked — it is what pins the toolchain every `LEDGER.md` claim was verified
against.

Print a theorem's axiom footprint (the actual Tier A gate, more reliable than reading source):
```lean
#print axioms Namespace.theorem_name
```

## Architecture

**`lean_src/`** — one active Lean file per mathematical object, imports chained, never
versioned copies (`_v2`, `_final` are banned — git history is the archive):
- `LocalDualScale.lean` — the T-dual effective-radius laws (`Reff`) and the Symmetric-Square
  recurrence lock (`sym2_recurrence`), the program's oldest, most-reviewed core.
- `DyadicShells.lean` — energy-flux telescoping identity for the truncated Katz–Pavlović
  dyadic shell model (the Stage-1 "laboratory" before any continuum PDE work).
- `EnstrophyProduction.lean` — imports `DyadicShells.lean`'s `prodOut`; proves the exact
  (non-telescoping) enstrophy-production identity, the dyadic vortex-stretching analogue.
- `HypothesisU_Statements.lean` — the non-vacuous, statement-level formalization of
  Hypothesis U itself (Galerkin-truncation shape). Marked **DRAFT** in its own header until a
  human statement-adequacy audit passes — machine verification checks proofs, but only a
  human audit can certify that a *statement* means what the physics is claiming.

**`tests/tier_b_*.py`, `test_*.py`** — exact-arithmetic mirrors of the Lean results, plus
independent computations (lattice counts, triad enumerations, percolation instruments) that
feed the still-blocked analytical tracks. Every file's negative control is not decorative —
`scripts/verify.sh` Gate 1 fails loudly if a harness's own sanity check doesn't hold.

**`symbolic/`** — exact-`Fraction` numerical/algebraic tooling (guess-and-prove recurrence
solvers, exact ODE integrators). **`exploration/`** — the *only* place floating point is
allowed; every file must open with a `# TIER C — EXPLORATORY, NO CLAIMS` banner.

**`docs/designs/`** — top-tier-authored derivation/design memos written *before* dispatching
implementation work (the project's standing practice: derive and hand-verify the mathematics
first, then hand a fully-specified proof/computation skeleton to an executing agent — never
the reverse). **`docs/escalations/`** — filed when a task hits a genuine blocker (missing
definition, methodology decision, computational anomaly) rather than being worked around
unilaterally; see `PLAN.md` §3 for the E-1…E-5 taxonomy. **`docs/proposals/`** — externally
submitted artifacts, archived verbatim with their compiled kernel output before any review or
merge — self-reported "no sorry" is never trusted without the compiler transcript.

**`data/`** — every CSV ships a `.meta` sidecar (exact generating command, tool version,
`sha256sum`) so a result can be reproduced or audited later, not just re-read.

## Working conventions specific to this repo

- **Never invent a mathematical definition or theorem statement.** If a task needs an object
  not already defined in `SPEC.md` / `docs/HYPOTHESIS_U_SPECIFICATION.md` / the relevant
  design memo, that is a blocker to escalate (`PLAN.md` §3, rule E-1), not a gap to fill in.
- **Agent/tool self-reports are not evidence.** Independently re-run the compiler or harness
  on the exact artifact before trusting or committing it — this project has caught two broken
  Lean proofs that a concurrent process's own report had described as passing.
- **`git add` by explicit path only, never `-A`/`.`, whenever a background agent or workflow
  might still be writing to this repo.** A broad `add` has twice swept an in-progress,
  non-compiling file into a commit; see `PLAN.md` §9.4 and `LL.md`.
- **Physical/cosmological narrative is quarantined in `docs/narrative/`** and must never be
  imported by `lean_src/` or cited as justification for a tier promotion.
