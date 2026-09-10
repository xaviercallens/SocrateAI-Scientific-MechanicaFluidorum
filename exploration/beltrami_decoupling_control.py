#!/usr/bin/env python3
# TIER C — EXPLORATORY, NO CLAIMS — NEVER GATES A CLAIM (SPEC bars floats from Tier B/A)
"""The decisive control on the "T-dual Beltrami shield": does the alignment come from the
METRIC or from the DAMPING TERM?

WHY THIS EXISTS. `docs/proposals/2026-09-10-leanflow-counterdetonation-review.md` found that the
solver's Beltrami result may be produced by a term the author added by hand rather than by the
T-dual metric. The owner ordered the decisive control on 2026-09-10.

WHAT THE OWNER ASKED FOR, AND WHY IT CANNOT BE RUN LITERALLY. The instruction was
"damping = 16, but alpha_prime = 0". In the reviewed source the damping is DERIVED FROM alpha:

    wall_factor = if alpha > 0 { (1 - k_eff/k).max(0) * 16 } else { 0 }

so setting alpha = 0 sets wall_factor = 0 as well: the literal run turns the damping off too, and
collapses back to the calibration run. The two effects have to be DECOUPLED, which needs the
2x2 design below. This is reported rather than silently "fixed" (LL-2 discipline).

THE DESIGN — a full factorial, because one cell cannot separate two causes:

    run  metric k_eff        damping on u^-      what it isolates
    A    k/(1+a k^2)         on  (a-derived)     the solver's own configuration
    B    k          (OFF)    on  (same profile)  DAMPING ALONE  <- the decisive cell
    C    k/(1+a k^2)         off (forced 0)      METRIC ALONE
    D    k          (OFF)    off                 calibration (classical)

Pre-registered reading, fixed before the run:
  * if B reaches alignment > 0.98 like A, the Beltrami state is produced by the DAMPING and the
    T-dual metric is not what causes it -> flag the result a numerical artifact;
  * if C reaches it and B does not, the metric is doing the work and the review was wrong;
  * if neither B nor C reaches it, the effect needs both and is a genuine interaction.

MODEL. Transcribed from the reviewed source (crates/leanflow-solver/src/euler_counterdetonation.rs),
not re-derived, so that the control tests THAT model:
    kappa_n = kappa_0 * lambda^n,  n = 0..N-1
    k* = k_eff(kappa_n, alpha)
    transfer_plus  = k* * (u+_{n-1}^2 - lambda * u+_n * u+_{n+1})
    cross          = c_stretch * k* * (u-_n * u-_{n+1} - u-_{n-1} * u-_n)
    du+_n = transfer_plus - cross
    transfer_minus = k* * (-u-_{n-1}^2 + lambda * u-_n * u-_{n+1})
    du-_n = transfer_minus + cross - wall_factor_n * u-_n
RK4, dt = 1e-4, T = 0.5, N = 20, kappa_0 = 1, lambda = 2, A = 2, gamma = 1/3, 3 packet shells,
epsilon_cross = 0.15, c_stretch = 0.25, alpha = 0.01 -- all as in the source.

OBSERVABLES. The alignment the solver reports, plus (directive D-2, 2026-09-10: abandon global
scalar ratios, track LOCAL DIRECTIONAL FLUXES) the per-band net helicity transfer
    dH_n/dt = 2 * kappa_n * (u+_n * du+_n - u-_n * du-_n)
aggregated over three shell bands, so that "where does helicity go" is answered directionally
instead of by one global ratio.

CONTROLS (SPEC §7.3, both directions, run before the measurement):
  P1  at alpha = 0 and wall_factor = 0 the scheme must CONSERVE the u^+ sector's energy to the
      integrator's order -- the homochiral transfers telescope. Positive control on the transcription.
  N1  the cross term must BREAK total energy conservation (the review's finding 4). If total energy
      is conserved, the transcription is wrong, since the reviewed source has this defect.
  N2  a deliberately mis-indexed influx (kappa_n in place of kappa_{n-1}) must change the answer.
NO VERDICT is issued here; verdicts are the owner's (PLAN §2).
"""

import math
import sys

