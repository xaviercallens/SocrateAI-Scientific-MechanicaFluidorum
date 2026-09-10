"""TIER B — the gauge question left open in WALEFFE_HELICAL_MEMO.md section 6bis.

WHAT SECTION 6bis LEFT OPEN. The planar frame is chosen PER TRIAD, so it is not a global gauge,
and the step "the signed sum may be evaluated triad by triad in each triad's own frame" was
recorded as observed but not proved. This file settles the frame question, and the answer runs
against the memo's own item 4.

ITEM 4 STATES THE MECHANISM FOR THE OBSERVED PER-CLASS ZERO AS:

    "In a triad's own planar frame the coefficient is PURELY IMAGINARY, so conj(C) = -C
     and each triad is cancelled exactly by its negation."

That sentence uses two facts drawn from DIFFERENT GAUGES:

  * pure-imaginarity is a TRIAD-FRAME fact -- it needs one common normal orthogonal to all
    three wavevectors, which is what N = p x q is;
  * the conjugation law C(-k,-p,-q) = conj(C(k,p,q)) was verified in two GLOBAL nu
    conventions, where each wavevector carries its own normal nu(a), and nu(-a) = -nu(a).

AND THE REASON IS NOT THE ONE IT LOOKS LIKE. The natural guess is that pure-imaginarity comes
from p x q being orthogonal to the triad plane. A control here REFUTES that guess: move the
common normal off the plane and the real part is still exactly zero. The actual cause needs no
geometry at all -- every term that could carry an even power of i is a triple product of the
form (N x x).N, and N x x is orthogonal to N whatever N is. So the condition is that the three
helical vectors share ONE frame vector, which is why a global nu, using three different ones,
breaks it. Formalised without hypotheses as HelicalBasis.gOf_conj.

The two never hold together, because the two frames behave OPPOSITELY under negation:

    global nu   : nu(-a) = -nu(a)          the frame FLIPS   -> negation CONJUGATES
    triad frame : (-p) x (-q) = p x q      the frame is FIXED -> negation leaves C UNCHANGED

So in the triad's own frame a triad and its negation carry the same coefficient and add to
twice it. THE STATED MECHANISM CANNOT HOLD IN EITHER GAUGE, and this file demonstrates it in
exact integer arithmetic. The Lean counterparts are HelicalBasis section 13.

WHAT THIS DOES NOT CLAIM. The empirical observation that the per-class signed sum is numerically
zero is NOT contradicted here; only the explanation offered for it is. Under a global nu the
negation pairing sends the sum to twice its REAL part, so the observed zero requires the real
parts to sum to zero over the ball -- a separate fact that item 4 does not supply. Naming the
correct mechanism is left open, and the memo's own verdict stands that the zero carries no
information about turbulence, being a symmetry of a negation-symmetric lattice.

EXACT, NO FLOATS: same polynomial representation as tests/tier_b_helical_closed_form.py, with
|p|, |q|, |k| as formal symbols. "Purely imaginary" is then a statement about which monomials
carry a nonzero coefficient, decided in integers.
"""

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from tier_b_helical_closed_form import (  # noqa: E402
    MP, MQ, MK, crossZ, cdot, crossRC_, hOf, padd, pconj, vadd,
)

EX = (1, 0, 0)
EY = (0, 1, 0)

SIGNS = (1, -1)

# The first entry is the owner's crucible triad from the D-3 memo.
TRIADS = [
    ((0, -1, 1), (1, 2, -1)),
    ((1, 0, 0), (0, 1, 0)),
    ((3, 1, -2), (-1, 4, 2)),
    ((2, -1, 3), (1, 5, -2)),
    ((1, 1, 0), (0, 1, 1)),
    ((-2, 3, 1), (4, -1, 2)),
]


def nuInt(k):
    """HelicalBasis.nuInt, transcribed: k x xhat, falling back to k x yhat where that degenerates."""
    c = crossZ(k, EX)
    return crossZ(k, EY) if c == (0, 0, 0) else c


def neg(v):
    return (-v[0], -v[1], -v[2])


def g_general(Nk, Np, Nq, sk, sp, sq, k, p, q):
    """The geometric factor with a possibly DIFFERENT normal for each wavevector."""
    hp = hOf(Np, sp, p, MP)
    hq = hOf(Nq, sq, q, MQ)
    hk = hOf(Nk, sk, k, MK)
    return cdot(crossRC_(hp, hq), [pconj(x) for x in hk])


