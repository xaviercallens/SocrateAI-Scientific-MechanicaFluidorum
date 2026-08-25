# Directions, deliverables and next steps — recorded 25 August 2026

**Purpose:** record the direction split proposed with the OP-6a submission, the deliverables
accepted, and the next executable step for each. **Companion to:**
`2026-08-25-situation-brief.md` (state) and `LEDGER.md` (claims).
**Status:** the effort split in §2 is a **recommendation awaiting owner arbitration**; §1 and §3
are settled facts.

---

## 1. Deliverable received and arbitrated: OP-6a

**`lean_src/FourierStateZ3.lean`** — the 3-D Fourier kinematic state space. Externally
submitted with a spec; verbatim copy archived in `docs/proposals/`.

**Gate 2 arbitration: the submission did not compile — 15 errors.** It is now repaired,
compiles clean (exit 0, ten certificates), and is merged as **DRAFT** pending human
statement-adequacy audit, wired into Gate 2 so it cannot rot.

The instructive part is *how* it failed. Nine of the fifteen errors were one structural cause:
proofs built on `fin_cases` + `simp only [reduceIte]`, where `fin_cases` emits indices as
`⟨0, ⋯⟩` rather than literals and the simp-proc does not see through them. The submission
anticipated the risk and offered a fallback (plain `simp`). **The repair did not take the
fallback**; it rewrote both proofs to use indicator sums (`Finset.sum_ite_eq`), which never
mention a `Fin` literal at all. The three fragile `linear_combination` coefficients vanished
with them. **The GATE-RISK register is retired rather than patched** — the fragility class is
gone, not merely worked around.

Also worth recording as a methodological data point: the submission's self-report was *true and
irrelevant*. "Zero `axiom`, zero `sorry` by construction" was accurate; the file still did not
compile. That is LL-2's exact shape, and the third time this repository has caught it.

**Two deviations, both accepted as improvements** — D1 (ℂ-valued projector, reality recovered as
`leray_conj`, removing every cast obligation) and D2 (idempotence proved at the *operator* level
as a one-line corollary of DoD-1 + DoD-2, making the entrywise `P² = P` optional). D2 is the
right instinct: the operator acts on states; the matrix identity was decoration.

**Audit flags handed to the owner, not resolved here:**

| # | Flag |
|---|---|
| **F1** | **Possible vacuity.** `sublattice_invariance` is conditional on `htriad`, which the *zero map* satisfies trivially. Its content rests entirely on OP-6b producing a `B` that satisfies `htriad` **and** is not identically zero. This is the LL-11 failure mode; a witness `B` must accompany the OP-6b merge. |
| **F2** | `planeSubgroup` is defined but exercised by no theorem, and carries no witness that it is a proper subgroup. |
| **F3** | Checked and consistent: `GalerkinState.cutoff` keeps `\|k\|² ≤ M²`, matching the repo's lattice convention. |

**~~Unverified claim~~ — CORRECTED 2026-08-25.** I flagged the `CallensDualScale` rename
directive as unsourced after searching this repository. **The scope was wrong and the claim is
sound:** `~/xdev/SocrateAI-Mathesis` (Stream 0) contains `lean/Mathesis/Scale/Reff.lean`, whose
header cites consolidation from our file "renamed per the standing decision that no structure in
this library carries a person's name (§9, L4.5)", recorded in `SPEC-STREAM0` §9. The migration
is a live owner-decision item. See `2026-08-25-cross-stream-alignment.md` §A1 — including the
nuance that Stream 0's `MX-C-0011` deliberately keeps *two* independent proofs of `Reff`, so
consolidation need not mean deletion here.

## 2. Direction split — recommendation, pending arbitration

The submitted spec proposes **40 % Door #2 / 40 % the 5/6 paper / 20 % OP-6b**. That mapping is
consistent with brief §7 and I endorse it, with one sequencing amendment noted in §2.3.

### 2.1 Door #2 — sign-changing data below α = 1/2 *(the only open door)*

The submitted first move — a **sign-flip fragility probe** — is well-posed and I recommend it,
because it attacks the barrier where our own Tier A result already points. Identity (Q1) shows
the monotone `H_γ` family (`γ < 0`) needs the sign of `Σ λ^{(2γ+1)n+1}u_n²u_{n+1}`, which is
exactly what positivity supplies and sign-changing data destroys. So the question "where does
positivity actually do the work?" already has a partial, formal answer, and the probe extends it.

**Next executable step (theory, `[top]`):** a memo tracing, inequality by inequality, where each
step of the blow-up argument uses positivity — producing either a sign-robust variant or a
precise list of the cancellation points that fail. Derive by hand first (LL-5).

