# Deep Think brief — state, open decisions, recommendations with rationales

**To:** Google DeepMind Deep Think, via the programme owner. **From:** Fable (red team /
derivation), MechanicaFluidorum. **Date:** 2026-09-12. **Self-contained**: no prior packet
required. Every number below is kernel-verified or exact-arithmetic; where something is
unproved, it says so.

---

## 0. What the programme is, in five lines

Target: **Hypothesis U** — a bound on the enstrophy of the frequency-truncated 3-D Navier–Stokes
system that is **uniform in the truncation** `M`. The specification identifies the programme's
dual-scale regularization with the sharp projection onto `|k| ≤ 1/√α′`, so the Galerkin system
**is** the regularized system under `M ↔ 1/√α′`, and Hypothesis U is uniformity in `M` and
nothing else. Standing obstruction **O5**: at fixed `M` the system is regular by an elementary
argument, so any result whose constants depend on `M` proves nothing about the limit. Everything
is gated: Tier A = Lean 4 kernel with `#print axioms` clean, Tier B = exact rational/integer
arithmetic with a negative control demonstrated to fail, floats quarantined.

## 1. What is established (Tier A unless marked)

**The fixed-`M` ledger is closed.** For the Leray-projected truncated nonlinearity `B`:

- **Energy conservation**: `Re Σ_k ⟨u_k, B(u,u)_k⟩ = 0`, every `M`, no smallness or genericity.
  It is an *instantiation* of a two-swap identity (`swap3` fixes the index carrying the
  gradient; the 3-cycle cannot close, which is why an earlier attempt stalled for two weeks).
- **The weighted triad identity** — one theorem containing both conservation questions. For any
  weight `w` on the triad's third member, given only divergence-freeness at `p`:
  `w_summand(p,q) + w_summand(swap3(p,q)) = (w(r) − w(q))·(k_q·u_p)(u_q·u_r)`.
  Constant `w` ⟹ energy conservation (derived *from* this, not asserted as analogy).
- **The enstrophy production, exactly**: with `w = |·|²`,
  `2 Σ_k |k|²⟨u_k,B_k⟩ = −i Σ_{triads} (|r|²−|q|²)(q·u_p)(u_q·u_r)`.
  **The entire obstruction is the single factor `|r|²−|q|²`**: a triad transfers enstrophy in
  proportion to the wavenumber disparity of its two swapped members, and none if they share a
  sphere. Non-vacuity checked on a genuine Galerkin state (Tier B, exact Gaussian rationals):
  energy production exactly `0`, enstrophy production `−18`, closed form matching.
- **The viscous balance laws**: energy cannot rise; the enstrophy balance is dissipation against
  that production. **Nothing bounds the production against the dissipation uniformly in `M`** —
  that sentence is in the theorem's own docstring, because it is the whole open problem.
- **The helical decomposition, and three deflations.** Waleffe resonance is *exactly*
  collinearity (proof never mentions `ℤ³` — it is the triangle inequality), so the "arithmetic
  rigidity of the lattice" contributes nothing there; the coefficient's closed form has a
  **converse** (ℂ has no zero divisors), so the inventory of inert triads is complete and has
  two members; and a previously claimed cancellation mechanism was **retracted** after a gauge
  analysis showed it spliced two incompatible gauges.

## 2. What the last three days actually found: a symmetry kernel

The adjudicated attack is **phase mixing**: show the production sum cancels for generic states
faster than a random-phase null. A pre-registered exact measurement was built (ℓ¹ cancellation
ratio, exact rationals — the sum is polynomial in the amplitudes, so no float is needed;
deterministic families; 20 seeded nulls; a **coherence control** required to pass before
anything is interpreted).

**The coherence control tripped three times. Each trip became a theorem.**

| trip | family | result | mechanism |
|---|---|---|---|
| 1 | real phases | exactly 0 | **parity**: real + conjugate-symmetric ⟹ `u(−k)=u(k)`; terms cancel pairwise under negation (**Tier A**) |
| 2 | tilted phase, one director | exactly 0 | **C-DIR**: the six orderings of a triad collapse to `2c³·det[a,b,d]·E`, and `Σ_{triads of ball} det·E ≡ 0` **in `d`** — by invariance of the ball under the cubic point group (Tier B exact at `M=2,3`; reduction and group action **Tier A**; the cubic-coefficient step is an open Lean obligation) |
| 3 | tilted phase, varied directors | at the null, then far below | **the X-reduction**: trilinearity + the always-(2,1) conjugate split + `t(−p,−q) = −conj t` force **any** single-phase family to `T = 2i·Im(cX)` for one `c`-independent `X`. Verified exactly: `X` from two tilts predicts a third to the last digit; `X` purely real at both `M` |

Also exact and now asserted on every run: `Re(Σ terms) = 0` for **every** conjugate-symmetric
state — which is precisely why the physical production is real.

