# Door #2 — theory memo: a line-by-line sign audit of the dyadic blow-up mechanism

**Status:** `[top]` **DRAFT for owner review.** Hand-derived from the primary text (LL-5).
Nothing here is implemented; §6 fixes the observable that the experiment may then use, and by
the owner's directive of 2026-08-25 **no Python may be written until this memo is validated**.
**Author:** orchestrator. **Date:** 2026-08-25.
**Primary source, read directly:** Cheskidov, *Blow-up in finite time for the dyadic model of
the Navier–Stokes equations*, arXiv:math/0601074v2, §4–§5 (full text extracted from the PDF;
every displayed equation quoted below was read, not reconstructed).
**Governing:** `DOOR2_SIGN_FRAGILITY.md` (the direction spec), `LEDGER.md` rows **L-3**, **L-4**.

---

## 1. What is being audited, and against what

The theorem (**L-3**, Cheskidov Thm 5.3), verbatim:

> "Let `u(t)` be a solution to (3.1) with `uₙ(0) ≥ 0` and `α < 1/3`. Then for every `γ > 0`,
> there exists a constant `M(γ)`, such that `‖u(t)‖³_{1/3+γ}` is not locally integrable on
> `[0,∞)`, provided `‖u(0)‖_γ > M(γ)`."

Two hypotheses beyond `α < 1/3`: **positivity** and **large data**. This memo audits the first.

**The question (from the direction spec):** is positivity load-bearing for the *conclusion*, or
only for the *proof*? The answer below is that it is load-bearing at four distinct places, that
three of them share a single mechanism, and that the mechanism admits an explicit
counter-configuration which is **generic rather than exotic**.

**Structure of the argument being audited.** It is a contradiction argument: assume
`‖u(t)‖³_{1/3+γ}` *is* locally integrable, deduce that `‖u(0)‖_γ` is bounded. The engine is a
Lyapunov functional `H(t)` shown to satisfy `H′ ≳ H^{3/2}`, hence to blow up in finite time.

## 2. The audit table

Every step classified into exactly one of **sign-free** / **sign-repairable** / **sign-critical**,
as directed.

| # | Step (source label) | Content | Class |
|---|---|---|---|
| **S0** | Thm 4.2 | **Positivity propagates**: `uₙ(0) ≥ 0 ⟹ uₙ(t) ≥ 0 ∀t` | **sign-critical** |
| **S1** | (5.2) | Integrability transfer `∫Σλ^{(1+2γ)n}u²ₙuₙ₊₁ ≤ 2∫‖u‖³_{1/3+γ} < ∞` | **sign-repairable** |
| **S2** | (5.3), (5.4) | Interpolation `uₙu²ₙ₊₁ ≤ ½u³ₙ₊₁ + 2u²ₙuₙ₊₁`, and its three-index consequence | **sign-critical** |
| **S3** | (5.5) | Nonlinear identity `−(B(u,u), A^{γ/α}u) = c₁Σλ^{(1+2γ)n}u²ₙuₙ₊₁`, `c₁ = λ^{2γ+1} − λ > 0` | **sign-free** |
| **S4** | (5.6) | The `H^γ` balance obtained by multiplying by `λ^{2γn}uₙ` and summing | **sign-free** |
| **S5** | def. of `H` | `H(t) := ‖u(t)‖²_γ + c₂ Σλ^{2γn}(uₙuₙ₊₁)(t)` — the Lyapunov functional | **sign-critical** |
| **S6** | post-(5.6) | The differential inequality, whose driver is `+(λc₂/4)∫Σλ^{(1+2γ)n}u³ₙ` | **sign-critical** |
| **S7** | Lemma 5.1 | `Σλ^{(1+2γ)n}\|uₙ\|³ ≥ A‖u‖³_{α+γ}`, Hölder with `p=3, q=3/2`, `ε := 2−6α−2γ > 0` | **sign-free** |
| **S8** | post-Lemma 5.1 | Cauchy–Schwarz `Σλ^{2(α+γ)n}uₙuₙ₊₁ ≤ ‖u‖²_{α+γ}` | **sign-free** |
| **S9** | conclusion | Riccati `H′ ≳ H^{3/2}` ⟹ finite-time blow-up given `H(0)` large | **sign-critical**, inherited |

### The four sign-critical steps, each with its exact mechanism

**S0 — positivity propagates, and the integrating factor changes character.** The proof uses
the variation-of-constants representation (4.5), quoted:

> `uₙ(t) = uₙ(0)·exp(−∫₀ᵗ[νλ^{2αn} + λ^{n+1}uₙ₊₁(τ)]dτ) + ∫₀ᵗ exp(−∫ₛᵗ[…])·(gₙ + λⁿu²ₙ₋₁(s))ds`

