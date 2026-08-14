#!/usr/bin/env python3
"""Definition-independent baseline: the resonant-triad hypergraph on a truncated Z^3 lattice.

WHY THIS IS BUILDABLE NOW, AND WHY IT IS NOT AN E-1 VIOLATION. Tracks T1/T4 and the bridge to
3-D (OP-2, OP-6) are all BLOCKED-ON-DEFINITION: nobody may invent the Sym^2-constrained spectrum
on T^3. This file does not. It builds the UNCONSTRAINED object -- vertices = Fourier modes,
hyperedges = resonant triads k1+k2=k3 -- which is fixed by the Navier-Stokes nonlinearity itself
and requires no choice. That is exactly the status PLAN.md section 6 grants to T0.1/T0.2
("executable now: definition-independent tooling and baselines"), and this file extends the same
tooling to the object those tracks actually need.

WHY THIS OBJECT. Three separate lines converged on it:
  * The audit killed the claim that the programme's 1-D formalisation restates 3-D NSE. Any
    bridge back must act on the VECTOR structure of Z^3.
  * OP-2's draft radial embedding was measured to fail T1's own kill criterion: 99% of the
    triads it "permits" are same-shell triads with an even index, so it is a parity filter on a
    radial grading, not a depletion (docs/designs/TRACK_DEFINITIONS_DRAFT.md).
  * The NSE nonlinearity IS the triad structure: the convolution sends (u_p, u_q) -> u_{p+q}.
    So the hypergraph is not a model OF the interaction; it is the interaction's combinatorics.

The Ramanujan-style question the programme wants to ask -- does a "locked" sub-hypergraph have a
spectral gap? -- needs the UNLOCKED spectrum first, as the reference against which any gap is a
gap. That baseline is what this computes.

WHAT IS COMPUTED. For a truncation Lambda_M = {k in Z^3 \\ {0} : |k|^2 <= M^2}:
  * the triad count, and the degree sequence (how many triads each mode participates in);
  * the mode-mode adjacency A[p][q] = #{triads containing both p and q}, which is the standard
    2-section of the hypergraph;
  * the spectral gap of the normalised Laplacian of that 2-section.
Exact integer arithmetic for the combinatorics (counts, degrees, adjacency). The eigenvalue step
is floating point and is therefore Tier C: it is reported, never used to gate anything.

CONTROLS (both run before any measurement, per SPEC 7.3 -- this is a classifier-like instrument,
so an explicit positive control is mandatory, LL-12):
  * POSITIVE: a complete graph K_n, whose normalised-Laplacian spectral gap is exactly
    n/(n-1). The routine must reproduce it.
  * NEGATIVE: a disconnected graph, whose gap must be 0. An instrument that reports a positive
    gap for a disconnected graph cannot be trusted to report one for the lattice.

NO CLAIM is made about depletion, gaps, or Navier-Stokes. This is a baseline.
"""

import sys
from fractions import Fraction as Q


# --------------------------------------------------------------------- lattice + hypergraph
def lattice(M):
    """Lambda_M = {k in Z^3 \\ {0} : |k|^2 <= M^2}, exact integer test."""
    out = []
    for x in range(-M, M + 1):
        for y in range(-M, M + 1):
            for z in range(-M, M + 1):
                n2 = x * x + y * y + z * z
                if 0 < n2 <= M * M:
                    out.append((x, y, z))
    return out


def triads(pts):
    """All ordered (k1,k2,k3) in Lambda^3 with k1+k2=k3. Exact; no floats."""
    S = set(pts)
    out = []
    for k1 in pts:
        x1, y1, z1 = k1
        for k3 in pts:
            k2 = (k3[0] - x1, k3[1] - y1, k3[2] - z1)
            if k2 in S:
                out.append((k1, k2, k3))
    return out


def degrees(pts, tri):
    """How many triads each mode participates in (as any of the three slots)."""
    deg = {p: 0 for p in pts}
    for a, b, c in tri:
        deg[a] += 1
        deg[b] += 1
        deg[c] += 1
    return deg


def two_section(pts, tri):
    """Adjacency of the hypergraph's 2-section: A[p][q] = # triads containing both."""
    idx = {p: i for i, p in enumerate(pts)}
    n = len(pts)
    A = [[0] * n for _ in range(n)]
    for a, b, c in tri:
        for u, v in ((a, b), (a, c), (b, c)):
            iu, iv = idx[u], idx[v]
            if iu != iv:
                A[iu][iv] += 1
                A[iv][iu] += 1
    return A


