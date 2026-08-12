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

### `lean_src/EnstrophyProduction.lean` — the dyadic enstrophy-production identity

| Claim | Formal name | Since |
|---|---|---|
| Pointwise doubling lemma: `prodIn(n+1) = 4·prodOut(n)` given `k(n+1)=2·k(n)` | `prodIn_succ_eq_four_mul_prodOut` | 2026-08-12 |
| Sum form of the doubling lemma | `sum_prodIn_eq_four_mul_sum_prodOut` | 2026-08-12 |
| **The production identity**: `Σ(prodIn−prodOut) = 3·Σ_{n<N} prodOut(n)` under truncation | `enstrophy_production_dyadic` | 2026-08-12 |
| Physical form: `dΩ/dt`'s nonlinear part `= 3·Σ k_n³ a_n² a_{n+1}` | `enstrophy_production_dyadic_NL`, `enstrophyTerm_eq` | 2026-08-12 |
| Negative control (non-doubling `k`) is kernel-verified to fail, not merely asserted | `negative_control_nondoubling` | 2026-08-12 |
| Non-vacuity: N=2 witness computes both sides to exactly 294 in Lean, matching independent hand and Tier B computation | `witness_lhs`, `witness_rhs`, `witness_theorem_gives_294` | 2026-08-12 |

**This is the dyadic analogue of vortex stretching, made exact.** `dΩ/dt = 3Σk_n³a_n²a_{n+1}
− νΣk_n⁴a_n²` — a signed production term against dissipation. The coefficient 3 is not a fit;
it is `r²−1` for doubling ratio `r=2`, and the Tier B harness independently confirms the
general formula holds at `r=3` (coefficient 8). **Scope (honesty clause):** an exact algebraic
identity between finite sums, not a bound — it does not by itself say whether production stays
dominated by dissipation as `N→∞`; that is the still-open dyadic Hypothesis U question this
identity was built to attack. General form proven (`k`,`a` arbitrary subject to the doubling
hypothesis), not merely the concrete `k_n=2^n` case — stronger and reusable.

**Tier B mirror** (`tests/tier_b_enstrophy_production.py`, wired into Gate 1): 240 exact-ℚ
cases at `k_n=2^n`, sanity case reproduces 294 exactly by hand/Python/Lean independently
(three-way agreement), negative control (`k_n=n+1`, non-doubling) fails with a nonzero
residual as required, bonus confirmation at ratio 3 (coefficient 8).

**Process note (recorded honestly):** the first commit of this file (`f279312`) was captured
mid-edit by `git add -A` while the authoring agent was still fixing a tactic failure (`rw
[hdouble]` did not see through an unreduced `match`); the committed version carried `sorryAx`
in five theorems. Caught and corrected same day — see the commit that follows this entry in
`git log` and `LL.md` LL-1.

### `lean_src/EnstrophyProductionBound.lean` — local production bound

| Claim | Formal name | Since |
|---|---|---|
| Pure algebra (doubling only): `Σ_{n<N}k_n²a_{n+1}² ≤ Ω_N` | `step1_flux_bound` (+ tighter `_half`) | 2026-08-12 |
| Sum-of-squares bound: `Σ_{n<N}k_n⁴a_n⁴ ≤ 4Ω_N²` | `step2_quartic_bound` | 2026-08-12 |
| Squared Cauchy–Schwarz combination | `step3_cauchy_schwarz` | 2026-08-12 |
| **`S_N² ≤ 2Ω_N³`** — the local production bound itself | `enstrophy_production_bound` | 2026-08-12 |

15 theorems, all footprints clean, independently recompiled. **Tier B mirror**
(`tests/tier_b_production_bound.py`, wired into Gate 1): 240 exact-ℚ cases per step;
negative control genuinely breaks Step 1 under non-doubling `k` (211/240 and 230/240 cases
for `k_n=n+1` and `k_n=1` respectively) — but did **not** break the final `MAIN` bound itself
on the tested state family, an honest, non-forced finding (Steps 2–3 don't use doubling at
all; whether `MAIN` can be violated under non-doubling `k` for some other state is open and
unexplored). **Erratum caught by the certifying agent, corrected same day**: the design
note's own Step 2 worked example quoted the full-range sum, not the restricted range Step 3
actually needs — does not affect the bound's validity (a sub-sum of nonnegative terms is
trivially ≤ the full sum); see the design note's erratum and `LL.md` LL-7.

*22 theorems total across the three files; all footprints verified
`[propext, Classical.choice, Quot.sound]` by independent recompilation 2026-08-12.*

*Scope note (honesty clause): these are lemmas about `max(R, α/R)`, scalar recurrences, and
abstract classes — not yet about fluids.*

### `lean_src/MillenniumReduction.lean` — conditional Millennium Reduction skeleton (F3)

