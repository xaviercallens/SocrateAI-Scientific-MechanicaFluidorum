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

| Sym² lock, variable coefficients (ported from prior tree, source's `+` convention) | `sym2_recurrence_variable` | ibid. | 2026-08-12 (F1) |

### `lean_src/DyadicShells.lean` — dyadic laboratory (Stage 1)

| Claim | Formal name | Since |
|---|---|---|
| Nonlinear energy flux telescopes to −outFlux N (arbitrary `k`, `a`) | `dyadic_flux_telescopes` | 2026-08-12 (D2) |
| Net nonlinear flux vanishes under truncation `a_{N+1}=0` | `dyadic_flux_zero_of_boundary` | 2026-08-12 (D2) |
| **Energy monotonicity** `dE/dt ≤ 0` for `ν ≥ 0` under truncation | `energyRate_nonpos` | 2026-08-12 (D3) |

*Scope (honesty clause): these are statements about a **finite sum**, not yet about ODE
solutions — no existence theory is invoked. They establish the ENERGY identity, **not** an
enstrophy bound; the enstrophy question (the Hypothesis U analogue) remains untouched.
Non-vacuity: witness pins `energyRate = −1` exactly, so `≤ 0` is not `0 ≤ 0`.*

*22 theorems total across the three files; all footprints verified
`[propext, Classical.choice, Quot.sound]` by independent recompilation 2026-08-12.*

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
| Unconstrained triads N(M) = #{ (k₁,k₂,k₃) ∈ (ℤ³)³ : k₁ + k₂ = k₃, \|kᵢ\|² ≤ M² }, M ∈ {2,4,8,16}, negative control (< vs ≤) | T0.2 | `data/triads_free.csv` |
| Lattice counts r₃(n), n ≤ 10000; Legendre anchors incl. r₃(7)=r₃(15)=0; negative control fails | T0.1 | `data/r3_counts.csv` (sha256 `4d51aa5a…33f1`) |
| **Dyadic energy flux telescopes** (exact ℚ, N=1..12, 240 cases) + partial-sum form (1800 cases); negative control (k_{n-1}→k_n) fails with residual 2/3 | D1 | `tests/tier_b_dyadic_checks.py` |
| Exact 3-D periodic percolation instrument: union-find, wrap detection, 27 checks; negative control (drop x-periodicity) fails | T0.3 | `symbolic/percolation_exact.py`, `tests/test_percolation.py` |

## Awaiting human statement-adequacy audit (NOT tiered — no claim may cite these)

`lean_src/HypothesisU_Statements.lean` compiles clean (5 theorems, clean footprints) but its
*statements* are unaudited, so nothing in it is a claim yet. Notably it **proves the prior
formalization was false**: `unconstrained_bound_false` machine-checks that "for all fields u,
enstrophy ≤ C" is refutable (via degree-2 homogeneity `enstrophy_smul`), converting
REVIEW finding L3 from prose into a theorem.

**Two questions the authoring agent raised and correctly refused to decide (PLAN.md E-4):**

- **Q1 (vacuity leak, load-bearing).** `HypothesisU` fixes one `u₀` across all cutoffs `N`,
  while clause (iii) forces `u t n = 0` for `n > N`. So if `u₀` has any mode above `N`, no
  solution exists at that `N` and the bound holds **vacuously** there. Fix requires choosing
  between (a) projecting `u₀` onto modes ≤ N at each cutoff, or (b) restricting to finitely
  supported `u₀`. **This is a statement-level decision for the human owner.**
- **Q2.** Whether the weight `w` should be constrained (`0 < w n`, or `w n = k n²`). Currently
  unconstrained, so `enstrophy` is not even asserted nonnegative.

## Tier C — conjectures, analogies, unformalized arguments

| Claim | Status | Roadmap |
|---|---|---|
| **Hypothesis U** (core assertion) | Open, Millennium-equivalent | Resolved by Stage 3 success (Weeks 17–28) |
| **Conjecture U** (mechanism via Sym² lock) | Unproven, architecturally sound | Verified via four analytical tracks |
| **Proposition 5.1** (U ⇒ regularity) | Paper-level standard; formalization = Stage 2 | Weeks 9–16 (Leray mollification, Prodi-Serrin) |
| **Stage 1: Shell-Model Well-Posedness** | Target: Tier A/B | Weeks 3–8. Falsifiable milestone: no blow-up in 100 empirical runs. |
| **Track T1 (Bourgain-Demeter)** | Arithmetic depletion via ℓ² decoupling | Weeks 17–24. Milestone: triadic resonance count η(M) ≪ 1. |
| **Track T2 (Villani-Mouhot)** | Phase mixing & enstrophy echo suppression | Weeks 17–24. Milestone: echo amplitude decays exponentially. |
| **Track T3 (Golse-Saint-Raymond)** | Hydrodynamic entropy limits as α' → 0 | Weeks 17–24. Milestone: dissipation rate O(1) uniform in α'. |
| **Track T4 (Duminil-Copin)** | Percolation scaling & zero Hausdorff dimension | Weeks 17–24. Milestone: subcritical percolation, dim < 1. |
| OP-1: Derive J_{√α'} dynamics from Reff metric | Open problem; metric = inspiration only | Research frontier (deferred). |
| Sym² lock relevance to NSE cascade | To be earned in Stage 1 dyadic lab | Validated empirically + formally (Stage 1). |
| All physical narrative (cosmology, dark sector) | Quarantined in `docs/narrative/` | Never imported by `lean_src/`. |

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
