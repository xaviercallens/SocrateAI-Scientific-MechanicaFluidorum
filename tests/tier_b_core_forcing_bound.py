"""TIER B — the forcing bound T-2 of docs/designs/CORE_TAIL_CAP.md section 3, checked exactly.

REGISTRATION: CORE_TAIL_CAP.md section 3 (objects PROPOSED for owner adoption, rule E-1) and
section 5 (this evaluator's design). Ordered by the 2026-09-13 adjudication, whose Core-Tail
computer-assisted proof needs exactly one arithmetic primitive: a rigorous upper bound on the
nonlinear forcing of a single mode, computed without floating point.

WHAT THIS FILE DOES AND DOES NOT CLAIM. T-2 is a proposed object. This harness adopts nothing
and bounds no solution. It checks, in exact rational arithmetic, that the inequality as written
is TRUE on genuine Galerkin states, that each of the three steps it is assembled from is true
separately, and that the checker detects false variants of it. Whether T-2 is the right object
for the certificate is the owner's call; whether its arithmetic is sound is this file's.

THE STATEMENT, in the repo's own definitions (tier_b_fourier_enstrophy, which mirror
FourierDynamicsZ3):
    B(u,u)_k = applyLeray(k, sum_{p in ball} (-i)(q . u_p) u_q),   q = k - p,
    ||B(u,u)_k||  <=  sum_{p+q=k} |q| ||u_p|| ||u_q||.
Assembled from three steps, each checked separately here:
    (L)  Leray is an orthogonal projection, hence a contraction:  ||P_k v|| <= ||v||.
    (CS) Cauchy-Schwarz against an integer wavevector:  |q . v|^2 <= k_sq(q) * ||v||^2.
    (T)  the triangle inequality on the sum, with (CS) applied termwise.

NO SQUARE ROOT IS EVER TAKEN. Both |q| and ||u_p|| are irrational; each is replaced by a
rational upper bound whose validity is certified by an exact integer comparison (sqrt_upper),
which is precisely what the interval evaluator must do at scale, and why the certificate can be
exact. Every comparison in this file is between two exact Fractions.

TWO STRATA OF STATES, because one of them cannot test the bound. Random states make the
convolution sum incoherent, so the triangle inequality loses the usual square-root-of-the-term-
count and the bound is slack by a factor that GROWS with M for a reason that has nothing to do
with the bound's quality. The second stratum is therefore a coherent family -- states supported
on two wavevectors and their conjugates -- where the sum has a handful of terms that can align.
Only the coherent stratum can decide whether the |q| factor is load-bearing.

ON THE NEGATIVE CONTROLS, recorded because one of them behaved informatively rather than
correctively (the LL-12 precedent). The three structural controls -- drop the |q| factor, use
|p| instead, round the roots the wrong way -- do NOT break the inequality, at either stratum.
That is a measurement, not a defect: T-2 turns out to be loose by a factor of 2 to 3 even where
it is tightest, which is more than any of those perturbations removes. The control that
certifies the checker can fail is therefore NC-E, which scales the bound by 1/4; its constant
was chosen AFTER the tightness was measured, precisely because a sensitivity control must be
calibrated to the measured slack to be able to fail at all. NC-E tests the checker, not the
mathematics; NC-D (reversing the inequality) tests the comparison itself.

STOP REASON (LL-18): fixed lists, no adaptive search, no early exit. Random stratum: M = 2, 3, 4
with 4, 3, 1 states; every mode of every ball checked; at M = 4 the negative controls are not
re-run. Coherent stratum: M = 2, all ordered pairs of half-ball modes; M = 3, all ordered pairs
drawn from the outer shell k_sq = 9; nine fixed seed-vector combinations per pair; k restricted
to the finitely many wavevectors where B can be nonzero at all (verified exhaustively at M = 2
against the full ball). All of this is declared here, before any number was read.
"""

import pathlib
import sys
from fractions import Fraction
from math import isqrt

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from tier_b_fourier_enstrophy import (  # noqa: E402
    G, B, apply_leray, ball, check_state, fourier_dot, k_sq, make_state, sub, u_at,
)
from tier_b_production_cancellation import dec as _dec  # noqa: E402

