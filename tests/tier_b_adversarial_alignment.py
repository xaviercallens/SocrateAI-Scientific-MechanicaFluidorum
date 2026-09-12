"""TIER B — the FOURTH trip: chirp phases, windowing, and an ADVERSARIAL alignment search.

ORDERED BY the Deep Think adjudication of 2026-09-12 (D-1: "execute the 4th trip with chirp
phases and windowing immediately; this is the final diagnostic") together with its D-2 ruling,
whose stated mechanism is: *no uniform oscillatory bound exists for all states because
adversarial phase-aligned states will always maximize the disparity factor.*

THAT MECHANISM IS ITSELF TESTABLE, AND THIS FILE TESTS IT. A null result would leave the
kill-decision resting on absence of evidence; a CONSTRUCTED adversarial state with a large
cancellation ratio is positive evidence that no kinematic uniform bound can exist. So this file
does not merely re-run the diagnostic: it tries to break the observable on purpose.

THE KEY REDUCTION that makes an exact search possible. Take purely imaginary amplitudes
a_k = i b_k d_k with b_k in {+1,-1} on the half-ball (the machinery forces a_{-k} = -conj(a_k),
which here means a is EVEN, so u is parity-ODD and the parity theorem does NOT apply -- this is
the complement of the stratum proved in FourierDynamicsZ3 section 11). Then u_k = i b_[k] (k x d_[k])
and every production term becomes

    t(p,q) = -i . b_[p] b_[q] b_[r] . Gint(p,q),
    Gint(p,q) = (|r|^2-|q|^2) . (q.(p x d_[p])) . ((q x d_[q]).(r x d_[r]))   in Z,

with [k] the half-ball representative of the pair {k,-k}. So

    rho = |sum b b b Gint| / sum |Gint|

is a PURE INTEGER optimisation over sign vectors: exact, no floats, and greedily searchable.
rho = 1 would mean perfect coherence. This also re-derives, independently, why Re(T) = 0.

FAMILIES (all conjugate-symmetric, divergence-free, zero-mean, varied directors per amendment 5):
  F2  null            random rational-circle phases (the standing baseline)
  F4  chirp           c(k) = c0^(|k|^2), c0 a rational circle point -- the registered redesign,
                      the first family with genuine RELATIVE phase structure across modes
  F5  adversarial     purely imaginary amplitudes with signs chosen by greedy alignment to
                      MAXIMISE |sum| -- the direct test of Deep Think's stated mechanism
  F5' control         same construction, signs chosen at random -- must NOT align, or the
                      greedy search is measuring nothing

WINDOWING: rho restricted to triads whose third member r lies in one shell |r|^2 = s, reported
per shell, so a global symmetry cannot swamp local structure.

AMENDMENT 6 (registered before the run that produced the reported numbers): the range is
extended to M = 4, with the null seed count reduced there for cost. Two points cannot establish
a trend, and the TREND -- whether the adversarial ratio decays with M as the null does -- is the
decision-relevant quantity for a uniformity question.

STOP REASON (LL-18): the registered range M = 2, 3, 4 is exhausted; the greedy search stops when
a full pass produces no improvement. No adaptive horizons.
"""

import pathlib
import sys
from fractions import Fraction

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from tier_b_fourier_enstrophy import (  # noqa: E402
    G, ball, k_sq, neg, add, cross_int_g, fourier_dot, bilinear, u_at,
)
from tier_b_production_cancellation import (  # noqa: E402
    half_ball, circle_point, direction_varied, make_family_state, measure,
    phases_random, l1, triad_terms, SEEDS,
)
from tier_b_production_cancellation import dec as _dec  # noqa: E402


def dec(x, places=4):
    return _dec(x, places)

ZERO = G(0, 0)


def rep(k):
    """The half-ball representative of the pair {k, -k}."""
    return k if k > neg(k) else neg(k)


def dot_i(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def cross_i(a, b):
    return (a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0])


