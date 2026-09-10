# Review packet — the Fourier–Galerkin energy identity, for external audit

**For:** the programme owner and Deep Think (Google DeepMind), 2026-09-10.
**Self-contained by design:** everything needed to check the mathematics is below. No repository
access is required. Paste it whole.
**Companion page (private):** https://claude.ai/code/artifact/ced76d21-fa3a-4e2b-8227-16d50647ebfb

**What we are asking you to do:** audit §2, and push hardest on §2.3, which is the single place the
design was at risk. §4 and §5 are reported for context and are *not* what we want adjudicated.

---

## 0. Setting, stated so nothing is assumed

Fourier–Galerkin truncation of the 3-D incompressible Navier–Stokes / Euler nonlinearity on the
integer lattice. Fix `M ∈ ℕ` and let

- `Λ_M := {k ∈ ℤ³ : |k|² ≤ M²}` (a finite set),
- `u : ℤ³ → ℂ³` a *Galerkin state*: divergence-free (`k · u_k = 0` for every `k`), conjugate-
  symmetric (`u_{−k} = conj(u_k)`), zero mean (`u_0 = 0`), and cut off (`u_k = 0` for `k ∉ Λ_M`),
- `P(k) := I − (k ⊗ k)/|k|²` the Leray projector (with `P(0) := I`),
- the nonlinearity

```
B(u,v)_k  :=  P(k) [ −i · Σ_{p ∈ Λ_M} ( (k−p) · u_p ) · v_{k−p} ] .
```

The inner bracket is the Fourier transform of `(u·∇)v`. **Note the placement of the contraction:**
the wavevector `q = k−p` is dotted with `u_p`, giving a scalar, which multiplies the *vector*
`v_q`. The variant `q · (u_p · v_q)` is identically zero on this lattice — every pair `(p,q)`
appears with its swap, `P(k)[q s] + P(k)[p s] = P(k)[k s] = 0` — and was caught and corrected in
our exact-arithmetic harness. We flag it because it is an easy and silent error.

Pairing: `⟨a, b⟩ := Σ_i conj(a_i) · b_i`.

## 1. The claim

> **Energy identity.** For every Galerkin state `u` on `Λ_M`,
> `Re Σ_{k ∈ Λ_M} ⟨ u_k , B(u,u)_k ⟩ = 0`.

Equivalently: the truncated nonlinearity does no net work. This is the discrete form of
`b(u,u,u) = 0` for the trilinear form `b(u,v,w) = ∫ (u·∇v)·w`, and it is the prerequisite for
global existence of the Galerkin ODE. It is verified computationally in exact (Gaussian-rational)
arithmetic at `M = 1, 2, 3`; what follows is the proof.

## 2. The proof

### 2.1 The Leray projector drops out of the outer pairing

`⟨u_k , P(k) x⟩ = ⟨u_k , x⟩` for every `x`.

`P(k)` is a real symmetric matrix, hence self-adjoint for this pairing, so it moves onto the left
argument. And `conj(u_k) = u_{−k}` satisfies `(−k) · u_{−k} = 0`, i.e. `k · conj(u_k) = 0`, so
`conj(u_k)` already lies in the range of `P(k)` and is fixed by it.

*Independent check that this step is right:* in our harness, deleting the projection breaks
transversality (`k · B = 0`) and leaves the energy identity intact — exactly as this argument
predicts, and not what one would guess.

### 2.2 The triad sum, and the two-swap

After §2.1, and writing `q := k − p` and `r := −k` (so `p + q + r = 0`, using
`conj(u_k) = u_{−k} = u_r`), the quantity is `−i · S` with

```
S  =  Σ_{p+q+r=0}  ( q · u_p ) ( u_q · u_r ) .
```

**The constraint set `{p+q+r = 0}` is invariant under exchanging `q` and `r`, and the factor
`(u_q · u_r)` is symmetric in `q, r`.** Therefore

```
S  =  Σ ( r · u_p )( u_q · u_r )                    [relabel q ↔ r]
2S =  Σ ( (q + r) · u_p )( u_q · u_r )              [add]
   = −Σ ( p · u_p )( u_q · u_r )                    [q + r = −p]
   =  0                                             [divergence-freeness at p]
```

Hence `S = 0` (ℂ has no 2-torsion), so the total is `−i·0 = 0` and its real part vanishes. ∎

**What the proof consumes:** divergence-freeness at `p`, and nothing else. Not reality, not the
projection, not the truncation convention, not conjugate symmetry beyond its use in §2.1.

**Why a previous attempt failed, since it may be your first instinct too.** A *3-cycle*
`(p,q,r) → (q,r,p)` does not close: the summand is not cyclically symmetric, because `p` is
distinguished — it is the index whose amplitude sits inside the wavevector contraction. The
2-swap that *fixes* `p` closes immediately. Our exact-arithmetic harness recorded "a direct 3-way
relabeling argument did not close cleanly" and left the identity computationally certified but
unproven; the diagnosis is that the group was wrong, not the identity.

### 2.3 THE POINT WE WANT AUDITED — the index set must be closed under the swap

§2.2 is written as if the sum ranged over all of `{p+q+r=0}`. It does not: it ranges over a finite
set, and the swap must map that set to itself, or step 2 is illegitimate.

Reindexing `(k,p) ↦ (p, q=k−p)` is a bijection from `Λ_M × Λ_M` onto

```
S′ := { (p,q) : p ∈ Λ_M ,  −(p+q) ∈ Λ_M } ,
```

