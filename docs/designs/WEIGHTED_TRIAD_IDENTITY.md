# Design memo — the weighted triad identity: why energy conserves and enstrophy does not

**Status: RELIED UPON by the owner's adjudication of 2026-09-10**
(`DECISION_2026-09-10_openai_leverage_adjudication.md`, Q4: "We rely entirely on the exact triad
identities and the closed-form enstrophy production sum that are already kernel-checked"). A
line-by-line statement-adequacy audit remains advisable and has not been performed; the reliance
is the owner's directive, not a completed audit.

**Original status: DRAFT — self-authored, and it needs the owner's statement-adequacy audit.**
Unlike `TASK22_ENERGY_IDENTITY.md`, this memo was not issued by the orchestrator. I derived it while
looking for unblocked work on the goal after Task 2.2 closed. The mathematics below is checked in
exact integers (`tests/tier_b_weighted_triad.py`) and formalised
(`AbstractAlgebraicConservation`), but **whether the statement is the one the programme wants is a
human judgement, not a machine one** — that is precisely the audit the tier system cannot perform.
See `feedback_gates-dont-compare-tiers-to-each-other` in the working notes.

**Date:** 2026-09-10. **Author:** Fable. **Scope:** algebra only; no analysis, no limit, no PDE.

---

## 1. Why this, and why now

Task 2.2 proved `Re Σ_k ⟨u_k, B(u,u)_k⟩ = 0` — the Galerkin ODE conserves energy exactly. That is a
prerequisite for global existence *of the truncated system*, and nothing more.

Hypothesis U is not about energy. `docs/HYPOTHESIS_U_SPECIFICATION.md` Definition 1.1 states it for
the **enstrophy** `E = ‖∇u‖²_{L²}`, and asks for a bound **uniform in the regularization
parameter**. So the object that matters is the enstrophy production

```
    P  =  Re Σ_k |k|² ⟨u_k , B(u,u)_k⟩ ,
```

the same sum as the energy identity but weighted by `|k|²`. The obvious question — does the
two-swap kill this too? — has an equally obvious answer, *no*, since otherwise 3-D Navier–Stokes
would be easy. **The useful question is not whether it fails but exactly how**, and that has a
clean, exact answer which this memo derives and which turns out to contain the energy identity as a
special case.

The remaining roadmap items (Task 2.3 sweeping cancellation, Tasks 3.1/3.2 confinement) are blocked
under rule E-1 on definitions that have not been authored. This one is not: enstrophy is defined in
the specification, the operator `B` is already Tier A here, and the identity below introduces no new
object beyond a weight function.

## 2. Setup, matching `AbstractAlgebraicConservation`

`k : I → Fin n → K` is the wavevector map, `u : I → Fin n → K` the field, and

```
    summand (p,q)  =  dot (k q) (u p) · dot (u q) (u r) ,        r := −(p+q)
    swap3 (p,q)    =  (p, r)                                      an involution
```

`swap3` fixes `p` and exchanges the second and third members of the triad. Write `D := dot (u q) (u r)`,
which is **symmetric** in `q, r`, so `swap3` leaves it alone. That symmetry is the whole engine.

The one hypothesis on the field is divergence-freeness at the first index, `dot (k p) (u p) = 0`.

## 3. The pair identity

Let `w : I → K` be **any** weight. Since `k = −r` for the outer index of the physical sum, the
weight attaches to the triad's **third** member. Define

```
    wsummand w (p,q)  =  w r · summand (p,q) .
```

Apply the swap. The pair `(p,r)` has third member `−(p+r) = q`, so

```
    wsummand w (p,q)  +  wsummand w (swap3 (p,q))
        =  w r · dot (k q) (u p) · D   +   w q · dot (k r) (u p) · D
        =  D · [ w r · dot (k q) (u p)  +  w q · dot (k r) (u p) ] .
```

Now the *only* place the hypothesis enters. Additivity of `k` and divergence-freeness give

```
    dot (k q) (u p) + dot (k r) (u p) = dot (k (q+r)) (u p) = dot (k (−p)) (u p) = −dot (k p) (u p) = 0 ,
```

so `dot (k r) (u p) = − dot (k q) (u p)`. Substituting:

> ```
>     wsummand w (p,q)  +  wsummand w (swap3 (p,q))
>          =  ( w r − w q ) · dot (k q) (u p) · dot (u q) (u r)
> ```

**This is the whole memo.** Everything below is a reading of it.

## 4. What it says

**(a) Energy conservation is the constant-weight case.** If `w` is constant then `w r − w q = 0`,
the pair cancels, and summing over a `swap3`-closed set gives `triad_sum_zero`. The existing energy
theorem is a corollary, not a separate fact. Nothing about the *value* of the constant is used, so
this is genuinely the same identity, not an analogy.

**(b) The obstruction is carried entirely by the weight difference across the swap.** Not by the
geometry of the triad, not by the chirality, not by the lattice — by `w r − w q` alone. Every other
factor is common to the two orderings.

**(c) So the enstrophy production is exactly the wavenumber-disparity term.** With `w = |·|²`,

```
    2 P  =  Σ  ( |r|² − |q|² ) · (q · u_p) · (u_q · u_r)
```

over the `swap3`-closed index set. This is vortex stretching in closed algebraic form: **a triad
transfers enstrophy in proportion to how unequal its two swapped members are in wavenumber, and a
triad whose two swapped members share a sphere transfers none.**

**(d) A sharp vanishing criterion, and it is not vacuous.** `P = 0` whenever `|q| = |r|` throughout
the index set — for instance on any set of isoceles triads. But that is a strong condition on the
whole set, not a symmetry of the equation, and the exact check finds the pair sum nonzero on 4 of 5
generic test triads for every non-constant weight tried.

## 5. What it does NOT say, stated plainly

- It is **not** a bound. It is an exact identity, and it gives no estimate on `P` whatsoever.
- It says **nothing** about uniformity in the truncation, which is the entire content of
  Hypothesis U. Under SPEC obstruction **O5**, an argument that does not use the limit uniformly
  proves nothing about the limit, and this one does not use the limit at all.
- It is **not** new mathematics. The enstrophy production of the Fourier–Galerkin system is
  classical; what is new here is only that it is kernel-checked in the same abstract form as the
  energy identity, so that the two are visibly one theorem.
- It does **not** unblock Task 2.3 or Tasks 3.1/3.2. Those remain blocked on definitions under E-1.

The honest summary is that this converts a known fact into a Tier A one and localises the 3-D
difficulty to a single factor. That is worth having and it is not progress on the bound.

## 6. Implementation order

1. `wsummand`, and `weighted_triad_pair` — the boxed identity of §3, for an arbitrary weight.
2. `weighted_triad_sum` — sum it over a `swap3`-closed set via the involution.
3. `triad_sum_zero_of_const` — energy conservation recovered as the constant-weight corollary,
   proved *from* the weighted identity, so that §4(a) is machine-checked rather than asserted.
4. The Tier B harness, exact integers, with divergence-freeness imposed by construction (`u_x =
   x × a_x`), covering several weights and a collinear degenerate case.

**Negative controls, to be demonstrated to fail before merging:**

- exchange the two weights in the conclusion (`w q − w r`) — must fail, or the identity is blind to
  the orientation it depends on;
- replace the difference by a sum (`w r + w q`) — must fail;
- drop divergence-freeness from `weighted_triad_pair` — must fail, since §3 uses it exactly once and
  the whole reduction turns on it;
- assert that the weighted pair *cancels* for a non-constant weight — must fail, or §4(c) is empty.
