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
| **A — Established** | Lean 4 kernel-compiled, zero `sorry`, axiom footprint containing **no axiom outside** `{propext, Classical.choice, Quot.sound}` (a strict subset is cleaner, and passes — see §5.1) | kernel + `#print axioms` membership test |

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

**RETRACTION (2026-08-13, external audit verdict D1 — KILLED; owner acceptance in
`docs/Memo 1.md`).** This section previously claimed the programme "restates the open core of
the Millennium problem". The audit found that claim false as applied to the formalisation: a
1-D index cutoff (not a `ℤ³` frequency cutoff), the weight `4ⁿ` (not the Laplacian symbol
`|k|²`), and an unconstrained interaction term `B` describe a **dyadic shell hierarchy**, not
the unreduced 3-D equations. The retraction is accepted in full, and the programme is
re-targeted accordingly:

- **The formal target is the truncated viscous Katz–Pavlović dyadic shell model** — a
  respected, active area of mathematical fluid mechanics in its own right (blow-up: Katz–
  Pavlović 2005, Cheskidov 2008; regularity under strong dissipation: Barbato–Morandin–Romito),
  where a machine-verified global-regularity or blow-up theorem would be a first.
- The prose of §1.1 about `𝕋³` and `J_{√α'}` remains the programme's *motivating* problem, and
  the 3-D bridge (ℤ³ reindexing; OP-2/OP-6) is explicit, open future work — never an implicit
  claim of the formalisation.
- Obstruction compliance (§1.3) is re-scoped: O1 (Tao) and O5 (the Euler test) remain
  meaningful for the dyadic target; O2–O4 are inherited only if and when the 3-D bridge is
  built (audit verdict D2: a 1-D sequence model lacks the surface area to encounter CKN).
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
| T2 Villani–Mouhot (phase mixing) | Gevrey–Newton scheme suppresses "enstrophy echoes" **[Gevrey confirmed available, but only *some* classes — §2.3.1]** | Precise *definition* of an enstrophy echo in the truncated system + its exact evolution in the dyadic model | echoes not suppressed even in the dyadic model → kill |
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

**RESOLVED same day — and the resolution is that the T2 row was NOT wrong.** Re-fetching the
arXiv abstract page directly (rather than relying on the earlier tool-generated summary, parts
of which were flagged as paraphrase) gives both readings, from two different revisions:

- the paper's own abstract states it establishes *"exponential Landau damping in **analytic**
  regularity"*, and elsewhere *"the (a priori unexpected) critical nature of the Coulomb
  potential and analytic regularity, which can be seen only at the nonlinear level"*;
- the current abstract page's version note states that the main result *"now covers Coulomb and
  Newton potentials, and (2) **some classes of Gevrey data**"*.

So the base result is analytic; the final version additionally covers Gevrey classes. **The
existing "Gevrey" description in the T2 row is therefore defensible and is left standing.**

**One substantive caveat now on record, which is the part that actually bears on T2:** the
coverage is *"**some** classes of Gevrey data"*, not all — so any T2 argument that leans on
Gevrey regularity must identify *which* class, and must not assume the full Gevrey scale is
available. That is a real constraint on the track's feasibility, not a matter of wording.

**Process note (the reason this entry exists in this form).** The first pass had enough
material to "fix" `SPEC.md` by replacing Gevrey with analytic. Doing so would have introduced
an error into the normative spec on the strength of a paraphrase — precisely the LL-6 failure
mode, one level up. Flagging rather than correcting was the right call, and re-fetching cost
one tool call. Recorded so the pattern is reusable: **when a correction is based on a summary
rather than a primary quote, flag it and re-fetch; do not edit the rulebook.**

No track status changes: T2 remains BLOCKED-ON-DEFINITION on OP-3 regardless.

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
2. **Gate 2 (Tier A):** kernel-compile every file in `lean_src/`; fail on any error or
   `sorry`; every `#print axioms` line must name **no axiom outside**
   `{propext, Classical.choice, Quot.sound}`.

   **Clarified 2026-08-13 (wording amended to match intent; see `LL.md` LL-8).** This rule
   previously read "must be exactly `[propext, Classical.choice, Quot.sound]`", and
   `scripts/verify.sh` implemented that literally as a string match. A theorem proved by purely
   computational means can report a **strict subset** — e.g. `[propext]` — which is *cleaner*
   than the permitted set, yet was rejected as non-clean
   (`TriadConservation.swap3_involutive` is the concrete instance). That false positive is not
   cosmetic: the cheapest way to satisfy a literal-equality gate is to **add** an unnecessary
   axiom dependency, i.e. to make the proof worse in exactly the dimension the gate exists to
   measure. The gate is therefore a **membership test**, which is strictly stronger than the
   old check in the direction that matters — `sorryAx`, custom axioms, and any other foreign
   axiom are still caught (re-verified against a six-case table, including cases that must
   fail, before the change was accepted).
3. **(Stage-0 addition — DONE 2026-08-13)** cold-build job; single-active-file lint (§7.4);
   LEDGER consistency check (every Tier A/B entry maps to a passing artifact).
   - **Cold build:** `lean_src/` is now a standalone Lake project with Mathlib pinned by
     revision (`lean_src/lakefile.lean`, plus the tracked `lean_src/lake-manifest.json` which
     pins every transitive dependency). Gate 2 prefers this local build and falls back to
     `LEAN_ENV_DIR` when it is absent, so a fresh clone still verifies without an ~8 GB build.
   - **Lint + LEDGER check:** implemented as Gate 1b, `scripts/ledger_check.py`. Ships its own
     negative controls (a dangling path, a dangling Lean name, and a banned versioned filename
     must each be rejected, plus a clean positive control that must be accepted) which run on
     every invocation — per §2's "a checker that cannot fail is not a checker".
     The name check resolves **class fields** as well as `theorem`/`def`/`instance`, which is
     load-bearing: `resonance_law` is cited by a Tier A row and is a class field, so a naive
     checker reports it as an orphan. It found and fixed one real defect on first run (a row
     citing the non-identifier fragment `` `_half` `` instead of `step1_flux_bound_half`).

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
2. **T2 (Villani-Mouhot):** Gevrey-regularity Newton iteration proving enstrophy echo exponential decay. **[only *some* Gevrey classes are covered by the source result — §2.3.1]**
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