**Diagnosis.** The observable is trilinear, so every single-phase family collapses onto one
geometric lattice number; the registered control-family *class* was structurally incapable of
certifying coherence. Corollary: the ratio is invariant under any global phase, so "coherence"
for a trilinear observable can only mean **relative** phase structure across modes.

**Standing lesson, three for three:** in this system an unexplained exact zero is a symmetry not
yet found, and it must be found before anything else is believed. Any "massive cancellation"
claim must first prove its test states lie **off** the symmetry kernel.

## 3. The external formal landscape, audited

A public Lean 4 development (OpenAI, `NavierStokesAndEuler@8937a8f`, Lean 4.34.0-rc2) proves the
**negative** directions: forced NS breakdown on `ℝ³` and `𝕋³` (Clay options C/D, force built as
the residual of a pre-constructed singular candidate), and unforced Euler blowup for a
constructed compact smooth datum with a quantitative singularity package. Audited here under our
own rules before citing anything: full rebuild (517 modules, 0 errors), then footprints on the
four headline theorems — **all exactly `[propext, Classical.choice, Quot.sound]`** — with a
built-in negative control (their four intentional challenge placeholders, adapted from
DeepMind's `formal-conjectures` statements, **must and do** show `sorryAx`) and an import scan
proving the proof tree never touches the placeholder modules.

**One structural caveat.** Placeholder and proof share fully-qualified names in modules that can
never be co-imported, so equivalence of the proved statements to the challenge statements is a
**human side-by-side audit, not a kernel fact**. We would value DeepMind's view on this, since
the challenge statements are yours.

**The asymmetry is the point**: everything verified there concerns constructed data or
manufactured forces. Nothing touches Statement A, global regularity, or uniformity.

## 4. Decisions open, with recommendations and rationales

### D-1. The observable: redesign or abandon? *(the live gate)*

**Recommendation: redesign, with two changes at once — chirp phases and windowed ratios — and
treat a fourth trip as decisive against the observable.**

*Rationale.* The three trips diagnosed a real defect of the *family class*, not of the idea that
cancellation carries information: a trilinear form cannot be probed by a one-parameter phase.
Chirp phases `c(k) = c₀^{|k|²}` (rational circle point to an integer power — exact) give genuine
**relative** phase structure, which is the only thing a trilinear observable can see; windowing
the ratio to triads whose third member lies in one shell prevents a global symmetry from
swamping local structure, and the null localises with it. Both are cheap and exact. The cost of
being wrong is one run.

*What would change my mind:* if Deep Think can show a priori that the production sum's symmetry
group forces `ρ` to the null for **every** deterministic family, the observable is dead and we
should go straight to evolved-state ensembles (expensive, needs a Rust exact port, but
physically honest).

### D-2. The strategic target: is phase mixing still the right track?

**Recommendation: keep it, but re-aim it at the disparity factor specifically, and set a
decision point.**

*Rationale.* The obstruction is now localised to `(|r|²−|q|²)` — that is unusually sharp for
this problem, and it is what a mixing argument would have to defeat. But two of the four
originally proposed tracks are already dead (geometric depletion died with
resonance = collinearity; the lattice contributes nothing to that), and mixing is the only one
with a Lean-reachable foundation. **The honest risk:** we have found three mechanisms that make
the sum vanish *for symmetry reasons*, and zero evidence so far of cancellation beyond symmetry.
That asymmetry should be named, not smoothed over.

*Question for Deep Think:* given the production is exactly
`Σ (|r|²−|q|²)(q·u_p)(u_q·u_r)` over lattice triads, **is there a known equidistribution or
oscillatory-sum technique that bounds such a form sub-linearly in the ball radius**, and does
any of it survive the fact that the same sum is annihilated by the cubic point group on
structured states? If the answer is "no known technique", that is decision-grade information and
we would rather have it now.

### D-3. The open Lean obligation

**Recommendation: formalise the cubic-coefficient step of C-DIR, at low priority.**

*Rationale.* The reduction (R1) and the group action are already Tier A; what remains is that a
cubic form in the director, equivariant under signed permutations with the determinant sign, is
zero. It is a clean finite-group argument, it would close A1 completely, and it is the kind of
lemma that will recur every time a symmetry stratum is found. Low priority because it certifies
something already exact at Tier B and does not unblock anything.

### D-4. The external results

**Recommendation: adopt as Tier L context with the naming caveat attached, and cite them for
exactly one thing — that the negative directions are now machine-checked territory.**

*Rationale.* They are genuinely kernel-clean, and they sharpen our framing: the open problem is
precisely the uniformity we have isolated. They must never be cited as bearing on Statement A.

## 5. What we are not asking

We are not asking for a proof strategy to be handed over, and we will not formalise anything
whose statement we cannot audit. If the most useful answer is "this track is a dead end for the
following reason", that is the answer we want, and the programme's record — three retracted
narratives, three symmetry artifacts caught, one wrong closed form found by its own crucible —
should make credible that we will act on it.
