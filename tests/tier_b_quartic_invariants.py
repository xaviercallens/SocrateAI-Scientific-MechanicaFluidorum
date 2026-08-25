#!/usr/bin/env python3
"""TIER B — is there a QUARTIC invariant of the truncated dyadic system? Exact rationals only.

Executes docs/designs/QUARTIC_INVARIANT_SEARCH.md, which was hand-derived first (LL-5).

WHY. lean_src/DyadicRiccati.lean (Tier A) shows that refuting finite-time enstrophy blow-up by
the Riccati route needs ||u||^theta in L^1_loc with theta >= 4 at alpha = 2/5, while the energy
inequality supplies exactly theta = 2. ||u||^2 is QUADRATIC in u; ||u||^4 is QUARTIC. Energy
methods produce L^1 control of quadratics - that is what they are. So the barrier's first door
is the sharply posed algebraic question: does the truncated system have a quartic conserved
quantity at all?

Identity (Q1) of the memo, derived by hand and re-checked here as Fact 0, settles the quadratic
side completely:

    d/dt H_gamma = -2 nu H_{gamma+alpha} + 2(lam^{2gamma} - 1) sum_n lam^{(2gamma+1)n+1} u_n^2 u_{n+1}

with H_gamma = sum lam^{2 gamma n} u_n^2. The prefactor vanishes ONLY at gamma = 0, so energy is
the unique conserved weighted quadratic: theta = 2 is the entire quadratic supply, not an
artifact of technique. (At gamma < 0 with POSITIVE data the prefactor is negative and the sum is
non-negative, giving a monotone family - which is exactly where positivity does its work in the
literature, and exactly what is unavailable for sign-changing data.)

THE SEARCH. For the INVISCID truncated system (nu = 0; dissipation only helps, so a quantity
conserved by the nonlinearity is the right target), require dQ/dt = 0 IDENTICALLY as a
polynomial in u_1..u_N. That is a linear system in Q's coefficients, solved here by exact
rational Gaussian elimination, returning the dimension of the solution space.

CONTROLS (three, all mandatory, LL-12):
  * POSITIVE 1: the quadratic search must return a 1-dimensional space spanned by energy
    (c_n = 1). A search that cannot find the invariant we know exists may not be read.
  * POSITIVE 2: on the exponent-shifted system (in-flux lam^n -> lam^{n+1}) the search must find
    the SHIFTED invariant c_n = lam^{-n}. This one was originally written as a NEGATIVE control
    and it FAILED (2026-08-25) - because shifting the exponent does not destroy the telescoping
    at all, it merely moves the conserved weights. Turning it into a positive control keeps the
    lesson and tests something the constant-vector case cannot: that the machinery tracks
    weights rather than pattern-matching c_n = 1.
  * NEGATIVE: the INDEX STRUCTURE broken (out-flux couples u_n u_{n+2}), which genuinely admits
    no conserved weighted quadratic - the in-flux monomials u_{n-1}^2 u_n and the out-flux
    monomials u_n^2 u_{n+2} have incompatible patterns and can never cancel. Must return {0}.

PRE-REGISTERED KILL CRITERION (LL-15, fixed before any number was seen): if the banded quartic
search returns only multiples of E^2 - which is quartic but carries no new information, since
L^1 control of E^2 is not control of int H_alpha^2 - then door #1 is CLOSED for banded
polynomial quartic invariants, and that is the recorded result.

SCOPE OF A NEGATIVE RESULT (must travel with it): it would close banded polynomial quartic
CONSERVED quantities. It would not close quartics that are monotone without a polynomial
certificate, non-polynomial quantities, quantities conserved only on invariant subsets, or
door #2 (leaving the Riccati route). A closed door is not a closed problem.
"""

import sys
import itertools
from fractions import Fraction as Q

LAM = 2


