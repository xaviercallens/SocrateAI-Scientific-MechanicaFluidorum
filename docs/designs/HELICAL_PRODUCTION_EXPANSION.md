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

## 5. Implementation order

1. `tests/tier_b_helical_production_expansion.py` — I1, I2, controls. **Done with this memo.**
2. Lean, `HelicalBasis` §14: I1 (`fourier_dot q (hOf N s p) = |N|²` under the triad frame) and
   I2, plus the assembled per-triad expansion; negative controls on scratch copies.
3. `tests/tier_b_production_cancellation.py` — the §4 measurement, families F1–F3, nulls first.
4. Only after 3: any statement about cancellation, and only in the words the nulls license.

**What this memo does not claim.** No bound, no uniformity, no mechanism — only an exact
re-expression, four structural facts, and a measurement design. SPEC obstruction O5 stands until
a theorem says otherwise.
