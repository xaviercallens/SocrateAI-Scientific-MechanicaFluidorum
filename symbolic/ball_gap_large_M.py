#!/usr/bin/env python3
"""Ball-truncation 2-section gap at M=6,7 -- the 5/6-conjecture stress test.

Combinatorics (lattice, triads, 2-section) exact integers (Tier B machinery, imported from
symbolic/triad_hypergraph.py); the eigenvalue itself is float power iteration (Tier C, as
LEDGER already records for M=2..5).

WHY: TriadTorus.lean (Tier A, 2026-08-14) proves the TORUS gap tends to 1, so the measured
ball gap ~5/6 is a pure boundary invariant of the sphere cutoff. The conjecture "gap -> 5/6"
so far rests on M=2..5 (0.834985, 0.833575, 0.833419, 0.833392; deviations 1.7e-3, 2.4e-4,
8.6e-5, 5.9e-5). Two more points either continue the monotone decrease toward 5/6 = 0.8333...
or expose a different limit. Controls are replayed before measuring (LL-12).

Raw numbers only; no verdict (SPEC 8).
"""

import sys
import time
sys.path.insert(0, __file__.rsplit("/", 1)[0])
from triad_hypergraph import lattice, triads, two_section, normalised_laplacian_gap, run_controls

if not run_controls():
    print("CONTROLS FAILED -- refusing to measure.")
    sys.exit(1)

print("\ncontrols pass. Ball gap at larger M (5/6 = 0.833333...):\n")
print(f"{'M':>3} {'|Lambda|':>9} {'triads':>10} {'gap':>10} {'gap - 5/6':>11} {'secs':>7}")
for M in (6, 7):
    t0 = time.time()
    pts = lattice(M)
    tri = triads(pts)
    A = two_section(pts, tri)
    gap = normalised_laplacian_gap(A, iters=600)
    dt = time.time() - t0
    print(f"{M:>3} {len(pts):>9} {len(tri):>10} {gap:>10.6f} {gap - 5.0/6.0:>+11.2e} {dt:>7.0f}",
          flush=True)

print("\nRaw numbers only; interpretation and any LEDGER update belong to the owner's review.")
