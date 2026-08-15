#!/usr/bin/env python3
"""Tier B exact check: is a proposed dissipation degree alpha in a regime where the answer is
already a theorem?

WHY THIS EXISTS. On 2026-08-14 the programme discovered (escalation E-3) that its own model sits
at dissipation degree alpha = 1, inside the band where global regularity for the dyadic model is
a PUBLISHED THEOREM. Two numerical campaigns had been confirming a theorem. That is the same
failure as the grid defect found the same day -- an instrument pointed where no signal can exist
-- one level up: the grid gate catches "varied a parameter over a range where it cannot matter",
this gate catches "ran in a regime where the answer is forced".

CORRECTED 2026-08-15 (escalation E-3b). The thresholds below are NOT a single band: they
depend on the SIGN CLASS of the initial data, and the previous version of this file encoded a
band that was too wide. See docs/escalations/2026-08-15-E3b-band-is-narrower.md.

    d/dt u_n + nu*lambda^{2*alpha*n} u_n - lambda^n u_{n-1}^2 + lambda^{n+1} u_n u_{n+1} = g_n

POSITIVE initial data (u_n(0) >= 0):
    alpha <  1/3   ->  finite-time BLOW-UP proven, for LARGE data
                       (Cheskidov arXiv:math/0601074 Thm 5.3 - requires u_n(0) >= 0 AND
                        ||u(0)||_gamma > M(gamma); it is NOT "every solution blows up")
    alpha >= 2/5   ->  GLOBAL REGULARITY proven
                       (Barbato-Morandin-Romito, Nonlinearity 24 (2011) 3083-3097, Thm A:
                        beta in (2, 5/2] with beta = 1/alpha, i.e. alpha in [2/5, 1/2), for
                        x_n >= 0 in l^2 -- and with UNIQUENESS and smoothness, which Cheskidov's
                        theorem does not assert; above 1/2 Cheskidov Thm 4.4 covers it)
    [1/3, 2/5)     ->  OPEN

SIGN-CHANGING initial data:
    alpha >= 1/2   ->  GLOBAL REGULARITY proven (Cheskidov Thm 4.4; u_0 in V = H^alpha; no
                       positivity hypothesis; EXISTENCE of a strong global solution, uniqueness
                       NOT asserted)
    alpha <  1/2   ->  OPEN in both directions: BMR needs positivity, and so does the blow-up
                       theorem, so nothing is proven either way below 1/2 for sign-changing data.

Why this matters beyond bookkeeping: with the intermittency dimension d = 5 - 2/alpha,
alpha = 2/5 is exactly d = 0, so the residual positive-data band [1/3, 2/5) sits at
d in [-1, 0) -- OUTSIDE the physically relevant range d in [0,3]. The survey by Cheskidov-Dai-
Friedlander (arXiv:2209.10203) states verbatim that BMR "settles that solutions to the dyadic
model corresponding to the 3D NSE are globally regular". A programme targeting [1/3, 2/5) must
say so plainly. The sign-changing band is where the genuinely open room is.

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

CONTROLS (PLAN.md: "a checker that cannot fail is not a checker"):
  * NEGATIVE: the programme's own alpha = 1 must be classified PROVEN_REGULAR in both sign
    classes -- a control on this repository's real history, not a synthetic one.
  * POSITIVE: alpha = 7/20 (inside [1/3, 2/5)) must be accepted as informative for positive
    data, or the checker refuses everything and is useless.
  * REGRESSION: alpha = 2/5 with POSITIVE data must classify PROVEN_REGULAR. This is the exact
    anchor the previous version of this file asserted was OPEN, and it was wrong. The control
    exists so the error cannot silently return.

Exact arithmetic: fractions.Fraction only. Deterministic.
"""

import sys
from fractions import Fraction as Q

BLOWUP_BELOW = Q(1, 3)        # positive data, large: blow-up proven below this (Cheskidov 5.3)
REGULAR_FROM_POS = Q(2, 5)    # positive data: regularity proven from here (BMR Thm A)
REGULAR_FROM_ANY = Q(1, 2)    # any sign: regularity proven from here (Cheskidov Thm 4.4)


def classify(alpha: Q, data: str = "positive") -> str:
    """Classify alpha. `data` is "positive" (u_n(0) >= 0) or "signed" (sign-changing allowed).

    The two classes have genuinely different literature: both the blow-up theorem and BMR's
    regularity theorem assume positivity, so for sign-changing data nothing is proven below 1/2
    in either direction."""
    if alpha <= 0:
        raise ValueError("dissipation degree must be positive")
    if data not in ("positive", "signed"):
        raise ValueError("data class must be 'positive' or 'signed'")
    if data == "signed":
        return "PROVEN_REGULAR" if alpha >= REGULAR_FROM_ANY else "OPEN"
    if alpha < BLOWUP_BELOW:
        return "PROVEN_BLOWUP"
    if alpha >= REGULAR_FROM_POS:
        return "PROVEN_REGULAR"
    return "OPEN"


