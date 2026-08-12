#!/usr/bin/env python3
# TIER C - EXPLORATORY, NO CLAIMS - NEVER GATES A CLAIM (SPEC bars floats from Tier B/A)
"""
Dual-precision (float64 vs mpmath 50-digit) IMEX-Euler steering run for the truncated
viscous dyadic Katz-Pavlovic shell model.

WHY THIS SCRIPT EXISTS: symbolic/dyadic_imex.py implements the SAME scheme in exact
fractions.Fraction (Tier B). It diverges by *digit explosion* (bit-length of numerators/
denominators roughly doubling every step) long before reaching the requested T=10 horizon --
see docs/escalations/2026-08-12-D5-digit-blowup.md. That is a representational blow-up of
exact rational iteration, not a magnitude blow-up of the trajectory. This script runs the
identical update rule in floating point (which has no representation-size problem) purely to
get steering data across the intended full grid, at two precisions, so a human can see whether
float64 and 50-digit mpmath agree. THIS PRODUCES NO CLAIM AND GATES NOTHING; SPEC.md bars
floating point from Tier B/A entirely. Nothing here re-derives the model -- the scheme, the
three initial profiles (P1/P2/P3), and their dt values are copied verbatim from
symbolic/dyadic_imex.py (read there for the design-memo provenance), not re-derived.

SCHEME (copied verbatim from symbolic/dyadic_imex.py's docstring, float instead of Fraction):
  Shells n = 0..N. Wavenumbers k_n = 2^n. Boundary a_{-1} = 0, a_{N+1} = 0 (truncation at N).
    NL_n = k_{n-1} * a_{n-1}^2  -  k_n * a_n * a_{n+1}
    a_n <- ( a_n + dt * NL_n ) / ( 1 + nu * k_n^2 * dt )     [IMEX-Euler update]
    Omega(t) = (1/2) * sum_n k_n^2 * a_n^2
Profiles and dt (copied verbatim from symbolic/dyadic_imex.py's DT_BY_PROFILE / make_profile):
    P1: a_0=1, rest 0            -> dt = 1/4  = 0.25
    P2: a_n = 1/2^n for all n    -> dt = 1/4  = 0.25
    P3: a_0=1, a_1=1/2, rest 0   -> dt = 1/8  = 0.125
T = 10.0 (float).

GRID: N in {8,12,16,20,24}, nu in {0.1,0.01,0.001}, profile in {P1,P2,P3} -> 45 configs.
Each config is run twice: once at plain Python float64, once with mpmath at mp.dps=50. Both
runs use the SAME dt (unlike D5's dt/dt-half consistency check -- that is not what this task
asks for; this task's cross-check is fp64-vs-mp50 at the SAME dt, see task prompt).

MAGNITUDE GUARD (both precisions): after every step, if any |a_n| > 1e15 or is NaN/inf, the
run stops early with status="DIVERGED" and the step count actually completed (before the
offending step) is retained. This is an ordinary numerical-magnitude guard, unlike D5's
digit-count guard -- floats have no representation-size blow-up problem, so no digit guard is
needed here, per the task prompt.

"steps" CSV column semantics (same convention as symbolic/dyadic_imex.py's "steps" column,
reused here for consistency): number of steps actually completed by the fp64 run (equal to
the full target step count T/dt when status_fp64=="OK"). The mp50 run's own completed-step
count is recorded per-row in the .meta sidecar (not the CSV) since both runs share one "steps"
column in the requested schema.

NEGATIVE CONTROL (PLAN.md section 2: "every checker must include a negative control you
demonstrate actually fails"): self_test() below hand-computes one IMEX-Euler step for a
trivial (N=1, nu=0, dt=1) configuration -- the identical hand-computation used in
symbolic/dyadic_imex.py's self_test() -- at both fp64 and mp50, and additionally checks that a
deliberately WRONG implementation (in-flux term uses k_n instead of k_{n-1}, same perturbation
style as symbolic/dyadic_imex.py) does NOT reproduce the hand-computed answer, at both
precisions. Run before the main sweep; aborts (exit 1) if any assertion fails.

SANITY CHECK (task-prompt-mandated, not a full negative control): for the single extra
configuration N=8, nu=1.0 (a large viscosity, NOT part of the main grid, added only for this
check), profile=P1, confirm at fp64 that energy E(t) = 0.5*sum_n a_n(t)^2 is non-increasing
step-to-step to within 1e-6 relative tolerance (E_new <= E_prev*(1+1e-6)). This mirrors D4's
own sanity check and is the numerical analogue of DyadicShells.lean's energyRate_nonpos
theorem. Result is reported as a plain boolean fact, no interpretation.

REPORTING DISCIPLINE (PLAN.md section 2 / section 8): this script and its output make NO
claim about whether sup_Omega is bounded, uniform in N, converges, or blows up. It reports
only the two sup_Omega values per configuration and their relative difference, as numbers.
Verdicts are reserved to the human owner.
"""

