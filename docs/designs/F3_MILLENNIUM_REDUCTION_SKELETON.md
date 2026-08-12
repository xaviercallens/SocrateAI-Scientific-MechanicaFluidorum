# Design memo: F3 — Conditional Millennium Reduction skeleton

**Author:** orchestrator (top-tier authoring step, PLAN.md §4 F3). **Date:** 2026-08-12.
**Status:** design for `lean_src/MillenniumReduction.lean`, written before implementation per
this project's standing practice (derive and hand-verify, then implement/verify — never the
reverse). **Prereq F2 merged:** yes, `HypothesisU_Statements.lean` is compiled and its Q1/Q2
audited (LEDGER.md).

## Objective (verbatim from PLAN.md §4)

> `theorem millennium_reduction (hU : HypothesisU …) (hAL : AubinLionsStatement …)
> (hPS : ProdiSerrinStatement …) : GlobalRegularityStatement …` — the implication chain with
> unproven analysis as named hypothesis parameters (never axioms).

## Why this is not a new invented definition (CLAUDE.md guard-rail)

`AubinLionsStatement` / `ProdiSerrinStatement` / `GlobalRegularityStatement` are not free
invention: PLAN.md §4 F3 already names them and prescribes the signature; SPEC.md §1.1's
Proposition 5.1 and `docs/HYPOTHESIS_U_SPECIFICATION.md` §II already fix the three-step logical
content they must encode (compactness → weak-lower-semicontinuity/Sobolev embedding →
Prodi–Serrin criterion ⇒ global smoothness); `docs/REVIEW-2026-08-12.md` L7 already prescribes
the *form*: park the undischarged analysis in the hypothesis's **type**, not behind an axiom.
What is being derived here is only the precise Lean shape of those three types, built
compositionally from objects `HypothesisU_Statements.lean` already defines and already got
audited (`HypothesisU`, `IsGalerkinSolution`, `enstrophy`) — not new PDE content.

**Explicitly rejected as a source:** the prior tree's `DualScale/NS/AubinLions.lean` /
`DualScale/Physics/AubinLions.lean` (`axiom aubin_lions_compactness` over `VelocityField`,
`MeasureTheory.integral`, `CentralCharge`, `bps_scaling`). That formalization is exactly what
`docs/REVIEW-2026-08-12.md` L5/L7 found defective (numerology contamination, raw axiom) and
what this program's declared scope exclusions (`HypothesisU_Statements.lean` header: "Real
Fourier analysis on 𝕋³... EXCLUDED") already rule out reusing. Only the *naming convention*
(`AubinLionsStatement` as a `Prop`, not a bald axiom) is kept.

## Design

**Self-contained file** (this project's `lean_src/` files do not cross-`import` each other —
verified: `EnstrophyProduction.lean` re-defines `prodOut` rather than importing
`DyadicShells.lean`; `scripts/verify.sh` Gate 2 compiles each file by direct path, not as a
Lake module graph). `MillenniumReduction.lean` therefore re-declares the minimal subset of
`HypothesisU_Statements.lean`'s vocabulary it needs (`IsGalerkinSolution`, `enstrophy`,
`HypothesisU`, `enstrophy_nonneg`/`enstrophy_zero` lemmas) rather than importing it.

**New object — `IsFullSolution`.** The untruncated (`N → ∞`) analogue of `IsGalerkinSolution`:
same evolution law, but (a) initial datum is `u0` directly (no cutoff to project onto — clause
(i) of `IsGalerkinSolution` used `truncate N u0` only because modes above `N` had to vanish;
here no mode is discarded), and (b) no clause (3) (nothing is forced to zero), and (c) the
evolution clause is required for **all `t ≥ 0`, unbounded** — this is the precise, honest
ODE-theoretic translation of "globally smooth solution": a blow-up at some finite `t*` is
exactly the failure of `HasDerivAt` to hold at `t*`, so requiring it to hold for every `t ≥ 0`
*is* "no finite-time blow-up" in this vocabulary, not an inflated gloss on it.

**Avoiding `tsum`/summability.** The continuum statement bounds `‖∇u‖_{L²}` — infinitely many
modes. Rather than introduce Mathlib summability machinery (not yet confirmed built, and a
scope increase), the limit's "boundedness" is stated as: **every finite partial sum** (reusing
the already-defined `enstrophy M w u t`, for arbitrary cutoff `M` applied to the *dynamics*-
untruncated `u`) stays `≤ C`. This is the finite-partial-sum avatar of a uniform bound on the
full (possibly infinite) sum and requires no new Mathlib import.

**Named intermediate — `HasBoundedFullLimit`.** Factors the compactness-step's output type out
so `AubinLionsStatement`'s conclusion and `ProdiSerrinStatement`'s hypothesis are *syntactically
the same type*, not two independently-typed anonymous tuples that happen to match — this is
what makes `hPS (hAL hU)` a direct, no-conversion proof term, and it is what a reviewer should
check first (a mismatch here would be exactly the kind of "Prop placeholder" the DoD warns
against).

