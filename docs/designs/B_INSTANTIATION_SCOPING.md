# Scoping memo: instantiating `B` with the real Navier–Stokes nonlinearity

**Status:** Tier C scoping draft. **Does not unblock anything by itself** — per PLAN.md's E-1
rule ("DO NOT invent a mathematical definition or theorem statement... STOP and escalate"),
this document is input to a human decision, not a Lean-ready specification. Nothing here may
be cited as a claim or implemented by an agent until the human owner picks among the options
below (or supplies a different one).

**Author:** orchestrator (top-tier authoring). **Requested:** 2026-08-13, as a deliberate
scoping-only task (distinct from implementation) after the earlier recommendations menu.

## Why this needed research before any option-drafting

`lean_src/HypothesisU_Statements.lean`'s own docstring already flags this precisely: *"The
true 3-D Navier–Stokes nonlinearity is NOT written here; instantiating `B` with it is
deferred, and that instantiation is where the entire mathematical content of the program
resides. Inventing a specific convolution at this point is banned by PLAN.md rule E-1."* I
searched the repo (SPEC.md, `docs/HYPOTHESIS_U_SPECIFICATION.md`, every `docs/designs/*`,
`docs/ROADMAP_6_MONTHS.md`, and the prior tree) before writing anything below. Finding: **no
Fourier/triad convolution formula for the nonlinearity exists anywhere in this program's
sanctioned content.** T0.1/T0.2's triad work (`data/triads_free.csv`) counts lattice points
`k₁+k₂=k₃`, `|kᵢ|²≤M²` with no amplitudes or coefficients — pure combinatorics, not a
convolution. OP-2's own draft (`docs/designs/TRACK_DEFINITIONS_DRAFT.md`) self-admits its
shell-index embedding "throws away the angular structure of `k`, which is precisely where
3-D vortex-stretching geometry lives" — i.e. it explicitly cannot supply this. The dyadic
shell model's `NL_n` (`EnstrophyProduction.lean`) is never asserted to derive from or
approximate `(u·∇)u` — every place it's mentioned it is called "morally" `k_n²`-weighted, a
Katz–Pavlović toy model borrowed from the turbulence literature, not derived from the PDE.
**This is a bona fide E-1 blocker, same class as OP-2…OP-5**, not a gap fillable from
existing repo content.

## The actual mathematics, for scoping purposes (NOT yet Lean-ready)

On `𝕋³ = (ℝ/2πℤ)³`, write `u(x,t) = Σ_{k∈ℤ³} û_k(t) e^{ik·x}`, divergence-free ⟺ `k·û_k = 0`,
real-valued ⟺ `û_{-k} = conj(û_k)`. With the Leray projector `P(k) := I − (k⊗k)/|k|²`, the
Fourier-Galerkin-truncated Euler/NS nonlinearity:

```
∂ₜ û_k = −ν|k|² û_k − i Σ_{p+q=k, p,q∈Λ} P(k)[ (q · û_p) û_q ]
```

