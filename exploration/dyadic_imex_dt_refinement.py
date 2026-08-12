#!/usr/bin/env python3
# TIER C - EXPLORATORY, NO CLAIMS - NEVER GATES A CLAIM (SPEC bars floats from Tier B/A)
"""
dt-refinement study for the 20 low-nu configurations that DIVERGED in
exploration/dyadic_imex_dual_precision.py (data/dyadic_imex_dual_precision.csv).

WHY THIS SCRIPT EXISTS: docs/escalations/2026-08-12-D5-digit-blowup.md option 3 (demote D5 to
Tier C, stop certifying it in exact Q) was accepted by the human owner 2026-08-12, together
with a specific follow-up before drawing any conclusion about the low-nu divergences: the dual-
precision run's own dt (copied from symbolic/dyadic_imex.py's D5 design, chosen ONLY from the
initial profile's excited scale -- docs/designs/D5-certified-integration.md's formula
`dt = 1 / (4 * max|a_n^(0)| * k_{n_max_excited})` -- never re-tuned for nu) was flagged as a
plausible confound: fp64/mp50 agreeing to ~1e-14-1e-16 at the moment of divergence rules out
ROUNDING as the cause, but says nothing about whether dt was simply too coarse to RESOLVE the
trajectory once nu's weaker damping let the state amplitude grow past what the initial-data-only
dt formula assumed.

WHAT THIS SCRIPT DOES: for each of the 4 distinct (nu, profile) pairs that diverged (divergence
was empirically identical across all N in the original sweep -- itself evidence the phenomenon
is N-independent, i.e. NOT a cutoff artifact -- so N=24 is used as the primary case, with N=8
re-run at every refinement level as a cheap cross-check that N-independence persists under
refinement), the SAME IMEX-Euler scheme is re-run at dt, dt/2, dt/4, dt/8, dt/16 (fp64 only --
the dual-precision run already ruled out rounding as the cause, so a second precision buys
nothing new here) and the WALL-CLOCK TIME at which the magnitude guard trips is recorded, not
just the step count. This is the standard diagnostic for "numerical artifact vs genuine
blow-up": refining dt while the divergence TIME stays essentially fixed is evidence of a
genuine (dt-independent) phenomenon; a divergence time that keeps growing as dt shrinks (with
no sign of settling) is evidence dt was under-resolving the trajectory. NEITHER outcome is
interpreted further here -- consistent with this program's ledger discipline (PLAN.md section 8),
that judgment is reported as raw numbers for the human owner, not drawn by this script.

SCHEME, PROFILES: copied verbatim from exploration/dyadic_imex_dual_precision.py (itself copied
verbatim from symbolic/dyadic_imex.py) -- not re-derived. Only the dt LEVELS explored are new.

NEGATIVE CONTROL: identical self_test() to dyadic_imex_dual_precision.py -- hand-computed
single step at N=1, nu=0, dt=1, plus a perturbed-influx variant that must NOT match.

REPORTING DISCIPLINE (PLAN.md section 2 / section 8): this script makes no claim about whether
the divergence is genuine or an artifact. It reports divergence time and sup_Omega at each
refinement level, as numbers. The verdict is reserved to the human owner.
"""

import csv
import hashlib
import math
import os
import platform
import subprocess
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(REPO_ROOT, "data")
CSV_PATH = os.path.join(DATA_DIR, "dyadic_imex_dt_refinement.csv")
META_PATH = CSV_PATH + ".meta"

# ---------------------------------------------------------------------------
# The 4 distinct (nu, profile) pairs that DIVERGED in
# data/dyadic_imex_dual_precision.csv, identically across every N tested there.
# ---------------------------------------------------------------------------
DIVERGED_CONFIGS = [
    ("0.01", "P1"),
    ("0.001", "P1"),
    ("0.001", "P2"),
    ("0.001", "P3"),
]
N_PRIMARY = 24  # largest N in the original grid
N_CROSSCHECK = 8  # smallest N in the original grid, re-run at every level for N-independence