BITS = 24                             # rational sqrt bounds certified to 2^-24
CASES = ((2, 4, True), (3, 3, True), (4, 1, False))   # (M, #states, run negative controls)


def dec(x, places=6):
    return _dec(x, places)


# ---------------------------------------------------------------------------
# Certified rational bounds on a square root, integers only.
# ---------------------------------------------------------------------------

def sqrt_upper(x, bits=BITS):
    """A Fraction y >= 0 with y*y >= x, for a Fraction x = a/b >= 0.

    y = (isqrt(a*b*4^bits) + 1) / (b*2^bits). Then y^2 = (isqrt(N)+1)^2 / (b^2 4^bits)
    > N / (b^2 4^bits) = a/b = x, because (isqrt(N)+1)^2 > N for every integer N >= 0.
    """
    x = Fraction(x)
    assert x >= 0, "sqrt_upper of a negative"
    if x == 0:
        return Fraction(0)
    a, b = x.numerator, x.denominator
    scale = 1 << bits
    y = Fraction(isqrt(a * b * scale * scale) + 1, b * scale)
    assert y * y >= x, "sqrt_upper failed its own certificate"
    return y


def sqrt_lower(x, bits=BITS):
    """A Fraction y >= 0 with y*y <= x. Used only to build negative control NC-C."""
    x = Fraction(x)
    assert x >= 0
    if x == 0:
        return Fraction(0)
    a, b = x.numerator, x.denominator
    scale = 1 << bits
    y = Fraction(isqrt(a * b * scale * scale), b * scale)
    assert y * y <= x, "sqrt_lower failed its own certificate"
    return y


def norm_sq(v):
    """||v||^2 of a Gaussian-rational 3-vector, as an exact Fraction."""
    return sum((c.re * c.re + c.im * c.im for c in v), Fraction(0))


def abs_sq(z):
    return z.re * z.re + z.im * z.im


# ---------------------------------------------------------------------------
# Genuine Galerkin states from a deterministic integer generator.
# ---------------------------------------------------------------------------

def lcg(seed):
    state = seed
    while True:
        state = (1103515245 * state + 12345) % (1 << 31)
        yield state


def make_states(M, count):
    """`count` genuine states on ball M -- divergence-free, conjugate-symmetric, zero-mean --
    with small integer Gaussian seeds, so every quantity below stays exact and small."""
    half = [k for k in ball(M) if k != (0, 0, 0) and k > tuple(-x for x in k)]
    gen = lcg(20260913)
    out = []
    for _ in range(count):
        seeds = []
        for k in half:
            a = [(next(gen) % 7 - 3, next(gen) % 7 - 3) for _c in range(3)]
            if any(x or y for x, y in a):
                seeds.append((k, a))
        u = make_state(M, seeds)
        check_state(M, u)
        out.append(u)
    return out


# ---------------------------------------------------------------------------
# The two elementary steps, each checked on its own.
# ---------------------------------------------------------------------------

def check_leray_contraction(M, states):
    """(L) ||applyLeray(k, v)||^2 <= ||v||^2 exactly, at every k, on every state vector and on
    one fixed vector that is deliberately not divergence-free (where the drop is strict)."""
    worst = Fraction(0)
    probe = [G(1, 2), G(-3, 1), G(2, -2)]
    for u in states:
        for k in ball(M):
            for v in (u_at(u, k), probe):
                lhs, rhs = norm_sq(apply_leray(k, v)), norm_sq(v)
                if lhs > rhs:
                    return None, (k, "contraction violated")
                if rhs:
                    worst = max(worst, lhs / rhs)
    return worst, None


def check_divfree_identity(M, states):
    """(DF) On a divergence-free state, q . u_p = k . u_p EXACTLY, because q = k - p and
    p . u_p = 0. This is what lets the varying factor |q| be replaced by the fixed |k| in the
    forcing bound -- the improvement proposed as T-2' in CORE_TAIL_CAP.md section 3.
    Checked as an exact Gaussian-rational equality over every (k, p) pair."""
    for u in states:
        for p in ball(M):
            up = u_at(u, p)
            if fourier_dot(p, up) != G(0, 0):
                return (p, "state is not divergence-free")
            for k in ball(M):
                if fourier_dot(sub(k, p), up) != fourier_dot(k, up):
                    return (k, p, "q.u_p != k.u_p")
    return None


