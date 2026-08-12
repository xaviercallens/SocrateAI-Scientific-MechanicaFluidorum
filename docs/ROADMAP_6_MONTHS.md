# AgoraAI-Agentic-Core: 6-Month Operational Roadmap

**Program:** Hypothesis U Resolution (Conjecture 5.2, Main)  
**Timeline:** 26 weeks (6 months)  
**Staging:** Five incremental stages, four parallel analytical tracks in Stage 3  
**Gate Criterion:** Each milestone is falsifiable; kill-criteria are pre-committed.

---

## Weeks 1–2: Stage 0 Verification ✅

**Status:** COMPLETE (2026-08-12)

**Deliverables:**
- ✅ `lean_src/CallensDualScale.lean`: 13 kernel-verified theorems (T-dual metric laws, Sym² lock, spectral content).
- ✅ `tests/tier_b_exact_checks.py`: Tier B harness (B1–B6), all exact ℚ arithmetic.
- ✅ `symbolic/picard_fuchs_generator.py`: Guess-and-prove pipeline.
- ✅ `scripts/verify.sh`: Two-gate CI (Tier B + Lean kernel).

**Verification Gate:** PASS (both gates green).

---

## Weeks 3–8: Stage 1 (Dyadic Shell-Model Laboratory)

**Objective:** Prove global well-posedness of T-dual regularized dyadic shell models (Katz-Pavlović, Desnyansky-Novikov).

### Week 3: Formalization Setup
- **Task 1.1:** Write dyadic shell model in Lean 4 with quantified initial data (u₀ ∈ L²).
- **Task 1.2:** State global existence theorem as: `∃ u ∈ C([0,T]; ℓ²), solves shell model, E(u) is bounded`.
- **Deliverable:** `lean_src/DyadicShells.lean` (draft, ~200 lines).

### Week 4: Empirical Energy Cascades (Tier B)
- **Task 1.3:** Implement exact ℚ-arithmetic ODE integrator (e.g., Runge-Kutta-4 in `symbolic/`).
- **Task 1.4:** Run energy cascade simulations for Katz-Pavlović with viscosity ν ∈ {0.1, 0.01, 0.001}.
- **Data Collection:** Time series E_j(t) (enstrophy in shell j) for 100 runs, varying initial conditions uniformly at random from unit ball in ℓ².
- **Tier B Check:** No observed blow-up in any run; E_total(t) ≤ C(ν, u₀) throughout [0, T].
- **Deliverable:** Dataset + visualization in `data/shell_cascades/`.

### Week 5–6: Analytical Proof (Picard-Lindelöf + Grönwall)
- **Task 1.5:** Prove existence via Picard-Lindelöf on finite-dimensional ball.
- **Task 1.6:** Apply Grönwall lemma to show energy bound: E(t) ≤ E₀ e^{Ct}, where C depends on ν and u₀.
- **Task 1.7:** Verify the constant C is independent of α' (the cutoff is fixed for this model).
- **Deliverable:** `lean_src/DyadicShells.lean` (completed, ~500 lines, Tier A draft).

### Week 7–8: Falsifiable Milestone
**Milestone 1.M1 (Tier B):** Dyadic models do NOT blow up under Sym² locks.
- **Quantitative Gate:** All 100 empirical runs show E(T) < 10 E₀.
- **Kill Criterion:** If ANY run exhibits E(t) → ∞ before time T, the mechanism is inert; program refocuses.
- **Expected Outcome:** ✅ PASS (dyadic models are known to be globally well-posed under dissipation).

**Milestone 1.M2 (Tier A):** Grönwall bound is proven in Lean, footprint clean.

**Status Post-Week 8:** Stage 1 COMPLETE. Proceed to Stage 2.

---

## Weeks 9–16: Stage 2 (Classical PDE Consolidation)

**Objective:** Reassemble the classical global theory of Leray-type mollified NSE with explicit α'-dependence tracking.

