#!/usr/bin/env python3
# TIER C — EXPLORATORY, NO CLAIMS — NEVER GATES A CLAIM (SPEC bars floats from Tier B/A)
"""STEP 1 of the S6.4 reconciliation: one triad, brute force versus closed form, side by side.

THE COLLISION (docs/designs/WALEFFE_HELICAL_MEMO.md §6.4). The hand-derived closed form predicts a
NON-zero per-class triad sum; the enumerator measured EXACTLY zero (1e-17) in every chirality
class. One of them is false. Global sums cannot arbitrate that — they hide the disagreement inside
a cancellation — so this file halts all summation and tests ONE triad, term by term.

TRIAD (owner-specified):  k = (1,1,0),  p = (0,-1,1),  q = (1,2,-1),  and indeed p + q = k.

THE THIRD SUSPECT, which the owner's two did not name and which this file therefore tests too.
The helical vector depends on the choice of the real unit vector nu ⊥ k. Rotating nu by an angle
theta about k multiplies h^s by a phase exp(-i s theta). So:

    |C| is independent of the choice of nu;   arg(C) is NOT.

The closed form of §4 was derived under a SPECIFIC choice: nu = n_hat, the triad-plane normal, for
ALL THREE members at once. A brute-force computation using any other nu (for instance the
`k x x_hat` construction the repository's other harnesses use) must therefore differ from it by a
phase, WITHOUT either being wrong. Comparing them without fixing the convention would manufacture
a disagreement out of nothing. Both conventions are computed below and reported separately.

CONTROLS (SPEC §7.3, run first; the comparison is void if any fails):
  H1  h^s . h^s        = 0      (self-null)
  H2  h^s . h^{-s}     = 2      (normalisation)
  H3  k . h^s          = 0      (transversality — the Leray projector fixes h)
  H4  i k x h^s = s|k| h^s      (curl eigenvector: the reason for the basis)
  H5  conj(h^s)        = h^{-s}
  NEG a sign-flipped vector must FAIL H4 (a control that cannot fail is not a control)
  LERAY  the explicit projector matrix must fix each h^s (independent route to H3)
"""

import cmath
import math
import sys

K = (1, 1, 0)
P = (0, -1, 1)
Q = (1, 2, -1)


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    """Bilinear dot, NO conjugation (the conjugation is always written explicitly)."""
    return sum(x * y for x, y in zip(a, b))


def conj3(v):
    return tuple(complex(x).conjugate() for x in v)


def norm(a):
    return math.sqrt(sum(abs(x) ** 2 for x in a))


def scale(a, s):
    return tuple(x * s for x in a)


def unit(a):
    n = norm(a)
    return scale(a, 1.0 / n)


# ---------------------------------------------------------------- the helical basis
def helical(k, s, nu):
    """h^s(k) = (nu x kappa) + i s nu, for a real unit nu ⊥ kappa."""
    kappa = unit(k)
    e1 = cross(nu, kappa)
    return tuple(complex(e1[j], s * nu[j]) for j in range(3))


def nu_generic(k):
    """The repository's usual construction: k x x_hat, falling back to k x y_hat."""
    v = cross(k, (1.0, 0.0, 0.0))
    if norm(v) < 1e-12:
        v = cross(k, (0.0, 1.0, 0.0))
    return unit(v)


def leray_matrix(k):
    k2 = dot(k, k)
    return [[(1.0 if i == j else 0.0) - k[i] * k[j] / k2 for j in range(3)] for i in range(3)]


def apply_mat(m, v):
    return tuple(sum(m[i][j] * v[j] for j in range(3)) for i in range(3))


