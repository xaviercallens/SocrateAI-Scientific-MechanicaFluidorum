# External Audit Packet — MechanicaFluidorum / Hypothesis U

> **AUDIT OUTCOME (2026-08-13) — this packet is now a historical record.** The audit returned;
> verdicts (including D1: KILLED on the central framing) and their dispositions are recorded in
> `LEDGER.md` ("External audit 2026-08-13"), the owner's acceptance in `docs/Memo 1.md`, and
> the executed pivot in `PLAN.md` §10. Do not audit against this packet's commit again —
> the programme's formal target has changed (dyadic shell model).

**Prepared:** 2026-08-13. **Audit target:** the commit that introduces this file
(`git log --oneline -- docs/AUDIT_PACKET.md` shows it) — check out exactly that commit; later
commits are outside this packet's scope.
**Prepared by:** the executing agent, for the human owner to forward. **Not itself audited.**
**Governing rule this packet serves:** `SPEC.md` §8 — *"Public claim of any kind: kernel-verified
proof + independent external expert audit. Until then, nothing leaves the repo."*

---

## 0. What is, and is not, being asked of you

**You are NOT being asked to check whether the proofs are correct.** The Lean 4 kernel does
that, and its verdict is mechanically reproducible in §2 below. Re-deriving those proofs by hand
would be wasted effort.

**You ARE being asked to judge statement adequacy** — whether the formal statements *mean* what
the informal mathematics claims they mean. This is the half of the oversight split
(`SPEC.md` §0) that machine verification structurally cannot perform:

> *The machine verifier checks the proofs; the human mathematician audits the questions.*

Concretely, the request is: **read §4's numbered questions and answer them.** Everything else
in this document exists to let you answer them without reading the repository.

**A "no" answer is a success, not a failure.** This programme's Definition of Done explicitly
does not include proving Hypothesis U; a negative verdict or a killed track counts as a
completed scientific outcome. Please do not soften a finding to be constructive.

---

## 1. What is claimed, in one page

### 1.1 The object

For `α' > 0`, let `J_{√α'}` project onto Fourier modes `|k| ≤ 1/√α'` on `𝕋³`, and let
`u^(α')` solve the truncated system

```
∂ₜu + ((J_{√α'} u)·∇)u = −∇p + νΔu,   ∇·u = 0,   u(0) = J_{√α'}u₀
```

which is globally smooth for each fixed `α' > 0`. **Hypothesis U** asserts

```
sup_{α'>0} sup_{0≤t≤T} ‖∇u^(α')(t)‖_{L²(𝕋³)} < ∞.
```

### 1.2 The honest framing (please hold the programme to this)

The truncated system **is** the classical Leray / Fourier–Galerkin mollification. That
mollified systems are smooth, and that a uniform-in-cutoff enstrophy bound implies regularity
of the limit, is standard. **Hypothesis U is a restatement of the open core of the Millennium
problem, not a reduction of its difficulty.** An earlier version of this programme's own
specification overstated this; the correction is recorded in `docs/REVIEW-2026-08-12.md` (M1).

If any artifact in this packet reads to you as claiming more than a restatement, that is a
finding — please report it.

### 1.3 What is actually proven (Tier A, kernel-checked)

66 theorems across 7 files, all with axiom footprints containing no axiom outside
`{propext, Classical.choice, Quot.sound}`:

| File | Content |
|---|---|
| `CallensDualScale.lean` | Laws of `Reff(α,R) = max(R, α/R)`, incl. sharpness; the Sym² recurrence lock |
| `DyadicShells.lean` | Energy-flux telescoping; `dE/dt ≤ 0` |
| `EnstrophyProduction.lean` | Exact identity `dΩ/dt = 3Σk_n³a_n²a_{n+1} − νΣk_n⁴a_n²` |
| `EnstrophyProductionBound.lean` | Local bound `S_N² ≤ 2Ω_N³` |
| `HypothesisU_Statements.lean` | **Statement shape** of Hypothesis U (DRAFT — your §4.A) |
| `MillenniumReduction.lean` | **Conditional** reduction skeleton (DRAFT — your §4.B) |
| `TriadConservation.lean` | Detailed energy conservation + transversality of the Fourier nonlinearity |

### 1.4 What is emphatically NOT claimed

- Hypothesis U itself. Not proven, not conjectured-with-evidence — **open**.
- Any statement about actual Navier–Stokes solutions.
- That the Sym² lock is relevant to the real NSE cascade (this is Tier C, a hope).
- Any verdict on cutoff-uniformity (evidence collected; verdict deliberately not issued).
- That the four analytical tracks work (all four are blocked on undefined objects — §3.3).
- **That the nonlinearity `B` has been instantiated.** It has not. By the programme's own
  assessment, that is where the entire mathematical content resides.

