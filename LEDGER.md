# Epistemic Ledger (normative — a claim not listed here has no tier)

Last verified: 2026-08-13 (`scripts/verify.sh` → all gates PASS, exit 0; 70 Lean theorems
kernel-compiled, of which 63 carry Tier A claims — `MillenniumReduction.lean`'s 7 are demoted,
see the audit section below).

## External audit 2026-08-13 — verdicts (human-issued; fully accepted, `docs/Memo 1.md`)

The external expert audit of `docs/AUDIT_PACKET.md` (audit target commit `1befcc1`+) returned
the following verdicts. Per SPEC §0/§8 these are human verdicts, recorded verbatim in intent;
a negative verdict is a completed scientific outcome. Dispositions are what this repo did.

| Q | Verdict | Substance | Disposition |
|---|---|---|---|
| A1 quantifier order `∃C∀N` | **YES** | Correct order for uniformity | Retained |
| A2 index vs frequency cutoff | **NO** | "Severe abstraction leak" — 1-D index flattening destroys ℤ³ geometry, density of states, triad constraints | **Dissolved by pivot**: the target is now the dyadic shell model, where the index IS the object |
| A3 weight `4ⁿ` | **NO** | Locks the theorem to an exponential sequence spectrum, decoupled from 3-D | **Dissolved by pivot**: `4ⁿ = k_n²` is the shell model's true weight |
| A4 quantify over every solution | **YES** | Finite-dim ODE: Picard–Lindelöf uniqueness; B–V applies to the limit PDE only | Retained |
| A5 unconstrained `B` | **NO** | "Fatal flaw... authenticating a mathematically empty envelope"; `B` must enforce `⟨B(u,u),u⟩=0` | **Fixed** (Memo Task 2): concrete `shellB` + Tier A `shellB_energy_conservation` |
| B1 `Prop→Prop` placeholders | **NO** | Kernel verifies only a tautology; violates DoD "bona fide statements" | **Demotion executed**: `MillenniumReduction.lean` → Tier C draft; repair = Memo Task 4 |
| B2 per-`T` limit | **REVISE** | Must hoist `∃ ulim, ∀ T`; needs Cantor diagonal | **Hoisted** (Memo Task 3): `HasGlobalBoundedLimit`; the diagonalisation now sits in `AubinLionsStatement`'s type |
| B3 per-time smoothness | **YES** | Physically correct (`t→0` divergence for `L²` data) | Retained |
| B4 no specialisation | **REVISE** | Generic reduction must be instantiated against the audited concrete object | **OPEN** — PLAN §10, part of the Task 4 repair |
| B5 bare existence | **YES** | Weak–strong uniqueness makes existence sufficient | Retained |
| C1 abstraction honesty | **OVERSTATES REACH** | Bypasses geometric aliasing on ℤ³ entirely | **Scope-fixed**: renamed `AbstractAlgebraicConservation.lean`, docstring states the exclusion |
| D1 tier overstatement | **KILLED** | "We are not restating the unreduced Millennium Problem" — the formalisation describes a 1-D dyadic toy model | **Claim retracted** (see Retired table); programme re-targeted to the dyadic shell model |
| D2 obstruction ledger | **MERELY LISTED** | A 1-D sequence model lacks the surface area to encounter Tao/CKN | Accepted; obstruction compliance re-scoped to the dyadic target (O1/O5 remain meaningful there) |

**The pivot (owner decision, Memo §3):** the programme's formal target is now **global
regularity bounds for the truncated viscous Katz–Pavlović dyadic shell model** — a respected,
active area of mathematical fluid mechanics where a machine-verified regularity (or blow-up)
result would be a first. The 3-D bridge (ℤ³ reindexing, OP-2/OP-6-D1) is explicit future work,
not an implicit claim.

