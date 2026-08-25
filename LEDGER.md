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
> ~~The live band is `1/3 ≤ α < 1/2`~~ — **CORRECTED 2026-08-15, escalation E-3b**
> (`docs/escalations/2026-08-15-E3b-band-is-narrower.md`): this statement was **wrong**, in two
> ways, both established from PDFs read in full.
>
> 1. **The upper half was closed in 2011.** Barbato–Morandin–Romito, *Nonlinearity* **24**
>    (2011) 3083–3097, Thm A: global regularity (with *uniqueness* and smoothness, from `ℓ²`
>    data) for `β ∈ (2, 5/2]`, i.e. **`α ∈ [2/5, 1/2)`**, for **positive** initial data. The
>    field's own survey (Cheskidov–Dai–Friedlander, arXiv:2209.10203) states verbatim that this
>    "settles that solutions to the dyadic model corresponding to the 3D NSE are globally
>    regular".
> 2. **Both bounding theorems assume positivity**, so there are *two* bands. Cheskidov's
>    blow-up theorem (Thm 5.3) needs `u_n(0) ≥ 0` **and large data**; BMR needs `x_n ≥ 0`;
>    Cheskidov's regularity theorem (Thm 4.4, `α ≥ 1/2`) needs neither.
>
> | data class | blow-up | regularity | genuinely OPEN |
> |---|---|---|---|
> | positive | `α < 1/3`, large data | **`α ≥ 2/5`** | **`[1/3, 2/5)`** |
> | sign-changing | *nowhere* | `α ≥ 1/2` | **`(0, 1/2)`** |
>
> With `d = 5 − 2/α`, the residual positive-data band is `d ∈ [−1, 0)` — **outside** the
> physically relevant intermittency range `d ∈ [0,3]`. **The room is in sign-changing data**,
> where nothing is proven below `1/2` in either direction.
>
> `tests/tier_b_regime_adequacy.py` had encoded the wrong band — and its own *positive control*
> asserted `α = 2/5` is OPEN, which is exactly BMR's endpoint. Corrected: `classify` now takes
> the data class, and a **regression control** asserts `classify(2/5, "positive") ==
> PROVEN_REGULAR` so the error cannot return. Lesson (see `LL.md`): controls test code against
> the thresholds you believe; only re-reading the primary source tests the belief — and LL-6
> had been applied to this very paper, but only to its abstract, which does not carry the range.
>
> Changing `α` remains a statement-level decision (E-4) and is the owner's.

## Tier A — kernel-verified (zero sorry; no axiom outside {propext, Classical.choice, Quot.sound} — membership test, see SPEC §5.1 / LL-8)

| Claim | Formal name | Artifact | Since |
|---|---|---|---|
| Effective radius is positive (α, R > 0) | `Reff_pos` | `lean_src/LocalDualScale.lean` | 2026-08-12 |
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

## Tier L — Literature (adopted 2026-08-25; see `SPEC.md` §2)

Published mathematics this programme relies on. **A Tier L row never discharges a Lean
obligation** — it motivates, scopes, or refutes. Each is cited to a *theorem statement* with the
hypotheses that scope it, because a threshold quoted without its hypotheses is a different claim
(LL-16). Declared in code through `cite_threshold` (`tests/controls.py`), which refuses a
constant lacking either.

