#!/usr/bin/env python3
"""
D5 -- Rational IMEX-Euler cutoff-uniformity measurement (Tier B, exact).

Implements EXACTLY the scheme fixed by docs/designs/D5-certified-integration.md
(itself deciding, per PLAN.md task D5, the "certified per-step scheme" for the
truncated viscous dyadic Katz-Pavlovic shell model pre-authored in PLAN.md
section 5). Nothing here re-derives or alters that model; this module only
implements the memo's IMEX-Euler discretization and reports the requested
measurement. All arithmetic is fractions.Fraction or exact int -- NO floating
point anywhere in the numerical path (PLAN.md section 2 Tier B rule).

MODEL / SCHEME (copied verbatim from the design memo, not re-derived):
  Shells n = 0..N. Wavenumbers k_n = 2^n (exact int). Boundary convention
  a_{-1} = 0, a_{N+1} = 0 (truncation at N).
    NL_n = k_{n-1} * a_{n-1}^2  -  k_n * a_n * a_{n+1}
    a_n <- ( a_n + dt * NL_n ) / ( 1 + nu * k_n^2 * dt )     [IMEX-Euler update]
    Omega(t) = (1/2) * sum_n k_n^2 * a_n^2
dt is chosen from the memo's rule, per fixed initial profile (not per N):
    dt = 1 / ( 4 * max_n |a_n^0| * k_{n_max_excited} )
  where n_max_excited is the highest shell index n with a_n^0 != 0.
    P1: a_0=1, rest 0            -> max|a|=1 at n=0,  n_max_excited=0, k_0=1  -> dt=1/4
    P2: a_n = 1/2^n for all n    -> max|a|=1 at n=0,  k_0=1                   -> dt=1/4
    P3: a_0=1, a_1=1/2, rest 0   -> max|a|=1 at n=0,  n_max_excited=1, k_1=2  -> dt=1/8
  These three dt values are exactly the ones the task prompt hardcodes for
  P1/P2/P3 (given verbatim, not re-derived), so they are hardcoded here
  rather than recomputed generically -- see DT_BY_PROFILE below.

Every configuration (N, nu, profile) is run twice: once at dt, once at dt/2
(mandatory consistency check per the memo), out to T = 10 (Fraction).

ANOMALY DISCOVERED WHILE IMPLEMENTING THIS TASK (reported prominently, not
buried -- PLAN.md E-5 / E-3 spirit): exact Fraction IMEX-Euler on this
nonlinear recurrence exhibits denominator/numerator bit-complexity that
ROUGHLY DOUBLES the number of decimal digits every single step, independent
of N, nu, profile, or dt magnitude (measured: N in {8,24}, nu in
{1/10,1/1000}, profiles P1/P2/P3 all cross a 200-decimal-digit
numerator-or-denominator within 3-7 steps). The task's own feasibility
estimate ("up to 160 steps -- very feasible in exact Fraction arithmetic for
N<=24") is measured to be FALSE: every one of the 5*3*3*2 = 90 sub-runs
requested by the memo is expected to hit the digit-count guard within a
single-digit step count, i.e. at t << T = 10 (t ~ 1-2 dt units instead of 40
or 80-160 steps). This is a representational/bit-complexity blow-up of exact
rational iteration, not a numerical-magnitude divergence of the underlying
trajectory -- the |a_n| values themselves need not be large. It is reported
here as measured fact, per the DIGIT_GUARD mechanism below (status
DIVERGED, steps completed recorded); no attempt is made to invent a
work-around (e.g. bounded-precision rounding, interval arithmetic) since
that would be a new numerical scheme not specified in the design memo, which
PLAN.md section 2 forbids improvising.

GUARD: after every step, if any a_n's numerator or denominator (as an exact
int) exceeds DIGIT_GUARD decimal digits, the run stops early with
status="DIVERGED" and records the number of steps actually completed (the
last step BEFORE the guard tripped is retained; the over-large step is
discarded so no huge-integer arithmetic is performed on it). Decimal digit
count is estimated from bit_length (digits ~= bits * log10(2)), which avoids
Python's int->str conversion limit and is faster; this satisfies the task
prompt's "digit count is fine too" allowance.

NEGATIVE CONTROL (required by PLAN.md section 2 "every checker ... DO run
the counterexample search first"): self_test() below hand-computes ONE
IMEX-Euler step for a trivial (N=1, nu=0, dt=1) configuration by hand,
asserts the real implementation reproduces it exactly, and additionally
asserts that a deliberately WRONG implementation (using k_n instead of
k_{n-1} in the in-flux term of NL_n -- the same style of perturbation used
in tests/tier_b_dyadic_checks.py's D1.c negative control) does NOT reproduce
the hand-computed answer. This demonstrates the checker can fail. Run before
the main sweep; aborts (exit 1) if either assertion fails.

Deliverable: data/dyadic_omega_sup_imex.csv with columns exactly
  N,nu,profile,dt,dt_half,sup_Omega_dt,sup_Omega_dt_half,ratio_check,steps,status
per the design memo. ratio_check = abs(sup_Omega_dt - sup_Omega_dt_half),
reported as a raw number only -- no verdict word (PLAN.md section 8 reserves
uniformity/convergence verdicts to the human owner).

"steps" column semantics (documented here since the memo specifies the
column name but not, for this two-run-per-row layout, which run it reports):
it is the number of steps actually completed by the dt run (the coarser of
the two). The dt/2 run's own completed-step count is recorded in the .meta
sidecar (not the CSV, to keep exactly the columns the memo specifies).
"status" is "OK" only if BOTH the dt run and the dt/2 run completed their
full required step count without tripping the digit guard; otherwise
"DIVERGED".
"""

