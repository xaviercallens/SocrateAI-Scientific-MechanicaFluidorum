#!/usr/bin/env python3
"""Tier B exact-arithmetic validation harness for the dyadic enstrophy
production identity (PLAN.md §5 lineage; task P1 -- nonlinear part of
dOmega/dt).  Style matches tests/tier_b_dyadic_checks.py.

All checks run in exact rational arithmetic (fractions.Fraction) or exact
integers -- floating point is barred by the Tier B gate.  Deterministic: no
randomness, no clock.

MODEL (as given in the task prompt; the identity below is PRE-DERIVED and
HAND-VERIFIED -- this file CERTIFIES it computationally across many exact
cases, it does not re-derive it).

Shells n = 0..N.  Wavenumbers k: Nat -> Fraction with dyadic doubling
k_{n+1} = 2 * k_n for all n >= 0; the primary check specializes to
k_n = 2^n exactly (an exact integer, held as Fraction).  State a: list of
Fraction, a[0..N].  Boundary convention (truncation): a_{-1} = 0,
a_{N+1} = 0.

    NL_n = k_{n-1} * a_{n-1}^2  -  k_n * a_n * a_{n+1}

(n = 0 term drops the first part since a_{-1} = 0; k_{-1} is never
evaluated).

THE IDENTITY CERTIFIED (nonlinear part of dOmega/dt only; the viscous part
-nu * sum k_n^4 a_n^2 is a separate, already-checked term and is NOT part of
this identity -- no nu appears anywhere below):

    sum_{n=0}^{N} k_n^2 * a_n * NL_n   =   3 * sum_{n=0}^{N-1} k_n^3 * a_n^2 * a_{n+1}

for k_n = 2^n (doubling ratio r = 2, coefficient = r^2 - 1 = 3).

Sanity case (given in the task prompt, hand-verified): N=2, k=(1,2,4),
a=(1,2,3): both sides equal exactly 294. This is checked FIRST, before the
sweep, and the run aborts (AssertionError) if it does not reproduce exactly.

Checks:
  P1.a  Identity holds exactly for N in 1..12, k_n = 2^n, over 20
        deterministic rational states a_n = Fraction(p+n, q+2n), (p,q) from
        a hardcoded list (q always odd, so q+2n is never zero; same family
        as tests/tier_b_dyadic_checks.py for continuity).
  P1.b  NEGATIVE CONTROL (required): replace k_n = 2^n with the NON-DOUBLING
        arithmetic sequence k_n = n+1 (k_{n+1} != 2*k_n in general), and
        assert the identity with coefficient 3 now FAILS for at least one
        state; the failing residual is printed. This demonstrates that
        coefficient 3 is a genuine consequence of the dyadic doubling ratio
        (ratio r gives coefficient r^2 - 1; r=2 => 3), not an artifact of
        the summation structure.
  P1.c  BONUS (confirmatory, only run if P1.a/P1.b pass): k_n = 3^n
        (doubling ratio r=3, k_{n+1} = 3*k_n, not 2*k_n -- still a *doubling
        family* in the general dyadic-doubling sense used by the model, just
        with ratio 3 instead of 2), same identity but with coefficient
        r^2 - 1 = 8 instead of 3.

Exit status 0 iff P1.a and P1.b hold exactly as required (P1.a positive,
P1.b's negative control genuinely fires). P1.c is confirmatory and does not
gate the exit status beyond also being required to hold if it runs.
"""

from fractions import Fraction as Q
import sys

FAILURES = []


def check(name, cond, detail=""):
    if not cond:
        FAILURES.append((name, detail))
        print(f"  FAIL {name}: {detail}")


# ---------------------------------------------------------------- model
def k_pow2(n):
    """k_n = 2^n, exact integer (dyadic doubling, ratio r=2). n >= 0 only."""
    return Q(2) ** n


def k_pow3(n):
    """k_n = 3^n, exact integer (doubling ratio r=3). n >= 0 only."""
    return Q(3) ** n


def k_arith(n):
    """k_n = n+1, NOT a doubling sequence (k_{n+1} != 2*k_n in general).
    Used only for the P1.b negative control."""
    return Q(n + 1)


# Hardcoded (p, q) pairs, q always odd so that q + 2n (n = 0..12) is never
# zero (odd + even = odd != 0). Includes negatives and a zero p. Same family
# as tests/tier_b_dyadic_checks.py, reused here for style continuity.
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


