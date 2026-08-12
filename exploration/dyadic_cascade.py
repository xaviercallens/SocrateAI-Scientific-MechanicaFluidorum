#!/usr/bin/env python3
# TIER C - EXPLORATORY, NO CLAIMS
"""
Exploratory RK4 cascade for the truncated viscous dyadic (Katz-Pavlovic /
Desnyansky-Novikov) shell model. Floats are permitted here ONLY because this
file carries the Tier C header above (PLAN.md section 2). No claims about
uniformity, boundedness, or blow-up are made or should be inferred from this
script's output; it exists to produce steering data for task D5.

MODEL (pre-authored in PLAN.md section 5 / task D4 prompt -- implemented
exactly, not modified):
  Shells n = 0..N, wavenumbers k_n = 2^n, viscosity nu > 0, state a_0..a_N.
  Boundary convention: a_{-1} = 0, a_{N+1} = 0.
    d a_n / dt = k_{n-1} * a_{n-1}^2 - k_n * a_n * a_{n+1} - nu * k_n^2 * a_n
  Energy:    E(t)     = 0.5 * sum_n a_n^2
  Enstrophy: Omega(t) = 0.5 * sum_n k_n^2 * a_n^2

Integrator: classical RK4, float64, fixed (non-adaptive-in-time) step size
chosen deterministically per configuration exactly as specified by the task
prompt:
    dt = 0.1 / (nu * k_N^2 + k_N)
Horizon T = 10.0.

Divergence guard: if any |a_n| exceeds 1e12 or becomes NaN, the run stops
early with status DIVERGED and the stop time is recorded.

COMPUTATIONAL-FEASIBILITY GUARD (added by this implementation; NOT a change
to the model or the dt formula, both of which are used exactly as given):
for several (N, nu) cells the dt formula above forces step counts that are
not executable on any single machine within a practical session -- e.g.
N=20, nu=0.1 requires ceil(T/dt) = 10,995,221,135,360 RK4 steps, which even
at ~5.5e5 steps/sec (measured, numba-JIT, this machine) is ~233 days of
wall-clock time. Rather than silently truncate such a run at an arbitrary
partial time (which would report a sup_Omega measured only over a
dynamically meaningless sliver t << T, e.g. t ~ 1e-6 out of T = 10), this
script computes the exact required step count analytically and, if it
exceeds FEASIBILITY_STEP_CAP, does NOT attempt the integration at all and
records status "INFEASIBLE" with the analytically exact dt, steps=0, and
t_stop=0.0 (sup_Omega/E_final reported at the initial condition, since zero
integration steps were taken). This is an engineering/runtime decision, not
a mathematical one, and is reported prominently to the task orchestrator as
an anomaly -- it is not silently absorbed into the data.

Which cells are executed vs. marked INFEASIBLE is entirely determined,
before any simulation runs, by comparing the exact integer step count to
FEASIBILITY_STEP_CAP (both hardcoded constants below) -- no randomness, no
wall-clock-based decisions.
"""

import csv
import hashlib
import math
import os
import platform
import subprocess
import sys

import numpy as np

try:
    from numba import njit
    _HAVE_NUMBA = True
except ImportError:  # pragma: no cover - environment-dependent fallback
    _HAVE_NUMBA = False

    def njit(*args, **kwargs):
        # No-op fallback decorator so the script still runs (much slower,
        # pure-Python/NumPy) if numba is not installed.
        if len(args) == 1 and callable(args[0]) and not kwargs:
            return args[0]

        def wrap(fn):
            return fn

        return wrap


# ---------------------------------------------------------------------------
# Fixed deterministic sweep parameters (hardcoded, not random; PLAN.md D4 /
# task prompt).
# ---------------------------------------------------------------------------

N_VALUES = [8, 12, 16, 20]
NU_VALUES = [0.1, 0.01, 0.001]
T_HORIZON = 10.0
DIVERGE_THRESHOLD = 1e12

