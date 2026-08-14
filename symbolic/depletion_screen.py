#!/usr/bin/env python3
"""Screening tool: does a candidate constrained spectrum DEPLETE resonances, or merely thin them?

WHY THIS EXISTS. Three proposed forms of the Sym^2 lock died on 2026-08-14, all of the same
defect: each looked like a constraint and constrained almost nothing of what mattered (LL-11).
Before another candidate is authored and sent for human audit, it should be screened cheaply.
This file is that screen, and it supplies the ingredient all three lacked: a NULL MODEL.

THE POINT, WHICH IS EASY TO MISS. Resonances k1+k2=k3 are TRILINEAR in the mode set. So keeping
a fraction f of the modes AT RANDOM already leaves about f^3 of the triads -- measured here:

    f = 0.80 -> ratio 0.484 (f^3 = 0.512)      f = 0.40 -> ratio 0.0608 (f^3 = 0.0640)
    f = 0.60 -> ratio 0.232 (f^3 = 0.216)      f = 0.25 -> ratio 0.0190 (f^3 = 0.0156)

Therefore "the constrained triad count is much smaller" is NOT evidence of depletion. Any thinning
does that. The only meaningful observable is the count RELATIVE TO RANDOM THINNING AT THE SAME
DENSITY:

    D  :=  (triads in S)  /  (f^3 * triads in Lambda),      f = |S| / |Lambda|

    D ~ 1  : no structure -- the candidate is just a thinner set (VACUOUS as a mechanism)
    D < 1  : genuine arithmetic depletion -- fewer resonances than chance allows
    D > 1  : ENRICHMENT -- the set is additively structured in a way that FAVOURS resonance,
             which is the opposite of what a lock is supposed to do

T1's kill criterion ("constrained count grows at the same order -> no depletion -> kill") is
exactly the statement D ~ 1, and this makes it measurable on a candidate before any audit.

A DISTINCTION THAT KILLED THE PREVIOUS DRAFT MORE SHARPLY THAN THE COUNT DID. OP-2's draft
filtered TRIADS directly (by their shell-index pattern) rather than constraining the SPECTRUM
(the mode set). T1's question -- how many resonances survive among a constrained spectrum -- is
not even well-posed for such a rule: a triad filter has no density f, so it has no null model
and cannot be compared to chance. A candidate must define a MODE SET.

CONTROLS (both mandatory, LL-12; this is a classifier-like instrument):
  * NEGATIVE: a random subset must score D ~ 1. If the screen reports depletion for randomness,
    it would certify anything.
  * POSITIVE: a sublattice (2Z)^3 is closed under addition, so it must score D clearly > 1
    (enrichment). An instrument that cannot see the most additively structured set there is
    cannot be trusted to see depletion either.

Exact integer arithmetic throughout (counts and lattice tests). Deterministic apart from the
random control, which is seeded.

A CALIBRATION RESULT WORTH KEEPING, AND THE TRAP IT REVEALS. The set {k : |k|^2 odd} scores
D = 0.00 -- it contains NO resonant triad at all, at density ~1/2. The reason is exact and
elementary: mod 2, x^2 = x, so |k|^2 = x+y+z (mod 2); if k1+k2=k3 with all three coordinate-sums
odd then odd+odd=odd, which is false. The set is SUM-FREE by parity. Verified exhaustively at
M=8: |S| = 1048, triads = 0.

That is total depletion -- and it is useless as a mechanism. A mode set with no triads has NO
nonlinear interaction: the restricted dynamics is linear and dissipative, so it is trivially
regular, not regular because of any lock. It is amputation, not depletion.

So D < 1 is necessary but NOT sufficient. A useful candidate needs 0 < D < 1: enough depletion
to matter, while retaining a cascade capable of transferring energy across scales. A candidate
scoring D = 0 should be rejected as fast as one scoring D ~ 1, for the opposite reason. Any
future screen should report, alongside D, whether the surviving triads still connect small to
large scales.

NO CANDIDATE HERE IS PROPOSED AS THE LOCK. Defining the constrained spectrum is OP-2, which is
BLOCKED-ON-DEFINITION (E-1). The sets below are calibration inputs for the screen.
"""