```
def HasBoundedFullLimit (nu T : ℝ) (B) (w) (u0) : Prop :=
  ∃ (ulim : ℝ → ℕ → ℝ) (C : ℝ), 0 < C ∧
    IsFullSolution nu B w u0 ulim ∧
    ∀ M : ℕ, ∀ t : ℝ, 0 ≤ t → t ≤ T → enstrophy M w ulim t ≤ C

def AubinLionsStatement (nu T : ℝ) (B) (w) (u0) : Prop :=
  HypothesisU nu T B w u0 → HasBoundedFullLimit nu T B w u0

def ProdiSerrinStatement (nu T : ℝ) (B) (w) (u0) : Prop :=
  HasBoundedFullLimit nu T B w u0 → GlobalRegularityStatement nu B w u0

def GlobalRegularityStatement (nu : ℝ) (B) (w) (u0) : Prop :=
  ∃ u : ℝ → ℕ → ℝ, IsFullSolution nu B w u0 u

theorem millennium_reduction (nu T : ℝ) (B) (w) (u0)
    (hU : HypothesisU nu T B w u0) (hAL : AubinLionsStatement nu T B w u0)
    (hPS : ProdiSerrinStatement nu T B w u0) : GlobalRegularityStatement nu B w u0 :=
  hPS (hAL hU)
```

Note `GlobalRegularityStatement` deliberately drops `T`: existence of a solution whose
derivative-clause holds for *all* `t ≥ 0` is T-independent by construction — matching the real
proof, where `T` is arbitrary-but-fixed on the hypothesis side and global regularity is the
`T`-independent conclusion (SPEC.md §1.1: "Hypothesis U holds for … all T").

**Non-vacuity (SPEC §7.5), scoped honestly.** Proving `HypothesisU` itself achievable requires
ODE uniqueness theory this toolchain excludes — already deferred in F2 via its own
`WITNESS DEFERRED` comment; `AubinLionsStatement`/`ProdiSerrinStatement` inherit the same
deferral (they are hypothesis parameters — the DoD explicitly does not ask for them to be
*proved*, only to be *bona fide statements*). What **is** proved here, matching exactly the
scope of F2's `zero_isGalerkinSolution`: `IsFullSolution` is inhabited (`zero_isFullSolution`,
zero flow given `hB`), and both `HasBoundedFullLimit` and `GlobalRegularityStatement` are
genuinely satisfiable Props, not empty types (`zero_has_bounded_full_limit`,
`zero_global_regularity`) — the minimal bar SPEC §7.5 sets for a *definition*, as opposed to
the (deferred) bar for a *hypothesis about the physical system*.

**Negative controls (hand-derived, to run against a scratch perturbed copy before commit):**

| # | perturbation | expected failure | actually run, 2026-08-12 |
|---|---|---|---|
| NC1 | inline `AubinLionsStatement`'s conclusion as a copy of `HasBoundedFullLimit` with the `0 ≤ t →` guard dropped, instead of using the shared def | `hPS (hAL hU)` no longer type-checks: `hAL hU : ∃ ulim C, … ∀ M, ∀ t ≤ T, …` ≠ expected `HasBoundedFullLimit nu T B w u0` | **confirmed FAIL** — `Application type mismatch` at `hPS (hAL hU)`, exactly this reason |
| NC2 | change `millennium_reduction`'s proof to `hAL hU` alone (drop `hPS`) | type error: expected `GlobalRegularityStatement …`, got `HasBoundedFullLimit …` | **confirmed FAIL** — exact error reported |
| NC3 | delete `hB` hypothesis from `zero_isFullSolution` | body's `rw [hB n]` and downstream callers relying on the hypothesis break | **confirmed FAIL** — `unknown identifier hB`, plus cascading errors at both non-vacuity call sites |

(NC1 as originally sketched — editing the shared `HasBoundedFullLimit` def directly — does NOT
fail, because both `AubinLionsStatement` and `ProdiSerrinStatement` reference the *same* def and
so change in lockstep. That is a feature of factoring the intermediate out, not a gap: it is
exactly what makes the join point robust to this class of edit. The table above tests the
version of NC1 that actually exercises the risk — a caller inlining a slightly different type
instead of using the shared name.)

## DoD checklist (PLAN.md §4 F3)

- [ ] Compiles clean (Gate 2, wired into `scripts/verify.sh`'s file loop).
- [ ] Hypothesis parameters (`AubinLionsStatement`, `ProdiSerrinStatement`) are bona fide typed
      statements built from already-audited vocabulary, not `Prop` placeholders — see design
      above; **full statement-adequacy audit is the human owner's, this only prepares it**.
- [ ] Ledger row at Tier A, explicitly scoped "conditional skeleton — the analytic content
      (Aubin–Lions compactness, Prodi–Serrin criterion) remains open", mirroring F2's own
      DRAFT-pending-audit framing.
