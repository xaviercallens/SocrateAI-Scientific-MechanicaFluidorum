#!/usr/bin/env python3
# TIER C — EXPLORATORY, NO CLAIMS — NEVER GATES A CLAIM
"""STEP 2 of the S6.4 reconciliation: is the enumerator's per-class signed sum even well defined?

WHERE THIS COMES FROM. `waleffe_triad_crucible.py` settled the first half: the memo's closed form
had a sign error (the p+q+r=0 versus p+q=k convention gap), and the corrected form matches brute
force to 2e-16 on the owner's triad in all eight chirality classes. What it did NOT explain is the
other half — why the enumerator reported a per-class signed sum of ~0 to one part in 10^17.

THE HYPOTHESIS THIS FILE TESTS. The helical vector depends on a choice of real unit `nu(k) ⊥ k`.
Rotating `nu` about `k` by an angle theta multiplies `h^s(k)` by `exp(-i s theta)`. Therefore

    |C| is INVARIANT under that choice;   arg(C) is NOT.

A sum of C over many triads adds quantities whose relative phases are set by an ARBITRARY,
mode-by-mode convention. If so, the per-class signed sum is not a property of the flow at all — it
is a property of how `nu` was picked — and its value, zero or otherwise, carries no information.

THE TEST. Compute the per-class signed sum over a small Galerkin ball twice, under two different
but equally legitimate `nu` conventions, and compare. If the sums differ, the quantity is
convention-dependent, and the S6.4 collision dissolves: the closed form is right, the enumerator's
arithmetic is right, and the OBSERVABLE was meaningless.

Controls: the invariance of |C| is checked at the same time and must hold to machine precision —
that is the positive control, and it is what makes a difference in the signed sum interpretable
rather than a symptom of a coding error.
"""

import math
import sys

M = 3


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def conj3(v):
    return tuple(complex(x).conjugate() for x in v)


def norm(a):
    return math.sqrt(sum(abs(x) ** 2 for x in a))


def unit(a):
    n = norm(a)
    return tuple(x / n for x in a)


def nu_from(axis):
    """A legitimate nu construction: normalise axis x kappa, falling back if they are parallel."""
    def f(k):
        v = cross(axis, unit(k))
        if norm(v) < 1e-12:
            alt = (1.0, 0.0, 0.0) if abs(axis[0]) < 0.5 else (0.0, 1.0, 0.0)
            v = cross(alt, unit(k))
        return unit(v)
    return f


def helical(k, s, nu_of):
    kappa = unit(k)
    nu = nu_of(k)
    e1 = cross(nu, kappa)
    return tuple(complex(e1[j], s * nu[j]) for j in range(3))


def lattice(m):
    out = []
    for x in range(-m, m + 1):
        for y in range(-m, m + 1):
            for z in range(-m, m + 1):
                if 0 < x * x + y * y + z * z <= m * m:
                    out.append((x, y, z))
    return out


def c_enum(sk, sp, sq, k, p, q, nu_of):
    """The enumerator's expression: all three conjugated, triad k+p+q = 0."""
    hp = conj3(helical(p, sp, nu_of))
    hq = conj3(helical(q, sq, nu_of))
    hk = conj3(helical(k, sk, nu_of))
    g = dot(cross(hp, hq), hk)
    return -0.25 * g * (sp * norm(p) - sq * norm(q))


def sweep(nu_of):
    pts = lattice(M)
    index = {p: i for i, p in enumerate(pts)}
    signed = {}
    absum = {}
    for ki in pts:
        for pi in pts:
            qi = (-ki[0] - pi[0], -ki[1] - pi[1], -ki[2] - pi[2])
            if qi not in index:
                continue
            for sk in (1, -1):
                for sp in (1, -1):
                    for sq in (1, -1):
                        cls = (sk, sp, sq)
                        c = c_enum(sk, sp, sq, ki, pi, qi, nu_of)
                        signed[cls] = signed.get(cls, 0j) + c
                        absum[cls] = absum.get(cls, 0.0) + abs(c)
    return signed, absum


def name(cls):
    return "".join("+" if s > 0 else "-" for s in cls)


def main():
    nu_z = nu_from((0.0, 0.0, 1.0))
    nu_x = nu_from((1.0, 0.0, 0.0))

    print(f"Galerkin ball M = {M}, {len(lattice(M))} modes.\n")
    sz, az = sweep(nu_z)
    sx, ax = sweep(nu_x)

    print("POSITIVE CONTROL — sum of |C| must be identical under both conventions (|C| is invariant):")
    worst_abs = max(abs(az[c] - ax[c]) / max(az[c], 1e-300) for c in az)
    print(f"  worst relative difference in sum|C|: {worst_abs:.3e}   "
          f"{'OK' if worst_abs < 1e-10 else '*** FAILED — a coding error, not a convention effect ***'}")
    if worst_abs >= 1e-10:
        sys.exit(1)

    print("\nTHE TEST — the SIGNED sum, under the two conventions:")
    print(f"{'class':7} {'|sum C|  (nu from z)':>22} {'|sum C|  (nu from x)':>22} {'sum|C|':>14} "
          f"{'ratio z':>11} {'ratio x':>11}")
    changed = False
    for cls in sorted(sz, key=name):
        vz, vx, a = abs(sz[cls]), abs(sx[cls]), az[cls]
        rz, rx = vz / a, vx / a
        if abs(vz - vx) > 1e-9 * max(a, 1.0):
            changed = True
        print(f"{name(cls):7} {vz:22.6e} {vx:22.6e} {a:14.6e} {rz:11.2e} {rx:11.2e}")

    print("\nReading:")
    if changed:
        print("  The signed sum CHANGES with the convention while sum|C| does not.")
        print("  => the per-class signed sum is NOT gauge invariant: it is a property of how nu was")
        print("     chosen mode by mode, not of the lattice or of any flow. Its value carries no")
        print("     information, and the S6.4 collision dissolves — the closed form is right, the")
        print("     enumerator's arithmetic is right, and the OBSERVABLE was meaningless.")
    else:
        print("  The signed sum is the SAME under both conventions. The gauge hypothesis is refuted,")
        print("  and S6.4 remains open: something else makes the per-class sum vanish.")
    print("\nNO VERDICT issued here; verdicts are the owner's (PLAN section 2).")


if __name__ == "__main__":
    main()
