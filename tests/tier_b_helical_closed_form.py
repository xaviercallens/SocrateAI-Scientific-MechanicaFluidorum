"""TIER B — the helical closed form, checked symbolically in EXACT arithmetic.

WHAT THIS CHECKS, AND WHY LEAN DOES NOT ALREADY CHECK IT.
`lean_src/HelicalBasis.lean` §12 proves `gOf_closed_form` and `cOf_closed_form`. The kernel
certifies that the *proof* of that statement is correct. It cannot certify that the *statement* is
the one the physics means — a mis-transcribed sign in the statement would be proved just as happily,
and the memo's first draft carried exactly such a sign error (see
`docs/designs/WALEFFE_HELICAL_MEMO.md` §4). This file is the independent transcription: it computes
the geometric factor by BRUTE FORCE from the definition and compares against the closed form, over a
sweep of lattice triads and all eight chirality classes.

WHY IT CAN BE EXACT, WITH NO FLOATS. `|p|`, `|q|` and `|k|` are square roots of integers, so a
numerical check would need floating point. But the closed form is *linear* in them and the brute
force at worst *quadratic*, so both sides are POLYNOMIALS in three formal symbols `mp, mq, mk` with
INTEGER coefficients. Two polynomials are equal iff their coefficients are. No square root is ever
evaluated and no float is ever constructed. This is also a stronger check than numerical agreement
would be: the identity is verified as an identity *in the magnitudes*, for every triad swept, not
merely at the particular magnitudes those triads happen to have.

THE IDENTITY (this file's unnormalised scaling, `N = p x q` the triad's own frame):

    g  =  (h^{s_p}(p) x h^{s_q}(q)) . conj(h^{s_k}(k))  =  - i (N.N)^2 (s_p|p| + s_q|q| + s_k|k|)

    4C =  -(s_p|p| - s_q|q|) g  =  i (N.N)^2 (s_p|p| + s_q|q| + s_k|k|) (s_p|p| - s_q|q|)

with `h^s(N, a) = (N x a) + i s |a| N` unnormalised, as in `HelicalBasis.hOf`. `C` itself carries a
factor 1/4; the check is stated on `4C` so that every coefficient stays an integer.

THE IDENTITY IS UNCONDITIONAL: it needs only `p + q = k`. It holds for collinear triads too (both
sides are then zero), which is why the sweep does not exclude them.
"""

from itertools import product

# ---------------------------------------------------------------------------
# Exact polynomial arithmetic in Z[i, mp, mq, mk] / (i^2 + 1).
# A monomial key is (e_i, e_mp, e_mq, e_mk) with e_i reduced to {0, 1}.
# Coefficients are Python ints — exact and unbounded.
# ---------------------------------------------------------------------------

Poly = dict


def const(c: int) -> Poly:
    return {} if c == 0 else {(0, 0, 0, 0): c}


def sym(index: int) -> Poly:
    key = [0, 0, 0, 0]
    key[index] = 1
    return {tuple(key): 1}


I = sym(0)
MP, MQ, MK = sym(1), sym(2), sym(3)


def padd(a: Poly, b: Poly) -> Poly:
    out = dict(a)
    for key, coeff in b.items():
        total = out.get(key, 0) + coeff
        if total:
            out[key] = total
        else:
            out.pop(key, None)
    return out


def pneg(a: Poly) -> Poly:
    return {key: -coeff for key, coeff in a.items()}


def psub(a: Poly, b: Poly) -> Poly:
    return padd(a, pneg(b))


def pmul(a: Poly, b: Poly) -> Poly:
    out: Poly = {}
    for ka, ca in a.items():
        for kb, cb in b.items():
            e_i = ka[0] + kb[0]
            sign = -1 if e_i >= 2 else 1          # i^2 = -1
            key = (e_i % 2, ka[1] + kb[1], ka[2] + kb[2], ka[3] + kb[3])
            total = out.get(key, 0) + sign * ca * cb
            if total:
                out[key] = total
            else:
                out.pop(key, None)
    return out


def pconj(a: Poly) -> Poly:
    """The magnitudes and the lattice entries are real, so only i flips."""
    return {key: (-coeff if key[0] else coeff) for key, coeff in a.items()}


