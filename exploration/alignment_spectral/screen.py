# TIER C — EXPLORATORY, NO CLAIMS. Optimiser screen of docs/designs/SPECTRAL_ALIGNMENT.md §3.2(C).
"""Fixed-budget optimiser screen (after karpathy/autoresearch), design fixed BEFORE the first row
by a three-lens proposal round and a judge pass (memo §3.2(C)). It chooses the optimiser that runs
at M = 32 and then M = 64; it produces no scientific result.

    python3 exploration/alignment_spectral/screen.py OUTDIR            # full M=16 screen
    python3 exploration/alignment_spectral/screen.py --selftest        # C6 only

Rows, in order: C3 (M=8 evaluator known value), C1 (B0 reference), H1..H10, C4 (corrupted
signs), C2 (B0 re-run). Every row: search under a 60 s wall budget -> exact i128 |S| of the
returned signs -> exact greedy polish (the immutable evaluator, `--align free --phases-start`).
The criterion below is the judge's, transcribed; `label()` is the only place it lives and C6
tests it on a synthetic table before any real row is labelled.
"""
import os, re, subprocess, sys, time, pathlib, json

REPO = pathlib.Path(__file__).resolve().parents[2]
SCOUT = ["cargo", "run", "--quiet", "--release", "--manifest-path",
         str(REPO / "exploration/dual_scale_scout_rs/Cargo.toml"), "--", "scout"]
COMMON = ["--ic", "adv", "--nu", "0.05", "--dt", "0.00025", "--steps", "0", "--every", "1",
          "--lambda", "-0.05", "--E0", "144"]
BUDGET_S = 60
EPS_INV = 100000                                   # tie band eps = 1e-5, tested in integers
Q0_EXPECTED_M16 = 17175910896716672                # committed B0 M=16 (S5_M16_phases_jacobi.txt)
S_EXPECTED_M8 = 822566075728                       # greedy == B0 at M=8
GREEDY_M8 = REPO / "exploration/scout_runs/S5_M8_phases_jacobi.txt"   # byte-identical to the greedy's
B0_W_SOLO = 18.9

HYPOTHESES = [   # (id, role, flags, description)
    ("H1", "control",   ["--rank", "delta"], "identity control: rank delta == rank gain here (F1), must be byte-identical to C1"),
    ("H2", "candidate", ["--rho", "0.02"], "small starting step"),
    ("H3", "candidate", ["--rho-max", "0.15"], "lower cap: late overshoot is cap-driven"),
    ("H4", "candidate", ["--rho-grow", "1.1"], "slower growth"),
    ("H5", "control",   ["--rho-max", "1.0"], "damping negative control: must visibly degrade"),
    ("H6", "candidate", ["--tabu", "3"], "tabu 3 (F3-fixed)"),
    ("H7", "variance",  ["--init", "random:1"], "random start seed 1"),
    ("H8", "variance",  ["--init", "random:2"], "random start seed 2"),
    ("H9", "candidate", ["--init", f"lift:{GREEDY_M8}"], "coarse-to-fine lift of the M=8 optimum; M=8 evaluations charged /8"),
    ("H10", "candidate", ["--anneal-tau", "1e-3", "--anneal-decay", "0.9"], "mild annealing (F2: does not remove retries)"),
]
DAMPING_AXIS = {"H3", "H4"}

# ------------------------------------------------------------------ the criterion (judge, verbatim in code)

def status_of(r, F0):
    if r.get("crash"): return "crash"
    if r.get("invalid"): return "invalid"
    if r["jstatus"] == "converged" and r["polish_flips"] > 0: return "false-converged"
    if r["jstatus"] in ("budget", "max-iter", "float-floor"): return "budget"
    if r["fails"] > 3 * max(F0, 1) or r["fails"] > 0.5 * r["evals"]: return "thrashing"
    return "converged"

def quality(Q, Q0, seed_spread_exceeds_eps):
    if EPS_INV * (Q - Q0) > Q0: return "tie" if seed_spread_exceeds_eps else "better"
    if EPS_INV * (Q0 - Q) > Q0: return "worse"
    return "tie"

