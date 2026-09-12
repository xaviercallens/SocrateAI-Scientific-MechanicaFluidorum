# Design memo — dynamic access: the pivot's objects, proposed in exact form

**Status: PROPOSAL of definitions for owner adoption (rule E-1), with one object already
Tier A and one pre-registered exact experiment.** Written on the Deep Think adjudication of
2026-09-12 ("bounds must be derived DYNAMICALLY from the PDE restricting access to such
states"; next phase: dynamic invariant regions and suppression of the sweeping effect) and the
owner's order to continue on the harder part. **Author:** Fable. Nothing here is a proof of
regularity or evidence about the limit; obstruction O5 stands until a theorem says otherwise.

---

## 1. What the kill established, stated as the pivot must use it

Kinematically — over the set of *all* Galerkin states at a given truncation — the production
sum does not cancel uniformly: exactly constructed adversarial states reach cancellation ratios
that *rise* with `M` while the random null's fall (4.2× → 11.2× → 28.4× at `M = 2, 3, 4`). So
any bound on production uniform in `M` must exclude those states, and only the dynamics can
exclude them. The pivot's question is therefore not "how much does the sum cancel" but

> **does the Galerkin flow reach, sustain, or leave the adversarial region?**

Everything below is machinery to make that question exact.

## 2. Objects proposed for adoption

### 2.1 The disparity decomposition — **Tier A, done**

`FourierDynamicsZ3` §12. For an ordered triad, `disparity(p,q) := |r|² − |q|²`, `r = −(p+q)`.
The production is a **partition** over the integer disparities occurring on the ball:

`2P = −i · Σ_δ P_δ`, `P_δ := Σ_{triads with disparity δ} productionTerm`
(`enstrophy_production_decomposition`).

Two free facts, proved: the `δ = 0` fiber is **identically zero** — same-shell advection, the
discrete face of Kraichnan sweeping, produces no enstrophy by the algebra alone
(`productionFiber_zero`, `productionTerm_eq_zero_of_same_shell`); and the decomposition drops
and double-counts nothing, so "how much production comes from large disparity" is well-posed.

**Proposed reading for the pivot's "suppression of the sweeping effect":** exact at `δ = 0`,
linear in `|δ|` near it. The dangerous production is *non-local in scale* — large `|δ|`. A
"sweeping-suppression" statement worth proving would bound the small-`|δ|` fibers by
`|δ|·(something dynamically controlled)`; the large-`|δ|` fibers are where the problem lives.

### 2.2 The adversarial set

`A_ρ₀(M) := { u ∈ GalerkinState M : ρ(u) ≥ ρ₀ }` with `ρ` the ℓ¹ cancellation ratio of
`tier_b_production_cancellation.py`. Established: `A_{0.15}(M) ≠ ∅` for `M = 2, 3, 4`, by
exhibited states. Definition is instrument-level (no square roots, exact), not a spec object;
it needs no owner authorship, only this record.

### 2.3 Dynamic access, and the first legal dynamical object

The programme has no time variable at Tier A (the balance laws are algebraic rates by design).
The first dynamical object that stays **exact** is the discrete-time map

`Φ_{dt}(u) := u + dt·F(u)`, `F_k = −ν|k|² u_k + B(u,u)_k`, `dt, ν ∈ ℚ`,

on Gaussian-rational Galerkin states. It is *not* the flow; it is forward Euler, and it is
proposed only for what it can honestly support: **short-horizon, exact, qualitative direction
of `ρ` under the dynamics**, with a step-halving consistency check. Its one exact invariant is a
gift from Task 2.2: since `Re⟨u,B⟩ = 0` is Tier A,

`E(Φu) − E(u) + 2·dt·ν·D(u) = dt²·‖F(u)‖²` **exactly**,

which the harness asserts at every step — a *dynamic* regression of `energy_conservation`.

**Dynamic access question (proposed):** for `u₀ ∈ A_ρ₀`, does `ρ(Φⁿu₀)` fall toward null
levels (dynamics *scrambles* alignment), hold, or rise? For `u₀` null, does `ρ` stay at null
levels (dynamics does not *create* alignment)?

### 2.4 What "dynamic invariant region" must mean, if it is to be provable

The retired task failed for want of a definition. The minimal shape that could carry a proof:
a set `R ⊆ GalerkinState M` with (i) `Φ_{dt}(R) ⊆ R` (or flow-invariance, once a flow exists
at Tier A), and (ii) a bound on `R` of the form `|P(u)| ≤ c·D(u)^θ·E(u)^{1−θ}` with `c, θ`
**independent of `M`**. Candidate (ii) is the aspirational shape from the previous workflow; it
is **not** proposed as a definition yet, because no evidence supports any specific `R`. The
experiment below is what would suggest one.

## 3. Pre-registered experiment (Tier B, exact) — `tests/tier_b_dynamic_access.py`

**Setup.** `M = 2`; `ν = 1/20`; `dt ∈ {1/32, 1/64}` run to the same physical time `1/8` (4 and
8 steps) — the horizon is short because exact rational iteration of a quadratic map squares
denominators each step (recorded lesson). Two initial conditions: **the adversarial state**
found by the greedy alignment (`ρ₀ ≈ 0.15`, exact), and a **random-phase null** state.

**Measured, exactly, per step:** `ρ`, `E`, `D`, the enstrophy `Z`, and the energy-step identity
residual (must be exactly zero).

**Hypotheses, stated before running.**
- **H-scramble** (the pivot's hope): from the adversarial IC, `ρ` falls toward the null level
  within the horizon.
- **H-quiet**: from the null IC, `ρ` stays at null level — the dynamics does not create
  alignment.
- **Failure modes:** `ρ` from the adversarial IC holds or rises ⟹ alignment is dynamically
  self-sustaining and the pivot's premise is in trouble; `ρ` from the null IC rises ⟹ the
  dynamics *creates* adversarial states, which is worse.
- **Consistency:** the two `dt` runs must agree in *direction* at the common time; if they do
  not, the horizon is too coarse and nothing is read.

**Scope.** Four to eight Euler steps at `M = 2` are a *direction of travel*, not a result about
turbulence, the limit, or Hypothesis U. Long horizons and larger `M` go to `exploration/` in
floating point (Tier C) with this exact run as their calibration.

> **First-run outcome (2026-09-12) and AMENDMENT 7, recorded before the second run.** The
> arithmetic held — the energy-step identity was exactly zero at every step, all state
> constraints held — and the registration was **missing a criterion**. Forward Euler's energy
> budget is `E' − E = −2·dt·ν·D + dt²‖F‖²`; at the registered amplitudes the injection term
> `dt²‖F‖²` came out **about 23 times** the physical dissipation `2·dt·ν·D` per step, so energy
> *rose* in every run (`1242 → 6215` at `dt = 1/32`, halving with `dt` exactly as a `dt²`
> artifact must) and `ρ` wandered step to step under the scheme's own dynamics. A run like that
> measures the integrator, not the flow. Two amendments, both fixed before re-running:
>
> 1. **Scheme-fidelity criterion.** A step *counts* only if `dt²‖F‖² ≤ (1/10)·2·dt·ν·D`, exactly;
>    a run with any disqualified step is reported **DISQUALIFIED** and no hypothesis is read
>    from it. This is the criterion any discrete-time proxy must carry, and its absence from the
>    first registration is the lesson.
> 2. **An amplitude-scaled regime.** Since `‖F‖² ∼ λ⁴` while `ν·D ∼ λ²` under `u ↦ λu`, the
>    injection ratio scales as `λ²`; `λ = 1/20` brings it to about `0.06`. This is the
>    *weakly nonlinear* regime — the nonlinear phase drift is first order in `λ·t` — and exact
>    arithmetic is what makes even a tiny change in `ρ` a true direction there. Both `λ = 1`
>    (expected disqualified, kept as the control on the criterion) and `λ = 1/20` are run.
>
> The (disqualified) `λ = 1` numbers are kept in the harness output as data about the scheme,
> not about the flow.
>
> **Second-run outcome (2026-09-12) — BOTH REGISTERED HYPOTHESES ARE FALSE in the qualified
> regime.** `λ = 1` was disqualified at every step (injection ratios 11–100), exactly as the
> criterion's own control predicts. `λ = 1/20` qualified at every step (worst ratio `0.069`),
> energy decayed (`3.105 → 2.993`), the energy-step identity was exactly zero throughout, and
> the two step sizes agree to four decimals at the common time — a clean, exact, consistent
> direction of travel:
>
> | IC | `ρ` at `t = 0` | `ρ` at `t = 1/8` (`dt = 1/32`) | (`dt = 1/64`) | direction |
> |---|---|---|---|---|
> | adversarial | 0.1545 | 0.1889 | 0.1888 | **rose**, monotonically |
> | random-phase null | 0.0005 | 0.0187 | 0.0186 | **rose**, monotonically |
>
> **H-scramble false**: the dynamics does not degrade the adversarial alignment, it sharpens it.
> **H-quiet false** — the "worse" registered failure mode: starting from a random-phase state,
> the dynamics *creates* alignment, driving `ρ` up by a factor of ~40 over the horizon.
>
> **Reading, with the physics that makes it unsurprising in hindsight.** The nonlinearity
> `B(u,u)` is a deterministic quadratic functional of the state; one step of it correlates the
> phases of every interacting triad, and triad-phase coherence is precisely what a trilinear
> production sum detects. Nonzero mean energy transfer *requires* such coherence — turbulence is
> not a random-phase field, which is a textbook fact. So the random-phase null is not a
> dynamically invariant class; it is **dynamically repelling**, and the first exact contact says
> the flow moves states *toward* the adversarial region, not away from it.
>
> **Consequences for the pivot's definitions (§2.4).** (i) A "dynamic invariant region" cannot
> be a neighbourhood of random-phase states, nor any set defined by a *small* cancellation ratio
> — `ρ` grows under the dynamics from both ends. (ii) `ρ` was the right observable for the
> kinematic question and is the wrong one for the dynamic one: the quantity Hypothesis U needs
> along trajectories is the **production-to-dissipation ratio** `P/(ν D)`, i.e. the enstrophy
> balance itself, not the cancellation geometry. (iii) Whether the alignment saturates, reverses,
> or runs away at longer times is **not accessible exactly** — denominators reached 22 000 bits
> at eight steps — so the next contact belongs to `exploration/` (Tier C, RK4, floating point,
> per the recorded lesson on rational iteration), **calibrated against this exact run** on its
> first eight steps before any longer horizon is trusted.
>
> **Scope, restated.** Eight Euler steps at `M = 2` in the weakly nonlinear regime. A direction
> of travel with no bearing on the limit, on regularity, or on Hypothesis U; O5 stands. Its
> value is that it retires one candidate definition before a proof was attempted against it —
> which is what E-1 discipline is for.
