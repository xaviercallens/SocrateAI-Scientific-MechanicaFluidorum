# TIER C — EXPLORATORY, NO CLAIMS. Control 1 of docs/designs/SPECTRAL_ALIGNMENT.md section 4.
"""Compare the scout's FFT gradient dP/dsigma_j (from `dual_scale_scout gradcheck`, stdout) with
the EXACT integer dS/dsigma_j from the Tier B objective table, class by class. Since P = c*S
with c independent of sigma, the ratio dP_j / dS_j must be ONE constant over j. A dropped
adjoint or a dropped reflection must break that constancy -- those are the negative controls.

usage: python3 gradcheck.py M phases.txt grad.txt
"""
import sys
sys.path.insert(0, "tests")
from tier_b_adversarial_alignment import geometric_table   # noqa: E402

M = int(sys.argv[1])
signs = {}
for line in open(sys.argv[2]):
    if line.startswith("#"): continue
    a, b, c, v = line.split(); signs[(int(a), int(b), int(c))] = int(v)
grad = {}
for line in open(sys.argv[3]):
    a, b, c, v = line.split(); grad[(int(a), int(b), int(c))] = float(v)

# dS/dsigma_j = sum over triads containing j (exactly once -- repeated classes have g = 0) of the
# product of the OTHER two signs times g. Exact integers.
table = geometric_table(M)
dS = {}
for a, b, c, g, _ in table:
    sa, sb, sc = signs[a], signs[b], signs[c]
    dS[a] = dS.get(a, 0) + sb * sc * g
    dS[b] = dS.get(b, 0) + sa * sc * g
    dS[c] = dS.get(c, 0) + sa * sb * g

ratios = []
for j, ds in dS.items():
    if ds == 0 or j not in grad: continue
    ratios.append((grad[j] / ds, j))
vals = [r for r, _ in ratios]
mean = sum(vals) / len(vals)
worst = max(abs(r / mean - 1.0) for r in vals)
print(f"M={M}: {len(vals)} classes with dS != 0")
print(f"  ratio dP/dS: mean {mean:.12e}   min {min(vals):.12e}   max {max(vals):.12e}")
print(f"  worst relative deviation from the mean: {worst:.3e}")
bad = sum(1 for r in vals if abs(r / mean - 1.0) > 1e-9)
print(f"  classes off by more than 1e-9 relative: {bad}")
print("  VERDICT:", "PASS -- one constant over j" if bad == 0 else "FAIL -- ratio is not constant")