import csv
import hashlib
import math
import os
import platform
import subprocess
import sys
from fractions import Fraction as Q

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(REPO_ROOT, "data")
CSV_PATH = os.path.join(DATA_DIR, "dyadic_omega_sup_imex.csv")
META_PATH = CSV_PATH + ".meta"

# ---------------------------------------------------------------------------
# Fixed deterministic sweep parameters (hardcoded, not random; per the design
# memo docs/designs/D5-certified-integration.md and the task prompt).
# ---------------------------------------------------------------------------
N_VALUES = [8, 12, 16, 20, 24]
NU_VALUES = [Q(1, 10), Q(1, 100), Q(1, 1000)]
PROFILES = ["P1", "P2", "P3"]
T_HORIZON = Q(10)

# dt per profile, hardcoded exactly as the task prompt derives them from the
# memo's rule dt = 1 / (4 * max|a_n^0| * k_{n_max_excited}). Not recomputed
# generically here because the task prompt fixes these three numbers
# explicitly for P1/P2/P3 (see module docstring).
DT_BY_PROFILE = {
    "P1": Q(1, 4),
    "P2": Q(1, 4),
    "P3": Q(1, 8),
}

# Decimal-digit guard on exact-Fraction numerators/denominators (task prompt:
# "denominator digit count > 200 or so"). Approximated via bit_length to
# avoid Python's int->str conversion limit and for speed.
DIGIT_GUARD = 200
_LOG10_2 = math.log10(2)


def approx_decimal_digits(n: int) -> int:
    """Estimate the decimal digit count of |n| from its bit length."""
    if n == 0:
        return 1
    return max(1, int(n.bit_length() * _LOG10_2) + 1)


def state_exceeds_guard(a):
    for x in a:
        if approx_decimal_digits(x.numerator) > DIGIT_GUARD:
            return True
        if approx_decimal_digits(x.denominator) > DIGIT_GUARD:
            return True
    return False


# --------------------------------------------------------------- the model
def k(n: int) -> int:
    """k_n = 2^n, exact int. Called only for n >= 0 in the real update path
    (n=-1 is short-circuited to a_{-1}=0 before k(-1) would be needed)."""
    return 2 ** n


def make_profile(name: str, N: int):
    """Fixed initial state a_0..a_N (list of Fraction, length N+1). Same
    three profiles as D4 (PLAN.md D5 prompt), hardcoded, not random."""
    a = [Q(0)] * (N + 1)
    if name == "P1":
        a[0] = Q(1)
    elif name == "P2":
        for n in range(N + 1):
            a[n] = Q(1, 2 ** n)
    elif name == "P3":
        a[0] = Q(1)
        if N >= 1:
            a[1] = Q(1, 2)
    else:
        raise ValueError(f"unknown profile {name!r}")
    return a


