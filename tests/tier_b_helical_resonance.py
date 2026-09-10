#!/usr/bin/env python3
"""Tier B — which lattice triads are INERT under the verified helical coefficient, in exact integers.

WHERE THIS COMES FROM. `docs/designs/WALEFFE_HELICAL_MEMO.md` §4, whose closed form was verified
against brute force to 2.1e-16 in all eight chirality classes
(`exploration/waleffe_triad_crucible.py`):

    C = +(i S_pq / 4|k|) (s_p|p| + s_q|q| + s_k|k|) (s_p|p| - s_q|q|)

so a triad carries NO transfer in the class (s_k,s_p,s_q) exactly when one of

    (R)  s_k|k| + s_p|p| + s_q|q| = 0      the Waleffe resonance condition
    (D)  s_p|p| = s_q|q|
    (G)  S_pq = 0                          collinear triad

THE POINT OF THIS FILE. On the lattice, |k| = sqrt(k_sq k) is a SQUARE ROOT OF AN INTEGER, so (R)
is not a generic real condition but a DIOPHANTINE one, and it can be decided in exact integer
arithmetic with no floating point anywhere. That is what makes this Tier B rather than Tier C, and
it is the first time the programme's recurring phrase "the arithmetic rigidity of Z^3" becomes a
checkable statement rather than a slogan.

THE CHARACTERISATION, derived here and verified by the sweep below. Write A = |k|^2, B = |p|^2,
C = |q|^2, all positive integers. Since all three magnitudes are positive, (R) can hold only with
exactly one sign differing from the other two, and the odd one out must be the largest; so (R) is
equivalent to one of sqrt(A) = sqrt(B) + sqrt(C) and its two relabellings. Now

    sqrt(A) = sqrt(B) + sqrt(C)  <=>  A - B - C = 2 sqrt(BC)  <=>  A - B - C >= 0  AND
                                                                   (A - B - C)^2 = 4BC ,

which is a statement about integers alone. Writing B = d b^2 and C = d c^2 with d squarefree, BC is
a perfect square exactly when B and C share the same squarefree kernel d, and then
A = d (b + c)^2 -- so ALL THREE of A, B, C carry the SAME squarefree kernel. Both formulations are
computed below and required to agree; they are independent implementations of one claim, which is
the point (a single implementation of a characterisation proves nothing about the characterisation).

CONTROLS (SPEC §7.3, both directions; the harness exits non-zero if any fails).
  P1  a known resonant triad must be ACCEPTED: p = q = (1,0,0) gives B = C = 1, A = 4, and
      sqrt 4 = sqrt 1 + sqrt 1. This is a real lattice triad with p + q = k.
  P2  the two independent decision procedures (integer square test, squarefree kernel) must agree
      on every triad in the sweep -- an explicit positive control on the characterisation itself.
  N1  DEMONSTRATED NEGATIVE (LL-19): perturbing the test to (A-B-C)^2 = 4BC + 1 must change the
      verdict on at least one triad. A perturbation that leaves the answer intact is inert and
      proves nothing.
  N2  a known NON-resonant triad must be REJECTED: A = 2, B = 1, C = 1 (k=(1,1,0), p=(1,0,0),
      q=(0,1,0)); sqrt 2 != 2, and no relabelling helps.

NO CLAIM is made here about turbulence, about Navier-Stokes, or about Hypothesis U. This counts
lattice triads.
"""

import sys
from math import isqrt


# ---------------------------------------------------------------- exact integer helpers
def is_square(n: int) -> bool:
    """Exact perfect-square test on a non-negative integer. No floats."""
    if n < 0:
        return False
    r = isqrt(n)
    return r * r == n


def squarefree_kernel(n: int) -> int:
    """The squarefree part d of n > 0, i.e. n = d * m^2 with d squarefree. Exact."""
    d = 1
    m = n
    f = 2
    while f * f <= m:
        if m % f == 0:
            e = 0
            while m % f == 0:
                m //= f
                e += 1
            if e % 2 == 1:
                d *= f
            f += 1
        else:
            f += 1
    return d * m


def k_sq(v):
    return v[0] * v[0] + v[1] * v[1] + v[2] * v[2]