> ## ⚠ E-3 FINDING 2026-08-14 — the programme's parameters sit in an already-solved regime
>
> Verified from the primary source (Cheskidov, arXiv:math/0601074, eq. (1.1) and abstract, both
> quoted verbatim in `docs/escalations/2026-08-14-E3-target-is-a-solved-case.md`):
> blow-up is proven for dissipation degree **α < 1/3**, global regularity for **α ≥ 1/2**.
>
> This programme's model has dissipation `ν k_n² = ν 2^{2n}`, i.e. **α = 1** — comfortably inside
> the proven-regular regime. **The dyadic uniformity question, for the parameters actually used,
> is settled in the affirmative by a published theorem.** Two numerical campaigns were confirming
> it.
>
> Consequences: (a) no numerical verdict here can be a discovery — at best instrument
> calibration; (b) **OP-2-lite as designed cannot produce a signal**, since the *unlocked* system
> is already regular and the lock has nothing to prevent; (c) a Lean regularity proof at `α = 1`
> remains valuable as a **formalisation first**, but would formalise *known* mathematics and must
> be described that way. The Tier A algebraic identities are unaffected — they are exact
> identities, independent of regime.
>
> The live band is `1/3 ≤ α < 1/2`, with `α = 1/3` matching 4-D NSE nonlinear estimates.
> Changing `α` is a statement-level decision (E-4) and is the owner's.

## Tier A — kernel-verified (zero sorry; no axiom outside {propext, Classical.choice, Quot.sound} — membership test, see SPEC §5.1 / LL-8)

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
| Pure algebra (doubling only): `Σ_{n<N}k_n²a_{n+1}² ≤ Ω_N` | `step1_flux_bound`, and the tighter `step1_flux_bound_half` | 2026-08-12 |
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

### `lean_src/MillenniumReduction.lean` — **DEMOTED TO TIER C (draft)**, audit verdict B1, 2026-08-13

**All rows in this subsection are TIER C as of 2026-08-13** (they remain kernel-compiled and
gated so they cannot rot, but per verdict B1 the `Prop → Prop` hypothesis parameters make the
headline theorem a verified tautology, not bona fide PDE mathematics). Repair path: Memo 1
Task 4 (real sequence-space topology) + B4 specialisation — PLAN.md §10. The B2 hoist is
already applied (`HasGlobalBoundedLimit` fixes one trajectory across all horizons).

(Original section follows; read every "Tier A" below as historical.)

| Claim | Formal name | Since |
|---|---|---|
| Untruncated (`N→∞`) solution family is inhabited (zero flow, given `hB`) | `zero_isFullSolution` | 2026-08-12 |
| Sobolev-level weight `k_n^{2s}` is nonnegative for any `k` (even exponent) | `sobolevWeight_nonneg` | 2026-08-12 |
| Zero flow is spatially smooth (every Sobolev class `H^s`) at every time | `zero_isSpatiallySmooth` | 2026-08-12 |
| **The reduction itself** (renamed per D2, 2026-08-13): Galerkin family + uniform bound + `AubinLionsStatement` + `ProdiSerrinStatement` ⇒ `GlobalRegularityStatement` | `dyadicShell_regularity_reduction` | 2026-08-13 |
| `GlobalRegularityStatement` is satisfiable, not vacuous (zero-flow witness) | `zero_global_regularity` | 2026-08-12 |

### α as a quantified parameter (E-3 response, 2026-08-14) — `DyadicShell_Statements.lean`

| Claim | Formal name | Since |
|---|---|---|
| Dissipation coefficient at degree `a`: `kₙ^{2a}`, positive for all `a` | `dissipationWeight`, `dissipationWeight_pos` | 2026-08-14 |
| **The conflation made explicit and proved**: at `a=1` the dissipation coefficient EQUALS the enstrophy weight | `dissipationWeight_one` | 2026-08-14 |
| Hypothesis U at dissipation degree `a`, with dissipation (`kₙ^{2a}`) and enstrophy (`kₙ²`) weights **separated** | `DyadicShellHypothesisU_alpha` (def) | 2026-08-14 |
| The α-parametrised statement specialises at `a=1` to the existing target — nothing orphaned | `dyadicShellHypothesisU_alpha_one` | 2026-08-14 |