With `uₙ(0) ≥ 0` and `gₙ ≥ 0`, every term is non-negative and positivity is preserved. The
sign-dependence is sharper than "terms are positive": the factor `exp(−∫λ^{n+1}uₙ₊₁)` is a
**contraction when `uₙ₊₁ ≥ 0` and an amplification when `uₙ₊₁ < 0`**. So sign-changing data does
not merely lose a convenient inequality — the shell-to-shell damping term reverses into growth.
**Everything downstream uses `uₙ(t) ≥ 0`, not `uₙ(0) ≥ 0`**, so S0 is the hinge on which the
other three hang.

**S2 — the interpolation is a case analysis on orderings of non-negative reals.** The text
argues: *"if `uₙ ≤ ½uₙ₊₁`, then `uₙu²ₙ₊₁ ≤ ½u³ₙ₊₁`. Otherwise `uₙu²ₙ₊₁ ≤ 2u²ₙuₙ₊₁`."* The second
branch divides by `uₙ₊₁ > 0`; the first uses that `≤` between the variables controls their
magnitudes. Under sign change neither survives: `uₙ ≤ ½uₙ₊₁` says nothing about `|uₙ|` when
`uₙ < 0`. The *absolute-value* analogues do hold, but they bound `|uₙu²ₙ₊₁|` and therefore give
an upper bound where the argument needs the terms to combine with a definite sign.

**S5 — the Lyapunov functional stops being coercive.** `H = ‖u‖²_γ + c₂Σλ^{2γn}uₙuₙ₊₁` with
`c₂ > 0`. For non-negative data the cross term is `≥ 0`, so `H ≥ ‖u‖²_γ`: **`H` dominates the
norm, which is what makes "H blows up" mean "the solution blows up".** For sign-alternating data
`uₙuₙ₊₁ < 0` term by term, the cross term is negative, and `H` can be strictly smaller than
`‖u‖²_γ` — with a large enough alternating cross term, `H` can be **negative**, at which point
`H′ ≳ H^{3/2}` is not even well-posed as a real inequality. **This is the deepest of the four:**
it is not an estimate that degrades, it is the functional itself ceasing to be a norm-equivalent
quantity.

**S6 — the production term is signed, and the sign is the whole engine.** The driver is
`+(λc₂/4)∫Σλ^{(1+2γ)n}u³ₙ`. The cube carries the sign of `uₙ`. Lemma 5.1 (S7) supplies
`Σλ^{(1+2γ)n}|uₙ|³ ≥ A‖u‖³_{α+γ}` — **note the absolute value in the source, which is why S7 is
sign-free** — and the argument silently identifies `Σu³ₙ` with `Σ|uₙ|³`, legitimate only under
S0. **The gap between those two sums is precisely the sign-critical content of the theorem.**

## 3. The explicit breaking configuration (as directed)

A configuration that leaves S7 intact and reverses S6, i.e. that isolates the sign as the
operative variable rather than the magnitudes.

**Take two adjacent shells.** Fix `n₀ ≥ 1` and set
```
u_{n₀} = a > 0 ,      u_{n₀+1} = −b   with b > 0 ,      uₙ = 0 otherwise.
```

**Production term.**
```
Σₙ λ^{(1+2γ)n} u³ₙ  =  λ^{(1+2γ)n₀} ( a³ − λ^{1+2γ} b³ ) ,
```
which is **negative** exactly when
```
b  >  λ^{−(1+2γ)/3} · a .
```
At `λ = 2` and small `γ` this is `b > 2^{−1/3}a ≈ 0.794 a`. **The condition is satisfied by an
open set of two-shell states with comparable amplitudes** — it needs no fine tuning, no smallness,
no large data. The driver of the blow-up does not merely weaken; it changes sign.

**Lemma 5.1 is untouched.** For the same state,
`Σλ^{(1+2γ)n}|uₙ|³ = λ^{(1+2γ)n₀}(a³ + λ^{1+2γ}b³) > 0`, and the Hölder bound holds verbatim
because it was proved with absolute values. **So the failure is localised exactly where the audit
says it is** — between `Σu³ₙ` and `Σ|uₙ|³`, and nowhere else in S7.

**Cross term.** `Σλ^{2γn}uₙuₙ₊₁ = −λ^{2γn₀}ab < 0`, so `H < ‖u‖²_γ` for the same state: S5 and S6
fail *together*, on the same configuration, which is evidence that they are one mechanism seen
twice rather than two independent obstacles.

**Honest scope of this configuration.** It is a statement about the *state*, not about a
*trajectory*: it shows the differential inequality's driver is negative at that instant. It does
**not** show that a solution launched there fails to blow up — the dynamics may reorganise the
signs immediately, and (5.2)'s reindexing couples shells. **Whether the sign structure persists
is exactly the empirical question**, and §6 makes it the observable.

