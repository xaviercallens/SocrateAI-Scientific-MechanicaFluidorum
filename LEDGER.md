# Epistemic Ledger (normative — a claim not listed here has no tier)

Last verified: 2026-08-12 (`scripts/verify.sh` → both gates PASS).

## Tier A — kernel-verified (zero sorry, footprint [propext, Classical.choice, Quot.sound])

| Claim | Formal name | Artifact | Since |
|---|---|---|---|
| Effective radius is positive (α, R > 0) | `Reff_pos` | `lean_src/CallensDualScale.lean` | 2026-08-12 |
| T-dual bound √α ≤ Reff α R | `Reff_ge_sqrt` | ibid. | 2026-08-12 |
| Bounce: R < √α → Reff = α/R | `Reff_bounce` | ibid. | 2026-08-12 |
| Inertial invisibility: √α ≤ R → Reff = R | `Reff_inertial` | ibid. | 2026-08-12 |
| T-duality: Reff α (α/R) = Reff α R | `Reff_tdual` | ibid. | 2026-08-12 |
| Strictness off the self-dual radius | `Reff_gt_sqrt_of_ne` | ibid. | 2026-08-12 |
| **Sharpness**: Reff = √α ⟺ R = √α (minimum attained exactly at the self-dual radius) | `Reff_eq_sqrt_iff` | ibid. | 2026-08-12 |
| Piecewise ("bounce") form = max form, for R > 0 | `tDualRadius_eq_Reff` | ibid. | 2026-08-12 |
| Genesis bounce: 0 < tDualRadius α R (axiom-free) | `genesis_no_singularity` | ibid. | 2026-08-12 |
| Necessity of the R > 0 side condition (α=4, R=−1 witness) | `example` | ibid. | 2026-08-12 |
| Sym² lock, constant coefficients | `sym2_recurrence` | ibid. | 2026-08-12 |
| Sym² lock, sequence-level interface | `sym2_recurrence_seq` | ibid. | 2026-08-12 |
| **Spectral form**: L3 coefficients = elementary symmetric functions of {λ², λμ, μ²} (e₁=a²+b, e₂=−b(a²+b), e₃=−b³) | `sym2_symmetric_functions` | ibid. | 2026-08-12 |
| Wave-mass nonzero (sanity lemma; one-step consequence of `resonance_law`) | `wave_mass_nonzero` | ibid. | 2026-08-12 |
| All Pillar-3 classes are inhabited (non-vacuity §7.5) | instances on ℝ | ibid. | 2026-08-12 |

*13 theorems total; all footprints verified `[propext, Classical.choice, Quot.sound]`.*

*Scope note (honesty clause): these are lemmas about `max(R, α/R)`, scalar recurrences, and
abstract classes — not yet about fluids.*

## Tier B — exact-arithmetic verified (ℚ, zero floats)

| Claim | Check | Artifact |
|---|---|---|
| Sym² lock, constant coeff. (196-case sweep) | B1 | `tests/tier_b_exact_checks.py` |
| Sym² lock, variable coefficients | B2 | ibid. (kernel proof exists in prior tree; migration = Stage 0) |
| Reff laws over ℚ, sqrt-free square forms | B3 | ibid. |
| L3 coefficients recoverable from data (guess-and-prove closes) | B4 | ibid. |
| Sharpness at self-dual radius; piecewise ≡ max for R>0; disagreement at R=−1 | B5 | ibid. |
| Spectral form of the Sym² lock over root pairs | B6 | ibid. |
| Guesser negative control: u³ refused at order 3, verified at order 4 (Sym³) | — | `symbolic/picard_fuchs_generator.py` |

## Tier C — conjectures, analogies, unformalized arguments

| Claim | Notes |
|---|---|
| **Hypothesis U** | Open. Equivalent in difficulty to the Millennium core (SPEC §1.2). |
| Proposition 5.1 (U ⇒ global regularity) | Paper-level standard chain; formalization = Stage 2. |
| Tracks T1–T4 | Analogies with milestones & kill criteria (SPEC §2.3). Obstruction notes required. |
| OP-1: derive the J_{√α'} dynamics from the Reff metric | Open problem; currently metric = inspiration only. |
| Sym² lock relevance to NSE cascade | Conjecture; to be earned in Stage 1 (dyadic laboratory). |
| All physical narrative (cosmology, dark sector, K3 constants) | Quarantined in `docs/narrative/`. |

## Retired / corrected claims

| v0.1 claim | Disposition |
|---|---|
| "Reff theorems proven in Lean with zero custom axioms" | Was false when written (no such proofs existed); made true 2026-08-12. |
| `genesis_no_singularity` with axiom `alpha_prime` | Violated §7.1 and its own #print-axioms expectation; superseded by axiom-free `Reff_pos`. |
| Prior-tree `HypothesisU` (arbitrary smooth fields) | Provably false as formalized (scaling); statement to be rebuilt with the equation as constraint (Stage 2). |
| Prior-tree `global_well_posedness_regularized_shell` | Trivial witness (u ≡ 0); statement to be rebuilt quantifying over data (Stage 1). |
| `axiom aubin_lions_compactness` | Banned form; to re-enter as hypothesis parameter (Stage 2). |
| Proposal (2026-08-12) `Reff_ge_sqrt` "proven, no sorry" | Did **not** compile (4 Lean-idiom errors); footprint contained `sorryAx`. Statement is true and was already proven in the core by another route. Evidence: `docs/proposals/2026-08-12-proposal-kernel-log.txt`. |
| Proposal `genesis_no_singularity` with `opaque alpha_prime` + `axiom alpha_prime_pos` | Compiled, but footprint carried `alpha_prime_pos`; `opaque` improves on v0.1 yet still fails the gate. Superseded by the axiom-free parameterized version. |
