# Deep Think brief — protocol S-5 closed, three standing headwinds unmoved, two decisions waiting

**To:** the programme owner, and Google DeepMind Deep Think via the owner. **From:** Claude
(Sonnet 5, MechanicaFluidorum session). **Date:** 2026-09-17. **Self-contained**: no prior
packet required. Every number below is kernel-verified, exact-arithmetic, or a directly-read
measurement; where something is a model or an extrapolation, it says so.

---

## 0. The one-paragraph version

A three-week numerical thread (S-2 through S-5, the adversarial transient on the greedy-aligned
family, `M = 2` through `64`) is now **closed**, both its float and exact readings certified. It
did what it was built to do — size the Core-Tail certificate's tail envelope — and did not, and
was never going to, touch the actual mathematical blocker. **O5 stands, no verdict.** The three
standing headwinds (the forcing bound's slack, the dynamics generating rather than scrambling
triad alignment, the still-growing transient) are unchanged by any of it. Two concrete decisions
are waiting on the owner and cost nothing to make: **Door #2** (three questions open since
2026-08-25) and **T-2′ adoption** (a measured, tighter forcing bound already sitting proposed).
Both are below with a recommendation, not just a restatement. Section 4 is the actual open
question worth Deep Think's attention: where the self-consistency closure itself stands and
what a next concrete step there looks like.

## 1. What is established (Tier A unless marked)

The fixed-`M` ledger closed weeks ago and is unchanged this cycle: energy conservation and the
exact enstrophy-production identity for the Leray-projected truncated nonlinearity on `ℤ³`
(`2 Σ_k |k|²⟨u_k,B_k⟩ = −i Σ_{triads} (|r|²−|q|²)(q·u_p)(u_q·u_r)` — the entire obstruction is
the single factor `|r|²−|q|²`), the viscous balance laws, the helical triad coefficient's closed
form and its converse (closing the inventory of inert triads at two members: collinear triads
and the balance condition), the torus 2-section spectrum, the T-dual effective-radius laws. 193
kernel-verified theorems across 12 Lean files, zero `sorry`, footprint
`{propext, Classical.choice, Quot.sound}` throughout. Nothing in this cycle touched any of it;
it is restated here only so this brief is self-contained.

## 2. What this cycle actually did: closed the numerical thread, both readings

**The question.** On one constructed adversarial family (greedy-aligned sign vectors maximising
the exact triad-sum objective `S(σ)`, at fixed `E₀`, `ν`), does the transient enstrophy
excursion `Z_max/Z₀` saturate as `M` grows, or keep growing? Six doublings now on record:

```
M =            2       4       8      16      32      64
Z_max/Z₀ − 1   0.0023  0.0122  0.0267  0.0324  0.0386  0.0431
local exponent 2.407   1.130   0.279   0.253   0.158
```

**Still growing, decelerating, not saturated at `M = 64`.** Three registered predictions were
falsified along the way and reported as falsified (divergent on three points → saturating on
four → neither on five → decelerating-but-still-growing on six); every reversal is attributed to
a named factor because each bracket was fixed before the number that tested it existed
(`CORE_TAIL_CAP.md` §4.3.4–4.3.11).

**Reaching `M = 64` at all needed a different search.** The exact greedy that produced every
earlier point is `O(M⁶)` per sweep; at `M = 64` that is an estimated `~80` days. A spectral
(FFT-gradient, damped-Jacobi) optimiser plus a fixed-budget, pre-registered screen for its
schedule (three independent proposer agents from different lenses, checked against the actual
code before running — which caught a real convergence bug — then a judge fixing the final
design and a mechanical decision rule) reached the same point in `7.7` h
(`SPECTRAL_ALIGNMENT.md` §3.2(C)). A family-equivalence control, registered before the `M = 64`
sign vector existed, confirmed the screened optimiser's result extends the existing series
rather than opening a second one.

**Both readings are now certified, not just one.** The float record above. The exact
`i128` record, reached on rented compute after real infrastructure trouble (§3 — GCP job, three
separate bugs, all diagnosed and fixed, none in the actual computation):
```
S(σ) = 13 477 832 078 223 027 252 042 752
```
every one of `548 958` classes checked, none improving it — matching the float record exactly
(`init = best`, `0` polish flips), extending the strict-local-optimum-of-the-exact-objective
pattern from `M = 8, 16, 32` to the fourth point running.