def cost(C, E0, sweeps, P0):
    if C <= 0.9 * E0 and sweeps <= P0: return "cheaper"
    if C > 1.1 * E0 or sweeps > P0: return "costlier"
    return "cost-tie"

def label(status, q, c, damping_voided=False):
    if status != "converged" or damping_voided: return "INCONCLUSIVE"
    if q == "worse" or (q == "tie" and c == "costlier"): return "DISCARD"
    if q in ("tie", "better") and (c == "cheaper" or (q == "better" and c == "cost-tie")): return "KEEP"
    return "TIE"

def selftest():
    """C6: every synthetic row must get its expected label, incl. integer ties exactly at eps."""
    Q0, E0, P0, F0 = 10**11, 100, 1, 5
    base = dict(jstatus="converged", polish_flips=0, fails=2, evals=100)
    cases = [
        (dict(base, crash=True), Q0, 100, 1, "INCONCLUSIVE"),
        (dict(base, jstatus="budget"), Q0, 100, 1, "INCONCLUSIVE"),
        (dict(base, polish_flips=3), Q0, 100, 2, "INCONCLUSIVE"),           # false-converged
        (dict(base, fails=16), Q0, 100, 1, "INCONCLUSIVE"),                 # thrashing (> 3*F0)
        (dict(base, fails=60, evals=100), Q0, 100, 1, "INCONCLUSIVE"),      # thrashing (> 50 %)
        (base, Q0 + Q0 // EPS_INV, 80, 1, "KEEP"),      # exactly +eps -> tie (not better); cheaper -> KEEP
        (base, Q0 + Q0 // EPS_INV + 1, 100, 1, "KEEP"), # just above eps -> better; cost-tie -> KEEP
        (base, Q0 - Q0 // EPS_INV, 100, 1, "TIE"),      # exactly -eps -> tie; cost-tie -> TIE
        (base, Q0 - Q0 // EPS_INV - 1, 50, 1, "DISCARD"),  # just below -eps -> worse
        (base, Q0, 120, 1, "DISCARD"),                  # tie + costlier (evals)
        (base, Q0, 80, 2, "DISCARD"),                   # tie + costlier (polish sweeps)
        (base, Q0 + Q0 // 1000, 120, 1, "TIE"),         # better + costlier
        (base, Q0, 90, 1, "KEEP"),                      # C = 0.9 E0 exactly is cheaper
        (base, Q0, 110, 1, "TIE"),                      # C = 1.1 E0 exactly is cost-tie
    ]
    bad = 0
    for i, (r, Q, C, sw, want) in enumerate(cases):
        st = status_of(r, F0)
        got = label(st, quality(Q, Q0, False), cost(C, E0, sw, P0))
        ok = got == want; bad += not ok
        print(f"  C6 case {i:2d}: status={st:<16} want {want:<12} got {got:<12} {'ok' if ok else 'MISLABELED'}")
    # the seed-spread downgrade
    got = quality(Q0 + Q0 // 1000, Q0, True); ok = got == "tie"; bad += not ok
    print(f"  C6 case spread: better downgraded to tie -> {got} {'ok' if ok else 'MISLABELED'}")
    # the damping-axis void
    got = label("converged", "tie", "cheaper", damping_voided=True); ok = got == "INCONCLUSIVE"; bad += not ok
    print(f"  C6 case damping-void: {got} {'ok' if ok else 'MISLABELED'}")
    print("  C6:", "PASS" if bad == 0 else f"FAIL ({bad} mislabeled)")
    return bad == 0

# ------------------------------------------------------------------ running rows

def sh(cmd, log):
    t0 = time.time()
    with open(log, "w") as fh:
        rc = subprocess.call(cmd, stdout=fh, stderr=subprocess.STDOUT, cwd=REPO)
    return rc, time.time() - t0

def signs_of(path):
    return [l.split()[3] for l in open(path) if not l.startswith("#")]

def evaluate(out, rid, M, seed_path):
    """The immutable evaluator: exact |S| of the seed, then the exact greedy polish."""
    pol = out / f"{rid}_M{M}_polished.txt"; plog = out / f"{rid}_M{M}_polish.log"
    rc, pwall = sh(SCOUT + ["--M", str(M), "--align", "free", "--phases-start", str(seed_path),
                            "--phases-out", str(pol)] + COMMON, plog)
    t = plog.read_text()
    m = re.search(r"initial exact \|S\| = (\d+)", t); sw = re.findall(r"sweep (\d+) done, best=(\d+)", t)
    if rc != 0 or not m or not sw: return None
    flips = sum(a != b for a, b in zip(signs_of(seed_path), signs_of(pol)))
    return dict(S_pre=int(m[1]), Q=int(sw[-1][1]), sweeps=int(sw[-1][0]), polish_flips=flips, polish_wall=pwall)

def search(out, rid, M, flags):
    ph = out / f"{rid}_M{M}_phases.txt"; log = out / f"{rid}_M{M}_jacobi.log"
    load = os.getloadavg()[0]
    rc, wall = sh(SCOUT + ["--M", str(M), "--align", "jacobi", "--budget-s", str(BUDGET_S),
                           "--phases-out", str(ph)] + COMMON + flags, log)
    t = log.read_text()
    fin = re.search(r"final \|P\|=([0-9.e+-]+) after (\d+) iterations, (\d+) flips, ([0-9.]+) s, status=([\w-]+)", t)
    acc = re.search(r"accounting: gradients=(\d+) objective_evals=(\d+) failed_steps=(\d+) iter_to_99.9%=(\d+)", t)
    if rc != 0 or not fin or not acc: return dict(id=rid, crash=True, load=load)
    r = dict(id=rid, P=float(fin[1]), iters=int(fin[2]), flips=int(fin[3]), wall=float(fin[4]), jstatus=fin[5],
             grads=int(acc[1]), objs=int(acc[2]), fails=int(acc[3]), it999=int(acc[4]), load=load, phases=str(ph))
    r["evals"] = r["grads"] + r["objs"]
    fail_iters = sorted({int(x) for x in re.findall(r"iter\s+(\d+): \|P\|", t)})
    r["trace_sig"] = [l for l in t.splitlines() if "[align/jacobi] iter" in l and ": |P|=" in l]
    r["trace_sig"] = [re.sub(r"\([0-9.]+ s\)", "", l) for l in r["trace_sig"]]   # wall stripped: identity is on the numbers
    ev = evaluate(out, rid, M, ph)
    if ev is None: r["crash"] = True; return r
    r.update(ev)
    return r

def stage2(out16, out):
    """M = 32 stage: the registered advancing rows + a B0 reference, 30 min search budget each,
    criterion re-applied against the reference, transfer check C/E0(32) <= C/E0(16) + 0.15.
    Post-hoc rows (declared after the M=16 result) are reported but never eligible."""
    global BUDGET_S
    BUDGET_S = 1800
    M = 32
    out.mkdir(parents=True, exist_ok=True)
    adv = json.load(open(out16 / "advance.json"))
    ce16 = {}
    for line in open(out16 / "results.tsv").read().splitlines()[1:]:
        f = line.split("\t"); ce16[f[0]] = float(f[10])
    rows = [dict(id=a["id"], flags=a["flags"].split(), posthoc=False) for a in adv]
    rows.append(dict(id="H3+H4", flags=["--rho-max", "0.15", "--rho-grow", "1.1"], posthoc=True))
    verdict = []
    say = lambda s: (print(s, flush=True), verdict.append(s))
    B0_PHASES_M32 = REPO / "exploration/scout_runs/S5_M32_phases_jacobi.txt"
    GREEDY_M32 = REPO / "exploration/scout_runs/S4_M32_phases.txt"
    g = signs_of(GREEDY_M32)
    say("== R: B0 reference, M=32 ==")
    ref = search(out, "R", M, [])
    ok = not ref.get("crash") and open(ref["phases"]).read() == B0_PHASES_M32.read_text() and ref["polish_flips"] == 0
    Q0, E0, P0, F0 = ref.get("Q"), ref.get("evals"), ref.get("sweeps"), ref.get("fails")
    say(f"  R Q0={Q0} E0={E0} F0={F0} P0={P0} iters={ref.get('iters')} wall={ref.get('wall')} reproduces committed M=32 B0: {'PASS' if ok else 'FAIL'}")
    void = [] if ok else ["R does not reproduce the committed M=32 B0 phases"]
    table = []
    for r in rows:
        res = search(out, r["id"].replace("+", "_"), M, r["flags"]); res.update(id=r["id"], flags=" ".join(r["flags"]), posthoc=r["posthoc"])
        if res.get("crash"):
            res.update(status="crash", label="INCONCLUSIVE"); table.append(res); say(f"  {r['id']}: CRASH"); continue
        res["C"] = res["evals"]; res["status"] = status_of(res, F0)
        res["q"] = quality(res["Q"], Q0, False); res["c"] = cost(res["C"], E0, res["sweeps"], P0)
        res["label"] = label(res["status"], res["q"], res["c"])
        res["transfer"] = "n/a" if r["posthoc"] else ("ok" if res["C"] / E0 <= ce16.get(r["id"], 0) + 0.15 else "FAIL")
        res["vs_greedy"] = sum(a != b for a, b in zip(signs_of(res["phases"]), g))
        table.append(res)
        say(f"  {r['id']}{' (POST-HOC)' if r['posthoc'] else ''}: status={res['status']} iters={res['iters']} C={res['C']} C/E0={res['C']/E0:.3f} fails={res['fails']} Q={res['Q']} Q/Q0-1={(res['Q']-Q0)/Q0:+.3e} sweeps={res['sweeps']} polish_flips={res['polish_flips']} signs!=greedy={res['vs_greedy']} quality={res['q']} cost={res['c']} label={res['label']} transfer={res['transfer']} wall={res['wall']}")
    elig = [t for t in table if not t.get("posthoc") and t.get("label") == "KEEP" and t.get("transfer") == "ok"]
    elig.sort(key=lambda t: (t["C"] / E0, -t["Q"]))
    say("\n== TO M=64 ==\n  " + (f"{elig[0]['id']}: {elig[0]['flags']}" if elig else "B0 (no eligible KEEP row at M=32)"))
    say("== VOID ==\n  " + ("; ".join(void) if void else "none"))
    (out / "verdict.txt").write_text("\n".join(verdict) + "\n")

def main():
    if "--selftest" in sys.argv:
        sys.exit(0 if selftest() else 1)
    if "--stage2" in sys.argv:
        i = sys.argv.index("--stage2")
        stage2(pathlib.Path(sys.argv[i + 1]), pathlib.Path(sys.argv[i + 2])); return
    out = pathlib.Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
    verdict = []; void = []; partial = []
    say = lambda s: (print(s, flush=True), verdict.append(s))

    say("== C6 criterion self-test ==");
    if not selftest(): void.append("C6 mislabeled a synthetic row")

    say("== C3 evaluator known value, M=8 ==")
    c3 = search(out, "C3", 8, [])
    ok = (not c3.get("crash") and c3["S_pre"] == S_EXPECTED_M8 and c3["iters"] == 16
          and open(c3["phases"]).read() == GREEDY_M8.read_text())
    say(f"  C3 |S|={c3.get('S_pre')} iters={c3.get('iters')} evals={c3.get('evals')} -> {'PASS' if ok else 'FAIL'}")
    if not ok: void.append("C3")

    M = 16
    say("== C1 B0 reference, M=16 ==")
    c1 = search(out, "C1", M, [])
    Q0, E0, F0, P0, W0 = c1.get("Q"), c1.get("evals"), c1.get("fails"), c1.get("sweeps"), c1.get("wall")
    ok = (not c1.get("crash") and c1["S_pre"] == Q0_EXPECTED_M16 and Q0 == Q0_EXPECTED_M16
          and c1["polish_flips"] == 0 and c1["iters"] == 71)
    say(f"  C1 Q0={Q0} E0={E0} F0={F0} P0={P0} W0={W0} iters={c1.get('iters')} load={c1['load']:.2f} -> {'PASS' if ok else 'FAIL'}")
    if not ok: void.append("C1");
    if W0 and abs(W0 / B0_W_SOLO - 1) > 0.20: partial.append(f"timings void: W0={W0} vs solo {B0_W_SOLO}")
    Pconst = c1["P"] / c1["S_pre"] if not c1.get("crash") else None

    rows = {}
    for hid, role, flags, desc in HYPOTHESES:
        r = search(out, hid, M, flags); r.update(role=role, desc=desc, flags=" ".join(flags))
        if not r.get("crash"):
            dev = abs(r["P"] / r["S_pre"] / Pconst - 1)
            r["C5_dev"] = dev
            if dev > 1e-9: r["invalid"] = True
        rows[hid] = r
        say(f"  {hid} done: " + ("CRASH" if r.get("crash") else
            f"status={r['jstatus']} iters={r['iters']} evals={r['evals']} fails={r['fails']} S_pre={r['S_pre']} Q={r['Q']} sweeps={r['sweeps']} polish_flips={r['polish_flips']} wall={r['wall']} load={r['load']:.2f}"))

    say("== C4 corrupted signs (C1 signs, indices 0..39 flipped) ==")
    lines = open(c1["phases"]).read().splitlines()
    for i in range(1, 41):
        a = lines[i].split(); a[3] = str(-int(a[3])); lines[i] = " ".join(a)
    cor = out / "C4_M16_phases.txt"; cor.write_text("\n".join(lines) + "\n")
    c4 = evaluate(out, "C4", M, cor)
    c4_lab = label("converged", quality(c4["Q"], Q0, False), cost(0, E0, c4["sweeps"], P0)) if c4 else None
    ok = c4 and c4["S_pre"] < Q0 and c4["polish_flips"] >= 1 and c4_lab != "KEEP"
    say(f"  C4 S_pre={c4 and c4['S_pre']} Q={c4 and c4['Q']} polish_flips={c4 and c4['polish_flips']} label={c4_lab} -> {'PASS' if ok else 'FAIL'}")
    if not ok: void.append("C4")

    say("== C2 B0 re-run ==")
    c2 = search(out, "C2", M, [])
    ok = (not c2.get("crash") and open(c2["phases"]).read() == open(c1["phases"]).read() and c2["Q"] == Q0
          and c2["iters"] == c1["iters"] and c2["evals"] == E0 and c2["trace_sig"] == c1["trace_sig"])
    say(f"  C2 identical to C1: {'PASS' if ok else 'FAIL'}  wall={c2.get('wall')}")
    if not ok: void.append("C2")
    if c2.get("wall") and W0 and abs(c2["wall"] / W0 - 1) > 0.20: partial.append(f"timings void: C2 wall {c2['wall']} vs W0 {W0}")

    # H1 identity
    h1 = rows["H1"]
    ok = (not h1.get("crash") and open(h1["phases"]).read() == open(c1["phases"]).read() and h1["Q"] == Q0
          and h1["iters"] == c1["iters"] and h1["evals"] == E0 and h1["trace_sig"] == c1["trace_sig"])
    rows["H1"]["control"] = "PASS" if ok else "FAIL"
    if not ok: void.append("H1 identity")
    # C5 on every row
    for r in rows.values():
        if r.get("invalid"): void.append(f"C5 on {r['id']} (dev {r['C5_dev']:.2e})")
    # seed spread
    h7, h8 = rows["H7"], rows["H8"]
    spread = (not h7.get("crash") and not h8.get("crash") and EPS_INV * abs(h7["Q"] - h8["Q"]) > Q0)
    # H5 damping control
    h5 = rows["H5"]
    if h5.get("crash"): damping_voided = True; rows["H5"]["control"] = "FAIL (crash)"
    else:
        degraded = (h5["fails"] >= 8 and h5["evals"] >= 1.1 * E0) or quality(h5["Q"], Q0, False) == "worse" or status_of(h5, F0) != "converged"
        falsified = h5["fails"] <= 5 and h5["evals"] <= E0 and quality(h5["Q"], Q0, False) != "worse"
        damping_voided = falsified
        rows["H5"]["control"] = "PASS (degraded)" if degraded else ("FAIL (damping premise falsified)" if falsified else "NEITHER")
        if falsified: partial.append("H5 did not degrade: H3, H4 INCONCLUSIVE")
    false_conv = [r["id"] for r in rows.values() if not r.get("crash") and r["jstatus"] == "converged" and r["polish_flips"] > 0]
    if len(false_conv) > 1: void.append(f"more than one false-converged row: {false_conv}")

    # labels
    prior_M8 = c3.get("evals", 0) / 8
    table = []
    for hid, r in rows.items():
        if r.get("crash"):
            r.update(status="crash", q="-", c="-", label="INCONCLUSIVE" if r["role"] == "candidate" else "FAIL"); table.append(r); continue
        C = r["evals"] + (prior_M8 if hid == "H9" else 0)
        r["C"] = C
        r["status"] = status_of(r, F0)
        r["q"] = quality(r["Q"], Q0, spread)
        r["c"] = cost(C, E0, r["sweeps"], P0)
        if r["role"] == "candidate":
            r["label"] = label(r["status"], r["q"], r["c"], damping_voided and hid in DAMPING_AXIS)
        else:
            r["label"] = r.get("control", "reported")
        wall_flag = ""
        if W0 and E0 and r["wall"] > 0 and abs((r["wall"] / r["evals"]) / (W0 / E0) - 1) > 0.25: wall_flag = "timing-flag"
        r["wall_flag"] = wall_flag
        table.append(r)

    say("\n== RESULTS (M=16; Q0=%d E0=%d F0=%d P0=%d W0=%s) ==" % (Q0, E0, F0, P0, W0))
    hdr = "id\trole\tflags\tstatus\titers\tit99.9\tgrads\tobjs\tfails\tC\tC/E0\tS_pre\tQ\tQ/Q0-1\tsweeps\tpolish_flips\twall_s\tload\tquality\tcost\tlabel\tnote"
    say(hdr)
    tsv = [hdr]
    for r in table:
        if r.get("crash") and "iters" not in r:
            line = f"{r['id']}\t{r['role']}\t{r['flags']}\tcrash" + "\t" * 17 + f"\t{r['label']}\t"
        else:
            line = "\t".join(map(str, [r["id"], r["role"], r["flags"], r["status"], r["iters"], r["it999"], r["grads"], r["objs"], r["fails"],
                     f"{r.get('C', 0):.1f}", f"{r.get('C', 0) / E0:.3f}", r["S_pre"], r["Q"], f"{(r['Q'] - Q0) / Q0:+.3e}", r["sweeps"], r["polish_flips"],
                     r["wall"], f"{r['load']:.2f}", r["q"], r["c"], r["label"], r.get("wall_flag", "")]))
        say(line); tsv.append(line)
    (out / "results.tsv").write_text("\n".join(tsv) + "\n")

    # advancement to M=32 (judge's rule)
    cand = [r for r in table if r["role"] == "candidate" and r["label"] in ("KEEP", "TIE")]
    key = lambda r: (r["C"] / E0, -r["Q"], r["sweeps"], int(r["id"][1:]))
    keeps = sorted([r for r in cand if r["label"] == "KEEP"], key=key)
    ties = sorted([r for r in cand if r["label"] == "TIE"], key=key)
    slots = keeps[:2]
    if len(keeps) >= 2 and keeps[0]["flags"].split()[0] != keeps[1]["flags"].split()[0]:
        slots.append(dict(id=f"{keeps[0]['id']}+{keeps[1]['id']}", flags=keeps[0]["flags"] + " " + keeps[1]["flags"], combo=True))
    else:
        slots += keeps[2:3]
    for t in ties:
        if len(slots) >= 3: break
        slots.append(t)
    say("\n== ADVANCE TO M=32 (30 min each, plus B0 M=32 reference) ==")
    for s in slots: say(f"  {s['id']}: {s['flags']}")
    if not slots: say("  none -- B0 is the default optimiser")
    say("\n== VOID ==\n  " + ("; ".join(void) if void else "none"))
    say("== PARTIAL VOIDS ==\n  " + ("; ".join(partial) if partial else "none"))
    (out / "verdict.txt").write_text("\n".join(verdict) + "\n")
    (out / "advance.json").write_text(json.dumps([dict(id=s["id"], flags=s["flags"]) for s in slots], indent=1))

if __name__ == "__main__":
    main()
