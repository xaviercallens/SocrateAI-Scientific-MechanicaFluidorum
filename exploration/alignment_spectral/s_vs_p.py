# TIER C — EXPLORATORY, NO CLAIMS. Grounding experiment for docs/designs/SPECTRAL_ALIGNMENT.md section 2.
# S is exact integer; P comes from the floating-point scout via --phases-in. Run from the repo root:
#   python3 exploration/alignment_spectral/s_vs_p.py <outdir>   then scout each written phases file with --steps 0.
"""Is the greedy's integer objective S(sigma) the scout's t=0 production P, up to a
sigma-INDEPENDENT constant? If yes, the alignment can be optimised with the scout's own
FFT machinery (O(N log N) per gradient) instead of O(#triads) per sweep. Exact integers on the
S side; the scout supplies P. Three sign patterns; the ratio must be one number."""
import sys, pathlib
sys.path.insert(0, "tests")
from tier_b_adversarial_alignment import geometric_table, total_of, rep   # noqa: E402
from tier_b_fourier_enstrophy import ball                                 # noqa: E402

M = 8
OUT = pathlib.Path(sys.argv[1])
hb = [k for k in ball(M) if k != (0, 0, 0) and k > tuple(-x for x in k)]
table = geometric_table(M)
classes = sorted({c for a, b, c2, _, _ in table for c in (a, b, c2)})
print(f"M={M}: {len(table)} triads, {len(classes)} classes, {len(hb)} half-ball vectors")

def read_phases(path):
    s = {}
    for line in open(path):
        if line.startswith("#"): continue
        a, b, c, v = line.split()
        s[(int(a), int(b), int(c))] = int(v)
    return s

def write_phases(path, signs):
    with open(path, "w") as fh:
        fh.write(f"# scout adversarial phases M={M}\n")
        for k in hb:
            fh.write(f"{k[0]} {k[1]} {k[2]} {signs.get(k, 1)}\n")

def lcg(seed):
    x = (seed * 2654435761) % (2 ** 31)
    out = {}
    for k in hb:
        x = (1103515245 * x + 12345) % (2 ** 31)
        out[k] = 1 if (x >> 16) & 1 else -1
    return out

patterns = {
    "ones":   {k: 1 for k in hb},
    "greedy": read_phases(OUT / "M8_greedy_phases.txt"),
    "random": lcg(7),
}
for name, s in patterns.items():
    full = {c: s.get(c, 1) for c in classes}          # classes are half-ball reps
    S = total_of(table, full)
    write_phases(OUT / f"M8_{name}_phases.txt", s)
    print(f"{name:>7}: S = {S:>16d}   |S| = {abs(S):>15d}")