---

## 2. Independent verification (≈30 minutes, no trust required)

Nothing below asks you to believe a self-report. This programme has twice caught agents (and
once caught a submitted external proposal) self-reporting "verified, no `sorry`" for artifacts
that did not compile; see `LL.md` LL-1, LL-2.

```bash
git clone <repo> && cd MechanicaFluidorum
git checkout $(git log --format=%h --diff-filter=A -- docs/AUDIT_PACKET.md)

# Full pipeline: Tier B harnesses, ledger consistency, Lean kernel + axiom footprints.
./scripts/verify.sh ; echo "EXIT=$?"        # expect EXIT=0
```

The Lean build is pinned by revision (`lean_src/lakefile.lean` + tracked
`lean_src/lake-manifest.json`). If `lean_src/.lake` is absent it will be built by
`cd lean_src && lake exe cache get && lake build` (~8 GB, mostly cache download).

**The check that actually matters** — the axiom footprint, not the absence of the string
`sorry` in the source (a failed proof still defines its theorem name; only `#print axioms`
reveals a stray `sorryAx`):

```lean
#print axioms MechanicaFluidorum.MillenniumReduction.millennium_reduction
-- must name no axiom outside {propext, Classical.choice, Quot.sound}
```

**Adversarial check we suggest you run:** perturb any theorem's hypotheses and confirm the
build *fails*. Each Lean file's footer documents specific perturbations that were tested and
the failures they produced. A gate that cannot fail is not a gate — please verify ours can.

---

## 3. Declared limitations (read before §4)

### 3.1 The abstract `B`

`HypothesisU_Statements.lean` models the truncated dynamics as
`d/ds u(s,n)|_{s=t} = B n (u t) − ν·w n·u(t,n)` where `B : ℕ → (ℕ → ℝ) → ℝ` is an
**unconstrained parameter**. No property of `B` is assumed. The true 3-D convolution
nonlinearity is not written anywhere in the formalisation.

### 3.2 The dyadic model is a toy, and is never claimed otherwise

The shell model `NLₙ = k_{n-1}a_{n-1}² − k_n a_n a_{n+1}` is Katz–Pavlović's, a standard
turbulence toy model. **The repository never asserts it is derived from, or approximates,
`(u·∇)u`.** If you find a place where it is treated as a stand-in for the real nonlinearity,
that is a finding.

### 3.3 All four analytical tracks are blocked

T1–T4 require four objects that do not exist in this programme or, to our knowledge, in the
literature: a Sym²-constrained spectrum on `𝕋³`; a formula for an "enstrophy echo"; an entropy
functional and reference state; a coupling of a percolation field to Sym². Draft definitions
exist but are **unaudited**, and authorship never unblocks a track.

**A structural finding against the programme's own architecture, which we surface rather than
bury:** under the natural choice of entropy functional, **T3 collapses into the direct
production-identity attack rather than being independent**, and **T1 and T4 depend on the same
unproven embedding**, so agreement between them would be correlated, not independent, evidence.
The advertised "four independent attacks" is not currently four independent attacks.

### 3.4 The local bound is not evidence for Hypothesis U

`S_N² ≤ 2Ω_N³` is proven. Note the exponent: production bounded by `Ω^{3/2}` is exactly the
supercritical scaling that makes the enstrophy differential inequality insufficient for global
control. **The bound is consistent with blow-up.** It is infrastructure, not progress toward U.

### 3.5 Errata caught (full list; `LL.md` has the incidents)

| # | Defect | Status |
|---|---|---|
| 1 | A broad `git add` committed a mid-edit Lean file carrying `sorryAx` in five theorems | Corrected same day |
| 2 | A submitted external proposal self-reported "proven, no sorry"; it did not compile | Rejected, archived with kernel log |
| 3 | A design memo's own worked example quoted the wrong summation range | Corrected; validity unaffected |
| 4 | The Tier A gate string-matched an exact axiom list, rejecting *cleaner* footprints | Fixed to a membership test |
| 5 | **The Mathlib dependency was unpinned** — a cold build would have verified everything against a different prover library | Pinned; lockfile tracked |
| 6 | A ledger row cited a non-identifier fragment (`_half`) | Found by the new ledger gate; fixed |

### 3.6 Citation discipline, and one near-miss

Literature was retrieved and verified rather than cited from memory; unconfirmable details are
marked `[unverified]` in `docs/report/mechanica_fluidorum_report.tex`'s bibliography rather
than asserted. One near-miss is worth your attention as a calibration signal: a first pass
concluded the spec misdescribed a track's regularity class and was about to "correct" the
normative rulebook — on the strength of a paraphrased summary. Re-fetching showed the spec was
defensible. **If you see remaining citation claims that rest on summaries rather than primary
sources, please flag them.**