import csv
import hashlib
import math
import os
import platform
import subprocess
import sys

try:
    import mpmath
except ImportError:
    print("MISSING DEPENDENCY: mpmath is not installed. Per task instructions, not attempting "
          "to pip install anything. ESCALATING.", file=sys.stderr)
    sys.exit(2)

mpmath.mp.dps = 50

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(REPO_ROOT, "data")
CSV_PATH = os.path.join(DATA_DIR, "dyadic_imex_dual_precision.csv")
META_PATH = CSV_PATH + ".meta"

# ---------------------------------------------------------------------------
# Fixed deterministic sweep parameters (hardcoded, not random). Copied
# verbatim in spirit from symbolic/dyadic_imex.py's N_VALUES/NU_VALUES/
# PROFILES/DT_BY_PROFILE, but as this task's own explicit grid (task prompt
# adds nu=0.1 to the grid, which symbolic/dyadic_imex.py's own sweep did not
# include -- everything else matches).
# ---------------------------------------------------------------------------
N_VALUES = [8, 12, 16, 20, 24]
NU_VALUES_STR = ["0.1", "0.01", "0.001"]  # decimal strings -> exact mpf, nearest-float for fp64
PROFILES = ["P1", "P2", "P3"]
T_HORIZON = 10.0

DT_BY_PROFILE = {
    "P1": 0.25,
    "P2": 0.25,
    "P3": 0.125,
}

MAG_GUARD = 1e15


# --------------------------------------------------------------- the model (float64)
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


# --------------------------------------------------------------- the model (mpmath, 50 dps)
def k_m(n: int):
    return mpmath.mpf(2) ** n


def make_profile_m(name: str, N: int):
    a = [mpmath.mpf(0)] * (N + 1)
    if name == "P1":
        a[0] = mpmath.mpf(1)
    elif name == "P2":
        for n in range(N + 1):
            a[n] = mpmath.mpf(1) / (mpmath.mpf(2) ** n)
    elif name == "P3":
        a[0] = mpmath.mpf(1)
        if N >= 1:
            a[1] = mpmath.mpf("0.5")
    else:
        raise ValueError(f"unknown profile {name!r}")
    return a


def imex_step_m(a, nu, dt, N: int, perturb_influx: bool = False):
    new = [None] * (N + 1)
    for n in range(N + 1):
        a_prev = a[n - 1] if n - 1 >= 0 else mpmath.mpf(0)
        a_next = a[n + 1] if n + 1 <= N else mpmath.mpf(0)
        if n - 1 >= 0:
            k_influx = k_m(n) if perturb_influx else k_m(n - 1)
            term1 = k_influx * a_prev * a_prev
        else:
            term1 = mpmath.mpf(0)
        term2 = k_m(n) * a[n] * a_next
        NL_n = term1 - term2
        kn = k_m(n)
        new[n] = (a[n] + dt * NL_n) / (1 + nu * kn * kn * dt)
    return new


def omega_m(a, N: int):
    total = mpmath.mpf(0)
    for n in range(N + 1):
        kn = k_m(n)
        total += kn * kn * a[n] * a[n]
    return total / 2


def state_exceeds_guard_m(a):
    for x in a:
        if not mpmath.isfinite(x):
            return True
        if abs(x) > MAG_GUARD:
            return True
    return False


