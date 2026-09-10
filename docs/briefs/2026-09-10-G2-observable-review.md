# G2 review packet — the coherence control has tripped three times, each time with a proof

**To:** the owner, and Deep Think. **From:** Fable, 2026-09-10. **Gate:** G2 of the
symmetry-quotient workflow ("if the amendment-5 coherence control trips a third time, the
observable itself is suspect — redesign or abandon"). It tripped. This packet is the review
material; per the pre-registration, **nothing further is run until this gate decides.**

## 1. The three trips, and what each proved

The cancellation observable is `ρ(M) = ℓ¹(T)/Σℓ¹(terms)` for the kernel-checked production sum
`T`. The coherence control requires some deterministic aligned family to show `ρ` well above the
random-phase null — else the observable cannot distinguish coherence from noise.

| trip | family | result | mechanism, proved |
|---|---|---|---|
| 1 | all-real phases, constant director | exactly 0 | parity: real + conjugate-symmetric ⟹ `u(−k)=u(k)`, terms cancel pairwise under negation (**Tier A**, `production_terms_eq_zero_of_even`) |
| 2 | tilted phase, constant director | exactly 0 | **C-DIR**: `Σ_triads det[a,b,d]·EXPR ≡ 0` in `d`, by cubic-group equivariance of the ball (exact for `M=2,3`; general-`M` proof recorded; Lean target L-DIR) |
| 3 | tilted phase, **varied** directors (amendment 5) | at the null (`M=2`), far **below** it (`M=3`: `0.0002` vs `0.0170`) | **the X-reduction**: for ANY single-phase family, `T = 2i·Im(c·X)` with one `c`-independent number `X`; verified exactly by predicting a third tilt from two; `X` real at both `M` |

## 2. The diagnosis, in one sentence

**The observable is trilinear, so every single-phase family collapses onto a single geometric
lattice number — the control-family CLASS was structurally incapable of certifying coherence,
independent of directors, moduli, or the phase chosen.** Three different symmetry/structure
mechanisms produced the three zeros; none of them says anything about phase mixing.

A corollary worth naming: `ρ` is invariant under any global phase (`T(cu) = c³T(u)` scales
numerator and denominator alike), so "coherence" for this observable can only mean **relative**
phase structure across modes — which single-phase families do not have.

## 3. Redesign candidates, for decision (not yet run; costs are per-run on the current exact instrument)

1. **Chirp families**: phase `c(k) = c₀^{k_sq k}` (powers of a rational circle point — exact).
   Deterministic, genuinely multi-phase, the classic constructive-interference candidate for a
   trilinear form; the triad phase becomes `c₀^{±(…)}` with exponent the weight itself, so the
   family is *aimed at* the observable's kernel structure rather than at a symmetry stratum.
2. **Two-phase interference families**: phase `c` on one shell class, `c′` on the rest;
   scanning the relative phase `c′/c̄` sweeps the interference explicitly and the control
   criterion becomes "the sweep shows a visible fringe", which no single number can fake.
3. **Windowed / per-shell `ρ`**: localize the cancellation ratio to triads with `r` in one
   shell; symmetry strata that kill the global sum need not kill windows, and the null
   comparison localizes with it.
4. **Abandon `ρ` for evolved states**: measure `|T|` against the dissipation sum on states
   produced by a few exact steps of the Galerkin dynamics from structured data — the physically
   honest ensemble, at real computational cost (each step is a full convolution; Rust port
   first).

My recommendation, for what it is worth at a gate that is yours: 1 + 3 together (both exact,
cheap, and aimed at the diagnosis), with 4 as the eventual replacement once the Rust port
exists. Candidate 2 is the most informative per run but needs a registered sweep protocol.

## 4. What stands regardless of this gate

The three trips produced three permanent results — the parity theorem (Tier A), the C-DIR
identity (Tier B exact, Lean target registered), and the X-reduction (exact, twice verified) —
plus a hardened instrument whose regression rows now *assert* the first two identities on every
run. The F2/F3 interpretation quarantine stands until a redesigned control passes. And the
standing lesson is now three-for-three: **in this system, an unexplained exact zero is a
symmetry you have not found yet, and it must be found before anything else is believed.**