DT_BASE_BY_PROFILE = {  # base dt, copied verbatim from dyadic_imex_dual_precision.py
    "P1": 0.25,
    "P2": 0.25,
    "P3": 0.125,
}
REFINEMENT_DIVISORS = [1, 2, 4, 8, 16]
T_HORIZON = 10.0
MAG_GUARD = 1e15


# --------------------------------------------------------------- the model (float64, verbatim)
def k_f(n: int) -> float:
    return 2.0 ** n


def make_profile_f(name: str, N: int):
    a = [0.0] * (N + 1)
    if name == "P1":
        a[0] = 1.0
    elif name == "P2":
        for n in range(N + 1):
            a[n] = 1.0 / (2.0 ** n)
    elif name == "P3":
        a[0] = 1.0
        if N >= 1:
            a[1] = 0.5
    else:
        raise ValueError(f"unknown profile {name!r}")
    return a


def imex_step_f(a, nu: float, dt: float, N: int, perturb_influx: bool = False):
    new = [None] * (N + 1)
    for n in range(N + 1):
        a_prev = a[n - 1] if n - 1 >= 0 else 0.0
        a_next = a[n + 1] if n + 1 <= N else 0.0
        if n - 1 >= 0:
            k_influx = k_f(n) if perturb_influx else k_f(n - 1)
            term1 = k_influx * a_prev * a_prev
        else:
            term1 = 0.0
        term2 = k_f(n) * a[n] * a_next
        NL_n = term1 - term2
        kn = k_f(n)
        new[n] = (a[n] + dt * NL_n) / (1.0 + nu * kn * kn * dt)
    return new


def omega_f(a, N: int) -> float:
    total = 0.0
    for n in range(N + 1):
        kn = k_f(n)
        total += kn * kn * a[n] * a[n]
    return total / 2.0


def state_exceeds_guard_f(a):
    for x in a:
        if not math.isfinite(x):
            return True
        if abs(x) > MAG_GUARD:
            return True
    return False


# ----------------------------------------------------------- negative control (verbatim)
def self_test():
    N = 1
    nu_f, dt_f = 0.0, 1.0
    a0_f = [1.0, 0.0]
    expected_f = [1.0, 1.0]
    got_correct_f = imex_step_f(a0_f, nu_f, dt_f, N, perturb_influx=False)
    ok_pos_f = got_correct_f == expected_f
    got_perturbed_f = imex_step_f(a0_f, nu_f, dt_f, N, perturb_influx=True)
    ok_neg_f = got_perturbed_f != expected_f
    print(f"self_test: correct step == hand answer: {ok_pos_f} "
          f"(got {got_correct_f}, expected {expected_f})")
    print(f"self_test: NEGATIVE CONTROL (perturbed influx) differs as required: {ok_neg_f} "
          f"(got {got_perturbed_f})")
    if not (ok_pos_f and ok_neg_f):
        print("self_test FAILED.")
        sys.exit(1)


# --------------------------------------------------------------- one refined run
def run_refined(N: int, nu: float, profile_name: str, dt: float):
    """Runs until t=T_HORIZON or the magnitude guard trips. Returns dict with steps_completed,
    status, divergence_time (steps_completed * dt, meaningful only if status==DIVERGED), and
    sup_Omega reached before stopping."""
    a = make_profile_f(profile_name, N)
    sup_Om = omega_f(a, N)
    steps_target = int(round(T_HORIZON / dt))
    steps_completed = 0
    status = "OK"
    for _ in range(steps_target):
        candidate = imex_step_f(a, nu, dt, N, perturb_influx=False)
        if state_exceeds_guard_f(candidate):
            status = "DIVERGED"
            break
        a = candidate
        steps_completed += 1
        om = omega_f(a, N)
        if om > sup_Om:
            sup_Om = om
    return {
        "steps_completed": steps_completed,
        "steps_target": steps_target,
        "status": status,
        "divergence_time": steps_completed * dt,
        "sup_Omega": sup_Om,
    }


