#!/usr/bin/env python3
"""Tier B exact-arithmetic validation harness for the dyadic shell model
(PLAN.md §5, task D1).

All checks run in exact rational arithmetic (fractions.Fraction) or exact
integers — floating point is barred by the Tier B gate.  Deterministic: no
randomness, no clock.

MODEL (pre-authored in PLAN.md §5 / D1; implemented exactly, not re-derived).
Shells n = 0..N.  Wavenumbers k_n = 2^n (exact integers).  State a: list of
Fraction, a[0..N].  Boundary convention: a_{-1} = 0, a_{N+1} = 0.
Nonlinear part of da_n/dt:

    NL_n = k_{n-1} * a_{n-1}^2  -  k_n * a_n * a_{n+1}

(the linear viscous part -nu*k_n^2*a_n plays no role in this identity and is
not modelled here).  At n = 0 the term k_{-1} * a_{-1}^2 is taken to be 0
directly (a_{-1} = 0 by the boundary convention; k_{-1} = 2^{-1} is never
evaluated, keeping k_n an exact integer for all n actually used).

THE IDENTITY CERTIFIED (TELESCOPING), pre-derived in PLAN.md / the task
prompt, not re-derived here:

    sum_{n=0}^{N} a_n * NL_n  =  0

with the partial-sum (un-cancelled boundary term) refinement: for every
0 <= m <= N,

    sum_{n=0}^{m} a_n * NL_n  =  - k_m * a_m^2 * a_{m+1}

(where a_{N+1} = 0, so the m = N case reduces to the full identity being 0).

Checks:
  D1.a  TELESCOPING holds exactly, for N in 1..12, over a deterministic
        family of 20 rational states a_n = Fraction(p+n, q+2n), (p,q) drawn
        from a hardcoded list (q always odd, so q+2n is never zero).
  D1.b  Partial-sum form holds exactly for every 0 <= m <= N, same family.
  D1.c  NEGATIVE CONTROL (required): perturb the model by using k_n (not
        k_{n-1}) in the in-flux term only; assert TELESCOPING now FAILS for
        at least one state, and print the failing residual.

Exit status 0 iff every check passes (i.e. D1.a and D1.b hold exactly, and
the negative control in D1.c genuinely fails as required).
"""

from fractions import Fraction as Q
import sys

FAILURES = []


def check(name, cond, detail=""):
    if not cond:
        FAILURES.append((name, detail))
        print(f"  FAIL {name}: {detail}")


# ---------------------------------------------------------------- model
def k(n):
    """k_n = 2^n, exact integer. Only ever called for n >= 0."""
    return Q(2) ** n


# Hardcoded (p, q) pairs, q always odd so that q + 2n (n = 0..12) is never
# zero (odd + even = odd != 0). Includes negatives and a zero p.
PQ_PAIRS = [
    (0, 1), (1, 1), (-1, 1), (2, 3), (-2, 3),
    (3, -1), (-3, -1), (0, -3), (5, 7), (-5, 7),
    (1, -5), (-1, -5), (4, 9), (-4, 9), (2, -7),
    (-2, -7), (7, 11), (-7, 11), (0, 13), (10, -13),
]
assert len(PQ_PAIRS) == 20
assert all(q % 2 != 0 for _, q in PQ_PAIRS), "q must be odd (denominator safety)"


def make_state(p, q, N):
    """a_n = (p+n)/(q+2n) for n = 0..N, exact Fraction, no floats."""
    a = []
    for n in range(N + 1):
        den = q + 2 * n
        assert den != 0, f"denominator underflow at p={p} q={q} n={n}"
        a.append(Q(p + n, den))
    return a


def nl(a, n, N, perturb_influx=False):
    """NL_n = k_{n-1} a_{n-1}^2 - k_n a_n a_{n+1}, boundary a_{-1}=a_{N+1}=0.

    If perturb_influx is True (negative control only), the in-flux term
    uses k_n instead of the correct k_{n-1} -- this is a deliberately wrong
    model, used only to demonstrate the checker can fail.
    """
    a_prev = a[n - 1] if n - 1 >= 0 else Q(0)
    a_next = a[n + 1] if n + 1 <= N else Q(0)
    if n - 1 >= 0:
        k_influx = k(n) if perturb_influx else k(n - 1)
        term1 = k_influx * a_prev * a_prev
    else:
        term1 = Q(0)  # a_{-1} = 0; k_{-1} never evaluated
    term2 = k(n) * a[n] * a_next
    return term1 - term2


# ---------------------------------------------------------------- D1.a
def d1a_telescoping():
    print("[D1.a] Telescoping identity, exact ℚ, N=1..12, 20 states")
    cases = 0
    for N in range(1, 13):
        for (p, q) in PQ_PAIRS:
            a = make_state(p, q, N)
            total = sum(a[n] * nl(a, n, N) for n in range(N + 1))
            check("D1.a", total == 0,
                  f"N={N} p={p} q={q}: sum = {total} != 0")
            cases += 1
    print(f"  {cases} (N, p, q) cases, all exact sums == 0")


# ---------------------------------------------------------------- D1.b
def d1b_partial_sum():
    print("[D1.b] Partial-sum form: sum_{n=0}^{m} a_n NL_n = -k_m a_m^2 a_{m+1}")
    cases = 0
    for N in range(1, 13):
        for (p, q) in PQ_PAIRS:
            a = make_state(p, q, N)
            running = Q(0)
            for m in range(N + 1):
                running += a[m] * nl(a, m, N)
                a_next = a[m + 1] if m + 1 <= N else Q(0)
                expected = -k(m) * a[m] * a[m] * a_next
                check("D1.b", running == expected,
                      f"N={N} p={p} q={q} m={m}: {running} != {expected}")
                cases += 1
    print(f"  {cases} (N, p, q, m) cases, all exact equalities hold")


# ---------------------------------------------------------------- D1.c
def d1c_negative_control():
    print("[D1.c] NEGATIVE CONTROL: perturb in-flux k_{n-1} -> k_n, "
          "expect TELESCOPING to fail")
    found_failure = False
    worst = None
    for N in range(1, 13):
        for (p, q) in PQ_PAIRS:
            a = make_state(p, q, N)
            total = sum(a[n] * nl(a, n, N, perturb_influx=True)
                        for n in range(N + 1))
            if total != 0:
                found_failure = True
                if worst is None:
                    worst = (N, p, q, total)
    if found_failure:
        N, p, q, total = worst
        print(f"  perturbed model genuinely fails telescoping, e.g. "
              f"N={N} p={p} q={q}: residual = {total} (!= 0), as required")
    check("D1.c.negative_control_fires", found_failure,
          "perturbed model did NOT fail -- negative control is broken; "
          "the checker cannot distinguish correct from incorrect model")


if __name__ == "__main__":
    d1a_telescoping()
    d1b_partial_sum()
    d1c_negative_control()
    if FAILURES:
        print(f"\nTIER B GATE (dyadic): FAIL ({len(FAILURES)} failures)")
        sys.exit(1)
    print("\nTIER B GATE (dyadic): PASS (all checks exact, zero floating "
          "point; negative control confirmed to fail as required)")