| # | Statement | Source (theorem, never an abstract) | Hypotheses that scope it |
|---|---|---|---|
| **L-1** | Global regularity of the dyadic model for `α ≥ 1/2` | Cheskidov, arXiv:math/0601074, **Thm 4.4** | `u₀ ∈ V = H^α`; **any sign**; asserts **existence** of a strong global solution — **not uniqueness** |
| **L-2** | Local regularity for `α > 1/3` | ibid., **Thm 4.3** | `u₀ ∈ V`; any sign; finite time interval only |
| **L-3** | Finite-time blow-up for `α < 1/3` | ibid., **Thm 5.3** | **`u_n(0) ≥ 0`** *and* **large data** `‖u(0)‖_γ > M(γ)`; it is *not* "every solution blows up" |
| **L-4** | Global regularity, with **uniqueness and smoothness**, for `β ∈ (2, 5/2]` i.e. `α ∈ [2/5, 1/2)` | Barbato–Morandin–Romito, *Nonlinearity* **24** (2011) 3083–3097, **Thm A** | **`x_n ≥ 0`** in `ℓ²`; method is an invariant region on `(X_n, X_{n+1})`, **not** an energy estimate |
| **L-5** | The equivalence `∫‖∇v‖⁴ < ∞ ⟺ global Serrin class`, at zero force | Ponce–Racke–Sideris–Titi, *Comm. Math. Phys.* **159** (1994), **Thm 2** | `Ω = ℝ³` or a Poincaré domain; zero external force |
| **L-6** | Global stability of large solutions: an `H¹` neighbourhood of a strong reference solution is globally regular | ibid., **Thm 1** | smallness is **Gronwall-exponential** (eq. 2.17), constants never tracked in `ν` — **not quantitatively usable**; the 2-D application (Thm 4) is **ℝ² two-component**, unforced, with decay `v₀ ∈ Lᵖ`, `p < 2` — **not 2D3C and not the torus**; **no periodic `T³` case is treated** |
| **L-7** | 2-D global regularity | Ladyzhenskaya, *The Mathematical Theory of Viscous Incompressible Flow* (title **singular**), 2nd ed. 1969, via Fefferman's Clay problem description | 2-D; PRST record that global strong existence "was first established by **Leray**" |
| **L-8** | A 2D3C field splits the 3-D equations into 2-D NSE plus a passively advected scalar | Biferale–Buzzicotti–Linkmann, arXiv:1706.02371 | continuum; the **lattice/Galerkin** form is *not* found published and is claimed here only as our own exact computation |

**Migration note.** These rows previously sat unlettered or implicitly under this repository's
`B`. Nothing about their truth changed; only the letter carrying them. Our `B` usage was already
the exact-arithmetic one, so no row was mis-tiered — the risk `MX-C-0001` names was inbound, not
outbound.