import sys
import random
from fractions import Fraction as Q


def lattice(M):
    return [(x, y, z)
            for x in range(-M, M + 1)
            for y in range(-M, M + 1)
            for z in range(-M, M + 1)
            if 0 < x * x + y * y + z * z <= M * M]


def triad_count(pts):
    """#{(k1,k3) in S^2 : k3-k1 in S}. Exact integer count."""
    S = set(pts)
    n = 0
    for a in pts:
        ax, ay, az = a
        for c in pts:
            if (c[0] - ax, c[1] - ay, c[2] - az) in S:
                n += 1
    return n


def screen(name, subset, full, T_full):
    """Report density, triads, null expectation, and the depletion ratio D."""
    f = Q(len(subset), len(full))
    t = triad_count(subset)
    null = float(f) ** 3 * T_full
    D = t / null if null > 0 else float("nan")
    if D < 1e-9:
        verdict = "AMPUTATION (no triads at all -- linear dynamics, useless as a mechanism)"
    elif D < 0.75:
        verdict = "DEPLETION (the interesting band)"
    elif D <= 1.35:
        verdict = "VACUOUS (thinning only)"
    else:
        verdict = "ENRICHMENT (favours resonance)"
    print(f"  {name:<34} f={float(f):.3f} |S|={len(subset):>5} triads={t:>8} "
          f"null={null:>10.0f}  D={D:>6.2f}   {verdict}")
    return D


def main():
    M = 6
    full = lattice(M)
    T = triad_count(full)
    print("== Depletion screen: does a candidate spectrum deplete, or merely thin? ==\n")
    print(f"lattice M={M}: |Lambda|={len(full)}, triads={T}")
    print("null model: random thinning to density f leaves ~ f^3 of the triads\n")

    random.seed(11)

    print("CONTROLS (must both behave, or no candidate may be screened):")
    # NEGATIVE control -- randomness must score D ~ 1
    rnd = [p for p in full if random.random() < 0.5]
    D_rnd = screen("NEGATIVE: random subset f~0.5", rnd, full, T)
    # POSITIVE control -- a subgroup must score D clearly > 1
    sub = [p for p in full if p[0] % 2 == 0 and p[1] % 2 == 0 and p[2] % 2 == 0]
    D_sub = screen("POSITIVE: sublattice (2Z)^3", sub, full, T)

    ok = (0.75 <= D_rnd <= 1.35) and (D_sub > 1.5)
    if not ok:
        print("\nCONTROLS FAILED -- refusing to screen candidates.")
        sys.exit(1)
    print("\n   controls pass (randomness ~ 1, subgroup enriched). Screen validated.\n")

    print("CALIBRATION SETS (illustrative -- none is proposed as the lock, OP-2 is blocked):")
    # arithmetic thinnings of the kind the owner's review sketched
    squares = {n * n for n in range(0, M + 1)}
    screen("|k|^2 a perfect square", [p for p in full if p[0]**2+p[1]**2+p[2]**2 in squares], full, T)
    screen("|k|^2 odd", [p for p in full if (p[0]**2+p[1]**2+p[2]**2) % 2 == 1], full, T)
    screen("|k|^2 = 0 mod 3", [p for p in full if (p[0]**2+p[1]**2+p[2]**2) % 3 == 0], full, T)
    screen("one coordinate zero (a plane set)", [p for p in full if 0 in p], full, T)

    print("\nReading: the interesting band is 0 < D < 1. D ~ 1 is a thinner set with no mechanism")
    print("(T1's kill criterion, made measurable). D = 0 is amputation, not depletion: no triads")
    print("means no nonlinearity, hence trivial regularity that proves nothing. Screen a candidate")
    print("HERE before audit -- three mechanisms died on 2026-08-14 for want of this step.")


if __name__ == "__main__":
    main()