def check_cauchy_schwarz(M, states):
    """(CS) |q . v|^2 <= k_sq(q) * ||v||^2, exactly, over every (q, mode) pair."""
    worst = Fraction(0)
    for u in states:
        for q in ball(M):
            for k in ball(M):
                v = u_at(u, k)
                lhs = abs_sq(fourier_dot(q, v))
                rhs = Fraction(k_sq(q)) * norm_sq(v)
                if lhs > rhs:
                    return None, (q, k, "Cauchy-Schwarz violated")
                if rhs:
                    worst = max(worst, lhs / rhs)
    return worst, None


# ---------------------------------------------------------------------------
# T-2 itself, and the false variants that must break it.
# ---------------------------------------------------------------------------

def bound_tables(M, u, rounding):
    """beta[k] >= ||u_k|| and gamma[k] >= |k|, rational, certified, computed once."""
    beta = {k: rounding(norm_sq(u_at(u, k))) for k in ball(M)}
    gamma = {k: rounding(Fraction(k_sq(k))) for k in ball(M)}
    return beta, gamma


def forcing_bound(M, u, k, beta, gamma, weight="q"):
    """sum over p in ball of w * beta[p] * beta[q], q = k - p; w = gamma[q] is T-2 as
    proposed, the other weights are the negative controls."""
    total = Fraction(0)
    for p in ball(M):
        q = sub(k, p)
        bq = beta.get(q)
        if bq is None or bq == 0 or beta[p] == 0:
            continue
        if weight == "q":
            w = gamma[q]
        elif weight == "p":
            w = gamma[p]
        elif weight == "k":
            w = gamma[k]
        elif weight == "none":
            w = Fraction(1)
        else:
            raise ValueError(weight)
        total += w * beta[p] * bq
    return total


def check_bound(M, states, bsq, weight="q", rounding=sqrt_upper, reverse=False, scale=1):
    """bsq[si][k] = ||B(u,u)_k||^2, precomputed. Returns (worst tightness, violations)."""
    violations = []
    worst = None
    scale = Fraction(scale)
    for si, u in enumerate(states):
        beta, gamma = bound_tables(M, u, rounding)
        for k in ball(M):
            lhs = bsq[si][k]
            rhs = scale * forcing_bound(M, u, k, beta, gamma, weight=weight)
            ok = (lhs >= rhs * rhs) if reverse else (lhs <= rhs * rhs)
            if not ok:
                violations.append((si, k))
            if rhs and not reverse:
                ratio = lhs / (rhs * rhs)
                worst = ratio if worst is None else max(worst, ratio)
    return worst, violations


# ---------------------------------------------------------------------------
# The coherent stratum: two-wavevector states, where the convolution sum can align.
# ---------------------------------------------------------------------------

SEED_VECS = (
    ((1, 0), (0, 0), (0, 0)),
    ((0, 0), (1, 0), (0, 0)),
    ((0, 0), (0, 0), (1, 0)),
)


def half_ball_of(M, shell_only=False):
    ks = [k for k in ball(M) if k != (0, 0, 0) and k > tuple(-x for x in k)]
    return [k for k in ks if k_sq(k) == M * M] if shell_only else ks


def pair_states(M, shell_only):
    """Every (p0, q0, seed_p, seed_q) state supported on +-p0, +-q0, with the finitely many
    wavevectors where B can be nonzero: k = s1 + s2 for s1, s2 in the support."""
    hb = half_ball_of(M, shell_only)
    bm = set(ball(M))
    for i, p0 in enumerate(hb):
        for q0 in hb[i + 1:]:
            support = [p0, tuple(-x for x in p0), q0, tuple(-x for x in q0)]
            ks = sorted({tuple(a[j] + b[j] for j in range(3)) for a in support for b in support}
                        & bm)
            for a in SEED_VECS:
                for b in SEED_VECS:
                    u = make_state(M, [(p0, list(a)), (q0, list(b))])
                    yield u, ks, (p0, q0)


