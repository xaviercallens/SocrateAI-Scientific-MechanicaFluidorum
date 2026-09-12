# Design memo — WP-1c: the enstrophy production sum in the helical basis, and the pre-registered phase-mixing measurement

**Status:** derivation memo, written before any Lean per standing practice. Ordered by the
Orchestrator's adjudication of 2026-09-10 (`DECISION_2026-09-10_openai_leverage_adjudication.md`),
Q3 ("phase mixing via transversality is the only live track") and Next Step 2 ("expand the exact
enstrophy production sum in the helical basis; establish the baseline exact arithmetic properties
of this sum on finite Galerkin balls"). **Author:** Fable. Identities I1–I2 below are verified in
exact integer arithmetic with negative controls before being written here.

---

## 1. The object

From `enstrophy_production_identity` (Tier A), for every Galerkin state:

```
    2 P  =  −i · Σ_{(p,q) ∈ triadSet M}  ( |r|² − |q|² ) · (q·u_p) · (u_q ·_bil u_r) ,   r = −(p+q).
```

Two remarks fix the ground rules of everything below.

**The production sum is polynomial — no square roots.** Unlike the triad *coefficient* of the
Waleffe analysis, `P` involves only `|r|² − |q|²` (integers) and bilinear dots of amplitudes. So
every baseline measurement of §4 can be **exact rational, Tier B, floats banned** — there is no
numerical-precision escape hatch for an artifact to hide in.

**Gauge legitimacy, settled for this use.** Each term `(q·u_p)(u_q·u_r)` never mentions a helical
basis: it is gauge-free as written. The expansion below evaluates each term in **its own triad's
frame** `N = p × q` as a computational device. This is exactly the move that §6bis of the Waleffe
memo left unjustified — and the distinction that makes it legitimate here is that *nothing below
adds terms expressed in different frames*: the frame enters and leaves within a single gauge-free
term. The retracted item 4 failed because a **cross-triad** cancellation claim silently compared
phases across gauges. Any phase-mixing claim in §4 must respect the same line.

## 2. The two frame factors (verified exactly; Lean targets L1, L2)

In the triad's own frame, with the unnormalised basis `h^s(x) = N×x + i s|x| N` of
`HelicalBasis.hOf`:

> **I1.**  `q · h^{s_p}(p) = |N|²` — **independent of the chirality `s_p`.**
> *(Proof: `q·(N×p) = N·(p×q) = |N|²` and `q·N = 0`.)*
>
> **I2.**  `h^{s_q}(q) ·_bil h^{s_r}(r) = |N|² [ (q·r) − s_q s_r |q||r| ]`.
> *(Proof: `(N×q)·(N×r) = |N|²(q·r)` since `N ⊥ q, r`; the cross terms die on `(N×·)·N = 0`;
> the imaginary parts contribute `−s_q s_r|q||r||N|²`.)*

Both verified on 5 triads × all chiralities, exact integers, with two negative controls confirmed
to fail (perturbed frame breaks I1; `|q|²` in place of `|q||r|` breaks I2):
`tests/tier_b_helical_production_expansion.py`.

## 3. The expansion, and what it says

Write `u_x = A_+(x) h^+(x) + A_−(x) h^−(x)` per triad in its own frame (legitimate for
non-collinear triads, where `h^±` span the transverse plane at each member; collinear triads
contribute nothing — Tier A). Substituting I1–I2, the production term of the triad, for
amplitudes `A`, is:

```
  (|r|²−|q|²) · |N|⁴ · [A_+(p) + A_−(p)] ·
        {  (q·r) · [A_+(q)+A_−(q)][A_+(r)+A_−(r)]  −  |q||r| · [A_+(q)−A_−(q)][A_+(r)−A_−(r)]  }
```

Structural content, stated as algebra and nothing else:

1. **The stretched leg's chirality is invisible.** The `p` slot couples only to the
   chirality-*blind* combination `A_+ + A_−` (I1's `s_p`-independence). Whatever selection the
   helical decomposition performs, it performs none through the leg that carries the gradient.
2. **The `(q,r)` slot splits into a blind part and an odd part.** The blind part is weighted by
   the geometry `(q·r)`; the chirality-*odd* part `[A_+−A_−][A_+−A_−]` is weighted by `|q||r|`
   and is the only place handedness enters the production at all.
3. **Vanishing is collinearity, again.** The brace vanishes for all amplitudes iff
   `(q·r) = ±|q||r|` — collinearity — consistent with every previous deflation; no new inert
   class appears in the helical variables.
4. **Square roots enter only through the odd part.** The blind sector of the production is
   entirely rational; irrationality (hence any genuinely Diophantine phenomenon on `ℤ³`) is
   confined to the chirality-odd channel via `|q||r|`. If the lattice contributes anything the
   continuum does not, this is the only door left for it — a sharp, checkable localisation.

## 4. The pre-registered baseline measurement (LL-11: nulls before interpretation)

**Quantity.** The cancellation ratio on the ball, exact rational:
`ρ(M) = |Σ terms| / Σ |terms|` for the production sum of `enstrophy_production_identity`, and the
raw growth `|P(M)|`, on `M = 1 … M_max`.

> **Pre-registration amendments (2026-09-10, recorded BEFORE the first run).** Three details of
> this section as first written would have required irrational quantities, violating the Tier B
> float ban. Amended as follows, each replacing the original for all runs:
>
> 1. **The modulus is `ℓ¹` on components**: `|z| := |Re z| + |Im z|`, exact rational. (The
>    Euclidean modulus is a square root.) `ρ` is therefore the `ℓ¹` cancellation ratio; the
>    comparison across families is unaffected, since one norm is used everywhere.
> 2. **Random phases are rational points of the unit circle**: `e^{iθ} → ((1−t²) + 2ti)/(1+t²)`
>    with `t` drawn from a seeded deterministic generator over rationals in `(−1, 1]` — exact
>    unit modulus, no floats.
> 3. **F3's spectral decay is in `k_sq`, not `|k|`**: modulus `∝ (k_sq k)^{−γ}` with
>    `γ ∈ {0, 1, 2}` (equivalently `|k|^{−β}`, `β ∈ {0, 2, 4}`), replacing the original
>    `β ∈ {1, 3/2, 2}` whose odd values are irrational on the lattice.
>
> One free integrity check is also registered: under `swap3` each production term maps to
> **itself** (the weight difference and the divergence-free contraction each flip sign), so the
> harness asserts `t(swap3(p,q)) = t(p,q)` termwise, exactly.

**State families, fixed in advance** (all conjugate-symmetric, divergence-free, zero-mean, by the
`u_k = k × a_k`, `a_{−k} = −conj(a_k)` construction of `tier_b_fourier_enstrophy.py`):

- **F1 coherent** — all seed amplitudes real positive, deterministic;
- **F2 random-phase null** — same amplitude moduli, phases from a seeded deterministic PRNG,
  ≥ 20 seeds; *this is the null model, and no claim about F1 or F3 is interpretable except
  against it*;
- **F3 equipartition-decay** — amplitudes `∝ |k|^{−β}` for pre-registered `β ∈ {1, 3/2, 2}`,
  phases from F2's generator.

**The phase-mixing hypothesis, falsifiably stated.** Transversality forces `ρ(M)` of F3 states to
decay with `M` at least as fast as the F2 null's; equivalently the coherent-sum growth of `P(M)`
is sub-linear in a sense to be READ OFF THE NULL, not assumed. Pre-registered failure modes: if
F1 ≈ F2 ≈ F3, the ratio measures nothing state-specific (artifact, LL-11); if F3 decays *slower*
than F2, phase mixing is refuted for this observable and the adjudication's track loses its first
empirical support.

**Guards.** Exact arithmetic throughout (the sum is polynomial, §1); every family deterministic
and seeded; negative controls: a state built to defeat mixing (phases aligned along a coherent
ray) must show `ρ` near 1, or the instrument cannot detect coherence and measures nothing.

> **First-run outcome (2026-09-10) — THE INSTRUMENT CONTROL TRIPPED, and the trip is a
> theorem.** F1's ratio came out `0.0000` at `M = 2, 3` — the coherent family shows *perfect*
> cancellation, the opposite of coherence. Mechanism, identified and then proved: all-real
> amplitudes combined with conjugate symmetry make the state **parity-even** (`u_{−k} = u_k`),
> and then the production terms cancel **pairwise under global negation** — the weight and the
> bilinear factor are even, the divergence contraction is odd. Kernel-checked the same day as
> `FourierDynamicsZ3.production_terms_eq_zero_of_even`. This is the same negation-symmetry
> family as the Waleffe §6bis per-class zero: a symmetry artifact, carrying no information
> about mixing.
>
> **Consequences, per the registration's own rules:** (i) the F2/F3 comparisons of the first
> run are **quarantined from interpretation** — the coherence control did not pass, so the
> observable has not yet demonstrated it can detect coherence; (ii) **amendment 4, recorded
> before the second run**: the coherent family is replaced by **F1′ — one fixed non-real
> phase** `c = ((1−t²)+2ti)/(1+t²)`, `t = 1/3`, applied to every half-ball mode. `c ≠ ±1`
> breaks the parity degeneracy while keeping all phases aligned, which is what "coherent" was
> meant to mean. F1's original numbers remain reported.
>
> **Second-run outcome (2026-09-10) — F1′ is ALSO exactly zero, and two more exact facts.**
> Checked at full precision, not off the 4-place display:
>
> 1. **`Re(Σ t) = 0 exactly, for every state tested — including every random-phase seed.**
>    Mechanism, derived and then checked termwise: for ANY conjugate-symmetric state,
>    global negation sends each term to **minus its own conjugate**
>    (`t(−p,−q) = −conj(t(p,q))`: the weight is even, the divergence contraction picks
>    `−conj`, the bilinear factor conjugates). So the real part cancels pairwise, always —
>    which is also exactly *why* the physical production `2P = −i·Σt` is real. Promoted to a
>    harness **integrity assertion** on every measured state.
> 2. **F1′'s sum is exactly zero at `M = 2, 3`, and parity does not explain it** — the tilted
>    phase breaks that symmetry. The suspect is a SECOND degeneracy of my construction: every
>    amplitude uses the **same director** (`a_k ∝ d` with one fixed `d`), so `u` is a
>    gradient-cross-director field (`u = ∇g × d`), velocity everywhere perpendicular to a
>    fixed direction — a quasi-planar class for which the production may vanish identically.
>    **Open**: mechanism unproved; hypothesis registered before any further run as
>    **amendment 5** — the next run must use `k`-dependent directors
>    (`d(k) = (1,2,3) + (k₂,k₃,k₁)`-type, with the parallel-degeneracy fallback), for ALL
>    families, F2/F3 included, so that no family owes its behaviour to the director artifact.
>
> **A1 RESOLVED (2026-09-10, same day) — the mechanism is cubic-group equivariance, and the
> quasi-planarity suspicion was WRONG in an instructive way.** Full detail:
> `tests/tier_b_director_stratum.py`. Four exact results:
>
> 1. **The director term factorizes**:
>    `t(p,q) = −W · c_p c_q c_r · det[p,q,d] · [(q·r)|d|² − (q·d)(r·d)]`.
> 2. **The six orderings of one triad sum to** `2 c_a c_b c_c · det[a,b,d] · EXPR` with
>    `EXPR = 2(a·d)(b·d)(B−A) + (b·d)²(B−C) + (a·d)²(C−A)` — the `|d|²` part cancels
>    identically (a clean `A,B,C` identity), so **all `d`-dependence is through the two
>    contractions**.
> 3. **`EXPR ≢ 0`: the stratum does NOT vanish per-triad**, and random-phase director states
>    have genuinely nonzero production (the F2 seeds are the standing witnesses). So
>    quasi-planarity does *not* kill production — the suspicion in item 2 above is refuted.
> 4. **C-DIR**: `Σ_{triads(ball M)} det[a,b,d]·EXPR = 0` **identically in `d`** — proved for
>    `M = 2, 3` by computing all ten coefficients of the cubic form exactly, and for **every**
>    `M` by equivariance: the ball is invariant under signed permutations `σ`, and
>    `Σ(d) = det(σ)·Σ(σᵀd)`; each axis reflection forces every monomial odd in that variable,
>    leaving only `d₀d₁d₂`, and any transposition kills that. **The double control trip is
>    hereby fully explained**: an aligned-phase family on any constant director is annihilated
>    by the lattice's own point symmetry — coherence collapses the sum onto `Σ det·EXPR`,
>    which the cubic group kills. Controls: flipping one sign inside `EXPR` breaks it, and
>    removing a single point from the ball breaks it — the symmetry is load-bearing.
>
> **Lean target L-DIR registered**: formalise C-DIR via the signed-permutation action on
> `ball M` (the equivariance proof above is finite-free and kernel-ready in outline).
> **Amendment 5 stands**, now with a proof of necessity: no constant-director coherent family
> can ever pass the coherence control.
>
> **Third-run outcome (2026-09-10) — THE THIRD TRIP, and gate G2 fires.** The amendment-5 run
> (varied directors for all families; constant-director rows retained as exactness
> regressions, which passed): the varied-director tilted-coherent control `F1v′` came out **at
> the null at `M = 2`** (`0.0360` vs null `0.0364`) and **far below the null at `M = 3`**
> (`0.0002` vs `0.0170`). Per the registered failure mode, this is the third trip and the
> observable goes to owner + Deep Think review (`G2`), packet:
> `docs/briefs/2026-09-10-G2-observable-review.md`.
>
> **And the trip has a proof — the X-reduction.** By trilinearity, the always-(2,1) class
> split, and the negation law `t(−p,−q) = −conj t`: for ANY single-phase family (phase `c` on
> the half-ball, forced conjugates opposite), `T(u(c)) = c·X − conj(c·X) = 2i·Im(c·X)` for
> **one** complex number `X(M, directors, moduli)` independent of `c`. Verified exactly:
> solving `X` from two tilts predicts the third tilt's sum to the last digit at `M = 2, 3` —
> and `X` came out **purely real** at both (`−1608`, `2928`), so `T = 2i·Im(c)·x(M)`.
> **Consequence: the coherence-control design class was structurally too thin.** A
> single-phase family can only ever measure the single lattice number `x(M)`; it cannot
> certify that the observable detects coherence, with any director scheme. The redesign
> candidates are in the G2 packet; nothing further is run until G2 decides. The F2/F3
> quarantine stands.
>
> **FOURTH RUN (2026-09-12) — THE CONTROL PASSES, AND WHAT IT DETECTS KILLS THE TRACK.**
> Executed on the Deep Think adjudication's D-1 order. `tests/tier_b_adversarial_alignment.py`,
> exact integers and rationals, range extended to `M = 4` as registered amendment 6 (two points
> cannot establish a trend, and the trend is the decision-relevant quantity).
>
> The registered redesign candidate **chirp phases failed** — `ρ` at or below the null at every
> `M` (`0.0150`, `0.0177`, `0.0056`). Recorded as a failed candidate, not quietly dropped.
>
> What worked is the direct test of Deep Think's *stated mechanism*. Purely imaginary amplitudes
> make the state **parity-odd** — the exact complement of the proved parity stratum, so that
> theorem cannot apply — and then every production term reduces to
> `t = −i·b_p b_q b_r·G_int(p,q)` with `G_int` an **integer**. The cancellation ratio becomes a
> pure integer optimisation over sign vectors, exactly searchable. Greedy alignment gives:
>
> | `M` | null | adversarial | ratio | random-sign control |
> |---|---|---|---|---|
> | 2 | 0.0364 | **0.1545** | 4.2× | 0.0517 |
> | 3 | 0.0170 | **0.1920** | 11.2× | 0.0284 |
> | 4 | 0.0083 | **0.2355** | 28.4× | 0.0083 |
>
> Each adversarial state was verified divergence-free, conjugate-symmetric and zero-mean,
> exactly. **The trend is the decisive part**: the null's cancellation *improves* as the ball
> grows (halving each step) while the adversarial state's *does not* — it rises. Random signs in
> the same construction stay at the null, so the search measures something real.
>
> **Reading.** After three trips the coherence control finally passes, and what it detects is
> that coherent states defeating the cancellation exist at every truncation tested, with the gap
> widening. Deep Think's mechanism is **exhibited, not merely argued**: this is positive
> evidence, not absence of evidence. **Kinematic phase mixing is dead** — see the LEDGER record.
> The F2/F3 quarantine is lifted only in the sense that the observable is now understood; the
> track it was built to serve is closed.
> 3. **Parity is now Tier A**: for parity-even states (`u(−k) = u(k)`), the production term
>    sum vanishes identically — `FourierDynamicsZ3.production_terms_eq_zero_of_even`, proved
>    by the negation involution.
>
> **Standing interpretation quarantine.** Until a run under amendment 5 passes the coherence
> control, none of the F2/F3 numbers may be read as evidence about phase mixing, in either
> direction. What the instrument HAS delivered so far is three exact structural facts about
> the production sum, two with proofs — which is the programme working as designed, and a
> warning received twice now: **the production sum has a large kernel of symmetry-degenerate
> states, and any mixing claim must first show its test states are outside it.**

## 5. Implementation order

1. `tests/tier_b_helical_production_expansion.py` — I1, I2, controls. **Done with this memo.**
2. Lean, `HelicalBasis` §14: I1 (`fourier_dot q (hOf N s p) = |N|²` under the triad frame) and
   I2, plus the assembled per-triad expansion; negative controls on scratch copies.
3. `tests/tier_b_production_cancellation.py` — the §4 measurement, families F1–F3, nulls first.
4. Only after 3: any statement about cancellation, and only in the words the nulls license.

**What this memo does not claim.** No bound, no uniformity, no mechanism — only an exact
re-expression, four structural facts, and a measurement design. SPEC obstruction O5 stands until
a theorem says otherwise.