**What this does and does not mean.** It bounds one constructed adversarial family's transient
and sizes the Gevrey tail envelope the Core-Tail certificate must cover — nothing more. Not the
dynamics' own worst case, not a counterexample, not the limit `M → ∞`. **O5 stands. No verdict.**
This thread is now the programme's complete record on this family absent a new construction or
search method; there is no cheap next doubling waiting.

## 3. The infrastructure episode, in one paragraph (full account: `LL.md` LL-29/30/31, the
report §5.4 "Certifying the exact record")

The GCP exact-evaluation job hit a quota refusal, then a fast-failing empty-bucket incident, then
— after a full resilience rewrite (checkpointing inside every pass, a self-resuming no-ssh
runner, 44 local test scenarios) — the job itself converged cleanly, and its **own verification
code** then failed twice more: a text search silently matched nothing against a log containing a
few stray bytes from an unflushed write at a preemption boundary, and a resume-logic bug read a
checkpoint field a finished run's checkpoint never writes. Both were diagnosed by reading raw
bytes directly, both reproduced deterministically before being trusted as fixed, and the answer
was recovered locally in under a second from an independently-mirrored backup rather than
re-spending `~16` cloud hours. Mentioned here because it produced two reusable artifacts:
`docs/harness/skill-resilient-job.md` and `docs/harness/skill-autoresearch-screen.md`, proposed
for installation so the next session — on this project or another — does not re-derive either
pattern from a fresh incident.

## 4. Where the actual blocker stands — the self-consistency closure

This is the section worth Deep Think's attention; nothing above touches it.

**The shape of what's provable, fixed at the 2026-09-13 adjudication.** Not "the tail decays
given a bounded core" (false as phrased — tail modes are forced by the core through disparate
triads, and nothing about the core's boundedness alone controls that forcing). What is provable
is a **self-consistent** tail bound, the standard structure for rigorous numerics of dissipative
PDEs (Zgliczyński–Mischaikow for Kuramoto–Sivashinsky): *assume* an explicit tail envelope
`ℰ(C,a) = {|u_k| ≤ C·e^{−a√(k²)} for k² > M_core²}`, show linear dissipation `ν|k|²` dominates
the nonlinear forcing of every tail mode by the core-plus-envelope, conclude `ℰ` is
forward-invariant. The rate is **exponential in `|k|` (Gevrey), not super-exponential** — that
word has been retired from the target statement. The virtue, if it closes: the inequality holds
for all `|k| > M_core` with no reference to the outer truncation `M`, so a closed envelope is
**uniform in `M`** — the first object in this programme whose shape could beat O5, for the
specific solutions the certificate covers.

