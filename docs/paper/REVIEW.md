# Peer review — `exact_triad_structure.tex` (draft of 2026-09-17, commit `1aa60e0`)

**Method.** Every theorem in the draft was checked against the Lean statement it claims to rest
on (`FourierDynamicsZ3.lean`, `AbstractAlgebraicConservation.lean`, `HelicalBasis.lean`,
`TriadTorus.lean`), every number against its source (`LEDGER.md`, `symbolic/ball_gap_large_M.py`,
a fresh recount of `|Λ_M|`), and every novelty claim against the literature (references verified
by retrieval, per the programme's LL-6). Format: the `claim-auditor` output format
(`docs/harness/agent-claim-auditor.md`). All findings below are addressed in the revision.

## Findings

**[BLOCKING] Novelty overclaim on the helical coefficient.**
- Where: abstract ("closing, for the first time to our knowledge in closed form, the inventory");
  §1 ("prior treatments of the helical decomposition leave open in general").
- Evidence: Waleffe, *Phys. Fluids A* **4** (1992) 350–363 (retrieved: AIP, ADS, NTRS listings)
  introduces the helical decomposition and derives the triad coefficient in the factorised form
  `∝ (s_p|p| − s_q|q|) × g`; the resonance condition `s_k|k|+s_p|p|+s_q|q| = 0` and the
  balance condition are classical there. The programme's own Lean docstring
  (`FourierDynamicsZ3.lean`, `enstrophy_production_identity`) says of the production identity: "It
  is also not new mathematics; the enstrophy production of the Fourier–Galerkin system is
  classical. What is new is only that it is kernel-checked."
- Failure: a referee familiar with Waleffe rejects the paper for claiming priority on a
  30-year-old result.
- Fix: attribute both the decomposition and the factorised coefficient to Waleffe; state the
  contribution accurately — a square-root-free integer-frame form of the coefficient, machine-
  checked, cross-checked in exact integers, with the "iff" (no further vanishing locus) stated
  and proved explicitly. Remove every "first" / "to our knowledge leaves open".

**[BLOCKING] Theorem 6.1 is stated for "any finite abelian group"; the Lean theorem requires no
2-torsion, and `n` is misdefined.**
- Where: §6, Theorem 6.1.
- Evidence: `TriadTorus.lean` `row_sum`, `eigen_even`, `eigen_odd` all carry
  `h2t : ∀ x, x + x = 0 → x = 0`; the file header says it "is genuinely needed" (with 2-torsion,
  `−u = u` puts the `P`-term on the excluded diagonal). `row_sum` gives degree
  `6·|Λ| − 8` with `|Λ| = |G| − 1`; the draft wrote "G of order n" and "degree 6n−8", which is
  off by 6.
- Failure: false as stated for `(ℤ/2)³`; the degree formula is wrong for the stated `n`.
- Fix: hypothesis "finite abelian group with no element of order 2"; `n := |Λ| = |G| − 1`;
  matrix defined on ordered pairs of distinct modes (zero diagonal); proof included (4 lines).

**[SUBSTANTIVE] "Seven-point" evidence is six points.**
- Where: abstract, Open Problem 6.2.
- Evidence: `LEDGER.md` lists gaps at `M = 2..7`: 0.834985, 0.833575, 0.833419, 0.833392,
  0.833359, 0.833348 — six values; the six deviations in the draft are the right ones. The
  LEDGER's own phrase "seven-point" is the transcription error the draft inherited.
- Fix: six points, `M = 2, …, 7`, with `|Λ_M| = 32, 122, 256, 514, 924, 1418` (recounted;
  the last two match the archived 924/1418), tabulated.

**[SUBSTANTIVE] Hypotheses of Theorems 4.2 and 5.1 are under-stated.**
- Evidence: `cOf_eq_zero_iff` holds for arbitrary real `s_k, s_p, s_q` and has three disjuncts
  (collinear ∨ resonance-sum = 0 ∨ balanced); the collapse to two members uses
  `resonance_implies_collinear_full`, which needs `s ∈ {±1}³` and `|k|,|p|,|q| > 0`.
- Fix: state signs in `{±1}`, `p, q, k = p+q` all nonzero; present the three-disjunct
  statement and then the two-member corollary.

**[SUBSTANTIVE] The coefficient's normalisation and gauge are not stated.**
- Evidence: `hOf N s k = (N × k) + i s |k| N` is unnormalised (`|N||k|` times Waleffe's
  `h^s`), the frame is `N = p × q` common to all three modes, and `gOf` is `|N|³|p||q||k|` times
  the memo's `g`; the file's own `cOf_neg_triad_frame` / global-`ν` results show the *phase* of
  `C` is frame-dependent. The draft presents (6) as "the" coefficient.
- Failure: a reader comparing (6) with Waleffe's normalised coefficient finds a different
  prefactor and phase.
- Fix: define `h^s_N(k)` explicitly, say the closed form is in that frame and scaling, and that
  the zero locus is invariant under any nonzero rescaling of the three basis vectors (so
  Theorem 5.1 is frame-independent while the prefactor and phase of (6) are not).

**[SUBSTANTIVE] Hypotheses of Corollaries 3.2–3.3 (reality) not stated; the abstract identity is
bilinear.**
- Evidence: `weighted_triad_pairing` is over a field with the *bilinear* dot (no conjugation);
  `energy_conservation` and `enstrophy_production_identity` are stated for `GalerkinState`,
  whose `FourierState` carries `conj_sym : u(−k) = conj u(k)`, used once (`hneg`) to turn the
  Hermitian pairing into the bilinear form; `triad_sum_zero` needs `2` invertible (`h2`);
  the Lean production identity is for the complex quantity, the physical rate is its real part.
- Fix: state "real (conjugate-symmetric), divergence-free" where used; note the field
  hypothesis; say the physical rate is the real part.

**[SUBSTANTIVE] Proof of Theorem 6.1 omitted ("supplementary material").**
- Fix: it is four lines given `A = 6(J−I) − 2P`; include it.

**[NOTE] `\author{}` is empty** — the PDF has no author. Placeholder inserted; the owner supplies
names and affiliations.

**[NOTE] Abstract is one 250-word paragraph**; "unexpectedly clean, unexpectedly unified" and
"That structure turns out to be…" oversell a rederivation. Trimmed and toned to the contribution.

**[NOTE] Triad-sum indexing.** The Lean sums run over the set of ordered pairs `(p, q)` with
`r = −(p+q)`, all three in the ball (`triadSet`); "Σ over triads" should say so, since the
factor 2 on the left of (3) depends on it.

**[NOTE] Terminology.** "normalised spectral gap" was undefined; defined as `1 − λ₂` of the
degree-normalised adjacency, matching `symbolic/triad_hypergraph.normalised_laplacian_gap`.

**[NOTE] References.** None in the draft. Added, each verified by retrieval on 2026-09-17:
Waleffe 1992; Kraichnan, *J. Fluid Mech.* **5** (1959) 497–543 (detailed conservation);
Zgliczyński–Mischaikow, *Found. Comput. Math.* **1** (2001) 255–288, DOI 10.1007/s002080010010
(self-consistent a-priori bounds); de Moura–Ullrich, CADE-28 (2021); The mathlib Community,
CPP 2020, DOI 10.1145/3372885.3373824.

`VERDICT: 2 blocking, 5 substantive, 5 notes` — all resolved in the revision committed with
this file.

## What the review did not find

No error in any identity as transcribed: (1), (2), (3), (4), (5), (6) match
`weighted_triad_pairing`, `energy_conservation`, `enstrophy_production_identity`,
`energyRateZ3_eq`, `enstrophyRateZ3_eq`, and `cOf_closed_form` respectively, sign for sign. The
numbers 2.1×10⁻¹⁶, 5 256 integer checks, and 558 090 lattice triads for the resonance sweep
are the report's own; the mode counts 924 and 1 418 were reproduced by an independent recount.