def scan_coherent(M, shell_only, verify_support=False):
    """Worst tightness of T-2 over the coherent family, and whether each structural negative
    control is violated anywhere in it."""
    worst, worst_at = Fraction(0), None
    nc = {"none": 0, "p": 0, "lower": 0, "quarter": 0}
    nstates = 0
    for u, ks, tag in pair_states(M, shell_only):
        nstates += 1
        check_state(M, u)
        beta_u, gamma = bound_tables(M, u, sqrt_upper)
        beta_l, gamma_l = bound_tables(M, u, sqrt_lower)
        scan = ball(M) if verify_support else ks
        for k in scan:
            lhs = norm_sq(B(M, u, k))
            if lhs == 0:
                continue
            if verify_support and k not in ks:
                return None, None, None, f"B_{k} nonzero outside the predicted support"
            rhs = forcing_bound(M, u, k, beta_u, gamma, weight="q")
            rhs2 = forcing_bound(M, u, k, beta_u, gamma, weight="k")
            if lhs > rhs * rhs:
                return None, None, None, f"T-2 VIOLATED at {k} for pair {tag}"
            if lhs > rhs2 * rhs2:
                return None, None, None, f"T-2' VIOLATED at {k} for pair {tag}"
            ratio = lhs / (rhs * rhs)
            nc["k_tight"] = max(nc.get("k_tight", Fraction(0)), lhs / (rhs2 * rhs2))
            if ratio > worst:
                worst, worst_at = ratio, (tag, k)
            for name, r in (("none", forcing_bound(M, u, k, beta_u, gamma, weight="none")),
                            ("p", forcing_bound(M, u, k, beta_u, gamma, weight="p")),
                            ("lower", forcing_bound(M, u, k, beta_l, gamma_l, weight="q")),
                            ("quarter", Fraction(1, 4) * rhs)):
                if lhs > r * r:
                    nc[name] += 1
    return (worst, worst_at, (nstates, nc)), None, None, None


def export_reference(path, M=4):
    """Write the reference data the Rust evaluator (tests/core_forcing_rs) is cross-checked
    against: the ball, ||u_k||^2 per mode, and a LOWER and an UPPER exact-rational bound on
    the T-2' forcing sum per mode. Two-sided, so the Rust fixed-point arithmetic can be
    validated rather than merely compared. Exact rationals as "num/den" strings; no float."""
    import json

    u = make_states(M, 1)[0]
    lo_beta, lo_gamma = bound_tables(M, u, sqrt_lower)
    hi_beta, hi_gamma = bound_tables(M, u, sqrt_upper)
    frac = (lambda f: f"{f.numerator}/{f.denominator}")
    modes, nsq, lo, hi = [], [], [], []
    for k in ball(M):
        modes.append(list(k))
        nsq.append(frac(norm_sq(u_at(u, k))))
        lo.append(frac(forcing_bound(M, u, k, lo_beta, lo_gamma, weight="k")))
        hi.append(frac(forcing_bound(M, u, k, hi_beta, hi_gamma, weight="k")))
    with open(path, "w") as fh:
        json.dump({"M": M, "bits": BITS, "weight": "k (T-2')", "ball": modes,
                   "norm_sq": nsq, "bound_lower": lo, "bound_upper": hi}, fh)
    print(f"wrote {path}: M={M}, {len(modes)} modes, two-sided exact rational bounds")
    return 0


