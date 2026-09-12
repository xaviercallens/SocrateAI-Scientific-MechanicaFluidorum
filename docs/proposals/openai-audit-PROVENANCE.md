# WP-0b audit artifacts — provenance and verdict against the pre-registered criterion

**Recorded:** 2026-09-12, by Fable. **Audit design:** `openai-audit-vm.sh` (committed before any
result existed), acceptance criteria in its header and in LEDGER.

## Provenance

The audited tree: `github.com/openai/NavierStokesAndEuler`, commit
`8937a8f4cbc7abaab5e9e97d1cc7f5d2319d9538`, branch `main`, Lean `4.34.0-rc2`, built by the owner
on a GCP VM (8 cores, precompiled Mathlib cache), `build_success: true`, 0 errors, 517 project
oleans. All artifacts published world-readable at
`gs://socrateai-datalake-gen-lang-client-0625573011/formal_verification/navierstokes_euler/`
(`build_summary.json`, `BUILD_ANALYSIS_REPORT.md`, `build.log`, the olean archive, and the three
audit outputs). The transcripts archived beside this note were fetched from that bucket by this
session and copied verbatim:

- `openai-audit-main.transcript.txt` — fetched 2026-09-12 (a background monitor caught the upload).
- `openai-audit-placeholders.transcript.txt` — fetched 2026-09-10.
- import scan: the bucket object `import-scan.txt` is **empty by design** — zero matches for
  `import ComparatorChallenges` under `NavierStokes/` or `Euler/`.

## Verdict against the pre-registered acceptance criteria

| part | criterion | result |
|---|---|---|
| 1, proof tree | all four footprints exactly `[propext, Classical.choice, Quot.sound]` | **PASS** — all four exact |
| 2, placeholders | `sorryAx` present in all four (built-in negative control) | **PASS** — present in all four |
| 3, import scan | zero proof-tree imports of the challenge modules | **PASS** — zero |

**Consequence (per the owner's adjudication of 2026-09-10, Q5):** the four proof-tree theorems
are now citable as **Tier L** context — kernel-verified statements of: forced Navier–Stokes
breakdown on ℝ³ and on the torus (Clay options C and D, with the manufactured-residual force),
and unforced Euler blowup for a constructed compact smooth datum, with the detailed singularity
package. **Standing caveat F-NAME travels with every citation:** the discharge of the
DeepMind-derived challenge *statements* is meta-level — placeholder and proof share
fully-qualified names in never-co-importable modules, so statement equivalence is certified by
human comparison, not by the kernel. Nothing here touches Statement A, global regularity, or
Hypothesis U; the asymmetry analysis in
`2026-09-10-dual-scale-openai-leverage-review.md` §5 stands.
