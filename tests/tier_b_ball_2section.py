#!/usr/bin/env python3
"""TIER B — exact-arithmetic verification of the two combinatorial theorems of
docs/designs/BALL_SPECTRAL_PROBLEM.md. Integers and Fractions only; no floats anywhere.

FACT 1 (exact ball weight). For distinct u, v in Lambda_M = {k in Z^3\\{0} : |k|^2 <= M^2},
the incidence-counted 2-section weight is

    A_M(u,v) = 2*[u+v in Lambda_M] + 4*[u-v in Lambda_M].

Checked against an INDEPENDENTLY built 2-section (symbolic/triad_hypergraph.two_section,
which enumerates triads and accumulates slot-pair incidences without knowing this formula).
This is the ball's boundary analogue of the torus theorem A = 6(J-I) - 2P proved in
lean_src/TriadTorus.lean; the two coincide when every nonzero sum stays in the index set.

FACT 2 (the linear eigenfunction). For h(u) = <u, e> any linear functional, and
C the operator with kernel [u - v in Lambda_M],

    (C h)(u) = (1/2) * V(u) * h(u),        V(u) = #{v in Lambda_M : u - v in Lambda_M},

exactly, at every mode. Reason: W(u) = {v : v, u-v both in Lambda_M} is invariant under the
involution v -> u-v, so sum_{W(u)} h(v) = sum_{W(u)} h(u-v) = V(u)h(u) - sum_{W(u)} h(v).
Consequence (see the memo): the odd-sector Rayleigh quotient reaches exactly 1/2, so the
continuum spectral gap is <= 5/6 with an explicit witness -- half the 5/6 conjecture.

CONTROLS (LL-12; both are identity verifiers, so the sweeps themselves are the positive
controls, and each carries an explicit negative control that must FIRE):
  * NC1: a deliberately wrong weight formula (coefficients 2 and 4 swapped) must MISMATCH.
  * NC2: a non-linear odd h (h(u) = u_1^3) must BREAK Fact 2 -- the identity is about
    linearity, not about oddness.
  * NC3: an even h (h(u) = u_1^2) must break Fact 2 as well.
A control that cannot fire is not a control; each is asserted to fire below.
"""

import sys
import os
from fractions import Fraction as Q

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "symbolic"))
from triad_hypergraph import lattice, triads, two_section   # noqa: E402


def ball_weight_predicted(u, v, S):
    """2*[u+v in Lambda] + 4*[u-v in Lambda], exact integer."""
    s = (u[0] + v[0], u[1] + v[1], u[2] + v[2])
    d = (u[0] - v[0], u[1] - v[1], u[2] - v[2])
    return 2 * (1 if s in S else 0) + 4 * (1 if d in S else 0)


def check_fact1(M, coeffs=(2, 4)):
    """Compare the closed form against the independently built 2-section. Exact integers."""
    pts = lattice(M)
    A = two_section(pts, triads(pts))
    S = set(pts)
    idx = {p: i for i, p in enumerate(pts)}
    a, b = coeffs
    mismatches = 0
    for u in pts:
        for v in pts:
            if u == v:
                continue                      # the formula is stated off-diagonal
            s = (u[0] + v[0], u[1] + v[1], u[2] + v[2])
            d = (u[0] - v[0], u[1] - v[1], u[2] - v[2])
            pred = a * (1 if s in S else 0) + b * (1 if d in S else 0)
            if A[idx[u]][idx[v]] != pred:
                mismatches += 1
    return len(pts), mismatches


def check_fact2(M, h):
    """Pointwise (C h)(u) == V(u) h(u) / 2, exact rationals. Returns (#modes, #mismatches)."""
    pts = lattice(M)
    S = set(pts)
    mismatches = 0
    for u in pts:
        W = [v for v in pts if (u[0] - v[0], u[1] - v[1], u[2] - v[2]) in S]
        lhs = Q(sum(h(v) for v in W))
        rhs = Q(len(W) * h(u), 2)
        if lhs != rhs:
            mismatches += 1
    return len(pts), mismatches


def main():
    print("== TIER B: ball 2-section closed form, and the linear eigenfunction ==\n")
    ok = True

    print("FACT 1 -- A_M(u,v) = 2*[u+v in Lambda] + 4*[u-v in Lambda], vs independent 2-section:")
    for M in (2, 3, 4):
        n, bad = check_fact1(M)
        print(f"   M={M}: |Lambda|={n:>4}, off-diagonal mismatches = {bad}"
              f"   {'OK' if bad == 0 else '*** FAILED ***'}")
        ok &= (bad == 0)

    print("\n   NC1 (negative control): coefficients swapped to 4 and 2 -- must MISMATCH:")
    n, bad = check_fact1(3, coeffs=(4, 2))
    print(f"      M=3: mismatches = {bad}   {'OK (control fires)' if bad > 0 else '*** DEAD CONTROL ***'}")
    ok &= (bad > 0)

    print("\nFACT 2 -- (C h)(u) = V(u) h(u) / 2 for linear h, pointwise:")
    for M in (3, 4, 5):
        for name, h in (("h(u) = u_1", lambda u: u[0]),
                        ("h(u) = u_1 - 2u_3", lambda u: u[0] - 2 * u[2])):
            n, bad = check_fact2(M, h)
            print(f"   M={M} {name:>16}: modes={n:>4}, mismatches = {bad}"
                  f"   {'OK' if bad == 0 else '*** FAILED ***'}")
            ok &= (bad == 0)

    print("\n   NC2 (negative control): h(u) = u_1^3 (odd, NOT linear) -- must break:")
    n, bad = check_fact2(3, lambda u: u[0] ** 3)
    print(f"      M=3: mismatches = {bad}   {'OK (control fires)' if bad > 0 else '*** DEAD CONTROL ***'}")
    ok &= (bad > 0)

    print("   NC3 (negative control): h(u) = u_1^2 (even) -- must break:")
    n, bad = check_fact2(3, lambda u: u[0] ** 2)
    print(f"      M=3: mismatches = {bad}   {'OK (control fires)' if bad > 0 else '*** DEAD CONTROL ***'}")
    ok &= (bad > 0)

    print("\nBoth facts hold exactly; all three negative controls fire." if ok
          else "\n*** SOMETHING FAILED -- see above ***")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