| Claim | Formal name | Since |
|---|---|---|
| Untruncated (`N→∞`) solution family is inhabited (zero flow, given `hB`) | `zero_isFullSolution` | 2026-08-12 |
| Sobolev-level weight `k_n^{2s}` is nonnegative for any `k` (even exponent) | `sobolevWeight_nonneg` | 2026-08-12 |
| Zero flow is spatially smooth (every Sobolev class `H^s`) at every time | `zero_isSpatiallySmooth` | 2026-08-12 |
| **The reduction itself**: `∀T,HypothesisU` + `AubinLionsStatement` + `ProdiSerrinStatement` ⇒ `GlobalRegularityStatement` (time- and space-regular) | `millennium_reduction` | 2026-08-12 |
| `HasBoundedFullLimit`/`GlobalRegularityStatement` are satisfiable, not vacuous (zero-flow witnesses) | `zero_has_bounded_full_limit`, `zero_global_regularity` | 2026-08-12 |

7 theorems, all footprints clean, independently recompiled. **CONDITIONAL SKELETON — proves no
PDE content.** `AubinLionsStatement` and `ProdiSerrinStatement` are named `Prop`-valued
hypothesis parameters (never axioms, per `docs/REVIEW-2026-08-12.md` L7) standing for the
undischarged Aubin–Lions compactness step and Prodi–Serrin regularity criterion
(SPEC.md §1.1 / `docs/HYPOTHESIS_U_SPECIFICATION.md` §II); `millennium_reduction`'s proof is the
one-line composition `hPS (hAL hU)` — all analytic weight is parked in the two hypotheses'
*types*, not proved here. Design + derivation: `docs/designs/F3_MILLENNIUM_REDUCTION_SKELETON.md`.

**Audit round 1 (2026-08-12), human-owner decisions recorded (Q3/Q4/Q5, same pattern as F2's
Q1/Q2):** the author's own adversarial self-review against SPEC.md's actual Proposition 5.1
text found — and the human owner accepted repairs for — three adequacy gaps in the first
version: **Q3** `GlobalRegularityStatement` covered only time-regularity (`HasDerivAt`
existing for all `t`), not spatial smoothness; repaired by adding `IsSpatiallySmooth`
(membership in the Fourier-side Sobolev class `H^s` for *every* `s`, the standard
Fourier-coefficient-decay characterization of `C^∞` on a torus) and a genuine wavenumber
parameter `k` with `w n = (k n)²` (`hwk`). **Q4** the theorem took a single fixed `T` yet
concluded a `T`-independent result, silently absorbing SPEC.md's "for all T" into
`ProdiSerrinStatement`'s undischarged content; repaired by quantifying `hU` over all `T`
explicitly. **Q5** `HasBoundedFullLimit` didn't require `w ≥ 0` (unlike F2's own
`enstrophy_nonneg`), so "bounded partial sums" didn't cleanly mean "enstrophy controlled";
repaired by threading `hw : ∀ n, 0 ≤ w n` through. Four hand-derived negative controls
(NC1–NC3 re-verified against the revised structure, NC4 newly added — a statement-adequacy
risk, not a compile-time-checkable one) confirmed to behave as predicted. Both gates
independently re-run and PASS after the revision.

**Status: awaiting full human statement-adequacy audit** (PLAN.md's oversight split —
authorship by the top-tier agent, even through a self-review pass, never itself licenses the
claim; same DRAFT-pending-audit posture as F2's `HypothesisU_Statements.lean` before its
Q1/Q2 audit — Q3/Q4/Q5 fixed three found gaps, they do not certify no others remain).

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
| **Dyadic enstrophy-production identity** (mirrors `EnstrophyProduction.lean` above): `Σk_n²a_nNL_n = 3Σ_{n<N}k_n³a_n²a_{n+1}` for `k_n=2^n`, 240 exact cases; negative control (`k_n=n+1`, non-doubling) fails; bonus confirms general formula (ratio `r`, coeff `r²−1`) at `r=3` | P1 | `tests/tier_b_enstrophy_production.py` |
| Rational IMEX-Euler discretization of the truncated dyadic shell model, negative control (perturbed influx term) fails as required — **instrument verified; the intended cutoff-uniformity measurement was NOT obtained; DEMOTED to Tier C, see decision below** | D5 | `symbolic/dyadic_imex.py`, `data/dyadic_omega_sup_imex.csv` (sha256 `8844dd2e…3580128`) |

**Human-owner decision on `docs/escalations/2026-08-12-D5-digit-blowup.md`, recorded 2026-08-12
(PLAN.md §8 — verdicts are human-owner-only):** option 3 accepted. D5's exact-rational
certification attempt is closed; no further work will try to certify the trajectory
measurement in ℚ (confirmed twice now, by two independent redesigns — D4 explicit float RK4,
D5 rational IMEX-Euler — that exact/rational iteration of this nonlinear recurrence is
structurally unworkable, not a bug in either design). Steering data is retained as permanent
Tier C, per the caveats below.

