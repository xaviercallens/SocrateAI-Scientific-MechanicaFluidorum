# Cross-stream alignment review — 25 August 2026

**Scope:** the other SocrateAI streams in `~/xdev/`, read for surfaces where their work and
Stream 1's (MechanicaFluidorum) touch. **Status of this document:** observations, each sourced
to a file I read. Where it reports another stream's claim, that is a **Tier C report of what
the file says**, never an endorsement — the same convention Stream 0 uses.
**Author:** orchestrator. **No implementation performed.**

---

## 0. The map, as Stream 0 records it

`SocrateAI-Mathesis` is **Stream 0**: the shared notation, verification kernel and epistemic
bookkeeping. It does no science of its own — "the first theorem here is about ledgers". It
maintains `docs/STREAM_MAP.md`, which lists eight streams and, more usefully, the **surfaces
where claims cross**. We are **Stream 1 (`MF`)**.

Stream 0 ranks those surfaces by how much damage a silent failure does, and puts
**narrative → publication (Stream 7, video) at the top**: "every other failure here is caught
eventually by a gate or a reviewer. A claim that reaches a video has left the system entirely,
and the retraction, if one is ever needed, is public." Our `docs/narrative/` quarantine and the
rule that it may never be imported by `lean_src/` are the right posture for that surface; they
should stay.

## 1. Findings that change something on our side

### A1 — I was wrong about the `CallensDualScale` rename; the decision is real

Yesterday I flagged the submitted rename directive as an unsourced claim, having searched
`SPEC.md`, `PLAN.md`, `LEDGER.md` and `docs/Memo 1.md`. **The search scope was wrong.** The
claim is cross-stream, and both halves check out:

- `SocrateAI-Mathesis/lean/Mathesis/Scale/Reff.lean` **exists**, and its header states it is the
  single source of truth for `Reff`, "consolidated from
  `SocrateAI-Scientific-MechanicaFluidorum/lean_src/CallensDualScale.lean`, renamed per the
  standing decision that no structure in this library carries a person's name (§9, L4.5)";
- the decision is recorded in `SPEC-STREAM0` §9.

**Lesson worth keeping:** verifying a cross-repository claim inside one repository and
concluding "unsourced" is the same class of error as verifying a threshold against an abstract
(LL-16) — correct discipline, wrong scope. The `LEDGER.md` row is corrected.

Two nuances Stream 0 records that matter for how the migration should be done:
- `MX-C-0011`: `Reff` is now proved **twice** (bespoke in `Scale/Reff.lean`, as an instance in
  `SelfDual.lean`), and **both survive by owner decision** — two independent kernel proofs of one
  statement is the differential-gate philosophy applied inside Lean. So consolidation here does
  not automatically mean deletion on our side.
- `MX-C-0003`: the duplicate `Reff` that `SPEC-STREAM0` §1 expected to find "does not exist" —
  a search of every `.lean` in `~/xdev` on 2026-08-13 found exactly one definition, ours.

**Owner decision item (unchanged in substance, now correctly sourced):** whether Stream 1
migrates `CallensDualScale.lean` to the Stream 0 target, keeps its copy as a second independent
proof per `MX-C-0011`, or does both.

### A2 — Tier **L** has been adopted programme-wide; our ledger notation is now behind

`MX-C-0001` records a **collision**: Stream 1 and Stream 5 both use the letter **B** for
incompatible admission criteria — *exact rational arithmetic* here, *peer-reviewed literature*
there. "A claim exported from one and imported by the other would silently convert a citation
into a computation."

`MX-C-0007` records the owner's resolution of 2026-08-14: **Tier `L` adopted — five tiers are
the programme notation**, Stream 5's literature rows migrate `B → L`, and `B` is reserved for
exact arithmetic programme-wide.

**Consequence for us.** Our `B` usage is already the exact-arithmetic one, so no row is
mis-tiered. But we now carry rows whose content is a *literature* fact rather than a
computation — the Cheskidov and Barbato–Morandin–Romito thresholds most obviously. Under the
five-tier notation those belong at **L**, and `tests/controls.py`'s `cite_threshold` already
holds exactly the metadata Tier L needs (theorem, hypotheses). This is a notation alignment, not
a re-verification: nothing changes about what is true, only about which letter carries it.

**Proposed, not done:** add Tier L to `SPEC.md` §2, re-letter the literature rows, and note in
`cite_threshold`'s docstring that a `Threshold` is the Tier L record for a constant.

### A3 — Stream 6 believes NS Lean proofs do not exist. They do; they are ours

`SocrateAIShared/lab5_lab0_ns_roadmap.md` (dated 2026-08-25, so current) contains this table for
the Navier–Stokes pathway:

| Component | Status (as that file states) |
|---|---|
| NS Lean proofs | ❌ **Does not exist** — Gap |
| Enstrophy bounds | ❌ **Does not exist in Lean** — Gap |
| Aubin–Lions | ❌ Not in this repo |

**As a statement about the programme this is false, and the correction is large.** Stream 1 has
**103 kernel-verified theorems** across ten Lean files, including exactly the two rows marked as
gaps: `EnstrophyProductionBound.lean` (15 theorems, the local bound `S_N² ≤ 2Ω_N³`) and
`EnstrophyProduction.lean` (11 theorems, the exact production identity), plus energy-flux
telescoping and monotonicity in `DyadicShells.lean`.

