# Draft Definitions for OP-2…OP-5 — AWAITING HUMAN AUDIT

> ## ⛔ OP-2's draft embedding FAILS T1's own kill criterion — measured 2026-08-14
>
> `SPEC.md` §2.3 states T1's kill criterion in advance: *"constrained count grows at the same
> order → no depletion → kill"*. The draft's radial rule was computed against it, using the
> existing T0.1/T0.2 lattice tooling. The rule, made explicit: sorted shell indices `(a≤b≤c)`
> are Sym²-compatible iff `{a,b,c} = {2i, i+j, 2j}`, i.e. **`a` even, `c` even, `b = (a+c)/2`**.
>
> | `M` | triads `k₁+k₂=k₃` | Sym²-permitted | fraction |
> |---|---|---|---|
> | 4 | 30 360 | 588 | 0.019 |
> | 6 | 398 190 | 104 772 | 0.263 |
> | 8 | 2 079 168 | 1 091 364 | **0.525** |
>
> The permitted fraction **rises** with `M`. Depletion would require it to fall toward zero;
> instead the constrained count grows at the same order as the unconstrained one. **Kill
> criterion met.**
>
> **Why**, which makes the finding structural rather than a number: at `M=8`, **99.0 % of all
> permitted triads have `a=b=c`** — same-shell triads whose common index happens to be even.
> The rule is not an arithmetic depletion of resonances; it is a **parity filter on the shell
> index**. It removes odd-indexed shells and leaves the resonance structure otherwise intact,
> so its apparent strength oscillates with where the outermost shell falls rather than
> reflecting any mechanism.
>
> **This is the same failure mode as the pointwise shell constraint** (`LL.md` LL-11): a
> translation that carries the *symbols* of the proven lock into a new setting while leaving
> the quantity it was supposed to control essentially free. The draft's own honesty clause
> anticipated the cause — *"the radial reduction throws away the angular structure of `k`,
> which is precisely where 3-D vortex-stretching geometry lives"* — and this measurement
> confirms it quantitatively.
>
> **Consequence for the audit:** OP-2 should not be audited as a candidate to approve, but as a
> candidate to **reject on evidence**, with the measurement above as the reason. A viable
> embedding must act on the *angular/vector* structure of the triads, not on a radial grading.
> The natural object is the resonant-triad hypergraph itself, which is definition-independent
> and can be built now.

**Status:** Tier C draft. **Does not unblock T1–T4 by itself** — per PLAN.md §6, only
human audit unblocks a `BLOCKED-ON-DEFINITION` track. This document is that audit's input,
not its output. Nothing here may be cited as a claim; nothing here may be executed by an
agent until a row below is marked AUDITED in `LEDGER.md`.

**Author:** Fable 5 (top-tier authoring, per PLAN.md's own rule that this class of task is
`[top]`+`[human]`, never `[any]`). Each section states the object, the reasoning behind the
specific choice, what it does *not* claim, and the smallest falsifiable first computation.

---

## OP-2: The Sym²-Constrained Spectrum on 𝕋³ (unblocks Track T1)

### The problem this must solve
Track T1 needs to count triadic resonances `k₁ + k₂ = k₃` in `ℤ³` that are "permitted" by the
Symmetric-Square Lock. The lock (proven, Tier A) is a statement about a **scalar linear
recurrence**: if `uₙ` solves an order-2 recurrence with characteristic roots `{λ, μ}`, the
squared sequence `uₙ²` solves an order-3 recurrence with roots `{λ², λμ, μ²}`. The 𝕋³ Fourier
modes are indexed by `k ∈ ℤ³`, not by a single recursion index `n`. **There is no existing
embedding of one into the other in this program or, to my knowledge, in the literature** —
this is exactly why OP-2 was correctly left blocked rather than improvised by a low-tier agent.

### Proposed embedding (Tier C, first candidate — not the only possible one)
Fix a **radial** correspondence: partition `ℤ³ \ {0}` into dyadic shells `Sⱼ = {k : 2^j ≤ |k| <
2^{j+1}}`, and treat the shell index `j` as playing the role of the recurrence index `n`.
Define a **shell transfer operator** `L₂^{(shell)}` acting on the sequence of shell-averaged
amplitudes `(A_j)_{j≥0}` — NOT on individual modes — by the same recurrence coefficients `(a,
b)` that the microscopic operator uses in the abstract `QuantumFiber`/`MacroManifold` classes
of `CallensDualScale.lean`. The Sym² lock then constrains which **shell-index triples**
`(i, j, l)` with `i + ... ` (radial combination, not vector combination) are permitted, and
the genuine vector resonance count `k₁+k₂=k₃` is filtered to those triples whose shell indices
`(⌊log₂|k₁|⌋, ⌊log₂|k₂|⌋, ⌊log₂|k₃|⌋)` are Sym²-compatible.

