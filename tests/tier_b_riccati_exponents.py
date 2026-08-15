#!/usr/bin/env python3
"""TIER B — the exponent bookkeeping behind Cheskidov's alpha >= 1/2 regularity theorem, and
the exact point at which the method dies below 1/2. Fractions only; no floats.

WHY THIS EXISTS. docs/designs/ALPHA_HALF_FORMALISATION.md targets Cheskidov Thm 4.4 for Lean.
Its whole content is a chain of exponents, and the programme's rule is that a threshold taken
from the literature must be checkable, not remembered (LL-16). Everything below is verified
against the paper's own displayed formulas, quoted in the memo.

THE CHAIN (arXiv:math/0601074, section 4; all four items are IN the paper except rho and
theta_star, which are derived in the memo and checked here):

  bilinear estimate      |(B(u,u), Au)| <= c_b |Au|^p ||u||^q,  p = 1/a - 1,  q = 4 - 1/a
                         [paper, displayed after "When alpha in [1/3,1], Holder's inequality
                          implies"; stated there as sharp]

  Young absorption       possible iff p < 2  <=>  a > 1/3
                         [paper: "Now consider the case where alpha > 1/3"]

  post-Young exponent    ||u||^r with r = 2q/(2-p) = (8a-2)/(3a-1)
                         [paper displays exactly c||u||^{(8a-2)/(3a-1)} - this is the check
                          that the derivation below reproduces the source, not merely
                          something self-consistent]

  Riccati exponent       y' <= C y^s with y = ||u||^2 and s = r/2 = (4a-1)/(3a-1)

  blow-up rate           y(t) >= c (t*-t)^{-rho},  rho = 1/(s-1) = 3 - 1/a       [derived]

  contradiction          the energy inequality gives ||u||^2 = y in L^1_loc, so a blow-up is
                         excluded exactly when (t*-t)^{-rho} is NOT locally integrable,
                         i.e. iff rho >= 1  <=>  a >= 1/2.                        [derived]

THE POINT. The threshold 1/2 is not an artifact of technique: it is precisely where the
Riccati blow-up rate crosses the integrability threshold that the energy inequality can see.
Below 1/2 the rate is integrable and there is no contradiction -- which is why energy methods
cannot reach the band, and why Barbato-Morandin-Romito needed invariant regions instead.

Quantified barrier (derived, checked here): closing alpha < 1/2 by this route requires an a
priori bound ||u||^{theta} in L^1_loc with theta >= theta_star(a) = 2/rho(a) = 2/(3 - 1/a),
whereas the energy inequality supplies exactly theta = 2. theta_star(a) > 2 iff a < 1/2, and
the deficit is explicit: at a = 2/5 one would need theta = 4 and has 2.

CONTROLS (LL-12; this is an identity verifier, so the sweep is its own positive control, plus
three anchors read off the paper's own special cases):
  * ANCHORS: r(1/2) = 4, r(2/5) = 6, and p(1/3) = 2 - all three appear as displayed formulas
    in the paper (||u||^4, ||u||^6, and |Au|^2||u|| respectively), so they test the algebra
    against the source rather than against itself.
  * NEGATIVE: a perturbed rate exponent (rho = 3 - 1/a replaced by 3 - 2/a) must break the
    alpha >= 1/2 characterisation. A formula that cannot be broken is not being tested.
"""

import sys
from fractions import Fraction as Q


def p_exp(a: Q) -> Q:
    """Exponent of |Au| in the bilinear estimate."""
    return 1 / a - 1


def q_exp(a: Q) -> Q:
    """Exponent of ||u|| in the bilinear estimate."""
    return 4 - 1 / a


def absorbable(a: Q) -> bool:
    """Young absorption against -nu|Au|^2 is possible iff the |Au| exponent is < 2."""
    return p_exp(a) < 2


def r_exp(a: Q) -> Q:
    """Post-Young exponent of ||u||: r = 2q/(2-p)."""
    if not absorbable(a):
        raise ValueError("no Young absorption at this alpha")
    return 2 * q_exp(a) / (2 - p_exp(a))


def riccati_s(a: Q) -> Q:
    """y' <= C y^s for y = ||u||^2."""
    return r_exp(a) / 2


def rate_rho(a: Q) -> Q:
    """Blow-up rate exponent: y >= c (t*-t)^{-rho}, rho = 1/(s-1)."""
    s = riccati_s(a)
    if s <= 1:
        raise ValueError("no Riccati blow-up rate at this alpha")
    return 1 / (s - 1)


