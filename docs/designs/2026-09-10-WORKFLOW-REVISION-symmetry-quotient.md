# Workflow revision — the symmetry-quotient programme

**Status: PROPOSAL, for the owner's approval (gate G1).** Supersedes the phase structure of
`DUAL_SCALE_WORKFLOW.md` (adjudicated 2026-09-10) in the light of what the first executed work
packages found; every standing rule, tier definition, and adjudicated verdict of that document
and of `DECISION_2026-09-10_openai_leverage_adjudication.md` remains in force. **Author:** Fable.

---

## 1. Why revise: what one day of execution established

1. **The fixed-truncation ledger is closed.** Energy conservation, the enstrophy production in
   exact closed form, the viscous balance laws, and the helical expansion's frame factors are all
   Tier A. There is no more bookkeeping to do at fixed `M`; every further theorem must say
   something about *families* of states or about *uniformity*.
2. **The adjudicated track met its first obstacle immediately, and the obstacle is a theorem.**
   The phase-mixing track needs the production sum to cancel for generic states. The
   pre-registered baseline found it cancels **perfectly** on whole strata of states — parity-even
   states (now Tier A: `production_terms_eq_zero_of_even`), apparently the constant-director
   class (exact at `M = 2, 3`, unproved), the `M = 1` ball, and the real part always. None of
   these carry information about mixing. **The coherence control tripped twice**, so the
   instrument has not yet measured anything the track can use.
3. **The lesson generalises the §6bis retraction.** Twice now, "massive cancellation" in this
   programme has turned out to be a symmetry artifact. The track's real task is therefore not
   "show cancellation" but **"show cancellation in excess of what the symmetry group forces,
   on states proved to lie off the degenerate strata."** That reframing is this document.

## 2. The reframed object

Write `T(u) = Σ_{triadSet M} (|r|²−|q|²)(q·u_p)(u_q·u_r)`, the kernel-checked production sum
(`2P = −i·T`, `P` real). Define — informally here, formally in Phase-A memos — the **symmetry
kernel** `𝒦_M`: the set of Galerkin states on which `T` vanishes for reasons that are invariances
of `T`, not properties of turbulence. Known or suspected strata so far:

| stratum | status |
|---|---|
| parity-even states `u(−k) = u(k)` | **Tier A** |
| `Re T = 0` — negation sends every term to `−conj` of itself | exact, every state; harness-asserted |
| constant-director states (`u = ∇g × d`, one fixed `d`) | exact at `M = 2, 3`; **unproved** |
| collinear-support and zero-mode-dominated states; all of `ball 1` | Tier A / trivial |

The phase-mixing question, restated falsifiably: **for pre-registered state families proved to
lie off `𝒦_M`, does `ρ(M) = ℓ¹(T)/Σℓ¹(terms)` fall faster than the random-phase null as `M`
grows?** Yes ⟹ the track earns its next theorem-shaped question. No ⟹ the track is refuted for
this observable and the owner re-decides at gate G4.

## 3. The phases

### Phase A — map the kernel (Fable derives; Opus proves; 1–2 sessions)

- **A1. Settle the director stratum.** Prove or refute: constant-director states have `T = 0`
  identically. Either outcome is progress — a new Tier A stratum, or the discovery that the
  observed zero has yet another cause, which the instrument must then find. *Method: memo first;
  the suspected mechanism is quasi-planarity, so try the substitution `u_k = k × (φ_k d)` in the
  closed form.* Negative control: a two-director state must break whatever proof emerges.
- **A2. The invariance inventory.** One memo listing every invariance of `T` with its proof
  status: negation (done), parity stratum (done), `swap3` termwise (done), the cubic lattice
  group (action on `triadSet` and on `T` — expected equivariance, unproved), global phase
  (`T(cu) = c³T(u)` — constrains coherent families), scaling `u → λu`. Each either proved
  (Opus, from the memo) or explicitly listed unproved. This is the checklist against which every
  future "cancellation" claim is audited first.
- **A3. The off-kernel certificate.** Define, in the measurement memo (instrumentation-level
  definition, not a spec object), a computable exact certificate that a state is off the known
  strata: nonzero parity-odd component, director rank ≥ 2, support off the degenerate sets. The
  harness must **assert the certificate** for every state whose numbers are to be interpreted.

### Phase B — the amended instrument (Opus implements; Haiku runs; 1 session + compute)

- **B1. Amendment-5 run**: `k`-dependent directors for **all** families, coherence control F1′′
  plus the A3 certificate on every state. The registered decision rule stands: the run is
  interpretable only if the coherence control passes.
- **B2. Reach in `M`.** Exact rationals in Python plateau near `M = 3–4`. Port the instrument to
  Rust with exact big-rationals (Opus; Haiku builds/runs) for `M ≤ 6–8`. Same seeds, same
  families, cross-checked against the Python harness at `M ≤ 3` exactly — the port is accepted
  only on exact agreement.
- **B3. Report `ρ(M)` off-kernel vs null**, with the pre-registered comparisons and nothing
  else. All interpretation language reserved to gate G4.

### Phase C — from measurement to mechanism (Fable + owner + Deep Think; contingent on B)

Only if B3 shows genuine super-null cancellation: identify the responsible structure (a
near-involution on off-kernel triad phases? an equidistribution statement over the sphere
shells?) and write the **target-theorem memo** — the exact statement whose proof would bound
`|P|` against dissipation uniformly in `M`. That statement is E-1-class: **its final form is
authored with the owner and reviewed by Deep Think before any proof attempt.** The shape to aim
at (aspirational, not yet a definition): `|P(u)| ≤ C · D(u)^θ · E(u)^{1−θ}` with `C, θ`
independent of `M`, where `D` is the dissipation sum and `E` the energy — the Millennium content
lives entirely in "`C` independent of `M`", per obstruction O5.

### Phase D — the foreign-tree audit (unchanged; waiting on the GCP transcript)

Acceptance criterion and probes as committed in `openai-axiom-audit.lean`. On PASS: their
breakdown results enter as Tier L context for the paper; on any `sorryAx`/custom axiom: the
affected theorem is uncitable and the finding itself becomes the report.

### Standing: the paper

The manuscript trails the ledger by three results (balance laws, parity kernel, the quarantined
baseline). One paper pass per phase boundary (Haiku builds, Fable writes), always after gates,
never before.

## 4. The human gates

| gate | question | who |
|---|---|---|
| **G1** | approve this revision | owner |
| **G2** | if the amendment-5 coherence control trips a **third** time: the observable itself is suspect — redesign (per-shell ρ? bispectral observable?) or abandon | owner + Deep Think |
| **G3** | the WP-0b transcript verdict | owner (Fable reports footprints) |
| **G4** | interpret B3: track earns Phase C, or is refuted for this observable | owner, on the pre-registered comparisons only |

## 5. What does not change

Memo before Lean; pre-registration with recorded amendments; negative controls demonstrated to
fail; nulls before interpretation; exact arithmetic in `tests/`; no `sorry`; `#print axioms` as
the only Tier A gate; verdicts belong to the owner; no theorem with a `1/α′` or `M`-dependent
constant may be labelled Statement A or Hypothesis U; the tier principle — **the cost of a wrong
statement sets the tier, not the size of the task.**

## 6. Honest odds, stated once

Phase A is certain to produce theorems (the kernel is real and provable). Phase B is certain to
produce a clean measurement (the instrument now checks its own blind spots). Phase C is where
the Millennium difficulty actually lives, and nothing above makes it easier — it makes it
**harder to fool ourselves on the way there**, which is the only thing a workflow can do.