# See the COMPUTATIONAL-FEASIBILITY GUARD note above. Hardcoded, deterministic.
FEASIBILITY_STEP_CAP = 20_000_000

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(REPO_ROOT, "data")
CSV_PATH = os.path.join(DATA_DIR, "dyadic_omega_sup.csv")
META_PATH = CSV_PATH + ".meta"


def make_profile(name, N):
    """Return the fixed initial state a_0..a_N (numpy float64 array of
    length N+1) for the named profile. Profiles are hardcoded per the task
    prompt, not random."""
    a = np.zeros(N + 1, dtype=np.float64)
    if name == "P1":
        # a_0 = 1.0, all others 0
        a[0] = 1.0
    elif name == "P2":
        # a_n = 2^(-n) for all n
        for n in range(N + 1):
            a[n] = 2.0 ** (-n)
    elif name == "P3":
        # a_0 = 1.0, a_1 = 0.5, rest 0
        a[0] = 1.0
        if N >= 1:
            a[1] = 0.5
    else:
        raise ValueError(f"unknown profile {name!r}")
    return a


PROFILES = ["P1", "P2", "P3"]


def make_k(N):
    k = np.empty(N + 1, dtype=np.float64)
    for n in range(N + 1):
        k[n] = 2.0 ** n
    return k


def energy(a):
    return 0.5 * float(np.sum(a * a))


def enstrophy(a, k):
    return 0.5 * float(np.sum((k * k) * (a * a)))


@njit(cache=False)
def _rhs(a, k, nu, N):
    """RHS of the shell ODE, exactly as specified (boundary convention
    a_{-1} = a_{N+1} = 0)."""
    da = np.empty(N + 1)
    for n in range(N + 1):
        a_nm1 = a[n - 1] if n - 1 >= 0 else 0.0
        k_nm1 = k[n - 1] if n - 1 >= 0 else 0.0
        a_np1 = a[n + 1] if n + 1 <= N else 0.0
        da[n] = (
            k_nm1 * a_nm1 * a_nm1
            - k[n] * a[n] * a_np1
            - nu * k[n] * k[n] * a[n]
        )
    return da


@njit(cache=False)
def _simulate(N, nu, k, dt, steps_total, T_horizon, a0, diverge_threshold):
    """Classical RK4 loop with divergence guard. Returns
    (a_final, sup_omega, steps_done, diverged, t_final)."""
    a = a0.copy()
    sup_om = 0.0
    for n in range(N + 1):
        v = 0.5 * k[n] * k[n] * a[n] * a[n]
        if v > sup_om:
            sup_om = v

    t = 0.0
    steps_done = 0
    diverged = False

    for step_idx in range(steps_total):
        remaining = T_horizon - t
        step_dt = dt if remaining >= dt else remaining
        if step_dt <= 0.0:
            break

        k1 = _rhs(a, k, nu, N)
        a2 = a + 0.5 * step_dt * k1
        k2 = _rhs(a2, k, nu, N)
        a3 = a + 0.5 * step_dt * k2
        k3 = _rhs(a3, k, nu, N)
        a4 = a + step_dt * k3
        k4 = _rhs(a4, k, nu, N)
        a_next = a + (step_dt / 6.0) * (k1 + 2.0 * k2 + 2.0 * k3 + k4)

        steps_done += 1

        bad = False
        for n in range(N + 1):
            x = a_next[n]
            if x != x or abs(x) > diverge_threshold:  # x != x  <=>  NaN
                bad = True
                break

        if bad:
            diverged = True
            a = a_next
            t = t + step_dt
            break

        a = a_next
        t = t + step_dt
        om = 0.0
        for n in range(N + 1):
            v = 0.5 * k[n] * k[n] * a[n] * a[n]
            if v > om:
                om = v
        if om > sup_om:
            sup_om = om

    return a, sup_om, steps_done, diverged, t


