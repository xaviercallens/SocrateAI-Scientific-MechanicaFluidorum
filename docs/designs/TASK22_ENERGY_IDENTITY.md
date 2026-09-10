# Design memo — Task 2.2: proving `EnergyConservationStatement`, and why it is already 90 % done

**Status: EXECUTED AND CLOSED, 2026-09-10.** `FourierDynamicsZ3.energy_conservation` proves
`EnergyConservationStatement M` for every `M`, zero `sorry`, footprint exactly
`[propext, Classical.choice, Quot.sound]`. All five implementation steps below are in
`FourierDynamicsZ3.lean` §8 (step 4 was already in §7). All three mandated negative controls were
run on scratch copies and each fails as required.

**One deviation from this memo, and it simplifies the proof.** §3 routes the Leray drop through the
conjugate symmetry `conj(u_k) = u_{−k}`. That is not needed. The wavevector entries are integers and
so are fixed by conjugation, which transfers divergence-freeness to `conj u` directly, and
`pairing_leray_drop` therefore holds for **any** divergence-free field, not only for a
`FourierState`. Conjugate symmetry is still used, but only once and elsewhere — in
`pairing_convective_expand`, to convert the Hermitian outer pairing into the bilinear `dot` that
`triad_sum_zero` is stated for.

**Original status line:** `[top]`-authored derivation, hand-checked before any Lean is written
(LL-5).
**Author:** orchestrator. **Date:** 2026-09-10.
**Target:** turn `FourierDynamicsZ3.EnergyConservationStatement (M : ℕ) : Prop` into a theorem
with zero `sorry`.
**Result of this memo:** the hard mathematics is **already Tier A in this repository**. What is
missing is a *bridge*, and this memo specifies it completely.

---

## 1. The claim, and the one line that proves it

We must show, for a Galerkin state `u` on `Λ_M`:

```
Re Σ_{k ∈ Λ_M} ⟨u_k , B(u,u)_k⟩ = 0 ,      B(u,u)_k = P(k)[ −i Σ_{p+q=k} (q·u_p) u_q ] .
```

**The whole proof is a two-element symmetry.** Write the triad sum with `r := −k`, so that
`p + q + r = 0`, and observe that the constraint set is invariant under exchanging `q` and `r`
while the factor `(u_q · u_r)` is *symmetric* in `q, r`. Averaging the two orderings replaces
`(q · u_p)` by `½((q + r) · u_p) = −½(p · u_p) = 0` — **divergence-freeness at `p`, and nothing
else**.

That is the entire content. No reality condition, no Leray projection, no truncation convention
enters it.

### 1.1 Why the earlier attempt stalled, recorded so it is not repeated

`tests/tier_b_nse_triad_convolution.py` states that the inner identity "was NOT re-derived
symbolically from scratch here — a first attempt at a direct **3-way relabeling argument** did not
close cleanly". That is the diagnosis: a **3-cycle** `(p,q,r) → (q,r,p)` does *not* close, because
the summand is not cyclically symmetric — `p` plays a distinguished role (it is the index carrying
`u_p` inside the wavevector contraction). The **2-swap** `(p,q,r) → (p,r,q)`, which *fixes* `p`,
does close, in one line. The failure was of the chosen group, not of the identity.

## 2. The abstract theorem is already proved here

`lean_src/AbstractAlgebraicConservation.lean` (Tier A, 2026-08-13) contains exactly this:

```lean
def summand (k u : I → Fin n → K) (pq : I × I) : K :=
  dot (k pq.2) (u pq.1) * dot (u pq.2) (u (-(pq.1 + pq.2)))

def swap3 (pq : I × I) : I × I := (pq.1, -(pq.1 + pq.2))

theorem triad_sum_zero (k u : I → Fin n → K) (S : Finset (I × I))
    (h2 : ∀ x : K, 2 * x = 0 → x = 0)
    (hkadd : ∀ a b i, k (a + b) i = k a i + k b i)
    (hclosed : ∀ pq ∈ S, swap3 pq ∈ S)
    (hdiv : ∀ pq ∈ S, dot (k pq.1) (u pq.1) = 0) :
    ∑ pq ∈ S, summand k u pq = 0
```

`swap3` **is** the 2-swap of §1: it fixes `p` and exchanges `q` with `r = −(p+q)`. So Task 2.2 is
not a proof obligation any more — it is an **instantiation** obligation. Four things must be
supplied, and §3–§6 supply them.

## 3. Bridge step A — the Leray projector drops out of the outer pairing

`⟨u_k , P(k) x⟩ = ⟨u_k , x⟩` for every `x`.

*Reason.* `P(k)` is a real symmetric matrix, hence self-adjoint for this pairing, so it may be
moved onto the left argument. And `conj(u_k) = u_{−k}` (conjugate symmetry) satisfies
`(−k) · u_{−k} = 0` (divergence-freeness at `−k`), i.e. `k · conj(u_k) = 0`, so `conj(u_k)` is
already in the range of `P(k)` and `P(k)[conj(u_k)] = conj(u_k)` by `applyLeray_eq_self`.

This step is **independent of the inner formula** — the Tier B harness confirms it experimentally:
its "drop the Leray projection" negative control breaks Fact 1 and leaves Fact 2 intact, exactly
as this argument predicts.

