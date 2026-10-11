# [ARCHIVED SUBMISSION — VERBATIM] Planar universal optimality, tiered: Lean 4 corollaries, a non-uniqueness theorem, and a CVODE N-body consistency check

> Archival note (2026-10-11): submitted at the owner's request ("commit, push the result into
> SocrateAI-Scientific-MechanicaFluidorum when the paper and Lean 4 is completed") by a Claude Code session working in
> AutoevolveAI. It is archived under the `docs/proposals/` convention **before** any review here. Nothing below has
> been verified by this repository. The review, if any, goes in a separate `-review.md`. **No file of this
> submission is wired into `scripts/verify.sh` or listed in `LEDGER.md`, so it has no tier here.**

## What this is, and what it is not

- **Not Navier–Stokes.** The subject is the planar Cohn–Kumar universal-optimality question for the triangular
  lattice. Its crossing surface with this repository is the openai/math Lean corpus, already audited here
  (`openai-audit-*`, `2026-09-10-dual-scale-openai-leverage-*`), and the method: tiers, controls,
  statement adequacy.
- **Different toolchain.** The Lean sources use Lean 4.34.1 + Mathlib `d13f23b7` + openai/math `adc7f124`, not this
  repository's `v4.33.1` pin. They are stored as `.lean.txt`, so no import crosses a repository boundary
  (CROSS_STREAM_INTEGRATION.md).

## Files

| File | Content |
|---|---|
| `2026-10-11-planar-universal-optimality-proposed.lean.txt` | the six Lean files verbatim, each with its sha256 |
| `2026-10-11-planar-universal-optimality-kernel-log.txt` | the producer's `#print axioms` output: 22 declarations within {propext, Classical.choice, Quot.sound} and 2 planted controls flagged (`sorryAx`, a custom axiom). Self-reported; re-run before trusting |
| `2026-10-11-planar-universal-optimality-ledger.json` | the claim ledger in SocrateAI-Scientific-Elenchus format (18 claims, tiers A/L/C/X). Its gate gives 0 blocks and 6 `LEDGER_UNAUDITED_TIER_A` flags (exit 1) |
| `2026-10-11-planar-universal-optimality-paper.pdf` | the preprint draft (v1, not yet on Zenodo) |
| `2026-10-11-planar-universal-optimality-numerics-summary.json` | the CVODE study summary. Floating point, so Tier C in this repository's scheme |

## Claims, with tiers as filed (Elenchus scale X < C < L < B < A)

- **A**, conditional on the fidelity of upstream's definitions; no human statement audit yet:
  - upstream `universal_energy_minimum` (our compile and footprint);
  - Riesz admissibility and optimality, finite lattice Riesz energy for s > 2, and optimality at every density with
    attainment (earlier paper doi:10.5281/zenodo.23285631);
  - `triangular_universally_optimal`: ρ^{-1/2}A satisfies CKMRV Def 1.3 at every ρ > 0, stated with upstream's lower
    energy. This is weaker than CKMRV's notion, which also requires the energy limit to exist;
  - `universal_optimum_not_unique`: A \ {0} is also universally optimal and is not an isometric image of A. This
    formalises CKMRV's remark after their Thm 1.4, also noted by upstream.
- **L:** CKMRV Def 1.3, the uniqueness remark, and the history. Dimension 1 was solved before 8 and 24
  (Ventevogel–Nijboer), and no d > 1 case was known before CKMRV.
- **C:**
  - Yukawa `exp(-κr)/r` is completely monotone in r² (via CKMRV footnote 2 and Leibniz);
  - the interpretation that "particles always arrange into a triangular lattice" is false among all
    configurations in this formulation.
- **X** (floating point; supports no claim): rusty-SUNDIALS CVODE study (PR #72), preregistered before code and
  results.
  - P1, no relaxed configuration below the lattice energy: pass at κ = 2 and 1.
  - P2, annealing reaches the lattice: pass at κ = 2, **fails** at κ = 1.
  - Controls behave as required, including the square-lattice saddle and the incommensurate box.

## Why it may interest this repository

1. **The statement-adequacy lesson in a second setting.** The kernel-checked non-uniqueness theorem shows how a
   correct theorem can still refute the *gloss* attached to it. This is the B1/D1 lesson of the 2026-08-13 external
   audit, met independently.
2. **A worked Elenchus ledger** with content-addressed evidence, the transitive tier check and Tier X numerics kept
   out of claims. It may be compared with this repository's `LEDGER.md` conventions.
3. **The openai/math crossing surface.** One more upstream theorem has a clean footprint under its pinned
   toolchain, and its Comparator acceptance is recorded in AutoevolveAI. The same audit, by the same method, as this
   repository's `openai-audit-*` files.

## What is asked of a reviewer here

1. Re-run the kernel log yourself before trusting it, per this repository's CLAUDE.md. Self-reports are not evidence.
2. A **human statement-adequacy audit** of `UniversallyOptimal` and of upstream's `energy` / `DensityOne` against
   CKMRV Defs 1.1–1.3. That is the one thing no gate in any of the three repositories can supply.
3. Decide whether anything here should enter `LEDGER.md`. The default is no: it is outside this repository's
   object of study and toolchain.

## Provenance

| Item | Location |
|---|---|
| Lean | AutoevolveAI `formal_cert/Triangular/` (sources at d50dfc43; paper 63453abd0c2d9bd4e127458014804d820b9f380d); LeanMaster release v3.48.1 (`contrib/openai_math_corollaries/`) |
| Numerics | rusty-SUNDIALS PR #72 (`crates/qf-yukawa-crystal`; prereg 636c514, code 968b0f2, results 1f46e70) |
| Initial conditions | Hugging Face `colabfit/OC20_IS2RES_val_id` (CC-BY-4.0, doi:10.60732/b4005525) |

All of the work (proofs, numerics, ledger, text) was produced by AI agents (Claude) under the owner's direction.
Verification and audit runs were separate instances of the same model, not human review.