N_SHELLS = 20
KAPPA_0 = 1.0
LAMBDA = 2.0
AMPLITUDE = 2.0
GAMMA = 1.0 / 3.0
N_PACKET = 3
EPS_CROSS = 0.15
C_STRETCH = 0.25
ALPHA = 0.01
DT = 1.0e-4
T_MAX = 0.5
WALL_STRENGTH = 16.0


def k_eff(k, alpha):
    """k/(1+alpha k^2), the solver's metric. NOTE: this is NOT the Fourier image of
    Reff = max(R, alpha/R), which would be min(k, 1/(alpha k)). Different object (review §4)."""
    return k if alpha <= 0.0 else k / (1.0 + alpha * k * k)


def kappas():
    return [KAPPA_0 * LAMBDA ** n for n in range(N_SHELLS)]


def initial_state():
    kap = kappas()
    up = [0.0] * N_SHELLS
    um = [0.0] * N_SHELLS
    for n in range(N_SHELLS):
        if n < N_PACKET:
            amp = AMPLITUDE * kap[n] ** (-GAMMA)
            up[n] = amp
            um[n] = EPS_CROSS * amp
    return up, um


def wall_profile(metric_alpha, damping_on):
    """The damping coefficient per shell.

    In the reviewed source this is tied to `alpha`. Here it is a SEPARATE argument, which is the
    entire point of the control: `damping_on` selects whether the term acts, `metric_alpha` selects
    what the triad rates see. The profile is the one the source would produce at alpha = ALPHA, so
    run B applies exactly the damping of run A while the triad rates run on the bare metric."""
    kap = kappas()
    if not damping_on:
        return [0.0] * N_SHELLS
    return [max(0.0, 1.0 - k_eff(k, ALPHA) / k) * WALL_STRENGTH for k in kap]


def rhs(up, um, metric_alpha, wall, perturb_influx=False):
    kap = kappas()
    dup = [0.0] * N_SHELLS
    dum = [0.0] * N_SHELLS
    for i in range(N_SHELLS):
        kn = kap[i]
        ks = k_eff(kn, metric_alpha)
        up_prev = up[i - 1] if i > 0 else 0.0
        up_next = up[i + 1] if i < N_SHELLS - 1 else 0.0
        um_prev = um[i - 1] if i > 0 else 0.0
        um_next = um[i + 1] if i < N_SHELLS - 1 else 0.0
        # Negative control N2 mis-indexes the influx wavenumber: the source scales the influx
        # `u+_{n-1}^2` by k* at shell n, so the perturbation scales it by k* at shell n-1 instead.
        # (An earlier version of this line indexed shell n on BOTH branches and was therefore an
        # inert control — caught by N2 itself reading 0.00e+00. LL-19, in this file's own run.)
        influx_scale = k_eff(kap[max(i - 1, 0)], metric_alpha) if perturb_influx else ks
        transfer_plus = influx_scale * up_prev * up_prev - ks * LAMBDA * up[i] * up_next
        cross = C_STRETCH * ks * (um[i] * um_next - um_prev * um[i])
        dup[i] = transfer_plus - cross
        transfer_minus = -ks * um_prev * um_prev + ks * LAMBDA * um[i] * um_next
        dum[i] = transfer_minus + cross - wall[i] * um[i]
    return dup, dum


def rk4(up, um, metric_alpha, wall, dt, perturb_influx=False):
    a1p, a1m = rhs(up, um, metric_alpha, wall, perturb_influx)
    p2 = [up[i] + 0.5 * dt * a1p[i] for i in range(N_SHELLS)]
    m2 = [um[i] + 0.5 * dt * a1m[i] for i in range(N_SHELLS)]
    a2p, a2m = rhs(p2, m2, metric_alpha, wall, perturb_influx)
    p3 = [up[i] + 0.5 * dt * a2p[i] for i in range(N_SHELLS)]
    m3 = [um[i] + 0.5 * dt * a2m[i] for i in range(N_SHELLS)]
    a3p, a3m = rhs(p3, m3, metric_alpha, wall, perturb_influx)
    p4 = [up[i] + dt * a3p[i] for i in range(N_SHELLS)]
    m4 = [um[i] + dt * a3m[i] for i in range(N_SHELLS)]
    a4p, a4m = rhs(p4, m4, metric_alpha, wall, perturb_influx)
    nup = [up[i] + dt / 6.0 * (a1p[i] + 2 * a2p[i] + 2 * a3p[i] + a4p[i]) for i in range(N_SHELLS)]
    num = [um[i] + dt / 6.0 * (a1m[i] + 2 * a2m[i] + 2 * a3m[i] + a4m[i]) for i in range(N_SHELLS)]
    return nup, num


