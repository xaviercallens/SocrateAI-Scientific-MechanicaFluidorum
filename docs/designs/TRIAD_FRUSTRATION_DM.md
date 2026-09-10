# Design memo — the triadic "frustration index" 𝒟(M): definition audit and pre-registration

**Status:** `[top]`-authored, hand-derived before any run (LL-5); the run it governs is Tier C.
**Author:** orchestrator. **Date:** 2026-09-09.
**Source of the object:** owner memorandum of 2026-09-09, archived verbatim (Tier C) at
`docs/narrative/MANIFESTE_THEORIQUE_NS.md` §I. **Owner decision of the same day:** write the
enumerator from the definition (no `triad_frustration_Z3.py` exists in this repository), and
compute the three readings side by side **with the null model**.
**Implementation:** `exploration/triad_frustration_rs/` (Rust, zero dependencies, std threads).
**Governing:** SPEC §7.3 (both-direction controls, null model first), LL-11 (a number that
looks like a mechanism because it was never compared to chance), LL-19 (a perturbation is a claim).

---

## 1. What the memorandum defines, and what it leaves open

The memorandum's words: *"Si la somme absolue des transferts (cohérence forcée) croît en
O(M⁶) sur une boule de Galerkin, le transfert net signé … se comporte asymptotiquement comme
une marche aléatoire en O(√M⁶) = O(M³). Par conséquent 𝒟(M) ∝ M⁶/M³ = M³ → ∞."*

So 𝒟(M) = (sum of absolute triadic transfers) / (net signed transfer), on Λ_M = {k ∈ ℤ³∖0 :
|k|² ≤ M²}. Three choices are not made by the words, and each changes the number:

| # | open choice | why it matters |
|---|---|---|
| 1 | **which signed sum** | Over the *whole* ball the signed sum of energy transfers is **exactly zero** — Tier A `AbstractAlgebraicConservation.triad_sum_zero`, Tier B fact 2 of `tests/tier_b_nse_triad_convolution.py`. A ratio with that denominator is ∞ for every M and every field: a vacuous 𝒟, the LL-11 failure mode. Only a *partial* signed sum (a flux across a sphere, or the transfer into a target set) is non-zero. |
| 2 | **on which field** | Triadic transfers are cubic in the Fourier amplitudes. "Depends only on angles and chiralities" is true of the *coefficient*; the *transfer* is coefficient × three amplitudes. |
| 3 | **against which null** | "Random walk ⇒ √(number of terms)" is precisely what *independent random phases* give. It is the null model's own prediction. A computation on random phases that returns M³ confirms the null, and cannot distinguish "the lattice forbids phase locking" from "we put in random phases". |