*Lean:* `leray_symm`, `leray_conj`, `applyLeray_eq_self` all exist in `FourierStateZ3.lean`.

## 4. Bridge step B — from the double sum to `summand`

After step A the quantity is

```
Σ_{k ∈ Λ_M} Σ_{p ∈ Λ_M} (−i) (q · u_p) (conj(u_k) · u_q) ,   q := k − p .
```

Substituting `conj(u_k) = u_{−k}` and setting `r := −k` gives `p + q + r = 0` and

```
= (−i) Σ (q · u_p) (u_q · u_r) = (−i) Σ summand (p, q) .
```

The reindexing `(k, p) ↦ (p, q = k − p)` is a **bijection** from `Λ_M × Λ_M` onto
`S′ := {(p,q) : p ∈ Λ_M, −(p+q) ∈ Λ_M}` (its inverse is `(p,q) ↦ (−(−(p+q)), p) = (p+q, p)`… more
simply, `k = p + q` recovered from `r = −(p+q)`).

*Lean:* `Finset.sum_nbij'` with the explicit inverse, or `Finset.sum_bij'`.

## 5. Bridge step C — the index set must be `swap3`-closed, and `S′` is NOT

**This is the one real trap, and it must not be discovered during implementation.**

`swap3(p,q) = (p, r)`. For the image to lie in `S′` we would need `−(p + r) = q ∈ Λ_M`, and `q` is
*not* constrained in `S′` — only `p` and `r` are. `S′` is therefore **not** closed, and
`triad_sum_zero` does not apply to it directly.

**The fix is the Galerkin cutoff itself.** For a `GalerkinState`, `u_q = 0` whenever `q ∉ Λ_M`, and
`summand (p,q)` carries the factor `dot (u q) (u r)`, so every term with `q ∉ Λ_M` **vanishes**.
Hence

```
Σ_{S′} summand = Σ_{S_M} summand ,   S_M := {(p,q) : p ∈ Λ_M ∧ q ∈ Λ_M ∧ −(p+q) ∈ Λ_M} .
```

and `S_M` **is** `swap3`-closed, for a reason worth stating because it is the whole point: `S_M`
is defined by a condition on the *unordered triad* `{p, q, r}` — all three members lie in `Λ_M` —
and `swap3` only permutes that triad. Symmetric condition, permuted arguments, closure.

*Lean:* `Finset.sum_subset` (the discarded terms are zero) with
`S_M = (ball M ×ˢ ball M).filter (fun pq => -(pq.1 + pq.2) ∈ ball M)`.

## 6. Bridge step D — the three side conditions of `triad_sum_zero`

| hypothesis | discharge |
|---|---|
| `h2 : ∀ x : ℂ, 2*x = 0 → x = 0` | ℂ has no 2-torsion: `by intro x hx; linarith`-style, or `two_ne_zero` + `mul_eq_zero` |
| `hkadd : k (a+b) i = k a i + k b i` | our wavevector map is `fun a i => (a i : ℂ)`, and `Int.cast` is additive: `push_cast; ring` |
| `hdiv : ∀ pq ∈ S_M, dot (k pq.1) (u pq.1) = 0` | `pq.1 ∈ Λ_M`, and `FourierState.div_free` holds at **every** `k`, not merely inside the ball — so this is immediate |

Note `hdiv` is required only at the *first* index, which is why the 2-swap works and the 3-cycle
does not: only `p` needs divergence-freeness.

## 7. Consequence, and the honest scope

`Σ_k ⟨u_k, B(u,u)_k⟩ = (−i)·0 = 0`, hence its real part is `0` and
`EnergyConservationStatement M` holds — **for every `M`, with no smallness, no genericity, and no
extra hypothesis beyond the `GalerkinState` structure already carried.**

**What this does NOT establish.** It is the *finite-dimensional* energy identity for the truncated
Fourier–Galerkin nonlinearity: the statement that the Galerkin ODE conserves energy exactly. It is
a prerequisite for global existence of the truncated system, not evidence for anything about the
`α′ → 0` limit, about Hypothesis U, or about Navier–Stokes. Audit verdict D1 still binds: a
truncation is a truncation.

## 8. Implementation order (each step independently checkable)

1. `pairing_leray_drop` — step A, on its own.
2. `sum_reindex_to_summand` — step B, the bijection.
3. `sum_restrict_to_ball_triads` — step C, the vanishing of out-of-ball terms.
4. `S_M_swap3_closed` — the closure lemma; **prove this one first**, it is where the design was at
   risk and it is three lines once stated correctly.
5. `energy_conservation` — assemble, apply `triad_sum_zero`.

**Negative controls to run on scratch copies before merging** (SPEC §7.3):
- drop `hdiv` from the assembled proof — it must fail (divergence-freeness is load-bearing);
- replace `S_M`'s third condition `−(p+q) ∈ Λ_M` by `p + q ∈ Λ_M` — the closure lemma must fail
  (it is the *signed* member of the triad that closes, and an unnoticed sign here would produce a
  theorem about a different index set);
- state the identity for a field **without** the cutoff — step C must fail.