def main() -> int:
    if len(sys.argv) > 2 and sys.argv[1] == "--export":
        return export_reference(sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 4)
    ok = True
    print("TIER B -- forcing bound T-2 (PROPOSED, CORE_TAIL_CAP.md section 3), exact check")
    print(f"   rational sqrt bounds certified to 2^-{BITS}; no float, no square root taken\n")

    for M, count, controls in CASES:
        states = make_states(M, count)
        bsq = [{k: norm_sq(B(M, u, k)) for k in ball(M)} for u in states]
        nonzero = sum(1 for t in bsq for v in t.values() if v != 0)
        print(f"-- M = {M}: {len(ball(M))} modes, {len(states)} genuine states, "
              f"{nonzero} modes with B_k != 0 (non-vacuity)")
        if nonzero == 0:
            print("   FAIL: every B_k vanished, the inequality would be vacuous")
            ok = False

        worst_l, err = check_leray_contraction(M, states)
        if err:
            print(f"   (L)  FAIL {err}")
            ok = False
        else:
            print(f"   (L)  contraction holds; worst ||Pv||^2/||v||^2 = {dec(worst_l)}")

        err = check_divfree_identity(M, states)
        if err:
            print(f"   (DF) FAIL {err}")
            ok = False
        else:
            print("   (DF) q.u_p = k.u_p holds exactly at every (k, p) -- T-2' is available")

        worst_cs, err = check_cauchy_schwarz(M, states)
        if err:
            print(f"   (CS) FAIL {err}")
            ok = False
        else:
            print(f"   (CS) holds; worst |q.v|^2 / (k_sq(q)||v||^2) = {dec(worst_cs)}")

        worst, viol = check_bound(M, states, bsq)
        if viol:
            print(f"   (T2) FAIL: {len(viol)} violated modes, first at {viol[0]}")
            ok = False
        else:
            print(f"   (T2) holds at every mode of every state; worst tightness")
            print(f"        ||B_k||^2 / bound^2 = {dec(worst)}   (1 would be an equality)")

        worst2, viol2 = check_bound(M, states, bsq, weight="k")
        if viol2:
            print(f"   (T2') FAIL: {len(viol2)} violated modes, first at {viol2[0]}")
            ok = False
        else:
            print(f"   (T2') |k| in place of |q| also holds; worst tightness = {dec(worst2)}")

        if not controls:
            print("   negative controls not re-run at this M (declared in STOP REASON)\n")
            continue

        for label, kwargs, why in (
            ("NC-A  drop the |q| factor    ", dict(weight="none"),
             "is the wavevector factor load-bearing?"),
            ("NC-B  use |p| in place of |q|", dict(weight="p"),
             "is it the RIGHT wavevector?"),
            ("NC-C  round the roots DOWN   ", dict(rounding=sqrt_lower),
             "does the rounding direction matter at this precision?"),
            ("NC-D  reverse the inequality ", dict(reverse=True),
             "does the comparison itself work?"),
            ("NC-E  quarter the bound      ", dict(scale=Fraction(1, 4)),
             "calibrated sensitivity: fails where the slack is under 4x"),
        ):
            _, v = check_bound(M, states, bsq, **kwargs)
            verdict = "FAILS as required" if v else "does NOT fail"
            print(f"   {label} {verdict:18s} ({len(v):4d} violated modes) -- {why}")
            if label.startswith("NC-D") and not v:
                print("        NC-D not failing would make the comparison vacuous: FAIL")
                ok = False
        print()

    print("-- COHERENT STRATUM: two-wavevector states, where the sum can align")
    for M, shell_only, verify in ((2, False, True), (3, True, False)):
        res, _, _, err = scan_coherent(M, shell_only, verify_support=verify)
        if err:
            print(f"   M = {M}: FAIL -- {err}")
            ok = False
            continue
        worst, at, (nstates, nc) = res
        which = "all half-ball pairs" if not shell_only else "outer-shell pairs (k_sq = M^2)"
        print(f"   M = {M}: {nstates} states, {which}"
              + ("; support prediction verified against the full ball" if verify else ""))
        print(f"        T-2 holds everywhere; worst tightness ||B_k||^2/bound^2 = {dec(worst)}"
              f" at {at[0][0]}+{at[0][1]} -> k={at[1]}")
        print(f"        T-2' (|k| for |q|) holds everywhere; worst tightness "
              f"= {dec(nc.get('k_tight', Fraction(0)))}")
        for name, label in (("none", "NC-A  drop the |q| factor    "),
                            ("p", "NC-B  use |p| in place of |q|"),
                            ("lower", "NC-C  round the roots DOWN   "),
                            ("quarter", "NC-E  quarter the bound      ")):
            verdict = "FAILS as required" if nc[name] else "does NOT fail"
            print(f"        {label} {verdict:18s} ({nc[name]:5d} violated modes)")
        if not nc["quarter"]:
            print("        NC-E not failing on the coherent stratum means this checker")
            print("        cannot detect a weakened bound at all: FAIL")
            ok = False
    print()

    print("SCOPE. This validates the arithmetic of a PROPOSED bound on a finite Galerkin")
    print("system, nothing more. It is not a bound on any solution, it says nothing about")
    print("uniformity in M, and it adopts no object. SPEC obstruction O5 stands.")
    print("\nRESULT: " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
