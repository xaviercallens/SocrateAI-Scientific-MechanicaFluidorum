"""TIER B — the weighted triad identity: why energy conserves and enstrophy does not.

DERIVATION: docs/designs/WEIGHTED_TRIAD_IDENTITY.md (DRAFT, awaiting the owner's
statement-adequacy audit). FORMALISED: AbstractAlgebraicConservation.weighted_triad_pairing
and weighted_triad_sum.

WHAT IS CHECKED. For a triad p + q + r = 0 and any weight w,

    w(r)*dot(q)(u_p)*dot(u_q)(u_r) + w(q)*dot(r)(u_p)*dot(u_r)(u_q)
      =  (w(r) - w(q)) * dot(q)(u_p) * dot(u_q)(u_r)

given only divergence-freeness at p. The two orderings of a triad differ in the weight and in
nothing else, so their sum is the weight DIFFERENCE times a common factor.

WHY IT MATTERS. Energy conservation is the constant-weight case: w(r) - w(q) = 0 and the pair
cancels. Enstrophy carries w = |.|^2, the difference does not vanish, and what survives is
exactly vortex stretching -- a triad transfers enstrophy in proportion to how UNEQUAL in
wavenumber its two swapped members are. The obstruction is carried by that one factor and by
nothing about the geometry, the chirality, or the lattice.

WHAT IS *NOT* CHECKED, AND MUST NOT BE READ IN. This is an identity, not a bound; it gives no
estimate on the production. It says nothing about uniformity in the truncation, which is the
whole content of Hypothesis U -- SPEC obstruction O5 stands untouched. And it is not new
mathematics: the enstrophy production of the Fourier-Galerkin system is classical. What is new
is only that it is checked in the same abstract form as the energy identity.

EXACT, NO FLOATS. Divergence-freeness is imposed BY CONSTRUCTION rather than approximated:
u_x := x cross a_x is orthogonal to x for any integer a_x, exactly. Every quantity below is a
Python int.
"""

from itertools import product


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def neg(a):
    return (-a[0], -a[1], -a[2])


def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def k_sq(a):
    return dot(a, a)


# (p, q, a_p, a_q, a_r). The last entry is a degenerate case: p and q collinear.
CASES = [
    ((1, 0, 0), (0, 1, 0), (2, -1, 3), (1, 1, 1), (0, 2, -1)),
    ((3, 1, -2), (-1, 4, 2), (1, 0, 5), (2, -3, 1), (4, 1, 0)),
    ((0, -1, 1), (1, 2, -1), (3, 3, 1), (-2, 1, 4), (1, -1, 2)),
    ((5, -2, 1), (-3, 4, 6), (0, 1, 1), (7, 2, -5), (1, 3, 2)),
    ((1, 2, 3), (-4, 1, 2), (2, 2, 2), (1, -1, 0), (3, 0, 1)),
    ((2, 2, 2), (4, 4, 4), (1, 0, 0), (0, 1, 0), (0, 0, 1)),
]

WEIGHTS = {
    "constant (energy)": lambda x: 1,
    "k_sq (enstrophy)": k_sq,
    "k_sq squared": lambda x: k_sq(x) ** 2,
    "first component": lambda x: x[0],
}


def triad(case):
    """Returns (p, q, r, u_p, u_q, u_r) with divergence-freeness exact by construction."""
    p, q, ap, aq, ar = case
    r = neg(add(p, q))
    up, uq, ur = cross(p, ap), cross(q, aq), cross(r, ar)
    assert dot(p, up) == 0 and dot(q, uq) == 0 and dot(r, ur) == 0
    return p, q, r, up, uq, ur


def pair_sum(case, w):
    """The left-hand side: the two orderings of the triad, weighted."""
    p, q, r, up, uq, ur = triad(case)
    return w(r) * dot(q, up) * dot(uq, ur) + w(q) * dot(r, up) * dot(ur, uq)


def closed_form(case, w, swap_weights=False, use_sum=False, drop_div=False):
    """The right-hand side, with the negative-control knobs."""
    p, q, r, up, uq, ur = triad(case)
    if drop_div:
        # break divergence-freeness at p while leaving everything else alone
        up = (up[0] + 1, up[1], up[2])
    wr, wq = w(r), w(q)
    if swap_weights:
        wr, wq = wq, wr
    coeff = (wr + wq) if use_sum else (wr - wq)
    return coeff * dot(q, up) * dot(uq, ur)