def energy(up, um):
    return 0.5 * sum(p * p + m * m for p, m in zip(up, um))


def energy_plus(up):
    return 0.5 * sum(p * p for p in up)


def enstrophy(up, um):
    kap = kappas()
    return 0.5 * sum(k * k * (p * p + m * m) for k, p, m in zip(kap, up, um))


def alignment(up, um):
    kap = kappas()
    num = sum(k * (p * p - m * m) for k, p, m in zip(kap, up, um))
    den = sum(k * (p * p + m * m) for k, p, m in zip(kap, up, um))
    return 1.0 if den <= 1e-15 else min(1.0, max(0.0, abs(num) / den))


BANDS = [(0, 6), (6, 13), (13, N_SHELLS)]
BAND_NAMES = ["IR n=0..5", "mid n=6..12", "UV n=13..19"]


def band_helicity_rate(up, um, dup, dum):
    """Directive D-2: local directional flux, not a global ratio.
    dH_n/dt = 2 kappa_n (u+_n du+_n - u-_n du-_n), aggregated per band."""
    kap = kappas()
    rates = []
    for lo, hi in BANDS:
        rates.append(sum(2.0 * kap[i] * (up[i] * dup[i] - um[i] * dum[i]) for i in range(lo, hi)))
    return rates


def run(label, metric_alpha, damping_on, perturb_influx=False, t_max=T_MAX):
    up, um = initial_state()
    wall = wall_profile(metric_alpha, damping_on)
    steps = int(round(t_max / DT))
    e0, om0 = energy(up, um), enstrophy(up, um)
    max_om = om0
    band_acc = [0.0, 0.0, 0.0]
    diverged = False
    done = 0
    for _ in range(steps):
        dup, dum = rhs(up, um, metric_alpha, wall, perturb_influx)
        r = band_helicity_rate(up, um, dup, dum)
        for j in range(3):
            band_acc[j] += r[j] * DT
        nup, num = rk4(up, um, metric_alpha, wall, DT, perturb_influx)
        if any(not math.isfinite(x) or abs(x) > 1e15 for x in nup + num):
            diverged = True
            break
        up, um = nup, num
        done += 1
        om = enstrophy(up, um)
        if om > max_om:
            max_om = om
    return {
        "label": label, "metric": "k_eff" if metric_alpha > 0 else "k (bare)",
        "damping": "on" if damping_on else "off",
        "align0": alignment(*initial_state()), "align": alignment(up, um),
        "E0": e0, "E": energy(up, um), "Om0": om0, "Om": enstrophy(up, um),
        "max_Om": max_om, "ratio_Om": max_om / om0, "steps": done, "diverged": diverged,
        "bands": band_acc,
    }


def controls():
    print("== CONTROLS (both directions; measurement is void if any fails) ==")
    ok = True
    # Controls run on a SHORT horizon on purpose: the alpha=0 trajectory is the calibration run,
    # which the source claims diverges before t = 0.3. Testing conservation across a divergence
    # measures the integrator's overflow, not the scheme (LL-18: a compute artifact is not a
    # physical statement). 200 steps = t = 0.02, far inside the regular regime.
    CTRL_STEPS = 200
    # P1: with no metric and no damping, the u+ sector's energy telescopes.
    up, um = initial_state()
    um = [0.0] * N_SHELLS          # pure u+ sector isolates the homochiral transfers
    wall = [0.0] * N_SHELLS
    e_start = energy_plus(up)
    for _ in range(CTRL_STEPS):
        up, um = rk4(up, um, 0.0, wall, DT)
    drift = abs(energy_plus(up) - e_start) / e_start
    p1 = drift < 1e-6
    print(f"P1 u+ sector energy conserved (alpha=0, no damping): relative drift {drift:.2e}   "
          f"{'OK' if p1 else '*** FAILED — transcription wrong ***'}")
    ok &= p1
    # N1: the cross term must BREAK total energy conservation (review finding 4).
    up, um = initial_state()
    e_start = energy(up, um)
    for _ in range(CTRL_STEPS):
        up, um = rk4(up, um, 0.0, wall, DT)
    drift_tot = abs(energy(up, um) - e_start) / e_start
    n1 = drift_tot > 1e-6
    print(f"N1 total energy NOT conserved (the cross term is non-conservative): drift "
          f"{drift_tot:.2e}   {'OK (fires)' if n1 else '*** INERT — expected the source defect ***'}")
    ok &= n1
    # N2: a mis-indexed influx must change the trajectory.
    a = run("N2-ref", 0.0, False, perturb_influx=False, t_max=0.05)
    b = run("N2-bad", 0.0, False, perturb_influx=True, t_max=0.05)
    n2 = abs(a["Om"] - b["Om"]) / max(a["Om"], 1e-300) > 1e-6
    print(f"N2 mis-indexed influx changes the answer: |dOm|/Om = "
          f"{abs(a['Om'] - b['Om']) / max(a['Om'], 1e-300):.2e}   "
          f"{'OK (fires)' if n2 else '*** INERT ***'}")
    ok &= n2
    print("CONTROLS:", "PASS\n" if ok else "*** FAILED — no reading admissible ***\n")
    return ok