**What's built and unconditional (Tier A target, provable now, not yet formalised in Lean):**
the per-mode energy balance, and the forcing bound `‖B(u,u)_k‖ ≤ Σ_{p+q=k} |q|·‖u_p‖·‖u_q‖`
(pure algebra plus norms plus the Leray projector's self-adjointness).

**What's conditional and is the actual closure statement:** for all `k` with `k² > M_core²`, if
`core(u) ∈ 𝒞` (a componentwise box, interval-certified) and `tail(u) ∈ ℰ(C,a)`, then
`ν k² · Ce^{−a|k|} > Σ_{p+q=k} |q|·bound(u_p)·bound(u_q)`. **Nothing about this has been shown
true or false at any `M_core`, `C`, `a`.** That inequality, evaluated, is the certificate; no
Lean theorem exists conditional on it yet.

**What is NOT the bottleneck, measured, not assumed.** The interval-arithmetic evaluator that
would check the inequality is built, validated against an independent two-sided bracket (zero
violations at `M = 4`, 257 modes), and fast: `32` ms at `M_core = 8`, `1.85` s at `M = 16`,
`O(n²)` scaling putting `M = 32` (`≈137 000` modes) at roughly two minutes. **Whatever blocks
this closure, it is the mathematics of finding `(M_core, β, C, a)` that make the inequality
true, not the arithmetic of checking one candidate.** T-2′ (§5 below) matters here directly: it
is the forcing bound used inside this exact inequality, and a tighter bound widens the region of
`(C, a)` for which the search might succeed.

**What Deep Think's attention would actually move, concretely:**
1. **Is there any principled way to search `(M_core, C, a)` rather than guess-and-check one
   candidate at a time against the evaluator?** The evaluator is cheap enough (`2` minutes at
   `M_core = 32`) that a moderately sized parameter sweep is affordable — but the space is
   continuous in `(C, a)` and the box `𝒞` at a given `M_core` is itself a nontrivial object to
   propose. Is there a standard closure-search strategy from the self-consistent a-priori-bounds
   literature (Zgliczyński–Mischaikow, or the Navier–Stokes-specific computer-assisted-proof
   literature) this programme should be following rather than inventing?
2. **Does T-2′'s ≈2× tightening (§5) plausibly matter at the scale needed**, or is the gap
   between "forcing bound achievable" and "dissipation needed" large enough that no bound
   improvement of this order closes it — i.e., is this worth the owner's adoption effort before
   or after a first real attempt at the closure search?
3. **Is `M_core ≤ 8` (the current interval-arithmetic ceiling) plausibly large enough for any
   Gevrey envelope to close against real Navier–Stokes-scale forcing**, or does the transient
   series in §2 (a `4.3 %` excursion still growing at `M = 64`, on a *different*, adversarially
   constructed family, not this closure's own core-box question) suggest the core needs to be
   much larger before self-consistency has a chance — in which case the interval evaluator's
   measured `O(n²)` scaling (§5.5 of `CORE_TAIL_CAP.md`) says how expensive that would be, but
   someone competent in the literature should judge whether it is *qualitatively* plausible
   before more machine time is spent finding out empirically.

None of these three questions has been answered by anything this programme has done; they are
exactly what mathematical judgment, not more computation, would move.

## 5. Decision requested — Door #2 (open since 2026-08-25, three questions, no cost to answer)

`docs/designs/DOOR2_MEMO_SIGN_AUDIT.md` §7, verbatim, restated here because it has been waiting
three weeks under an active embargo (nothing leaves Stream 1 until sealed):

1. **Validate or reject the sign audit** — specifically the S5/S6 classification and the claim
   that Door #2's four sign-critical steps in Cheskidov §5 reduce to one mechanism (a positivity
   propagation requirement that a two-shell breaking configuration, `u_{n₀}=a>0, u_{n₀+1}=−b<0`
   with `b > λ^{−(1+2γ)/3}a`, violates on an open set — verified exactly at three `γ` values).
2. **Authorise the §6 observables** (`O1` signed production normalised by `‖u‖³_{α+γ}`, `O2`
   coercivity ratio `H/‖u‖²_γ`) as the pre-registration, which unlocks the D6 harness — the work
   that would actually test whether the breaking configuration matters dynamically, not just
   algebraically.
3. **Rule on the cheap theory question**: does a functional with `|uₙuₙ₊₁|` as the cross term
   (coercive for any signs) still satisfy a superlinear differential inequality? This is paper
   work, not a run, and could close or reopen Door #2 before any harness executes.

**Recommendation.** Answer (3) first — it is free (no compute, no formalisation, an afternoon of
algebra) and its answer changes what (1) and (2) are even worth authorising. If the alternative
functional works, Door #2 may be moot regardless of the sign audit's verdict; if it provably
doesn't, (1) and (2) become the only route and are worth authorising promptly given the
embargo's three-week cost already paid.

## 6. Decision requested — T-2′ adoption (E-1, a ruling not a task)

`CORE_TAIL_CAP.md` §5.2. `T-2′: ‖B(u,u)_k‖ ≤ |k|·Σ_{p+q=k}‖u_p‖‖u_q‖` (fixed weight `|k|`,
factoring out of the convolution, versus T-2's varying `|q|`), from the exact identity
`q·u_p = k·u_p` on divergence-free states. **Measured, not asserted**: holds everywhere tested,
nearly `2×` tighter than T-2 on the coherent stratum at `M = 3` (`0.2125` vs `0.1111`). Proposed,
awaiting owner adoption; not citable until then. Directly feeds §4's closure inequality — see
question 2 there.

**Recommendation.** Adopt. The measurement is already done and favourable everywhere checked;
the cost of adopting is one Lean statement change and re-running the certificate evaluator
against it, both cheap given §5.5's measured `32` ms–`2` min sizing. The only reason to withhold
would be if §4 question 2 suggests the tightening is immaterial at the scale needed — worth
answering together with that question rather than treating T-2′ in isolation.

## 7. What is emphatically not claimed by any of this

Hypothesis U, in any form. Any statement about the dynamics' own worst case. Any claim that six
points on one adversarially-constructed family bear on the limit `M → ∞`. Any claim that the
GCP infrastructure work (§3) is itself a scientific result — it produced two reusable process
artifacts and nothing about Navier–Stokes. The programme's own `LEDGER.md` and this report are
the citable record; nothing in this brief may be cited without checking against them.