def pair_sum_div_broken(case, w):
    p, q, r, up, uq, ur = triad(case)
    up = (up[0] + 1, up[1], up[2])
    return w(r) * dot(q, up) * dot(uq, ur) + w(q) * dot(r, up) * dot(ur, uq)


def sweep(**knobs):
    """Returns (checked, mismatches)."""
    checked = mismatches = 0
    for case in CASES:
        for w in WEIGHTS.values():
            checked += 1
            lhs = (pair_sum_div_broken(case, w) if knobs.get("drop_div")
                   else pair_sum(case, w))
            if lhs != closed_form(case, w, **knobs):
                mismatches += 1
    return checked, mismatches


def main() -> int:
    total = len(CASES) * len(WEIGHTS)
    print("== TIER B: the weighted triad identity, exact integers ==")
    print(f"   {len(CASES)} triads x {len(WEIGHTS)} weights = {total} cases;")
    print("   divergence-freeness imposed by construction, u_x = x cross a_x.\n")

    ok = True

    checked, mismatches = sweep()
    print(f"  the pair identity holds : {checked - mismatches} / {checked}")
    if mismatches:
        print("WEIGHTED TRIAD GATE: FAIL")
        return 1
    print("  -> the two orderings differ in the weight and in nothing else.\n")

    print("-- energy conservation is the constant-weight case")
    const_nonzero = sum(1 for case in CASES if pair_sum(case, WEIGHTS["constant (energy)"]) != 0)
    print(f"   pairs failing to cancel with constant weight : {const_nonzero} / {len(CASES)}"
          f"   {'-> ALL CANCEL, as the energy identity requires' if const_nonzero == 0 else '-> FAILED'}")
    ok &= const_nonzero == 0

    print("\n-- and it is the ONLY case that cancels: the identity is not vacuous")
    for name, w in WEIGHTS.items():
        nz = sum(1 for case in CASES if pair_sum(case, w) != 0)
        print(f"   w = {name:22s} : {nz} / {len(CASES)} pairs have a NONZERO sum")
        if name != "constant (energy)" and nz == 0:
            print("   -> FAILED: a non-constant weight cancelled everywhere, so section 4(c) is empty")
            ok = False

    print("\n-- the sharp vanishing criterion: |q| = |r| kills the enstrophy term")
    # An isoceles triad: q and r share a sphere, so the enstrophy weight difference vanishes.
    p_iso, q_iso = (2, 0, 0), (-1, 1, 0)
    r_iso = neg(add(p_iso, q_iso))
    same_shell = k_sq(q_iso) == k_sq(r_iso)
    iso_case = (p_iso, q_iso, (0, 1, 1), (1, 0, 2), (2, 1, 0))
    iso_sum = pair_sum(iso_case, k_sq)
    print(f"   p={p_iso}, q={q_iso}, r={r_iso}: |q|^2={k_sq(q_iso)}, |r|^2={k_sq(r_iso)}, "
          f"same shell={same_shell}")
    print(f"   enstrophy pair sum : {iso_sum}"
          f"   {'-> vanishes, as the criterion predicts' if iso_sum == 0 else '-> FAILED'}")
    ok &= same_shell and iso_sum == 0

    print("\n== negative controls (each MUST fail) ==")
    for label, knobs in (
        ("N1 exchange the two weights, w(q) - w(r)", {"swap_weights": True}),
        ("N2 use the SUM of the weights, not the difference", {"use_sum": True}),
        ("N3 break divergence-freeness at p", {"drop_div": True}),
    ):
        _, m = sweep(**knobs)
        print(f"  {label}: {m} / {total} mismatches "
              f"{'(rejected as required)' if m else '*** DID NOT FAIL ***'}")
        ok &= m > 0

    # N4: assert the weighted pair cancels, as the constant-weight case does.
    n4 = sum(1 for case in CASES
             for name, w in WEIGHTS.items()
             if name != "constant (energy)" and pair_sum(case, w) != 0)
    print(f"  N4 assert the pair cancels for a NON-constant weight: {n4} counterexamples "
          f"{'(rejected as required)' if n4 else '*** DID NOT FAIL ***'}")
    ok &= n4 > 0

    if not ok:
        print("\nWEIGHTED TRIAD GATE: FAIL")
        return 1

    print("\nWEIGHTED TRIAD GATE: PASS")
    print("  Scope reminder: this is an IDENTITY, not a bound. It gives no estimate on the")
    print("  enstrophy production and says nothing about uniformity in the truncation, which")
    print("  is the whole content of Hypothesis U. SPEC obstruction O5 stands.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