def real_part(poly):
    """Monomials with no factor of i."""
    return {kk: vv for kk, vv in poly.items() if kk[0] == 0}


def g_triad_frame(sk, sp, sq, k, p, q, normal_offset=None, split_one=False):
    """One common normal N = p x q for all three.

    Two control knobs. `normal_offset` moves the COMMON normal off the triad plane, destroying
    its orthogonality to p and q while keeping it common. `split_one` instead gives k's helical
    vector a DIFFERENT normal, breaking commonality while leaving the plane alone. Only the
    second should break pure-imaginarity -- see the module docstring."""
    N = crossZ(p, q)
    if normal_offset is not None:
        N = vadd(N, normal_offset)
    Nk = vadd(N, (1, 0, 0)) if split_one else N
    return g_general(Nk, N, N, sk, sp, sq, k, p, q)


def g_global(sk, sp, sq, k, p, q):
    """A different normal per wavevector, from the canonical global nu."""
    return g_general(nuInt(k), nuInt(p), nuInt(q), sk, sp, sq, k, p, q)


# ---------------------------------------------------------------------------


def check_triad_frame_purely_imaginary(normal_offset=None, split_one=False):
    """Returns the number of (triad, class) pairs whose coefficient has a real part."""
    bad = 0
    for p, q in TRIADS:
        k = vadd(p, q)
        for sk in SIGNS:
            for sp in SIGNS:
                for sq in SIGNS:
                    g = g_triad_frame(sk, sp, sq, k, p, q, normal_offset, split_one)
                    if real_part(g):
                        bad += 1
    return bad


def check_global_purely_imaginary():
    """How many (triad, class) pairs have a real part under the global nu gauge?"""
    bad = 0
    for p, q in TRIADS:
        k = vadd(p, q)
        for sk in SIGNS:
            for sp in SIGNS:
                for sq in SIGNS:
                    if real_part(g_global(sk, sp, sq, k, p, q)):
                        bad += 1
    return bad


def check_negation(gauge: str, law: str):
    """Count (triad, class) pairs where the given law FAILS.
    gauge is 'triad' or 'global'; law is 'conj' or 'equal'."""
    fails = 0
    for p, q in TRIADS:
        k = vadd(p, q)
        pn, qn, kn = neg(p), neg(q), neg(k)
        for sk in SIGNS:
            for sp in SIGNS:
                for sq in SIGNS:
                    if gauge == "triad":
                        g = g_triad_frame(sk, sp, sq, k, p, q)
                        gn = g_triad_frame(sk, sp, sq, kn, pn, qn)
                    else:
                        g = g_global(sk, sp, sq, k, p, q)
                        gn = g_global(sk, sp, sq, kn, pn, qn)
                    target = pconj(g) if law == "conj" else g
                    if gn != target:
                        fails += 1
    return fails


def check_cancellation(gauge: str):
    """Count (triad, class) pairs where a triad and its negation DO NOT cancel."""
    no_cancel = 0
    total = 0
    for p, q in TRIADS:
        k = vadd(p, q)
        pn, qn, kn = neg(p), neg(q), neg(k)
        for sk in SIGNS:
            for sp in SIGNS:
                for sq in SIGNS:
                    total += 1
                    if gauge == "triad":
                        g = g_triad_frame(sk, sp, sq, k, p, q)
                        gn = g_triad_frame(sk, sp, sq, kn, pn, qn)
                    else:
                        g = g_global(sk, sp, sq, k, p, q)
                        gn = g_global(sk, sp, sq, kn, pn, qn)
                    if padd(g, gn):
                        no_cancel += 1
    return no_cancel, total