### Week 9–10: Mollifier Bounds & Energy Identities
- **Task 2.1:** Formalize mollifier operator $J_{\sqrt{\alpha'}}$ in Lean 4 (projection onto |k| ≤ 1/√α').
- **Task 2.2:** Prove Sobolev bounds: ‖J_{√α'} u‖_{H^k} ≤ C(k) ‖u‖_{H^k} (independent of α').
- **Task 2.3:** Derive energy identity for truncated system, track α'-dependence of constants.
- **Deliverable:** `lean_src/LerayMollification.lean` (~300 lines).

### Week 11–12: Aubin-Lions & Compactness
- **Task 2.4:** State Aubin-Lions embedding rigorously in Lean (as an axiom parameter, per §7.1 rule).
- **Task 2.5:** Prove sequential compactness of regularized family {u^(α')} in L²_{t,x}.
- **Task 2.6:** Extract Leray-Hopf weak solution as α' → 0 limit.
- **Deliverable:** `lean_src/AubinLions_Careful.lean` (repaired version of prior tree, ~200 lines).

### Week 13–14: Prodi-Serrin Regularity Class
- **Task 2.7:** Formalize Prodi-Serrin blow-up criterion: u ∈ L^s_t L^q_x, 2/s + 3/q ≤ 1 ⇒ smooth.
- **Task 2.8:** Prove that Hypothesis U ⇒ u ∈ L^∞_t H^1_x ⊂ L^∞_t L^6_x.
- **Task 2.9:** Show 2/∞ + 3/6 = 1/2 < 1, hence regularity.
- **Deliverable:** `lean_src/ProdiSerrin.lean` (~150 lines).

### Week 15–16: Paper-Level Monograph
- **Task 2.10:** Synthesize the proof chain into a coherent paper-level argument.
- **Task 2.11:** Document all constants and their α'-dependence explicitly.
- **Deliverable:** `docs/ProofMonograph_Stage2.pdf` (target: 20–30 pages).

**Milestone 2.M1 (Tier A on paper):** Complete proof chain is written and reviewed.

**Status Post-Week 16:** Stage 2 COMPLETE. Move to Stage 3 (Four Tracks in parallel).

---

## Weeks 17–28: Stage 3 (Four Analytical Tracks in Parallel)

**Strategy:** Deploy four teams/agents in parallel, each attacking one track. Milestones are staggered; kill criteria are checked weekly.

### **TRACK 1: Bourgain-Demeter (Arithmetic Depletion)**

**Weeks 17–22:** Triadic Resonance Analysis
- **Task T1.1 (Week 17–18, Tier B):** Enumerate all triadic resonances k₁ + k₂ = k₃ with |k₁|, |k₂|, |k₃| ≤ M for M ∈ {2⁵, 2¹⁰, 2¹⁵}.
  - Exact count (no constraints): $N_{\text{free}}(M) = O(M^3)$ (expected).
  - Count under Sym² spectral constraint: $N_{\text{constrained}}(M)$.
  - Ratio: η(M) = $N_{\text{constrained}}(M) / N_{\text{free}}(M)$.
- **Deliverable:** `data/triadic_resonances.csv` (M, η(M), both counts).

**Week 19 Falsifiable Milestone T1.M1 (Tier B):**
- Gate: η(M) ≪ 1 (e.g., η ≈ 0.01–0.1 even at M = 2¹⁵).
- Kill Criterion: If η(M) → 1 as M increases, the Sym² lock provides negligible depletion.
- **Expected:** η ≈ 0.05 (strong depletion).

**Weeks 20–22:** ℓ² Decoupling (Paper-Level Tier B/A)
- **Task T1.2:** Given the depleted resonance set, apply Bourgain-Demeter ℓ² decoupling.
- **Construct:** Strichartz-type bound on high-frequency modes using decoupling frequency-cap size δ(α').
- **Prove:** Enstrophy growth rate $d/dt E(t) \leq \nu E(t) + O(α')$, a Grönwall integral.
- **Deliverable:** `docs/Bourgain_Demeter_Analysis.pdf` (paper-level, ~15 pages).

**Weeks 23–24:** Formalization (Lean 4, Tier A draft)
- **Task T1.3:** Encode the ℓ² decoupling bound in Lean 4.
- **Deliverable:** `lean_src/Bourgain_Demeter.lean` (draft, ~200 lines).

---

### **TRACK 2: Villani-Mouhot (Phase Mixing & Echo Decay)**

**Weeks 17–22:** Echo Dynamics & Gevrey Regularity (Tier C → Tier B)
- **Task T2.1 (Week 17–18):** Define "enstrophy echo" precisely as a secondary cascade event:
  - Primary cascade: direct energy transfer from wavenumber k to higher modes.
  - Echo: re-injection of energy at intermediate scales due to nonlinear interactions.
  - Quantify: amplitude A_echo(t) as a convolution of past velocity fields.
- **Task T2.2 (Week 19–20):** Construct Gevrey-regularity Newton iteration following Mouhot–Villani framework.
  - Shift velocity to Gevrey class: u → u_σ with exponential decay at high k.
  - Prove contraction of map M(u) = ∫ convolution in Gevrey norm.
- **Deliverable:** `docs/Villani_Mouhot_Echo_Theory.pdf` (theory paper, ~20 pages).

**Week 20 Falsifiable Milestone T2.M1 (Tier B):**
- Gate: Echo amplitude decays exponentially: $A_{\text{echo}}(t) \leq A_0 e^{-\lambda t}$, λ > 0.
- Verify in dyadic model: Run numerical simulations isolating echo contribution (Tier B).
- Kill Criterion: If echoes persist with A(t) → const, the Gevrey mechanism fails.
- **Expected:** λ ≈ ν/(enstrophy scale), so echoes decay on viscous timescale.

**Weeks 21–22:** Gevrey Regularity Formalization (Paper-Level Tier A draft)
- **Task T2.3:** Prove H¹ bound via controlled echo sums: ‖u‖²_{H¹} ≤ C(1 + ∑ A_echo(t)).
- **Deliverable:** `docs/Gevrey_Regularity_Bound.pdf` (proof paper, ~12 pages).

**Weeks 23–24:** Lean Formalization
- **Deliverable:** `lean_src/Villani_Mouhot.lean` (draft, ~150 lines).

---

### **TRACK 3: Golse-Saint-Raymond (Entropy Limits)**

**Weeks 17–22:** Relative-Entropy Functional (Tier C → Tier B/A)
- **Task T3.1 (Week 17–18):** Define enstrophy-based relative entropy:
  $$H(t) = \int_{\mathbb{T}^3} h(u^{(\alpha')} | \bar{u}) \, dx$$
  where h is a convex functional and $\bar{u}$ is a reference background.
- **Task T3.2 (Week 19–20):** Derive dissipation inequality:
  $$\frac{d}{dt} H(t) + \lambda \| \nabla u^{(\alpha')} \|^2_{L^2} \leq O(\alpha')$$
  using weak compactness and velocity-averaging lemmas.
- **Deliverable:** `docs/Relative_Entropy_Inequalities.pdf` (theory, ~18 pages).

**Week 21 Falsifiable Milestone T3.M1 (Tier B/A):**
- Gate: Entropy dissipation bound holds at fixed α' (Tier A proof).
- Verify uniformity as α' → 0 (Tier B). Run numerical checks for α' ∈ {0.1, 0.01, 0.001, 0.0001}.
- Kill Criterion: If dissipation rate diverges as α' → 0 (e.g., grows like 1/α'), the track fails.
- **Expected:** Dissipation rate is O(1) uniformly.

**Weeks 22–24:** Compactness & Convergence (Tier A draft)
- **Task T3.3:** Prove weak convergence of {u^(α')} to classical Leray-Hopf u with ‖∇u‖_{L^∞_t L^2_x} < ∞.
- **Deliverable:** `lean_src/Golse_SaintRaymond.lean` (draft, ~250 lines).

---

### **TRACK 4: Duminil-Copin (Percolation & Scaling Limits)**

**Weeks 17–22:** Percolation Cluster Analysis (Tier B)
- **Task T4.1 (Week 17–18):** Define percolation lattice of spacing √α' on 𝕋³. Mark cells where enstrophy density e(x,t) > Λ (threshold).
- **Task T4.2 (Week 19–20):** For fixed α' ∈ {0.1, 0.01, 0.001}, compute percolation probability:
  $$P_{\text{perc}}(\alpha', \Lambda) = \Pr[\text{high-enstrophy region connects macroscopically}]$$
  under Sym² spectral constraints.
- **Task T4.3:** Compute Hausdorff dimension of the high-enstrophy cluster (use box-counting or spectral analysis).
- **Deliverable:** `data/percolation_analysis_alpha_prime.csv` (α', Λ, $P_{\text{perc}}$, dimension).

**Week 21 Falsifiable Milestone T4.M1 (Tier B):**
- Gate: Percolation is **subcritical** under Sym² locks: $P_{\text{perc}} < p_c$ (critical threshold).
- Hausdorff dimension: dim_H(singular set) < 1 - ε for ε > 0.
- Kill Criterion: If percolation is supercritical or dimension ≥ 1, singular vortex filaments persist; Duminil-Copin track fails.
- **Expected:** Dimension ≈ 0.3–0.7 (strictly less than 1).

**Weeks 22–24:** Scaling-Limit Theorem (Tier A draft)
- **Task T4.4:** Prove formal scaling-limit result: as α' → 0, the limit of percolation clusters has zero Hausdorff dimension.
- **Deliverable:** `lean_src/Duminil_Copin.lean` (draft, ~200 lines).

---

### **Track Synchronization & Status**

| Week | T1 (Resonances) | T2 (Echo) | T3 (Entropy) | T4 (Percolation) | Status |
|------|---|---|---|---|---|
| 17–18 | Problem setup | Echo definition | Entropy functional | Percolation lattice | Parallel starts |
| 19 | **Milestone T1.M1** | Setup OK | Setup OK | Setup OK | Resonate count checkpoint |
| 20 | Decoupling | **Milestone T2.M1** | Dissipation ineq. | Dissipation ineq. | Echo decay checkpoint |
| 21 | Formalization | Gevrey regularity | **Milestone T3.M1** | **Milestone T4.M1** | Entropy & percolation checkpoints |
| 22–24 | Lean draft | Lean draft | Lean draft | Lean draft | All four formalize |

**Kill Decision:** If a milestone fails, the corresponding track is marked "INCONCLUSIVE" but work continues on the other three. A track can be revised if the underlying mechanism is sound but the formulation was flawed.

---

## Weeks 25–26: Stage 4 (Formal Audit & Synthesis)

**Objective:** Assemble all four track proofs into a single sorry-free Lean 4 file.

### Week 25: Integration & Cleanup
- **Task 4.1:** Merge `Bourgain_Demeter.lean`, `Villani_Mouhot.lean`, `Golse_SaintRaymond.lean`, `Duminil_Copin.lean` into one master file.
- **Task 4.2:** Resolve any cross-dependencies and missing lemmas.
- **Task 4.3:** Run `scripts/verify.sh` to confirm both gates PASS.
- **Deliverable:** `lean_src/HypothesisU_Proof.lean` (integrated, target ~1500 lines).

### Week 26: Final Verification & Publishing
- **Task 4.4:** Verify the axiom footprint:
  ```lean
  #print axioms hypothesis_u_holds
  -- Should output: [propext, Classical.choice, Quot.sound]
  ```
- **Task 4.5:** Generate PDF of the full proof with Lean syntax highlighting.
- **Task 4.6:** Prepare manuscript for submission (target venue: Annals of Mathematics, Acta Mathematica, or Inventiones).
- **Deliverable:** `HypothesisU_FinalProof.pdf` (publication-ready).

**Final Gate (Week 26, Tier A):** Lean kernel accepts the proof; axiom footprint is clean.

---

## Success Criteria & Branching Logic

### Stage 3 Outcomes:

1. **All Four Tracks Pass (≥3 milestones hit):** → Stage 4 proceeds as planned. Hypothesis U is resolved.
2. **Three Tracks Pass, One Fails:** → Four-track proof is partial. Revise the failed track or concede.
3. **Two or Fewer Tracks Pass:** → Program pivots. Re-examine mechanism or seek alternative approaches.

### Fallback Strategy (if major track fails):
- The program **does not stop** but instead **shifts to an alternative research direction**:
  - Focus on **partial regularity** (extending CKN).
  - Target a **weaker regularity class** (e.g., Serrin class with s = 4, q = 3).
  - Formalize **necessary conditions** for Hypothesis U (what must be true if U holds).

---

## Resource Allocation & Staffing Model

| Role | Weeks | Responsibility |
|------|-------|---|
| **Lead (Xavier/Claude)** | All | Overall coordination, Stage 2/4 PDE theory, Lean architecture |
| **Agent T1** | Weeks 17–24 | Bourgain-Demeter track (resonance analysis + decoupling) |
| **Agent T2** | Weeks 17–24 | Villani-Mouhot track (echo dynamics + Gevrey regularity) |
| **Agent T3** | Weeks 17–24 | Golse-Saint-Raymond track (entropy limits + compactness) |
| **Agent T4** | Weeks 17–24 | Duminil-Copin track (percolation + scaling limits) |
| **Integration Agent** | Weeks 25–26 | Merge proofs, verify synthesis, prepare final manuscript |

---

## Deliverables Checklist

- [ ] Week 2: Dyadic shell-model lab complete, Tier B cascade empirics pass.
- [ ] Week 16: Stage 2 classical PDE theory complete (monograph).
- [ ] Week 21–22: All four tracks produce paper-level proofs + falsifiable milestone data.
- [ ] Week 24: All four tracks Lean 4 drafts compiled.
- [ ] Week 26: Final synthesis in Lean 4, `#print axioms` gate passes, manuscript ready.

---

**End of Roadmap (v1.0)**

*Next review: 2026-10-12 (end of Week 8, post-Stage-1 evaluation).*
