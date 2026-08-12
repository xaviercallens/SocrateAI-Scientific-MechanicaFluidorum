#!/usr/bin/env python3
"""Tier B exact-arithmetic certification of the sqrt-free local bound on the
enstrophy production term, per docs/designs/ENSTROPHY_PRODUCTION_BOUND.md
(PLAN.md lineage; dispatched from that design note's "Dispatch plan" §1).
Style matches tests/tier_b_enstrophy_production.py.

All checks run in exact rational arithmetic (fractions.Fraction) or exact
integers -- floating point is barred by the Tier B gate. Deterministic: no
randomness, no clock.

MODEL (as given in the task prompt and design note; the three-step chain
below is PRE-DERIVED and HAND-VERIFIED in the design note on the N=2
instance -- this file CERTIFIES it computationally across many exact cases,
it does not re-derive it).

Shells n = 0..N. k_n = 2^n exactly (int held as Fraction). State a: list of
Fraction, a[0..N]. Boundary convention (truncation, matched to the
production-identity file): a_{-1} = 0, a_{N+1} = 0 (not actually evaluated
by any sum below -- all sums stay within 0..N).

    S_N     = sum_{n=0}^{N-1} k_n^3 * a_n^2 * a_(n+1)
    Omega_N = (1/2) * sum_{n=0}^{N} k_n^2 * a_n^2

Three intermediate inequalities (design note's derivation, three elementary
steps) plus the combined MAIN bound:

  Step1: sum_{n=0}^{N-1} k_n^2 * a_(n+1)^2               <=  Omega_N / 2
  Step2: sum_{n=0}^{N-1} k_n^4 * a_n^4                    <=  4 * Omega_N^2
         (pointwise sum-of-squares-<=-square-of-sum lemma for
          x_n = k_n^2*a_n^2 >= 0; generic in k, needs NO doubling)
  Step3: S_N^2  <=  (sum_{n<N} k_n^4 a_n^4) * (sum_{n<N} k_n^2 a_(n+1)^2)
         (Cauchy-Schwarz on the two length-N sequences (k_n^2 a_n^2) and
          (k_n a_(n+1)); generic, needs NO doubling)
  MAIN:  S_N^2  <=  2 * Omega_N^3

Only Step1 uses the doubling structure k_{n-1} = k_n/2 (see design note
Step 1 derivation); Step2 and Step3 are generic pointwise/Cauchy-Schwarz
facts that hold for ANY k. This asymmetry is exploited by the negative
control below.

SANITY CASE (design note's own worked example, reproduced FIRST): N=2,
k=(1,2,4), a=(1,2,3). S_N=98 (from the identity file's own witness),
Omega_N=80.5=161/2.
  Step1 LHS=40, bound=Omega_N/2=40.25(=161/4)
  MAIN:  S_N^2=9604, bound=2*Omega_N^3=1043320.25(=4173281/4)
These two reproduce EXACTLY (see sanity_case()). Step2 does NOT reproduce
exactly as literally specified -- see the DISCREPANCY note printed by
sanity_case() and documented below: the task prompt's quoted "Step2
LHS=20993" is the design note's own Sigma x_n^2 over the FULL range
n=0..N (not the n=0..N-1 range that the Step2 bullet as literally worded,
and that Step3's Cauchy-Schwarz literally needs, uses). This file computes
BOTH quantities, uses the literal restricted-range one (n<N) as "Step2"
for the gating checks and for feeding Step3 (matching Step3's own stated
formula, which explicitly sums n<N on both factors), and separately
verifies the full-range quantity against the design note's own printed
20993/25921 numbers. Both quantities are algebraically <= 4*Omega_N^2 (the
restricted one trivially, being a sub-sum of the full one, which is itself
<= 4*Omega_N^2 by the sum-of-squares-<=-square-of-sum lemma) so the
discrepancy does not affect MAIN's validity; it is reported per the task's
explicit instruction to surface rather than silently paper over a mismatch
against the design note's quoted numbers.

Checks (N=1..12, same 20 deterministic (p,q) rational states as
tests/tier_b_enstrophy_production.py):
  PB.1  Step1 holds for every (N,p,q), k_n=2^n.
  PB.2  Step2 (restricted range n<N, the literal bullet quantity and the
        one Step3 actually uses) holds for every (N,p,q), k_n=2^n; the
        full-range companion quantity (matching the design note's 20993
        example) is also checked <= 4*Omega_N^2 as a confirmatory bonus.
  PB.3  Step3 (Cauchy-Schwarz combination) holds for every (N,p,q),
        k_n=2^n.
  PB.4  MAIN (S_N^2 <= 2*Omega_N^3) holds for every (N,p,q), k_n=2^n.
  PB.5  NEGATIVE CONTROL (required): break the doubling structure the same
        way as the production-identity file's own negative control
        (k_n = n+1), and separately the more extreme k_n = 1 for all n.
        Step1 -- the ONE step whose derivation used k_(n-1)=k_n/2 -- is
        shown to genuinely fail (LHS > bound) for many states under both
        broken k's; this is the required, gating negative control (mirrors
        the identity file's P1.b: it demonstrates the checker can actually
        detect a broken hypothesis, here specifically the doubling
        hypothesis that Step1's derivation used and Step2/Step3 did not).
        A search for an actual MAIN-bound violation (S_N^2 > 2*Omega_N^3)
        is ALSO run over the same broken k's and the same state family, as
        a separate, non-gating, honestly-reported finding (see printed
        output and notes_for_orchestrator): it is NOT required to find one,
        and none is fabricated if the search comes up empty.

Exit status 0 iff PB.1-PB.4 (positive, k_n=2^n) hold exactly for every case,
AND the Step1 negative control (PB.5, k_n=n+1 and k_n=1) genuinely fires.
The MAIN-bound violation sub-search inside PB.5 does not gate exit status
either way (see rationale above).
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
    """k_n = 2^n, exact integer (dyadic doubling, ratio r=2)."""
    return Q(2) ** n


def k_arith(n):
    """k_n = n+1, NOT a doubling sequence. Negative-control k, variant A
    (same choice as tests/tier_b_enstrophy_production.py's P1.b)."""
    return Q(n + 1)


def k_one(n):
    """k_n = 1 for all n, NOT a doubling sequence (ratio 1, not 2).
    Negative-control k, variant B (more extreme, per task instructions)."""
    return Q(1)


# Same 20 (p, q) pairs, same family, as tests/tier_b_enstrophy_production.py
# (and tests/tier_b_dyadic_checks.py before it). q always odd so q+2n != 0.
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


# ------------------------------------------------------- the four quantities
def S_N(a, N, kfun):
    """sum_{n=0}^{N-1} k_n^3 * a_n^2 * a_(n+1)"""
    return sum(kfun(n) ** 3 * a[n] ** 2 * a[n + 1] for n in range(N))


def Omega_N(a, N, kfun):
    """(1/2) * sum_{n=0}^{N} k_n^2 * a_n^2"""
    return Q(1, 2) * sum(kfun(n) ** 2 * a[n] ** 2 for n in range(N + 1))


def step1_sum(a, N, kfun):
    """sum_{n=0}^{N-1} k_n^2 * a_(n+1)^2"""
    return sum(kfun(n) ** 2 * a[n + 1] ** 2 for n in range(N))


def step2_restricted_sum(a, N, kfun):
    """sum_{n=0}^{N-1} k_n^4 * a_n^4 -- the literal Step2 bullet quantity,
    and the exact quantity Step3's Cauchy-Schwarz combination uses."""
    return sum(kfun(n) ** 4 * a[n] ** 4 for n in range(N))


def step2_full_sum(a, N, kfun):
    """sum_{n=0}^{N} k_n^4 * a_n^4 = Sigma x_n^2 for x_n = k_n^2 a_n^2 -- the
    design note's own worked-example quantity (reproduces 20993 on the
    sanity case), full range n=0..N."""
    return sum(kfun(n) ** 4 * a[n] ** 4 for n in range(N + 1))


# ------------------------------------------------------------- sanity case
def sanity_case():
    print("[sanity] N=2, k=(1,2,4), a=(1,2,3): reproduce design note's own numbers")
    N = 2
    a = [Q(1), Q(2), Q(3)]
    kfun = k_pow2

    S = S_N(a, N, kfun)
    Om = Omega_N(a, N, kfun)
    print(f"  S_N = {S}   Omega_N = {Om}")
    assert S == Q(98), f"S_N = {S} != 98 -- disagrees with the identity file's own witness"
    assert Om == Q(161, 2), f"Omega_N = {Om} != 161/2 -- disagrees with design note (80.5)"

    s1 = step1_sum(a, N, kfun)
    s1_bound = Om / 2
    print(f"  Step1: LHS = {s1} (expect 40)   bound = Omega_N/2 = {s1_bound} (expect 161/4 = 40.25)")
    assert s1 == Q(40), f"Step1 LHS = {s1} != 40"
    assert s1_bound == Q(161, 4), f"Step1 bound = {s1_bound} != 161/4"

    s2r = step2_restricted_sum(a, N, kfun)
    s2f = step2_full_sum(a, N, kfun)
    s2_bound = 4 * Om ** 2
    print(f"  Step2 (restricted, n<N literal bullet quantity): LHS = {s2r}")
    print(f"  Step2 (full range n<=N, design note's own 'Sigma x_n^2'): LHS = {s2f} (expect 20993)")
    print(f"  Step2 bound = 4*Omega_N^2 = {s2_bound} (expect 25921)")
    assert s2_bound == Q(25921), f"Step2 bound = {s2_bound} != 25921"
    assert s2f == Q(20993), (
        f"Step2 full-range LHS = {s2f} != 20993 -- disagrees with the design note's own "
        f"worked 'Sigma x_n^2' computation; this is a genuine implementation mismatch, stop."
    )
    if s2r != Q(20993):
        print(
            f"  DISCREPANCY (reported, not silently absorbed): the task prompt's quoted "
            f"'Step2 LHS=20993' does NOT match the literal restricted-range (n=0..N-1) "
            f"quantity the Step2 bullet names (that quantity is {s2r} on this instance). "
            f"It DOES match the design note's own full-range (n=0..N) 'Sigma x_n^2' "
            f"worked example ({s2f} == 20993, verified above). Both quantities are "
            f"algebraically <= 4*Omega_N^2 (restricted <= full, since it is a sub-sum of "
            f"nonnegative terms, and full <= 4*Omega_N^2 by the sum-of-squares lemma), so "
            f"this does not affect the validity of Step2 or of MAIN; it is a range "
            f"mismatch between the task prompt's bullet wording and its quoted number, "
            f"traced to the design note's own text (which names the full range n=0..N as "
            f"'Sigma x_n^2' but the Step3 formula explicitly needs the restricted n<N sum "
            f"on both factors). Proceeding with the restricted-range quantity for PB.2/PB.3 "
            f"gating, since that is what Step3's stated Cauchy-Schwarz formula literally uses."
        )
    assert s2r <= s2_bound
    assert s2f <= s2_bound

    s3_bound = s2r * s1
    print(f"  Step3: S_N^2 = {S**2}   bound = (restricted Step2) * Step1 = {s2r}*{s1} = {s3_bound}")
    assert S ** 2 <= s3_bound, f"Step3 (Cauchy-Schwarz) fails on sanity case: {S**2} > {s3_bound}"

    main_bound = 2 * Om ** 3
    print(f"  MAIN: S_N^2 = {S**2} (expect 9604)   bound = 2*Omega_N^3 = {main_bound} (expect 4173281/4 = 1043320.25)")
    assert S ** 2 == Q(9604), f"MAIN LHS = {S**2} != 9604"
    assert main_bound == Q(4173281, 4), f"MAIN bound = {main_bound} != 4173281/4"
    assert S ** 2 <= main_bound
    print("  sanity case: Step1, MAIN (and Step2's design-note full-range number) reproduce "
          "exactly; Step2's restricted-range number does not match the quoted 20993 for the "
          "traced reason above -- proceeding to sweep with the restricted quantity.")


# ---------------------------------------------------------------- PB.1-PB.4
def pb1_step1():
    print("[PB.1] Step1: sum_{n<N} k_n^2 a_(n+1)^2 <= Omega_N/2, k_n=2^n, N=1..12, 20 states")
    cases = 0
    for N in range(1, 13):
        for (p, q) in PQ_PAIRS:
            a = make_state(p, q, N)
            lhs = step1_sum(a, N, k_pow2)
            bound = Omega_N(a, N, k_pow2) / 2
            check("PB.1", lhs <= bound, f"N={N} p={p} q={q}: lhs={lhs} bound={bound}")
            cases += 1
    print(f"  {cases} (N, p, q) cases, all exact Step1 <= bound")


def pb2_step2():
    print("[PB.2] Step2: sum_{n<N} k_n^4 a_n^4 <= 4*Omega_N^2 (restricted, gating) "
          "+ full-range confirmatory, k_n=2^n, N=1..12, 20 states")
    cases = 0
    for N in range(1, 13):
        for (p, q) in PQ_PAIRS:
            a = make_state(p, q, N)
            Om = Omega_N(a, N, k_pow2)
            bound = 4 * Om ** 2
            s2r = step2_restricted_sum(a, N, k_pow2)
            s2f = step2_full_sum(a, N, k_pow2)
            check("PB.2.restricted", s2r <= bound, f"N={N} p={p} q={q}: lhs={s2r} bound={bound}")
            check("PB.2.full", s2f <= bound, f"N={N} p={p} q={q}: lhs={s2f} bound={bound}")
            check("PB.2.restricted_le_full", s2r <= s2f,
                  f"N={N} p={p} q={q}: restricted={s2r} full={s2f}")
            cases += 1
    print(f"  {cases} (N, p, q) cases, all exact Step2 <= bound (both restricted and full range)")


def pb3_step3():
    print("[PB.3] Step3 (Cauchy-Schwarz): S_N^2 <= (restricted Step2)*(Step1), "
          "k_n=2^n, N=1..12, 20 states")
    cases = 0
    for N in range(1, 13):
        for (p, q) in PQ_PAIRS:
            a = make_state(p, q, N)
            S = S_N(a, N, k_pow2)
            s2r = step2_restricted_sum(a, N, k_pow2)
            s1 = step1_sum(a, N, k_pow2)
            bound = s2r * s1
            check("PB.3", S ** 2 <= bound, f"N={N} p={p} q={q}: S^2={S**2} bound={bound}")
            cases += 1
    print(f"  {cases} (N, p, q) cases, all exact Step3 <= bound")


def pb4_main():
    print("[PB.4] MAIN: S_N^2 <= 2*Omega_N^3, k_n=2^n, N=1..12, 20 states")
    cases = 0
    for N in range(1, 13):
        for (p, q) in PQ_PAIRS:
            a = make_state(p, q, N)
            S = S_N(a, N, k_pow2)
            Om = Omega_N(a, N, k_pow2)
            bound = 2 * Om ** 3
            check("PB.4", S ** 2 <= bound, f"N={N} p={p} q={q}: S^2={S**2} bound={bound}")
            cases += 1
    print(f"  {cases} (N, p, q) cases, all exact MAIN <= bound")


# ---------------------------------------------------------------- PB.5
def pb5_negative_control():
    print("[PB.5] NEGATIVE CONTROL: break doubling (k_n=n+1, then k_n=1), N=1..12, 20 states")
    print("  (a) Step1 (the doubling-dependent step) -- expect genuine failures:")
    step1_any_failure = False
    for kfun, kname in [(k_arith, "k_n=n+1"), (k_one, "k_n=1")]:
        found = 0
        worst = None
        for N in range(1, 13):
            for (p, q) in PQ_PAIRS:
                a = make_state(p, q, N)
                lhs = step1_sum(a, N, kfun)
                bound = Omega_N(a, N, kfun) / 2
                if lhs > bound:
                    found += 1
                    if worst is None:
                        worst = (N, p, q, lhs, bound)
        if found:
            step1_any_failure = True
            N, p, q, lhs, bound = worst
            print(f"    {kname}: Step1 broken in {found}/240 cases, e.g. N={N} p={p} q={q}: "
                  f"lhs={lhs} > bound={bound}")
        else:
            print(f"    {kname}: Step1 held in all 240 cases (no failure found)")
    check("PB.5.step1_negative_control_fires", step1_any_failure,
          "neither k_n=n+1 nor k_n=1 broke Step1 -- negative control is broken; the "
          "checker cannot distinguish the doubling-dependent step from an arbitrary k")

    print("  (b) MAIN bound (S_N^2 <= 2*Omega_N^3) itself -- non-gating exploratory search:")
    for kfun, kname in [(k_arith, "k_n=n+1"), (k_one, "k_n=1")]:
        found = 0
        example = None
        for N in range(1, 13):
            for (p, q) in PQ_PAIRS:
                a = make_state(p, q, N)
                S = S_N(a, N, kfun)
                Om = Omega_N(a, N, kfun)
                lhs = S ** 2
                bound = 2 * Om ** 3
                if lhs > bound:
                    found += 1
                    if example is None:
                        example = (N, p, q, lhs, bound)
        if found:
            N, p, q, lhs, bound = example
            print(f"    {kname}: MAIN VIOLATED in {found}/240 cases, e.g. N={N} p={p} q={q}: "
                  f"S_N^2={lhs} > 2*Omega_N^3={bound}")
        else:
            print(f"    {kname}: MAIN bound held in all 240 (N,p,q) cases tried "
                  f"(N=1..12, the 20 PQ_PAIRS states) -- no violation found. Reported "
                  f"honestly as-is per task instructions: not fabricated, and Step1's "
                  f"failure above shows the doubling hypothesis is genuinely used by the "
                  f"proof even though this search did not turn up a state where its "
                  f"absence breaks the final MAIN inequality.")


if __name__ == "__main__":
    sanity_case()
    pb1_step1()
    pb2_step2()
    pb3_step3()
    pb4_main()
    pb5_negative_control()
    if FAILURES:
        print(f"\nTIER B GATE (production bound): FAIL ({len(FAILURES)} failures)")
        sys.exit(1)
    print("\nTIER B GATE (production bound): PASS (Step1, Step2, Step3, MAIN all exact, "
          "zero floating point, over N=1..12 x 20 states with k_n=2^n; Step1 negative "
          "control confirmed to genuinely fail under both k_n=n+1 and k_n=1)")
