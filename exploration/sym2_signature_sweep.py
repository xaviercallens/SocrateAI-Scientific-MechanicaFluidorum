#!/usr/bin/env python3
# TIER C - EXPLORATORY, NO CLAIMS - NEVER GATES A CLAIM (SPEC bars floats from Tier B/A)
"""
Clean measurement of the Sym^2 signature S(t) across dissipation regimes.

WHAT QUESTION THIS ANSWERS. A single exploratory trajectory suggested S rises as blow-up
develops, which would mean blow-up requires BREAKING Sym^2 structure -- and hence that enforcing
the lock might prevent it. That reading survived a dt-refinement check and was still an
artifact: the underlying 3x3 fit was singular wherever the cascade had not yet populated the
higher shells (LL-14). With the conditioning guard in place, the question is reopened honestly:

    Does S(t) actually rise as blow-up develops, on more than one trajectory, and only where
    the fit is well-posed?

DESIGN, fixed before running (per the pre-registration discipline of docs/designs/OP2_LITE_CANDIDATES.md):

  * REGIMES. alpha in {1/4, 3/10} (blow-up PROVEN, Cheskidov alpha<1/3), {2/5} (OPEN band),
    {1} (regularity PROVEN, = Navier-Stokes dissipation). The two proven regimes bracket the
    open one and act as controls on the MEASUREMENT rather than on the detector.
  * PROFILES. P1 (a_0=1), P2 (a_n=2^-n), P3 (a_0=1, a_1=1/2) -- the programme's standing three.
  * ENSEMBLE. Each profile is run at 5 perturbed amplitudes (a_0 scaled by 1 +/- eps) so that a
    spread can be reported. This is a sensitivity spread, NOT a statistical error bar: the
    dynamics are deterministic and the spread measures how much the answer depends on where you
    start, which is the relevant uncertainty here.
  * CONDITIONING. Every S value passes the COND_MIN guard; windows below it are dropped and the
    count of surviving windows is reported. A point with no surviving window is reported as
    NOT MEASURABLE, never as a small number.
  * BINNING. S is reported in two bins defined by ENSTROPHY GROWTH, not by time, so that
    regimes with different blow-up times are compared at comparable dynamical stages:
      "early"  : Omega <= 2 * Omega(0)
      "late"   : Omega >= 20 * Omega(0)   (or the last measurable point before the guard)
  * PRE-REGISTERED READING. The hypothesis under test is S(late) > S(early). It is supported
    only if that holds across BOTH blow-up regimes and BOTH exceed the detector's generic range
    lower edge; a rise seen in one regime only, or one that stays inside the generic band
    0.3-1.0 throughout, is reported as no signal.

The detector, its two controls and the conditioning guard live in sym2_signature_detector.py and
are re-run here before any measurement is reported.

NO VERDICT is drawn. Verdicts are the human owner's (SPEC 8).
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sym2_signature_detector import profile_signature, run_controls, COND_MIN  # noqa: E402


def k(n):
    return 2.0 ** n


def make_profile(name, N, scale=1.0):
    a = [0.0] * (N + 1)
    if name == "P1":
        a[0] = 1.0 * scale
    elif name == "P2":
        for n in range(N + 1):
            a[n] = (2.0 ** -n) * scale
    elif name == "P3":
        a[0] = 1.0 * scale
        if N >= 1:
            a[1] = 0.5 * scale
    else:
        raise ValueError(name)
    return a


def step(a, nu, alpha, dt, N):
    new = [0.0] * (N + 1)
    for n in range(N + 1):
        ap = a[n - 1] if n >= 1 else 0.0
        an = a[n + 1] if n + 1 <= N else 0.0
        influx = k(n - 1) * ap * ap if n >= 1 else 0.0
        NL = influx - k(n) * a[n] * an
        new[n] = (a[n] + dt * NL) / (1.0 + nu * (k(n) ** (2 * alpha)) * dt)
    return new


def enstrophy(a, N):
    return 0.5 * sum(k(n) ** 2 * a[n] ** 2 for n in range(N + 1))


def run_one(profile, alpha, nu, N, dt, scale, tmax, guard=1e10):
    """Return (S_early, S_late, n_meas_early, n_meas_late, reached_guard)."""
    a = make_profile(profile, N, scale)
    Om0 = enstrophy(a, N)
    S_early = S_late = None
    n_early = n_late = 0
    reached = False
    steps = int(tmax / dt)
    for i in range(1, steps + 1):
        a = step(a, nu, alpha, dt, N)
        if max(abs(x) for x in a) > guard:
            reached = True
            break
        if i % 200:
            continue
        Om = enstrophy(a, N)
        S = profile_signature([x * x for x in a], (0, 1, 2))
        if not S:
            continue
        m = sum(S) / len(S)
        if Om <= 2 * Om0 and S_early is None:
            S_early, n_early = m, len(S)
        if Om >= 20 * Om0:
            S_late, n_late = m, len(S)      # keep updating: last measurable late point
    return S_early, S_late, n_early, n_late, reached


def main():
    print("== Sym^2 signature sweep across dissipation regimes (Tier C) ==\n")
    print(f"conditioning guard COND_MIN = {COND_MIN:g}; windows below it are dropped\n")

    if not run_controls(verbose=False):
        print("DETECTOR CONTROLS FAILED -- refusing to report any measurement.")
        sys.exit(1)
    print("detector controls (positive + negative): PASS\n")

    REGIMES = [(0.25, "blow-up PROVEN"), (0.30, "blow-up PROVEN"),
               (0.40, "OPEN band"), (1.00, "regularity PROVEN (= NSE dissipation)")]
    PROFILES = ["P1", "P2", "P3"]
    SCALES = [0.9, 0.95, 1.0, 1.05, 1.1]
    nu, N, dt, tmax = 1e-3, 18, 5e-5, 4.0

    print(f"{'alpha':>6} {'regime':<38} {'profile':>8} {'S_early':>22} {'S_late':>22} {'guard'}")
    summary = {}
    for alpha, label in REGIMES:
        for prof in PROFILES:
            es, ls, ne, nl, hit = [], [], 0, 0, 0
            for sc in SCALES:
                Se, Sl, a_ne, a_nl, r = run_one(prof, alpha, nu, N, dt, sc, tmax)
                if Se is not None:
                    es.append(Se); ne = max(ne, a_ne)
                if Sl is not None:
                    ls.append(Sl); nl = max(nl, a_nl)
                hit += int(r)
            def fmt(vals, nw):
                if not vals:
                    return "NOT MEASURABLE"
                lo, hi = min(vals), max(vals)
                return f"{sum(vals)/len(vals):.3f} [{lo:.3f},{hi:.3f}] w={nw}"
            print(f"{alpha:>6.2f} {label:<38} {prof:>8} {fmt(es,ne):>22} {fmt(ls,nl):>22}  {hit}/{len(SCALES)}")
            summary[(alpha, prof)] = (es, ls)
        print()

    print("PRE-REGISTERED READING (hypothesis: S_late > S_early in BOTH blow-up regimes):")
    verdictable = True
    for alpha in (0.25, 0.30):
        rises = []
        for prof in PROFILES:
            es, ls = summary[(alpha, prof)]
            if es and ls:
                rises.append(sum(ls)/len(ls) > sum(es)/len(es))
        if not rises:
            print(f"   alpha={alpha}: no profile yielded BOTH bins measurable -> cannot evaluate")
            verdictable = False
        else:
            print(f"   alpha={alpha}: S_late > S_early in {sum(rises)}/{len(rises)} measurable profiles")
    if not verdictable:
        print("\n   -> The pre-registered test CANNOT BE EVALUATED on this sweep. Reported as such,")
        print("      not as a weak positive. No verdict; that is the owner's (SPEC 8).")
    else:
        print("\n   -> Reported as raw counts. No verdict is drawn; that is the owner's (SPEC 8).")


if __name__ == "__main__":
    main()