def excluded_by_energy(a: Q, rho=None) -> bool:
    """Blow-up excluded iff the rate is NOT locally integrable, i.e. rho >= 1."""
    return (rate_rho(a) if rho is None else rho(a)) >= 1


def theta_star(a: Q) -> Q:
    """A priori exponent needed: ||u||^theta in L^1_loc with theta >= 2/rho."""
    return 2 / rate_rho(a)


def main():
    print("== TIER B: Riccati exponent chain for the dyadic model (exact rationals) ==\n")
    ok = True

    print("ANCHORS against the paper's own displayed special cases:")
    checks = [
        ("r(1/2) = 4      (paper displays ||u||^4 for alpha >= 1/2)", r_exp(Q(1, 2)), Q(4)),
        ("r(2/5) = 6      (paper displays ||u||^6 for alpha = 2/5)", r_exp(Q(2, 5)), Q(6)),
        ("p(1/3) = 2      (paper displays |Au|^2||u|| at alpha = 1/3)", p_exp(Q(1, 3)), Q(2)),
        ("p(2/5) = 3/2    (paper displays |Au|^{3/2}||u||^{3/2})", p_exp(Q(2, 5)), Q(3, 2)),
        ("q(2/5) = 3/2    (same display)", q_exp(Q(2, 5)), Q(3, 2)),
    ]
    for label, got, want in checks:
        good = got == want
        ok &= good
        print(f"   {label:<52} got {str(got):>5}  {'OK' if good else '*** FAILED ***'}")

    print("\n   general form r(a) = (8a-2)/(3a-1), as displayed in the paper:")
    for a in (Q(1, 2), Q(2, 5), Q(1), Q(5, 12)):
        got, want = r_exp(a), (8 * a - 2) / (3 * a - 1)
        good = got == want
        ok &= good
        print(f"      a={str(a):>5}: derived {str(got):>7} vs source form {str(want):>7}"
              f"   {'OK' if good else '*** FAILED ***'}")

    print("\nYoung absorption possible iff alpha > 1/3:")
    for a, want in ((Q(1, 4), False), (Q(1, 3), False), (Q(7, 20), True), (Q(1, 2), True)):
        good = absorbable(a) == want
        ok &= good
        print(f"   a={str(a):>5}: absorbable={absorbable(a)!s:<5} expected {want!s:<5}"
              f"  {'OK' if good else '*** FAILED ***'}")

    print("\nThe threshold, derived: blow-up excluded by the energy inequality iff rho >= 1:")
    print(f"   {'alpha':>6} {'s':>7} {'rho':>7} {'excluded':>9} {'theta*':>8} {'energy gives':>13}")
    for a in (Q(7, 20), Q(2, 5), Q(9, 20), Q(1, 2), Q(3, 5), Q(1)):
        s, rho, th = riccati_s(a), rate_rho(a), theta_star(a)
        exc = excluded_by_energy(a)
        ok &= (exc == (a >= Q(1, 2)))
        print(f"   {str(a):>6} {str(s):>7} {str(rho):>7} {exc!s:>9} {str(th):>8} {'2':>13}")
    print("   -> 'excluded' flips exactly at alpha = 1/2, and theta* exceeds the energy")
    print("      inequality's exponent 2 exactly below it. This IS Cheskidov's threshold.")

    print("\nNEGATIVE CONTROL: perturb the rate exponent to rho = 3 - 2/a; the characterisation")
    print("   'excluded iff alpha >= 1/2' must then FAIL for some alpha:")
    bad = lambda a: 3 - 2 / a          # noqa: E731 - deliberate wrong formula
    broke = [a for a in (Q(7, 20), Q(2, 5), Q(1, 2), Q(3, 5), Q(1))
             if excluded_by_energy(a, rho=bad) != (a >= Q(1, 2))]
    print(f"   alphas where the perturbed formula disagrees: {[str(a) for a in broke]}")
    if not broke:
        print("   *** DEAD CONTROL: the perturbation changed nothing ***")
        ok = False
    else:
        print("   OK (control fires)")

    print("\nTIER B GATE (riccati exponents): PASS (exact rationals; the derived chain reproduces"
          " the paper's displayed exponents at 1/3, 2/5 and 1/2; the alpha>=1/2 characterisation"
          " is exact and a perturbed rate demonstrably breaks it)" if ok else
          "\n*** SOMETHING FAILED — see above ***")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
