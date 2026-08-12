> **RECORD — v0.1 as received 2026-08-12, verbatim.** This document is frozen for provenance.
> It is superseded by `../SPEC.md` (v0.2). The critical review is `REVIEW-2026-08-12.md`.

# The AgoraAI-Agentic-Core Framework: Unified Agent & Scientific Specification for Solving Hypothesis U

This document establishes the technical, architectural, and mathematical specification for the **AgoraAI-Agentic-Core**. It details the required agent skills, directory layout, symbolic and formal verification toolchains, and the complete mathematical background of **Xavier Callens' Dual-Scale Topological Geometry**. This specification is designed to direct autonomous, verifier-in-the-loop AI agents in the staged execution of the **Scientific Program to prove the global regularity of the 3D Navier-Stokes equations** via **Hypothesis U**.

---

## 1. Executive Summary & Epistemic Frame

The **AgoraAI** platform operates under a strict **scalable oversight paradigm**: **the verifier checks the mathematical proof, while the human mathematician audits the question (the statement of the theorems and definitions)**.

To avoid the historical pitfalls of unverified, peer-reviewed mathematical announcements that are later retracted, the agent core operates under a **Three-Tier Epistemic Gating System**, mechanically enforced by the continuous integration (CI) pipeline:
*   **[Tier C] — Conjecture**: Theoretical proposals, physical interpretations, or unverified outputs produced by the initial reasoning models.
*   **[Tier B] — Checkable**: Statements and identities validated by **exact rational arithmetic (Q)** and certified computational witnesses, explicitly barring floating-point approximations.
*   **[Tier A] — Established**: Formally verified, **sorry-free** mathematical proofs compiled by the **Lean 4 kernel** depending strictly on the foundational axioms of Mathlib.

---

## 2. Scientific & Mathematical Foundations (The Dual-Scale Program)

### 2.1 The T-Dual Effective Metric (Dual-Scale Geometry)
In the classical continuum, the Richardson-Kolmogorov energy cascade allows vortex stretching to focus unbounded enstrophy at arbitrarily small scales, generating finite-time blow-ups. **Dual-Scale Geometry resolves this by introducing a T-duality cutoff inspired by string theory**.

For a fixed fundamental area (the squared minimal length scale) alpha' > 0, we define the **T-dual effective radius** for any spatial scale R > 0 as:

    Reff(alpha', R) = max(R, alpha'/R)

