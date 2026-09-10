"""TIER B — the frame factors of the helical production expansion (WP-1c step 1).

DERIVATION: docs/designs/HELICAL_PRODUCTION_EXPANSION.md, ordered by the owner's adjudication of
2026-09-10 (Q3: phase mixing is the live track; Next Step 2: expand the exact enstrophy
production sum in the helical basis).

WHAT IS CHECKED, in the triad's own frame N = p x q with the unnormalised basis
h^s(x) = N x x + i s |x| N of HelicalBasis.hOf:

  I1:  q . h^{s_p}(p)  =  |N|^2                                -- INDEPENDENT of s_p
  I2:  h^{s_q}(q) .bil h^{s_r}(r)  =  |N|^2 ( (q.r) - s_q s_r |q||r| )

WHY THEY MATTER. Substituted into the kernel-checked production sum, they give the per-triad
helical expansion: the stretched leg couples only to the CHIRALITY-BLIND amplitude combination
(I1), and handedness enters production only through the |q||r|-weighted chirality-odd channel
(I2) -- which is also the only place a square root, hence anything genuinely Diophantine about
the lattice, survives. The memo records the gauge-legitimacy argument: each production term is
gauge-free as written, and the frame enters and leaves within a single term, unlike the retracted
cross-triad claim of the Waleffe memo's section 6bis.

EXACT, NO FLOATS. |p|, |q|, |r| are formal symbols with integer polynomial coefficients, as in
tier_b_helical_closed_form.py, whose machinery this file reuses.
"""

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from tier_b_helical_closed_form import (  # noqa: E402
    MP, MQ, MK, const, padd, pmul, psub, hOf, cdot, crossZ, k_sq, vadd,
)

MR = MK  # the third magnitude symbol carries |r|

SIGNS = (1, -1)

TRIADS = [
    ((0, -1, 1), (1, 2, -1)),      # the owner's crucible triad
    ((1, 0, 0), (0, 1, 0)),
    ((3, 1, -2), (-1, 4, 2)),
    ((2, -1, 3), (1, 5, -2)),
    ((-2, 3, 1), (4, -1, 2)),
    ((5, 0, 1), (2, -3, 7)),
]


def neg(v):
    return (-v[0], -v[1], -v[2])


def dot_int(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def int_dot_polyvec(a, V):
    """The bilinear contraction of an integer vector against a polynomial 3-vector."""
    out = {}
    for i in range(3):
        out = padd(out, pmul(const(a[i]), V[i]))
    return out


def check_I1(frame_offset=None):
    """Cases where I1 fails. `frame_offset` perturbs the frame off the triad (control)."""
    bad = 0
    for p, q in TRIADS:
        N = crossZ(p, q)
        if frame_offset is not None:
            N = vadd(N, frame_offset)
        for sp in SIGNS:
            if int_dot_polyvec(q, hOf(N, sp, p, MP)) != const(k_sq(N)):
                bad += 1
    return bad


def check_I2(mismatch_symbol=False):
    """Cases where I2 fails. `mismatch_symbol` replaces |q||r| by |q|^2 (control)."""
    bad = 0
    for p, q in TRIADS:
        r = neg(vadd(p, q))
        N = crossZ(p, q)
        n2 = k_sq(N)
        odd = pmul(MQ, MQ) if mismatch_symbol else pmul(MQ, MR)
        for sq in SIGNS:
            for sr in SIGNS:
                lhs = cdot(hOf(N, sq, q, MQ), hOf(N, sr, r, MR))
                rhs = psub(const(n2 * dot_int(q, r)), pmul(const(n2 * sq * sr), odd))
                if lhs != rhs:
                    bad += 1
    return bad


def main() -> int:
    n1 = len(TRIADS) * 2
    n2 = len(TRIADS) * 4
    print("== TIER B: the frame factors of the helical production expansion ==")
    print(f"   {len(TRIADS)} triads; magnitudes are formal symbols; exact integers.\n")

    ok = True

    bad1 = check_I1()
    print(f"  I1  q.h^s(p) = |N|^2, independent of s : {n1 - bad1}/{n1} cases"
          f"   {'-> HOLDS' if bad1 == 0 else '-> FAILS'}")
    ok &= bad1 == 0

    bad2 = check_I2()
    print(f"  I2  h^sq(q).h^sr(r) = |N|^2((q.r) - sq sr |q||r|) : {n2 - bad2}/{n2} cases"
          f"   {'-> HOLDS' if bad2 == 0 else '-> FAILS'}")
    ok &= bad2 == 0

    print("\n== negative controls (each MUST fail) ==")

    c1 = check_I1(frame_offset=(1, 0, 0))
    print(f"  N1 perturb the frame off the triad: I1 fails in {c1}/{n1} "
          f"{'(rejected as required)' if c1 else '*** DID NOT FAIL ***'}")
    ok &= c1 > 0

    c2 = check_I2(mismatch_symbol=True)
    print(f"  N2 |q|^2 in place of |q||r| in the odd channel: I2 fails in {c2}/{n2} "
          f"{'(rejected as required)' if c2 else '*** DID NOT FAIL ***'}")
    ok &= c2 > 0

    if not ok:
        print("\nHELICAL EXPANSION GATE: FAIL")
        return 1

    print("\nHELICAL EXPANSION GATE: PASS")
    print("  Scope: two exact identities and their controls. No bound, no uniformity, no")
    print("  cancellation claim -- those await the pre-registered measurement of the memo's")
    print("  section 4, nulls first. SPEC obstruction O5 stands.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