**A latent conflation that generalising α exposed.** `HypothesisU` uses a single weight `w` in
*both* roles: the dissipation coefficient inside `IsGalerkinSolution` (`−ν·w n·u`) and the weight
defining the bounded quantity (`enstrophy N w`). At `α = 1` both are `kₙ²`, so the conflation was
invisible. They are different objects — enstrophy is *by definition* the `kₙ²`-weighted sum
whatever the dissipation is. The α-parametrised statement keeps them apart;
`dissipationWeight_one` is the proof that the old form is exactly the `α=1` special case.

### Task 4 repair applied 2026-08-13 (audit B1/B4; decisions D1–D3; `docs/designs/TASK4_ELL2_REPAIR.md`)

**Still Tier C** — the repair makes the undischarged debt *legible*, it does not pay it.

| Claim | Formal name | Since |
|---|---|---|
| ℓ² finite-enstrophy predicate + series form for untruncated states (D1, localised) | `HasFiniteEnstrophy`, `enstrophyTsum` | 2026-08-13 |
| **The bridge**: bounded finite partial sums (nonneg weight) ⇒ `Summable` ∧ `tsum ≤ C` — makes the ℓ² upgrade a *conservative extension* | `hasFiniteEnstrophy_of_bounded` | 2026-08-13 |
| **What compactness actually delivers**, four load-bearing clauses incl. modewise convergence along a **subsequence** (D3) | `IsGalerkinLimit` (def) | 2026-08-13 |
| `IsGalerkinLimit` is inhabited (zero family, identity subsequence) — the four-clause conclusion is not vacuously unsatisfiable | `zero_isGalerkinLimit` | 2026-08-13 |
| `shellB` vanishes at the zero state (re-declared copy; see sync note) | `shellB_zero` | 2026-08-13 |

**Specialised to `shellB`/`dyadicWeight` throughout, closing audit verdict B4.** Negative
controls run and confirmed to fail: dropping the weight-nonnegativity hypothesis breaks the
bridge; weakening clause 3 from `∀T ∃C` to `∀T ∀t ∃C` (destroying uniformity in `t` on a
horizon — the A1 failure mode one level down) breaks the inhabitation witness.

**Known cost, recorded:** `shellB`, `dyadicWavenumber`, `dyadicWeight` are **verbatim
re-declarations** of `DyadicShell_Statements.lean`'s canonical definitions, forced by Gate 2
compiling each file standalone. They must be kept in sync by hand. **Not kernel-checkable**;
likewise whether the four clauses of `IsGalerkinLimit` say the right thing is a
statement-adequacy question reserved to human audit (memo §5, NC1).

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
explicitly. **Q5** `HasGlobalBoundedLimit` didn't require `w ≥ 0` (unlike F2's own
`enstrophy_nonneg`), so "bounded partial sums" didn't cleanly mean "enstrophy controlled";
repaired by threading `hw : ∀ n, 0 ≤ w n` through. Four hand-derived negative controls
(NC1–NC3 re-verified against the revised structure, NC4 newly added — a statement-adequacy
risk, not a compile-time-checkable one) confirmed to behave as predicted. Both gates
independently re-run and PASS after the revision.

**Status: awaiting full human statement-adequacy audit** (PLAN.md's oversight split —
authorship by the top-tier agent, even through a self-review pass, never itself licenses the
claim; same DRAFT-pending-audit posture as F2's `DyadicShell_Statements.lean` before its
Q1/Q2 audit — Q3/Q4/Q5 fixed three found gaps, they do not certify no others remain).

### `lean_src/AbstractAlgebraicConservation.lean` — abstract algebraic conservation (scope-fixed per audit C1)