**Next executable step (experiment, Tier B/C):** α = 2/5, sign-alternating data, against the
**theorem-backed** positive control that BMR guarantees regular. Three hard requirements, from
this cycle's incidents:
- the run must **refuse to start** if the seed violates `u₀ ∈ V` (`require_hypothesis`, LL-17);
- terminations must distinguish physics from compute budget, and any aggregate containing a
  budget stop must refuse interpretation (`StopReason`/`Aggregate`, LL-18) — the previous θ
  probe's entire large-amplitude sweep was lost to exactly this;
- the null model must be computed **before** the numbers are interpreted (LL-14/15).

`FourierStateZ3` serves this direction only as phase-space bookkeeping. Invariant *repulsive*
manifolds are landmarks, not mechanisms — the guardrail applies.

### 2.2 The 5/6 conjecture's other half — the publication candidate

Endorsed without amendment. Self-contained, independent of Hypothesis U, and **half already
proved** with an explicit witness (linear functionals are exact eigenfunctions with eigenvalue
½ ⟹ gap ≤ 5/6). Remaining: that ½ is the *largest* odd eigenvalue.

**Next executable step:** `BALL_SPECTRAL_PROBLEM.md` §5 as written — spherical-harmonic
block-diagonalisation, then exact rational Rayleigh **upper** bounds per block. Lower bounds are
already exact. Mandatory control: the `ℓ = 1` block, whose top eigenvalue is *known* to be ½,
must be reproduced; a perturbed kernel must break the bound.

Pairing this with `TriadTorus.lean` (`A = 6(J−I) − 2P`, torus gap → 1) gives a clean external
paper — a spectral result with exact witnesses, whatever happens to Hypothesis U.

### 2.3 OP-6b and Thm 4.4 — with one sequencing amendment

The spec is right that `GalerkinState M` is the finite-dimensional arena where Mathlib's
Picard–Lindelöf becomes genuinely available, and that this is Thm 4.4's critical path.

**Amendment: F1 makes OP-6b's first deliverable the witness, not the vector field.** Before `B`
is used anywhere, it must be shown to satisfy `htriad` *and* to be somewhere nonzero. Otherwise
`sublattice_invariance` — the file's headline theorem — remains formally true and empty, and we
would be repeating the exact defect that killed three Sym² translations. Sequence:
**(i)** define `B` on finite support and prove `htriad` for it; **(ii)** a non-vacuity witness
(`B u v k ≠ 0` for one explicit triad); **(iii)** promote the `p ↔ q` pairing conservation,
already verified in exact arithmetic at `M ≤ 3`; **(iv)** then the ODE and local existence.

## 3. What was NOT accepted

- The submission's own request to "redonne tous les derniers Lean" was correctly declined by its
  author under LL-2, and that reasoning is endorsed: the compiled repository is the artifact of
  record, and regenerating files from conversation memory would produce strictly less reliable
  artefacts than the gates-green tree.
- The `CallensDualScale` rename directive — unverified premise (§1).
- Any reading of `sublattice_invariance` as evidence for confinement-based regularity. The
  guardrail is in the file header, the LEDGER row, and here.

## 4. Owner actions, consolidated

1. **Statement-adequacy audit of `FourierStateZ3.lean`** — structure fields, `GalerkinState.cutoff`
   shape, and the abstract `htriad` formulation, with **F1 the priority question**.
2. **Arbitrate the effort split** (recommendation: 40/40/20 as above, with the §2.3 amendment).
3. **Decide the `Reff` migration** — the Stream 0 rename decision is real (§1, corrected). The
   options are: migrate, keep our copy as a second independent kernel proof per `MX-C-0011`, or
   both. Stream 0's stated philosophy favours keeping two proofs.
4. **Adopt Tier `L`?** Stream 0 records the owner's 2026-08-14 adoption of a fifth tier for
   literature (`MX-C-0007`); our literature rows are currently unlettered under it.
5. **Go / no-go on the Door #2 theory memo** (`docs/designs/DOOR2_SIGN_FRAGILITY.md` §6) — it is
   the cheap half and it gates the experiment, which has no observable until the memo fixes one.
6. Carried from the situation brief, unchanged: the `IsGalerkinLimit` adequacy audit (now
   load-bearing for direction 3) and the two remaining draft-file audits.
7. **Cross-stream offers** (no decision needed, but worth knowing): Stream 6 is blocked on a
   Leray `Fin 3` lemma we proved today, believes NS Lean proofs "do not exist" when we hold 103,
   and carries a "2D3C depletes 97 % of triads" reading that our null model shows is enrichment
   (`D = 1.87`). Details and proposed offers in `2026-08-25-cross-stream-alignment.md` §3.
