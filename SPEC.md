# AgoraAI-Agentic-Core — Specification v0.2 (2026-08-12)

**Program:** a staged, verifier-in-the-loop scientific program on the global regularity of the
3D Navier–Stokes equations, organized around **Hypothesis U** (uniform enstrophy control of the
frequency-truncated system), conducted with formal verification (Lean 4), exact arithmetic (ℚ),
and disciplined use of cross-disciplinary analogy.

**Status of this document:** single active specification (per §7.4). Supersedes
`docs/SPEC_v0.1_original.md` (frozen record). Rationale for every change:
`docs/REVIEW-2026-08-12.md`.

---

## 0. Epistemic Charter

Oversight split: **the machine verifier checks the proofs; the human mathematician audits the
questions** (statements, definitions, and the adequacy of formalizations to their intended
meaning). No LLM output gates a tier promotion.

Three-tier gating, mechanically enforced by `scripts/verify.sh`:

| Tier | Meaning | Gate |
|---|---|---|
| **C — Conjecture** | proposals, analogies, physical narratives, unverified reductions | none (but must be tagged) |
| **B — Checkable** | identities validated in exact rational arithmetic; certified witnesses; no floats | `tests/` harness exits 0 |
| **A — Established** | Lean 4 kernel-compiled, zero `sorry`, axiom footprint exactly `[propext, Classical.choice, Quot.sound]` | kernel + `#print axioms` grep |

**The honesty clause.** Every public claim carries its tier. A claim absent from `LEDGER.md`
has no tier and may not be cited. Tier A status attaches to the *formal statement actually
proven*, never to its informal gloss — the human audit of statement adequacy is what licenses
the gloss.

---

## 1. The Problem, Stated Honestly

### 1.1 Hypothesis U

