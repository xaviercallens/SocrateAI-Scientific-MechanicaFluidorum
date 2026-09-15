#!/usr/bin/env bash
# TIER C — EXPLORATORY, NO CLAIMS. Time-to-complete calibration for the exact evaluation at M,
# measured with the job's own binary on this machine -- a clock, not an extrapolation (LL-22).
#
# The job is three passes; each is timed where it actually runs:
#   A. class-set pass, run for real from scratch until it saturates (its true length is unknown
#      in advance: it stops once every class is present);
#   B. initial exact |S| pass: seconds per chunk at SIX positions across the ball (cost depends on
#      where the chunk sits), from the real checkpoint A leaves, with only the position edited;
#   C. sweep: classes per second at SIX positions, from the same checkpoint with `best` set out of
#      reach so no flip is accepted -- exactly the no-flip verification sweep the polish is
#      expected to be (the M=16 and M=32 seeds needed 0 flips).
# Nothing here is uploaded or used as a result; the probes' outputs are discarded.
#
#   bash exploration/gcp/calibrate_eval.sh M SEED WORKDIR
set -uo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
M=${1:?M}; SEED=${2:?seed}; W=${3:?workdir}
BIN="$REPO/exploration/dual_scale_scout_rs/target/release/dual_scale_scout"
rm -rf "$W"; mkdir -p "$W"
COMMON=(--M "$M" --ic adv --align free --phases-start "$SEED" --nu 0.05 --dt 0.0000025 --steps 0 --every 1 --lambda -0.05 --E0 144)
stamp() { while IFS= read -r l; do printf '%s %s\n' "$(date +%s.%N)" "$l"; done; }

echo "== A: class pass from scratch (load $(cut -d' ' -f1-3 /proc/loadavg))"
( "$BIN" scout "${COMMON[@]}" --ckpt "$W/a.ckpt" --ckpt-every-s 0 --phases-out "$W/a.out" 2>&1 >/dev/null | stamp > "$W/a.log" ) &
apid=$!
until [ "$(grep -c 'ckpt #[0-9]* phase=init chunk=' "$W/a.log" 2>/dev/null)" -ge 4 ]; do sleep 5; done
pkill -f "dual_scale_scout scout --M $M .*$W/a.ckpt"; wait "$apid" 2>/dev/null
grep -o "class set saturated.*" "$W/a.log" | sed 's/^/   /'

python3 - "$W" "$SEED" <<'PY'
import sys
W, seed = sys.argv[1], sys.argv[2]
def fnv64(b):
    h = 0xcbf29ce484222325
    for x in b:
        h ^= x
        h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF
    return h
lines = open(W + "/a.ckpt").read().split("\n")
prefix = " ".join(lines[0].split()[:6])          # "# mfckpt v2 M=.. chunks=.. seed=.."
mask = next(l for l in lines if l.startswith("MASK "))
signs = next(l for l in lines if l.startswith("SIGNS "))
n = len(signs) - len("SIGNS ")
chunks = int(prefix.split("chunks=")[1].split()[0])
def write(path, fields):
    body = prefix + " " + fields + "\n" + mask + "\n" + signs + "\n"
    open(path, "w").write(body + "END %016x\n" % fnv64(body.encode()))
for c in [int(chunks * f) for f in (0.2, 0.4, 0.6, 0.8)] + [chunks - 4]:
    write("%s/b_%d.ckpt" % (W, c), "phase=init chunk=%d sum=0" % c)
