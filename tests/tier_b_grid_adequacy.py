#!/usr/bin/env python3
"""Tier B exact-arithmetic check: can a proposed (nu, N) grid DETECT cutoff-dependence at all?

WHY THIS EXISTS. On 2026-08-14 the programme's own synthesis -- "44/45 configurations flat in
N", written into LEDGER.md as the evidence base for a uniformity verdict -- was found to be an
artifact of the grid rather than a finding about the dynamics. Direct shell-amplitude profiling
showed the cascade never reaches the shells the grid varies: at nu=0.01 the highest populated
shell is n=8 while the grid tested N in {8,12,16,20,24}, so every added shell was numerically
ZERO. Adding zeros changes sup_Omega by exactly nothing, which is also why 44/45 configurations
agreed BIT-IDENTICALLY -- a fact reported as striking evidence that was really the signature of
a measurement with no detection power.

This harness makes that failure mode impossible to repeat silently: it rejects a proposed grid
BEFORE it is run, on exact integer arithmetic, whenever the cutoff sits at or above the
dissipation scale (so truncation removes nothing the dynamics was using).

THE CRITERION, DERIVED EXACTLY (no floats, no logs).

  Balance the viscous rate against the nonlinear transfer rate at shell n:
      viscous    ~ nu * k_n^2
      nonlinear  ~ k_n * a_n ,   with the K41 shell amplitude a_n ~ k_n^{-1/3}
  Equality gives the dissipation wavenumber:
      nu * k^2 = k * k^{-1/3}   =>   nu * k^{4/3} = 1   =>   k_d = nu^{-3/4}.

  With k_n = 2^n the cutoff N lies AT OR ABOVE the dissipation scale iff
      2^N >= nu^{-3/4}
  Raising both sides to the 4th power (both positive, so the direction is preserved) and
  clearing nu:
      2^(4N) * nu^3 >= 1 .
  Writing nu = p/q exactly as a Fraction, this is the INTEGER inequality
      2^(4N) * p^3 >= q^3 .
  No logarithm, no float, no rounding: the whole test is integer comparison.

  The cutoff BITES (the grid can detect something) iff the strict converse holds:
      2^(4N) * p^3 < q^3 .

SCOPE / HONESTY. k_d ~ nu^{-3/4} is the standard K41 estimate and is an ORDER-OF-MAGNITUDE
criterion, not a theorem about this shell model; it carries an unknown O(1) prefactor. It is
used here only in the safe direction: a grid it rejects is one where the cutoff exceeds the
dissipation scale by a factor that grows GEOMETRICALLY in N (each shell doubles k), so an O(1)
prefactor cannot rescue it. A grid it accepts is not thereby proven informative -- it is merely
not disqualified on this ground. The check is necessary, not sufficient.

NEGATIVE CONTROL (PLAN.md: "a checker that cannot fail is not a checker"). The historical grid
that produced the retracted synthesis -- nu in {1/10, 1/100, 1/1000}, N in {8,12,16,20,24} --
must be REJECTED by this harness. That is a negative control on real data the programme already
published, not a synthetic one. A positive control (a grid with small N at small nu, where
truncation genuinely amputates the cascade) must be ACCEPTED.

Exact arithmetic throughout: fractions.Fraction and int only. Deterministic.
"""

import sys
from fractions import Fraction as Q


def cutoff_at_or_above_dissipation(nu: Q, N: int) -> bool:
    """Exact integer test of 2^(4N) * nu^3 >= 1, i.e. 2^(4N) * p^3 >= q^3."""
    if nu <= 0:
        raise ValueError("viscosity must be positive")
    p, q = nu.numerator, nu.denominator
    return (2 ** (4 * N)) * (p ** 3) >= (q ** 3)


def cutoff_bites(nu: Q, N: int) -> bool:
    """The truncation removes shells the dynamics would actually have used."""
    return not cutoff_at_or_above_dissipation(nu, N)


def max_biting_cutoff(nu: Q, search_max: int = 64) -> int:
    """Largest N whose cutoff still bites (-1 if none). Exact; bounded loop."""
    best = -1
    for N in range(0, search_max + 1):
        if cutoff_bites(nu, N):
            best = N
    return best


def assess_grid(nus, Ns, label):
    """A grid is ADEQUATE if at least one (nu, N) pair has a biting cutoff."""
    biting = [(nu, N) for nu in nus for N in Ns if cutoff_bites(nu, N)]
    total = len(nus) * len(Ns)
    print(f"  {label}")
    print(f"    configurations: {total}; with a BITING cutoff: {len(biting)}")
    for nu in nus:
        nmax = max_biting_cutoff(nu)
        tested_biting = sorted(N for N in Ns if cutoff_bites(nu, N))
        print(f"      nu={str(nu):>8}: cutoff bites only for N <= {nmax}; "
              f"tested N that bite: {tested_biting if tested_biting else 'NONE'}")
    return len(biting) > 0


def main():
    print("== Tier B: experiment-grid adequacy (exact integer criterion) ==\n")

    # --- Sanity anchors, hand-checkable ---
    # nu = 1/1000 : 2^(4N) >= 10^9  <=>  4N >= ~29.9  <=>  N >= 8.
    assert cutoff_at_or_above_dissipation(Q(1, 1000), 8), "anchor: N=8 is above dissipation at nu=1e-3"
    assert cutoff_bites(Q(1, 1000), 7), "anchor: N=7 still bites at nu=1e-3"
    # nu = 1/100  : 2^(4N) >= 10^6  <=>  4N >= ~19.9  <=>  N >= 5.
    assert cutoff_at_or_above_dissipation(Q(1, 100), 5), "anchor: N=5 is above dissipation at nu=1e-2"
    assert cutoff_bites(Q(1, 100), 4), "anchor: N=4 still bites at nu=1e-2"
    print("  sanity anchors (N thresholds at nu=1e-3 and 1e-2): PASS\n")

    HISTORICAL_NUS = [Q(1, 10), Q(1, 100), Q(1, 1000)]
    HISTORICAL_NS = [8, 12, 16, 20, 24]

    print("NEGATIVE CONTROL — the historical grid behind the retracted synthesis:")
    hist_ok = assess_grid(HISTORICAL_NUS, HISTORICAL_NS, "nu in {1/10,1/100,1/1000}, N in {8,12,16,20,24}")
    if hist_ok:
        print("\n  NEGATIVE CONTROL FAILED: the historical grid was accepted, but it is the very")
        print("  grid whose flatness was shown to be an artifact. The checker cannot fail.")
        sys.exit(1)
    print("    -> REJECTED, as required: no tested configuration has a biting cutoff.\n")

    print("POSITIVE CONTROL — a grid designed so truncation amputates the cascade:")
    GOOD_NUS = [Q(1, 1000)]
    GOOD_NS = [3, 4, 5, 6, 7]
    good_ok = assess_grid(GOOD_NUS, GOOD_NS, "nu = 1/1000, N in {3,4,5,6,7}")
    if not good_ok:
        print("\n  POSITIVE CONTROL FAILED: a grid with cutoffs below the dissipation scale was")
        print("  rejected. The checker rejects everything and is therefore useless.")
        sys.exit(1)
    print("    -> ACCEPTED, as required.\n")

    print("TIER B GATE (grid adequacy): PASS (exact integer criterion; the historical grid is "
          "demonstrably rejected and a cutoff-biting grid is demonstrably accepted; anchors hold)")


if __name__ == "__main__":
    main()
