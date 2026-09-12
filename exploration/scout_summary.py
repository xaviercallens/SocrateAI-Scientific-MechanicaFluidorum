# TIER C — EXPLORATORY, NO CLAIMS
"""Summarise dual_scale_scout CSV runs, and check step-halving agreement.

usage:
  python3 exploration/scout_summary.py summary  <run.csv> [...]
  python3 exploration/scout_summary.py halving  <run_dt.csv> <run_dt_over_2.csv> [tolerance]
  python3 exploration/scout_summary.py transient <run.csv> [...]

`summary` prints, per run: initial E, Z (= D), D2, the two production ratios; the transient
enstrophy amplification Z_max / Z_0 and its time; and the final row.
`halving` aligns the two runs on common times and prints the max relative difference of E and Z
up to each sampled time -- the READABLE horizon is where that difference stays below the
tolerance (default 0.02). Per the registration, nothing is read beyond it.
"""
import sys


def load(path):
    rows = []
    header = None
    meta = None
    for line in open(path):
        line = line.strip()
        if line.startswith("=="):
            meta = line
            continue
        if line.startswith("step,"):
            header = line.split(",")
            continue
        if not line:
            continue
        vals = line.split(",")
        rows.append({h: (int(v) if h == "step" else float(v)) for h, v in zip(header, vals)})
    return meta, rows


def summary(paths):
    for p in paths:
        meta, rows = load(p)
        r0, rl = rows[0], rows[-1]
        zmax = max(rows, key=lambda r: r["D"])
        has_d2 = "D2" in r0
        print(f"\n{meta}")
        print(f"  t=0    : E {r0['E']:.4e}  Z {r0['D']:.4e}"
              + (f"  D2 {r0['D2']:.4e}  P/(nu D2) {r0['ratio_enstrophy']:+.3f}" if has_d2 else "")
              + f"  P/(nu D) {r0.get('ratio_energy', r0.get('ratio')):+.3f}")
        print(f"  Z peak : Z_max/Z_0 = {zmax['D'] / r0['D']:.4f} at t = {zmax['t']:.3f}"
              f"   (E there {zmax['E']:.4e})")
        print(f"  t={rl['t']:<5}: E {rl['E']:.4e}  Z {rl['D']:.4e}"
              + (f"  P/(nu D2) {rl['ratio_enstrophy']:+.4f}" if has_d2 else "")
              + f"  P/(nu D) {rl.get('ratio_energy', rl.get('ratio')):+.4f}")


def transient(paths):
    """One line per run: the S-2 observables of the early transient.

    ratio0     : P/(nu D2) at t = 0 (> 1 means enstrophy rising initially)
    t_dephase  : first sampled time at which P changes sign (the alignment's lifetime)
    Zmax/Z0, t : transient enstrophy amplification and where it peaks
    dZ_inj/Z0  : the enstrophy the production injects before dephasing, as a fraction of Z0,
                 integrated by the trapezoid rule on the sampled P (2P is dZ/dt's production part)
    Z(t=1)/Z0  : enstrophy left at t = 1, for the decay-rate comparison across M
    """
    print(f"{'M':>3} {'ic':>4} {'lam':>6} {'ratio0':>8} {'t_dephase':>10} {'Zmax/Z0':>9} {'t_peak':>7}"
          f" {'dZinj/Z0':>9} {'Z(1)/Z0':>8}")
    for p in paths:
        meta, rows = load(p)
        tag = dict(kv.split("=") for kv in meta.strip("= ").split() if "=" in kv)
        r0 = rows[0]
        zmax = max(rows, key=lambda r: r["D"])
        sign0 = 1 if r0["P_re"] > 0 else -1
        t_deph, inj = None, 0.0
        for a, b in zip(rows, rows[1:]):
            if (b["P_re"] > 0) != (sign0 > 0):
                t_deph = b["t"]
                break
            inj += (a["P_re"] + b["P_re"]) * (b["t"] - a["t"])   # 2P integrated
        z1 = next((r for r in rows if abs(r["t"] - 1.0) < 1e-9), None)
        print(f"{tag['M']:>3} {tag['ic']:>4} {float(tag['lambda']):>+6.2f} {r0['ratio_enstrophy']:>+8.3f}"
              f" {t_deph if t_deph is not None else float('nan'):>10.3f} {zmax['D'] / r0['D']:>9.4f}"
              f" {zmax['t']:>7.3f} {inj / r0['D']:>+9.4f}"
              f" {(z1['D'] / r0['D']) if z1 else float('nan'):>8.4f}")


def halving(a, b, tol):
    ma, ra = load(a)
    mb, rb = load(b)
    tb = {round(r["t"], 6): r for r in rb}
    print(f"\nA: {ma}\nB: {mb}")
    print(f"  {'t':>8} {'relE':>10} {'relZ':>10}   readable(tol={tol})")
    worst_e = worst_z = 0.0
    horizon = None
    for r in ra:
        t = round(r["t"], 6)
        if t not in tb:
            continue
        s = tb[t]
        re = abs(r["E"] - s["E"]) / max(abs(s["E"]), 1e-300)
        rz = abs(r["D"] - s["D"]) / max(abs(s["D"]), 1e-300)
        worst_e, worst_z = max(worst_e, re), max(worst_z, rz)
        ok = worst_e <= tol and worst_z <= tol
        if ok:
            horizon = t
        print(f"  {t:8.3f} {re:10.2e} {rz:10.2e}   {'yes' if ok else 'NO'}")
    print(f"  READABLE HORIZON (both E and Z within {tol} so far): t <= {horizon}")


if __name__ == "__main__":
    mode = sys.argv[1]
    if mode == "summary":
        summary(sys.argv[2:])
    elif mode == "transient":
        transient(sys.argv[2:])
    elif mode == "halving":
        halving(sys.argv[2], sys.argv[3], float(sys.argv[4]) if len(sys.argv) > 4 else 0.02)
    else:
        print(__doc__)