**Dual-precision (Tier C, quarantined) steering data**: `exploration/dyadic_imex_dual_precision.py`,
`data/dyadic_imex_dual_precision.csv` (sha256 `02256f87…c103d`, verified independently). Same
IMEX-Euler scheme in float64 + mpmath-50-digit, full N∈{8..24} grid, T=10. 45 rows; several
configurations at low ν (0.01, 0.001) show `status=DIVERGED` with fp64/mp50 agreeing to
~1e-14–1e-16 — agreement this tight rules out ordinary floating-point rounding as the cause,
but did **not by itself** distinguish genuine trajectory divergence from a `dt` that was simply
too coarse: the design memo's `dt` formula depends only on the initial profile's excited scale,
never on `ν`, so it was never re-tuned for the low-viscosity configurations that diverge.

**Follow-up dt-refinement study (accepted 2026-08-12 as the concrete next step, resolves the
caveat above):** `exploration/dyadic_imex_dt_refinement.py`, `data/dyadic_imex_dt_refinement.csv`
(sha256 `3ed72957…500ecf`, verified independently, bit-for-bit reproducible on rerun). All 4
distinct `(ν, profile)` pairs that diverged in the dual-precision sweep were re-run at
`dt, dt/2, dt/4, dt/8, dt/16` (fp64; N=24 primary + N=8 cross-check, identical at every level —
confirms the phenomenon is N-independent under refinement too). **In every one of the 4 cases,
`status` flips from `DIVERGED` to `OK` at a finite refinement level and stays `OK` at every
finer level tested**, with `sup_Omega` monotonically *decreasing* as `dt` shrinks further within
the `OK` regime (e.g. ν=0.01,P1: 45.1 → 21.8 → 17.3 → 15.8 across the last four levels) rather
than converging to a large or unbounded value — the signature of a discretization artifact
resolving under refinement, not of a fixed-time genuine blow-up (which would keep reappearing,
at a stable time, however fine `dt` gets). **No verdict is drawn here per PLAN.md §8** — this is
reported as the raw finding for the human owner's read, not asserted as a proof that no genuine
divergence exists in the true (continuum-time) dyadic model; it only shows the specific
divergences observed at the original `dt` do not survive step-size refinement of this discrete
scheme.

## Tier A — `lean_src/HypothesisU_Statements.lean` (statement shape; audited 2026-08-12)

Q1 and Q2 (below) were **decided by the human owner 2026-08-12** and implemented same day;
recompiled independently, 9 theorems, all footprints clean. The *shape* of the statement is
now audited; the *instantiation* of `B` by the true NSE nonlinearity remains explicitly
out of scope (declared exclusion in the file) and is where the program's real content lives.

| Claim | Formal name | Decision |
|---|---|---|
| `truncate` projects `u₀` onto modes ≤ N; `truncate 0-datum = 0-datum` | `truncate`, `truncate_zero` | Q1: projected initial data, mirroring `u(0)=J_{√α'}u₀` |
| `IsGalerkinSolution` clause (i) is `u 0 = truncate N u0` — no vacuity leak across cutoffs | `IsGalerkinSolution` | Q1 |
| Concrete weight `w n = (2ⁿ)²`, matching `DyadicShells.lean`'s `k_n` | `dyadicWavenumber`, `dyadicWeight` | Q2: concrete `w n = k n²` |
| Enstrophy is genuinely nonnegative (general `w ≥ 0`, and the concrete dyadic instance) | `enstrophy_nonneg`, `enstrophy_nonneg_dyadic` | Q2 |
| Concrete top-level statement | `HypothesisU_dyadic` | Q1+Q2 combined |
| **The prior formalization is provably false** (machine-checked, not prose) | `unconstrained_bound_false` (via `enstrophy_smul`) | — |
| `IsGalerkinSolution` is inhabited (non-vacuity, §7.5) | `zero_isGalerkinSolution` | — |

*Remaining open item, unaffected by Q1/Q2:* `B` (the mode-interaction term) is still an
abstract parameter; no claim about actual Navier–Stokes solutions may be drawn from this file.

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
| **Local bound derivation** `S_N² ≤ 2Ω_N³` (docs/designs/ENSTROPHY_PRODUCTION_BOUND.md) | **Tier A** — proven (see below); **Tier B** mirror in `tests/tier_b_production_bound.py` | Sqrt-free, three-step (algebra + `Σx²≤(Σx)²` + Cauchy-Schwarz). **Local only** — does not use dissipation, does not address uniformity in N. |
| Barbato–Morandin–Romito, *"Smooth solutions for the dyadic model,"* arXiv:1007.3401 (2010) | Abstract verified via WebFetch 2026-08-12; full proof NOT reviewed | Proves well-posedness of **positive** solutions of the viscous dyadic model in the NSE-matching scaling range — a real, precisely-scoped result, not unconditional global regularity. Do not cite more broadly than this. |
| **OP-2…OP-5 draft definitions** (Sym²-spectrum embedding, enstrophy echo, entropy functional, percolation coupling) | Drafted 2026-08-12, **awaiting human audit** (PLAN.md §6 — audit is what unblocks, not authorship) | `docs/designs/TRACK_DEFINITIONS_DRAFT.md`. Surfaces a structural finding: the proposed T3 (`h=Ω, ū=0`) collapses into the direct production-identity attack rather than being independent; T1 and T4 share the OP-2 embedding and so are correlated, not independent, measurements. |

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