# ----------------------------------------------------------- negative control
def self_test():
    """Hand-computed single-step reference check + negative control, at both precisions.
    Identical hand-computation to symbolic/dyadic_imex.py's self_test(). Exits with status 1
    if any assertion fails."""
    # N=1, nu=0, dt=1, a0=[1,0].
    #   NL_0 = 0 (a_{-1}=0) - k_0*a0*a1 = -1*1*0 = 0  -> a0_new = (1+0)/(1+0) = 1
    #   NL_1 = k_0*a0^2 - k_1*a1*a2(=0) = 1*1 - 0 = 1 -> a1_new = (0+1)/(1+0) = 1
    # Hand answer: [1, 1].
    N = 1
    all_ok = True

    # --- float64 ---
    nu_f, dt_f = 0.0, 1.0
    a0_f = [1.0, 0.0]
    expected_f = [1.0, 1.0]
    got_correct_f = imex_step_f(a0_f, nu_f, dt_f, N, perturb_influx=False)
    ok_pos_f = got_correct_f == expected_f
    got_perturbed_f = imex_step_f(a0_f, nu_f, dt_f, N, perturb_influx=True)
    ok_neg_f = got_perturbed_f != expected_f
    print(f"self_test[fp64]: correct step == hand answer: {ok_pos_f} "
          f"(got {got_correct_f}, expected {expected_f})")
    print(f"self_test[fp64]: NEGATIVE CONTROL (perturbed influx) differs as required: "
          f"{ok_neg_f} (got {got_perturbed_f})")
    all_ok = all_ok and ok_pos_f and ok_neg_f

    # --- mpmath 50 dps ---
    nu_m, dt_m = mpmath.mpf(0), mpmath.mpf(1)
    a0_m = [mpmath.mpf(1), mpmath.mpf(0)]
    expected_m = [mpmath.mpf(1), mpmath.mpf(1)]
    got_correct_m = imex_step_m(a0_m, nu_m, dt_m, N, perturb_influx=False)
    ok_pos_m = got_correct_m == expected_m
    got_perturbed_m = imex_step_m(a0_m, nu_m, dt_m, N, perturb_influx=True)
    ok_neg_m = got_perturbed_m != expected_m
    print(f"self_test[mp50]: correct step == hand answer: {ok_pos_m} "
          f"(got {got_correct_m}, expected {expected_m})")
    print(f"self_test[mp50]: NEGATIVE CONTROL (perturbed influx) differs as required: "
          f"{ok_neg_m} (got {got_perturbed_m})")
    all_ok = all_ok and ok_pos_m and ok_neg_m

    if not all_ok:
        print("self_test FAILED.")
        sys.exit(1)


# --------------------------------------------------------------- sanity check (energy)
def sanity_check_energy_nonincreasing():
    """N=8, nu=1.0 (large viscosity, not in main grid), profile=P1, fp64. Confirms
    E(t) = 0.5*sum(a_n^2) is non-increasing step-to-step to within 1e-6 relative tolerance.
    Returns True/False (held or not) plus diagnostic info; does not interpret further."""
    N = 8
    nu = 1.0
    dt = DT_BY_PROFILE["P1"]
    steps_target = int(round(T_HORIZON / dt))
    a = make_profile_f("P1", N)

    def energy(state):
        return 0.5 * sum(x * x for x in state)

    e_prev = energy(a)
    held = True
    first_violation = None
    for step_idx in range(1, steps_target + 1):
        a = imex_step_f(a, nu, dt, N, perturb_influx=False)
        if state_exceeds_guard_f(a):
            break
        e_new = energy(a)
        if e_new > e_prev * (1.0 + 1e-6):
            held = False
            if first_violation is None:
                first_violation = (step_idx, e_prev, e_new)
        e_prev = e_new

    return held, first_violation, steps_target


# --------------------------------------------------------------- one run, one precision
def run_trajectory_f(N: int, nu: float, profile_name: str, dt: float, steps_target: int):
    a = make_profile_f(profile_name, N)
    sup_Om = omega_f(a, N)
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
    return {"sup_Omega": sup_Om, "steps_completed": steps_completed, "status": status}


def run_trajectory_m(N: int, nu, profile_name: str, dt, steps_target: int):
    a = make_profile_m(profile_name, N)
    sup_Om = omega_m(a, N)
    steps_completed = 0
    status = "OK"
    for _ in range(steps_target):
        candidate = imex_step_m(a, nu, dt, N, perturb_influx=False)
        if state_exceeds_guard_m(candidate):
            status = "DIVERGED"
            break
        a = candidate
        steps_completed += 1
        om = omega_m(a, N)
        if om > sup_Om:
            sup_Om = om
    return {"sup_Omega": sup_Om, "steps_completed": steps_completed, "status": status}


