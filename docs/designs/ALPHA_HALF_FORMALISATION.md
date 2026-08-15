# Design memo — formalising `α ≥ 1/2`, structured so the barrier below `1/2` becomes formal

**Status:** `[top]` hand-derivation per LL-5, written **before** the Lean it specifies.
**Owner decision, 2026-08-15:** target `α ≥ 1/2` as a known theorem — "pour valider et
stabiliser" — but *generalise while doing it*, and treat the sign-changing band below `1/2` as
the real problem, to be attacked with what this exercise teaches.
**Author:** orchestrator (Fable). **Date:** 2026-08-15.
**Prerequisite reading:** `docs/escalations/2026-08-15-E3b-band-is-narrower.md` (the corrected
regime map; any α-claim must name its data class).

---

## 0. The design principle this memo exists to enforce

The naive way to formalise a known theorem is to fix `α = 1/2` and let the constant `1/2` be
baked into every lemma. That produces a correct Lean file that teaches nothing.

**Instead: carry `α` symbolically through the entire chain, and let `α ≥ 1/2` enter at exactly
one place.** Then the Lean file does not merely certify Cheskidov's theorem; it *localises the
obstruction*, and the statement "this is where the method dies" becomes a formal object rather
than a remark. That is the whole point of doing the known case first.

The derivation below shows the localisation is real: **`α ≥ 1/2` is used once**, and what it
buys is not an estimate but an *integrability threshold*.

## 1. The object (verbatim from the source, nothing invented)

Cheskidov, arXiv:math/0601074v2, eq. (3.1) — the **infinite**, untruncated system:

```
d/dt u_n + ν λ^{2αn} u_n − λ^n u²_{n−1} + λ^{n+1} u_n u_{n+1} = g_n ,   n ≥ 1,   u_0 = 0
```

with `λ > 1`, `ν > 0`, `α > 0`, and `g` time-independent, `g ∈ H`, `g_n ≥ 0`. Spaces:
`((u,v))_γ = Σ λ^{2γn} u_n v_n`, `H = H^0`, `V = H^α`, `|·|` the `H`-norm, `‖·‖` the enstrophy
norm on `V`, `A` the dissipation operator (`(Au)_n = λ^{2αn}u_n`).

> **Theorem 4.4 (the target).** *"If α ≥ 1/2, then for any `u₀ ∈ V` there exists a strong
> solution `u(t)` to (3.1) on `[0,∞)` with `u(0) = u₀`."*

Two scoping facts that must travel with every citation of it:
- it is **existence**, not uniqueness — Thm 4.4 asserts no uniqueness, and we may not either;
- **no positivity** is assumed, so this theorem already lives in the sign-changing world that
  §5 identifies as the real target.

Definition 3.1 and its remark are what make this tractable: *"since `(B(u,u))_n` has a finite
number of terms, the notions of a weak solution and a classical solution (of a system of ODEs)
coincide"*, and *"a solution is strong (or regular) … if `‖u(t)‖` is bounded"*. **There is no
distribution theory to formalise.** `H^γ` is a weighted sequence space; regularity is
boundedness of a norm; the equation is an ODE system.

## 2. The chain, with `α` carried symbolically