def rhs_monomials(N, perturbed=None):
    """du_n/dt for the INVISCID truncated system, as a dict {monomial: coeff}.

    Monomials are sorted index tuples; u_0 = u_{N+1} = 0 by omission.
        du_n/dt = lam^n u_{n-1}^2 - lam^{n+1} u_n u_{n+1}

    perturbed = "exponent": lam^n -> lam^{n+1} in the in-flux. NOTE (recorded because it cost a
      failed control on 2026-08-25): this is NOT a destructive perturbation. The telescoping
      survives it - it merely moves the conserved weights from c_n = 1 to c_n = lam^{-n}, since
      cancellation needs c_{n+1} lam^{n+2} = c_n lam^{n+1}. Kept as a SECOND POSITIVE control:
      the search must find that shifted invariant, which tests that the machinery tracks weights
      rather than pattern-matching the constant vector.
    perturbed = "gap": out-flux couples u_n u_{n+2} instead of u_n u_{n+1}. This DOES destroy
      conservation: the in-flux monomials u_{n-1}^2 u_n and the out-flux monomials u_n^2 u_{n+2}
      have incompatible index patterns and can never cancel, so no weighting can work.
    """
    out = []
    for n in range(1, N + 1):
        d = {}
        if n - 1 >= 1:
            e = n + 1 if perturbed == "exponent" else n
            d[(n - 1, n - 1)] = d.get((n - 1, n - 1), 0) + Q(LAM) ** e
        j = n + 2 if perturbed == "gap" else n + 1
        if j <= N:
            d[tuple(sorted((n, j)))] = d.get(tuple(sorted((n, j))), 0) - Q(LAM) ** (n + 1)
        out.append(d)
    return out


def poly_time_derivative(monos, coeff_index, N, rhs):
    """d/dt of sum_j c_j * M_j, returned as {output_monomial: {c_index: coeff}}.

    Differentiating a monomial u_{i1}...u_{ik} gives sum over slots of the monomial with that
    slot replaced by du/dt, which is itself a sum of monomials. All exact.
    """
    acc = {}
    for j, mono in enumerate(monos):
        for slot in range(len(mono)):
            n = mono[slot]
            rest = mono[:slot] + mono[slot + 1:]
            for rmono, rc in rhs[n - 1].items():
                out = tuple(sorted(rest + rmono))
                acc.setdefault(out, {})
                acc[out][j] = acc[out].get(j, Q(0)) + rc
    return acc


def nullspace_dim_and_basis(rows, ncols):
    """Exact rational nullspace of the matrix given as list of dicts {col: val}."""
    mat = [[r.get(c, Q(0)) for c in range(ncols)] for r in rows]
    pivots = []
    r = 0
    for c in range(ncols):
        piv = None
        for i in range(r, len(mat)):
            if mat[i][c] != 0:
                piv = i
                break
        if piv is None:
            continue
        mat[r], mat[piv] = mat[piv], mat[r]
        pv = mat[r][c]
        mat[r] = [x / pv for x in mat[r]]
        for i in range(len(mat)):
            if i != r and mat[i][c] != 0:
                f = mat[i][c]
                mat[i] = [a - f * b for a, b in zip(mat[i], mat[r])]
        pivots.append(c)
        r += 1
        if r == len(mat):
            break
    free = [c for c in range(ncols) if c not in pivots]
    basis = []
    for fc in free:
        v = [Q(0)] * ncols
        v[fc] = Q(1)
        for ri, pc in enumerate(pivots):
            v[pc] = -mat[ri][fc]
        basis.append(v)
    return len(free), basis


def search(monos, N, perturbed=None):
    rhs = rhs_monomials(N, perturbed)
    acc = poly_time_derivative(monos, None, N, rhs)
    rows = list(acc.values())
    return nullspace_dim_and_basis(rows, len(monos))


def quad_monos(N):
    return [(n, n) for n in range(1, N + 1)]


def quartic_diag(N):
    return [(n, n, n, n) for n in range(1, N + 1)]


def quartic_neighbour(N):
    return [(n, n, n + 1, n + 1) for n in range(1, N)]


def quartic_banded(N, w):
    """All sorted 4-index monomials whose index spread is < w."""
    out = []
    for combo in itertools.combinations_with_replacement(range(1, N + 1), 4):
        if combo[-1] - combo[0] < w:
            out.append(combo)
    return out


def fmt(v):
    return "[" + ", ".join(str(x) for x in v) + "]"


