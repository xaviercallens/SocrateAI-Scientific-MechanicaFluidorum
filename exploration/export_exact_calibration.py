# TIER C — EXPLORATORY, NO CLAIMS
"""Export the EXACT Tier B calibration trajectory for the floating-point scout.

The Deep Think adjudication of 2026-09-13 (D-2) authorises Tier C long-horizon runs "strictly
calibrated against the exact 8 initial rational steps". This script produces that calibration
target: the adversarial and null initial conditions at lambda = 1/20, and the eight exact
forward-Euler steps at dt = 1/64 from tests/tier_b_dynamic_access.py, with energy E, dissipation
D and the enstrophy production P at every step -- all as EXACT decimal strings (30 significant
digits computed by integer arithmetic; no float is formed here). The Rust scout parses them to
f64 and must reproduce the trajectory to round-off before any longer horizon is trusted.

Output: exploration/calibration/exact_steps_M2.json
"""
import json
import pathlib
import sys
from fractions import Fraction

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests"))

from tier_b_fourier_enstrophy import ball, k_sq, u_at, production, KSQ_WEIGHT  # noqa: E402
from tier_b_production_cancellation import make_family_state, phases_random, SEEDS  # noqa: E402
from tier_b_dynamic_access import (  # noqa: E402
    adversarial_ic, scale, euler_step, energy, dissipation, M, NU,
)

LAM = Fraction(1, 20)
DT = Fraction(1, 64)
STEPS = 8


def exact_decimal(fr: Fraction, digits: int = 30) -> str:
    """Decimal string of a Fraction with `digits` places after the point, by integer division."""
    sign = "-" if fr < 0 else ""
    fr = abs(fr)
    scaled = (fr.numerator * 10 ** digits) // fr.denominator
    ip, fp = divmod(scaled, 10 ** digits)
    return f"{sign}{ip}.{str(fp).zfill(digits)}"


def dump_state(u):
    return [[exact_decimal(c.re), exact_decimal(c.im)] for k in ball(M) for c in u_at(u, k)]


def trajectory(u0):
    u = u0
    rows = []
    for n in range(STEPS + 1):
        P = production(M, u, KSQ_WEIGHT)
        rows.append({
            "step": n,
            "t": exact_decimal(n * DT),
            "E": exact_decimal(energy(u)),
            "D": exact_decimal(dissipation(u)),
            "P_re": exact_decimal(P.re),
            "P_im": exact_decimal(P.im),
            "u": dump_state(u),
        })
        if n < STEPS:
            u, _ = euler_step(u, DT)
    return rows


def main():
    out = {
        "M": M,
        "nu": str(NU),
        "dt": str(DT),
        "lambda": str(LAM),
        "steps": STEPS,
        "ball": [list(k) for k in ball(M)],
        "note": "exact rationals rendered to 30 decimals by integer arithmetic; "
                "components listed in ball order, three per mode, [re, im]",
        "adversarial": trajectory(scale(adversarial_ic(), LAM)),
        "null": trajectory(scale(make_family_state(M, phases_random(M, SEEDS[0]), 0), LAM)),
    }
    dest = ROOT / "exploration" / "calibration"
    dest.mkdir(exist_ok=True)
    (dest / "exact_steps_M2.json").write_text(json.dumps(out))
    print(f"wrote {dest / 'exact_steps_M2.json'}: {len(out['ball'])} modes, "
          f"{STEPS + 1} states per IC")


if __name__ == "__main__":
    main()