**ERRATUM (2026-08-13, caught by the Tier B harness below, not by inspection — recorded
honestly per this program's own "an agent's self-report is not evidence, re-verify"
discipline):** the formula first written here, sourced from a single web-search cross-check
against arXiv:2604.12188 (`q (û_p · û_q)` — the wavevector `q` times the scalar
velocity-velocity dot product), was **wrong**. `tests/tier_b_nse_triad_convolution.py` proved
in exact arithmetic that formula is identically zero for every `k`, on every field and
truncation tested: `P(k)` annihilates anything parallel to `k`, and because every pair `(p,q)`
with `p+q=k` appears alongside its swap `(q,p)` in the same sum, the two terms are exact
negatives (`P(k)[q·s] + P(k)[p·s] = P(k)[(p+q)·s] = P(k)[k·s] = 0`), so the whole sum
telescopes to zero — clearly not the real (nonzero) NSE nonlinearity. This was very likely a
search-summarizer transcription artifact, not an error in the underlying arXiv source, but
that was never independently confirmed either way — exactly the risk the "not yet verified"
caveat (previously here) existed to flag. The corrected formula above, `(q · û_p) û_q` (`q`
DOTTED with the velocity `û_p`, a scalar, times the velocity vector `û_q`), matches the
standard Fourier transform of the convective derivative `(u·∇)u`, is nonzero, and is now
checked in exact arithmetic (Fact 1 unconditionally; Fact 2 — energy conservation — verified
computationally at `M=1,2,3`, not yet proven symbolically in general — see the harness file's
own docstring for the honest scope of what's proven vs. computationally confirmed).
```

**Why this is a much bigger step than "instantiate one function," and why option-drafting
(not implementation) is the right scope for this task:**

1. **The state representation itself must change.** `HypothesisU_Statements.lean`'s `u : ℝ →
   ℕ → ℝ` is a single REAL scalar sequence indexed by `ℕ` (one shell/mode index). The formula
   above needs `û : ℝ → ℤ³ → ℂ³` (complex, vector-valued, indexed by the full 3-D lattice),
   subject to two side constraints (`k·û_k=0`, `û_{-k}=conj(û_k)`) that have no analogue in
   the current framework. `B`'s TYPE (`ℕ → (ℕ→ℝ) → ℝ`) cannot literally hold this — this is a
   restructuring of the whole formal object, not a substitution into the existing slot.
2. **No sanctioned bridge exists** from the program's current `ℕ`-indexed shell abstraction to
   genuine `ℤ³` wavevectors (this is precisely what OP-2 was blocked on, for the same
   underlying reason: a genuine embedding of shell/recursion structure into `ℤ³` geometry does
   not exist in this program or, per OP-2's own draft, "to my knowledge, in the literature").
3. **Sign/normalization conventions vary by source** and must be pinned down by hand against
   one fixed, cited reference before any Lean commitment — this program has been burned before
   by citing from memory (LL.md; the Barbato–Morandin–Romito citation was WebFetched and found
   narrower than a from-memory citation would have implied).

## Decision points for the human owner (not decided here, per E-1/E-4)

**D1 — Scope of the restructuring.** Do the full `ℤ³`-indexed complex-vector reindexing (the
"honest" version, matching real NSE, but a multi-session undertaking that likely obsoletes
much of `HypothesisU_Statements.lean`'s current shape), or seek a smaller, provably-legitimate
*reduced* proxy that keeps the current `ℕ`-indexed shape (e.g. a genuine multi-shell
generalization of the dyadic model that at least captures triad *counting* structure via
T0.1/T0.2's existing tooling, while still not claiming to be the real 3-D nonlinearity)?

**D2 — Sequencing.** Should `B`'s instantiation be attempted before or after OP-2's embedding
question is resolved? They are related (both need a shell↔`ℤ³` bridge) — solving one may solve
or simplify the other, or they may turn out to need genuinely different embeddings for
different purposes (OP-2 is about Sym²-lock resonance filtering; `B` is about the literal PDE
nonlinearity). Worth deciding whether to unify or keep separate.

**D3 — Right-sized first deliverable. DONE 2026-08-13.** `tests/tier_b_nse_triad_convolution.py`
(wired into `scripts/verify.sh` Gate 1) — a standalone Tier B exact-arithmetic harness
certifying transversality (`k·N(û)_k=0`, unconditional) and detailed energy conservation
(`Σ_k conj(û_k)·N(û)_k=0`, given divergence-free + conjugate-symmetric input) of the corrected
formula above, at `M=1,2,3`, with two negative controls (drop Leray projection; break
divergence-free on one mode) confirmed to fail exactly as the hand derivation predicts —
**and it caught the erratum above**, which is exactly the kind of concrete, auditable artifact
this deliverable was meant to produce before committing to D1's larger choice.

## What this memo does NOT do

No change to `lean_src/HypothesisU_Statements.lean`. `B` is not instantiated there and no
ledger row claims it is. D3's Tier B harness (above) is a standalone artifact about the
Fourier-triad convolution formula's own structural properties — it does not touch, and does
not by itself unblock, `HypothesisU_Statements.lean`'s abstract `B` parameter; that remains
gated on D1/D2. The formula is now backed by an exact-arithmetic check (stronger than the
original "not yet verified" caveat), but Fact 2's general triad identity is still only
computationally confirmed (M=1,2,3), not proven symbolically — see the harness file's own
docstring.

## Smallest question that unblocks further work

D3 is done. What remains open is **D1** (full `ℤ³` reindexing vs. a smaller shell-preserving
proxy) and **D2** (sequencing vs. OP-2) — both still genuinely the human owner's call, neither
resolved by D3's harness.