def main():
    self_test()

    sanity_held, sanity_violation, sanity_steps_target = sanity_check_energy_nonincreasing()
    print(f"\nSANITY CHECK (N=8, nu=1.0, P1, fp64, energy non-increasing to 1e-6 rel tol "
          f"over {sanity_steps_target} steps): held={sanity_held}"
          + ("" if sanity_held else f" first_violation(step,E_prev,E_new)={sanity_violation}"))

    os.makedirs(DATA_DIR, exist_ok=True)

    rows = []
    meta_lines = []
    for N in N_VALUES:
        for nu_str in NU_VALUES_STR:
            nu_f = float(nu_str)
            nu_m = mpmath.mpf(nu_str)
            for profile_name in PROFILES:
                dt_f = DT_BY_PROFILE[profile_name]
                dt_m = mpmath.mpf(str(dt_f))
                steps_target_q = T_HORIZON / dt_f
                steps_target = int(round(steps_target_q))
                assert abs(steps_target_q - steps_target) < 1e-9, \
                    f"T/dt not (numerically) exact: {steps_target_q}"

                r_f = run_trajectory_f(N, nu_f, profile_name, dt_f, steps_target)
                r_m = run_trajectory_m(N, nu_m, profile_name, dt_m, steps_target)

                sup_f = r_f["sup_Omega"]
                sup_m = r_m["sup_Omega"]
                sup_m_as_float = float(sup_m)
                denom = max(abs(sup_m_as_float), 1e-300)
                rel_diff = abs(sup_f - sup_m_as_float) / denom

                row = {
                    "N": N,
                    "nu": nu_str,
                    "profile": profile_name,
                    "dt": dt_f,
                    "steps": r_f["steps_completed"],
                    "status_fp64": r_f["status"],
                    "sup_Omega_fp64": sup_f,
                    "status_mp50": r_m["status"],
                    "sup_Omega_mp50": sup_m,
                    "rel_diff": rel_diff,
                }
                rows.append(row)
                print(
                    f"N={N} nu={nu_str} profile={profile_name} dt={dt_f} "
                    f"steps_fp64={r_f['steps_completed']}/{steps_target} status_fp64={r_f['status']} "
                    f"sup_Omega_fp64={sup_f!r} | "
                    f"steps_mp50={r_m['steps_completed']}/{steps_target} status_mp50={r_m['status']} "
                    f"sup_Omega_mp50={sup_m} | rel_diff={rel_diff!r}"
                )
                meta_lines.append(
                    f"  N={N} nu={nu_str} profile={profile_name} "
                    f"steps_fp64={r_f['steps_completed']}/{steps_target} status_fp64={r_f['status']} "
                    f"steps_mp50={r_m['steps_completed']}/{steps_target} status_mp50={r_m['status']} "
                    f"rel_diff={rel_diff!r}\n"
                )

    header = [
        "N", "nu", "profile", "dt", "steps", "status_fp64", "sup_Omega_fp64",
        "status_mp50", "sup_Omega_mp50", "rel_diff",
    ]
    with open(CSV_PATH, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        for r in rows:
            writer.writerow([
                r["N"],
                r["nu"],
                r["profile"],
                repr(r["dt"]),
                r["steps"],
                r["status_fp64"],
                repr(r["sup_Omega_fp64"]),
                r["status_mp50"],
                mpmath.nstr(r["sup_Omega_mp50"], 50),
                repr(r["rel_diff"]),
            ])

    n_diverged_f = sum(1 for r in rows if r["status_fp64"] == "DIVERGED")
    n_diverged_m = sum(1 for r in rows if r["status_mp50"] == "DIVERGED")

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

    with open(META_PATH, "w") as f:
        f.write(f"generating_command: {generating_command}\n")
        f.write(f"python_version: {platform.python_version()} ({sys.version.splitlines()[0]})\n")
        f.write(f"mpmath_version: {mpmath.__version__}\n")
        f.write(f"mpmath_mp_dps: {mpmath.mp.dps}\n")
        f.write(f"git_commit: {git_rev}\n")
        f.write(f"sha256sum: {csv_hash}  {os.path.basename(CSV_PATH)}\n")
        f.write(f"row_count: {len(rows)} ({n_diverged_f} DIVERGED at fp64, "
                 f"{n_diverged_m} DIVERGED at mp50)\n")
        f.write(f"magnitude_guard: |a_n| > {MAG_GUARD:g} or non-finite\n")
        f.write(
            "csv 'steps' column = steps completed by the fp64 run (equal to the target "
            "step count T/dt when status_fp64==OK); the mp50 run's own completed-step "
            "count is listed per-row below since both runs share one 'steps' column.\n"
        )
        f.write(
            f"SANITY CHECK (N=8, nu=1.0, P1, fp64, energy 0.5*sum(a_n^2) non-increasing "
            f"step-to-step to within 1e-6 relative tolerance, {sanity_steps_target} steps): "
            f"held={sanity_held}"
            + ("\n" if sanity_held else f" first_violation(step,E_prev,E_new)={sanity_violation}\n")
        )
        f.write("per_row_detail (N,nu,profile,steps_fp64/target,status_fp64,steps_mp50/target,status_mp50,rel_diff):\n")
        f.writelines(meta_lines)

    print(f"\nWrote {CSV_PATH} ({len(rows)} rows: {n_diverged_f} DIVERGED@fp64, "
          f"{n_diverged_m} DIVERGED@mp50)")
    print(f"Wrote {META_PATH}")


if __name__ == "__main__":
    main()