def main():
    self_test()
    os.makedirs(DATA_DIR, exist_ok=True)

    rows = []
    print()
    for nu_str, profile in DIVERGED_CONFIGS:
        nu = float(nu_str)
        dt_base = DT_BASE_BY_PROFILE[profile]
        print(f"-- nu={nu_str} profile={profile} (dt_base={dt_base}) --")
        for N in (N_PRIMARY, N_CROSSCHECK):
            for div in REFINEMENT_DIVISORS:
                dt = dt_base / div
                r = run_refined(N, nu, profile, dt)
                rows.append({
                    "N": N, "nu": nu_str, "profile": profile,
                    "dt_divisor": div, "dt": dt,
                    "steps_completed": r["steps_completed"], "steps_target": r["steps_target"],
                    "status": r["status"], "divergence_time": r["divergence_time"],
                    "sup_Omega": r["sup_Omega"],
                })
                tag = "N=24(primary)" if N == N_PRIMARY else "N=8(crosscheck)"
                print(f"   {tag} dt=dt0/{div:<2} ({dt:.6g}) status={r['status']:<8} "
                      f"steps={r['steps_completed']}/{r['steps_target']} "
                      f"divergence_time={r['divergence_time']!r} sup_Omega={r['sup_Omega']!r}")
        print()

    header = ["N", "nu", "profile", "dt_divisor", "dt", "steps_completed", "steps_target",
              "status", "divergence_time", "sup_Omega"]
    with open(CSV_PATH, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        for r in rows:
            writer.writerow([
                r["N"], r["nu"], r["profile"], r["dt_divisor"], repr(r["dt"]),
                r["steps_completed"], r["steps_target"], r["status"],
                repr(r["divergence_time"]), repr(r["sup_Omega"]),
            ])

    sha256 = hashlib.sha256()
    with open(CSV_PATH, "rb") as f:
        sha256.update(f.read())
    csv_hash = sha256.hexdigest()

    generating_command = "python3 " + os.path.relpath(os.path.abspath(__file__), REPO_ROOT)
    try:
        git_rev = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=REPO_ROOT, stderr=subprocess.DEVNULL
        ).decode().strip()
    except Exception:
        git_rev = "unknown (not a git repo or git unavailable)"

    n_diverged = sum(1 for r in rows if r["status"] == "DIVERGED")
    n_ok = len(rows) - n_diverged

    with open(META_PATH, "w") as f:
        f.write(f"generating_command: {generating_command}\n")
        f.write(f"python_version: {platform.python_version()} ({sys.version.splitlines()[0]})\n")
        f.write(f"git_commit: {git_rev}\n")
        f.write(f"sha256sum: {csv_hash}  {os.path.basename(CSV_PATH)}\n")
        f.write(f"row_count: {len(rows)} ({n_diverged} DIVERGED, {n_ok} OK)\n")
        f.write(f"magnitude_guard: |a_n| > {MAG_GUARD:g} or non-finite\n")
        f.write(
            "purpose: dt-refinement (divisors 1,2,4,8,16 of the original dyadic_imex_dual_"
            "precision.py dt) for the 4 distinct (nu,profile) pairs that DIVERGED there, at "
            "N=24 (primary) and N=8 (cross-check for N-independence). Reports divergence_time "
            "= steps_completed * dt (meaningful only when status==DIVERGED), not merely step "
            "count, since step count alone is not comparable across dt levels.\n"
        )
        f.write(
            "REPORTING DISCIPLINE: no verdict is drawn on whether divergence is genuine or a "
            "dt-resolution artifact. That judgment is reserved to the human owner (PLAN.md "
            "section 8) and should read divergence_time's trend as dt_divisor increases: "
            "roughly constant -> evidence of a genuine, dt-independent phenomenon; growing "
            "without an apparent limit -> evidence the original dt was under-resolving the "
            "trajectory.\n"
        )

    print(f"Wrote {CSV_PATH} ({len(rows)} rows: {n_diverged} DIVERGED, {n_ok} OK)")
    print(f"Wrote {META_PATH}")


if __name__ == "__main__":
    main()
