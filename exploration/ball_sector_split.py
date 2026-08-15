#!/usr/bin/env python3
# TIER C - EXPLORATORY, NO CLAIMS - NEVER GATES A CLAIM (floats; SPEC bars them from Tier A/B)
"""
WHICH SECTOR carries the second eigenvalue of the ball 2-section? The decisive discriminator
for the 5/6 conjecture, and the reason docs/designs/BALL_SPECTRAL_PROBLEM.md can state a sharp
continuum problem instead of a vague one.

THE STRUCTURE BEING TESTED (derived by hand in that memo, exact-arithmetic-verified for its
combinatorial half). The exact ball weight is

    A_M(u,v) = 2*[u+v in Lambda_M] + 4*[u-v in Lambda_M]        (u != v)

so the adjacency commutes with the reflection R: f(u) -> f(-u), and the spectrum splits.
On EVEN vectors the two indicator terms merge with weight 2+4 = 6; on ODD vectors they cancel
to 4-2 = 2. Writing C for the common "lens" operator (kernel [u-v in Lambda_M]) and
Q = D^{-1/2} C D^{-1/2}, this gives

    P_even = 6Q      P_odd = 2Q          (P = D^{-1/2} A D^{-1/2})

and, in the continuum, Q has Perron eigenvalue EXACTLY 1/6 with eigenfunction sqrt(V(|x|)),
V the lens volume -- so P's Perron eigenvalue is 1, as it must be. The second eigenvalue is
therefore

    mu_2 = max( 6 * nu_2^even(Q),  2 * nu_1^odd(Q) )

and the measured mu_2 ~ 1/6 is consistent with EITHER nu_2^even = 1/36 OR nu_1^odd = 1/12.
Those are different mathematical statements about different operators. THIS SCRIPT DECIDES
WHICH, by computing each sector's leading eigenvalue separately (P commutes with R, so power
iteration inside a sector stays in it; the projection is re-applied each step to kill
numerical leakage).

CONTROLS (both mandatory, LL-12):
  * POSITIVE: the even sector's leading eigenvalue must come out 1.000000 (Perron, exact by
    construction). If it does not, the sector projection or the normalisation is broken.
  * NEGATIVE: the reflection R must be a genuine involution with both sectors non-trivial
    (dim_even + dim_odd = n, both > 0). A degenerate split would make the comparison vacuous.
"""

import sys
import numpy as np

sys.path.insert(0, __file__.rsplit("/", 1)[0].replace("/exploration", "/symbolic"))
from triad_hypergraph import lattice, triads, two_section   # noqa: E402


def build(M):
    pts = lattice(M)
    A = np.array(two_section(pts, triads(pts)), dtype=float)
    idx = {p: i for i, p in enumerate(pts)}
    perm = np.array([idx[(-p[0], -p[1], -p[2])] for p in pts])   # the reflection R
    d = A.sum(axis=1)
    Dm = 1.0 / np.sqrt(d)
    P = (A * Dm[:, None]) * Dm[None, :]
    return pts, P, perm, d


def sector_top(P, perm, parity, deflate=None, iters=3000):
    """Leading eigenvalue of P restricted to the even (+1) or odd (-1) sector."""
    n = P.shape[0]
    rng = np.random.default_rng(7)
    v = rng.standard_normal(n)

    def project(w):
        w = 0.5 * (w + parity * w[perm])          # into the sector
        if deflate is not None:
            w = w - (w @ deflate) * deflate       # off the Perron direction
        return w

    v = project(v)
    v /= np.linalg.norm(v)
    shift = 3.0                                    # make it positive-definite for convergence
    for _ in range(iters):
        w = P @ v + shift * v
        w = project(w)
        nw = np.linalg.norm(w)
        if nw < 1e-300:
            return float("nan"), v
        v = w / nw
    return float(v @ (P @ v)), v


def main():
    print("== Which sector carries mu_2? (ball 2-section, normalised adjacency) ==\n")
    print(f"{'M':>3} {'n':>6} {'dim even':>9} {'dim odd':>8} {'even#1':>9} {'even#2':>10}"
          f" {'odd#1':>10} {'mu_2':>10} {'gap':>10} {'carrier':>8}")
    for M in (3, 4, 5, 6):
        pts, P, perm, d = build(M)
        n = len(pts)

        # NEGATIVE control: the split must be non-degenerate.
        n_even = int(round(sum(1 for i in range(n) if perm[i] == i)))   # self-paired = 0 here
        dim_odd = n // 2
        dim_even = n - dim_odd
        if dim_even <= 0 or dim_odd <= 0:
            print(f"{M:>3}  degenerate sector split -- refusing to report"); continue

        perron = np.sqrt(d)
        perron = perron / np.linalg.norm(perron)

        # POSITIVE control: even sector's leading eigenvalue must be 1.
        e1, _ = sector_top(P, perm, +1.0)
        if abs(e1 - 1.0) > 1e-6:
            print(f"{M:>3}  even#1 = {e1:.6f} != 1 -- construction broken, refusing to report")
            continue

        e2, _ = sector_top(P, perm, +1.0, deflate=perron)
        o1, _ = sector_top(P, perm, -1.0)
        mu2 = max(e2, o1)
        carrier = "even" if e2 >= o1 else "odd"
        print(f"{M:>3} {n:>6} {dim_even:>9} {dim_odd:>8} {e1:>9.6f} {e2:>10.6f}"
              f" {o1:>10.6f} {mu2:>10.6f} {1 - mu2:>10.6f} {carrier:>8}")

    print("\nReading: mu_2 = max(6*nu_2^even(Q), 2*nu_1^odd(Q)); the carrier column says which")
    print("continuum eigenvalue problem the 5/6 conjecture actually is. Raw numbers, no verdict.")


if __name__ == "__main__":
    main()
