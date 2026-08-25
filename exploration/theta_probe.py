#!/usr/bin/env python3
# TIER C - EXPLORATORY, NO CLAIMS - NEVER GATES A CLAIM (floats; SPEC bars them from Tier A/B)
"""
Does the alpha < 1/2 band have any room for a BETTER a priori bound? A cheap screen, run
BEFORE investing in the search -- the step the four dead Sym^2 mechanisms lacked.

THE QUESTION, made precise by lean_src/DyadicRiccati.lean (Tier A). Refuting finite-time
enstrophy blow-up by the Riccati route needs an a priori bound

    ||u||^theta  in  L^1_loc     with   theta >= theta*(alpha) = 2 / (3 - 1/alpha).

The energy inequality supplies exactly theta = 2. At alpha = 2/5 -- the case Cheskidov singles
out as carrying the SAME enstrophy estimate as 3D NSE, and which Barbato-Morandin-Romito closed
for POSITIVE data only -- theta*(2/5) = 4. So the whole question is: for SIGN-CHANGING data, is
there any sign that ||u||^4 might be locally integrable, or is theta = 2 the ceiling?

WHAT CAN AND CANNOT BE MEASURED. A finite truncation cannot blow up, so I_theta(T) = int_0^T
||u||^theta dt is finite at every N and proves nothing by itself. The signature of true
non-integrability is I_theta(T) GROWING WITHOUT SATURATING AS N INCREASES. So the observable is
I_theta(T) as a function of the truncation N, and the reported quantity is its growth ratio.
Reading a single N would be exactly the "N-flatness" grid artifact this programme already made
once.

CONTROLS -- three, each theorem-backed, all pre-registered (LL-12/LL-15):
  * POSITIVE #1 (regularity side): at alpha = 1, global regularity is a published theorem
    (Cheskidov Thm 4.4), so I_theta must SATURATE in N for every theta tested. If it diverges
    there, the instrument reports divergence where none exists and nothing it says is usable.
  * POSITIVE #2 (the sharpest one, at the very parameter of interest): at ANY alpha, theta = 2
    is controlled by the energy inequality itself. So I_2 must saturate in N even at alpha=2/5.
    An instrument that cannot see the one bound we KNOW holds cannot be trusted about theta=4.
  * NEGATIVE (blow-up side): at alpha = 1/4 with LARGE POSITIVE data, finite-time blow-up is
    proven (Cheskidov Thm 5.3 - positivity and largeness are both required hypotheses), so
    I_theta must FAIL to saturate for large theta. An instrument that never reports divergence
    is not a test.

The system (Cheskidov arXiv:math/0601074 eq. 3.1, truncated at N, g = 0, lambda = 2):
    du_n/dt = -nu 2^{2 alpha n} u_n + 2^n u_{n-1}^2 - 2^{n+1} u_n u_{n+1},  u_0 = u_{N+1} = 0.
The truncation conserves energy exactly in the nonlinearity (telescoping, both ends vanish) --
checked at runtime as a fourth, structural control.

Floats by necessity: this is many-step nonlinear iteration, where exact rationals blow up in
representation size (a recorded lesson of this programme, not a guess). Raw numbers only; no
verdict (SPEC 8) -- and in particular this screen can only ever say "no room visible", never
"a bound exists".
"""

import math
import sys

import numpy as np

LAM = 2.0
T_END = 2.0
GUARD = 1e12
MAX_STEPS = 400_000        # runaway backstop; a run that hits it is reported, not silently cut


def nonlinear(u, pw1, pw2):
    """N_n = 2^n u_{n-1}^2 - 2^{n+1} u_n u_{n+1}, with u_0 = u_{N+1} = 0. Vectorised."""
    prev = np.concatenate(([0.0], u[:-1]))
    nxt = np.concatenate((u[1:], [0.0]))
    return pw1 * prev * prev - pw2 * u * nxt


def enstrophy(u, w2a):
    return float(np.dot(w2a, u * u))


def nonlinear_energy_flux(u, pw1, pw2):
    """sum_n u_n N_n -- exactly 0 for the truncated system (telescoping, both ends vanish)."""
    return float(np.dot(u, nonlinear(u, pw1, pw2)))