| Claim | Formal name | Since |
|---|---|---|
| Bilinear pairing is symmetric / additive / negation-compatible | `dot_comm`, `dot_add_left`, `dot_neg_left` | 2026-08-13 |
| **Termwise triad cancellation**: for `k_p+k_q+k_r=0` and `dot k_p u_p = 0`, the orderings `(p,q,r)` and `(p,r,q)` cancel exactly | `triad_pairing` | 2026-08-13 |
| The swap `(p,q) ↦ (p,−(p+q))` is an involution | `swap3_involutive` | 2026-08-13 |
| **Detailed energy conservation (summed)**: `Σ (k_q·u_p)(u_q·u_r) = 0` over any `swap3`-closed finite set | `triad_sum_zero` | 2026-08-13 |
| **Transversality** (the harness's Fact 1, unconditional): a sum of vectors each orthogonal to `k` is orthogonal to `k` | `transversality_of_sum` | 2026-08-13 |

7 theorems, all footprints within the permitted axiom set, independently recompiled.

### `lean_src/TriadTorus.lean` — the resonant-triad 2-section on a torus, solved exactly (2026-08-14)

The programme's first Tier A result about the genuine ℤ³-type resonance structure. `G` any
finite additive abelian group (intended instance `(ℤ_m)³`), `Λ = G \ {0}`, ordered triads
`a + b = c` in the `(a,c)` representation of `symbolic/triad_hypergraph.py`; the 2-section
weight counts (triad, slot-pair) **incidences**, which absorbs the `(u,u,2u)` degeneracy so the
formula is uniform with no genericity hypothesis. Derivation memo (written first, LL-5):
`docs/designs/TRIAD_TORUS_THEOREM.md`.

| Claim | Formal name | Since |
|---|---|---|
| Slot-pair counts: type {1,3} and {2,3} contribute exactly 2 each; type {1,2} contributes `2·[u+v≠0]` | `w13_eq`, `w23_eq`, `w12_eq` | 2026-08-14 |
| **Torus 2-section solved**: `A(u,v) = 6 − 2·[u+v=0]`, i.e. `A = 6(J−I) − 2P` | `A_eq` | 2026-08-14 |
| Degree: `Σ_{v≠u} A(u,v) = 6·|Λ| − 8` (no 2-torsion) | `row_sum` | 2026-08-14 |
| Spectral sum identities: zero-sum even vectors have eigenvalue −8, odd vectors −4 ⟹ normalised spectrum `{1, −4/(6n−8), −8/(6n−8)}`, torus gap → 1 | `eigen_even`, `eigen_odd` | 2026-08-14 |

7 theorems, all footprints within the permitted axiom set (verify.sh Gate 2 re-elaboration).
Negative controls NC1–NC3 (drop `u≠v`; drop no-2-torsion; perturb −8 to −6) each fail to
compile on scratch copies, run 2026-08-14. Non-vacuity witnesses at `(ℤ_3)³` inside the file,
including the antipodal case `A((1,0,0),(2,0,0)) = 4`.

**Consequence for the measured ball gap:** since the torus gap tends to 1, the stable ≈ 5/6
gap on the ball truncation (M=2..5) is a pure boundary invariant of the sphere cutoff — now an
explicitly separated, still-open conjecture (continuum kernel `2·1_B(x+y) + 4·1_B(x−y)`),
**not** part of this Tier A entry.
`transversality_of_sum` covers the harness's *other* certified fact; the two are genuinely
independent, as the harness's own negative controls show (dropping the Leray projector breaks
transversality but leaves energy conservation intact; breaking divergence-freeness does the
reverse). It is stated as a property of the projector's *defining* orthogonality (supplied as
hypothesis `hP`) rather than constructing `P(k) = I − (k⊗k)/|k|²`, which would need division,
a `|k| ≠ 0` side condition and a field — machinery this file deliberately avoids for the same
D1-scope reason as above. **Promotes
to Tier A the identity that `tests/tier_b_nse_triad_convolution.py` (OP-6/D3) verified only
computationally (`M=1,2,3`) and explicitly declined to claim as proven.**

## Tier C — OP-2′ attractivity experiment K3 (run 2026-08-15; verdict pending owner)

