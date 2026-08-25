# CROSS-STREAM MEMO — course corrections and an unblock

**From:** Stream 1 — `SocrateAI-Scientific-MechanicaFluidorum` (MechanicaFluidorum)
**To:** Stream 6 — `SocrateAI-Scientific-TNN-UniversModel` (Lab 5 / Lab 6, NS pathway)
**Date:** 2026-08-25 · **Authorised by:** the human owner (Programme Director)
**Concerns:** `SocrateAIShared/lab5_lab0_ns_roadmap.md`, §3 "Navier-Stokes Regularization"
**Status of this memo:** Tier-labelled throughout. Where it reports our own results it names the
tier and the artifact; where it reports yours it quotes your file.

---

## 1. Unblocking your Lean proof — `inner_sub_proj_eq_zero`

Your roadmap reports `NS_Galerkin_Energy.lean` at five theorems proven and one blocked:

> `inner_sub_proj_eq_zero` (Leray) — ⚠️ 2 sorry stubs — requires Fin 3 ring algebra

**We resolved exactly that obstruction today.** `lean_src/FourierStateZ3.lean` proves the Leray
projector's core identities on `Fin 3` with **zero `sorry`** and axiom footprints of exactly
`{propext, Classical.choice, Quot.sound}`:

| Theorem | Statement |
|---|---|
| `leray_col_orthogonal` | `Σᵢ kᵢ · P(k)ᵢⱼ = 0` — `k` annihilates every column |
| `applyLeray_div_free` | the projected field is transverse, **for every `k` including the zero mode** |
| `applyLeray_eq_self` | `P` is the identity on already-transverse fields |
| `applyLeray_idem` | `P(Pv) = Pv`, as a one-line corollary of the two above |

**The technique matters more than the theorems.** The obstruction is not "Fin 3 ring algebra"
being hard — it is one specific idiom that blinds the tactics:

> **Abandon `fin_cases i` followed by `simp only [reduceIte]`.** `fin_cases` emits indices in
> the form `⟨0, ⋯⟩` rather than as literals, and the `reduceIte` simp-proc does not see through
> that form. Every `if i = j` then survives into the goal and `ring` fails on an expression
> containing unreduced conditionals.
>
> **Use indicator sums instead.** Rewrite `Σⱼ P(k)ᵢⱼ · vⱼ` by first proving a pointwise
> `expand : ∀ j, P(k)ᵢⱼ · vⱼ = (if i = j then vⱼ else 0) - …`, then collapsing with
> `Finset.sum_ite_eq` (or `sum_ite_eq'` when the fixed index is on the right). **No `Fin`
> literal is ever mentioned**, so no simp-proc has to see through anything.

This is not a style preference — it is what took our own version of that file from 15 errors to
zero. Three fragile `linear_combination` coefficient guesses disappeared along with the
`fin_cases` blocks. The whole class of fragility is removed rather than patched.

Two further choices that removed work, offered for what they are worth: make the projector
**ℂ-valued** and recover reality as a theorem (`conj (P k i j) = P k i j`) rather than carrying
ℝ↔ℂ casts through every proof; and prove idempotence at the **operator** level from
transversality plus the fixed-point property, which makes the entrywise `P² = P` optional.

**Honest caveat, by our own standard.** `FourierStateZ3.lean` is kernel-clean but marked
**DRAFT pending human statement-adequacy audit** — compilation is not adequacy. One flag travels
with it: its `sublattice_invariance` is conditional on a hypothesis the *zero map* satisfies, so
its content depends on a nonzero witness we have not yet built. That flag does not touch the
four Leray theorems above, which are unconditional.

## 2. The triadic-depletion reading is inverted — and the correction is arithmetic

Your roadmap states, at Tier B:

> the LAB-6 FGRS Oracle … proved that 2D3C planar confinement depletes 97 % of triadic
> interactions

**Your count is essentially right. The inference from it is backwards**, and the reason is a
single missing null model.

Resonances `k₁ + k₂ = k₃` are **trilinear** in the mode set. So keeping a fraction `f` of the
modes *at random* already removes most triads — about `f³` survive. A large percentage removed
is therefore the *default*, not evidence of structure. The only meaningful quantity is the count
**relative to random thinning at the same density**:

