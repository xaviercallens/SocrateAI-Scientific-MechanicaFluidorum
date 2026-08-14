# E-3 — The programme's formal target is a case where regularity is already a published theorem

**Filed:** 2026-08-14, orchestrator. **Rule triggered:** `PLAN.md` §3 **E-3** (*"your result
contradicts a `LEDGER.md` row — this is a **discovery**, report it prominently, do not bury
it"*). **Status:** finding delivered; the decisions it forces are the human owner's.

## What I was doing

Preparing decision options on D6 (the redesigned uniformity measurement) and OP-2-lite. Both
rest on the premise that whether the truncated viscous Katz–Pavlović model stays bounded is an
**open** question the programme is measuring.

## The finding

It is not open for our parameters. Verified from the primary source, not from memory or a
summary (LL-6).

**Cheskidov, arXiv:math/0601074, equation (1.1), quoted verbatim from the paper:**

```
d/dt u_n + ν λ^{2αn} u_n − λ^n u_{n−1}² + λ^{n+1} u_n u_{n+1} = g_n ,   n ∈ ℕ
```

with `λ > 1` the dyadic ratio, `α > 0` the **dissipation degree**, `ν ≥ 0` the viscosity. The
paper's thresholds, also quoted from the abstract: **finite-time blow-up for `α < 1/3`**
(improving Katz–Pavlović's `α < 1/4`), and **global regularity for `α ≥ 1/2`**. It further notes
that `α = 1/3` "enjoys the same estimates on the nonlinear term as the 4D Navier–Stokes
equations".

**This programme's model** (`PLAN.md` §5; `lean_src/EnstrophyProduction.lean`;
`DyadicShell_Statements.shellB`), with `k_n = 2ⁿ` and no forcing, is

```
d/dt a_n + ν k_n² a_n − k_{n−1} a_{n−1}² + k_n a_n a_{n+1} = 0
         = ν 2^{2n} a_n − 2^{n−1} a_{n−1}² + 2^n a_n a_{n+1}
```

- **Nonlinear terms:** the same structure at `λ = 2`, uniformly shifted by one factor of `λ`
  (`2^{n−1}, 2^n` here versus `2^n, 2^{n+1}` there). A uniform rescaling of amplitude/time
  absorbs it; the *relative* scaling of the two terms — the part that carries the cascade
  physics — is identical.
- **Dissipation:** `ν 2^{2n}` against `ν λ^{2αn}` with `λ = 2` gives `2αn = 2n`, i.e.

> ## **α = 1**, and `1 ≥ 1/2`, so **global regularity for this model is a published theorem.**

## Why this matters, concretely

1. **The uniformity question the programme has been measuring is settled in the affirmative for
   its own parameters.** Two numerical campaigns were confirming a theorem. This is consistent
   with — and explains — everything observed: the boundedness, the flatness, and the fact that
   nothing ever blew up except through discretisation artifacts.
2. **It compounds the grid defect found the same day.** That defect was "the experiment varied a
   parameter over a range where it could have no effect". This one is "the experiment ran in a
   regime where the answer is forced by a theorem". Both are the same failure at different
   levels: **an instrument pointed where no signal can exist.** The grid gate now catches the
   first; nothing was catching the second.
3. **OP-2-lite, as designed, cannot produce a signal.** Its question is whether the Sym² lock
   "buys exponent". At `α = 1` the *unlocked* system is already globally regular, so the lock
   has nothing to prevent. A null result would be uninterpretable, and a positive result would
   be evidence of an implementation artifact rather than of a mechanism.
4. **The Lean target is still worth pursuing, but its value must be restated honestly.** A
   machine-verified regularity proof for `α = 1` would be a genuine first *as a formalisation* —
   which is exactly what the external auditor said made the pivot attractive — but it would be
   formalising **known mathematics**, not establishing new mathematics. The ledger and the report
   must say so.

## What is NOT affected

- The Tier A algebraic results (production identity, local bound, energy conservation of
  `shellB`, the triad identity) are unaffected: they are exact identities, true regardless of
  which regularity regime the model sits in.
- The pivot itself remains correct. The audit's verdict — that the formalisation describes a
  dyadic shell model — stands. What changes is *which* dyadic question is worth asking.

## The smallest question that unblocks

**In which dissipation regime should the programme work?** The scientifically live band is
`1/3 ≤ α < 1/2` — between the proven blow-up and the proven regularity — with `α = 1/3` singled
out by Cheskidov as matching 4-D Navier–Stokes nonlinear estimates. Options and trade-offs are
laid out for the owner; this file only establishes that the current choice `α = 1` is not a live
question.

**I have not changed the model.** Changing `α` changes what the programme studies, which is a
statement-level decision (E-4) and therefore not mine to take.
