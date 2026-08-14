# Regime map — where the dyadic question is open, and what each regime is for

**Status:** Tier C reference, `[top]`-authored. Not a claim; a map for choosing where to work.
**Owed since:** the owner's request of 2026-08-14, following escalation E-3.
**Author:** orchestrator. **Date:** 2026-08-14.

---

## 1. The one-line correspondence that fixes everything else

The dyadic dissipation term is `ν·k_n^{2α}`. Navier–Stokes dissipation is `νΔu`, whose Fourier
symbol is `−ν|k|²`. Setting `2α = 2`:

> ## **α = 1 *is* the Navier–Stokes dissipation.** It is not an arbitrary choice — it is the Laplacian.

This is not an analogy or a scaling argument; it is the same exponent. And Cheskidov proves
global regularity for `α ≥ 1/2`. Therefore:

> ## The dyadic shell model **at Navier–Stokes dissipation is provably regular.**

That is a fact about dyadic models, not a defect in this programme's choices. It is also the
single most important thing on this page, and it bounds what the pivot can deliver.

## 2. The map

| `α` | Status | Corresponds to | What the regime is *for* |
|---|---|---|---|
| `α < 1/4` | **Blow-up proven** (Katz–Pavlović 2005) | strongly hypo-dissipative | negative control; the original blow-up result |
| `1/4 ≤ α < 1/3` | **Blow-up proven** (Cheskidov 2008, improving the above) | hypo-dissipative | **negative control**, and the *only* regime where a proposed regularising mechanism can demonstrate anything |
| `α = 1/3` | Lower edge of the open band | *"the same estimates on the nonlinear term as the 4-D Navier–Stokes equations"* (Cheskidov's own remark) | the most interesting single point: closest thing to a genuine NSE analogue |
| `1/3 ≤ α < 1/2` | **OPEN** | between 4-D NSE and proven-regular | **the only band where a measurement or proof can discover something** |
| `α ≥ 1/2` | **Regularity proven** (Cheskidov 2008) | includes NSE dissipation | **positive control**; and the tractable target for a formalisation |
| `α = 1` | Regularity proven | **exactly NSE dissipation** | the programme's historical choice; a formalisation target, not a research question |

Mechanised as `tests/tier_b_regime_adequacy.py`, whose negative control is the programme's own
`α = 1`.

## 3. The consequence nobody should have to discover later

Because `α = 1` is NSE dissipation *and* is provably regular, and because the hard dyadic band
sits at `α < 1/2`:

> **The dyadic model's difficult regime corresponds to dissipation *weaker* than Navier–Stokes,
> not to Navier–Stokes.**

So a result in the open band `[1/3, 1/2)` is a result about **hypo-dissipative shell models**. It
is genuinely interesting mathematics — that band is open and `α = 1/3` carries a 4-D NSE
analogy — but it is **not** a step toward 3-D Navier–Stokes, and must never be reported as one.
The dyadic model is a surrogate for the *cascade mechanism*, not for NSE's criticality; at NSE's
own criticality it is simply too easy.

This is the honest ceiling on the pivot. The external audit established that the formalisation
describes a shell model rather than 3-D NSE; this establishes that even a *complete success* in
the shell model's hard regime would not close that gap.

## 4. What changes in the repository per regime

The cost of moving is now low, because `α` is a quantified parameter rather than a constant
(`DyadicShell_Statements.dissipationWeight`, added 2026-08-14):

| Component | Effect of changing `α` |
|---|---|
| `dissipationWeight a n = k_n^{2a}` | the parameter itself; nothing to edit |
| `DyadicShellHypothesisU_alpha a nu T u0` | already α-parametrised |
| `shellB`, `shellB_energy_conservation` | **unchanged** — the nonlinearity does not involve `α`, so exact energy conservation holds in every regime |
| `EnstrophyProduction`, `EnstrophyProductionBound` | **unchanged** — algebraic identities in `k` and `a`, independent of dissipation |
| numerical harnesses | one exponent; the shell step already takes `α` |
| `tests/tier_b_grid_adequacy.py` | **needs generalising**: its dissipation-scale criterion `2^(4N)p³ ≥ q³` was derived for `α = 1`. For general `α` the balance `ν k^{2α} = k·a_n` with `a_n ∼ k^{-1/3}` gives `k_d ∼ ν^{-1/(2α−2/3)}`, valid only for `α > 1/3` — **at and below `α = 1/3` there is no dissipation scale in this sense**, which is precisely why blow-up is possible there. Flagged, not silently reused. |

## 5. Recommendation

The owner has already chosen to work in **both**: `α < 1/3` for the lock experiment, `α = 1` for
the Lean formalisation. This map supports that split and sharpens each side:

- **`α < 1/3` for the lock** is right, and for a sharper reason than "blow-up happens there": it
  is the *only* regime where the unmodified system fails, hence the only one in which a
  regularising mechanism can be shown to do anything. Recommend `α = 1/4`, which is inside both
  Katz–Pavlović's and Cheskidov's proven-blow-up ranges, so the null behaviour is doubly
  attested.
- **`α = 1` for Lean** is right, and should be *described* as what it is: formalising a known
  theorem, valuable as a formalisation first, with no discovery claim attached.
- **`α = 1/3` deserves a place** neither has: it is the open band's edge and the closest dyadic
  analogue of a genuine NSE difficulty. If the programme ever wants a result that is
  mathematically live rather than a formalisation or a control, that is where it is.