def subst_mp_eq_mq(a: Poly) -> Poly:
    """Impose |p| = |q| by merging the two symbols. Used for the balance locus."""
    out: Poly = {}
    for (e_i, e_p, e_q, e_k), coeff in a.items():
        key = (e_i, 0, e_p + e_q, e_k)
        total = out.get(key, 0) + coeff
        if total:
            out[key] = total
        else:
            out.pop(key, None)
    return out


# ---------------------------------------------------------------------------
# Integer vector algebra, mirroring HelicalBasis.crossZ / dotZ / k_sq exactly.
# ---------------------------------------------------------------------------


def crossZ(a, b):
    return (a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0])


def dotZ(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def k_sq(a):
    return dotZ(a, a)


def vadd(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


# ---------------------------------------------------------------------------
# The basis and the coefficient, by BRUTE FORCE from the definition.
# ---------------------------------------------------------------------------


def hOf(N, s: int, a, m: Poly):
    """h^s(a) in frame N, unnormalised: (N x a) + i s |a| N, with |a| the symbol m."""
    Na = crossZ(N, a)
    scaled = pmul(pmul(I, const(s)), m)
    return [padd(const(Na[i]), pmul(scaled, const(N[i]))) for i in range(3)]


def crossRC_(v, w):
    return [psub(pmul(v[1], w[2]), pmul(v[2], w[1])),
            psub(pmul(v[2], w[0]), pmul(v[0], w[2])),
            psub(pmul(v[0], w[1]), pmul(v[1], w[0]))]


def cdot(v, w):
    return padd(padd(pmul(v[0], w[0]), pmul(v[1], w[1])), pmul(v[2], w[2]))


def g_brute(N, sk: int, sp: int, sq: int, k, p, q) -> Poly:
    hp = hOf(N, sp, p, MP)
    hq = hOf(N, sq, q, MQ)
    hk = hOf(N, sk, k, MK)
    return cdot(crossRC_(hp, hq), [pconj(x) for x in hk])


def anti(sp: int, sq: int) -> Poly:
    """The antisymmetrisation factor s_p|p| - s_q|q|."""
    return psub(pmul(const(sp), MP), pmul(const(sq), MQ))


def c4_brute(N, sk: int, sp: int, sq: int, k, p, q) -> Poly:
    """4C = -(s_p|p| - s_q|q|) g."""
    return pmul(pneg(anti(sp, sq)), g_brute(N, sk, sp, sq, k, p, q))


# ---------------------------------------------------------------------------
# The closed form, transcribed from the Lean statement.
# `flip_k` and `flip_q` are the negative-control knobs.
# ---------------------------------------------------------------------------


def balance(sk: int, sp: int, sq: int, flip_k: int = 1, flip_q: int = 1) -> Poly:
    """s_p|p| + s_q|q| + s_k|k|."""
    return padd(padd(pmul(const(sp), MP), pmul(const(sq * flip_q), MQ)),
                pmul(const(sk * flip_k), MK))


def g_closed(N, sk: int, sp: int, sq: int, **knobs) -> Poly:
    return pmul(pmul(pneg(I), const(k_sq(N) ** 2)), balance(sk, sp, sq, **knobs))


def c4_closed(N, sk: int, sp: int, sq: int, **knobs) -> Poly:
    return pmul(pmul(pmul(I, const(k_sq(N) ** 2)), balance(sk, sp, sq, **knobs)),
                anti(sp, sq))


# ---------------------------------------------------------------------------
# The sweep.
# ---------------------------------------------------------------------------

SIGNS = (1, -1)

# Larger triads carried alongside the exhaustive small box, so the check is not confined to
# components in {-1, 0, 1}. The first entry is the owner's crucible triad from the D-3 memo.
EXTRA = [
    ((0, -1, 1), (1, 2, -1)),      # k = (1, 1, 0)  -- the crucible triad
    ((3, 1, -2), (-1, 4, 2)),
    ((5, 0, 1), (2, -3, 7)),
    ((-4, 2, 6), (1, 1, -5)),
    ((7, -6, 2), (-3, 8, 1)),
    ((2, 2, 2), (4, 4, 4)),        # collinear, and both sides must be zero
    ((1, 0, 0), (0, 1, 0)),        # the balance witness
]


def triads():
    """Every p, q with components in {-1, 0, 1} and p, q, p + q all nonzero, plus EXTRA.
    Collinear triads are deliberately INCLUDED: the identity is unconditional."""
    box = [v for v in product((-1, 0, 1), repeat=3) if v != (0, 0, 0)]
    for p in box:
        for q in box:
            k = vadd(p, q)
            if k != (0, 0, 0):
                yield p, q, k
    for p, q in EXTRA:
        yield p, q, vadd(p, q)


def sweep(stop_on_first: bool = False, frame_swapped: bool = False, **knobs):
    """Returns (checked, mismatches, first_mismatch)."""
    checked = 0
    mismatches = 0
    first = None
    for p, q, k in triads():
        N = crossZ(q, p) if frame_swapped else crossZ(p, q)
        if frame_swapped and N == (0, 0, 0):
            continue                      # a swapped null frame is not a discriminating case
        for sk, sp, sq in product(SIGNS, repeat=3):
            checked += 1
            bad = (g_brute(N, sk, sp, sq, k, p, q) != g_closed(N, sk, sp, sq, **knobs)
                   or c4_brute(N, sk, sp, sq, k, p, q) != c4_closed(N, sk, sp, sq, **knobs))
            if bad:
                mismatches += 1
                if first is None:
                    first = (p, q, k, sk, sp, sq)
                if stop_on_first:
                    return checked, mismatches, first
    return checked, mismatches, first


def main() -> int:
    print("== TIER B: the helical closed form, exact symbolic check ==")
    print("   symbols mp, mq, mk carry |p|, |q|, |k|; coefficients are Python ints;")
    print("   no float is constructed anywhere in this file.\n")

    checked, mismatches, first = sweep()
    print(f"  triad x chirality-class checks : {checked}")
    print(f"  mismatches (g and 4C)          : {mismatches}")
    if mismatches:
        print(f"  FIRST MISMATCH                 : {first}")
        print("CLOSED FORM: FAIL")
        return 1
    print("  -> g and 4C agree with the closed form, identically in |p|, |q|, |k|,")
    print("     across all eight chirality classes and including collinear triads.\n")

    print("== negative controls (each MUST fail) ==")
    ok = True
    for label, kwargs in (
        ("N1 flip the sign of s_k|k| in the balance factor", {"flip_k": -1}),
        ("N2 flip the sign of s_q|q| in the balance factor", {"flip_q": -1}),
        ("N3 build the frame as q x p, opposite orientation", {"frame_swapped": True}),
    ):
        _, n, where = sweep(stop_on_first=True, **kwargs)
        verdict = "rejected as required" if n else "*** DID NOT FAIL ***"
        print(f"  {label}: {verdict}")
        if n:
            print(f"     first disagreement at p={where[0]}, q={where[1]}, "
                  f"signs (s_k,s_p,s_q)=({where[3]},{where[4]},{where[5]})")
        ok &= n > 0

    if not ok:
        print("CONTROL GATE: FAIL (a control that cannot fail is not a control)")
        return 1

    print("\n== the three vanishing loci, read off the verified closed form ==")

    p, q = (1, 0, 0), (0, 1, 0)
    k, N = vadd(p, q), crossZ(p, q)
    balanced = subst_mp_eq_mq(c4_brute(N, 1, 1, 1, k, p, q))
    print(f"  balance   |p| = |q| and s_p = s_q = +1, p=(1,0,0), q=(0,1,0) : "
          f"4C = {'0' if not balanced else 'NONZERO'}")

    p, q = (1, 0, 0), (2, 0, 0)
    k, N = vadd(p, q), crossZ(p, q)
    collinear = c4_brute(N, 1, 1, -1, k, p, q)
    print(f"  collinear p=(1,0,0), q=(2,0,0)                               : "
          f"4C = {'0' if not collinear else 'NONZERO'}")

    # The balance witness must be genuinely non-collinear, or the first line proves nothing.
    noncollinear = crossZ((1, 0, 0), (0, 1, 0)) != (0, 0, 0)
    print(f"  the balance witness is NOT collinear (non-vacuity, LL-11)    : {noncollinear}")

    if balanced or collinear or not noncollinear:
        print("VANISHING LOCUS CHECK: FAIL")
        return 1

    print("\nCLOSED FORM: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