For α' > 0 let J_{√α'} denote the projection onto Fourier modes |k| ≤ 1/√α' on 𝕋³, and let
u^(α') solve the truncated system

    ∂ₜu + ((J_{√α'} u)·∇)u = −∇p + νΔu,  ∇·u = 0,  u(0) = J_{√α'} u₀,

which is globally smooth for each fixed α' > 0. **Hypothesis U** (for data u₀ and horizon T):

    sup_{α'>0} sup_{0≤t≤T} ‖∇u^(α')(t)‖_{L²(𝕋³)} < ∞.

**Proposition 5.1 (Millennium Reformulation).** If Hypothesis U holds for all smooth
divergence-free u₀ and all T, then 3D Navier–Stokes is globally regular.
*Chain:* energy identity → L^∞ₜL²ₓ ∩ L²ₜH¹ₓ bounds → Aubin–Lions → strong-L² subsequential
limit is Leray–Hopf → under U the limit is in L^∞ₜH¹ₓ ↪ L^∞ₜL⁶ₓ → Serrin class (2/s + 3/q =
1/2 ≤ 1) → smooth. **[Tier C: paper-level standard result; formalization is Stage 2.]**

### 1.2 What this framing is and is not

- The truncated system *is* the classical Leray/Fourier–Galerkin mollification. Proposition 5.1
  is standard. **Hypothesis U is a restatement of the open core of the Millennium problem, not
  a reduction of its difficulty.** Its value is organizational: one quantitative target, four
  independent attacks, machine-checked bookkeeping.
- The T-dual effective radius Reff(α, R) = max(R, α/R) — with its proven laws (§2.1) — is the
  program's *geometric inspiration* for the cutoff. The *mechanism* in the PDE is the cutoff
  J_{√α'} itself. Deriving the truncated dynamics from a genuine metric deformation is an open
  problem of the program (OP-1, Tier C), not an assumption.

### 1.3 Obstruction Ledger (normative)

Every proposed strategy, agent-generated or human, must include an **Obstruction Compliance
Note** addressing all five items. Strategies that cannot are rejected at review, before any
formal work (§7.3).

| # | Obstruction | Compliance question |
|---|---|---|
| O1 | **Tao 2016** — an averaged NSE obeying the energy identity blows up | Which structural feature of the *true* nonlinearity (beyond the energy identity) does the strategy use? |
| O2 | **Supercriticality** — enstrophy is supercritical; ∫ω·S·ω defeats all known bounds | Where exactly does the strategy gain over the naive enstrophy inequality, uniformly in α'? |
| O3 | **CKN 1982** — best known: singular set has vanishing 1-D parabolic Hausdorff measure | If the strategy implies something stronger than CKN, what new mechanism pays for it? |
| O4 | **Buckmaster–Vicol** — weak solutions are non-unique below the Leray class | In which class is the α' → 0 limit taken, and why is the limit the physical solution? |
| O5 | **The Euler test** — the argument must break at ν = 0 | Point to the step that fails for Euler. A strategy that would also "prove" 3D Euler regularity is presumptively wrong. |

---

## 2. Mathematical Foundations

### 2.1 T-dual effective radius — **[Tier A, verified 2026-08-12]**

`Reff (α R : ℝ) : ℝ := max R (α / R)` with, for α > 0, R > 0:

1. `Reff_pos` — 0 < Reff α R.
2. `Reff_ge_sqrt` — √α ≤ Reff α R (universal minimum scale).
3. `Reff_bounce` — R < √α → Reff α R = α / R.
4. `Reff_inertial` — √α ≤ R → Reff α R = R (classical at macroscopic scales).
5. `Reff_tdual` — Reff α (α / R) = Reff α R.

**Sharpness** (added 2026-08-12 from proposal review): `Reff_gt_sqrt_of_ne` — the inequality is
strict for R ≠ √α; `Reff_eq_sqrt_iff` — the minimum `√α` is attained at **exactly one point**,
the self-dual radius R = √α. The minimal scale *is* the self-dual scale.

**Two presentations, one object**: `tDualRadius α R := if R < √α then α/R else R` (the piecewise
"bounce" form the narrative speaks) equals `Reff α R` for R > 0 (`tDualRadius_eq_Reff`), and
`genesis_no_singularity : 0 < tDualRadius α R` follows axiom-free. The side condition is real:
at α = 4, R = −1 the forms give −4 and −1 respectively (witnessed `example`, §7.5).

Proven in `lean_src/CallensDualScale.lean`; zero `sorry`; zero custom axioms; footprint
`[propext, Classical.choice, Quot.sound]` (log: `docs/verification-log-2026-08-12.txt`).
α' is a *hypothesis parameter* (0 < α), never an axiom — see §7.1 for why this is forced by
Hypothesis U itself. Tier B mirror: sqrt-free square-form checks over ℚ
(`tests/tier_b_exact_checks.py`, B3, B5).

### 2.2 Symmetric-square lock — **[Tier A (constant coeff.); Tier B (variable coeff.)]**

`sym2_recurrence`: if u_{n+2} = a·u_{n+1} + b·u_n then v = u² satisfies

    v_{n+3} = (a²+b)·v_{n+2} + b(a²+b)·v_{n+1} − b³·v_n     (L3 = Sym²(L2))

— the discrete shadow of Clausen's identity (roots {λ, μ} ↦ {λ², λμ, μ²}). Proven in Lean;
independently re-derived from data by exact linear solving (`tests/…`, B4) — the guess-and-prove
loop closes. `sym2_recurrence_seq` gives the sequence-level interface (v supplied and related to
u by hypothesis). **`sym2_symmetric_functions`** verifies the spectral content that makes the
lock structural rather than a lucky identity: the L3 coefficients are the elementary symmetric
functions of {λ², λμ, μ²}, i.e. e₁ = a²+b, e₂ = −b(a²+b), e₃ = −b³ (Tier B mirror: B6). The
variable-coefficient version is Tier B here (B2) and has a kernel proof in the prior tree
pending migration. **Intended role (Tier C):** rigidity constraint tying macroscopic
transport (L3) to the fiber operator (L2) in the Picard–Fuchs setting; its *relevance to NSE*
is a conjecture of the program, to be earned in Stage 1.

### 2.3 The four analytical tracks — **[all Tier C]**

Four independent attacks on Hypothesis U. Each is an *analogy with a falsification plan*, run
under §7.3 (counterexample-before-attack). First milestones are deliberately modest and
decidable.

| Track | Idea | First falsifiable milestone | Kill criterion |
|---|---|---|---|
| T1 Bourgain–Demeter (arithmetic depletion) | ℓ²-decoupling starves high-frequency triadic resonances | Exact count of resonant triads k₁+k₂=k₃ under the Sym² spectral constraint vs. unconstrained, on shells up to \|k\| = 2⁸ (Tier B computation) | constrained count grows at the same order → no depletion → kill |
| T2 Villani–Mouhot (phase mixing) | Gevrey–Newton scheme suppresses "enstrophy echoes" **[regularity class UNCONFIRMED — see §2.3.1]** | Precise *definition* of an enstrophy echo in the truncated system + its exact evolution in the dyadic model | echoes not suppressed even in the dyadic model → kill |
| T3 Golse–Saint-Raymond (entropy limits) | relative-entropy functional controls dissipation uniformly | A relative-entropy inequality at PDE level (DiPerna–Lions style) for the *truncated* system, α' fixed | inequality already fails at fixed α' → kill (note: α'→0 is **not** a Knudsen limit; no kinetic layer exists — see review M4) |
| T4 Duminil-Copin (percolation of high enstrophy) | supercritical-enstrophy regions form subcritical percolation clusters | Recover the **CKN dimension bound** in the lattice formulation | lattice formulation cannot recover even CKN → kill |

### 2.3.1 Open citation-verification item on T2 (raised 2026-08-13)

While verifying references for `docs/report/mechanica_fluidorum_report.tex` under rule LL-6
("verify literature precisely before citing"), retrieval of the **Mouhot–Villani** abstract
(*On Landau damping*, arXiv:0904.2760, **Acta Mathematica 207(1) (2011), 29–201** — journal
reference confirmed by direct fetch) indicated that the paper's **core stated result is set
in an analytic-regularity class**, with Gevrey-class settings appearing as a related or
limiting extension rather than as the central theorem. The T2 row above, and §5's T2 endpoint,
both describe the track as resting on **Gevrey** regularity.

**Status: UNRESOLVED — do not "fix" either way without checking the paper itself.** The
indication above came from a fetched *abstract plus a tool-generated summary*, parts of which
were explicitly flagged as paraphrase rather than direct quotation. Asserting "Gevrey is
wrong" on that basis would repeat precisely the error LL-6 exists to prevent, one level up.

**What would close this item:** read the statement of the main theorem(s) in the published
Acta paper (or arXiv full text, not the abstract) and record which regularity class is
actually required, with a quotation. **Why it matters, and why it is not cosmetic:** the
required regularity class governs whether any analogue could plausibly transfer to a fluid
setting at all, so it bears directly on T2's feasibility — not merely on how T2 is described.

Filed by the report-authoring pass; no track status is changed by this note, and T2 remains
BLOCKED-ON-DEFINITION on OP-3 independently of how this resolves.

### 2.4 Physical narrative — **[Tier C, quarantined]**

Cosmological interpretations (T-dual bounce as Big-Bang regularization, "dark sector" mass
laws, K3/mock-modular numerology) live in `docs/narrative/` only. `lean_src/` never imports
them; tier promotions never cite them; no magic constants in mathematical definitions. The
sense of beauty and analogy that motivates the program is welcome *there* — and it earns its
way into the core only through Tiers B and A.

---

## 3. Repository Layout (actual, enforced)

```
SocrateAI-Scientific-MechanicaFluidorum/
├── SPEC.md                          ← this file (single active spec — rules)
├── PLAN.md                          ← agent execution plan (operational law; tasks, DoD, escalation)
├── LEDGER.md                        ← normative claim inventory with tiers
├── LL.md                            ← lessons learned: why each process rule exists, with evidence
├── CLAUDE.md                        ← build/verify commands and architecture, for Claude Code sessions
├── README.md
├── docs/
│   ├── SPEC_v0.1_original.md        ← frozen record of the received spec
│   ├── REVIEW-2026-08-12.md         ← critical review (rationale for v0.2)
│   ├── verification-log-2026-08-12.txt
│   ├── proposals/                   ← submitted artifacts: verbatim record + kernel log + review
│   └── narrative/                   ← Tier C physical interpretation (quarantine)
├── lean_src/
│   ├── CallensDualScale.lean        ← Tier A core (single active file)
│   ├── lean-toolchain               ← leanprover/lean4:v4.33.0-rc2
│   └── lakefile.lean                ← mathlib dependency (cold build: lake exe cache get && lake build)
├── symbolic/
│   └── picard_fuchs_generator.py    ← exact-ℚ guess-and-prove core (+ negative control)
├── tests/
│   └── tier_b_exact_checks.py       ← Tier B gate (B1–B4)
└── scripts/
    └── verify.sh                    ← two-gate CI entry point
```

Interim build note: Gate 2 verifies against the locally built Mathlib at
`~/xdev/SocrateAI-Scientific-RajMathRecovery/dualscale/lean` (override with `LEAN_ENV_DIR`).
Stage 0 includes standing up the standalone cold build.

## 4. Toolchain

- **Lean 4** `v4.33.0-rc2` + Mathlib (pinned by `lake-manifest.json` once the standalone build
  lands; migrate to a stable toolchain tag as a Stage-0 chore). Interactive proving via
  Pantograph or `lake env lean`; diagnostics parsed from compiler output.
- **Python 3.12**, exact arithmetic only in Tier B code (`fractions.Fraction`); floats barred.
- **Symbolic guessing**: exact-ℚ core in `symbolic/`; scale up with SageMath `ore_algebra` or
  Maple `gfun` (n.b. `gfun` is Maple, not Python) when Picard–Fuchs work begins in earnest;
  Zeilberger creative telescoping via those systems.

## 5. Verification Gates (CI)

`scripts/verify.sh` runs, in order:

1. **Gate 1 (Tier B):** `tests/tier_b_exact_checks.py` must exit 0.
2. **Gate 2 (Tier A):** kernel-compile `lean_src/CallensDualScale.lean`; fail on any error or
   `sorry`; every `#print axioms` line must be exactly `[propext, Classical.choice, Quot.sound]`.
3. **(Stage-0 addition)** cold-build job; single-active-file lint (§7.4); LEDGER consistency
   check (every Tier A/B entry maps to a passing artifact).

## 6. Staged Roadmap

**Stage 0 — Foundations & governance** *(largely done 2026-08-12)*
Tier A core + Tier B harness + gates: **done**. Remaining: standalone cold build; migrate the
variable-coefficient Sym² proof out of the prior tree; CI automation of §5.3.

**Stage 1 — Shell-model calibration (the honest testbed).**
Formalize the Desnyansky–Novikov and Katz–Pavlović dyadic cascades *with initial data
quantified* (repairing review-L6), plus a ℚ-exact finite-truncation integrator (Tier B) for
enstrophy trajectories. State the **dyadic Hypothesis U** and prove or refute it there.
Literature to re-verify and cite precisely first (Tier C until then): dyadic Euler blowup
(Katz–Pavlović; Kiselev–Zlatoš), dissipative dyadic results (Cheskidov; Barbato–Morandin–
Romito), Tao's averaged model. *This stage is the program's laboratory: any mechanism from
tracks T1–T2 that cannot produce a uniform bound in the dyadic model dies here, cheaply.*

**Stage 2 — Formal skeleton of Proposition 5.1.**
Fourier-side definitions of the truncated system on 𝕋³ (finite Galerkin ODE: global existence
is honestly formalizable); statement-level formalization of Hypothesis U **with the equation
and data as constraints** (repairing review-L3); Prop 5.1 with unproven infrastructure
(Aubin–Lions, Serrin) as *hypothesis parameters*, never axioms (repairing review-L7). Scope
honesty: full analytic formalization is a multi-year Mathlib-scale effort; the paper proof +
Tier B numerics carry the interim weight, and the ledger says so.

**Stage 2 — Classical PDE Consolidation.**
Reassemble the global theory of Leray-type mollified NSE, tracking explicit dependence on α'.
Energy inequalities, Aubin-Lions embedding, Prodi-Serrin criterion application. Target: paper-level Tier A formalization.

**Stage 3 — Enstrophy Bounds (The Four Tracks).**
Scale-by-scale proof of Hypothesis U via four deep mathematical disciplines:
1. **T1 (Bourgain-Demeter):** ℓ² decoupling to show triadic resonant depletion under Sym² lock.
2. **T2 (Villani-Mouhot):** Gevrey-regularity Newton iteration proving enstrophy echo exponential decay. **[regularity class UNCONFIRMED — see §2.3.1]**
3. **T3 (Golse-Saint-Raymond):** Relative-entropy functional showing dissipation uniformly bounds enstrophy as α' → 0.
4. **T4 (Duminil-Copin):** Percolation scaling limits proving zero-dimensional singular set.

Each track has a falsifiable milestone (Tier B computation or Tier A proof). Each has a kill criterion.

**Stage 4 — Formal Audit.**
Translate Stage 3 analytics into machine-checked Lean 4. Final verification: `#print axioms` footprint = `[propext, Classical.choice, Quot.sound]`.

**Stage 4 — Synthesis.** Only entered if a track survives Stage 3 with a continuum-level
Tier B result. Integration of partial bounds toward Hypothesis U; adversarial review; outside
expert audit *before* any public claim (the §1 retraction pitfall applies to us most of all).

## 7. Rules (Do's and Don'ts)

**7.1 Axioms are forbidden; α′ is quantified, never fixed.** No custom axioms, ever. Unproven
infrastructure enters as explicit hypothesis parameters, visible in the theorem's type. Gate:
`#print axioms` grep (§5). Note `opaque c : ℝ` adds no axiom and is preferable to `axiom c : ℝ`,
but any `axiom c_pos : 0 < c` still pollutes every downstream footprint.

*The primary reason to parameterize α′ is scientific, not bureaucratic:* Hypothesis U is
`sup_{α′>0} sup_t ‖∇u^(α′)(t)‖_{L²} < ∞` — a statement **quantified over α′**, whose whole
content is the α′ → 0 limit. If α′ is a fixed global constant (`opaque` or axiomatized), the
family `u^(α′)` cannot be formed, uniformity cannot be stated, and the limit cannot be taken.
Every definition in the program must therefore take α′ as an argument.

**7.1b Submitted artifacts are recorded, compiled, then merged.** Any proposed Lean file (human
or agent) is (i) archived verbatim under `docs/proposals/`, (ii) compiled as-submitted with its
kernel log saved, (iii) reviewed against the gates, (iv) merged in repaired form into the single
active file with credit for what it contributed. A named theorem in the environment is *not*
evidence: a failed proof still defines the name, and only the footprint reveals the `sorryAx`.
Never accept "no `sorry` in the source" as a substitute for the gate.

**7.2 Strict epistemic gating.** Every result is tagged C/B/A in `LEDGER.md` at creation.
Promotion B→A requires the kernel; promotion C→B requires the exact-arithmetic harness;
*statement adequacy* at any tier requires human sign-off, not an LLM judge.

**7.3 Counterexample before attack.** Before any formal proof attempt on a new goal: run
degenerate/boundary probes and an exact-arithmetic falsification sweep; strategies must file
an Obstruction Compliance Note (§1.3). Negative controls are part of every harness (a checker
that cannot fail is not a checker).

**7.4 Single active file; cold builds.** One active version per module; iterations happen
in-place under version control (git history is the archive — no `_v2`/`_final` copies; no
`verify_*.lean` litter). Cold builds from zero `.olean` cache must pass before a release tag.

**7.5 Non-vacuity.** Every class/structure ships an explicit instance; every theorem's
hypotheses ship a concrete witness (`example` blocks alongside the theorem); existence
statements quantify over the data (no trivial-witness "well-posedness"). Every division and
every integral inside a Tier A statement carries a witnessed side condition (Lean's junk
values: `x/0 = 0`, integral of non-integrable = 0).

**7.6 Honest difficulty language.** "Reformulation", not "reduction"; "conjecture", not
"mechanism", until tiered. The program's ambition is the reason for this discipline, not an
exemption from it.

## 8. Scoring (revised SCSC)

Mechanical score per generated Lean artifact: **SCSC = (IC1 · IC2)^(1/2)** with IC1 = file
typechecks (0/1), IC2 = fraction of declarations closed without `sorry`/`admit`. TE1 (semantic
adequacy of statements) is an **advisory flag that requests human audit** — it never gates.
D1/D2 apply only to benchmark exercises that have a gold reference.

---

*v0.2 drafted, reviewed against the audit findings, and gate-verified 2026-08-12. The next
edit to this file is a Stage-0/Stage-1 change and goes through review like any other artifact.*
