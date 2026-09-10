"""TIER B — A1 resolved: the director stratum, its exact reduction, and the C-DIR identity.

CONTEXT. The pre-registered cancellation baseline (tier_b_production_cancellation.py) found the
coherent families F1/F1' EXACTLY zero and left the mechanism open, suspecting the constant
director. This file settles A1 of the symmetry-quotient workflow with four exact results.

For director states u_x = c_x (x cross d) (one fixed integer d, arbitrary complex c with the
conjugate-symmetry constraint), with r = -(p+q), W = |r|^2 - |q|^2:

  R1 (term formula)   t(p,q) = -W c_p c_q c_r det[p,q,d] [ (q.r)|d|^2 - (q.d)(r.d) ]
  R2 (six-sum)        the sum of t over the six orderings of one unordered triad {a,b,c} is
                        2 c_a c_b c_c det[a,b,d] EXPR,
                        EXPR = 2 (a.d)(b.d)(B-A) + (b.d)^2 (B-C) + (a.d)^2 (C-A)
                      -- the |d|^2 part of the bracket cancels IDENTICALLY (the A,B,C identity),
                      and det[a,b,d]*EXPR is an invariant of the unordered triad.
  R3 (no per-triad vanishing)  EXPR is NOT identically zero: the director stratum does NOT
                      vanish triad by triad, and random-phase director states have genuinely
                      nonzero production (F2 of the baseline is the standing witness).
  R4 (C-DIR)          Sigma(d) := sum over ALL unordered triads of ball M of det[a,b,d]*EXPR
                      VANISHES IDENTICALLY IN d -- proved here for M = 2, 3 by computing all
                      ten coefficients of the cubic form exactly.

  WHY R4 HOLDS FOR EVERY M (proof, recorded for the Lean target L-DIR): ball M is invariant
  under signed permutations sigma; substituting a -> sigma a, b -> sigma b gives
  Sigma(d) = det(sigma) * Sigma(sigma^T d). Each axis reflection (det = -1) forces every
  monomial of the cubic form to be ODD in that variable, so only d0*d1*d2 can survive; any
  transposition (det = -1) then forces its coefficient to equal its own negative. So
  Sigma == 0, for every ball and every d. The symmetry is LOAD-BEARING: control N2 removes
  one asymmetric point from the ball and the identity fails.

  CONSEQUENCE FOR THE INSTRUMENT. An aligned-phase family on any constant director is killed
  by cubic-group equivariance -- a symmetry artifact, exactly why the coherence control
  tripped twice. Amendment 5 (varied directors) is hereby justified as necessary. The
  interpretation quarantine on F2/F3 stands until a varied-director coherent family passes
  the coherence control.

EXACT, NO FLOATS.
"""

import pathlib
import sys
from collections import defaultdict
from fractions import Fraction

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from tier_b_fourier_enstrophy import (  # noqa: E402
    G, ball, k_sq, neg, add, cross_int_g, fourier_dot, bilinear,
)

ZERO = G(0, 0)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def det3(p, q, d):
    return (p[1] * q[2] - p[2] * q[1]) * d[0] \
         + (p[2] * q[0] - p[0] * q[2]) * d[1] \
         + (p[0] * q[1] - p[1] * q[0]) * d[2]


def term_direct(p, q, d, c):
    r = neg(add(p, q))
    dG = [G(x) for x in d]
    up = [c[p] * v for v in cross_int_g(p, dG)]
    uq = [c[q] * v for v in cross_int_g(q, dG)]
    ur = [c[r] * v for v in cross_int_g(r, dG)]
    return G(k_sq(r) - k_sq(q)) * fourier_dot(q, up) * bilinear(uq, ur)


def term_formula(p, q, d, c):
    r = neg(add(p, q))
    W = k_sq(r) - k_sq(q)
    bracket = dot(q, r) * dot(d, d) - dot(q, d) * dot(r, d)
    return G(-W * det3(p, q, d) * bracket) * c[p] * c[q] * c[r]


def expr_of(a, b, d):
    c = neg(add(a, b))
    A, B, C = k_sq(a), k_sq(b), k_sq(c)
    al, be = dot(a, d), dot(b, d)
    return 2 * al * be * (B - A) + be * be * (B - C) + al * al * (C - A)


def triads_unordered(points):
    bm = set(points)
    seen = set()
    for p in points:
        for q in points:
            r = neg(add(p, q))
            if r not in bm:
                continue
            key = tuple(sorted([p, q, r]))
            if key not in seen:
                seen.add(key)
                yield key