def main():
    if not controls():
        sys.exit(1)
    runs = [
        run("A  metric+damping (the solver's own configuration)", ALPHA, True),
        run("B  damping ALONE  <-- THE DECISIVE CELL", 0.0, True),
        run("C  metric ALONE", ALPHA, False),
        run("D  calibration (neither)", 0.0, False),
    ]
    print(f"{'run':52} {'metric':10} {'damp':5} {'align(0)':>9} {'align(T)':>9} "
          f"{'maxOm/Om0':>11} {'steps':>6}")
    for r in runs:
        print(f"{r['label']:52} {r['metric']:10} {r['damping']:5} {r['align0']:9.4f} "
              f"{r['align']:9.4f} {r['ratio_Om']:11.3e} {r['steps']:6d}"
              + ("  DIVERGED" if r["diverged"] else ""))

    print("\nD-2 observable — net helicity transferred into each shell band (time-integrated):")
    print(f"{'run':52} " + " ".join(f"{n:>14}" for n in BAND_NAMES))
    for r in runs:
        print(f"{r['label']:52} " + " ".join(f"{v:14.4e}" for v in r["bands"]))

    a, b, c, d = runs
    print("\nPre-registered reading, applied mechanically:")
    print("  A DIVERGED cell is INADMISSIBLE. Its terminal alignment is the state of an overflowing")
    print("  integrator, not of a flow (LL-18: a compute artifact is not a physical statement).")
    for r in runs:
        verdict = "INADMISSIBLE (diverged)" if r["diverged"] else (
            f"align {r['align']:.4f} {'>' if r['align'] > 0.98 else '<='} 0.98")
        print(f"    {r['label'][:44]:46} {verdict}")

    print(f"\n  The initial condition is ALREADY {a['align0']:.4f} aligned, by construction:")
    print("  epsilon_cross = 0.15 sets u- = 0.15 u+, giving (1-0.15^2)/(1+0.15^2). Any claim of")
    print("  'conversion into a Beltrami flow' must be read as the DELTA from that starting point.")
    for r in runs:
        if not r["diverged"]:
            print(f"    {r['label'][:44]:46} delta = {r['align'] - r['align0']:+.4f}")

    admissible = [r for r in runs if not r["diverged"]]
    if not admissible:
        print("\n  => no admissible cell; nothing can be read.")
    else:
        metric_only_bounded = (not c["diverged"])
        damping_only_bounded = (not b["diverged"])
        print("\n  Which factor keeps the run bounded:")
        print(f"    metric alone  (C): {'bounded' if metric_only_bounded else 'DIVERGED'}")
        print(f"    damping alone (B): {'bounded' if damping_only_bounded else 'DIVERGED'}")
        if metric_only_bounded and not damping_only_bounded:
            print("  => BOUNDEDNESS is supplied by the METRIC, not by the damping term.")
            print(f"  => and the damping's contribution to alignment is only "
                  f"{a['align'] - c['align']:+.4f} on top of the metric alone.")
    print("\nNO VERDICT is issued here. Verdicts are the owner's (PLAN section 2).")


if __name__ == "__main__":
    main()