**Concretely, the constraint set:** a triad `(k₁,k₂,k₃)` is Sym²-permitted iff there exist
`λ, μ` (roots of `x² = ax+b` for the program's fixed `(a,b)`) such that the shell-index triple
matches one of `{2i, i+j, 2j}` for some valid `(i,j)` pairing consistent with the recurrence
order (i.e., the three shell indices, sorted, differ pairwise by the recurrence-order gap
structure `{i, j}  → {2i, i+j, 2j}` reachable from *some* base pair). This is the most literal
transcription of "L₃ spectrum = products of L₂ spectrum" onto a radially-graded frequency
space.

### What this is honestly worth
This is a **modeling choice**, not a derivation — the radial (shell-average) reduction throws
away the angular structure of `k`, which is precisely where 3-D vortex-stretching geometry
lives. It is the *minimal* embedding that makes T1's counting question well-posed at all,
and its main virtue is falsifiability: T0.1 (`r₃(n)`, already computed and ledgered) and T0.2
(unconstrained triad counts, already computed and ledgered) are the exact instruments needed
to execute the count once this embedding — or the human's preferred alternative — is approved.

### First falsifiable computation (ready to dispatch once audited)
Using the shell partition above and the existing `data/triads_free.csv` /
`data/r3_counts.csv` baselines: compute `N_constrained(M)` by filtering the M0-baseline
triad enumeration through the shell-compatibility predicate, for the SAME `M ∈ {2,4,8,16}`
already computed. This is a mechanical `[any]` task — no new mathematics, only the filter
predicate from this document — estimated at under an hour of agent time.

### Explicit alternative the audit should weigh
A **non-radial** embedding is also possible: treat `n` as indexing a fixed **direction** (a
lattice line through the origin) rather than a shell, giving one recurrence per direction and
leaving cross-direction triads entirely unconstrained. This would likely produce *much weaker*
depletion (most triads mix directions) and is flagged here as the honest "if the radial
embedding is rejected, this is the fallback, and it predicts T1 fails its milestone" case.

---

## OP-3: "Enstrophy Echo" (unblocks Track T2)

### The problem this must solve
Track T2 borrows "Landau damping echoes" from kinetic theory (Mouhot–Villani), where an echo
is a well-defined phenomenon: a perturbation at wavenumber `k` and time `0`, transported by
free streaming, resonates with a perturbation at `k'` at a later time, producing a secondary
field response. **NSE has no free-streaming term** — the transport in the shell model is the
nonlinear cascade itself, so "echo" cannot mean the same thing. This is exactly why OP-3 must
not be filled in casually.

### Proposed definition (Tier C, first candidate)
Work in the dyadic shell model (`lean_src/DyadicShells.lean`), where the machinery already
exists. Define the **direct cascade contribution** to shell `n` at time `t` as the part of
`a_n(t)` attributable to the *nonlinear forcing from shells `< n`* alone (i.e., solve the
shell ODE with the `−k_n a_n a_{n+1}` self-interaction term removed — a "one-way" cascade).
Call this `a_n^{direct}(t)`. Define the **enstrophy echo** at shell `n`, time `t`, as the
*residual*:
```
Echo_n(t) := k_n² · [ a_n(t)² − a_n^{direct}(t)² ]
```
i.e., the enstrophy contribution attributable to the *removed* self-interaction (backscatter)
term, as a function of time. This is well-defined given any solution trajectory (which the
D4/D5 numerical integrators already produce), requires no new theory to *compute*, and
directly asks the falsifiable question: does `sup_n |Echo_n(t)|` decay as `t` grows (as the
Gevrey mechanism predicts) or not?

### What this is honestly worth
This defines an echo as a **counterfactual difference** (with vs. without backscatter),
which is a legitimate and common technique (it is how "backscatter" is isolated in
turbulence closures) but it is **not** the same mathematical object as a Landau-damping echo
— there is no oscillatory phase-mixing structure being cancelled here, only a nonlinear term
being switched off. The audit should decide whether this counterfactual notion is close
enough to what Villani–Mouhot's Gevrey machinery actually needs, or whether the track's
premise (that an NSE analogue of Landau echoes exists at all) should be abandoned in favor of
directly attacking the cascade with the production identity now in `EnstrophyProduction.lean`
instead (see the note in §Cross-track dependency below).

### First falsifiable computation (ready to dispatch once audited)
Modify the D4/D5 integrator to also run the "backscatter-removed" variant and compute
`Echo_n(t)` from the existing trajectory data — a small, mechanical extension of already-built
Tier B/C code.

---

## OP-4: The Entropy Functional `h` and Reference State `ū` (unblocks Track T3)

### The problem this must solve
Golse–Saint-Raymond's method needs a convex entropy functional whose dissipation controls the
quantity of interest, and a reference state to measure relative entropy against. Naming these
"whatever makes the theorem work" (T3's original framing) is circular — choosing `h` and `ū`
*is* the track's mathematical content, which is why this was correctly left blocked.

### Proposed definition (Tier C, first candidate)
Take `ū ≡ 0` (the trivial reference — the quiescent fluid) and `h(a) := ½ Σ_n k_n² a_n²`, i.e.
**the entropy functional IS the enstrophy functional itself.** This is not a dodge: for `ū=0`,
the "relative entropy" `H(u|ū) = h(u)` collapses to `Ω`, and the question "does relative
entropy dissipation control enstrophy generation uniformly" collapses to exactly Hypothesis
U's dyadic analogue — which is now precisely the quantity `EnstrophyProduction.lean` computes
an exact identity for. **Concretely:** using the just-derived identity
`dΩ/dt = 3Σ k_n³a_n²a_{n+1} − νΣk_n⁴a_n²`, the Golse–Saint-Raymond-style dissipation
inequality this track needs is literally: *does the production term `3Σk_n³a_n²a_{n+1}`
stay dominated by the dissipation term `νΣk_n⁴a_n²`, uniformly in N?* That is not a new
inequality to invent — it is a direct question about data already being generated.

### What this is honestly worth
Taking `h = Ω` and `ū = 0` makes Track T3 **not independent of** the direct enstrophy-bound
question — it becomes a restatement of it with different vocabulary. That is an honest
finding, not a failure: it suggests T3's real content, if it has any beyond restating the
core problem, must come from a **non-trivial** reference state `ū` (e.g. a slowly-varying
background flow) that the trivial choice above does not supply. The audit should decide
whether to (a) accept the trivial `h=Ω, ū=0` reduction as T3's actual content (in which case
T3 merges into the direct production-identity attack, and is not a fourth independent method),
or (b) require a genuinely non-trivial `ū`, which is a harder, still-open research question
this document does not resolve.

### First falsifiable computation
None beyond what the production identity already provides — this is the honest outcome of
the audit question above, not a new computation to dispatch.

---

## OP-5: Coupling the Percolation Field to the Sym² Constraint (unblocks Track T4)

### The problem this must solve
Track T4 needs the *occupancy field* (which lattice cells count as "high enstrophy") to be
constrained by the Sym² lock — otherwise T4 measures generic percolation, which cannot beat
the already-known CKN bound (SPEC Obstruction O3), and the track is scientifically inert by
construction.

### Proposed definition (Tier C, first candidate)
Reuse the OP-2 shell-compatibility predicate. Define the occupancy field on the periodic
lattice of spacing `√α'` (the `symbolic/percolation_exact.py` grid, already built and
Tier-B-tested) by: a cell at position `x` is **occupied** iff the *local* enstrophy density
exceeds `Λ` **and** the dominant contributing Fourier shell at `x` (the shell `j` whose
`A_j` — shell-averaged amplitude, from OP-2 — is largest in a neighborhood of `x`) is one that
survived the Sym²-compatible depletion filter from OP-2. In words: **cells are only eligible
to be "high-enstrophy" if their energy arrives via a Sym²-permitted resonance pathway** — the
lock doesn't change the enstrophy threshold, it changes which spatial regions can *reach* it.

### What this is honestly worth
This directly makes T4 **dependent on OP-2's embedding choice**: if the radial shell
embedding of OP-2 is rejected, T4's coupling must be redefined too. This dependency should be
stated explicitly to the audit, not hidden — T1 and T4 are not independent tracks under this
proposal; they share a foundation. That may be a reason to audit OP-2 and OP-5 together rather
than separately.

### First falsifiable computation (ready to dispatch once audited)
Once OP-2's filter predicate is approved, the existing percolation toolkit
(`symbolic/percolation_exact.py`, 27/27 tests passing) can directly compute percolation
statistics on a field constructed from OP-2's shell filter plus a threshold `Λ` — no new
software, only a field-construction function connecting two already-built instruments.

---

## Cross-track dependency this audit should weigh as a whole

This drafting exercise surfaced a structural finding worth flagging explicitly, since it
changes what "four independent tracks" means:

- **T3 (with the proposed trivial `h=Ω, ū=0`) is not independent of the direct attack** — it
  restates the enstrophy-production question. If the audit accepts this, the program's real
  independent attacks are T1/T4 (shared OP-2 foundation, geometric/arithmetic) versus T2
  (dynamical, echo-based) versus the direct production-identity route now available in
  `EnstrophyProduction.lean` (once the workflow dispatched in parallel with this document
  completes and is reviewed).
- **T1 and T4 share OP-2.** They are not independent verifications of the mechanism; they are
  two different measurements (spectral counting vs. spatial percolation) of the *same*
  proposed embedding. Agreement between them is corroborating, not independent, evidence.

Recommendation for the audit: approve or reject OP-2 as a single decision (it gates both T1
and T4), decide T3's fate (trivial reduction vs. requiring non-trivial `ū`) as a separate
question, and treat OP-3 as the one genuinely independent open definition.