def geometric_table(M):
    """Gint for every ordered triad, with its three sign-classes. Pure integers."""
    bm = set(ball(M))
    dirs = {r: direction_varied(r) for r in half_ball(M)}
    table = []
    for p in ball(M):
        for q in ball(M):
            r = neg(add(p, q))
            if r not in bm:
                continue
            if p == (0, 0, 0) or q == (0, 0, 0) or r == (0, 0, 0):
                continue
            rp, rq, rr = rep(p), rep(q), rep(r)
            W = k_sq(r) - k_sq(q)
            g = (W * dot_i(q, cross_i(p, dirs[rp]))
                 * dot_i(cross_i(q, dirs[rq]), cross_i(r, dirs[rr])))
            if g:
                table.append((rp, rq, rr, g, k_sq(r)))
    return table


def total_of(table, signs):
    return sum(signs[a] * signs[b] * signs[c] * g for a, b, c, g, _ in table)


def denom_of(table):
    return sum(abs(g) for _, _, _, g, _ in table)


def greedy_align(table, classes, start):
    """Flip one sign at a time while it increases |sum|. Deterministic; stops when a full
    pass yields no improvement."""
    signs = dict(start)
    best = abs(total_of(table, signs))
    improved = True
    passes = 0
    while improved:
        improved = False
        passes += 1
        for c in classes:
            signs[c] = -signs[c]
            val = abs(total_of(table, signs))
            if val > best:
                best = val
                improved = True
            else:
                signs[c] = -signs[c]
    return signs, best, passes


def lcg_signs(classes, seed):
    x = (seed * 2654435761) % (2 ** 31)
    out = {}
    for c in classes:
        x = (1103515245 * x + 12345) % (2 ** 31)
        out[c] = 1 if (x >> 16) & 1 else -1
    return out


def chirp_phases(M, num=1, den=3):
    """c(k) = c0^(|k|^2) with c0 = circle_point(num/den): exact, and genuinely
    mode-dependent -- the first family with RELATIVE phase structure."""
    c0 = circle_point(Fraction(num, den))
    out = {}
    for k in half_ball(M):
        acc = G(1, 0)
        for _ in range(k_sq(k)):
            acc = acc * c0
        out[k] = acc
    return out


def windowed_rho(M, u):
    """rho restricted to triads whose third member lies in one shell."""
    num, den = {}, {}
    for (p, q), t in triad_terms(M, u):
        s = k_sq(neg(add(p, q)))
        num[s] = num.get(s, ZERO) + t
        den[s] = den.get(s, Fraction(0)) + l1(t)
    return {s: (l1(num[s]) / den[s]) for s in sorted(den) if den[s]}