Its "Roadmap: 4 Steps to Tier A Navier-Stokes Formalization" then proposes building the Galerkin
energy estimate and 2-D enstrophy conservation from scratch. **That is duplicated effort against
work already at Tier A here.** The roadmap is scoped to its own repository, which explains the
table honestly — but the *conclusion drawn from it* ("Gap") is a programme-level claim that a
programme-level check refutes.

**Action proposed:** Stream 1 supplies its ledger to that roadmap rather than letting the gap
stand; the correction belongs in Stream 0's map, which is the place designed to hold it.

### A4 — We can close two of Stream 6's `sorry` stubs today

The same roadmap reports `NS_Galerkin_Energy.lean` with five theorems proven and
`inner_sub_proj_eq_zero` (the Leray projection identity) carrying **2 `sorry` stubs — "requires
Fin 3 ring algebra"**.

`lean_src/FourierStateZ3.lean`, merged today, proves exactly that content in `Fin 3` with zero
`sorry`: `leray_col_orthogonal` (`Σᵢ kᵢ P(k)ᵢⱼ = 0`), `applyLeray_div_free`,
`applyLeray_eq_self` and `applyLeray_idem`. The repair even removed the fragile `fin_cases`
idiom in favour of indicator sums, which is precisely the technique that makes "Fin 3 ring
algebra" tractable.

**This is the highest-value concrete alignment item in this review**: a stream is blocked on a
lemma another stream proved the same day. Offering it costs nothing and removes two `sorry`s.
*Caveat to state when offering:* our file is **DRAFT** pending statement-adequacy audit, and
flag **F1** (possible vacuity of `sublattice_invariance` until a nonzero `B` satisfying `htriad`
exists) travels with it.

### A5 — Stream 6's "2D3C depletes 97 % of triads" is a null-model artifact, and we have the number

The roadmap states the FGRS Oracle "proved that 2D3C planar confinement depletes 97 % of triadic
interactions", at Tier B.

**The raw count is roughly right and the inference is backwards.** Resonances `k₁+k₂=k₃` are
*trilinear* in the mode set, so keeping a fraction `f` of modes at random already leaves about
`f³` of the triads. Our `symbolic/depletion_screen.py` exists to make that correction, and run
today at `M = 6` it gives, for a coordinate-plane set:

```
one coordinate zero (a plane set)   f=0.325  |S|=300  triads=25518  null=13628  D=1.87  ENRICHMENT
```

The plane retains ~6 % of the lattice's 398 190 triads — a "94 % depletion" by raw count, close
to the quoted 97 %. But random thinning to the same density would leave only 13 628, and the
plane has **25 518 — 1.87× more than chance**. Planes are *enriched*, not depleted. Controls on
that screen behave: a random subset scores `D = 1.01` and the sublattice `(2ℤ)³` scores `7.25`.

**This is the exact error that killed three of our own Sym² translations** and is why the
depletion screen was written (LL-11). Separately, our owner verdict of 15 August killed 2D3C
confinement as a mechanism for a *different* and stronger reason: the manifold is exactly
invariant **and measurably repulsive** (excess `σ − σ_lin > 0` at all six points, both planes).

**Action proposed:** offer the screen and the verdict, not as a correction of their computation —
their count is fine — but of the reading. A number that looks like a mechanism because it was
never compared to chance is the single most repeated failure in this programme's record.

### A6 — Do not add an import into Stream 5's `DualScale/`

`MX-C-0003` (Stream 0's axiom survey, 2026-08-13): Stream 1's `lean_src/` has **0 axioms,
0 `sorry`**; Stream 5's `DualScale/` has **34 axioms across 14 files plus 2 `sorry`**.
Contamination is **latent, not live** — we import only Mathlib and use that tree solely as a
Mathlib provider. Three overlaps would become load-bearing the moment one `import` line were
added: `aubin_lions_compactness` (axiom there ×2, a hypothesis parameter here),
`dyadic_cascade_conservation` (axiom there, **proved Tier A here**), and `enstrophy`
(axiomatized there, defined here).

**Standing constraint, worth writing into `SPEC.md`:** Stream 1 imports Mathlib and nothing else
from another stream's tree. Our move to a standalone `lean_src/` Lake project already removed
the build coupling (`MX-C-0005` recorded that `LEAN_ENV_DIR` used to determine what was
*provable*, with no diagnostic separating "false" from "not built"); this keeps the axiom
coupling closed too.

## 2. What this review did **not** find

No conflict with our α-band results, our Riccati threshold theorem, or the 5/6 work — those have
no counterpart in another stream. No other stream is working on the dyadic shell model.

## 3. Proposed alignment actions, in order of value

| # | Action | Cost | Owner decision needed? |
|---|---|---|---|
| 1 | Offer `FourierStateZ3`'s Leray theorems to Stream 6 to close its two `sorry` stubs (A4) | ~0 | no — but flag F1 travels |
| 2 | Correct the "NS Lean proofs do not exist" gap via Stream 0's map (A3) | small | no |
| 3 | Offer the depletion screen + the OP-2′ verdict against the "97 % depletion" reading (A5) | small | no |
| 4 | Adopt Tier **L** in `SPEC.md` and re-letter our literature rows (A2) | small | **yes** — notation change |
| 5 | Decide the `Reff` migration: move, keep as second proof per `MX-C-0011`, or both (A1) | medium | **yes** |
| 6 | Write the "Mathlib only, from other streams" constraint into `SPEC.md` (A6) | small | no |
