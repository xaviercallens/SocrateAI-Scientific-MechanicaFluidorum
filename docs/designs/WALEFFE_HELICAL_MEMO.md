# Design memo — D-3: the helical decomposition, the exact triad coefficient, and what it does and does not explain

**Status:** `[top]`-authored derivation. **NO LEAN MAY BE WRITTEN UNTIL THE OWNER APPROVES THIS
MEMO** (owner directive, 2026-09-10). Everything below is hand-derived; §6 lists what still needs
checking before it is trusted.
**Author:** orchestrator. **Date:** 2026-09-10.
**Source of the basis:** Waleffe, *The nature of triad interactions in homogeneous turbulence*,
Phys. Fluids A **4** (1992) 350–363 — the construction, not the conclusions, which are Tier L at best.
**Governing:** directive D-3; SPEC §7.1 (α′ quantified), §7.5 (non-vacuity), §7.3 (controls).

---

## 1. The basis on the lattice, and the one obstruction Lean will hit

For `k ∈ ℤ³ ∖ {0}` put `κ = k/|k|`, pick a real unit vector `ν = ν(k) ⊥ κ`, and define

```
    h^s(k)  :=  (ν × κ)  +  i s ν ,        s ∈ {+1, −1} .
```

Writing `e₁ := ν × κ` and `e₂ := ν`, the triple `(e₁, e₂, κ)` is a real orthonormal frame, and the
five facts that carry everything follow by direct computation:

| # | fact | note |
|---|---|---|
| **H1** | `h^s · h^s = 0` | *self-null*: `e₁·e₁ − e₂·e₂ = 0` and the cross term `2is e₁·e₂ = 0` |
| **H2** | `h^s · h^{−s} = 2` | the normalisation; equivalently `‖h^s‖² = h^s · conj(h^s) = 2` |
| **H3** | `k · h^s = 0` | transversality — the basis lives in the Leray range automatically |
| **H4** | `i k × h^s = s \|k\| h^s` | **curl eigenvector**, eigenvalue `s\|k\|`. This is the whole reason for the basis |
| **H5** | `conj(h^s) = h^{−s}` | so the reality condition `u_{−k} = conj(u_k)` becomes a statement about chirality |

**The obstruction, stated up front because it dictates the Lean design.** `|k| = √(k_sq k)` is
**irrational** for almost every lattice point. So:

- the basis and the coefficient below cannot live in `ℚ`; the Tier B mirror must be written in
  **squared form** (only `k_sq` appears) or it cannot exist;
- in Lean the natural home is `ℝ`/`ℂ` with `Real.sqrt`, which is available and total, but every
  division by `|k|` needs `k ≠ 0` as an explicit side condition (SPEC §7.5: Lean's junk values make
  `x/0 = 0`, so an unwitnessed division silently proves the wrong thing);
- `ν(k)` is a **choice**. Nothing below depends on which choice, but Lean needs *some* total
  function. The clean construction is the one already used in this repository's exact harness:
  `v₁ = k × x̂`, falling back to `k × ŷ` when `k ∥ x̂`, then normalise. Its totality and its
  orthogonality are two small lemmas, and they are the first thing to prove.

## 2. The nonlinearity in Lamb form — where the eigenvalue enters

The Leray-projected convective term has an equivalent form that makes the helical basis pay:

```
    (u·∇)u  =  ω × u  +  ∇(½|u|²) ,        P[∇φ] = 0 ,
```

so `P[(u·∇)u] = P[ω × u]`. On the Fourier side, with `ω̂_p = i p × û_p`, and expanding
`û_p = Σ_{s_p} a_p^{s_p} h^{s_p}(p)`, fact **H4** gives immediately

```
    ω̂_p  =  Σ_{s_p}  s_p |p| · a_p^{s_p} · h^{s_p}(p) .
```

**This is the point of the whole construction:** in this basis the curl is diagonal, and the
vortex-stretching term stops being a differential operator and becomes multiplication by `s|p|`.

## 3. The exact interaction coefficient

Project the equation of motion onto `h^{s_k}(k)` using **H2** (divide by 2), and note that
`conj(h^{s_k}(k))` is transverse by **H3**, so `P(k)` drops out of the pairing exactly as it does in
Task 2.2's step A. For the triad `p + q = k`:

```
    ȧ_k^{s_k} = −½ Σ_{p+q=k} Σ_{s_p,s_q} s_p|p| · a_p^{s_p} a_q^{s_q} ·
                      [ ( h^{s_p}(p) × h^{s_q}(q) ) · conj(h^{s_k}(k)) ] .
```

