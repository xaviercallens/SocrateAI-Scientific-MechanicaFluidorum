#!/usr/bin/env python3
# TIER C - EXPLORATORY, NO CLAIMS - NEVER GATES A CLAIM (SPEC bars floats from Tier B/A)
"""
K3 of docs/designs/OP2_PRIME_PLANAR_CONFINEMENT.md: the FULL attractivity experiment.

Extends the validated pilot (exploration/sigma_planar_pilot.py, instrument checks passed
2026-08-14) along the four axes the pilot deliberately deferred:

  1. M=3 (the pilot's M=2 doubled: ~122 modes), so tilted planes have enough in-plane modes;
  2. TILTED plane <(1,0,0),(0,1,2)> (normal (0,-2,1)) alongside the coordinate plane z=0
     (normal (0,0,1)) -- K1 proved invariance for the tilted plane in exact arithmetic, the
     pilot only ever exercised z=0;
  3. nu swept with each (nu, M) pair's grid-adequacy status computed in EXACT rational
     arithmetic and printed next to the measurement: nu^3 * M^4 >= 1, the alpha=1 instance of
     tests/tier_b_grid_adequacy.py's criterion with the sphere radius M standing in for the
     dyadic cutoff 2^N (an adaptation, recorded honestly: M is not a power of 2);
  4. PRST secondary observable (Ponce-Racke-Sideris-Titi, CMP 159 (1994): near-2D 3-D data
     has globally regular solutions): alongside sigma we report max-enstrophy amplification
     Z_max/Z_0 per run. In a finite truncation nothing can blow up, so this is NOT a
     regularity test -- it is the raw number PRST's neighbourhood statement says should stay
     tame for small eps, recorded for later comparison against their smallness condition.

CONTROLS (per plane, before any measurement from that plane is reported; LL-12/LL-15):
  * K2 POSITIVE (theorem-backed, K1): exactly planar data must keep E_out at machine zero.
  * NEGATIVE: generic data must show O(1) out-of-plane fraction.

Observable: sigma = log-slope of E_out/E_tot over the middle half of the run. sigma > 0
uniformly = repulsive (the pre-registered expected null); sigma <= 0 anywhere = candidate
discovery, to be escalated, never concluded here. Raw numbers only; verdicts are the owner's
(SPEC 8). Pre-registered kill criterion K3: sigma > 0 everywhere => OP-2' dead as a route to
regularity for GENERIC data (the PRST neighbourhood half survives regardless -- it is a
published theorem, not this experiment's to kill).
"""

import math
import sys
from fractions import Fraction as Q

M = 3
DT, T_END = 2e-3, 4.0
NU_LIST = (Q(1, 2), Q(1, 10), Q(1, 50))     # exact, for the adequacy check
EPS_LIST = (1e-6, 1e-4)
PLANES = (
    ("z=0 (coordinate)", (0, 0, 1)),
    ("<(1,0,0),(0,1,2)> (tilted)", (0, -2, 1)),
)


def modes(M):
    return [(x, y, z) for x in range(-M, M + 1) for y in range(-M, M + 1)
            for z in range(-M, M + 1) if 0 < x * x + y * y + z * z <= M * M]


PTS = modes(M)
IDX = {p: i for i, p in enumerate(PTS)}
N_MODES = len(PTS)
PAIRS = [(i, IDX[(c[0] - a[0], c[1] - a[1], c[2] - a[2])], IDX[c])
         for i, a in enumerate(PTS) for c in PTS
         if (c[0] - a[0], c[1] - a[1], c[2] - a[2]) in IDX]


def grid_adequate(nu_exact):
    """alpha=1 sphere-cutoff adaptation of tier_b_grid_adequacy: nu^3 * M^4 >= 1, exact."""
    return nu_exact ** 3 * Q(M) ** 4 >= 1


def leray(k, v):
    k2 = k[0] * k[0] + k[1] * k[1] + k[2] * k[2]
    kv = (k[0] * v[0] + k[1] * v[1] + k[2] * v[2]) / k2
    return (v[0] - kv * k[0], v[1] - kv * k[1], v[2] - kv * k[2])


def nonlinear(u):
    """N(u)_k = -i sum_{p+q=k} P(k)[(q . u_p) u_q] (float port of the Tier B evaluator)."""
    acc = [(0j, 0j, 0j)] * N_MODES
    for ip, iq, ik in PAIRS:
        q = PTS[iq]
        up, uq = u[ip], u[iq]
        s = q[0] * up[0] + q[1] * up[1] + q[2] * up[2]
        a = acc[ik]
        acc[ik] = (a[0] + s * uq[0], a[1] + s * uq[1], a[2] + s * uq[2])
    out = [None] * N_MODES
    for ik, k in enumerate(PTS):
        v = leray(k, acc[ik])
        out[ik] = (-1j * v[0], -1j * v[1], -1j * v[2])
    return out


def rhs(u, nu):
    Nl = nonlinear(u)
    out = [None] * N_MODES
    for i, k in enumerate(PTS):
        k2 = k[0] * k[0] + k[1] * k[1] + k[2] * k[2]
        out[i] = tuple(Nl[i][c] - nu * k2 * u[i][c] for c in range(3))
    return out