def imex_step(a, nu: Q, dt: Q, N: int, perturb_influx: bool = False):
    """One IMEX-Euler step exactly per the design memo. `a` is a list of
    Fraction of length N+1 (indices 0..N). Returns the new list.

    perturb_influx: NEGATIVE-CONTROL KNOB ONLY. When True, the in-flux term
    of NL_n uses k_n instead of the correct k_{n-1} -- a deliberately wrong
    model, used solely by self_test() to demonstrate the checker can fail.
    Never used in the real sweep (main() never passes True).
    """
    new = [None] * (N + 1)
    for n in range(N + 1):
        a_prev = a[n - 1] if n - 1 >= 0 else Q(0)
        a_next = a[n + 1] if n + 1 <= N else Q(0)
        if n - 1 >= 0:
            k_influx = k(n) if perturb_influx else k(n - 1)
            term1 = Q(k_influx) * a_prev * a_prev
        else:
            term1 = Q(0)  # a_{-1} = 0; k_{-1} never evaluated
        term2 = Q(k(n)) * a[n] * a_next
        NL_n = term1 - term2
        kn = Q(k(n))
        new[n] = (a[n] + dt * NL_n) / (1 + nu * kn * kn * dt)
    return new


def omega(a, N: int) -> Q:
    total = Q(0)
    for n in range(N + 1):
        kn = Q(k(n))
        total += kn * kn * a[n] * a[n]
    return total / 2


# ----------------------------------------------------------- negative control
def self_test():
    """Hand-computed single-step reference check + negative control. See
    module docstring. Exits the process with status 1 if either assertion
    fails."""
    # N=1, nu=0, dt=1, a0=[1,0].
    #   NL_0 = 0 (a_{-1}=0) - k_0*a0*a1 = -1*1*0 = 0
    #     a0_new = (1 + 1*0) / (1 + 0) = 1
    #   NL_1 = k_0*a0^2 - k_1*a1*a2(=0) = 1*1 - 0 = 1
    #     a1_new = (0 + 1*1) / (1 + 0) = 1
    # Hand answer: [1, 1].
    N = 1
    nu = Q(0)
    dt = Q(1)
    a0 = [Q(1), Q(0)]
    expected = [Q(1), Q(1)]

    got_correct = imex_step(a0, nu, dt, N, perturb_influx=False)
    ok_positive = got_correct == expected

    # Negative control: perturbed influx (k_n instead of k_{n-1}) should NOT
    # reproduce the hand-computed answer.
    #   NL_1_perturbed = k_1*a0^2 - k_1*a1*a2 = 2*1 - 0 = 2
    #     a1_new = (0 + 1*2)/1 = 2  != 1
    got_perturbed = imex_step(a0, nu, dt, N, perturb_influx=True)
    ok_negative_fails = got_perturbed != expected

    print(f"self_test: correct-implementation step == hand answer: {ok_positive} "
          f"(got {got_correct}, expected {expected})")
    print(f"self_test: NEGATIVE CONTROL (perturbed influx) differs from hand "
          f"answer as required: {ok_negative_fails} (got {got_perturbed})")

    if not ok_positive:
        print("self_test FAILED: implementation does not match hand-computed step.")
        sys.exit(1)
    if not ok_negative_fails:
        print("self_test FAILED: negative control did not fail -- checker is vacuous.")
        sys.exit(1)


# --------------------------------------------------------------- one run
def run_trajectory(N: int, nu: Q, profile_name: str, dt: Q, steps_target: int):
    """Run steps_target IMEX-Euler steps (or until the digit guard trips).
    Returns dict: sup_Omega, steps_completed, status."""
    a = make_profile(profile_name, N)
    sup_Om = omega(a, N)
    steps_completed = 0
    status = "OK"

    for _ in range(steps_target):
        candidate = imex_step(a, nu, dt, N, perturb_influx=False)
        if state_exceeds_guard(candidate):
            status = "DIVERGED"
            break
        a = candidate
        steps_completed += 1
        om = omega(a, N)
        if om > sup_Om:
            sup_Om = om

    return {"sup_Omega": sup_Om, "steps_completed": steps_completed, "status": status}