def can_discover(alpha: Q, data: str = "positive") -> bool:
    """True only in the open band: the only regime where a measurement can find something new."""
    return classify(alpha, data) == "OPEN"


def legitimate_role(alpha: Q, data: str = "positive") -> str:
    return {
        "OPEN": "discovery (the answer is not known)",
        "PROVEN_REGULAR": "POSITIVE control only (must read as bounded)",
        "PROVEN_BLOWUP": "NEGATIVE control, and the only regime where a regularising "
                         "mechanism can demonstrate anything",
    }[classify(alpha, data)]


def report(alpha: Q, label: str, data: str = "positive"):
    c = classify(alpha, data)
    print(f"  alpha = {str(alpha):<6} [{label}]  data: {data}")
    print(f"      classification : {c}")
    print(f"      can discover   : {can_discover(alpha, data)}")
    print(f"      legitimate use : {legitimate_role(alpha, data)}")
    return c


def main():
    print("== Tier B: dissipation-regime adequacy (exact rational thresholds) ==")
    print(f"   POSITIVE data : blow-up < {BLOWUP_BELOW};  regular >= {REGULAR_FROM_POS} (BMR);"
          f"  open band [{BLOWUP_BELOW}, {REGULAR_FROM_POS})")
    print(f"   SIGNED   data : regular >= {REGULAR_FROM_ANY} (Cheskidov); nothing proven below,"
          f"  open band (0, {REGULAR_FROM_ANY})\n")

    # --- hand-checkable anchors on the exact boundaries ---
    assert classify(Q(1, 4)) == "PROVEN_BLOWUP", "anchor: 1/4 < 1/3 is proven blow-up (positive)"
    assert classify(Q(1, 3)) == "OPEN", "anchor: 1/3 is the lower endpoint of the open band"
    assert classify(Q(7, 20)) == "OPEN", "anchor: 7/20 is interior to [1/3, 2/5)"
    assert classify(Q(2, 5)) == "PROVEN_REGULAR", "anchor: 2/5 is proven regular by BMR (positive)"
    assert classify(Q(1, 2)) == "PROVEN_REGULAR", "anchor: 1/2 proven regular"
    assert classify(Q(1)) == "PROVEN_REGULAR", "anchor: 1 is proven regular"
    assert classify(Q(2, 5), "signed") == "OPEN", "anchor: 2/5 is OPEN for sign-changing data"
    assert classify(Q(1, 4), "signed") == "OPEN", "anchor: no blow-up theorem for signed data"
    assert classify(Q(1, 2), "signed") == "PROVEN_REGULAR", "anchor: Cheskidov covers 1/2, any sign"
    print("  boundary anchors (1/4, 1/3, 7/20, 2/5, 1/2, 1; both data classes): PASS\n")

    print("NEGATIVE CONTROL - this programme's own dissipation degree:")
    report(Q(1), "nu*k_n^2 = nu*2^{2n}, i.e. alpha = 1")
    if can_discover(Q(1)) or can_discover(Q(1), "signed"):
        print("\n  NEGATIVE CONTROL FAILED: alpha=1 accepted as a discovery regime, but "
              "regularity there is a published theorem. The checker cannot fail.")
        sys.exit(1)
    print("      -> correctly refused as a source of discovery (E-3).\n")

    print("POSITIVE CONTROL - a regime where the question is genuinely open:")
    report(Q(7, 20), "interior of the residual open band [1/3, 2/5)")
    if not can_discover(Q(7, 20)):
        print("\n  POSITIVE CONTROL FAILED: an open-band regime was refused. The checker "
              "refuses everything and is useless.")
        sys.exit(1)
    print("      -> accepted as informative.\n")

    print("REGRESSION CONTROL - the anchor this file previously got WRONG (E-3b):")
    c = report(Q(2, 5), "BMR's endpoint: beta = 5/2", "positive")
    if c != "PROVEN_REGULAR":
        print("\n  REGRESSION CONTROL FAILED: alpha=2/5 with positive data must be "
              "PROVEN_REGULAR (Barbato-Morandin-Romito 2011). The old, too-wide band is back.")
        sys.exit(1)
    print("      -> correctly refused; and note the SAME alpha is still OPEN for signed data:")
    report(Q(2, 5), "same alpha, sign-changing data", "signed")
    print()

    print("For reference, the regime a regularising-mechanism experiment needs:")
    report(Q(1, 4), "below the blow-up threshold, positive data")
    print("      -> not a discovery regime, but the ONLY one where such a mechanism can show\n"
          "         anything, since it is the only one where the unmodified system fails.\n")

    print("TIER B GATE (regime adequacy): PASS (exact rational thresholds, both data classes; "
          "alpha=1 demonstrably refused; an open-band alpha demonstrably accepted; the E-3b "
          "regression anchor alpha=2/5 demonstrably refused for positive data)")


if __name__ == "__main__":
    main()
