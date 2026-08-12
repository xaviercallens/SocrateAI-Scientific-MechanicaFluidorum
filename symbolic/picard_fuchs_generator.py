#!/usr/bin/env python3
"""Guess-and-prove pipeline for recurrence operators (Stream 1, spec §4.2).

NOTE (review correction to spec v0.1): `gfun` is a Maple package
(Salvy–Zimmermann, Inria), not a Python library.  For production-scale
Picard–Fuchs guessing use SageMath's `ore_algebra` (Kauers–Jaroschek–Johansson)
or Maple `gfun`; this module provides the exact-ℚ core needed now:

  guess_recurrence(seq, order)  — fit a constant-coefficient linear recurrence
                                  of the given order by exact linear algebra
  verify_recurrence(seq, coeffs) — check the guess on ALL remaining terms

Everything is exact (fractions.Fraction).  A guess that fits the fitting
window but fails verification is rejected — this is the Tier C → Tier B
promotion step.  Tier B → Tier A promotion is a Lean proof (see
lean_src/CallensDualScale.lean, `sym2_recurrence`).
"""

from fractions import Fraction as Q


def _solve_exact(rows):
    """Gauss–Jordan over ℚ. rows: augmented matrix. Returns solution or None."""
    n = len(rows[0]) - 1
    rows = [list(r) for r in rows]
    m = len(rows)
    col = 0
    pivots = []
    for i in range(m):
        while col < n:
            piv = next((r for r in range(i, m) if rows[r][col] != 0), None)
            if piv is not None:
                break
            col += 1
        else:
            break
        rows[i], rows[piv] = rows[piv], rows[i]
        rows[i] = [x / rows[i][col] for x in rows[i]]
        for r in range(m):
            if r != i and rows[r][col] != 0:
                f = rows[r][col]
                rows[r] = [x - f * y for x, y in zip(rows[r], rows[i])]
        pivots.append(col)
        col += 1
    if len(pivots) < n:
        return None  # underdetermined
    for r in range(len(pivots), m):
        if rows[r][n] != 0 and all(x == 0 for x in rows[r][:n]):
            return None  # inconsistent
    sol = [Q(0)] * n
    for i, c in enumerate(pivots):
        sol[c] = rows[i][n]
    return sol


def guess_recurrence(seq, order):
    """Guess c s.t. seq[n+order] = sum(c[j] * seq[n+j] for j in range(order)).

    Uses the first `2*order` windows for an overdetermined exact fit.
    Returns list of Fractions (c_0 ... c_{order-1}) or None.
    """
    seq = [Q(x) for x in seq]
    need = 2 * order + order
    if len(seq) < need:
        raise ValueError(f"need at least {need} terms, got {len(seq)}")
    rows = [seq[n:n + order] + [seq[n + order]] for n in range(2 * order)]
    return _solve_exact(rows)


def verify_recurrence(seq, coeffs):
    """Exact check of the recurrence on every available window of seq."""
    seq = [Q(x) for x in seq]
    order = len(coeffs)
    return all(
        seq[n + order] == sum(c * seq[n + j] for j, c in enumerate(coeffs))
        for n in range(len(seq) - order)
    )


if __name__ == "__main__":
    # Demonstration on the Sym² lock: u_{n+2} = a u_{n+1} + b u_n,
    # guess the order-3 operator satisfied by v = u² and confirm it equals
    # Sym²(L2) = [−b³, b(a²+b), a²+b].
    a, b = Q(2), Q(3)
    u = [Q(1), Q(1)]
    for _ in range(20):
        u.append(a * u[-1] + b * u[-2])
    v = [x * x for x in u]

    c = guess_recurrence(v, 3)
    assert c is not None, "no order-3 recurrence found"
    assert verify_recurrence(v, c), "guess failed verification window"
    expected = [-(b ** 3), b * (a * a + b), a * a + b]
    assert c == expected, (c, expected)
    print(f"[Tier B] guessed L3 coefficients {c} == Sym²(L2) closed form  ✓")

    # Negative control (§5.3): u³ does NOT satisfy an order-3 operator
    # (Sym³(L2) has order 4) — the guesser must refuse or fail verification.
    w = [x ** 3 for x in u]
    c3 = guess_recurrence(w, 3)
    ok = c3 is not None and verify_recurrence(w, c3)
    assert not ok, "negative control failed: cubes wrongly fit order 3"
    print("[Tier B] negative control: cubes rejected at order 3 (need Sym³, order 4)  ✓")
    c4 = guess_recurrence(w, 4)
    assert c4 is not None and verify_recurrence(w, c4)
    print(f"[Tier B] cubes verified at order 4: {c4}  ✓")