# ---------------------------------------------------------------- controls
def controls():
    print("== CONTROLS ==")
    ok = True
    worst = {"H1": 0.0, "H2": 0.0, "H3": 0.0, "H4": 0.0, "H5": 0.0, "LERAY": 0.0}
    neg_min = float("inf")
    for k in (K, P, Q):
        for nu in (unit(cross(P, Q)), nu_generic(k)):
            kn = norm(k)
            for s in (1, -1):
                h = helical(k, s, nu)
                hm = helical(k, -s, nu)
                worst["H1"] = max(worst["H1"], abs(dot(h, h)))
                worst["H2"] = max(worst["H2"], abs(dot(h, hm) - 2.0))
                worst["H3"] = max(worst["H3"], abs(dot(k, h)) / kn)
                curl = tuple(1j * x for x in cross(tuple(complex(c) for c in k), h))
                worst["H4"] = max(worst["H4"],
                                  max(abs(curl[j] - s * kn * h[j]) for j in range(3)) / kn)
                worst["H5"] = max(worst["H5"], max(abs(conj3(h)[j] - hm[j]) for j in range(3)))
                ph = apply_mat(leray_matrix(k), h)
                worst["LERAY"] = max(worst["LERAY"], max(abs(ph[j] - h[j]) for j in range(3)))
                # NEGATIVE CONTROL: the opposite-sign vector must FAIL the eigen-equation
                hbad = helical(k, -s, nu)
                neg_min = min(neg_min,
                              max(abs(curl[j] - s * kn * hbad[j]) for j in range(3)) / kn)
    for name, v in worst.items():
        good = v < 1e-12
        ok &= good
        print(f"  {name:6} worst residual {v:.2e}   {'OK' if good else '*** FAILED ***'}")
    good = neg_min > 1e-3
    ok &= good
    print(f"  NEG    sign-flipped vector fails H4 by at least {neg_min:.2e}   "
          f"{'OK (fires)' if good else '*** INERT ***'}")
    print("CONTROLS:", "PASS\n" if ok else "*** FAILED — comparison void ***\n")
    return ok


# ---------------------------------------------------------------- the two computations
def c_brute(sk, sp, sq, nu_of, p=P, q=Q, k=K):
    """C = -1/4 (s_p|p| - s_q|q|) * (h^{s_p}(p) x h^{s_q}(q)) . conj(h^{s_k}(k))

    `p`, `q`, `k` are arguments rather than globals so that the parity probe can exchange the two
    summation slots without mutating module state."""
    hp = helical(p, sp, nu_of(p))
    hq = helical(q, sq, nu_of(q))
    hk = helical(k, sk, nu_of(k))
    g = dot(cross(hp, hq), conj3(hk))
    return -0.25 * (sp * norm(p) - sq * norm(q)) * g, g


def c_closed(sk, sp, sq):
    """CORRECTED closed form (2026-09-10, after this crucible refuted the first one):

        C = +(i S_pq / 4|k|) (s_p|p| + s_q|q| + s_k|k|) (s_p|p| - s_q|q|),   nu = n_hat.

    The memo's original had `- s_k|k|` and an overall minus. Root cause, exactly where §6.3 said to
    look: the derivation reduced the signed areas using |k|kappa_k = -|p|kappa_p - |q|kappa_q, which
    is the relation for the triad written p+q+r=0. In the p+q=k convention actually used, the
    relation is |k|kappa_k = +|p|kappa_p + |q|kappa_q, so BOTH reduced areas flip:

        S_kp = -(|q|/|k|) S_pq        S_kq = +(|p|/|k|) S_pq

    which turns the balance factor into the SUM of all three signed helical wavenumbers -- the
    classical Waleffe resonance condition s_k|k| + s_p|p| + s_q|q| = 0."""
    n_hat = unit(cross(P, Q))
    s_pq = dot(cross(unit(P), unit(Q)), n_hat)
    bal = sp * norm(P) + sq * norm(Q) + sk * norm(K)
    dif = sp * norm(P) - sq * norm(Q)
    return (1j * s_pq / (4.0 * norm(K))) * bal * dif, s_pq


def fmt(z):
    return f"{z.real:+11.6f}{z.imag:+11.6f}i"


