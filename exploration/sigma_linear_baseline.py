#!/usr/bin/env python3
# TIER C - EXPLORATORY, NO CLAIMS - NEVER GATES A CLAIM (SPEC bars floats from Tier B/A)
"""
LINEAR NULL MODEL for the K3 sigma measurement (companion to sigma_planar_full.py).

WHY THIS EXISTS (LL-14/LL-15). The full experiment measured sigma < 0 at nu=1/2 - the
pre-registered "candidate discovery" branch. Before that number is allowed to mean anything,
the obvious artifact must be computed: under PURE LINEAR dynamics u_k(t) = u_k(0) e^{-nu k^2 t}
(nonlinearity off), the fraction E_out/E_tot already drifts whenever the out-of-plane modes
carry a different energy-weighted <|k|^2> than the in-plane modes. That drift is spectral
bookkeeping, not attractivity of the manifold. The meaningful observable is the EXCESS
sigma_measured - sigma_linear.

This file computes sigma_linear in CLOSED FORM from the same seed, same window, same slope
estimator as the experiment: E_out(t) = sum_out |u_k(0)|^2 e^{-2 nu |k|^2 t}, no integration,
no timestep error. It is deterministic given the seed.

A measurement survives as a candidate discovery ONLY if sigma_measured is materially below
sigma_linear (the nonlinearity actively pumps energy back toward the plane). If
sigma_measured ~ sigma_linear the negative sign is the linear artifact.
"""

import math

# mirror the experiment's configuration exactly
import importlib.util as _il
import os
_spec = _il.spec_from_file_location(
    "sig_full", os.path.join(os.path.dirname(__file__), "sigma_planar_full.py"))
_full = _il.module_from_spec(_spec)
_spec.loader.exec_module(_full)

PTS, DT, T_END = _full.PTS, _full.DT, _full.T_END
NU_LIST, EPS_LIST, PLANES = _full.NU_LIST, _full.EPS_LIST, _full.PLANES
in_plane, seed_field, slope = _full.in_plane, _full.seed_field, _full.slope


def linear_frac_series(u0, nu, normal):
    """E_out/E_tot at the same sample times as the experiment, under exact linear decay."""
    e0 = []
    for i, k in enumerate(PTS):
        e = sum(abs(x) ** 2 for x in u0[i])
        k2 = k[0] ** 2 + k[1] ** 2 + k[2] ** 2
        e0.append((e, k2, in_plane(k, normal)))
    frac = []
    steps = int(T_END / DT)
    for s in range(steps):
        if s % 50 == 0:
            t = s * DT
            ei = sum(e * math.exp(-2.0 * nu * k2 * t) for e, k2, inp in e0 if inp)
            eo = sum(e * math.exp(-2.0 * nu * k2 * t) for e, k2, inp in e0 if not inp)
            tot = ei + eo
            frac.append((t, eo / tot if tot > 0 else 0.0))
    return frac


def mean_k2(u0, normal):
    num_i = num_o = den_i = den_o = 0.0
    for i, k in enumerate(PTS):
        e = sum(abs(x) ** 2 for x in u0[i])
        k2 = k[0] ** 2 + k[1] ** 2 + k[2] ** 2
        if in_plane(k, normal):
            num_i += e * k2; den_i += e
        else:
            num_o += e * k2; den_o += e
    return (num_i / den_i if den_i > 0 else float("nan"),
            num_o / den_o if den_o > 0 else float("nan"))


def main():
    print("== linear null model sigma_lin (closed form, same seed/window/estimator as K3) ==\n")
    for plane_name, normal in PLANES:
        print(f"---- plane {plane_name} ----")
        for eps in EPS_LIST:
            u0 = seed_field(eps, normal)
            ki, ko = mean_k2(u0, normal)
            print(f"  eps={eps:.0e}: energy-weighted <k^2>_in = {ki:.3f}, <k^2>_out = {ko:.3f}"
                  f"  (out - in = {ko - ki:+.3f}; linear drift predicted "
                  f"{'NEGATIVE' if ko > ki else 'positive'})")
            for nu_q in NU_LIST:
                nu = float(nu_q)
                fr = linear_frac_series(u0, nu, normal)
                s = slope(fr)
                tag = f"{s:+.3f}" if s is not None else "n/a"
                print(f"    nu={str(nu_q):>5}: sigma_lin = {tag}")
        print()
    print("Compare: excess = sigma_measured - sigma_lin. Only a materially negative excess")
    print("would mean the nonlinearity pumps energy toward the plane. Raw numbers; no verdict.")


if __name__ == "__main__":
    main()