---

## 4. The questions we need answered

Each is a genuine judgment call where a different answer changes the formalisation. Please
answer **yes / no / revise**, with reasoning where you say no.

### 4.A — `HypothesisU_Statements.lean` (statement shape)

**A1. Is `∃C. ∀N. …` the right quantifier order?**
`HypothesisU := ∃ C > 0, ∀ N, ∀ u, IsGalerkinSolution N … u → ∀ t ∈ [0,T], enstrophy N w u t ≤ C`.
The constant is chosen *before* the cutoff. Swapping to `∀N ∃C` would be the trivial statement
that each finite truncation is bounded on its own. We believe this ordering is the entire
content. *Do you agree it faithfully mirrors `sup_{α'>0}`?*

**A2. Is an index cutoff an adequate stand-in for a frequency cutoff?**
`truncate N u₀` zeroes modes by **index** `n > N`, not by wavenumber magnitude `|k| > 1/√α'`.
The correspondence `N ≈ 1/√α'` is declared narrative and is not formalised. *Adequate, or does
this abstract away something load-bearing?*

**A3. Is fixing `w n = (2ⁿ)² = 4ⁿ` the right weight?**
Chosen to match the dyadic model, not a literal `|k|²` on a `ℤ³` lattice. It makes enstrophy
provably a nonnegative sum of squares. *Right proxy to carry forward, or dyadic-only?*

**A4. Should the statement quantify over *every* solution?**
`∀ u, IsGalerkinSolution … u → …` bounds every solution of the constraint, not one canonical
trajectory — relevant to obstruction O4 (Buckmaster–Vicol non-uniqueness). *Is the stronger
reading intended?*

**A5. Is it acceptable to certify this file's shape while `B` carries zero structural content?**
*Or should some minimal property of `B` be required first (e.g. the transversality fact now
proven in `TriadConservation.lean`)?*

### 4.B — `MillenniumReduction.lean` (conditional reduction)

**B1. Are `AubinLionsStatement` and `ProdiSerrinStatement` bona fide statements, or placeholders?**
Both are bare `Prop → Prop` arrows with no internal reference to norms or the Serrin exponent
condition `2/s + 3/q ≤ 1`. The Definition of Done requires "bona fide statements, not `Prop`
placeholders". *Does the current form satisfy that, or must the names be verifiably tied to the
real theorems?*

**B2. `HasBoundedFullLimit` permits a different limit solution for each horizon `T`.**
`∀T, HasBoundedFullLimit …` allows a distinct `ulim` per `T`, yet `GlobalRegularityStatement`
demands a single global solution. The diagonalisation is implicit and unnamed. *Should one
`ulim` be fixed across all `T`, or the diagonalisation step made explicit?*

**B3. `IsSpatiallySmooth`'s bound may depend on `t`.**
Smoothness is certified separately at each time, with no uniform-in-`t` bound. *Is per-time
smoothness the intended reading of the Prodi–Serrin conclusion?*

**B4. The theorem is never specialised to the concrete object.**
`millennium_reduction` stays generic in any `w = k²`; it is never instantiated against
`HypothesisU_dyadic`. *Should it be, so the two audited files provably describe the same
object?*

**B5. `GlobalRegularityStatement` is existence-only** — no uniqueness, no link back to "the"
Leray–Hopf limit, though Proposition 5.1 says "*the* limit `u` is smooth". *Is bare existence
the intended reading?*

### 4.C — `TriadConservation.lean`

**C1. Is the abstraction level honest, or does it overstate reach?**
The file proves detailed energy conservation over an *arbitrary commutative ring* with an
arbitrary additive index group — deliberately **not** over `Λ ⊂ ℤ³` with complex velocities,
because that concrete apparatus is an open decision. The bridge to the concrete
Fourier–Galerkin setting is **not built**. *Is the file's own scope note adequate, or could a
reader reasonably over-read it as a theorem about Navier–Stokes?*

### 4.D — Global

**D1. Does anything in this packet, the LaTeX report, or `LEDGER.md` overstate its tier?**
This is the question the programme most wants adversarially checked.

**D2. Is the obstruction ledger (`SPEC.md` §1.3: Tao, supercriticality, CKN, Buckmaster–Vicol,
the Euler test) actually engaged, or merely listed?**

---

## 5. Reporting back

No format is imposed. What is most useful: for each question, **yes / no / revise** plus
reasoning; then anything in §4.D you found independently. Findings will be recorded in
`LEDGER.md` with attribution and a date, including — especially — findings that kill a claim.

**If you conclude the programme's central framing is wrong, or that a Tier A claim overstates
what its formal statement supports, that is the single most valuable outcome this packet can
produce.**