for i in [0, n // 5, 2 * n // 5, 3 * n // 5, 4 * n // 5, n - 6000]:
    write("%s/c_%d.ckpt" % (W, i), "phase=sweep sweep=1 i=%d s=0 best=%d improved=0 init=0 flips=0" % (i, 10**30))
open(W + "/n.txt", "w").write("%d %d\n" % (n, chunks))
PY

for f in "$W"/b_*.ckpt; do
  c=${f##*/b_}; c=${c%.ckpt}
  echo "== B: init pass at chunk $c"
  "$BIN" scout "${COMMON[@]}" --ckpt "$f" --ckpt-every-s 0 --die-after-saves 3 --phases-out "$W/b.out" 2>&1 >/dev/null | stamp > "$W/b_$c.log"
done
for f in "$W"/c_*.ckpt; do
  i=${f##*/c_}; i=${i%.ckpt}
  echo "== C: sweep at class $i"
  timeout 100 "$BIN" scout "${COMMON[@]}" --ckpt "$f" --ckpt-every-s 1000000 --phases-out "$W/c.out" 2>&1 >/dev/null | stamp > "$W/c_$i.log"
done

python3 - "$W" <<'PY'
import sys, glob, re, statistics as st
W = sys.argv[1]
n, chunks = map(int, open(W + "/n.txt").read().split())
def save_times(path, phase):
    out = []
    for l in open(path):
        m = re.match(r"(\S+) .*ckpt #\d+ phase=%s chunk=(\d+)" % phase, l)
        if m: out.append((float(m.group(1)), int(m.group(2))))
    return out
def per_chunk(ts):   # seconds per chunk from consecutive saves
    return [(b[0] - a[0]) / (b[1] - a[1]) for a, b in zip(ts, ts[1:]) if b[1] > a[1]]
a = open(W + "/a.log").read()
sat = re.search(r"saturated after (\d+)/(\d+)", a)
sat_chunks = int(sat.group(1)) if sat else chunks
cls_t = per_chunk(save_times(W + "/a.log", "classes"))
init_samples = {0: per_chunk(save_times(W + "/a.log", "init"))}
for f in glob.glob(W + "/b_*.log"):
    init_samples[int(re.search(r"b_(\d+)", f).group(1))] = per_chunk(save_times(f, "init"))
sweep_rates = {}
for f in glob.glob(W + "/c_*.log"):
    pts = [(float(m.group(1)), int(m.group(2))) for m in
           (re.match(r"(\S+) .*phase=sweep sweep=1 (\d+)/\d+ classes", l) for l in open(f)) if m]
    if len(pts) >= 2:
        sweep_rates[int(re.search(r"c_(\d+)", f).group(1))] = (pts[-1][1] - pts[0][1]) / (pts[-1][0] - pts[0][0])
print("\n== MEASURED on this machine (%s)" % open("/proc/cpuinfo").read().split("model name")[1].split("\n")[0].strip(": "))
cls_mean = st.mean(cls_t) if cls_t else float("nan")
print("class pass : %.1f s/chunk (n=%d), saturated after %d/%d chunks -> %.2f h" % (cls_mean, len(cls_t), sat_chunks, chunks, cls_mean * sat_chunks / 3600))
init_means = {c: st.mean(v) for c, v in init_samples.items() if v}
for c in sorted(init_means): print("init pass  : chunk %4d  %.1f s/chunk" % (c, init_means[c]))
init_mean = st.mean(init_means.values())
T_init = init_mean * chunks
print("init pass  : mean %.1f s/chunk (min %.1f, max %.1f) -> %.2f h" % (init_mean, min(init_means.values()), max(init_means.values()), T_init / 3600))
for i in sorted(sweep_rates): print("sweep      : class %6d  %.2f classes/s" % (i, sweep_rates[i]))
sw_mean = st.mean(sweep_rates.values())
T_sweep = n / sw_mean
print("sweep      : mean %.2f classes/s (min %.2f, max %.2f), n=%d -> %.2f h per sweep" % (sw_mean, min(sweep_rates.values()), max(sweep_rates.values()), n, T_sweep / 3600))
T1 = cls_mean * sat_chunks + T_init + T_sweep
print("\nTOTAL here, 1 sweep (expected: 0 polish flips) : %.1f h" % (T1 / 3600))
print("TOTAL here, 2 sweeps (if the seed needs flips)  : %.1f h" % ((T1 + T_sweep) / 3600))
open(W + "/estimate.txt", "w").write("%f %f %f %f %f\n" % (cls_mean * sat_chunks, T_init, T_sweep, T1, T1 + T_sweep))
PY