def seed(N, amplitude, beta, signed):
    """u_n(0) = A (-1)^n 2^{-beta n}. NOTE beta > alpha is REQUIRED: ||u(0)||^2 =
    sum 2^{2 alpha n} u_n^2 = A^2 sum 2^{2(alpha-beta)n} converges iff beta > alpha. With
    beta <= alpha the initial data has INFINITE enstrophy in the limit, violating the
    theorems' hypothesis u_0 in V, and every run is then N-dependent by construction. This
    caught a broken positive control on 2026-08-15 - see the header."""
    n = np.arange(1, N + 1)
    v = amplitude * LAM ** (-beta * n)
    if signed:
        v = v * np.where(n % 2 == 0, -1.0, 1.0)
    return v


def run(alpha, nu, N, amplitude, beta, signed, thetas):
    """Integrating-factor RK2: the stiff linear part is solved exactly, so the step size is
    set by the NONLINEAR timescale (adaptively) rather than by nu*2^{2*alpha*N}."""
    n = np.arange(1, N + 1)
    w2a = LAM ** (2.0 * alpha * n)          # enstrophy weights
    L = -nu * w2a                            # linear (dissipative) rates
    pw1 = LAM ** n
    pw2 = LAM ** (n + 1)

    u = seed(N, amplitude, beta, signed)
    e0 = float(np.dot(u, u))
    acc = {th: 0.0 for th in thetas}
    series = [(0.0, dict(acc))]
    worst_flux = 0.0
    t = 0.0
    steps = 0
    while t < T_END and steps < MAX_STEPS:
        z = enstrophy(u, w2a)
        if not (z < GUARD) or not np.all(np.isfinite(u)):
            series.append((t, dict(acc)))
            return None, acc, worst_flux, t, series
        # adaptive step from the nonlinear rate
        rate = float(np.max(pw2 * np.abs(u))) + 1e-30
        dt = min(0.05 / rate, 1e-2, T_END - t)
        if dt <= 0:
            break
        nrm = math.sqrt(max(z, 0.0))
        for th in thetas:
            acc[th] += (nrm ** th) * dt
        f = nonlinear_energy_flux(u, pw1, pw2)
        worst_flux = max(worst_flux, abs(f) / (max(e0, 1e-30) * max(LAM ** N, 1.0)))
        E = np.exp(L * dt)
        k1 = nonlinear(u, pw1, pw2)
        u1 = E * (u + dt * k1)
        k2 = nonlinear(u1, pw1, pw2)
        u = E * u + 0.5 * dt * (E * k1 + k2)
        t += dt
        steps += 1
        if steps % 200 == 0:
            series.append((t, dict(acc)))
    series.append((t, dict(acc)))
    hit_cap = steps >= MAX_STEPS
    return (None if hit_cap else u), acc, worst_flux, t, series


def at_time(series, t_target):
    """Cumulative I_theta at the last sample with t <= t_target."""
    best = series[0][1]
    for t, acc in series:
        if t <= t_target:
            best = acc
        else:
            break
    return best


def sweep(label, alpha, nu, amplitude, beta, signed, thetas, Ns):
    print(f"\n--- {label} ---")
    print(f"    alpha={alpha}  nu={nu}  A={amplitude}  beta={beta}  "
          f"data={'SIGN-CHANGING' if signed else 'positive'}")
    if beta <= alpha:
        print(f"    *** REFUSING: beta={beta} <= alpha={alpha} means INFINITE-enstrophy initial")
        print("        data in the limit; the theorems' hypothesis u_0 in V is violated. ***")
        return None
    print(f"    theta* = {2/(3-1/alpha):.3g} needed here (energy inequality supplies 2)")

    runs = []
    for N in Ns:
        u, acc, flux, tfin, series = run(alpha, nu, N, amplitude, beta, signed, thetas)
        runs.append((N, u, acc, flux, tfin, series))
    t_common = min(r[4] for r in runs)
    print(f"    common window [0, {t_common:.4g}]  (per-N final times: "
          + ", ".join(f"N={r[0]}:{r[4]:.3g}" for r in runs) + ")")
    print("      N  " + "".join(f"{'I_'+str(th):>13}" for th in thetas) + "   flux_err  status")
    rows = []
    for N, u, acc, flux, tfin, series in runs:
        a = at_time(series, t_common)
        status = "ok" if u is not None else "STOPPED EARLY"
        print(f"    {N:>3}  " + "".join(f"{a[th]:>13.4g}" for th in thetas)
              + f"   {flux:.1e}  {status}")
        rows.append((N, a))
    print("      growth ratios over the COMMON window (-> 1 means saturating = bounded):")
    for th in thetas:
        rs = []
        for k in range(1, len(rows)):
            x, y = rows[k - 1][1][th], rows[k][1][th]
            rs.append(y / x if x > 0 else float("nan"))
        print(f"        theta={th}: " + "  ".join(f"{r:.3f}" for r in rs))
    tmin = min(r[4] for r in runs)
    tmax = max(r[4] for r in runs)
    if tmax > 0 and tmin / tmax < 0.5:
        print(f"      NOTE: final times shrink with N ({tmax:.3g} -> {tmin:.3g}) -- the")
        print("      signature of genuine blow-up in the limit, not of saturation.")
    return rows