# --------------------------------------------------------------------- spectrum (Tier C)
def normalised_laplacian_gap(A, iters=400):
    """Spectral gap of L = I - D^{-1/2} A D^{-1/2}, i.e. its smallest NONZERO eigenvalue,
    estimated by deflated power iteration on (2I - L). Floating point: Tier C."""
    n = len(A)
    d = [sum(row) for row in A]
    if n == 0 or any(x == 0 for x in d):
        return 0.0                      # isolated vertex => disconnected => gap 0
    import math
    inv = [1.0 / math.sqrt(x) for x in d]
    # v0 = D^{1/2} 1 is the exact null vector of L; deflate against it.
    v0 = [math.sqrt(x) for x in d]
    nrm = math.sqrt(sum(x * x for x in v0))
    v0 = [x / nrm for x in v0]

    def Mv(v):                          # (2I - L) v = (I + D^-1/2 A D^-1/2) v
        out = [0.0] * n
        for i in range(n):
            s = 0.0
            Ai = A[i]
            for j in range(n):
                if Ai[j]:
                    s += inv[i] * Ai[j] * inv[j] * v[j]
            out[i] = v[i] + s
        return out

    v = [1.0 if i % 2 == 0 else -1.0 for i in range(n)]
    for _ in range(iters):
        c = sum(v[i] * v0[i] for i in range(n))
        v = [v[i] - c * v0[i] for i in range(n)]
        v = Mv(v)
        nv = math.sqrt(sum(x * x for x in v))
        if nv < 1e-300:
            return 0.0
        v = [x / nv for x in v]
    c = sum(v[i] * v0[i] for i in range(n))
    v = [v[i] - c * v0[i] for i in range(n)]
    nv = math.sqrt(sum(x * x for x in v))
    if nv < 1e-12:
        return 0.0
    v = [x / nv for x in v]
    Av = Mv(v)
    lam_max_deflated = sum(v[i] * Av[i] for i in range(n))
    return 2.0 - lam_max_deflated       # = smallest nonzero eigenvalue of L


# --------------------------------------------------------------------- controls
def run_controls():
    ok = True
    # POSITIVE: complete graph K_n has normalised-Laplacian gap exactly n/(n-1).
    print("POSITIVE CONTROL -- complete graph K_n, exact gap n/(n-1); the routine must find it:")
    for n in (4, 6, 8):
        A = [[0 if i == j else 1 for j in range(n)] for i in range(n)]
        got = normalised_laplacian_gap(A)
        want = n / (n - 1)
        good = abs(got - want) < 1e-6
        ok = ok and good
        print(f"   K_{n}: got {got:.6f}, exact {want:.6f}   {'OK' if good else '*** FAILED ***'}")
    # NEGATIVE: two disjoint triangles must give gap 0.
    print("\nNEGATIVE CONTROL -- disconnected graph, gap must be 0:")
    A = [[0] * 6 for _ in range(6)]
    for (i, j) in ((0, 1), (1, 2), (0, 2), (3, 4), (4, 5), (3, 5)):
        A[i][j] = A[j][i] = 1
    got = normalised_laplacian_gap(A)
    good = abs(got) < 1e-6
    ok = ok and good
    print(f"   two disjoint triangles: got {got:.2e}   {'OK' if good else '*** FAILED ***'}")
    return ok


def main():
    print("== Resonant-triad hypergraph: unconstrained baseline ==\n")
    if not run_controls():
        print("\nCONTROLS FAILED -- refusing to report any lattice measurement.")
        sys.exit(1)
    print("\n   controls pass. Instrument validated.\n")

    print(f"{'M':>3} {'|Lambda|':>9} {'triads':>10} {'<deg>':>10} {'gap(2-section)':>16}")
    for M in (2, 3, 4):
        pts = lattice(M)
        tri = triads(pts)
        deg = degrees(pts, tri)
        avg = Q(sum(deg.values()), len(pts))          # exact
        A = two_section(pts, tri)
        gap = normalised_laplacian_gap(A)
        print(f"{M:>3} {len(pts):>9} {len(tri):>10} {float(avg):>10.1f} {gap:>16.6f}")

    print("\nBaseline only. No claim about depletion, gaps, or Navier-Stokes is made or implied;")
    print("the locked sub-hypergraph requires a definition that does not exist (OP-2, E-1).")


if __name__ == "__main__":
    main()