def step_rk2(u, nu, dt):
    k1 = rhs(u, nu)
    mid = [tuple(u[i][c] + 0.5 * dt * k1[i][c] for c in range(3)) for i in range(N_MODES)]
    k2 = rhs(mid, nu)
    return [tuple(u[i][c] + dt * k2[i][c] for c in range(3)) for i in range(N_MODES)]


def project_div_and_reality(u):
    u = [leray(PTS[i], u[i]) for i in range(N_MODES)]
    out = list(u)
    for i, k in enumerate(PTS):
        j = IDX[(-k[0], -k[1], -k[2])]
        avg = tuple(0.5 * (u[i][c] + u[j][c].conjugate()) for c in range(3))
        out[i] = avg
        out[j] = tuple(x.conjugate() for x in avg)
    return out


def in_plane(k, normal):
    return k[0] * normal[0] + k[1] * normal[1] + k[2] * normal[2] == 0


def energies(u, normal):
    e_in = e_out = 0.0
    for i, k in enumerate(PTS):
        e = sum(abs(x) ** 2 for x in u[i])
        if in_plane(k, normal):
            e_in += e
        else:
            e_out += e
    return e_in, e_out


def enstrophy(u):
    return sum((k[0]**2 + k[1]**2 + k[2]**2) * sum(abs(x) ** 2 for x in u[i])
               for i, k in enumerate(PTS))


def seed_field(eps, normal, seed=3):
    import random
    rng = random.Random(seed)
    u = []
    for k in PTS:
        amp = 1.0 if in_plane(k, normal) else eps
        u.append(tuple(amp * complex(rng.uniform(-1, 1), rng.uniform(-1, 1)) for _ in range(3)))
    return project_div_and_reality(u)


def run(nu, eps, normal):
    u = seed_field(eps, normal)
    z0 = enstrophy(u)
    z_max = z0
    steps = int(T_END / DT)
    frac = []
    for s in range(steps):
        u = step_rk2(u, nu, DT)
        if s % 50 == 0:
            u = project_div_and_reality(u)
            ei, eo = energies(u, normal)
            tot = ei + eo
            if not (tot < 1e12):
                return None, frac, float("inf")
            z_max = max(z_max, enstrophy(u))
            frac.append((s * DT, eo / tot if tot > 0 else 0.0))
    return u, frac, (z_max / z0 if z0 > 0 else float("nan"))


def slope(frac):
    mid = [(t, f) for t, f in frac if frac[-1][0] * 0.25 <= t <= frac[-1][0] * 0.75 and f > 0]
    if len(mid) < 4:
        return None
    t0, f0 = mid[0]
    t1, f1 = mid[-1]
    if f0 <= 0 or f1 <= 0 or t1 <= t0:
        return None
    return (math.log(f1) - math.log(f0)) / (t1 - t0)


def main():
    print(f"== K3 full sigma experiment: M={M} ({N_MODES} modes, {len(PAIRS)} triad pairs) ==")
    print(f"   dt={DT}, T={T_END}; adequacy criterion (exact): nu^3 * M^4 >= 1\n")

    for plane_name, normal in PLANES:
        n_in = sum(1 for k in PTS if in_plane(k, normal))
        print(f"---- plane {plane_name}: {n_in} in-plane / {N_MODES - n_in} out-of-plane ----")

        u, frac, _ = run(nu=0.1, eps=0.0, normal=normal)
        worst = max((f for _, f in frac), default=1.0)
        ok = worst < 1e-12
        print(f"  K2 positive control (eps=0): max E_out/E_tot = {worst:.2e}  "
              f"{'OK' if ok else '*** FAILED ***'}")
        if not ok:
            print("  refusing to report this plane."); continue

        u, frac, _ = run(nu=0.1, eps=1.0, normal=normal)
        typical = frac[len(frac) // 2][1]
        ok = typical > 0.05
        print(f"  negative control (eps=1):    E_out/E_tot mid-run = {typical:.3f}  "
              f"{'OK' if ok else '*** FAILED ***'}")
        if not ok:
            print("  observable insensitive; refusing to report this plane."); continue

        print(f"  {'nu':>6} {'adequate':>9} {'eps':>8} {'sigma':>10} {'Zmax/Z0':>10}")
        for nu_q in NU_LIST:
            adq = "yes" if grid_adequate(nu_q) else "NO"
            for eps in EPS_LIST:
                u, frac, zr = run(float(nu_q), eps, normal)
                s = slope(frac) if frac else None
                tag = f"{s:+.3f}" if s is not None else "n/a"
                guard = " [guard]" if u is None else ""
                print(f"  {str(nu_q):>6} {adq:>9} {eps:>8.0e} {tag:>10} {zr:>10.2f}{guard}")
        print()

    print("sigma > 0 = repulsive (expected null); sigma <= 0 anywhere = escalate, do not conclude.")
    print("Zmax/Z0 = PRST secondary observable (raw; finite truncation cannot blow up).")
    print("Raw numbers only. Verdict on K3 is the owner's (SPEC 8).")


if __name__ == "__main__":
    main()