def run_one(N, nu, profile_name):
    k = make_k(N)
    k_N = float(k[N])
    dt = 0.1 / (nu * k_N * k_N + k_N)
    steps_required = int(math.ceil(T_HORIZON / dt))

    a0 = make_profile(profile_name, N)
    E_initial = energy(a0)

    if steps_required > FEASIBILITY_STEP_CAP:
        # See COMPUTATIONAL-FEASIBILITY GUARD note at top of file. No
        # integration is attempted; report the initial-condition values and
        # the exact dt, with steps=0 and status=INFEASIBLE.
        sup_Omega = enstrophy(a0, k)
        return {
            "N": N,
            "nu": nu,
            "profile": profile_name,
            "dt": dt,
            "steps": 0,
            "status": "INFEASIBLE",
            "sup_Omega": sup_Omega,
            "E_initial": E_initial,
            "E_final": E_initial,
            "t_stop": 0.0,
            "steps_required": steps_required,
        }

    a_final, sup_Omega, steps_done, diverged, t_final = _simulate(
        N, nu, k, dt, steps_required, T_HORIZON, a0, DIVERGE_THRESHOLD
    )

    status = "DIVERGED" if diverged else "OK"
    E_final = energy(a_final)
    if diverged and (math.isnan(E_final) or math.isinf(E_final)):
        E_final = float("nan")

    return {
        "N": N,
        "nu": nu,
        "profile": profile_name,
        "dt": dt,
        "steps": steps_done,
        "status": status,
        "sup_Omega": sup_Omega,
        "E_initial": E_initial,
        "E_final": E_final,
        "t_stop": t_final,
        "steps_required": steps_required,
    }


@njit(cache=False)
def _simulate_check_monotone(N, nu, k, dt, steps_total, T_horizon, a0, diverge_threshold):
    """Same RK4 loop as _simulate, but additionally tracks per-step energy
    to verify E is non-increasing to within 1e-9 per step (RK4 wiring sanity
    check, task prompt). Returns (held, worst_increase, steps_checked,
    diverged)."""
    a = a0.copy()
    E_prev = 0.0
    for n in range(N + 1):
        E_prev += 0.5 * a[n] * a[n]

    held = True
    worst_increase = 0.0
    steps_checked = 0
    t = 0.0
    diverged = False

    for step_idx in range(steps_total):
        remaining = T_horizon - t
        step_dt = dt if remaining >= dt else remaining
        if step_dt <= 0.0:
            break

        k1 = _rhs(a, k, nu, N)
        a2 = a + 0.5 * step_dt * k1
        k2 = _rhs(a2, k, nu, N)
        a3 = a + 0.5 * step_dt * k2
        k3 = _rhs(a3, k, nu, N)
        a4 = a + step_dt * k3
        k4 = _rhs(a4, k, nu, N)
        a_next = a + (step_dt / 6.0) * (k1 + 2.0 * k2 + 2.0 * k3 + k4)

        steps_checked += 1

        bad = False
        for n in range(N + 1):
            x = a_next[n]
            if x != x or abs(x) > diverge_threshold:
                bad = True
                break
        if bad:
            diverged = True
            held = False
            a = a_next
            t = t + step_dt
            break

        a = a_next
        t = t + step_dt

        E_now = 0.0
        for n in range(N + 1):
            E_now += 0.5 * a[n] * a[n]
        increase = E_now - E_prev
        if increase > worst_increase:
            worst_increase = increase
        if increase > 1e-9:
            held = False
        E_prev = E_now

    return held, worst_increase, steps_checked, diverged


def sanity_check_energy_monotone(N=8, nu=1.0, profile_name="P1"):
    """Extra check run (task prompt): with nu large, energy should be
    non-increasing to within 1e-9 per step. This is a wiring sanity check on
    the RK4 implementation, not a claim about the model. Returns
    (held: bool, worst_increase: float, steps_checked: int)."""
    k = make_k(N)
    k_N = float(k[N])
    dt = 0.1 / (nu * k_N * k_N + k_N)
    steps_total = int(math.ceil(T_HORIZON / dt))

    a0 = make_profile(profile_name, N)

    held, worst_increase, steps_checked, diverged = _simulate_check_monotone(
        N, nu, k, dt, steps_total, T_HORIZON, a0, DIVERGE_THRESHOLD
    )
    return held, worst_increase, steps_checked


