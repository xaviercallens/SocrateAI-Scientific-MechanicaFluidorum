# E-3b — the "open band" is narrower than this repository stated, and depends on the data class

**Filed:** 2026-08-15. **Class:** E-3 (computational//literature anomaly invalidating a stated
premise), second instance. **Raised by:** source verification commissioned before opening the
α-band formalisation track. **Status:** correction applied to the instrument and the ledger;
the strategic consequence is the owner's.

---

## 1. What this repository said, and what is true

`LEDGER.md`'s E-3 box, `SPEC.md` §, `tests/tier_b_regime_adequacy.py` and the report all stated:

> blow-up proven for **α < 1/3**, global regularity for **α ≥ 1/2**, hence **the live band is
> `1/3 ≤ α < 1/2`**.

The first two clauses are right. **The conclusion is wrong**, in two independent ways.

### (a) The upper half of the band was closed in 2011, for positive data

Barbato, Morandin & Romito, *Smooth solutions for the dyadic model*, **Nonlinearity 24 (2011)
3083–3097** (arXiv:1007.3401), Theorem A, verbatim:

> "Let β ∈ (2, 5/2], then for every initial condition `(x_n)_{n⩾1}` such that `x_n ⩾ 0` for all
> `n ⩾ 1`, and `Σ x_n² < ∞`, there exists a **unique** solution to problem (1.1), which is
> **smooth**, that is `sup_n (λ^{γn} X_n(t)) < ∞` for all `γ > 0` and `t > 0`."

Their `β` is our `1/α` — confirmed twice independently: (i) the survey below gives `θ = 1/γ`;
(ii) BMR themselves write "If β ⩽ 2 … Cheskidov [4] proved existence of regular global
solutions … if β > 3 … all solutions with large enough initial condition develop a blow-up",
which maps exactly onto α ≥ 1/2 and α < 1/3. So **β ∈ (2, 5/2] ⟺ α ∈ [2/5, 1/2)**.

BMR's result is *stronger* than Cheskidov's where they overlap in conclusion (uniqueness and
smoothness, from mere `ℓ²` data rather than `V = H^α`) and *narrower* in hypothesis (positivity).

Confirmed independently by the field's own survey — Cheskidov, Dai & Friedlander,
*Dyadic models for fluid equations: a survey* (arXiv:2209.10203), verbatim:

> "The gap was made smaller thanks to a regularity result of Barbato, Morandin and Romito. The
> authors showed global regularity for (3.6) with γ ≥ 2/5 … **Therefore, [9] settles that
> solutions to the dyadic model corresponding to the 3D NSE are globally regular.**"

That sentence is written by the author of the α ≥ 1/2 theorem himself.

### (b) Both bounding theorems assume positivity — so there are *two* bands, not one

Cheskidov's blow-up theorem (arXiv:math/0601074, Thm 5.3) begins "Let `u(t)` be a solution to
(3.1) with **`u_n(0) ≥ 0`** and α < 1/3", and additionally requires *large* data
(`‖u(0)‖_γ > M(γ)`) — it is not "every solution blows up". BMR likewise require `x_n ≥ 0`.
Cheskidov's regularity theorem (Thm 4.4, α ≥ 1/2) requires **no** positivity.

Hence:

| data class | blow-up proven | regularity proven | genuinely open |
|---|---|---|---|
| **positive** (`u_n(0) ≥ 0`) | α < 1/3, large data | **α ≥ 2/5** (BMR) | **[1/3, 2/5)** |
| **sign-changing** | *nowhere* | α ≥ 1/2 (Cheskidov) | **(0, 1/2)** |

## 2. The instrument was wrong, and its own positive control encoded the error

`tests/tier_b_regime_adequacy.py` asserted, as its **positive control anchor**:

```python
assert classify(Q(2, 5)) == "OPEN", "anchor: 2/5 is interior to the open band"
```

α = 2/5 is precisely BMR's endpoint — the one value in the file that is *most* certainly not
open for positive data. A Tier B gate was returning a wrong verdict, and the wrongness was
built into the control that was supposed to prove the gate meaningful.

**This is the LL-12/LL-15 lesson recurring one level up.** The file had both controls, both
fired, and the gate passed — because *a control can only test the code against the thresholds
you believe*. Neither a negative nor a positive control can detect a mis-stated premise. Only
re-reading the primary source can, which is LL-6 — and LL-6 had been applied to this very
paper before (it is cited in `LL.md` for exactly this reason), but only to its *abstract*,
which does not carry the β-range.