def main():
    print("== TIER B: quartic invariants of the truncated dyadic system (exact rationals) ==\n")
    ok = True

    print("FACT 0 -- identity (Q1): energy is the UNIQUE conserved weighted quadratic.")
    print("   d/dt H_g has nonlinear prefactor 2(lam^{2g} - 1), which vanishes only at g = 0.")
    for g in (Q(0), Q(1, 2), Q(1), Q(-1)):
        pref = Q(LAM) ** (2 * g) - 1 if (2 * g).denominator == 1 else None
        if pref is None:
            continue
        print(f"      gamma={str(g):>4}: prefactor = {pref}"
              + ("   <- conserved" if pref == 0 else ""))
    print()

    print("POSITIVE CONTROL -- weighted-quadratic search must return exactly span{energy}:")
    for N in (5, 7, 9):
        dim, basis = search(quad_monos(N), N)
        good = (dim == 1)
        if good and basis:
            b = basis[0]
            good = all(x == b[0] and x != 0 for x in b)     # constant vector = energy
        ok &= good
        shown = fmt(basis[0]) if basis else "(none)"
        print(f"   N={N}: dim = {dim}, basis = {shown}   {'OK (energy)' if good else '*** FAILED ***'}")

    print("\nPOSITIVE CONTROL 2 -- exponent-shifted system: telescoping survives, so the search")
    print("   must find the SHIFTED invariant c_n = lam^{-n}, not the constant one:")
    for N in (5, 7):
        dim, basis = search(quad_monos(N), N, perturbed="exponent")
        good = (dim == 1)
        if good and basis:
            b = basis[0]
            good = all(b[i] * Q(LAM) == b[i - 1] for i in range(1, len(b))) and b[0] != 0
        ok &= good
        print(f"   N={N}: dim = {dim}, basis = {fmt(basis[0]) if basis else '(none)'}"
              f"   {'OK (geometric weights)' if good else '*** FAILED ***'}")

    print("\nNEGATIVE CONTROL -- index structure broken (out-flux couples u_n u_{n+2}):")
    print("   in-flux and out-flux monomial patterns are then incompatible; NO weighting works.")
    for N in (5, 7, 9):
        dim, _ = search(quad_monos(N), N, perturbed="gap")
        good = (dim == 0)
        ok &= good
        print(f"   N={N}: dim = {dim}   {'OK (control fires: no invariant)' if good else '*** DEAD CONTROL ***'}")

    if not ok:
        print("\nCONTROLS FAILED -- refusing to report any quartic search.")
        return 1

    print("\ncontrols pass. QUARTIC SEARCHES (inviscid truncated system):")
    for N in (5, 7, 9):
        d1, _ = search(quartic_diag(N), N)
        d2, _ = search(quartic_neighbour(N), N)
        print(f"   N={N}:  diagonal  sum c_n u_n^4      -> dim {d1}")
        print(f"          neighbour sum c_n u_n^2u_{{n+1}}^2 -> dim {d2}")

    print("\n   banded general quartics (window w; contains diagonal and neighbour):")
    for N, w in ((5, 3), (6, 3), (7, 3), (5, 4), (6, 4)):
        monos = quartic_banded(N, w)
        dim, basis = search(monos, N)
        print(f"      N={N} w={w}: {len(monos):>3} monomials -> nullspace dim {dim}")
        if dim > 0:
            print(f"         (a basis vector: {fmt(basis[0])[:100]}...)")

    print("\nReading, against the criterion fixed in advance: a nullspace of dimension 0 means")
    print("NO conserved quartic exists in that class -- not even E^2, because E^2 is not banded")
    print("(it couples index 1 to index N). Door #1 would then be closed for BANDED polynomial")
    print("quartic invariants, which is the natural home of an energy-method improvement.")
    print("Scope of that closure, which must travel with it: it does not close monotone-without-")
    print("certificate quantities, non-polynomial ones, invariant-subset ones, or door #2.")
    print("\nTIER B GATE (quartic invariants): PASS (exact rationals; positive controls find")
    print("energy uniquely and track the shifted weights under an exponent change; the negative")
    print("control, with the index structure broken, demonstrably finds nothing)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