The index set `{p+q=k}` is symmetric under exchanging the two summation slots, while the cross
product is **antisymmetric**. Antisymmetrising — the same two-element move that proves Task 2.2 —
replaces `s_p|p|` by `½(s_p|p| − s_q|q|)`:

```
    ȧ_k^{s_k} = Σ_{p+q=k} Σ_{s_p,s_q} C^{s_k s_p s_q}_{k,p,q} · a_p^{s_p} a_q^{s_q} ,

    C^{s_k s_p s_q}_{k,p,q} := −¼ ( s_p|p| − s_q|q| ) · g^{s_k s_p s_q}_{k,p,q} ,

    g^{s_k s_p s_q}_{k,p,q} := ( h^{s_p}(p) × h^{s_q}(q) ) · conj( h^{s_k}(k) ) .
```

**Consequence C0, free and worth stating:** `C = 0` whenever `s_p|p| = s_q|q|`. In particular every
**same-chirality, same-magnitude** interaction is inert. On `ℤ³` that is not a measure-zero curiosity:
`|p| = |q|` holds for every pair on a common sphere, and lattice spheres are heavily populated.

## 4. The closed form, and which chiralities vanish

A triad `p + q + r = 0` (here `r = −k`) is **coplanar**. Let `n̂` be a unit normal to that plane and
choose `ν = n̂` for all three members — legitimate, since `n̂ ⊥` every vector in the plane, and §1 says
nothing depends on the choice. Then `e₁(a) = n̂ × κ_a` is in-plane and `e₂(a) = n̂` is out of plane.

Write `S_ab := (κ_a × κ_b) · n̂`, the signed sine of the angle from `a` to `b`. Expanding
`h^{s_p} × h^{s_q}` in this frame and using `n̂ × (n̂ × κ) = −κ`:

```
    h^{s_p}(p) × h^{s_q}(q)  =  (e₁(p) × e₁(q))  +  i s_q κ_p  −  i s_p κ_q ,
```

and pairing with `conj(h^{s_k}(k)) = e₁(k) − i s_k n̂`, using that `e₁(p) × e₁(q) ∥ n̂` (so it kills
the in-plane `e₁(k)`) and that `κ_p · n̂ = κ_q · n̂ = 0`:

```
    g  =  i [ − s_k (κ_p × κ_q)·n̂  +  s_q (κ_k × κ_p)·n̂  −  s_p (κ_k × κ_q)·n̂ ] .
```

Now use the triad relation itself. From `|k|κ_k = −|p|κ_p − |q|κ_q`, crossing with `κ_p` and with
`κ_q` gives `S_kp = (|q|/|k|) S_pq` and `S_kq = −(|p|/|k|) S_pq`. Substituting, **everything
collapses onto one geometric scalar**:

> ```
>     g^{s_k s_p s_q}  =  ( i S_pq / |k| ) · ( s_p|p| + s_q|q| − s_k|k| )
> ```
>
> and therefore
>
> ```
>     C^{s_k s_p s_q}  =  −( i S_pq / 4|k| ) · ( s_p|p| + s_q|q| − s_k|k| ) · ( s_p|p| − s_q|q| ) .
> ```

**This is the algebraic structure D-3 asks for, and it is exact.** Every dependence on the triad's
shape is carried by the single factor `S_pq`, common to all eight chirality classes; the chirality
enters only through two scalar factors built from the **signed helical wavenumbers** `s|k|`.

**The vanishing classes, read straight off:**

| condition | consequence |
|---|---|
| `s_p\|p\| = s_q\|q\|` | `C = 0` — the antisymmetrisation factor dies |
| `s_p\|p\| + s_q\|q\| = s_k\|k\|` | `C = 0` — the geometric factor `g` itself dies |
| `S_pq = 0` (collinear triad) | `C = 0` for **all eight classes** at once |

The second line is the one with content. It says a triad is inert exactly when the signed helical
wavenumbers **balance**, and it is the precise form of what Waleffe calls the instability
assumption: the class with the largest `|s|k||` in the "wrong" position is the one that drives
transfer, and the balanced classes carry none.

**Non-vacuity, because a vanishing theorem about nothing is worthless (LL-11).** The balance
condition is satisfiable on `ℤ³`: any triad with `|p| = |q|` and `s_p = +`, `s_q = −` has
`s_p|p| + s_q|q| = 0`, so it is inert for the class `s_k = +` precisely when `|k| = 0` — excluded —
hence *not* inert, while the **first** line kills the same triad for `s_p = s_q`. A concrete
witness pair must accompany any Lean statement.

