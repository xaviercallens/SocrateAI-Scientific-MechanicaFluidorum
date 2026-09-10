#!/usr/bin/env python3
# TIER C — EXPLORATORY, NO CLAIMS — NEVER GATES A CLAIM
"""Plot and tabulate the D(M) sweep produced by exploration/triad_frustration_rs.

Reads dm_readings.csv (three readings on fields) and dm_waleffe.csv (pure-geometry reading (c)),
fits log D vs log M on M >= MFIT for each (gamma, field, reading), prints the slope table, and
writes a PNG. The random-phase rows (several seeds) are combined by geometric mean with the
min/max spread as the band. Verdicts are reserved to the owner (PLAN.md section 2).
"""
import csv, math, sys, os
from collections import defaultdict

MFIT = 8

def load(path):
    with open(path) as f:
        return list(csv.DictReader(f))

def fit_slope(xs, ys):
    pts = [(math.log(x), math.log(y)) for x, y in zip(xs, ys) if x >= MFIT and y > 0 and math.isfinite(y)]
    if len(pts) < 3:
        return float("nan"), len(pts)
    n = len(pts)
    mx = sum(p[0] for p in pts) / n
    my = sum(p[1] for p in pts) / n
    sxx = sum((p[0] - mx) ** 2 for p in pts)
    sxy = sum((p[0] - mx) * (p[1] - my) for p in pts)
    return sxy / sxx, n

def main(out_dir):
    rows = load(os.path.join(out_dir, "dm_readings.csv"))
    # group: (gamma, field) -> M -> list of rows (seeds)
    g = defaultdict(lambda: defaultdict(list))
    for r in rows:
        g[(float(r["gamma"]), r["field"])][int(r["M"])].append(r)
    readings = ["D_a", "D_b1", "D_b2"]
    print(f"slope of log D vs log M on M >= {MFIT}  (random: geometric mean over seeds)")
    print(f"{'gamma':>6} {'field':>12} " + " ".join(f"{k:>10}" for k in readings) + "   n_pts")
    series = {}
    for (gamma, field), byM in sorted(g.items()):
        Ms = sorted(byM)
        line = f"{gamma:6.3f} {field:>12} "
        for key in readings:
            ys = []
            lo, hi = [], []
            for M in Ms:
                vals = [float(r[key]) for r in byM[M]]
                gm = math.exp(sum(math.log(v) for v in vals) / len(vals)) if all(v > 0 for v in vals) else float("nan")
                ys.append(gm); lo.append(min(vals)); hi.append(max(vals))
            s, n = fit_slope(Ms, ys)
            series[(gamma, field, key)] = (Ms, ys, lo, hi)
            line += f" {s:10.3f}"
        line += f"   {n}"
        print(line)
    # Waleffe reading (c), per class
    wpath = os.path.join(out_dir, "dm_waleffe.csv")
    if os.path.exists(wpath):
        w = load(wpath)
        byc = defaultdict(list)
        for r in w:
            byc[r["class"]].append((int(r["M"]), float(r["D_c"]), float(r["sum_absC"]), abs(complex(float(r["sum_C_re"]), float(r["sum_C_im"])))))
        print("\nreading (c), Waleffe coefficients, per chirality class: slope of log D_c vs log M")
        for cls, pts in sorted(byc.items()):
            pts.sort()
            Ms = [p[0] for p in pts]; ys = [p[1] for p in pts]
            s, n = fit_slope(Ms, ys)
            last = pts[-1]
            print(f"  class {cls:>4}: slope {s:7.3f} (n={n}); at M={last[0]}: sum|C|={last[2]:.3e} |sumC|={last[3]:.3e} D_c={last[1]:.3e}")
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("matplotlib unavailable; table only"); return
    gammas = sorted({k[0] for k in series})
    fig, axes = plt.subplots(len(gammas), len(readings), figsize=(4.2 * len(readings), 3.6 * len(gammas)), squeeze=False)
    for i, gamma in enumerate(gammas):
        for j, key in enumerate(readings):
            ax = axes[i][j]
            anchor = None   # value of the RANDOM series at M = MFIT, used to place the guide line
            m_max = MFIT
            for (gm, field, k), (Ms, ys, lo, hi) in series.items():
                if gm != gamma or k != key:
                    continue
                ax.plot(Ms, ys, marker="o", ms=3, label=field)
                m_max = max(m_max, max(Ms))
                if field == "random":
                    ax.fill_between(Ms, lo, hi, alpha=0.2)
                    # anchor the guide to the null model itself, not to an arbitrary offset:
                    # a slope guide placed by hand invites eyeballing an agreement that is not there.
                    for M, y in zip(Ms, ys):
                        if M == MFIT and y > 0 and math.isfinite(y):
                            anchor = y
            if anchor is not None:
                xs = list(range(MFIT, m_max + 1))
                ax.plot(xs, [anchor * (x / MFIT) ** 3 for x in xs], "k--", lw=0.8,
                        label="slope 3 guide (anchored to random at M=%d)" % MFIT)
            ax.set_xscale("log"); ax.set_yscale("log")
            ax.set_title(f"{key}, γ={gamma:.3f}"); ax.set_xlabel("M"); ax.grid(True, which="both", alpha=0.3)
            if i == 0 and j == 0:
                ax.legend(fontsize=7)
    fig.suptitle("TIER C — D(M) three readings; null = random phases; no verdict", fontsize=10)
    fig.tight_layout()
    png = os.path.join(out_dir, "dm_readings.png")
    fig.savefig(png, dpi=130)
    print(f"\nwrote {png}")

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "data/triad_frustration")
