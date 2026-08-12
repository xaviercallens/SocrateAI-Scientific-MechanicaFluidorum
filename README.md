# MechanicaFluidorum — AgoraAI-Agentic-Core

A staged, verifier-in-the-loop scientific program on 3D Navier–Stokes global regularity,
organized around **Hypothesis U** (uniform enstrophy control of the frequency-truncated
system). Human intuition audits the questions; the Lean 4 kernel checks the proofs; exact
rational arithmetic checks everything in between.

- **`SPEC.md`** — the active specification (v0.2): epistemic charter, obstruction ledger,
  mathematical foundations, staged roadmap, rules.
- **`LEDGER.md`** — normative claim inventory. *A claim not in the ledger has no tier.*
- **`docs/REVIEW-2026-08-12.md`** — critical review of the founding spec (v0.1) with the
  full audit evidence; `docs/SPEC_v0.1_original.md` is the frozen record.
- **`lean_src/CallensDualScale.lean`** — Tier A core: T-dual effective-radius laws and the
  symmetric-square lock, kernel-verified, zero custom axioms.
- **`tests/`, `symbolic/`** — Tier B exact-ℚ gate and guess-and-prove tooling.

## Verify everything

```bash
./scripts/verify.sh
```

Gate 1 runs the exact-arithmetic harness; Gate 2 kernel-compiles the Lean core and enforces
the `[propext, Classical.choice, Quot.sound]` axiom footprint. Both must pass.

Current state: Stage 0 essentially complete (2026-08-12). Next: Stage 1, the dyadic
shell-model laboratory (`SPEC.md` §6).