def nl(a, n, N, kfun):
    """NL_n = k_{n-1} a_{n-1}^2 - k_n a_n a_{n+1}, boundary a_{-1}=a_{N+1}=0.

    kfun is only ever evaluated at indices >= 0 (the a_{-1}=0 boundary term
    is short-circuited to Q(0) without calling kfun(-1))."""
    a_next = a[n + 1] if n + 1 <= N else Q(0)
    if n - 1 >= 0:
        a_prev = a[n - 1]
        term1 = kfun(n - 1) * a_prev * a_prev
    else:
        term1 = Q(0)
    term2 = kfun(n) * a[n] * a_next
    return term1 - term2


def lhs(a, N, kfun):
    """sum_{n=0}^{N} k_n^2 * a_n * NL_n"""
    return sum(kfun(n) ** 2 * a[n] * nl(a, n, N, kfun) for n in range(N + 1))


def rhs(a, N, kfun, coeff):
    """coeff * sum_{n=0}^{N-1} k_n^3 * a_n^2 * a_{n+1}"""
    return coeff * sum(kfun(n) ** 3 * a[n] ** 2 * a[n + 1] for n in range(N))


# ------------------------------------------------------------- sanity case
def sanity_case():
    print("[sanity] N=2, k=(1,2,4), a=(1,2,3): both sides must equal 294 exactly")
    N = 2
    a = [Q(1), Q(2), Q(3)]
    L = lhs(a, N, k_pow2)
    R = rhs(a, N, k_pow2, 3)
    print(f"  LHS = {L}   RHS = {R}")
    assert L == Q(294), f"LHS = {L} != 294 -- implementation does not match the hand-verified case"
    assert R == Q(294), f"RHS = {R} != 294 -- implementation does not match the hand-verified case"
    assert L == R
    print("  sanity case reproduces 294 == 294 exactly -- proceeding to sweep")


# ---------------------------------------------------------------- P1.a
def p1a_identity():
    print("[P1.a] Identity holds exactly, k_n=2^n, N=1..12, 20 states, coeff=3")
    cases = 0
    for N in range(1, 13):
        for (p, q) in PQ_PAIRS:
            a = make_state(p, q, N)
            L = lhs(a, N, k_pow2)
            R = rhs(a, N, k_pow2, 3)
            check("P1.a", L == R,
                  f"N={N} p={p} q={q}: LHS={L} RHS={R} residual={L - R}")
            cases += 1
    print(f"  {cases} (N, p, q) cases, all exact LHS == RHS")


# ---------------------------------------------------------------- P1.b
def p1b_negative_control():
    print("[P1.b] NEGATIVE CONTROL: k_n = n+1 (non-doubling), coeff=3 kept fixed, "
          "expect identity to FAIL")
    found_failure = False
    worst = None
    for N in range(1, 13):
        for (p, q) in PQ_PAIRS:
            a = make_state(p, q, N)
            L = lhs(a, N, k_arith)
            R = rhs(a, N, k_arith, 3)
            if L != R:
                found_failure = True
                if worst is None:
                    worst = (N, p, q, L, R)
    if found_failure:
        N, p, q, L, R = worst
        print(f"  non-doubling k genuinely breaks the identity, e.g. "
              f"N={N} p={p} q={q}: LHS={L} RHS={R} residual={L - R} (!= 0), as required")
    check("P1.b.negative_control_fires", found_failure,
          "perturbed (non-doubling) model did NOT fail -- negative control is "
          "broken; the checker cannot distinguish the dyadic-doubling identity "
          "from an arbitrary k sequence")


# ---------------------------------------------------------------- P1.c (bonus)
def p1c_bonus_ratio3():
    print("[P1.c] BONUS (confirmatory): k_n=3^n (doubling ratio r=3), "
          "coeff = r^2-1 = 8, N=1..12, 20 states")
    cases = 0
    for N in range(1, 13):
        for (p, q) in PQ_PAIRS:
            a = make_state(p, q, N)
            L = lhs(a, N, k_pow3)
            R = rhs(a, N, k_pow3, 8)
            check("P1.c", L == R,
                  f"N={N} p={p} q={q}: LHS={L} RHS={R} residual={L - R}")
            cases += 1
    print(f"  {cases} (N, p, q) cases, all exact LHS == RHS (r=3, coeff=8)")


if __name__ == "__main__":
    sanity_case()
    p1a_identity()
    p1b_negative_control()
    p1c_ran = False
    if not FAILURES:
        p1c_bonus_ratio3()
        p1c_ran = True
    else:
        print("[P1.c] SKIPPED (P1.a/P1.b did not both pass; bonus is not required)")
    if FAILURES:
        print(f"\nTIER B GATE (enstrophy production): FAIL ({len(FAILURES)} failures)")
        sys.exit(1)
    print(f"\nTIER B GATE (enstrophy production): PASS (all checks exact, zero "
          f"floating point; negative control confirmed to fail as required; "
          f"P1.c bonus {'ran and passed' if p1c_ran else 'skipped'})")