## 5. The UV question — the premise is wrong, and this is the correction

Directive D-3 asks for an analytic reason why "the UV band receives exactly zero net transfer under
our T-dual metric", citing the D-2 measurement. **Checked before deriving anything: it receives zero
because the band is never populated, not because anything cancels.** Peak amplitude by shell over
the whole run, metric on:

| `n` | 0 | 4 | 6 | 8 | 10 | 12 | 13…19 |
|---|---|---|---|---|---|---|---|
| peak `\|uₙ\|` | 2.0 | 1.0 | 1.1e−1 | 2.6e−9 | 1.5e−43 | 3.6e−184 | **0.0** |

By `n = 13` the amplitude has fallen below the smallest representable `float64`. Without the metric
all seven UV shells are populated. So the `0.0` is an **underflow**, and in exact arithmetic the
flux there is astronomically small but non-zero.

**What is real, and what the analysis should therefore explain, is the decay rate.** In the shell
surrogate the metric replaces `k` by `k_eff = k/(1+α′k²)`, so beyond the wall `k ≫ 1/√α′` the
transfer coefficient decays like `1/(α′k)` while the shell spacing is geometric — giving decay in
the shell index that compounds multiplicatively, which is what the table shows. **Searching for an
algebraic cancellation to explain a number that is really `~10⁻³⁷⁰` would be chasing a ghost**, and
is the same failure mode as reading a depletion off a count that was never compared to chance.

**One thing the closed form of §4 does say about the UV, and it is worth checking numerically:**
`C ∝ (s_p|p| + s_q|q| − s_k|k|)`. For a local UV triad with `|k| ≈ |p| ≈ |q|`, the class
`s_k = s_p = s_q = +` gives a factor `≈ |k|`, while mixed classes give factors that can be much
smaller or vanish. That is a statement about *which* UV interactions are strong, and it is
independent of any metric — so it is testable against the existing D-2 instrument.

## 6. What must be checked before this memo is trusted, and before any Lean

Listed because the derivation is new and hand-made, and this repository's rule is that a memo names
its own weak points.

1. **The sign of `S_kp` and `S_kq`.** The collapse in §4 hinges on `S_kp = (|q|/|k|)S_pq` and
   `S_kq = −(|p|/|k|)S_pq`. A sign slip there would leave the closed form the *right shape* with the
   *wrong* balance condition — invisible in structure, fatal in content. **Check numerically first**
   against the existing enumerator, which already computes `g` by brute force.
2. **The antisymmetrisation constant.** `−¼` versus `−½` depends on whether the double sum is over
   ordered or unordered pairs. State the convention in Lean, and verify against a two-mode example.
3. **The convention gap with the existing code.** `exploration/triad_frustration_rs` computes `g`
   with all three vectors conjugated and the triad written `k+p+q = 0`; this memo conjugates only
   the `k` slot and writes `p+q = k`. The two differ by relabelling `k → −k` and **H5**; the
   translation must be written down explicitly, or the numerical check in item 1 will compare two
   different objects and appear to disagree.
4. **The per-class numerical zero, now explainable.** The enumerator found the signed sum over
   triads to be zero *in every chirality class* to `10⁻¹⁷`. The closed form makes this checkable:
   under the relabelling `(k,p,q) → (k,q,p)` the factor `S_pq` changes sign while
   `(s_p|p| + s_q|q| − s_k|k|)` is symmetric and `(s_p|p| − s_q|q|)` antisymmetric — a product of one
   sign-flip and one antisymmetric factor, hence **even**, which does *not* cancel. **So the closed
   form does not yet explain the measurement, and one of the two is wrong.** That contradiction is
   the single most informative open item here and must be resolved before any Lean is written.

## 7. Proposed Lean order, riskiest first (for approval, not for execution)

Per `docs/designs/FORMALIZATION_WORKFLOW.md`, and to be started only after this memo is approved:

1. `helical` — the basis, with `ν` total and `k ≠ 0` witnessed; then **H1–H5**, each with a negative
   control (perturb a sign; the eigen-equation must fail, as it already does in the Rust harness).
2. `g_closed_form` — §4, the collapse onto `S_pq`. **This is the riskiest step**, per item 1 above.
3. `C_vanishes_iff` — the two vanishing conditions, plus a **non-vacuity witness** for each.
4. Only then, if items 1–4 of §6 are resolved: any statement about which classes dominate.

**Nothing here touches Hypothesis U**, which stays a conditional parameter (directive D-4). The
whole content of this memo is algebra about a determinate function of three wavevectors and three
signs — which is exactly why it was chosen as the remaining tractable path.
