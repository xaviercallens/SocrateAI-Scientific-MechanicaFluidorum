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

  The cutoff BITES (the grid can detect something) iff the strict converse holds.

GENERALISED TO ANY DISSIPATION DEGREE alpha (2026-08-14). The criterion above was derived for
alpha = 1 and is WRONG elsewhere, so reusing it silently after the programme decided to work at
other alpha would have reintroduced the very failure this file exists to prevent. For general
alpha the same balance gives k_d = nu^{-1/(2a - 2/3)}, and with alpha = p/q the exact test is

      nu^(3q) * 2^(N(6p-2q))  >=  1 ,

which at alpha = 1 collapses to 2^(4N) nu^3 >= 1 -- verified against the original form on 21
cases in main(), so nothing previously checked changes.

A CONSISTENCY CHECK THAT WAS NOT PUT IN BY HAND. The exponent 1/(2a - 2/3) diverges as
alpha -> 1/3 from above, and for alpha <= 1/3 the K41 balance has NO solution: there is no
dissipation scale, so the cascade is not stopped at any finite shell. That is exactly Cheskidov's
proven blow-up threshold (alpha < 1/3), arrived at here from an elementary heuristic that knows
nothing about his proof. Below the threshold the function REFUSES to answer rather than
returning a meaningless value -- grid adequacy is not the relevant question there; regime
adequacy is (tests/tier_b_regime_adequacy.py, docs/designs/REGIME_MAP.md).

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


def cutoff_at_or_above_dissipation(nu: Q, N: int, alpha: Q = Q(1)) -> bool:
    """Exact test, for a general dissipation degree `alpha`.

    Balancing nu*k^{2a} against the nonlinear rate k*a_k with the K41 amplitude a_k ~ k^{-1/3}:
        nu*k^{2a} = k^{2/3}  =>  k_d = nu^{-1/(2a - 2/3)} ,
    so the cutoff k_N = 2^N is at or above the dissipation scale iff nu*2^{N(2a-2/3)} >= 1.
    Writing alpha = p/q, we have 2a - 2/3 = (6p-2q)/(3q); raising both sides to the power 3q > 0
    (which preserves the direction) clears every fraction and leaves exact rational arithmetic:

        nu^(3q) * 2^(N(6p-2q))  >=  1 .

    At alpha = 1 (p=q=1) this is nu^3 * 2^(4N) >= 1, the original alpha=1 criterion, so nothing
    previously checked changes.

    Raises for alpha <= 1/3, where 6p-2q <= 0 and there is NO dissipation scale in this sense --
    the K41 balance has no solution, which is exactly why blow-up is possible there. That the
    heuristic's breakdown point coincides with Cheskidov's proven blow-up threshold alpha < 1/3
    is a nontrivial consistency check on the criterion, not an assumption fed into it.
    """
    if nu <= 0:
        raise ValueError("viscosity must be positive")
    if alpha <= 0:
        raise ValueError("dissipation degree must be positive")
    p, q = alpha.numerator, alpha.denominator
    e = 6 * p - 2 * q
    if e <= 0:
        raise ValueError(
            f"alpha = {alpha} <= 1/3: no dissipation scale exists, so 'cutoff above the "
            f"dissipation scale' is not defined. Grid adequacy is not the relevant question "
            f"in that regime -- see tests/tier_b_regime_adequacy.py and docs/designs/REGIME_MAP.md."
        )
    return (nu ** (3 * q)) * (Q(2) ** (N * e)) >= 1


def cutoff_bites(nu: Q, N: int, alpha: Q = Q(1)) -> bool:
    """The truncation removes shells the dynamics would actually have used."""
    return not cutoff_at_or_above_dissipation(nu, N, alpha)


def max_biting_cutoff(nu: Q, search_max: int = 64, alpha: Q = Q(1)) -> int:
    """Largest N whose cutoff still bites (-1 if none). Exact; bounded loop."""
    best = -1
    for N in range(0, search_max + 1):
        if cutoff_bites(nu, N, alpha):
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
    print("  sanity anchors (N thresholds at nu=1e-3 and 1e-2): PASS")

    # --- the generalised criterion must reduce EXACTLY to the alpha=1 form ---
    for N in (0, 3, 5, 7, 8, 12, 20):
        for nu in (Q(1, 10), Q(1, 100), Q(1, 1000)):
            gen = cutoff_at_or_above_dissipation(nu, N, Q(1))
            old = (2 ** (4 * N)) * (nu.numerator ** 3) >= (nu.denominator ** 3)
            assert gen == old, f"alpha=1 reduction broken at nu={nu}, N={N}"
    print("  generalised criterion reduces exactly to the alpha=1 form (21 cases): PASS")

    # --- below alpha = 1/3 the question is not defined, and must be refused, not answered ---
    refused = 0
    for bad in (Q(1, 3), Q(1, 4), Q(1, 5)):
        try:
            cutoff_at_or_above_dissipation(Q(1, 1000), 8, bad)
        except ValueError:
            refused += 1
    assert refused == 3, "alpha <= 1/3 must be refused, not silently answered"
    print("  alpha <= 1/3 correctly refused (no dissipation scale exists there): PASS\n")

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