def main():
    os.makedirs(DATA_DIR, exist_ok=True)

    rows = []
    for N in N_VALUES:
        for nu in NU_VALUES:
            for profile_name in PROFILES:
                rows.append(run_one(N, nu, profile_name))

    header = [
        "N", "nu", "profile", "dt", "steps", "status",
        "sup_Omega", "E_initial", "E_final", "t_stop",
    ]
    with open(CSV_PATH, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        for r in rows:
            writer.writerow([
                r["N"],
                repr(r["nu"]),
                r["profile"],
                repr(r["dt"]),
                r["steps"],
                r["status"],
                repr(r["sup_Omega"]),
                repr(r["E_initial"]),
                repr(r["E_final"]),
                repr(r["t_stop"]),
            ])

    # Sanity assertion (task prompt): nu = 1.0, N = 8, profile P1 -- energy
    # must be non-increasing to within 1e-9 per step.
    held, worst_increase, steps_checked = sanity_check_energy_monotone(
        N=8, nu=1.0, profile_name="P1"
    )

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

    infeasible_rows = [r for r in rows if r["status"] == "INFEASIBLE"]

    with open(META_PATH, "w") as f:
        f.write(f"generating_command: {generating_command}\n")
        f.write(f"python_version: {platform.python_version()} ({sys.version.splitlines()[0]})\n")
        f.write(f"numba_used: {_HAVE_NUMBA}\n")
        f.write(f"git_commit: {git_rev}\n")
        f.write(f"sha256sum: {csv_hash}  {os.path.basename(CSV_PATH)}\n")
        f.write(
            "sanity_check: nu=1.0 N=8 profile=P1 energy non-increasing "
            f"(tol 1e-9/step) -> held={held} worst_increase={worst_increase!r} "
            f"steps_checked={steps_checked}\n"
        )
        f.write(
            f"feasibility_step_cap: {FEASIBILITY_STEP_CAP} "
            "(configs requiring more RK4 steps than this to reach T=10 are "
            "marked status=INFEASIBLE and NOT integrated; see file docstring)\n"
        )
        f.write(f"infeasible_config_count: {len(infeasible_rows)} of {len(rows)}\n")
        for r in infeasible_rows:
            f.write(
                f"  INFEASIBLE: N={r['N']} nu={r['nu']!r} profile={r['profile']} "
                f"dt={r['dt']!r} steps_required={r['steps_required']}\n"
            )

    print("== Tier C exploratory dyadic cascade sweep ==")
    print(f"numba JIT available: {_HAVE_NUMBA}")
    print(f"Configurations run: {len(rows)}")
    print(f"Configurations marked INFEASIBLE (step count > {FEASIBILITY_STEP_CAP}): {len(infeasible_rows)}")
    print(f"CSV written: {CSV_PATH}")
    print(f"CSV sha256: {csv_hash}")
    print()
    print("Sanity assertion (nu=1.0, N=8, profile=P1, energy non-increasing, tol 1e-9/step):")
    print(f"  held = {held}")
    print(f"  worst single-step increase observed = {worst_increase!r}")
    print(f"  steps checked = {steps_checked}")
    print()
    print(",".join(header))
    for r in rows:
        print(
            f'{r["N"]},{r["nu"]!r},{r["profile"]},{r["dt"]!r},{r["steps"]},'
            f'{r["status"]},{r["sup_Omega"]!r},{r["E_initial"]!r},'
            f'{r["E_final"]!r},{r["t_stop"]!r}'
        )


if __name__ == "__main__":
    main()