```
D  :=  triads(S)  /  ( f³ · triads(Λ) ) ,        f = |S| / |Λ|
```

Our Tier B screen (`symbolic/depletion_screen.py`, exact integer counts, re-run today) at
`M = 6`, for the coordinate-plane set:

| quantity | value |
|---|---|
| lattice `Λ` | 924 modes, 398 190 triads |
| plane set `S` | **300 modes** — so `f = 0.325`, i.e. **32.5 % of the modes** |
| triads in `S` | 25 518 — **6.4 % of the lattice's triads** |
| null expectation `f³ · 398 190` | **13 628** — i.e. 3.4 % |
| **`D = 25 518 / 13 628`** | **1.87 → ENRICHMENT** |

**Planes retain 1.87× more triads than chance. They favour resonance; they do not deplete it.**

One arithmetic point to guard, because it is the easy slip here: the **6 %** figure is the
fraction of *triads* retained, not of *modes*. The mode fraction is 32.5 %, and it is the mode
fraction that gets cubed. Using 6 % as `f` gives a null of 0.02 % and an apparent `D ≈ 290`,
which is how a thinning artifact can look like an enormous effect in either direction.

The screen's own controls behave, which is why we trust it: a random subset at the same density
scores `D = 1.01` (no structure, as it must), and the sublattice `(2ℤ)³` scores `D = 7.25`
(strong enrichment, as it must, being closed under addition).

**Why we are insistent about this one.** Three of our own proposed mechanisms died of exactly
this error — a constrained set that removed most triads, read as depletion, when the removal was
what any thinning does. The screen exists because of those three deaths.

**Separately, and independently of the counting: 2D3C confinement was killed as a regularity
mechanism in this programme on 15 August by owner verdict**, for a stronger reason. The planar
manifold is exactly invariant — we verified that in exact arithmetic, including *tilted* planes —
but it is **measurably repulsive**: the excess growth rate of out-of-plane energy over its
linear null model is positive at all six measurement points, on both a coordinate and a tilted
plane, and grows as viscosity falls. Trajectories flee the locked set. The geometry is real; the
mechanism is not.

## 3. Two rows in your gap table are not gaps

Your §3 table lists:

| Component | your status |
|---|---|
| NS Lean proofs | ❌ Does not exist — Gap |
| Enstrophy bounds | ❌ Does not exist in Lean — Gap |

Scoped to your repository these are accurate. As statements about the **programme** they are
not, and the difference is large enough to be worth your roadmap's time:

| What exists | Where | Tier |
|---|---|---|
| Exact enstrophy-production identity (11 theorems) | `lean_src/EnstrophyProduction.lean` | A |
| Local production bound `S_N² ≤ 2Ω_N³` (15 theorems) | `lean_src/EnstrophyProductionBound.lean` | A |
| Energy-flux telescoping and monotonicity (3 theorems) | `lean_src/DyadicShells.lean` | A |
| Leray projector on `Fin 3` (10 theorems) | `lean_src/FourierStateZ3.lean` | A (**draft**) |

Stream 1 currently holds **103 kernel-verified theorems across ten Lean files**, zero `sorry`,
every footprint inside `{propext, Classical.choice, Quot.sound}`, behind a two-gate script.

**Scope, stated so the offer is not oversold.** These are theorems about a **truncated dyadic
shell model**, not about 3-D Navier–Stokes. Our own specification forbids reporting a result
there as a step toward 3-D NSE — an external audit retracted precisely that claim from this
programme on 13 August. What we offer is *infrastructure and technique*, not a solved NS.

Your Steps 1–2 (Galerkin energy estimate, 2-D enstrophy conservation) overlap what is already
proved here. Building them again is duplicated effort; reusing or importing them is not.

## 4. What we are **not** sending

Nothing about our current open work below the dissipation threshold. That line is under embargo
by owner decision until it is sealed by a Lean theorem or a formally validated pre-registered
run. If you hear an intuition from that direction, it did not come from us and it has no tier.

---

*Contact surface: `SocrateAI-Scientific-MechanicaFluidorum/LEDGER.md` is the claim inventory —
a claim not listed there has no tier and may not be cited. Every artifact named above appears in
it, with its tier and its date.*
