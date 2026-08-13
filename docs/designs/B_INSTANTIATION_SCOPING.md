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
Fourier-Galerkin-truncated Euler/NS nonlinearity is the standard form (cross-checked via web
search against current literature restating this identical form, e.g. the Galerkin-truncated
system as stated in arXiv:2604.12188 — **NOT independently verified against a fixed textbook
page the way this program's citation discipline (LL.md, "verify literature before citing")
normally requires; treat the formula below as "matches independent recollection and one
literature cross-check," not as fully verified**):

```
∂ₜ û_k = −ν|k|² û_k − i Σ_{p+q=k, p,q∈Λ} P(k)[q (û_p · û_q)]
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

**D3 — Right-sized first deliverable.** Rather than attempting the full reindexing in one
step, the smallest well-scoped, independently-checkable next task I can identify (recommended,
not decided) is: **a standalone Tier B exact-arithmetic harness for the Fourier-triad
convolution formula itself**, extending T0.1/T0.2's existing lattice/triad-enumeration code
(`symbolic/`, `data/triads_free.csv`) to small finite truncations with exact-rational (or
Gaussian-rational, for the complex Leray projection) amplitudes, checked against the standard
**detailed energy conservation** identity of the Leray-projected quadratic nonlinearity
(`Σ_k conj(û_k) · N(û)_k = 0`, i.e. the nonlinear term alone conserves energy — the textbook
fact underlying the NSE energy identity `SPEC.md` already cites) as its negative-control-style
sanity check (a version with the Leray projection dropped, or a sign error, should demonstrably
FAIL the identity). This doesn't require touching `HypothesisU_Statements.lean` at all, is
independently falsifiable, and would give the human owner a concrete, small artifact to audit
before committing to D1's larger choice.

## What this memo does NOT do

No Lean file is touched. No `B` instantiation is implemented, drafted as Lean code, or added to
any ledger row. No claim is made that the formula above is final or fully verified — it is
explicitly flagged as needing independent verification against a fixed citable source before
any further step. This is scoping only, matching what was requested.

## Smallest question that unblocks further work

Which of D1's two paths (full `ℤ³` reindexing vs. a smaller shell-preserving proxy), and
should D3's recommended first deliverable (Tier B triad-convolution + energy-conservation
harness) be dispatched now regardless of the D1 answer, since it's useful under either path?