| Item | Result | Artifact |
|---|---|---|
| K3 σ measurement, M=3, planes z=0 and ⟨(1,0,0),(0,1,2)⟩ | Raw σ: −0.265/+1.230/+2.609 (z=0; ν=1/2, 1/10, 1/50) and −0.310/+0.586/+2.055 (tilted); ε-independent; Zmax/Z0 = 1.00 throughout; K2 positive control at literal 0.00e+00 on both planes, negative controls 0.739/0.886 | `exploration/sigma_planar_full.py` |
| Linear null model (closed form, same seed/window/estimator) | σ_lin = −0.305/−0.392/−0.067 (z=0), −0.317/−0.164/−0.018 (tilted): the ν=1/2 negative raw σ is the linear spectral artifact (⟨k²⟩_out 6.26 vs ⟨k²⟩_in 4.95); **excess σ−σ_lin positive everywhere** (+0.040 … +2.676), the tilted ν=1/2 excess +0.007 at noise level | `exploration/sigma_linear_baseline.py` |
| Grid adequacy stamps | Exact ν³M⁴ ≥ 1: adequate only at ν=1/2; ν=1/10, 1/50 rows labelled NO (sphere-radius adaptation of `tier_b_grid_adequacy`, recorded as an adaptation) | same file |

**Status: pre-registered K3 kill criterion (σ > 0 everywhere for generic data) is met on its
face after artifact correction; the verdict is the owner's to sign (SPEC §8), not this row's
to assert.** The near-discovery at ν=1/2 (raw σ < 0) was caught as a linear artifact by the
null model *before* interpretation — LL-14/LL-15 discipline working as designed.

**How it closed, recorded because the earlier attempt failed:** the Tier B harness's docstring
records that a direct *three-way* relabeling argument (cycling `p→q→r`) did not close. It does
not need to — the cancellation is **two-way and termwise**: pairing `(p,q,r)` with `(p,r,q)`
gives `[(k_q·u_p)+(k_r·u_p)](u_q·u_r) = (−k_p·u_p)(u_q·u_r) = 0` using only symmetry of the
pairing and divergence-freeness at `p`. Re-derived by hand, then confirmed on **6486 triples in
exact arithmetic before any Lean was written** (LL-5 practice), then proven.

**Scope (honesty clause) — this is deliberately abstract and does NOT close OP-6.** Stated over
an arbitrary commutative ring with an arbitrary additive index group and additive wavevector
map. It is **not** stated over `Λ ⊂ ℤ³` with complex velocities: that concrete apparatus is
exactly OP-6 decision **D1**, which is OPEN. **The bridge from this lemma to the concrete
Fourier–Galerkin setting is NOT built**, nothing here instantiates `B` in
`DyadicShell_Statements.lean`, and nothing here is a statement about Navier–Stokes solutions.
The Leray projector does not appear — the harness's own derivation shows it drops out of the
energy pairing identically, and independently confirms this (dropping `P(k)` breaks
transversality but leaves energy conservation intact). The 2-torsion hypothesis `h2` is
load-bearing, not a technicality: `swap3` has fixed points (`q=r`, forcing `p=−2q`) where the
pairing yields only `2f=0`. Three negative controls (drop `hdiv`; drop `hk`; drop `h2`) each
confirmed to fail with `sorryAx` or a type error.

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
| **Experiment-grid adequacy** (exact integers, no floats/logs): a cutoff is at/above the dissipation scale iff `2^(4N)·p³ ≥ q³` for `ν=p/q`. Negative control is the programme's OWN historical grid — **0 of 15 configurations had a biting cutoff**; positive control is a cutoff-biting grid | Gate 1b-adj | `tests/tier_b_grid_adequacy.py` |
| **Dissipation-regime adequacy** (exact rationals): classifies `α` into PROVEN_BLOWUP (`<1/3`) / OPEN (`[1/3,1/2)`) / PROVEN_REGULAR (`≥1/2`) per Cheskidov. Negative control is the programme's OWN `α=1`, correctly refused as a discovery regime (E-3); positive control `α=2/5` accepted. Boundary anchors at 1/4, 1/3, 2/5, 1/2, 1 | E-3 | `tests/tier_b_regime_adequacy.py` |
| **Fourier-Galerkin NSE nonlinearity, two structural identities** (transversality `k·N(û)_k=0`, unconditional; detailed energy conservation `Σ_k conj(û_k)·N(û)_k=0`, given divergence-free + conjugate-symmetric input), exact Gaussian-rational arithmetic, `M∈{1,2,3}` (`|Λ|`=26,124,342); two negative controls (drop Leray projection; break divergence-free on one mode) each confirmed to fail exactly one fact and leave the other intact, matching the hand derivation. **Caught and corrected a genuine formula erratum in the process** (the web-search-sourced formula in `docs/designs/B_INSTANTIATION_SCOPING.md` was identically zero; corrected same day) — recorded honestly in both the harness's own docstring and the design memo. Fact 2's general triad identity is verified computationally here, not yet proven symbolically. | OP-6/D3 | `tests/tier_b_nse_triad_convolution.py` |

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

