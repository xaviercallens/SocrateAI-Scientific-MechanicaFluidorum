#!/usr/bin/env python3
"""Tier B exact check: is a proposed dissipation degree alpha in a regime where the answer is
already a theorem?

WHY THIS EXISTS. On 2026-08-14 the programme discovered (escalation E-3) that its own model sits
at dissipation degree alpha = 1, inside the band where global regularity for the dyadic model is
a PUBLISHED THEOREM. Two numerical campaigns had been confirming a theorem. That is the same
failure as the grid defect found the same day -- an instrument pointed where no signal can exist
-- one level up: the grid gate catches "varied a parameter over a range where it cannot matter",
this gate catches "ran in a regime where the answer is forced".

THE THRESHOLDS (Cheskidov, arXiv:math/0601074; eq. (1.1) and abstract both retrieved and quoted
verbatim in docs/escalations/2026-08-14-E3-target-is-a-solved-case.md):

    d/dt u_n + nu*lambda^{2*alpha*n} u_n - lambda^n u_{n-1}^2 + lambda^{n+1} u_n u_{n+1} = g_n

    alpha <  1/3   ->  finite-time BLOW-UP is proven   (improves Katz-Pavlovic's alpha < 1/4)
    alpha >= 1/2   ->  GLOBAL REGULARITY is proven
    1/3 <= alpha < 1/2  ->  OPEN.  alpha = 1/3 is singled out in that paper as enjoying the same
                            estimates on the nonlinear term as the 4D Navier-Stokes equations.

This programme's dissipation nu*k_n^2 = nu*2^{2n} matches nu*lambda^{2*alpha*n} at lambda=2 with
2*alpha*n = 2*n, i.e. alpha = 1.

WHAT THIS GATE DOES. It classifies a proposed alpha into PROVEN_BLOWUP / OPEN / PROVEN_REGULAR
using exact rational comparison (Fraction, no floats), and reports whether an experiment in that
regime can produce new information:

  * OPEN            -> informative; the measurement can discover something.
  * PROVEN_REGULAR  -> NOT informative as a discovery, but LEGITIMATE and valuable as a POSITIVE
                       CONTROL (an instrument that has never registered a known-bounded case
                       cannot be believed when it reports boundedness).
  * PROVEN_BLOWUP   -> NOT informative as a discovery, but LEGITIMATE and valuable as a NEGATIVE
                       CONTROL (an instrument that cannot see a known blow-up is broken), AND it
                       is the only regime in which a proposed regularising mechanism -- such as
                       the Sym^2 lock -- can demonstrate anything, since it is the only regime
                       where the UNMODIFIED system fails.

So a proven regime is not forbidden. What is forbidden is running in one and reporting the
result as a discovery. This gate makes the classification explicit and mechanical so that the
distinction cannot be lost between a run and its write-up.

NEGATIVE CONTROL (PLAN.md: "a checker that cannot fail is not a checker"). The programme's own
alpha = 1 must be classified PROVEN_REGULAR, i.e. rejected as a source of discovery. That is a
control on the repository's real history, not a synthetic one. A positive control (alpha = 2/5,
inside the open band) must be accepted as informative.

Exact arithmetic: fractions.Fraction only. Deterministic.
"""

import sys
from fractions import Fraction as Q

BLOWUP_BELOW = Q(1, 3)   # alpha < 1/3  : blow-up proven
REGULAR_FROM = Q(1, 2)   # alpha >= 1/2 : regularity proven


def classify(alpha: Q) -> str:
    if alpha <= 0:
        raise ValueError("dissipation degree must be positive")
    if alpha < BLOWUP_BELOW:
        return "PROVEN_BLOWUP"
    if alpha >= REGULAR_FROM:
        return "PROVEN_REGULAR"
    return "OPEN"


def can_discover(alpha: Q) -> bool:
    """True only in the open band: the only regime where a measurement can find something new."""
    return classify(alpha) == "OPEN"


def legitimate_role(alpha: Q) -> str:
    return {
        "OPEN": "discovery (the answer is not known)",
        "PROVEN_REGULAR": "POSITIVE control only (must read as bounded)",
        "PROVEN_BLOWUP": "NEGATIVE control, and the only regime where a regularising "
                         "mechanism can demonstrate anything",
    }[classify(alpha)]


def report(alpha: Q, label: str):
    c = classify(alpha)
    print(f"  alpha = {str(alpha):<6} [{label}]")
    print(f"      classification : {c}")
    print(f"      can discover   : {can_discover(alpha)}")
    print(f"      legitimate use : {legitimate_role(alpha)}")
    return c


def main():
    print("== Tier B: dissipation-regime adequacy (exact rational thresholds) ==")
    print(f"   blow-up proven for alpha < {BLOWUP_BELOW};  regularity proven for alpha >= {REGULAR_FROM}")
    print(f"   open band: [{BLOWUP_BELOW}, {REGULAR_FROM})\n")

    # --- hand-checkable anchors on the exact boundaries ---
    assert classify(Q(1, 4)) == "PROVEN_BLOWUP", "anchor: 1/4 < 1/3 is proven blow-up"
    assert classify(Q(1, 3)) == "OPEN", "anchor: 1/3 is the lower endpoint of the open band"
    assert classify(Q(2, 5)) == "OPEN", "anchor: 2/5 is interior to the open band"
    assert classify(Q(1, 2)) == "PROVEN_REGULAR", "anchor: 1/2 is proven regular (closed below)"
    assert classify(Q(1)) == "PROVEN_REGULAR", "anchor: 1 is proven regular"
    print("  boundary anchors (1/4, 1/3, 2/5, 1/2, 1): PASS\n")

    print("NEGATIVE CONTROL — this programme's own dissipation degree:")
    c = report(Q(1), "nu*k_n^2 = nu*2^{2n}, i.e. alpha = 1")
    if can_discover(Q(1)):
        print("\n  NEGATIVE CONTROL FAILED: alpha=1 was accepted as a discovery regime, but "
              "regularity there is a published theorem. The checker cannot fail.")
        sys.exit(1)
    print("      -> correctly refused as a source of discovery (E-3).\n")

    print("POSITIVE CONTROL — a regime where the question is genuinely open:")
    report(Q(2, 5), "interior of the open band")
    if not can_discover(Q(2, 5)):
        print("\n  POSITIVE CONTROL FAILED: an open-band regime was refused. The checker "
              "refuses everything and is useless.")
        sys.exit(1)
    print("      -> accepted as informative.\n")

    print("For reference, the regime the Sym^2 lock experiment needs (OP-2-lite):")
    report(Q(1, 4), "below the blow-up threshold")
    print("      -> not a discovery regime, but the ONLY one where the lock can show anything,\n"
          "         since it is the only one where the unmodified system fails.\n")

    print("TIER B GATE (regime adequacy): PASS (exact rational thresholds; the programme's own "
          "alpha=1 is demonstrably refused as a discovery regime and an open-band alpha is "
          "demonstrably accepted; boundary anchors hold)")


if __name__ == "__main__":
    main()