> ## ⚖ OWNER ARBITRATION — 2026-08-25 (Xavier Callens, PLAN §8)
>
> Issued in response to `docs/briefs/2026-08-25-cross-stream-alignment.md` and
> `docs/designs/DOOR2_SIGN_FRAGILITY.md` §6.
>
> 1. **Effort split 40 / 40 / 20 — GO.** 40 % Door #2 (sign fragility), 40 % the Ball Spectral
>    Problem paper (*explicitly noted as insulated from Hypothesis U's fate*), 20 % OP-6b.
> 2. **Door #2 theory memo and its pre-registration — GO.** The classification
>    (sign-free / sign-repairable / sign-critical) is mandatory, an explicit breaking
>    configuration is required for every sign-critical step, and the three hard requirements
>    (hypothesis guard, budget-vs-physics stop reasons, null model first) are **obligatory for
>    the experiment to be valid at all**.
> 3. **EMBARGO — cross-stream circulation of Door #2 fragility signals before audit: STRICT
>    NO-GO.** Until a fragility result is sealed by a Lean theorem (Tier A) **or** a formally
>    validated pre-registered run (Tier B), it may not be shared with any other stream — not as
>    a result, not as an intuition. Rationale accepted from Stream 0: the narrative surface is
>    the programme's highest-consequence failure mode, and a claim that reaches a video has left
>    the system.
> 4. **Corrective memo to Stream 6 — transmit immediately** (unblock their Lean proof; correct
>    the triadic-depletion reading; close the two perceived gaps).

### `lean_src/FourierStateZ3.lean` — OP-6a, the 3-D Fourier kinematic state space (**DRAFT**, 2026-08-25)

**Provenance: externally submitted.** Verbatim submission archived at
`docs/proposals/2026-08-25-FourierStateZ3-v2-proposed.lean.txt`. **It did not compile as
submitted — 15 errors.** Repaired in-repo (see the file header for the full arbitration record);
the structural fix retired the whole GATE-RISK register rather than patching it, by replacing
every `fin_cases` + `reduceIte` block with indicator sums (`Finset.sum_ite_eq`). This is LL-2
working exactly as intended: the submission's own self-report claimed "zero `sorry` by
construction", which was true and irrelevant — it did not compile.

**Status: DRAFT pending human statement-adequacy audit** (same posture as
`DyadicShell_Statements.lean` before its Q1/Q2 audit). Kinematics only: **no** nonlinearity `B`
(that is OP-6b), **no** Hypothesis U.

> **Guardrail, carried from the file header.** `sublattice_invariance` is **geometry, not a
> regularity mechanism**. The owner verdict of 2026-08-15 killed planar confinement as a
> mechanism: the 2D3C manifold is exactly invariant *and measurably repulsive*. Nothing in this
> file may be cited as evidence for confinement-based regularity.

| Claim | Formal name | Since |
|---|---|---|
| `|k|² = 0 ↔ k = 0` — the load-bearing lemma that collapses every degenerate branch | `k_sq_eq_zero_iff` | 2026-08-25 |
| Constrained state space (divergence-free, conjugate-symmetric, zero mean) with a **nontrivial** witness (mode pair `{k₀,−k₀}`), not merely the zero state | `pairWitness_nontrivial` | 2026-08-25 |
| Leray projector: reality and symmetry | `leray_conj`, `leray_symm` | 2026-08-25 |
| Column orthogonality `Σᵢ kᵢ P(k)ᵢⱼ = 0` | `leray_col_orthogonal` | 2026-08-25 |
| **DoD-1** projected field is transverse, for *every* `k` including the zero mode | `applyLeray_div_free` | 2026-08-25 |
| **DoD-2** identity on already-transverse fields | `applyLeray_eq_self` | 2026-08-25 |
| **DoD-3** idempotence, as a one-line corollary of DoD-1 + DoD-2 (operator level, deviation D2) | `applyLeray_idem` | 2026-08-25 |
| Sublattice invariance for an **arbitrary** triadic bilinear map; Leray never moves support | `sublattice_invariance`, `leray_support` | 2026-08-25 |

10 theorems, footprints within the permitted set. Negative controls run on scratch copies before
merge, all fail as required: drop `hv` from `applyLeray_eq_self` (2 errors); drop `hv` from
`sublattice_invariance` (2); invert `k_sq_eq_zero_iff` (3).

**Audit flags raised by the repairer, unresolved (they are the audit's input, not its output):**
- **F1 — possible vacuity.** `sublattice_invariance` is conditional on `htriad`, which the zero
  map satisfies trivially. Its content rests entirely on OP-6b producing a `B` that satisfies
  `htriad` *and* is not identically zero. Until then the theorem is true and possibly empty —
  the LL-11 failure mode exactly. **A witness `B` must accompany the OP-6b merge.**
- **F2 — unexercised infrastructure.** `planeSubgroup` is defined but used by no theorem and has
  no witness that it is proper (that some `k` lies outside it).
- **F3 — checked, consistent.** `GalerkinState.cutoff` keeps `|k|² ≤ M²`, matching
  `symbolic/triad_hypergraph.py`'s `0 < n2 <= M*M`.

**~~Unverified claim~~ — CORRECTION 2026-08-25, my flag was wrong.** I first recorded the
submission's `LocalDualScale` rename directive as an unsourced claim, having searched
`SPEC.md`, `PLAN.md`, `LEDGER.md` and `docs/Memo 1.md`. **That search scope was too narrow: the
claim is cross-stream, and both halves check out.** `~/xdev/SocrateAI-Mathesis` (Stream 0, the
shared verification kernel) contains `lean/Mathesis/Scale/Reff.lean`, whose header states it is
the single source of truth for `Reff`, "consolidated from
`SocrateAI-Scientific-MechanicaFluidorum/lean_src/LocalDualScale.lean`, renamed per the
standing decision that no structure in this library carries a person's name (§9, L4.5)". The
decision is recorded in `SPEC-STREAM0` §9. **The migration is a live owner-decision item, not a
fabrication.** See `docs/briefs/2026-08-25-cross-stream-alignment.md` §2.

*Lesson (candidate LL): a claim about a cross-repository target must be verified across the
repositories it names. Applying LL-6 within one repo and concluding "unsourced" is the same
class of error as verifying a threshold against an abstract (LL-16) — right discipline, wrong
scope.*

### `lean_src/DyadicRiccati.lean` — why the dyadic threshold is exactly `α = 1/2` (Tier A, 2026-08-15)

**SCOPE, normative:** this is **not** a formalisation of Cheskidov's Theorem 4.4. It formalises
the *reason its threshold is 1/2*, as a self-contained statement about exponents and
integrability. It contains **no** bilinear estimate (an input, quoted from the source), **no**
local existence, **no** Galerkin approximation and **no** limit passage — which is where the
real cost of Thm 4.4 sits. Citing this file as "Thm 4.4 formalised" would be a D1-class
overstatement of the kind the 2026-08-13 audit killed this programme's headline for.

| Claim | Formal name | Since |
|---|---|---|
| Homogeneity `pExp + qExp = 3`; `2 − pExp = rhoExp`; `qExp = rhoExp + 1` (the collapse) | `pExp_add_qExp`, `two_sub_pExp`, `qExp_eq_rhoExp_add_one` | 2026-08-15 |
| **Young absorption possible ⟺ `α > 1/3`** — the content of *local* regularity, and NOT the source of the 1/2 | `absorbable_iff` | 2026-08-15 |
| Post-Young exponent `rExp α = (8α−2)/(3α−1)`, the source's displayed form | `rExp_eq`, `rhoExp_eq_div`, `rhoExp_ne_zero` | 2026-08-15 |
| `sExp − 1 = 1/rhoExp`, hence `rhoExp = 1/(sExp−1)` — the identity behind the blow-up rate | `sExp_sub_one_eq_inv_rhoExp`, `rhoExp_eq_inv_sExp_sub_one` | 2026-08-15 |
| The single use of `α ≥ 1/2`: `1 ≤ rhoExp α ⟺ 1/2 ≤ α`; and `0 < rhoExp α` for `α > 1/3` | `rhoExp_one_le_iff`, `rhoExp_pos` | 2026-08-15 |
| Integrability half, **genuine measure theory** (Mathlib `integrableOn_Ioo_rpow_iff`): `x^(−ρ)` integrable on `Ioo 0 T` ⟺ `ρ < 1` | `rate_integrableOn_iff` | 2026-08-15 |
| **THE THEOREM — the regularity threshold IS an integrability threshold**: the Riccati blow-up rate `(t*−t)^{−ρ(α)}` fails to be integrable ⟺ `α ≥ 1/2` | `blowupRate_not_integrable_iff` | 2026-08-15 |
| **The barrier below 1/2, formalised**: the a priori exponent needed, `2/ρ(α)`, exceeds the `θ = 2` the energy inequality supplies ⟺ `α < 1/2` | `thetaStar_two_lt_iff` | 2026-08-15 |

13 theorems, all footprints within the permitted axiom set (Gate 2 re-elaboration). Negative
controls run on scratch perturbed copies before commit, all fail as required: NC1 perturbed
rate `3 − 2/a` (9 errors), NC2 dropped `1/3 < a` from positivity (3 errors), NC3 weakened the
main theorem's `1/2 ≤ a` to `1/3 < a` (1 error). Non-vacuity witnesses in-file: `ρ(1/2) = 1`
(borderline), `ρ(2/5) = 1/2` (rate integrable, argument yields nothing), `rExp(2/5) = 6` and
`rExp(1/2) = 4` reproducing the source's displayed `‖u‖⁶` and `‖u‖⁴`.

**Why it matters for the real target.** The obstruction below `1/2` is now a Lean lemma about
an integrability threshold rather than a folk remark, with exactly two doors enumerated: raise
`θ`, or leave the Riccati route. Any `α < 1/2` proposal must name its door and its gain — the
pre-registered screen the four dead Sym² translations lacked.

## Tier B — door #1 of the α<1/2 barrier: CLOSED for banded quartic invariants (2026-08-25)

Memo (hand-derived first, LL-5): `docs/designs/QUARTIC_INVARIANT_SEARCH.md`.
Harness: `tests/tier_b_quartic_invariants.py` (Gate 1; exact `Fraction` linear algebra).

**Why quartic.** `DyadicRiccati.thetaStar_two_lt_iff` (Tier A) needs `‖u‖^θ ∈ L¹_loc` with
`θ ≥ 4` at α=2/5, while the energy inequality supplies `θ = 2`. `‖u‖² = H_α` is *quadratic*;
`‖u‖⁴ = H_α²` is *quartic*. Energy methods yield L¹ control of quadratics — that is what they
are. So door #1 is the algebraic question: is there a quartic conserved quantity at all?

| Claim | Result | Status |
|---|---|---|
| **Identity (Q1), derived**: `d/dt H_γ = −2ν H_{γ+α} + 2(λ^{2γ}−1)·Σ λ^{(2γ+1)n+1} u_n² u_{n+1}` | prefactor vanishes **only** at γ=0 ⟹ **energy is the unique conserved weighted quadratic**; `θ = 2` is the entire quadratic supply, not an artifact of technique. Generalises the repo's Tier A `shellB_energy_conservation` (its γ=0 case). At γ<0 with **positive** data the prefactor is negative and Σ ≥ 0, giving a monotone family — *precisely where positivity does its work in the literature, and precisely what is unavailable for sign-changing data* | **Tier B** |
| Quartic search, diagonal `Σc_n u_n⁴` and neighbour `Σc_n u_n²u_{n+1}²`, N=5,7,9 | **nullspace dim 0** | Tier B |
| Quartic search, banded general (all 4-index monomials of index spread < w), N=5,6,7 at w=3 and N=5,6 at w=4 (up to 75 monomials) | **nullspace dim 0** | Tier B |

**Pre-registered kill criterion met (fixed before any number was seen): DOOR #1 IS CLOSED for
banded polynomial quartic conserved quantities** — the natural home of an energy-method
improvement. Not even `E²` survives, since it is not banded (it couples index 1 to index N).

**Scope of the closure, which must travel with it:** it does **not** close quartics that are
monotone without a polynomial certificate, non-polynomial quantities, quantities conserved only
on invariant subsets, or **door #2** (leaving the Riccati route). A closed door is not a closed
problem — the distinction the four dead Sym² mechanisms failed to observe.

**Control note (LL-12 discipline, recorded because it was informative rather than merely
corrective):** the originally-designed negative control *failed* — perturbing the in-flux
exponent `λ^n → λ^{n+1}` does **not** destroy conservation, it only moves the conserved weights
from `c_n = 1` to `c_n = λ^{−n}`. The telescoping is robust to the exponent and sensitive to the
*index structure*. That perturbation is now kept as a **second positive control** (the search
must find the shifted weights, testing that it tracks weights rather than pattern-matching the
constant vector), and the real negative control breaks the index structure instead
(`u_n u_{n+2}`), returning dim 0 as required.

## Tier C — θ probe: screen for room below α=1/2 (2026-08-15; NO ADMISSIBLE READING at large A)

`exploration/theta_probe.py`. Observable: `I_θ(T) = ∫₀^T ‖u‖^θ dt` versus shell truncation `N`
(a finite truncation cannot blow up, so growth-without-saturation is the only signature).

| Regime | Result | Admissible? |
|---|---|---|
| **Positive control** α=1 (regularity is a theorem) | saturates: ratios 1.001 / 1.000 / 1.000 | ✅ instrument sound here |
| **Negative control** α=1/4, large positive data (blow-up is a theorem) | diverges over the common window (θ=4: 4.54, 5.95, 6.95), final times collapse 2 → 0.0176 under the **magnitude** guard | ✅ can detect divergence |
| α=2/5, both data classes, **A=2** | both saturate (θ=4 ratio → 1.006) | ⚠️ small-data regime — regularity is trivial there, so this carries **no information** |
| α=2/5, both data classes, **A=8, 32** | apparent blow-up signature in **both** columns | ❌ **INADMISSIBLE — artifact** |

**The failed control, and what it caught.** BMR 2011 proves **positive** data at α=2/5 globally
regular at *every* amplitude, so that column must saturate however large `A`. It did not — and
since the positive case is a theorem, the signature had to be an artifact. It was: every early
stop at A≥8 was the integrator's **step-count cap**, not its magnitude guard. Shrinking final
times meant the computation ran out of budget. Verified directly: `A=8, N=17` returns
`CAP(compute budget)` in both sign classes. The harness now separates the two stop reasons and
refuses to let a compute-limited block be read.

**Net scientific state: no numerical evidence in either direction below α=1/2.** The question
stands exactly where `DyadicRiccati.lean`'s Tier A barrier leaves it. Answering it needs an
integrator that resolves the cascade at large amplitude (implicit/exponential, far larger step
budget) or an observable that does not require following the trajectory that far.

**Methodological note (LL-17, and the campaign's recurring finding).** This is the third
occasion in this campaign where a pre-registered control turned a publishable-looking number
into a caught artifact — after the σ null-model catch (OP-2′) and the mis-stated regime band
(E-3b/LL-16). In this domain the artifact rate for uncontrolled measurements appears close to
one.

## Tier B — the Riccati exponent chain and the α<1/2 barrier, quantified (2026-08-15)

Derivation memo (hand-derived first, LL-5): `docs/designs/ALPHA_HALF_FORMALISATION.md`.
Harness: `tests/tier_b_riccati_exponents.py` (Gate 1; exact `Fraction`s, negative control on a
perturbed rate exponent demonstrated to fire).

| Claim | Status | Evidence |
|---|---|---|
| The derived exponent chain **reproduces Cheskidov's own displayed formulas**: `r(α) = (8α−2)/(3α−1)`, `r(1/2)=4`, `r(2/5)=6`, `p(1/3)=2`, `p(2/5)=q(2/5)=3/2` | **Tier B** (exact rationals against four independent source displays) | harness anchors |
| Young absorption possible **iff `α > 1/3`** (the content of Cheskidov's *local* Thm 4.3 — and *not* where the 1/2 comes from) | Tier B | ibid. |
| Riccati blow-up rate `y ≥ c(t*−t)^{−ρ}` with **`ρ(α) = 3 − 1/α`** (derived; reproduces the paper's `c/(t*−t)` at `α=1/2`) | Tier B (algebra) | ibid. |
| **The threshold, explained**: the energy inequality supplies `‖u‖² ∈ L¹_loc`, so blow-up is refuted iff the rate is non-integrable, iff `ρ ≥ 1`, **iff `α ≥ 1/2`** — the constant is an integrability threshold, not a technical artifact | **Tier B** | exact characterisation, flips precisely at 1/2 |
| **The barrier below 1/2, quantified**: refuting blow-up needs `‖u‖^θ ∈ L¹_loc` with `θ ≥ θ*(α) = 2/(3−1/α)`; energy supplies exactly `θ = 2`, and `θ*(α) > 2 ⟺ α < 1/2`. At `α=2/5` one needs `θ=4`; at `α=7/20`, `θ=14` | **Tier B** | ibid. |

**Consequence for the programme.** The obstruction is a single scalar deficit with exactly two
doors: raise `θ`, or avoid the Riccati route entirely. Any future `α < 1/2` proposal must name
which door it takes and by how much (LL-15 pre-registration). Lean target and its honesty
clause — Steps 1–4 deliver the *continuation* half only, **not** Galerkin existence — are
specified in the memo §4; **not started, awaiting owner go.**

## Tier B — the ball 2-section closed form and the linear eigenfunction (2026-08-15)

Derivation memo (hand-derived first, LL-5/LL-7): `docs/designs/BALL_SPECTRAL_PROBLEM.md`.
Harness: `tests/tier_b_ball_2section.py` (Gate 1; exact integers/Fractions, three negative
controls all demonstrated to fire: swapped coefficients 9714 mismatches, non-linear odd
`u₁³` 94, even `u₁²` 122).

| Claim | Status | Evidence |
|---|---|---|
| **Exact ball weight**: for distinct `u,v ∈ Λ_M`, `A_M(u,v) = 2·[u+v ∈ Λ_M] + 4·[u−v ∈ Λ_M]` — the boundary analogue of `TriadTorus.A_eq`, which it specialises to when every nonzero sum stays in the index set | **Tier B** (exact, vs an independently built 2-section that does not know the formula) | M=2,3,4: 81 034 ordered pairs, 0 mismatches |
| **Continuum kernel is derived, not conjectured**: rescaling `x=u/M` turns the two conditions into `x±y ∈ B`, giving `K(x,y) = 2·1_B(x+y) + 4·1_B(x−y)` | Tier B consequence of the above | same |
| **Sector splitting**: `A_M` commutes with `u ↦ −u`; even sector acts as `6C`, odd as `2C` (`C` = kernel `[u−v ∈ Λ_M]`), modulo an `O(n)` diagonal defect that vanishes in the limit and explains the approach to 5/6 from above | Tier B (algebraic) / Tier C (the eigenvalue measurement) | `exploration/ball_sector_split.py` |
| **The odd sector carries μ₂** — even#2 stays clear below and is non-monotone; odd#1 rises monotonically to 1/6 (0.166425, 0.166581, 0.166608, 0.166641 at M=3..6). Positive control: even#1 = 1.000000 exactly | Tier C (floats) | ibid. |
| **The linear eigenfunction (exact, every M)**: for `h(u)=⟨u,e⟩`, `(Ch)(u) = ½·V(u)·h(u)` pointwise, by the involution `v ↦ u−v` on `W(u)` | **Tier B** (exact rationals, pointwise at every mode) | M=3,4,5, two independent functionals, 0 mismatches |
| **⟹ half the 5/6 conjecture is proved**: the odd Rayleigh quotient attains exactly ½, so `μ₂ ≥ 1/6` and the continuum gap is **≤ 5/6**, with an explicit witness | **Tier B** | measured `R[h] = 0.500000` at M=4,5,6 vs 0.454 (`u₁/|u|`) and 0.379 (`sign u₁`) — the value is specific to linearity |

**What remains open** (the entire residue of "5/6"): that `½` is the *largest* odd generalised
eigenvalue, i.e. `ν₁^odd = 1/12`, `μ₂ = 1/6`, gap → exactly 5/6. Seven-point Tier C support
(deviations 1.7e-3 → 1.5e-5 over M=2..7, strictly monotone). Attack plan in the memo §5
(spherical-harmonic block-diagonalisation, then exact rational Rayleigh upper bounds per
block); **not started — awaiting owner go.**

## Tier C — OP-2′ attractivity experiment K3 (run 2026-08-15; verdict pending owner)

| Item | Result | Artifact |
|---|---|---|
| K3 σ measurement, M=3, planes z=0 and ⟨(1,0,0),(0,1,2)⟩ | Raw σ: −0.265/+1.230/+2.609 (z=0; ν=1/2, 1/10, 1/50) and −0.310/+0.586/+2.055 (tilted); ε-independent; Zmax/Z0 = 1.00 throughout; K2 positive control at literal 0.00e+00 on both planes, negative controls 0.739/0.886 | `exploration/sigma_planar_full.py` |
| Linear null model (closed form, same seed/window/estimator) | σ_lin = −0.305/−0.392/−0.067 (z=0), −0.317/−0.164/−0.018 (tilted): the ν=1/2 negative raw σ is the linear spectral artifact (⟨k²⟩_out 6.26 vs ⟨k²⟩_in 4.95); **excess σ−σ_lin positive everywhere** (+0.040 … +2.676), the tilted ν=1/2 excess +0.007 at noise level | `exploration/sigma_linear_baseline.py` |
| Grid adequacy stamps | Exact ν³M⁴ ≥ 1: adequate only at ν=1/2; ν=1/10, 1/50 rows labelled NO (sphere-radius adaptation of `tier_b_grid_adequacy`, recorded as an adaptation) | same file |

> ### ✅ VERDICT K3 — OWNER-ISSUED, 2026-08-15 (Xavier Callens; PLAN §8)
>
> **OP-2′ is KILLED as a route to global regularity for _generic_ data.** The pre-registered
> criterion (`σ > 0` everywhere ⇒ the planar-locked manifold is repulsive, so generic
> trajectories flee it) is met at all six measurement points after artifact correction, on
> both a coordinate and a tilted plane, ε-independently. The mechanism is dead **with a
> number**, which is the outcome the charter counts as a completed scientific result.
>
> **What this verdict does NOT kill**, and may not be read as killing:
> - the *geometric* half — Sym² closure ⟹ exact planar (2D3C) confinement, K1-verified in
>   exact arithmetic including tilted planes, and apparently unpublished in its lattice form;
> - `TriadTorus.lean` and the 5/6 ball conjecture, which are independent results that merely
>   arose during the screening;
> - the possibility that some *admissible modification* makes the manifold attractive — not
>   tested here, and now a lower priority given the measured repulsion strengthens as ν falls.
>
> The near-discovery at ν=1/2 (raw σ < 0) was caught as a linear spectral artifact by the
> closed-form null model *before* interpretation — LL-14/LL-15 discipline working as designed,
> and the reason this verdict is trustworthy rather than merely convenient.

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
| **Dissipation-regime adequacy** (exact rationals), **corrected 2026-08-15 per E-3b**: `classify(α, data)` over two data classes — positive (`blow-up <1/3` large data / OPEN `[1/3,2/5)` / PROVEN_REGULAR `≥2/5`, BMR) and sign-changing (OPEN below `1/2` / PROVEN_REGULAR `≥1/2`, Cheskidov). Negative control is the programme's OWN `α=1`, refused in both classes; positive control `α=7/20`; **regression control `classify(2/5,'positive') = PROVEN_REGULAR`** — the anchor the previous version got wrong. Anchors at 1/4, 1/3, 7/20, 2/5, 1/2, 1 in both classes | E-3 | `tests/tier_b_regime_adequacy.py` |
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
| **Resonant-triad hypergraph — unconstrained spectral baseline** (Tier B combinatorics; Tier C eigenvalues) | Vertices = modes, hyperedges = `k₁+k₂=k₃`; **definition-independent**, so buildable without OP-2 (same status PLAN §6 grants T0.1/T0.2). Normalised-Laplacian gap of the 2-section approaches **5/6** monotonically across M=2..7 (0.834985, 0.833575, 0.833419, 0.833392, 0.833359, 0.833348; deviations 1.7e-3 → 1.5e-5, strictly decreasing) — *seven-point Tier C evidence for the ball-boundary conjecture, not established*; the torus half is now Tier A (`TriadTorus.lean`: gap → 1), so the ball value is a pure boundary invariant. M=6,7 runner: `symbolic/ball_gap_large_M.py`. Reading: the triad structure is a **strong expander**, so no depletion is available for free; any candidate lock must be shown to destroy this expansion, and now has a concrete number to beat. Controls: complete graph `K_n` gap `n/(n-1)` reproduced exactly; disconnected graph gives 0. | `symbolic/triad_hypergraph.py` |
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