def main():
    print("== theta probe: is there room for a better a priori bound below alpha=1/2? ==")
    print("   observable: I_theta(T) = int_0^T ||u||^theta dt, as a function of truncation N")
    print("   saturating in N  ->  plausibly bounded;  growing  ->  no such bound\n")
    Ns = (8, 11, 14, 17)
    thetas = (2, 3, 4)

    sweep("POSITIVE CONTROL 1 (alpha=1: regularity is a THEOREM, must saturate)",
          alpha=1.0, nu=0.05, amplitude=1.0, beta=1.2, signed=True, thetas=thetas, Ns=Ns)

    sweep("NEGATIVE CONTROL (alpha=1/4, LARGE POSITIVE data: blow-up is a THEOREM)",
          alpha=0.25, nu=0.002, amplitude=8.0, beta=0.30, signed=False, thetas=thetas, Ns=Ns)

    sweep("MEASUREMENT (alpha=2/5, sign-changing -- the open case)",
          alpha=0.4, nu=0.02, amplitude=2.0, beta=0.5, signed=True, thetas=thetas, Ns=Ns)

    sweep("COMPARISON (alpha=2/5, POSITIVE data -- closed by BMR 2011)",
          alpha=0.4, nu=0.02, amplitude=2.0, beta=0.5, signed=False, thetas=thetas, Ns=Ns)

    print("\n" + "=" * 78)
    print("AMPLITUDE SWEEP -- the discriminating experiment.")
    print("At A=2 the solution is in the small-data regime, where regularity is trivial and")
    print("saturation says nothing. The question lives at LARGE amplitude. And there the")
    print("comparison is theorem-backed on one side: BMR 2011 proves POSITIVE data at")
    print("alpha=2/5 is globally regular at EVERY amplitude, so the positive column must")
    print("saturate however large A gets. A sign-changing column that stops saturating where")
    print("the positive one still does would be a genuine signal; identical behaviour is a")
    print("null result. Either way it is pre-registered before the numbers are seen.")
    print("=" * 78)
    for A in (8.0, 32.0):
        sweep(f"alpha=2/5, SIGN-CHANGING, A={A} (open case)",
              alpha=0.4, nu=0.02, amplitude=A, beta=0.5, signed=True, thetas=thetas, Ns=Ns)
        sweep(f"alpha=2/5, POSITIVE, A={A} (BMR: regular at every amplitude)",
              alpha=0.4, nu=0.02, amplitude=A, beta=0.5, signed=False, thetas=thetas, Ns=Ns)

    print("\nPOSITIVE CONTROL 2 is built into every row: theta=2 is controlled by the energy")
    print("inequality at EVERY alpha, so its column must saturate everywhere. If it does not,")
    print("the instrument is wrong and no other column may be read.")
    print("flux_err = worst |sum u_n N_n| / scale; the truncated nonlinearity conserves energy")
    print("exactly, so this is a structural check on the integrator, not a physical quantity.")
    print("\nRaw numbers only. This screen can say 'no room visible'; it can never say a bound")
    print("exists. Verdict is the owner's (SPEC 8).")


if __name__ == "__main__":
    main()