## 4. Verdict of the audit

**Positivity is load-bearing for this proof at four places, which reduce to one mechanism:**
the argument needs `Σλ^{(1+2γ)n}u³ₙ` to be a *positive* driver and `Σλ^{2γn}uₙuₙ₊₁` to be a
*positive* correction, and both are guaranteed only by S0.

**But the audit cannot say positivity is load-bearing for the conclusion**, and it is important
to state where that stops. What has been established is that *this route* to blow-up has no
sign-robust variant: the repairs available (absolute values in S1, S2, S7) all produce upper
bounds on magnitudes where the argument requires a signed lower bound, and no rearrangement
recovers it, because the obstruction is that a *sum of signed cubes is not controlled below by
anything about magnitudes*.

Corroborating, and independent of our derivation: BMR (**L-4**) close `α ∈ [2/5, 1/2)` for
positive data by **abandoning energy methods entirely** for an invariant-region argument on the
pair `(Xₙ, Xₙ₊₁)` — a construction that reads signs directly, in their words because the range
"is where it becomes crucial to understand how the structure of the non-linearity drives the
dynamics". Two independent routes into this band both require positivity, at the same place: the
sign of the shell-to-shell transfer.

**This is a negative result about proofs, not about the world**, and it must be reported that
way. The sign-changing band remains open below `1/2` *because nobody has an argument*, and this
memo now says precisely which argument fails and why.

## 5. What would change the verdict

Two openings, both stated so they can be pursued or dismissed rather than left implicit:

- **A signed lower bound.** Anything that controls `Σλ^{(1+2γ)n}u³ₙ` from below in terms of a
  norm, for sign-changing data, revives S6 directly. The audit's claim is that no *rearrangement*
  of the existing steps does this; it is not a proof that no such bound exists.
- **A different functional.** S5 fails because `H`'s cross term is sign-indefinite. A functional
  whose cross term is `|uₙuₙ₊₁|` or `(uₙuₙ₊₁)²` would be coercive for any signs — the question is
  whether it still satisfies a superlinear differential inequality. **This is the concrete
  candidate the memo recommends examining first**, and it is a *theory* question, cheap to
  settle on paper before any run.

## 6. The observable for the experiment — fixed here, as required

By the direction spec, the observable is fixed by this memo and **may not be chosen after seeing
data**. Two, both read directly off the audit:

**O1 — the signed production functional** (the S6 driver):
```
P_γ(u) := Σₙ λ^{(1+2γ)n} u³ₙ ,    reported as the time-average of  P_γ(u(t)) / ‖u(t)‖³_{α+γ}
```
Normalising by `‖u‖³_{α+γ}` makes it scale-free and directly comparable to Lemma 5.1's constant
`A`: for non-negative data the ratio is `≥ A > 0` by S7; the question is its sign and magnitude
under alternation.

**O2 — the Lyapunov coercivity ratio** (the S5 failure):
```
R_γ(u) := H(u) / ‖u‖²_γ = 1 + c₂ Σλ^{2γn}uₙuₙ₊₁ / ‖u‖²_γ
```
`R ≥ 1` for non-negative data; `R < 1` measures the loss of coercivity, and `R < 0` its complete
failure.

**Pre-registered reading, fixed now.** *Sign-fragile* if `O1` fails to stay positive, or `O2`
drops below 1, for alternating data **while the positive-data column at the same `α` and matched
enstrophy keeps `O1 ≥ A` and `O2 ≥ 1`**. *Sign-robust* if both track the positive column.
**Either outcome is a result; neither is a claim about regularity.**

**Controls, unchanged from the direction spec and mandatory:** the BMR-regular positive column at
`α = 2/5` as the theorem-backed positive control; `α = 1/4` with large positive data as the
theorem-backed negative control; and a structure-free surrogate at matched enstrophy computed
**before** either is interpreted.

**The three hard requirements, restated because the run is invalid without them:** the harness
must **refuse to start** when the seed violates `u₀ ∈ V` (`require_hypothesis`); physical
divergence and compute-budget exhaustion must carry **different names**, and any aggregate
containing a budget stop must refuse interpretation (`StopReason`/`Aggregate`); and the null
model is computed first. All three are already available in `tests/controls.py`.

## 7. Owner decision requested

1. **Validate or reject this audit**, in particular the S5/S6 classification and the claim in §4
   that the four sign-critical steps are one mechanism.
2. **Authorise §6's observables** as the pre-registration, which unlocks the D6 harness work.
3. **Rule on §5's second opening** — whether the `|uₙuₙ₊₁|` functional is examined on paper now
   (cheap, and it could close or reopen Door #2 before any run) or deferred until after the
   experiment.

**Embargo acknowledged:** nothing in this memo leaves Stream 1 until sealed at Tier A or by a
validated pre-registered Tier B run.