def cubic_coeffs(points, flip_sign=False):
    """All ten coefficients of Sigma(d); `flip_sign` is control N1 (breaks R2's EXPR)."""
    coeffs = defaultdict(int)
    for a, b, _ in triads_unordered(points):
        c = neg(add(a, b))
        A, B, C = k_sq(a), k_sq(b), k_sq(c)
        s = -1 if flip_sign else 1
        cross = (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2],
                 a[0] * b[1] - a[1] * b[0])
        for i in range(3):
            for j in range(3):
                for k in range(3):
                    quad = 2 * a[j] * b[k] * (B - A) + s * b[j] * b[k] * (B - C) \
                        + a[j] * a[k] * (C - A)
                    coeffs[tuple(sorted((i, j, k)))] += cross[i] * quad
    return {m: v for m, v in coeffs.items() if v}


CASES = [
    ((1, -2, 0), (3, 1, 2), (1, 2, 3)),
    ((2, 0, 1), (-1, 4, 1), (2, -1, 1)),
    ((0, 1, 1), (5, -2, 3), (1, 2, 3)),
    ((1, 1, -3), (-2, 5, 1), (0, 4, -9)),
]


def main() -> int:
    ok = True
    print("== TIER B: A1 resolved — the director stratum ==\n")

    # R1
    bad = 0
    for a, b, d in CASES:
        cv = {}
        for n, v in enumerate((a, b, neg(add(a, b)), neg(a), neg(b))):
            cv.setdefault(v, G(Fraction(n + 2, 7), Fraction(3 - n, 5)))
        for (p, q) in ((a, b), (b, a)):
            r = neg(add(p, q))
            cv.setdefault(r, G(1, 2))
            if term_direct(p, q, d, cv) != term_formula(p, q, d, cv):
                bad += 1
    print(f"  R1 term formula          : {len(CASES)*2 - bad}/{len(CASES)*2}"
          f"   {'HOLDS' if bad == 0 else 'FAILS'}")
    ok &= bad == 0

    # R2 + R3
    bad = 0
    expr_nonzero = 0
    for a, b, d in CASES:
        cc = neg(add(a, b))
        cv = {a: G(Fraction(1, 3), Fraction(1, 2)), b: G(Fraction(2, 5), Fraction(-1, 4)),
              cc: G(Fraction(-1, 2), Fraction(1, 7))}
        total = ZERO
        for (p, q) in ((a, b), (b, cc), (cc, a), (b, a), (a, cc), (cc, b)):
            total = total + term_direct(p, q, d, cv)
        pred = G(2 * det3(a, b, d) * expr_of(a, b, d)) * cv[a] * cv[b] * cv[cc]
        if total != pred:
            bad += 1
        if expr_of(a, b, d) != 0:
            expr_nonzero += 1
    print(f"  R2 six-sum reduction     : {len(CASES) - bad}/{len(CASES)}"
          f"   {'HOLDS' if bad == 0 else 'FAILS'}")
    print(f"  R3 EXPR nonzero witnesses: {expr_nonzero}/{len(CASES)}"
          f"   (per-triad vanishing REFUTED)")
    ok &= bad == 0 and expr_nonzero > 0

    # R4
    for M in (2, 3):
        cf = cubic_coeffs(ball(M))
        ntri = sum(1 for _ in triads_unordered(ball(M)))
        print(f"  R4 C-DIR at M={M}         : all 10 coefficients of Sigma(d) vanish over "
              f"{ntri} triads: {not cf}")
        ok &= not cf

    print("\n== negative controls (each MUST fail) ==")
    n1 = cubic_coeffs(ball(2), flip_sign=True)
    print(f"  N1 flip one sign inside EXPR       : identity {'BROKEN as required'
          if n1 else '*** DID NOT FAIL ***'} ({len(n1)} nonzero coefficients)")
    ok &= bool(n1)

    broken = [p for p in ball(2) if p != (1, 1, 0)]
    n2 = cubic_coeffs(broken)
    print(f"  N2 remove ONE point from the ball  : identity {'BROKEN as required'
          if n2 else '*** DID NOT FAIL ***'} ({len(n2)} nonzero coefficients)"
          f" — the cubic symmetry is load-bearing")
    ok &= bool(n2)

    if not ok:
        print("\nDIRECTOR STRATUM GATE: FAIL")
        return 1
    print("\nDIRECTOR STRATUM GATE: PASS")
    print("  A1 resolved: aligned-phase constant-director states vanish by cubic-group")
    print("  equivariance (a symmetry artifact — the coherence control's double trip is")
    print("  fully explained); the stratum does NOT vanish for generic phases. The")
    print("  interpretation quarantine stands until a varied-director coherent family")
    print("  passes the coherence control.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