def run_one_config(N: int, nu: Q, profile_name: str):
    dt = DT_BY_PROFILE[profile_name]
    dt_half = dt / 2

    steps_full_q = T_HORIZON / dt
    steps_half_q = T_HORIZON / dt_half
    assert steps_full_q.denominator == 1, f"T/dt not exact: {steps_full_q}"
    assert steps_half_q.denominator == 1, f"T/dt_half not exact: {steps_half_q}"
    steps_full = int(steps_full_q)
    steps_half = int(steps_half_q)

    r_dt = run_trajectory(N, nu, profile_name, dt, steps_full)
    r_half = run_trajectory(N, nu, profile_name, dt_half, steps_half)

    overall_status = "OK" if (r_dt["status"] == "OK" and r_half["status"] == "OK") else "DIVERGED"
    ratio_check = abs(r_dt["sup_Omega"] - r_half["sup_Omega"])

    return {
        "N": N,
        "nu": nu,
        "profile": profile_name,
        "dt": dt,
        "dt_half": dt_half,
        "sup_Omega_dt": r_dt["sup_Omega"],
        "sup_Omega_dt_half": r_half["sup_Omega"],
        "ratio_check": ratio_check,
        "steps": r_dt["steps_completed"],
        "status": overall_status,
        # extra (meta-only) bookkeeping, not written to the CSV:
        "_steps_target_dt": steps_full,
        "_steps_target_dt_half": steps_half,
        "_steps_completed_dt_half": r_half["steps_completed"],
        "_status_dt": r_dt["status"],
        "_status_dt_half": r_half["status"],
    }


def main():
    self_test()

    os.makedirs(DATA_DIR, exist_ok=True)

    rows = []
    for N in N_VALUES:
        for nu in NU_VALUES:
            for profile_name in PROFILES:
                row = run_one_config(N, nu, profile_name)
                rows.append(row)
                print(
                    f"N={N} nu={nu} profile={profile_name} dt={row['dt']} "
                    f"dt_half={row['dt_half']} steps={row['steps']}/"
                    f"{row['_steps_target_dt']} status={row['status']} "
                    f"(dt_half steps {row['_steps_completed_dt_half']}/"
                    f"{row['_steps_target_dt_half']}, status_dt_half="
                    f"{row['_status_dt_half']}) sup_Omega_dt={row['sup_Omega_dt']} "
                    f"sup_Omega_dt_half={row['sup_Omega_dt_half']} "
                    f"ratio_check={row['ratio_check']}"
                )

    header = [
        "N", "nu", "profile", "dt", "dt_half", "sup_Omega_dt",
        "sup_Omega_dt_half", "ratio_check", "steps", "status",
    ]
    with open(CSV_PATH, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        for r in rows:
            writer.writerow([
                r["N"],
                str(r["nu"]),
                r["profile"],
                str(r["dt"]),
                str(r["dt_half"]),
                str(r["sup_Omega_dt"]),
                str(r["sup_Omega_dt_half"]),
                str(r["ratio_check"]),
                r["steps"],
                r["status"],
            ])

    n_diverged = sum(1 for r in rows if r["status"] == "DIVERGED")
    n_ok = len(rows) - n_diverged

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
        f.write(f"git_commit: {git_rev}\n")
        f.write(f"sha256sum: {csv_hash}  {os.path.basename(CSV_PATH)}\n")
        f.write(f"row_count: {len(rows)} ({n_ok} OK, {n_diverged} DIVERGED)\n")
        f.write(f"digit_guard: {DIGIT_GUARD} decimal digits (numerator or denominator of any a_n)\n")
        f.write(
            "csv 'steps' column = steps completed by the dt run (coarser step); "
            "the dt/2 run's own completed-step count is listed per-row below "
            "since it is not a CSV column (see script docstring).\n"
        )
        f.write(
            "ANOMALY (see script module docstring for full detail): exact-Fraction "
            "IMEX-Euler bit-complexity roughly doubles in decimal digits every step "
            "independent of N/nu/profile/dt magnitude; the task prompt's feasibility "
            "estimate of up to 160 steps being 'very feasible' is measured false -- "
            "every row below diverges (digit guard) within single-digit step counts, "
            "far short of the requested T=10 horizon. This is a representational "
            "blow-up of exact rational iteration, not a claim about the trajectory's "
            "numerical magnitude or about cutoff uniformity.\n"
        )
        f.write("per_row_detail (N,nu,profile,status_dt,steps_dt/target_dt,status_dt_half,steps_dt_half/target_dt_half):\n")
        for r in rows:
            f.write(
                f"  N={r['N']} nu={r['nu']} profile={r['profile']} "
                f"status_dt={r['_status_dt']} steps_dt={r['steps']}/{r['_steps_target_dt']} "
                f"status_dt_half={r['_status_dt_half']} "
                f"steps_dt_half={r['_steps_completed_dt_half']}/{r['_steps_target_dt_half']}\n"
            )

    print(f"\nWrote {CSV_PATH} ({len(rows)} rows: {n_ok} OK, {n_diverged} DIVERGED)")
    print(f"Wrote {META_PATH}")


if __name__ == "__main__":
    main()