Each step is labelled **[source]** (displayed in the paper) or **[derived]** (obtained here and
verified against the paper's special cases). All exponent algebra is machine-checked in exact
rationals by `tests/tier_b_riccati_exponents.py`.

**(a) Bilinear estimate [source].** For `α ∈ [1/3, 1]`, Hölder gives
```
|(B(u,u), Au)|  ≤  c_b |Au|^{1/α−1} ‖u‖^{4−1/α} ,        c_b = λ^α − λ^{−α} > 0,
```
and the paper states these estimates are **sharp** (witness: `u` with two consecutive nonzero
terms). Write `p(α) = 1/α − 1`, `q(α) = 4 − 1/α`; note `p + q = 3`, the homogeneity of `B·A`.

**(b) Young absorption against `−ν|Au|²` [source: "Now consider the case where α > 1/3"].**
Possible iff `p(α) < 2`, i.e. **iff `α > 1/3`**. This is the whole content of the local-existence
theorem (Thm 4.3), and it is *not* where `1/2` comes from.

**(c) Post-Young exponent [source, and reproduced by derivation].**
`r(α) = 2q/(2−p) = (8α−2)/(3α−1)` — the paper displays exactly `c‖u‖^{(8α−2)/(3α−1)}`.
The harness checks the derived form against that source form, and against three independent
displayed special cases: `r(1/2)=4` (`‖u‖⁴`), `r(2/5)=6` (`‖u‖⁶`), `p(1/3)=2` (`|Au|²‖u‖`,
"which corresponds to the 4D Navier–Stokes equations").

**(d) Riccati inequality [source at α ≥ 1/2 and α = 2/5; general form derived].** With
`y = ‖u‖²`,
```
y′  ≤  −(2ν/3)|Au|²  +  C y^{s(α)}  +  C′|g|² ,          s(α) = r/2 = (4α−1)/(3α−1).
```

**(e) Blow-up rate [derived].** If `y → ∞` as `t → t*⁻`, integrating `y′ ≤ Cy^s` from `t` to
`t*` gives `y^{1−s}(t) ≤ (s−1)C(t*−t)`, i.e.
```
y(t)  ≥  c · (t* − t)^{−ρ(α)} ,          ρ(α) = 1/(s−1) = 3 − 1/α .
```
At `α = 1/2`, `ρ = 1`, reproducing the paper's `‖u(t)‖² ≥ c/(t*−t)`.

**(f) The contradiction, and the single use of `α ≥ 1/2` [derived].** The energy identity
`½ d/dt|u|² = −ν‖u‖² + (g,u)` (using `(B(u,u),u) = 0`) integrates to the **energy inequality**,
which supplies exactly
```
‖u‖²  =  y  ∈  L¹_loc .
```
A blow-up is therefore impossible precisely when the rate in (e) is **not** locally integrable:
```
∫^{t*} (t*−t)^{−ρ} dt = ∞   ⟺   ρ ≥ 1   ⟺   3 − 1/α ≥ 1   ⟺   α ≥ 1/2 .
```

> **This is the theorem's threshold, and it is not an artifact of technique.** `α = 1/2` is
> exactly where the Riccati blow-up rate crosses the integrability threshold that the energy
> inequality is able to see. Above it the rate is too fast to be integrable and the blow-up is
> refuted; below it the rate is integrable, the energy inequality notices nothing, and there is
> no contradiction to be had.

## 3. The barrier below `1/2`, quantified

Suppose one had an a priori bound `‖u‖^θ ∈ L¹_loc` for some exponent `θ` instead of `θ = 2`.
The same argument refutes blow-up iff `(t*−t)^{−ρθ/2}` is non-integrable, i.e. iff
`θ ≥ θ*(α) := 2/ρ(α) = 2/(3 − 1/α)`. Machine-checked (exact rationals):

| `α` | `s(α)` | `ρ(α)` | blow-up excluded? | `θ*(α)` needed | energy supplies |
|---|---|---|---|---|---|
| 7/20 | 8 | 1/7 | no | **14** | 2 |
| 2/5 | 3 | 1/2 | no | **4** | 2 |
| 9/20 | 16/7 | 7/9 | no | **18/7** | 2 |
| **1/2** | 2 | **1** | **yes** | **2** | **2** |
| 3/5 | 7/4 | 4/3 | yes | 3/2 | 2 |
| 1 | 3/2 | 2 | yes | 1 | 2 |

`θ*(α) > 2 ⟺ α < 1/2`, exactly. So the obstruction is a **single scalar deficit**, and it is
severe: at `α = 2/5` the method needs `L¹` control of `‖u‖⁴` and has it only for `‖u‖²`; at
`α = 7/20` it needs `‖u‖¹⁴`. This is why energy methods cannot reach the band, and why
Barbato–Morandin–Romito had to abandon them for invariant regions (their own words: *"do not
cover the range β ∈ (2, 5/2], where it becomes crucial to understand how the structure of the
non-linearity drives the dynamics"*).

Historical note worth keeping: Cheskidov singles out `α = 2/5` as having *the same* enstrophy
estimate as 3-D NSE and calls it *"the same open question concerning the regularity of the
solutions"*. BMR later closed it — **for positive data**. The sign-changing case at `α = 2/5`
is therefore, as far as the verified sources show, still the 3-D-NSE-analogue open question.

## 4. Lean plan (dispatch-ready, α-general by construction)

File `lean_src/DyadicRiccati.lean`. **Everything in Steps 1–3 is `α`-general; `α ≥ 1/2` appears
only in Step 4.** No new mathematical definitions: the shell state, `k_n`, and the truncated
`shellB` already exist in `DyadicShell_Statements.lean` and must be reused, not re-declared
(SPEC: never invent a definition — if the infinite-system objects are needed and absent, that
is an E-1 blocker, not a gap to fill).

1. **Exponent lemmas** (`ℝ`, no analysis): `p + q = 3`; `absorbable ↔ 1/3 < α`;
   `r = (8α−1·2)/(3α−1)`; `s − 1 = α/(3α−1)`; `ρ = 3 − 1/α`. These mirror the Tier B harness
   one-for-one and are pure field arithmetic — `field_simp; ring` territory.
2. **The integrability characterisation** — the load-bearing lemma:
   `IntegrableRate ρ ↔ ρ < 1`, hence `¬IntegrableRate (ρ α) ↔ α ≥ 1/2`. Stated for real
   exponents about `(t*−t)^{−ρ}`; this is where `α ≥ 1/2` is *derived*, not assumed.
3. **The Riccati comparison lemma**: from `y′ ≤ C y^s` on `[t₀,t*)` with `y → ∞`, conclude
   `y(t) ≥ c (t*−t)^{−1/(s−1)}`. Standard ODE comparison; the only genuinely analytic step, and
   `α`-free.
4. **The specialisation**: `α ≥ 1/2 → ¬(blow-up)`, by combining 2 and 3 against a hypothesis
   `y ∈ L¹_loc` (the energy inequality, taken as a *hypothesis* at first — see the honesty
   clause below).

**Honesty clause, to be written into the file header.** Step 4 delivers the *continuation*
half of Thm 4.4 — "no finite-time enstrophy blow-up, given local existence and the energy
inequality". It does **not** deliver Galerkin existence or the passage to the limit, which is
where the real formalisation cost sits (infinite sums, convergence, the rearrangement behind
`(B(u,v),v) = 0`). The file must state that it formalises a *component* of a known theorem, and
the LEDGER row must say so too. Claiming Thm 4.4 whole on the strength of Steps 1–4 would be
exactly the D1-class overstatement the 2026-08-13 audit killed this programme's headline for.

**Negative controls (to run on scratch perturbed copies before commit, per the standing rule):**
NC1 — replace `ρ = 3 − 1/α` by `3 − 2/α`: Step 2's characterisation must fail to compile.
NC2 — drop `α > 1/3` from the absorption lemma: `2 − p > 0` becomes unprovable.
NC3 — weaken `α ≥ 1/2` to `α > 1/3` in Step 4: the integrability contradiction must break.

## 5. What this hands to the `α < 1/2` attack (the actual target)

The exercise is not tribute to a known theorem; it produces three things the sign-changing band
needs:

1. **A formal, localised barrier.** After Step 2, "the method dies below 1/2" is a Lean lemma
   about an integrability threshold, not a folk remark. Any proposed route into the band can be
   tested against it mechanically: *does it raise `θ` above `θ*(α)`, or does it lower `ρ`'s
   requirement by not going through Riccati at all?* Those are the only two doors, and now they
   are enumerated rather than guessed.
2. **The pre-registered kill criterion for the next mechanism.** By the LL-15 rule, whatever is
   proposed for `α < 1/2` must name in advance the quantity it improves — `p`, `θ`, or the
   route — and by how much. A proposal that improves none of them is refuted before it is
   implemented, which is exactly the screen the four dead Sym² translations lacked.
3. **A verified statement of where the real question lives.** Both bounding theorems assume
   positivity (E-3b); Cheskidov's `α ≥ 1/2` does not. So the natural next object is
   **sign-changing data at `α ∈ [2/5, 1/2)`** — the region BMR's invariant-region argument
   cannot reach because it is built on positivity, and which Cheskidov himself flagged at
   `α = 2/5` as carrying the 3-D NSE enstrophy estimate. That is a genuinely open, precisely
   stated question, and it is where this programme should point after Step 4.

**Not claimed here:** any route into the band. §5 says what a route would have to do, not that
one exists. Proposing one is `[top]` authoring plus human audit, and it must pass the depletion
screen and the LL-11 vacuity test before it is written up — the four dead mechanisms are the
reason those screens exist.