**Correction applied**: `classify(alpha, data)` now takes the data class; thresholds are
`BLOWUP_BELOW = 1/3`, `REGULAR_FROM_POS = 2/5`, `REGULAR_FROM_ANY = 1/2`; and a **regression
control** now asserts `classify(2/5, "positive") == "PROVEN_REGULAR"` — the exact anchor that
was wrong — so the too-wide band cannot silently return.

## 3. The strategic consequence (owner's call, not the instrument's)

With intermittency dimension `d = 5 − 2/α`: `α = 2/5 ⟺ d = 0` and `α = 1/3 ⟺ d = −1`. So the
residual positive-data band `[1/3, 2/5)` sits at `d ∈ [−1, 0)` — **outside** the physically
relevant range `d ∈ [0, 3]` that the survey names. Working there is legitimate mathematics but
must not be described as bearing on 3-D NSE; the survey explicitly says the physically
relevant regime is settled.

**Where the room actually is: sign-changing data.** Below α = 1/2 nothing is proven in either
direction for data of variable sign, because both bounding theorems assume positivity. That is
a wider open region than the one this repository was targeting, it is not disposed of by BMR,
and it is a more defensible framing than "the band [1/3,1/2) is open" full stop.

## 4. Recommended target for the formalisation track, and its honest description

**Cheskidov Theorem 4.4 (α ≥ 1/2, any sign, `u₀ ∈ V`): global strong existence.** Reasons:

- The argument is elementary and fully reconstructed from the PDF: the enstrophy estimate at
  α ≥ 1/2 gives `(B(u,u), Au) ≤ c_b|Au|‖u‖²`, hence a Riccati inequality
  `½ d/dt‖u‖² ≤ −ν|Au|² + c_b|Au|‖u‖² + (g,Au) ≤ −(ν/3)|Au|² + (3c_b²/4ν)‖u‖⁴ + (3/4ν)|g|²`;
  a finite-time blow-up would force `‖u(t)‖² ≥ c/(t*−t)`, which is not locally integrable and
  contradicts the energy inequality. The threshold `1/2` enters at exactly one place: the
  general estimate carries `|Au|^{1/α−1}`, and `1/α − 1 = 1` precisely at `α = 1/2`, which is
  what makes Young absorption against `−ν|Au|²` possible. That is also *why* energy methods
  cannot go below it and why BMR needed invariant regions instead.
- **No PDE machinery is required.** Cheskidov notes that weak and classical solutions coincide
  here ("since `(B(u,u))_n` has a finite number of terms"), and `H^γ` is a weighted sequence
  space. Regularity *is* boundedness of the enstrophy norm. The real formalisation cost is
  infinite sums (convergence, the rearrangement behind `(B(u,v),v) = 0`) and the Galerkin
  existence theory — not the differential inequality.
- Honest description of what it would be: **a formalisation of known mathematics** (2006), and
  an **existence** statement — Thm 4.4 does *not* assert uniqueness. Both must be stated
  plainly wherever the result is cited.

**No prior formalisation found** of dyadic or shell models in mathlib, the Archive of Formal
Proofs, arXiv, or public Lean Zulip archives as of 2026-08-15 (`lean-dojo/LeanMillenniumPrize
Problems` contains only a `sorry`-bodied NSE statement skeleton, no dyadic content). Absence of
evidence is not evidence of absence: a direct Zulip search is recommended before any "first
formalisation" claim is published.

## 5. Two recent papers that look relevant and are not

- **Looi (Caltech), Princeton seminar 2026-04-02**, "Global Regularity for a Viscous Dyadic
  Model" — the **Obukhov** model (`ȧ_j = λ_j a_{j−1}a_j − λ_{j+1}a²_{j+1}`), a *backward*
  cascade, not Katz–Pavlović. No preprint located.
- **Palasek, arXiv:2407.06179**, non-uniqueness in the Leray–Hopf class — **also Obukhov**.

Recorded here so they are not rediscovered and misattributed later.

## 6. Sources

All three principal papers were retrieved as PDFs and read in full text (not abstracts):
Cheskidov arXiv:math/0601074v2; Cheskidov–Dai–Friedlander arXiv:2209.10203v2;
Barbato–Morandin–Romito arXiv:1007.3401v1 (= Nonlinearity **24** (2011) 3083–3097,
doi:10.1088/0951-7715/24/11/004). Abstract-only: Palasek arXiv:2407.06179,
Barbato–Morandin arXiv:1201.2693 (*inviscid* — does not bear on the viscous band).