**Synthesis across D4 + dual-precision + dt-refinement (2026-08-12) — the fullest picture this
program has assembled on the central "does `sup_t Ω_N(t)` grow with `N`?" question, still Tier
C throughout (floats; a specific discrete IMEX-Euler scheme, not the continuum dyadic model or
true NSE), presented for the human owner's verdict, not asserting one:**

- **D4** (`data/dyadic_omega_sup.csv`, explicit float RK4): 58% of configs infeasible
  (stiffness), but every completed `(ν, profile)` pair's `sup_Ω` at `N=8` vs `N=12` agrees to
  within ~0.1% (e.g. `ν=0.001,P1`: `70.8796` vs `70.8859`) — flat, not growing.
- **Dual-precision + dt-refinement** (`data/dyadic_imex_dual_precision.csv` +
  `data/dyadic_imex_dt_refinement.csv`, full `N∈{8,12,16,20,24}` grid, all 45 configs now
  resolved to `status=OK` at fine-enough `dt`): 44 of 45 configs are EXACTLY flat in `N`
  (bit-identical `sup_Ω` across every `N` tested, e.g. `ν=0.01,P2`: `467.4` at every `N`).
- **The one apparent exception, investigated and explained:** `ν=0.1, profile=P2` showed
  `sup_Ω` growing *linearly* in `N` (`4.5, 6.5, 8.5, 10.5, 12.5` at `N=8,12,16,20,24` — exactly
  `0.5·(N+1)`). Traced by hand (reproducible: `python3` snippet computing `omega_f` step-by-step
  for `N=24,ν=0.1,P2,dt=0.25`, printed at `t=0,0.25,0.5,…`): this is **not** dynamical growth.
  `0.5·(N+1)` is exactly profile P2's ANALYTIC INITIAL enstrophy (`a_n=2^{-n}` for `n=0..N`,
  `k_n=2^n` ⟹ `Σ k_n² a_n² = Σ 1 = N+1`) — P2 is defined to fill every retained mode, so a
  larger cutoff `N` starts with strictly more initial enstrophy BY CONSTRUCTION, independent of
  any dynamics. The trajectory itself confirms this: `Ω(t)` collapses from `12.5` at `t=0` to
  `1.79` by `t=0.25` and continues to decay (`t=2.5`: `0.27`; `t=4.75`: `0.035`) — the reported
  `sup_Ω=12.5` is simply the (never-exceeded) initial value, i.e. `ν=0.1` is large enough here
  that the trajectory is strictly dissipative from `t=0` on (consistent with
  `DyadicShells.lean`'s `energyRate_nonpos` in spirit). **The "growth" is an initial-data
  artifact of profile P2's own definition, not evidence against uniformity of the dynamics.**
- **Net:** once the P2 case is understood, EVERY tested configuration across both numerical
  campaigns is flat (`N`-independent) in `sup_Ω`, at fine-enough `dt`. This is the complete
  Tier C evidence base for the campaign DoD's D4–D5 line ("uniformity question has a
  human-issued verdict recorded in `LEDGER.md`, whatever the verdict is") — ready for that
  verdict whenever the human owner wants to render one; still not rendered here.

## Tier A — `lean_src/DyadicShell_Statements.lean` (pivoted target; renamed from `HypothesisU_Statements.lean` 2026-08-13)

**Post-audit status:** A1/A4 upheld; A2/A3 dissolved by the pivot (the index cutoff and the
weight `4ⁿ = k_n²` are the dyadic shell model's OWN objects, no longer proxies for ℤ³); A5
fixed by the concrete nonlinearity below. The file's headline statement is now
`DyadicShellHypothesisU` — uniform-in-cutoff enstrophy control of the truncated viscous
Katz–Pavlović model, with nothing abstract remaining in it.

### New rows (Memo 1 Task 2, 2026-08-13)

| Claim | Formal name | Since |
|---|---|---|
| The concrete Katz–Pavlović nonlinearity (`B` no longer abstract) | `shellB` | 2026-08-13 |
| `shellB` vanishes at the zero state (inhabitation applies to the concrete model) | `shellB_zero` | 2026-08-13 |
| Telescoping: `Σ_{n≤N} v_n·B_n(v) = −k_N v_N² v_{N+1}` | `sum_mul_shellB` | 2026-08-13 |
| **Exact energy conservation `Σ u_n B_n(u) = 0`** under truncation — the structural constraint whose absence audit verdict A5 called fatal | `shellB_energy_conservation` | 2026-08-13 |
| Every Galerkin solution of the concrete model conserves energy at every time | `galerkin_shellB_conservation` | 2026-08-13 |
| **The pivoted headline statement**: Hypothesis U for the concrete truncated viscous Katz–Pavlović model | `DyadicShellHypothesisU` (def) | 2026-08-13 |

(Original 2026-08-12 section follows.)

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
| **T1 / OP-2 — KILLED ON PRE-REGISTERED CRITERION, 2026-08-14** | The draft radial embedding fails `SPEC.md` §2.3's own kill criterion (*"constrained count grows at the same order → no depletion → kill"*), measured with the T0.1/T0.2 tooling: permitted-triad fraction **rises** with `M` (0.019 → 0.263 → **0.525** at M=4,6,8). Mechanism: at M=8, **99.0 %** of permitted triads have `a=b=c` — it is a **parity filter on the shell index**, not an arithmetic depletion. Same failure mode as LL-11. The draft's own honesty clause anticipated the cause (the radial reduction discards the angular structure). **Rejected on evidence, not abandoned.** | `docs/designs/TRACK_DEFINITIONS_DRAFT.md` (kill banner) |
| **Depletion screen with a null model** (exact integer counts) | Resonances are **trilinear** in the mode set, so random thinning to density `f` already leaves `~f³` of the triads (measured: `f=0.8→0.484` vs `f³=0.512`; `f=0.4→0.0608` vs `0.0640`). Hence "fewer triads" is **not** evidence of depletion. The meaningful observable is `D = triads(S) / (f³·triads(Λ))`. Controls: random subset `D=1.01`; sublattice `(2ℤ)³` `D=7.25` (enrichment — subgroups *favour* resonance). **Calibration finding:** `{k : \|k\|² odd}` has **exactly zero** triads at density ½ — sum-free by parity, since `\|k\|² ≡ x+y+z (mod 2)` and odd+odd≠odd; verified exhaustively at `M=8` (1048 modes, 0 triads). That is **amputation, not depletion**: no triads means no nonlinearity, hence trivial regularity proving nothing. **The useful band is `0 < D < 1`.** | `symbolic/depletion_screen.py` |
| **Resonant-triad hypergraph — unconstrained spectral baseline** (Tier B combinatorics; Tier C eigenvalues) | Vertices = modes, hyperedges = `k₁+k₂=k₃`; **definition-independent**, so buildable without OP-2 (same status PLAN §6 grants T0.1/T0.2). Normalised-Laplacian gap of the 2-section is **stable at ≈ 0.8334** across M=2,3,4 (0.834985, 0.833575, 0.833419), apparently approaching ≈ 5/6 — *suggestive on three points, not established*. Reading: the triad structure is a **strong expander**, so no depletion is available for free; any candidate lock must be shown to destroy this expansion, and now has a concrete number to beat. Controls: complete graph `K_n` gap `n/(n-1)` reproduced exactly; disconnected graph gives 0. | `symbolic/triad_hypergraph.py` |
| **OP-2…OP-5 draft definitions** (Sym²-spectrum embedding, enstrophy echo, entropy functional, percolation coupling) | Drafted 2026-08-12, **awaiting human audit** (PLAN.md §6 — audit is what unblocks, not authorship) | `docs/designs/TRACK_DEFINITIONS_DRAFT.md`. Surfaces a structural finding: the proposed T3 (`h=Ω, ū=0`) collapses into the direct production-identity attack rather than being independent; T1 and T4 share the OP-2 embedding and so are correlated, not independent, measurements. |
| **OP-6 scoping — instantiating `B` with the real NSE nonlinearity** | Scoped 2026-08-13, D3 done, D1/D2 still open (PLAN.md §6) | `docs/designs/B_INSTANTIATION_SCOPING.md`. No Fourier/triad convolution formula exists anywhere in this program's sanctioned content prior to this memo (confirmed by search: T0.1/T0.2 count triads with no amplitudes; OP-2's draft self-admits it discards angular structure; the dyadic `NL_n` is never asserted to derive from `(u·∇)u`). **Erratum caught and corrected same day** (see Tier B row below): the web-search-sourced formula was identically zero; the corrected form is now Tier B verified. D1 (full `ℤ³` reindexing vs. reduced proxy) and D2 (sequencing vs. OP-2) remain open, still the human owner's call. Neither this memo nor the Tier B harness touches or unblocks `DyadicShell_Statements.lean`'s abstract `B` parameter. |

## Retired / corrected claims

| v0.1 claim | Disposition |
|---|---|
| **"Hypothesis U [as formalised] is a restatement of the open core of the Millennium problem"** (SPEC §1.2, the report, the audit packet) | **KILLED by external audit 2026-08-13 (verdict D1), retraction accepted by the owner (`docs/Memo 1.md` §2)**: with a 1-D index cutoff, weight `4ⁿ`, and unconstrained `B`, the formalisation describes a dyadic shell hierarchy, not the unreduced 3-D problem. The programme is re-targeted to the dyadic shell model, where the same statements are exact rather than leaky. |
| "Reff theorems proven in Lean with zero custom axioms" | Was false when written (no such proofs existed); made true 2026-08-12. |
| `genesis_no_singularity` with axiom `alpha_prime` | Violated §7.1 and its own #print-axioms expectation; superseded by axiom-free `Reff_pos`. |
| Prior-tree `HypothesisU` (arbitrary smooth fields) | Provably false as formalized (scaling); statement to be rebuilt with the equation as constraint (Stage 2). |
| Prior-tree `global_well_posedness_regularized_shell` | Trivial witness (u ≡ 0); statement to be rebuilt quantifying over data (Stage 1). |
| `axiom aubin_lions_compactness` | Banned form; to re-enter as hypothesis parameter (Stage 2). |
| Proposal (2026-08-12) `Reff_ge_sqrt` "proven, no sorry" | Did **not** compile (4 Lean-idiom errors); footprint contained `sorryAx`. Statement is true and was already proven in the core by another route. Evidence: `docs/proposals/2026-08-12-proposal-kernel-log.txt`. |
| Proposal `genesis_no_singularity` with `opaque alpha_prime` + `axiom alpha_prime_pos` | Compiled, but footprint carried `alpha_prime_pos`; `opaque` improves on v0.1 yet still fails the gate. Superseded by the axiom-free parameterized version. |