def main():
    assert add(P, Q) == K, "the triad must satisfy p + q = k"
    if not controls():
        sys.exit(1)

    n_hat = unit(cross(P, Q))
    print(f"triad   k={K}  p={P}  q={Q}   (p+q=k verified)")
    print(f"|k|={norm(K):.6f}  |p|={norm(P):.6f}  |q|={norm(Q):.6f}")
    print(f"n_hat = {tuple(round(x, 6) for x in n_hat)}   S_pq = {c_closed(1,1,1)[1]:+.6f}\n")

    hdr = f"{'s_k s_p s_q':11} {'C brute (nu=n_hat)':>24} {'C closed form':>24} {'|ratio|':>9} {'arg ratio/pi':>13}"
    print(hdr)
    print("-" * len(hdr))
    max_dev_planar = 0.0
    rows = []
    for sk in (1, -1):
        for sp in (1, -1):
            for sq in (1, -1):
                cb, _ = c_brute(sk, sp, sq, lambda a: n_hat)
                cc, _ = c_closed(sk, sp, sq)
                if abs(cc) < 1e-14 and abs(cb) < 1e-14:
                    ratio_s, dev = "   both 0", 0.0
                elif abs(cc) < 1e-14 or abs(cb) < 1e-14:
                    ratio_s, dev = "  ONE IS 0", 1.0
                else:
                    r = cb / cc
                    ratio_s = f"{abs(r):9.6f}"
                    dev = abs(cb - cc) / max(abs(cb), abs(cc))
                arg_s = "        —" if abs(cc) < 1e-14 or abs(cb) < 1e-14 else \
                    f"{cmath.phase(cb / cc) / math.pi:+13.6f}"
                max_dev_planar = max(max_dev_planar, dev)
                sgn = lambda s: "+" if s > 0 else "-"
                rows.append((sgn(sk) + sgn(sp) + sgn(sq), cb, cc))
                print(f"{sgn(sk)}   {sgn(sp)}   {sgn(sq)}    {fmt(cb)} {fmt(cc)} {ratio_s} {arg_s}")

    print(f"\nworst relative deviation, planar convention (nu = n_hat): {max_dev_planar:.3e}")
    print("=> CLOSED FORM", "CONFIRMED" if max_dev_planar < 1e-10 else "*** REFUTED ***",
          "for this triad under its own convention.\n")

    # the generic-nu run, to show the phase and settle the third suspect
    print("Same triad, brute force with the GENERIC nu (k x x_hat) instead of the plane normal:")
    print(f"{'s_k s_p s_q':11} {'C brute (generic nu)':>24} {'|C| brute':>12} {'|C| closed':>12} {'|.| match':>10}")
    mag_ok = True
    for sk in (1, -1):
        for sp in (1, -1):
            for sq in (1, -1):
                cg, _ = c_brute(sk, sp, sq, nu_generic)
                cc, _ = c_closed(sk, sp, sq)
                m = abs(abs(cg) - abs(cc)) <= 1e-10 * max(1.0, abs(cc))
                mag_ok &= m
                sgn = lambda s: "+" if s > 0 else "-"
                print(f"{sgn(sk)}   {sgn(sp)}   {sgn(sq)}    {fmt(cg)} {abs(cg):12.6f} "
                      f"{abs(cc):12.6f} {'yes' if m else 'NO':>10}")
    print(f"\n|C| agrees across the two nu conventions: {mag_ok}")
    print("  (as it must: rotating nu about k multiplies h^s by a phase, so |C| is invariant and")
    print("   arg(C) is not. A comparison that does not fix the convention manufactures a")
    print("   disagreement out of nothing — this is the third suspect for S6.4.)\n")

    print("PARITY PROBE — the actual subject of S6.4.")
    print("Exchange the two summation slots, p <-> q, KEEPING the chirality labels on the slots,")
    print("which is what the enumerator does when p ranges over the lattice at fixed k.")
    print(f"{'class':7} {'C(k;p,q)':>24} {'C(k;q,p)':>24} {'sum':>24}")
    for sk in (1, -1):
        for sp in (1, -1):
            for sq in (1, -1):
                c1, _ = c_brute(sk, sp, sq, lambda a: n_hat, p=P, q=Q)
                c2, _ = c_brute(sk, sp, sq, lambda a: n_hat, p=Q, q=P)
                sgn = lambda s: "+" if s > 0 else "-"
                print(f"{sgn(sk)}{sgn(sp)}{sgn(sq)}    {fmt(c1)} {fmt(c2)} {fmt(c1 + c2)}")
    print("\nNEGATION PROBE — the involution the memo's parity argument never examined.")
    print("The enumerator sums over the WHOLE symmetric lattice, so every triad appears alongside")
    print("its negation (-k,-p,-q). With the repository's nu construction nu(-a) = -nu(a), giving")
    print("h^s(-a) = conj(h^s(a)); and C is purely imaginary, so conj(C) = -C. Test it:")
    print(f"{'class':7} {'C(k;p,q)':>24} {'C(-k;-p,-q)':>24} {'sum':>24}")
    neg = lambda v: tuple(-x for x in v)
    worst_neg = 0.0
    for sk in (1, -1):
        for sp in (1, -1):
            for sq in (1, -1):
                c1, _ = c_brute(sk, sp, sq, nu_generic, p=P, q=Q, k=K)
                c2, _ = c_brute(sk, sp, sq, nu_generic, p=neg(P), q=neg(Q), k=neg(K))
                worst_neg = max(worst_neg, abs(c1 + c2))
                sgn = lambda s: "+" if s > 0 else "-"
                print(f"{sgn(sk)}{sgn(sp)}{sgn(sq)}    {fmt(c1)} {fmt(c2)} {fmt(c1 + c2)}")
    print(f"\nworst |C(triad) + C(-triad)| = {worst_neg:.3e}")
    if worst_neg < 1e-12:
        print("=> EXACT CANCELLATION under negation, in every chirality class.")
        print("   This is the mechanism behind the enumerator's per-class zero. Both computations")
        print("   are therefore CORRECT: the closed form does not cancel under p<->q (it does not")
        print("   claim to), and the enumerator's zero comes from summing a purely imaginary")
        print("   quantity over a lattice that is symmetric under negation.")
        print("   CONSEQUENCE: that zero is a TRIVIAL LATTICE SYMMETRY, not a statement about")
        print("   turbulence, and it must not be read as a cancellation of physical transfer.")
    else:
        print("=> no cancellation under negation; the S6.4 collision is NOT yet resolved.")

    # ---- the enumerator's own convention, which is what S6.4 is actually about
    print("\nENUMERATOR CONVENTION — all three vectors conjugated, triad written k+p+q = 0.")
    print("This is what exploration/triad_frustration_rs computes. It is a DIFFERENT expression")
    print("from the one above (§6.3's convention gap), so it gets its own negation test.")

    def c_enum(sk, sp, sq, k, p, q):
        """g = (conj h_p x conj h_q) . conj h_k, times -1/4 (s_p|p| - s_q|q|); triad k+p+q=0."""
        hp = conj3(helical(p, sp, nu_generic(p)))
        hq = conj3(helical(q, sq, nu_generic(q)))
        hk = conj3(helical(k, sk, nu_generic(k)))
        g = dot(cross(hp, hq), hk)
        return -0.25 * g * (sp * norm(p) - sq * norm(q))

    # k + p + q = 0 form of the same triad: negate k, keep p and q
    KE = neg(K)
    print(f"  triad in that convention: k={KE}, p={P}, q={Q}  (sums to zero: {add(add(KE,P),Q)})")
    print(f"{'class':7} {'C_enum(k;p,q)':>24} {'C_enum(-k;-p,-q)':>24} {'sum':>24}")
    worst_enum = 0.0
    for sk in (1, -1):
        for sp in (1, -1):
            for sq in (1, -1):
                c1 = c_enum(sk, sp, sq, KE, P, Q)
                c2 = c_enum(sk, sp, sq, neg(KE), neg(P), neg(Q))
                worst_enum = max(worst_enum, abs(c1 + c2))
                sgn = lambda s: "+" if s > 0 else "-"
                print(f"{sgn(sk)}{sgn(sp)}{sgn(sq)}    {fmt(c1)} {fmt(c2)} {fmt(c1 + c2)}")
    print(f"\nworst |C_enum(triad) + C_enum(-triad)| = {worst_enum:.3e}")
    if worst_enum < 1e-12:
        print("=> EXACT CANCELLATION under negation, in every chirality class, in the ENUMERATOR's")
        print("   convention. That is the mechanism behind its per-class zero: it sums over a")
        print("   lattice symmetric under negation, and each triad is exactly cancelled by its")
        print("   negation. BOTH computations are correct; the memo's parity argument examined the")
        print("   wrong involution (p<->q instead of the global negation).")
        print("   CONSEQUENCE: that zero is a TRIVIAL LATTICE SYMMETRY, not a cancellation of")
        print("   physical transfer, and must never be read as one.")
    else:
        print("=> still no cancellation; the S6.4 collision needs a further mechanism.")

    print("\nNO VERDICT issued here; verdicts are the owner's (PLAN section 2).")


if __name__ == "__main__":
    main()
