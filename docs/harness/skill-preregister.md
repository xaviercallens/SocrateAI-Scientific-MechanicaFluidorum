---
name: preregister
description: Register a measurement's protocol, its predicted outcome, and whether it can actually discriminate between the hypotheses in play — BEFORE the run that produces it. Use when about to launch a Tier C scout run, extend a registered protocol (S-2, S-3, …) to a new point, start a parameter sweep, or otherwise produce a number that will be read as evidence. Also use when a series of two or three points is about to be described with a word like "saturating", "decelerating", "growing", or "converging".
---

# Pre-register the measurement, then run it

This repository already derives and registers before measuring (`PLAN.md`, `SPEC.md` §7.3). This
skill is the step that kept getting skipped: registering what the run is **predicted to return**,
and whether that prediction can be **told apart** from its rival. Origin: `LL.md` LL-20, where
three points were called "decelerating" from their ratios while their differences grew, and the
protocol's registered decisive point turned out not to be decisive.

Work the five steps in order, write the result into the governing memo (`docs/designs/*.md`) as a
numbered subsection, and **commit it before launching the run.** The commit timestamp is the
whole point — it is what makes the later reading a test rather than a fit.

## 1. State the question as a discriminating pair, not as an observable

Not "does `Z_max/Z₀` grow with `M`?" — any number answers that. Write the hypotheses the
programme actually cares about, as **functional forms with parameters**:

> H_sat: `e(M) = e_∞ − A·M^(−β)`, `β > 0` — the excursion approaches a ceiling.
> H_div: `e(M) = c·(log₂ M)²` — the excursion grows without bound, slowly.

If the rival hypothesis cannot be written as a form, the run cannot discriminate and you are
collecting description, not evidence. Say that in the memo rather than proceeding quietly.

## 2. Fit every form to the points you already have; report inadmissible parameters

An exact fit exists whenever parameters ≥ points, so **the fit is not the test — the parameter's
sign and range is.** A saturating claim needs `β > 0`. If the fit returns `β < 0`, the only
member of that family through your points *diverges*, and the saturating reading is dead however
comfortable it looked. (LL-20: the fit returned `β = −0.53`.)

Do this in a script in the scratchpad, never in prose. Put the script's output in the memo.

## 3. Report the trend in the units the claim is about

Print **both** the ratios and the differences of the series, side by side. They can decelerate
and accelerate at the same time — which is exactly what happened:

```
e(M)  = 0.0023, 0.0122, 0.0265
ratios:      ×5.30, ×2.17     <- "decelerating"
differences: +0.0099, +0.0143  <- growing
```

State which one the claim rests on. For "saturation" the **differences** must turn over; a
falling ratio is not evidence of a ceiling.

Then look for a **bookkeeping mechanism** that would generate the trend with none of the physics.
A ratio climbing toward a hard ceiling — a surviving fraction, an efficiency, a probability —
forces fast early growth and later deceleration by itself. In LL-20 the surviving fraction
`e/ΔZ_inj` ran `0.147, 0.418, 0.571` toward a ceiling of 1, and accounted for most of the
observed deceleration. If such a mechanism exists, say so and quantify it.

## 4. Predict the next point, with a bracket, by two independent routes where possible

Write the number down:

> Predicted: `Z_max/Z₀|_{M=16} ≈ 1.040–1.052` — (a) divergent `c(log₂M)²` with `c` fixed at
> `M = 8` gives 1.047; (b) the survival-fraction bracket gives 1.040–1.052.

Two routes agreeing is worth much more than one route quoted to three decimals.

## 5. THE STEP THAT SAVES THE COMPUTE: check the prediction can discriminate

Evaluate **every** hypothesis from step 1 at the point you are about to run. If their predictions
overlap within the spread of the estimates, **the run cannot decide the question** — and you
learned that for free, before spending the machine.

When that happens, do not cancel silently and do not quietly keep calling the run decisive.
Record in the memo:

- what the point is **still** worth — usually a falsification test of step 3's bookkeeping model,
  where a return *outside* the bracket is the informative outcome;
- **which** point would discriminate, and its cost via the `cost-model` skill;
- an explicit withdrawal of the protocol's claim of decisiveness.

## Definition of done

- [ ] Rival hypotheses written as parameterised forms.
- [ ] Every form fitted to existing points; inadmissible parameters reported with values.
- [ ] Ratios **and** differences printed; the claim's units named; bookkeeping mechanism checked.
- [ ] Predicted value or bracket for the next point, ideally by two routes.
- [ ] Discrimination check done; the discriminating point named with its cost.
- [ ] Written into the governing memo and **committed before the run launches**.
- [ ] `LEDGER.md` records what was registered, never a verdict.

## What this skill must never do

Never write a prediction after seeing the result and present it as pre-registered. If numbers
already exist, the honest artifact is a *post*-diction, labelled as one. The commit timestamp is
the only thing this skill provides; forging it destroys its entire value.