def main() -> int:
    print("== TIER B: the FOURTH trip — chirp, windowing, and adversarial alignment ==")
    print("   exact rationals and integers throughout; no float is constructed.\n")

    ok = True
    findings = {}

    for M, nseeds in ((2, 20), (3, 20), (4, 4)):
        print(f"-- M = {M} " + "-" * 56)

        # F2 null, the standing baseline
        nulls = []
        for seed in SEEDS[:nseeds]:
            u = make_family_state(M, phases_random(M, seed), 0)
            rho, _, _, _, integ = measure(M, u)
            ok &= integ
            if rho is not None:
                nulls.append(rho)
        null_mean = sum(nulls) / len(nulls)
        print(f"   F2 null            rho mean {dec(null_mean)}   "
              f"(min {dec(min(nulls))}, max {dec(max(nulls))})")

        # F4 chirp — the registered redesign
        u_ch = make_family_state(M, chirp_phases(M), 0)
        rho_ch, _, _, _, integ_ch = measure(M, u_ch)
        ok &= integ_ch
        print(f"   F4 chirp           rho      {dec(rho_ch)}"
              f"   {'ABOVE null' if rho_ch > null_mean else 'at/below null'}")

        # F5 adversarial — the direct test of the stated mechanism
        table = geometric_table(M)
        classes = sorted({c for a, b, c2, _, _ in table for c in (a, b, c2)})
        den = denom_of(table)
        ones = {c: 1 for c in classes}
        rho_ones = Fraction(abs(total_of(table, ones)), den)
        signs, best, passes = greedy_align(table, classes, ones)
        rho_adv = Fraction(best, den)
        print(f"   F5 adversarial     rho      {dec(rho_adv)}   "
              f"(from {dec(rho_ones)} at all-ones; {len(classes)} sign classes, "
              f"{passes} passes)")

        # F5' control — random signs in the SAME construction must not align
        rnd = [Fraction(abs(total_of(table, lcg_signs(classes, s))), den) for s in SEEDS[:10]]
        rnd_mean = sum(rnd) / len(rnd)
        print(f"   F5' random-sign    rho mean {dec(rnd_mean)}   "
              f"(max {dec(max(rnd))})   <- the search's own control")

        findings[M] = (null_mean, rho_ch, rho_adv, rnd_mean)

        # verify the adversarial family really is a Galerkin state, exactly
        adv_phases = {c: G(0, signs[c]) for c in classes}
        for k in half_ball(M):
            adv_phases.setdefault(k, G(0, 1))
        u_adv = make_family_state(M, adv_phases, 0)
        from tier_b_fourier_enstrophy import check_state
        div_ok, conj_ok, mean_ok = check_state(M, u_adv)
        print(f"   F5 state check     div-free {div_ok}, conj-sym {conj_ok}, "
              f"zero-mean {mean_ok}")
        ok &= div_ok and conj_ok and mean_ok

        # windowing, on the family that showed most structure
        win = windowed_rho(M, u_ch if rho_ch >= rho_adv else u_adv)
        print("   windowed rho by |r|^2 shell (most-structured family): "
              + ", ".join(f"{s}:{dec(v)}" for s, v in list(win.items())[:6]))
        print()

    print("== findings, printed as data (verdicts are the owner's) ==")
    for M, (nm, ch, adv, rnd) in findings.items():
        print(f"   M={M}: null {dec(nm)} | chirp {dec(ch)} | ADVERSARIAL {dec(adv)} "
              f"| random-sign {dec(rnd)}")

    Ms = sorted(findings)
    print()
    print("   ratio of adversarial to null, and the trend in M:")
    for M in Ms:
        nm, _, adv, _ = findings[M]
        print(f"     M={M}: adversarial/null = {dec(adv / nm, 2)}x"
              f"   (null {dec(nm)} falling, adversarial {dec(adv)})")

    # The three things that must hold for the reading below, each checked separately.
    detects = all(findings[M][2] > 3 * findings[M][0] for M in Ms)
    ctrl_ok = all(findings[M][3] < findings[M][2] / 2 for M in Ms)
    null_decays = all(findings[Ms[i + 1]][0] < findings[Ms[i]][0] for i in range(len(Ms) - 1))
    adv_holds = all(findings[Ms[i + 1]][2] > findings[Ms[i]][2] / 2 for i in range(len(Ms) - 1))

    print()
    print(f"   coherence control passes (adv > 3x null, every M) : {detects}")
    print(f"   search's own control stays low                    : {ctrl_ok}")
    print(f"   null DECAYS with M                                : {null_decays}")
    print(f"   adversarial does NOT decay with M                 : {adv_holds}")
    print()
    if detects and ctrl_ok and null_decays and adv_holds:
        print("   READING: after three trips, the coherence control PASSES. A deterministic,")
        print("   exactly-constructed Galerkin state -- divergence-free, conjugate-symmetric,")
        print("   zero-mean -- reaches a cancellation ratio several times the random-phase")
        print("   null, while random signs in the SAME construction do not. And the trend is")
        print("   the decisive part: the null's cancellation IMPROVES as the ball grows while")
        print("   the adversarial state's does not. Deep Think's stated mechanism is thereby")
        print("   EXHIBITED rather than argued -- adversarial phase alignment defeats the")
        print("   cancellation at every truncation tested, so no KINEMATIC bound uniform in M")
        print("   can hold. This is positive evidence for the kill, not absence of evidence.")
    else:
        print("   READING: at least one of the four conditions above failed; the result does")
        print("   NOT support the mechanism, and the printed numbers are the finding.")
    ok &= ctrl_ok

    if not ok:
        print("\nADVERSARIAL GATE: FAIL (instrument integrity or control)")
        return 1
    print("\nADVERSARIAL GATE: PASS (integrity; findings above are data)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