Choice 3 is the substantive one. It is also why the memorandum's proposed deliverable (*"un
graphique prouvant que 𝒟(M) suit une loi en O(M³)"*) cannot, as posed, seal anything: the
law is the null. What *can* be measured is whether phase-**coherent** fields on the same
lattice, with the same envelope, give the same growth. If they do, the growth is a property of
the lattice geometry (which is the memorandum's actual claim). If they give a much smaller
𝒟, the growth belongs to the random phases, not to ℤ³.

## 2. The model (fixed, not chosen here)

The nonlinearity is the repository's Tier B-certified formula,
`N(u)_k = −i Σ_{p+q=k} P(k)[(q·u_p) u_q]`. Energy transfer into mode k is
`T_k = Re[conj(u_k)·N(u)_k]`. Because `u_k` is transverse the projection drops out of the
pairing (the Tier B derivation), so per **ordered** pair `(p, q = k−p)`:

```
t(k;p,q) = Re[ conj(u_k) · (−i (q·u_p) u_q) ] = Im[ (q·u_p) · (conj(u_k)·u_q) ]
T_k = Σ_p t(k;p,k−p)      (signed)          A_k = Σ_p |t(k;p,k−p)|      (absolute)
```

## 3. The three readings (pre-registered)

- **(a) mid-sphere flux.** `𝒟_a(M) = Σ_{|k|>M/2} A_k / |Σ_{|k|>M/2} T_k|`. Denominator = net
  energy flux across the sphere of radius M/2 (the only signed quantity that is not identically
  zero); numerator = absolute transfer into the outer half. Sphere at M/2 so both sides carry
  comparable populations at every M.
- **(b) outer shell** (the memorandum's "far-UV mode k*", averaged over the shell
  `(M−1)² < |k|² ≤ M²`): `𝒟_b1 = Σ_shell A_k / Σ_shell |T_k|` and `𝒟_b2 = Σ_shell A_k / |Σ_shell T_k|`.
  Both denominators are reported because the words do not say which; b1 is per-mode
  cancellation, b2 adds cross-mode cancellation.
- **(c) pure geometry, no field.** Waleffe's helical basis `h^s(k) = ν×κ + i s ν`
  (Waleffe, *Phys. Fluids A* **4**, 350 (1992)), coefficient `g = −¼(h_p^{s_p*} × h_q^{s_q*})·h_k^{s_k*}`,
  transfer coefficient `C = g·(s_p|p| − s_q|q|)` over ordered triads `k+p+q = 0` in the ball.
  `𝒟_c = Σ|C| / |ΣC|` **per chirality class** `(s_k,s_p,s_q)`.
  **Derived before the run:** under the global chirality flip `s ↦ −s`, `h^{−s} = conj(h^s)`, so
  `g ↦ conj(g)` and `(s_p|p| − s_q|q|) ↦ −(…)`, hence `C ↦ −conj(C)`; and under `(k,p,q) ↦
  (−k,−p,−q)`, `C ↦ conj(C)`. Together: the all-class signed sum is real and equals its own
  negative, so it is **exactly zero**. The all-class reading of (c) is vacuous by symmetry; the
  harness verifies this (control P3) and reports the eight class sums instead.

## 4. Fields: the null model and its comparators

All fields are divergence-free and conjugate-symmetric by construction, with envelope
`|u_k| = |k|^{−γ}`, `γ ∈ {0, 11/6}` (flat, and the Kolmogorov `E(k) ∝ k^{−5/3}` envelope).

| name | phases | role |
|---|---|---|
| `random` (seeds 1..S) | independent uniform phases on both helical amplitudes | **the null model**; the spread across seeds is the ensemble uncertainty |
| `locked_plus` | single chirality (+), every amplitude real positive | coherent comparator 1: maximally helical, "all phases aligned" |
| `locked_quad` | both chiralities, `θ⁺ = 0`, `θ⁻ = π/2` for every k | coherent comparator 2 |
| `arith` | the Tier B harness's deterministic arithmetic construction, renormalised to the envelope | a third, non-random, non-locked structure |
| `real_even` | both chiralities, all phases 0 | **inert, recorded only**: every `u_k` is real, `u(x)` is an even real field, and every `t` is the imaginary part of a real number, i.e. `Σ|T| = 0` identically. Found by the first control run (LL-19: the obvious "phase-locked" comparator was silent by parity). |

**None of these is a solution of Euler or Navier–Stokes.** The only field with a claim to
dynamical relevance would be a time-evolved one, which needs the Euler engine (separate task).

## 5. Controls (run before every measurement; the binary refuses to continue if any fails)

| control | direction | expected answer and its source |
|---|---|---|
| P1 helical basis: `|h|² = 2`, `k·h = 0`, `i k×h = s|k| h` on every mode of Λ₄ | positive | curl-eigenbasis identity (Waleffe 1992); residual < 1e-12 |
| P1-neg: the opposite-sign vector must **fail** the eigen-equation | negative, demonstrated | residual O(1) |
| P2 `Σ_k T_k = 0` for every field kind and envelope | positive | Tier A `triad_sum_zero` / Tier B fact 2; relative residual < 1e-10, **and `Σ|T| > 0`** (a 0/0 pass is inert) |
| P2-neg: inject a longitudinal component on one mode pair | negative, demonstrated | fact 2 needs divergence-free input; residual > 1e-6 |
| P2b `real_even` has `Σ|T| = 0` | recorded finding | the parity argument of §4 |
| P3 all-class Waleffe signed sum vanishes | positive | the §3(c) derivation; relative residual < 1e-10 |

## 6. Pre-registered reading (fixed before the numbers)

For each reading and envelope, fit `log 𝒟` against `log M` on `M ≥ 8`.

- If `random` gives slope ≈ 3 (a, b2) — that is the null and is **expected**; it is not a result.
- The result is the **comparison**: if `locked_plus`, `locked_quad` and `arith` show the same
  slope and magnitude as `random`, the cancellation is geometric (supports the memorandum's
  claim about ℤ³). If the coherent comparators sit well below `random` in 𝒟, or grow with a
  smaller exponent, the cancellation is supplied by the random phases, and the M³ law says
  nothing about the lattice.
- Reading (b1) is bounded by the number of pairs per mode and is reported for completeness.
- Reading (c) is reported per class; its all-class version is vacuous.

**Either outcome is Tier C.** No verdict on Navier–Stokes, Euler, Hypothesis U, or "the
suppression of the UV cascade" follows from any of these numbers, and none will be written
into `LEDGER.md` above Tier C.

## 7. What this memo does NOT do

It does not endorse the memorandum's chain "𝒟 → ∞ ⇒ the cascade is stifled". Even a
geometric M³ growth of an absolute/signed ratio is compatible with a finite, sign-definite net
flux — which is what the Kolmogorov 4/5 law asserts for the inertial range of real turbulence.
A large 𝒟 says the cancellation is large relative to the gross traffic; it does not say the
net flux is small.