# ---------------------------------------------------------------- the two decision procedures
def resonant_by_integer_test(A: int, B: int, C: int, perturb: bool = False) -> bool:
    """(R) holds for SOME chirality assignment, decided in integers only.

    sqrt(X) = sqrt(Y) + sqrt(Z)  <=>  X - Y - Z >= 0 and (X - Y - Z)^2 = 4 Y Z.
    `perturb` is the N1 negative control: it offsets the square test by one."""
    off = 1 if perturb else 0
    for X, Y, Z in ((A, B, C), (B, A, C), (C, A, B)):
        t = X - Y - Z
        if t >= 0 and t * t == 4 * Y * Z + off:
            return True
    return False


def resonant_by_kernel(A: int, B: int, C: int) -> bool:
    """Same predicate via the squarefree kernel: all three share a kernel d, and one root is the
    sum of the other two. Independent of the routine above."""
    dA, dB, dC = squarefree_kernel(A), squarefree_kernel(B), squarefree_kernel(C)
    if not (dA == dB == dC):
        return False
    d = dA
    a, b, c = isqrt(A // d), isqrt(B // d), isqrt(C // d)
    return a == b + c or b == a + c or c == a + b


# ---------------------------------------------------------------- lattice
def ball(M):
    return [(x, y, z)
            for x in range(-M, M + 1)
            for y in range(-M, M + 1)
            for z in range(-M, M + 1)
            if 0 < x * x + y * y + z * z <= M * M]


def cross_is_zero(p, q) -> bool:
    """p x q = 0, i.e. p and q collinear. Exact integer test; this is condition (G), S_pq = 0."""
    return (p[1] * q[2] - p[2] * q[1] == 0
            and p[2] * q[0] - p[0] * q[2] == 0
            and p[0] * q[1] - p[1] * q[0] == 0)


def sweep(M):
    """Every ordered triad p + q = k with all three nonzero and inside the ball."""
    pts = ball(M)
    inside = set(pts)
    total = 0
    reson = 0
    degen = 0          # (D): |p| = |q| with opposite chirality available
    disagree = 0
    reson_noncollinear = 0     # THE decisive count: (R) without (G)
    examples = []
    for k in pts:
        A = k_sq(k)
        for p in pts:
            q = (k[0] - p[0], k[1] - p[1], k[2] - p[2])
            if q not in inside:
                continue
            B, C = k_sq(p), k_sq(q)
            total += 1
            r1 = resonant_by_integer_test(A, B, C)
            r2 = resonant_by_kernel(A, B, C)
            if r1 != r2:
                disagree += 1
            if r1:
                reson += 1
                if not cross_is_zero(p, q):
                    reson_noncollinear += 1
                    if len(examples) < 5:
                        examples.append((k, p, q, A, B, C))
            if B == C:
                degen += 1
    return total, reson, degen, disagree, reson_noncollinear, examples


# ---------------------------------------------------------------- controls
def controls():
    print("== CONTROLS (both directions) ==")
    ok = True

    # P1 — a genuine resonant lattice triad
    k, p, q = (2, 0, 0), (1, 0, 0), (1, 0, 0)
    assert (p[0] + q[0], p[1] + q[1], p[2] + q[2]) == k
    A, B, C = k_sq(k), k_sq(p), k_sq(q)
    p1 = resonant_by_integer_test(A, B, C) and resonant_by_kernel(A, B, C)
    print(f"P1 resonant triad k={k} p={p} q={q}  (A,B,C)=({A},{B},{C}): accepted by both = {p1}"
          f"   {'OK' if p1 else '*** FAILED ***'}")
    ok &= p1

    # N2 — a genuine NON-resonant lattice triad
    k, p, q = (1, 1, 0), (1, 0, 0), (0, 1, 0)
    A, B, C = k_sq(k), k_sq(p), k_sq(q)
    n2 = (not resonant_by_integer_test(A, B, C)) and (not resonant_by_kernel(A, B, C))
    print(f"N2 non-resonant triad k={k} p={p} q={q}  (A,B,C)=({A},{B},{C}): rejected by both = {n2}"
          f"   {'OK' if n2 else '*** FAILED ***'}")
    ok &= n2

    # N1 — the perturbation must actually change a verdict (LL-19)
    changed = 0
    for M in (3,):
        pts = ball(M)
        inside = set(pts)
        for k in pts:
            for p in pts:
                q = (k[0] - p[0], k[1] - p[1], k[2] - p[2])
                if q not in inside:
                    continue
                A, B, C = k_sq(k), k_sq(p), k_sq(q)
                if resonant_by_integer_test(A, B, C) != resonant_by_integer_test(A, B, C, True):
                    changed += 1
    n1 = changed > 0
    print(f"N1 DEMONSTRATED NEGATIVE: offsetting the square test by 1 flips {changed} verdicts"
          f"   {'OK (fires)' if n1 else '*** INERT — the control proves nothing (LL-19) ***'}")
    ok &= n1

    # squarefree kernel sanity, exact
    kern_ok = all(squarefree_kernel(n) == d for n, d in
                  ((1, 1), (2, 2), (4, 1), (8, 2), (9, 1), (12, 3), (18, 2), (50, 2), (72, 2)))
    print(f"    squarefree kernel on a fixed table: {'OK' if kern_ok else '*** FAILED ***'}")
    ok &= kern_ok

    print("CONTROLS:", "PASS\n" if ok else "*** FAILED ***\n")
    return ok


def main():
    if not controls():
        sys.exit(1)

    print("Ordered lattice triads p + q = k with all three inside the ball, and how many are INERT")
    print("under the Waleffe resonance condition (R). Exact integer arithmetic; no floating point.\n")
    print(f"{'M':>3} {'triads':>10} {'resonant (R)':>13} {'fraction':>12} {'|p|=|q| (D)':>13} "
          f"{'(R) & NOT collinear':>20} {'disagree':>9}")
    grand_disagree = 0
    grand_noncol = 0
    for M in (2, 3, 4, 5, 6):
        total, reson, degen, disagree, noncol, ex = sweep(M)
        grand_disagree += disagree
        grand_noncol += noncol
        frac = reson / total if total else 0.0
        print(f"{M:>3} {total:>10} {reson:>13} {frac:>12.6f} {degen:>13} {noncol:>20} {disagree:>9}")
        if ex:
            print("      non-collinear resonant triads found (these would refute the theorem below):")
            for e in ex:
                print(f"        k={e[0]} p={e[1]} q={e[2]}   A={e[3]} B={e[4]} C={e[5]}")

    print(f"\nP2 the two independent decision procedures disagreed on {grand_disagree} triads"
          f"   {'OK' if grand_disagree == 0 else '*** FAILED — the characterisation is wrong ***'}")
    if grand_disagree != 0:
        sys.exit(1)

    print(f"\nP3 resonant triads that are NOT collinear, over all M swept: {grand_noncol}")
    print("""
   THE THEOREM this count tests, proved in one line and NOT special to the lattice:

     For a triad p + q = k of nonzero real vectors, the Waleffe resonance condition
         s_k|k| + s_p|p| + s_q|q| = 0
     holds for some choice of signs  <=>  the triad is COLLINEAR.

   Proof. All three magnitudes are positive, so the signs cannot all agree; exactly one differs,
   and the condition reads |k| = |p| + |q|, or |p| = |k| + |q|, or |q| = |k| + |p|. Each is
   EQUALITY IN THE TRIANGLE INEQUALITY for the relation k = p + q (rewritten as p = k - q or
   q = k - p), and equality holds exactly when the two vectors on the right are parallel and
   like-directed. Hence all three are collinear. The converse is immediate. []

   CONSEQUENCE, and it is a NEGATIVE one for the "helical resonance selects a special inert set"
   reading: condition (R) implies condition (G) -- S_pq = 0 -- so (R) contributes NOTHING beyond
   the degenerate triads that carry no transfer anyway, for want of a plane. The inert set is not
   enriched by chirality; it is the collinear set.

   NOTE ALSO what the proof does NOT use: it never mentions Z^3. The "arithmetic rigidity of the
   lattice" plays no part -- the statement holds for real vectors. Any argument resting on the
   lattice making resonances rare is resting on nothing here.""")
    if grand_noncol != 0:
        print("\n*** THE THEOREM IS REFUTED by the triads listed above. ***")
        sys.exit(1)

    print("\nTIER B GATE (helical resonance): PASS (exact integers, zero floating point; the")
    print("  resonance predicate is decided two independent ways and they agree on every triad;")
    print("  a known resonant triad is accepted, a known non-resonant one rejected, and the")
    print("  perturbed test demonstrably changes verdicts)")


if __name__ == "__main__":
    main()