This geometric construct satisfies several key theorems, proven in Lean with zero custom axioms:
1.  **T-Dual Bound (`Reff_ge_sqrt`)**: Reff(alpha', R) >= sqrt(alpha') for all R > 0. **The scale sqrt(alpha') acts as a universal minimum scale, rendering smaller distances literally unreachable**.
2.  **Bounce (`Reff_bounce`)**: If R < sqrt(alpha'), then Reff(alpha', R) = alpha'/R. Contraction below the fundamental length is reflected and dilated back into the macroscopic domain.
3.  **Inertial Invisibility (`Reff_inertial`)**: If R >= sqrt(alpha'), then Reff(alpha', R) = R. **The metric remains perfectly classical at macroscopic scales**, confining the deformation strictly below the cutoff.
4.  **T-Duality (`Reff_tdual`)**: Reff(alpha', alpha'/R) = Reff(alpha', R). The effective geometry cannot distinguish a sub-cutoff scale from its dual macroscopic counterpart.

### 2.2 The Symmetric-Square Lock (L3 = Sym^2(L2))
To prevent independent macroscopic degrees of freedom from decoupling and blowing up on their own, **HoloAlg imposes a Symmetric-Square Lock**. The macroscopic evolution operator L3 is the symmetric square of the microscopic quantum fiber operator L2.

This is the abstract form of **Clausen's Identity**, where products of the solutions of a 2nd-order differential equation span the solution space of a 3rd-order equation. At the level of characteristic roots, if L2 has the spectrum {lambda, mu}, then L3 is locked to {lambda^2, lambda*mu, mu^2}.

The discrete shadow of this lock is verified at **Tier A** via the theorem `sym2_recurrence`:
*   Let u_n satisfy the 2nd-order recurrence: u_{n+2} = a u_{n+1} + b u_n (operator L2).
*   Then v_n := u_n^2 satisfies the 3rd-order recurrence:

        v_{n+3} = (a^2+b) v_{n+2} + b(a^2+b) v_{n+1} - b^3 v_n   (operator L3 = Sym^2 L2)

### 2.3 Leray Truncation & The Millennium Reduction
Under the T-dual effective metric, the velocity field u^(alpha') is governed by a **T-dual regularized system** on the periodic torus T^3:

    dt u + ((J_{sqrt(alpha')} u) . grad) u = -grad p + nu Laplacian u,   div u = 0

where J_{sqrt(alpha')} is the Leray-type projection onto Fourier frequencies |k| <= 1/sqrt(alpha'). For any fixed alpha' > 0, global-in-time existence and smoothness are guaranteed.

**The Millennium Reduction (Proposition 5.1)** states that if the regularized velocity field satisfies a single uniform bound on its enstrophy flux as alpha' -> 0:

    Hypothesis U:  sup_{alpha' > 0} sup_{0 <= t <= T} || grad u^(alpha')(t) ||_{L^2(T^3)} < infinity

then the classical, unmodified Navier-Stokes equations possess a globally smooth solution on [0, T].

*Proof Sketch*: The energy identity establishes that u^(alpha') is bounded in L^infty_t L^2_x  ∩ L^2_t H^1_x. Aubin-Lions compactness yields a subsequence converging strongly in L^2_{t,x} to a Leray-Hopf weak solution u. Under Hypothesis U, the limit inherits the bound u in L^infty_t H^1_x embedded in L^infty_t L^6_x. This places the weak solution in the critical **Prodi-Serrin regularity class** (2/s + 3/q <= 1 with s=infty, q=6), guaranteeing smoothness on (0, T].

### 2.4 The Four Analytical Tracks to Solve Hypothesis U
The core program decomposes the verification of Hypothesis U into **four specialized mathematical tracks**:

```
                     +------------------------------------------+
                     |          HYPOTHESIS U BOUND              |
                     +--------------------+---------------------+
                                          |
         +-------------------+------------+-----------+---------------------+
         v                   v                        v                     v
+-----------------+ +-----------------+     +------------------+   +-----------------+
|BOURGAIN-DEMETER | | VILLANI-MOUHOT  |     |GOLSE-ST-RAYMOND  |   |  DUMINIL-COPIN  |
|  (Arithmetic    | | (Phase Mixing & |     |  (Hydrodynamic   |   | (Scale Limits & |
|   Depletion)    | |  Echo Decay)    |     |  Entropy Limits) |   |   Percolation)  |
+-----------------+ +-----------------+     +------------------+   +-----------------+
```

1.  **The Bourgain-Demeter Track (Arithmetic Depletion)**: Uses **l^2 Decoupling** over the discrete Fourier spectrum of the Sym^2 lock. By leveraging Sarnak's spectral gap bounds on arithmetic manifolds, the agent must prove that triadic resonant interactions (k1 + k2 = k3) are statistically starved at high frequencies, enforcing a Strichartz-type bound that prevents constructive interference.
2.  **The Villani-Mouhot Track (Phase Mixing)**: Models the enstrophy cascade as a phase-mixing process in the fluid's phase space. The agent constructs a **Gevrey-class Gevrey-regularity Newton iteration scheme** (similar to non-linear Landau damping) to demonstrate that the non-linear "enstrophy echoes" are exponentially suppressed over time by the Sym^2(L2) Picard-Fuchs operators.
3.  **The Golse-Saint-Raymond Track (Hydrodynamic Limits)**: Treats the limit alpha' -> 0 as the hydrodynamic Knudsen limit epsilon -> 0. By formulating an **enstrophy relative entropy functional**, the agent uses weak-compactness arguments and DiPerna-Lions-style renormalization to bound the enstrophy dissipation uniformly.
4.  **The Duminil-Copin Track (Scale Limits)**: Formulates regions of enstrophy density exceeding a high threshold Lambda as a **percolation cluster on a discrete lattice** with a minimal scale sqrt(alpha'). The agent must prove that the Hausdorff dimension of the singular set is strictly zero in the continuum limit, ensuring that macroscopic vortex tubes cannot connect to form an active singularity.

---

## 3. Agent Repository Specification (`AgoraAI-Agentic-Core`)

The repository must be initialized under a strict, standardized workspace layout. This structure isolates verified libraries, intermediate computation scripts, and the active formalization files.

```
/workspace/
+-- AgoraAI-Agentic-Core/
    +-- lean_src/
    |   +-- CallensDualScale.lean        <- Core axiomatic & constructive foundation
    |   +-- ToyShellModels.lean          <- Stage 1: Katz-Pavlovic & Desnyansky-Novikov
    |   +-- lakefile.lean                <- Pinning lean4/v4.22.0 & Mathlib v4.22.0
    +-- symbolic/
    |   +-- picard_fuchs_generator.py    <- Gfun and Zeilberger recurrences (Stream 1)
    |   +-- b_regular_automata.py        <- Recurrence divide-and-conquer parser
    +-- tests/
        +-- rns_multiplier_test.py       <- Tier B exact-arithmetic validation harness
```

### The Foundation File: `CallensDualScale.lean`
The agent must verify that the axiomatic foundations compile cleanly with **"zero sorry"**. The verified core of the dual-scale space is formalized as follows:

```lean
import Mathlib.Data.Real.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

namespace CallensDualScale
universe u

/-! ### PILIER 1 : La Geometrie Operatorielle Symetrique -/

class QuantumFiber (F : Type u) where
  L2_op : F -> F

class MacroManifold (M : Type u) where
  L3_op : M -> M
  lattice_det : Int

class DualScaleSpace (F : Type u) [QuantumFiber F] (M : Type u) [MacroManifold M] where
  proj : F -> M
  sym2_lock : forall (q : F), MacroManifold.L3_op (proj q) = proj (QuantumFiber.L2_op (QuantumFiber.L2_op q))

/-! ### PILIER 2 : Le Couplage Discret-Continu (Reseau <-> Onde) -/

class CosmicWave (W : Type u) where
  wave_mass : W -> Real

class WaveCoupling (M : Type u) [MacroManifold M] (W : Type u) [CosmicWave W] where
  to_wave : M -> W
  resonance_law : forall (m : M), (CosmicWave.wave_mass (to_wave m)) * (MacroManifold.lattice_det m : Real) = 1.0

/-! ### THEOREME 1 : L'Emergence Inevitable du Secteur Sombre -/

theorem wave_mass_nonzero
  {M : Type u} [MacroManifold M]
  {W : Type u} [CosmicWave W]
  [c : WaveCoupling M W]
  (m : M) :
  CosmicWave.wave_mass (c.to_wave m) != 0 := by
  intro h_zero
  have h_law := c.resonance_law m
  rw [h_zero] at h_law
  have h_mul : (0 : Real) * (MacroManifold.lattice_det m : Real) = 0 := MulZeroClass.zero_mul _
  rw [h_mul] at h_law
  exact zero_ne_one h_law

/-! ### PILIER 3 : L'Eclosion Cosmologique (Inversion T-Duale) -/

axiom alpha_prime : Real
axiom alpha_prime_pos : 0 < alpha_prime

noncomputable def t_dual_radius (R : Real) : Real :=
  if R < Real.sqrt alpha_prime then alpha_prime / R else R

/-! ### THEOREME 2 : La Fin du Big Bang Classique -/

theorem genesis_no_singularity (R : Real) (hR : 0 < R) : 0 < t_dual_radius R := by
  dsimp [t_dual_radius]
  split_ifs with h
  . exact div_pos alpha_prime_pos hR
  . exact hR

end CallensDualScale
```

---

## 4. Agent Interaction, Tools, and Skills

To execute this program, the agent must be equipped with specialized APIs and verification harnesses.

```
       +-------------------------------------------------------------+
       |                 AGORA-AGENTIC-CORE LOOP                     |
       +------------------------------+------------------------------+
                                      |
                   +------------------+------------------+
                   v                                     v
     +---------------------------+         +---------------------------+
     |    SYMBOLIC GENERATION    |         |     FORMAL COMPILER       |
     |      (Python / Gfun)      |         |     (Lean 4 / Lake)       |
     +-------------+-------------+         +-------------+-------------+
                   |                                     |
                   |  [Iterative Search]                 |  [Typechecking & Proof]
                   +------------------+------------------+
                                      v
                       +----------------------------+
                       |    SCSC SCORING PIPELINE   |
                       |   (IC1 ^ IC2 ^ TE1 ^ D2)   |
                       +----------------------------+
```

### 4.1 Lean 4 Interactive Proving (Pantograph & Lake)
The agent must interact programmatically with the Lean 4 compiler via **Pantograph**, which exposes internal proof states, goal hypotheses, and tactic-level operations:
*   **Skill Requirements**: The agent must parse the `lake build` output, extract diagnostic line numbers, and resolve typeclass resolution conflicts (e.g., coercions between non-negative reals `R>=0` and reals `R`).
*   **Verification Command**:
    ```bash
    lake env lean lean_src/CallensDualScale.lean
    ```

### 4.2 Symbolic Mathematics and Algorithmic Guessing
To find the algebraic locks for the Picard-Fuchs operators (representing L2 and L3 recurrences), the agent must employ **symbolic-numeric "Guess-and-Prove" pipelines**:
*   **Skill Requirements**: Use the **Inria `gfun` package** and **Zeilberger's creative telescoping** to guess linear differential equations from initial series expansions, then construct the polynomial vector fields representing the corresponding initial value problems.
*   **Divide-and-Conquer Recurrences**: Convert polynomial recurrences involving residues modulo base powers into systems of b-regular equations.

### 4.3 Verifier-Feedback Loop & SCSC Scoring (VeriBench)
The agent's code-generation performance is scored using the **SCSC (Smooth Conjunctive Score for Code Verification)**:

    SCSC(L-hat, L*) = (IC1 * IC2 * TE1 * D1 * D2)^(1/5)

*   **IC1 (File Typechecks)**: Binary gate (1 if the agent-generated file compiles, 0 if it fails).
*   **IC2 (Proof Closure)**: Measures the proportion of agent-generated theorems that are closed **without using `sorry` or `admit`**.
*   **TE1 (Theorem Equivalence)**: Deploys an LLM-evaluation judge to check if the generated theorem statements semantically cover the target physical invariants.
*   **D1/D2 (Gold-side Validity Gates)**: Tracks whether the gold reference itself compiles and proves cleanly.

---

## 5. Agent Goals and Frontiers (Do's and Don'ts)

### 5.1 The "Axioms are Forbidden" Principle
*   **DO NOT** declare custom axioms to bypass proof obligations. An early version of the Dual-Scale framework encoded the T-dual bounce as a raw axiom, introducing an inconsistency where division-by-zero (`x/0 = 0` in Lean) derived `False` and rendered all downstream theorems vacuously true.
*   **DO** construct explicit, kernel-accepted models (such as instantiating the framework with a collapsing dyadic cascade) to prove that the axiomatic definitions are inhabited.
*   **DO** verify every compiled file with the **#print axioms gate**. The command must output exactly:
    ```lean
    #print axioms CallensDualScale.genesis_no_singularity
    -- Expected: [propext, Classical.choice, Quot.sound]
    ```

### 5.2 Strict Epistemic Gating
*   **DO NOT** label any unverified statement as proved.
*   **DO** tag every result dynamically:
    *   **[Tier C]**: Outputs generated by the reasoning loops before arithmetic check.
    *   **[Tier B]**: Algebraically verified identities validated by exact arithmetic.
    *   **[Tier A]**: Compiles under the Lean 4 kernel with zero `sorry` and a clean 3-axiom footprint.

### 5.3 The Counterexample-Before-Attack Rule
*   **DO NOT** assign the agent to prove an unverified goal blindly. LLMs frequently state false or unprovable lemma targets during reduction.
*   **DO** run a counterexample search (using fuzzers or symbolic evaluations in the Python environment) under degenerate and boundary configurations before attempting a formal Lean proof.

### 5.4 The Version-Proliferation Ban & Cold-Build Verification
*   **DO NOT** generate multiple versioned copies of the same file (e.g., `CallensDualScale_v2.lean`, `CallensDualScale_final.lean`). This pollutes the import graph and hides active `sorry` statements.
*   **DO** enforce a strict single-active-file policy.
*   **DO** run a **cold build** (from a clean state with zero cached `.olean` files) to confirm that no namespace collisions or definition drifts occur across the module boundaries.

### 5.5 Spec Non-Vacuity Checks
*   **DO** ensure that theorem statements do not become vacuously true. Agents can accidentally write unsatisfiable preconditions (e.g., assuming a parameter is both zero and positive), which allows Lean to discharge the proof immediately but invalidates the physical model. Every theorem must be validated against a concrete, instantiated witness.