def main() -> int:
    total = len(TRIADS) * 8
    print("== TIER B: the gauge question of WALEFFE_HELICAL_MEMO.md section 6bis ==")
    print(f"   {len(TRIADS)} triads x 8 chirality classes = {total} cases, exact integers.\n")

    ok = True

    print("-- Fact 1: in the TRIAD'S OWN frame the coefficient is purely imaginary")
    bad = check_triad_frame_purely_imaginary()
    print(f"   cases with a real part: {bad} / {total}"
          f"   {'-> PURELY IMAGINARY, as the memo says' if bad == 0 else '-> FAILED'}")
    ok &= bad == 0

    print("\n-- Fact 1b: and NOT because the frame is orthogonal to the triad plane.")
    print("   The natural guess is that p x q being perpendicular to p and q is what does it.")
    print("   Move the COMMON normal off the plane and see whether anything changes:")
    bad_off = check_triad_frame_purely_imaginary(normal_offset=(1, 0, 0))
    print(f"   cases with a real part: {bad_off} / {total}")
    if bad_off:
        print("   -> the guess would be confirmed")
        ok = False
    else:
        print("   -> the guess is REFUTED. Orthogonality is irrelevant; what matters is that")
        print("      the three helical vectors share ONE frame vector. Every term that could")
        print("      carry an even power of i is a triple product (N x x).N, zero for any N.")

    print("\n-- Fact 2: under a GLOBAL nu it is NOT purely imaginary")
    bad_global = check_global_purely_imaginary()
    print(f"   cases with a real part: {bad_global} / {total}")
    if bad_global == 0:
        print("   -> FAILED: the two gauges agree here, so there is nothing to separate")
        ok = False
    else:
        print("   -> the memo's pure-imaginarity does NOT extend to the gauge in which")
        print("      the conjugation law was measured")

    print("\n-- Fact 3: the two frames behave OPPOSITELY under negation")
    gl_conj = check_negation("global", "conj")
    gl_eq = check_negation("global", "equal")
    tr_conj = check_negation("triad", "conj")
    tr_eq = check_negation("triad", "equal")
    print(f"   global nu   : g(-triad) = conj(g) fails in {gl_conj} / {total}"
          f"    g(-triad) = +g fails in {gl_eq} / {total}")
    print(f"   triad frame : g(-triad) = conj(g) fails in {tr_conj} / {total}"
          f"    g(-triad) = +g fails in {tr_eq} / {total}")
    if not (gl_conj == 0 and tr_eq == 0 and gl_eq > 0 and tr_conj > 0):
        print("   -> FAILED: the expected gauge separation did not appear")
        ok = False
    else:
        print("   -> the conjugation law holds ONLY in the global gauge, and the")
        print("      invariance law holds ONLY in the triad frame. Item 4 combines them.")

    print("\n-- Fact 4: in NEITHER gauge does a triad cancel its own negation")
    for gauge, label in (("triad", "triad frame"), ("global", "global nu ")):
        nc, tot = check_cancellation(gauge)
        print(f"   {label}: {nc} / {tot} cases do NOT cancel")
        if nc == 0:
            print("   -> FAILED: cancellation was universal, contradicting the finding")
            ok = False

    print("\n== negative controls (each MUST fail) ==")

    # Commonality of the frame, NOT its orthogonality, is what makes the coefficient purely
    # imaginary. Give k's helical vector its own normal and the real part must appear.
    bad_split = check_triad_frame_purely_imaginary(split_one=True)
    print(f"  N1 give ONE of the three its own normal, breaking commonality: "
          f"{bad_split} / {total} acquire a real part "
          f"{'(rejected as required)' if bad_split else '*** DID NOT FAIL ***'}")
    ok &= bad_split > 0

    # Asserting the memo's law inside the triad frame must fail -- this is the Lean NC-E.
    print(f"  N2 assert the conjugation law in the triad frame: "
          f"fails in {tr_conj} / {total} "
          f"{'(rejected as required)' if tr_conj else '*** DID NOT FAIL ***'}")
    ok &= tr_conj > 0

    # Asserting frame-invariance in the global gauge must fail -- this is the Lean NC-F.
    print(f"  N3 assert invariance under negation in the global gauge: "
          f"fails in {gl_eq} / {total} "
          f"{'(rejected as required)' if gl_eq else '*** DID NOT FAIL ***'}")
    ok &= gl_eq > 0

    if not ok:
        print("\nGAUGE GATE: FAIL")
        return 1

    print("\nGAUGE GATE: PASS")
    print("  CONCLUSION, for the owner's verdict: the mechanism stated in section 6bis item 4")
    print("  splices a triad-frame fact to a global-gauge fact. Neither gauge yields the")
    print("  cancellation it claims. The observed per-class zero still needs an explanation.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