in which **`q` is unconstrained**. The swap sends `(p,q) ↦ (p, r)` with `r = −(p+q)`, and for the
image to lie in `S′` we would need `−(p+r) = q ∈ Λ_M`. So **`S′` is not closed**, and the argument
does not apply to it as stated.

**The repair.** For a Galerkin state, `u_q = 0` whenever `q ∉ Λ_M`, and every summand carries the
factor `(u_q · u_r)`. So all terms with `q ∉ Λ_M` vanish and

```
Σ_{S′} = Σ_{S_M} ,      S_M := { (p,q) : p ∈ Λ_M ∧ q ∈ Λ_M ∧ −(p+q) ∈ Λ_M } .
```

`S_M` **is** closed, and for a reason that is the whole point: its defining condition is a
property of the *unordered triad* `{p, q, r}` — all three members lie in `Λ_M` — while the swap
only permutes that triad.

**Our specific questions to you:**

1. Is the reindexing bijection stated correctly, in particular the direction of the sign in
   `r = −(p+q)` versus `k = p+q`? A sign error here would silently produce a theorem about a
   different index set. (Our machine-checked closure lemma fails when `−(p+q)` is replaced by
   `p+q`, which is evidence but not a proof that the *statement* is the intended one.)
2. Is the vanishing argument legitimate at the boundary — specifically for pairs where `p, q ∈ Λ_M`
   but `p+q` is large, so that `r ∉ Λ_M`? Such pairs are excluded from `S_M`, and we claim their
   summand vanishes because `u_r = 0`. We believe this is right; it is where we would look first
   for an error.
3. Does anything break at the fixed points of the swap (`q = r`, forcing `p = −2q`)? Our abstract
   lemma handles them by requiring that `2` not be a zero divisor, and derives the vanishing from
   divergence-freeness at `p = −2q`. Is that the cleanest treatment?

### 2.4 Status of the formalisation

The abstract theorem — the swap, its fixed points, the summed vanishing — is already
kernel-verified in Lean 4, with axiom footprint exactly `{propext, Classical.choice, Quot.sound}`.
The remaining work is the bridge of §2.1–§2.3, of which the closure lemma of §2.3 is done and
negative-controlled. So the request is an audit of the *mathematics*, not of Lean.

## 3. Verification conventions, so you can calibrate how much to trust the rest

- **Tier A** = Lean 4 kernel-compiled, zero `sorry`, and the axiom footprint is checked by
  `#print axioms` rather than by reading the source, because a failed proof still defines its name
  and only the footprint reveals the stray `sorryAx`.
- **Tier B** = exact rational or Gaussian-rational arithmetic; floating point is barred entirely.
- **Tier C** = anything floating point, or unformalised. Never gates a claim.
- Every checker ships a **negative control demonstrated to fail**. A theorem gets one too: we
  perturb the statement and confirm the proof breaks.
- Self-reports are not evidence: four submitted artifacts have claimed a clean gate, three did not
  compile.

## 4. Context, not for adjudication: a measurement that came out negative

A "triadic frustration index" `𝒟(M) = Σ|T| / |Σ T|` over the Galerkin ball was predicted to grow
like `M³` and to demonstrate the lattice suppressing the cascade. Computed to `M = 20`:

| field | slope of log 𝒟 vs log M, flat envelope | Kolmogorov envelope |
|---|---|---|
| random independent phases (**the null model**) | 3.43 | 1.89 |
| phase-coherent | −0.12 | −0.20 |
| deterministic arithmetic construction | 4.01 | 2.07 |

The growth belongs to the random phases, not to `ℤ³`: a phase-coherent field on the same lattice
with the same envelope gives `𝒟` flat. The predicted `M³` is the null model's own arithmetic (a
random walk over the same number of terms).

Separately, the pure-geometry version of the same quantity — Waleffe helical coefficients, no
field — has signed sum **exactly zero in every chirality class**, to `10⁻¹⁷` at every `M`. The
targeted "cancellation to `O(M³)`" is neither asymptotic nor statistical: it is the cyclic triad
identity, i.e. detailed conservation, which is the same fact §2 proves.

## 5. Context, not for adjudication: an audit that came out negative

A companion solver reports a "T-dual shield" converting a blow-up into a stationary Beltrami flow.
Reading its source: a damping term of strength 16 is applied to the negative-helicity amplitudes
whenever the shield is on, and the reported alignment `|Σκ(u₊²−u₋²)| / Σκ(u₊²+u₋²)` tends to 1
identically as those amplitudes vanish. The Lamb-vector norm is *derived from* that alignment
rather than computed from `u × ω`. Its frustration index returns `INFINITY` when `|ΣT| < 10⁻¹²`
without testing `Σ|T|`, so a frozen flow scores maximal frustration. And its blow-up threshold
(`×10⁶` in enstrophy) is crossed by an ordinary cascade into a 20-shell truncation, where the a
priori bound is `κ_N²·E ≈ 2.7 × 10¹¹ · E`.

The decisive control is one run: keep the damping, set the effective wavenumber back to `k`. If
alignment still exceeds 0.98, the result belongs to the damping and not to the geometry.

## 6. What this proves, and what it does not

§2 establishes the **finite-dimensional** energy identity for the truncated Fourier–Galerkin
nonlinearity. It is a prerequisite for global existence of the truncated ODE.

It is **not** evidence about the `α′ → 0` limit, about uniform enstrophy control, or about
Navier–Stokes. An external audit of this programme in August established that a truncated or
dyadic model is not the unreduced 3-D equations, and that verdict binds here. We would rather be
told this framing is still too generous than have it pass unchallenged.
