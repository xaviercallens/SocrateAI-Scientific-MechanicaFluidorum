#!/usr/bin/env python3
# TIER C - EXPLORATORY, NO CLAIMS - NEVER GATES A CLAIM (SPEC bars floats from Tier B/A)
"""
PILOT for the OP-2' attractivity experiment (K2/K3 of docs/designs/OP2_PRIME_PLANAR_CONFINEMENT.md).

QUESTION (pre-registered there): is the planar-locked manifold attractive, neutral or repulsive
under the truncated 3-D Galerkin flow? Observable: growth rate sigma of the out-of-plane energy
fraction from near-planar data. Expected null: repulsive (classical 3-D instability of 2-D
flows) -- and that expectation is the CONTROL structure, per LL-15: the design names in advance
a condition where the effect must be ABSENT (exactly planar data, which stays planar by the
K1-verified invariance -- a theorem-backed positive control).

THIS IS A PILOT. M=2 (32 modes), coordinate plane z=0 only (tilted planes need larger M to have
enough in-plane modes; K1 was verified for tilted planes in exact arithmetic separately). Its
purpose is to validate the instrument and produce a first sigma sign, not a result.

Dynamics: du_k/dt = N(u)_k - nu |k|^2 u_k, with the Leray-projected convolution
N(u)_k = -i sum_{p+q=k} P(k)[(q . u_p) u_q] -- the float port of the exact Tier B evaluator
(tests/tier_b_nse_triad_convolution.py); the port is cross-checked against structure by its
controls below rather than against the exact evaluator directly (a pilot-level shortcut,
recorded honestly).

CONTROLS, run before any measurement is reported:
  * K2 POSITIVE (theorem-backed): exactly planar data must keep E_out at machine-zero level.
    Fails => integrator broken, refuse to report.
  * NEGATIVE: generic 3-D data must show O(1) out-of-plane energy fraction throughout.
    Fails => the observable is insensitive, refuse to report.

Output: sigma estimated as the log-slope of E_out/E_tot over the middle half of the run, for a
few (nu, epsilon). Raw numbers only; no verdict (SPEC 8).
"""

import math
import sys

M = 2
NU_LIST = (0.1, 0.02)
EPS_LIST = (1e-6, 1e-4)
DT, T_END = 2e-3, 6.0


def modes(M):
    return [(x, y, z) for x in range(-M, M + 1) for y in range(-M, M + 1)
            for z in range(-M, M + 1) if 0 < x * x + y * y + z * z <= M * M]


PTS = modes(M)
IDX = {p: i for i, p in enumerate(PTS)}
N_MODES = len(PTS)
PAIRS = [(i, IDX[(c[0] - a[0], c[1] - a[1], c[2] - a[2])], IDX[c])
         for i, a in enumerate(PTS) for c in PTS
         if (c[0] - a[0], c[1] - a[1], c[2] - a[2]) in IDX]  # (p, q, k) index triples


def leray(k, v):
    k2 = k[0] * k[0] + k[1] * k[1] + k[2] * k[2]
    kv = (k[0] * v[0] + k[1] * v[1] + k[2] * v[2]) / k2
    return (v[0] - kv * k[0], v[1] - kv * k[1], v[2] - kv * k[2])


def nonlinear(u):
    """N(u)_k = -i sum_{p+q=k} P(k)[(q . u_p) u_q]; u is a list of complex 3-tuples."""
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
    """Enforce k.u_k = 0 (Leray per mode) and u_{-k} = conj(u_k) by symmetrisation."""
    u = [leray(PTS[i], u[i]) for i in range(N_MODES)]
    out = list(u)
    for i, k in enumerate(PTS):
        j = IDX[(-k[0], -k[1], -k[2])]
        avg = tuple(0.5 * (u[i][c] + u[j][c].conjugate()) for c in range(3))
        out[i] = avg
        out[j] = tuple(x.conjugate() for x in avg)
    return out


def energies(u):
    e_in = e_out = 0.0
    for i, k in enumerate(PTS):
        e = sum(abs(x) ** 2 for x in u[i])
        if k[2] == 0:
            e_in += e
        else:
            e_out += e
    return e_in, e_out


def seed_field(eps, seed=3):
    import random
    rng = random.Random(seed)
    u = []
    for k in PTS:
        amp = eps if k[2] != 0 else 1.0
        u.append(tuple(amp * complex(rng.uniform(-1, 1), rng.uniform(-1, 1)) for _ in range(3)))
    return project_div_and_reality(u)


def run(nu, eps):
    u = seed_field(eps)
    steps = int(T_END / DT)
    frac = []
    for s in range(steps):
        u = step_rk2(u, nu, DT)
        if s % 50 == 0:
            u = project_div_and_reality(u)   # control drift of the constraints
            ei, eo = energies(u)
            tot = ei + eo
            if not (tot < 1e12):
                return None, frac
            frac.append((s * DT, eo / tot if tot > 0 else 0.0))
    return u, frac


def slope(frac):
    """log-slope of E_out/E_tot over the middle half; None if not measurable."""
    mid = [(t, f) for t, f in frac if frac[-1][0] * 0.25 <= t <= frac[-1][0] * 0.75 and f > 0]
    if len(mid) < 4:
        return None
    t0, f0 = mid[0]
    t1, f1 = mid[-1]
    if f0 <= 0 or f1 <= 0 or t1 <= t0:
        return None
    return (math.log(f1) - math.log(f0)) / (t1 - t0)


def main():
    print(f"== sigma pilot: planar attractivity, M={M} ({N_MODES} modes), plane z=0 ==\n")

    # K2 POSITIVE control: exactly planar data must stay planar (machine zero out-of-plane).
    u, frac = run(nu=0.1, eps=0.0)
    worst = max((f for _, f in frac), default=1.0)
    print(f"K2 positive control (eps=0): max E_out/E_tot = {worst:.2e}  "
          f"{'OK (machine level)' if worst < 1e-12 else '*** FAILED ***'}")
    if worst >= 1e-12:
        print("Refusing to report any measurement."); sys.exit(1)

    # NEGATIVE control: generic data must show O(1) out-of-plane fraction.
    u, frac = run(nu=0.1, eps=1.0)
    typical = frac[len(frac) // 2][1]
    print(f"negative control (eps=1):    E_out/E_tot mid-run = {typical:.3f}  "
          f"{'OK (O(1))' if typical > 0.05 else '*** FAILED ***'}")
    if typical <= 0.05:
        print("Observable insensitive; refusing to report."); sys.exit(1)

    print("\ncontrols pass. PILOT measurement (raw, no verdict):")
    print(f"{'nu':>6} {'eps':>8} {'sigma (log-slope of E_out/E_tot)':>34}")
    for nu in NU_LIST:
        for eps in EPS_LIST:
            u, frac = run(nu, eps)
            s = slope(frac) if frac else None
            tag = f"{s:+.3f}" if s is not None else "not measurable"
            blowup = "  [magnitude guard hit]" if u is None else ""
            print(f"{nu:>6} {eps:>8.0e} {tag:>34}{blowup}")
    print("\nsigma > 0 = repulsive (expected null), sigma < 0 = attractive (would be a discovery).")
    print("PILOT ONLY: M=2, coordinate plane, short horizon. No verdict; that is the owner's.")


if __name__ == "__main__":
    main()
