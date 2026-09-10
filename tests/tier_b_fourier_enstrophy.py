"""TIER B — the 3-D Fourier enstrophy production, end to end on a GENUINE Galerkin state.

NOT to be confused with `tests/tier_b_enstrophy_production.py`, which certifies the DYADIC SHELL
model's production identity. This file is about the Fourier–Galerkin system on `ℤ³`.

WHY THIS FILE EXISTS, AND WHAT GAP IT CLOSES.
`FourierDynamicsZ3.enstrophy_production_identity` is an equation, and an equation can be true of
nothing. Its non-vacuity had been argued from `tests/tier_b_weighted_triad.py`, which imposes
divergence-freeness but **not** conjugate symmetry `u(-k) = conj(u(k))` or the zero-mean condition.
A real `GalerkinState` carries all three. So that argument established non-vacuity for a strictly
LARGER class than the theorem quantifies over — which is not the same thing, and the difference is
exactly the reality condition on the velocity field. This file closes the gap by building genuine
Galerkin states and computing on them.

It also checks the whole Lean chain end to end against a brute-force evaluation from the
definitions — the Leray drop, the reindexing onto `triadSet`, and the weighted identity. Nothing
here reuses the Lean proofs' structure; `B` is rebuilt from `convective` and `applyLeray` directly.

EXACT, NO FLOATS. Amplitudes are Gaussian rationals, pairs of `fractions.Fraction`. The Leray
projector is rational (`δ_ij − k_i k_j / |k|²`), so every quantity below is exact.

THE CONSTRUCTION, which makes all three constraints hold at once and exactly:

    u_k := k × a_k        orthogonal to k, hence divergence-free, for any a_k;
    a_{-k} := −conj(a_k)  forces u_{-k} = k × conj(a_k) = conj(u_k), because k is a real integer
                          vector — so conjugate symmetry is exact, not approximate;
    u_0 = 0 × a_0 = 0     so the zero-mean condition is automatic.

WHAT IS CHECKED
  1. the state really is divergence-free, conjugate-symmetric and zero-mean, exactly;
  2. the ENERGY production vanishes exactly — Task 2.2 confirmed on a concrete state;
  3. the ENSTROPHY production does NOT vanish — the gap this file exists to close;
  4. `2 · production = −i Σ (|r|²−|q|²)(q·u_p)(u_q·u_r)` over `triadSet` — the Lean identity,
     checked against brute force.

SCOPE. An identity checked on one state. Not a bound, and not a statement about uniformity in the
truncation, which is the whole content of Hypothesis U. SPEC obstruction O5 stands.
"""

from fractions import Fraction
from itertools import product


# ---------------------------------------------------------------------------
# Exact Gaussian rationals.
# ---------------------------------------------------------------------------

class G:
    __slots__ = ("re", "im")

    def __init__(self, re=0, im=0):
        self.re = Fraction(re)
        self.im = Fraction(im)

    def __add__(self, o):
        return G(self.re + o.re, self.im + o.im)

    def __sub__(self, o):
        return G(self.re - o.re, self.im - o.im)

    def __neg__(self):
        return G(-self.re, -self.im)

    def __mul__(self, o):
        return G(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re)

    def __truediv__(self, f):
        f = Fraction(f)
        return G(self.re / f, self.im / f)

    def conj(self):
        return G(self.re, -self.im)

    def __eq__(self, o):
        return self.re == o.re and self.im == o.im

    def __bool__(self):
        return self.re != 0 or self.im != 0

    def __repr__(self):
        sign = "+" if self.im >= 0 else "-"
        return f"({self.re} {sign} {abs(self.im)}i)"


ZERO = G(0, 0)
ONE = G(1, 0)
I = G(0, 1)


# ---------------------------------------------------------------------------
# Lattice, mirroring FourierDynamicsZ3 exactly.
# ---------------------------------------------------------------------------

def k_sq(k):
    return k[0] ** 2 + k[1] ** 2 + k[2] ** 2


def neg(k):
    return (-k[0], -k[1], -k[2])


def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def ball(M):
    """FourierDynamicsZ3.ball: the cube [-M,M]^3 filtered by k_sq <= M^2."""
    return [k for k in product(range(-M, M + 1), repeat=3) if k_sq(k) <= M * M]


def cross_int_g(k, a):
    """k cross a, with k an integer vector and a a Gaussian-rational vector."""
    ki = [G(x) for x in k]
    return [ki[1] * a[2] - ki[2] * a[1],
            ki[2] * a[0] - ki[0] * a[2],
            ki[0] * a[1] - ki[1] * a[0]]


def fourier_dot(k, v):
    """FourierStateZ3.fourier_dot: sum_i (k_i) * v_i, bilinear against an integer wavevector."""
    out = ZERO
    for i in range(3):
        out = out + G(k[i]) * v[i]
    return out


def bilinear(v, w):
    """AbstractAlgebraicConservation.dot: the UNCONJUGATED form."""
    out = ZERO
    for i in range(3):
        out = out + v[i] * w[i]
    return out


def pairing(a, b):
    """FourierDynamicsZ3.pairing: sum_i conj(a_i) * b_i, the Hermitian outer pairing."""
    out = ZERO
    for i in range(3):
        out = out + a[i].conj() * b[i]
    return out


def apply_leray(k, v):
    """FourierStateZ3.applyLeray: delta_ij - k_i k_j / k_sq, or the identity at k = 0."""
    ks = k_sq(k)
    out = []
    for i in range(3):
        acc = ZERO
        for j in range(3):
            p = ONE if i == j else ZERO
            if ks != 0:
                p = p - G(k[i] * k[j]) / ks
            acc = acc + p * v[j]
        out.append(acc)
    return out


# ---------------------------------------------------------------------------
# A genuine Galerkin state.
# ---------------------------------------------------------------------------

def make_state(M, seed_pairs):
    """u : wavevector -> Gaussian-rational 3-vector, supported in ball M, divergence-free,
    conjugate-symmetric and zero-mean, all exactly."""
    amps = {}
    for k, a in seed_pairs:
        assert k_sq(k) <= M * M, f"seed {k} lies outside the ball"
        amps[k] = [G(x, y) for x, y in a]
        amps[neg(k)] = [-c.conj() for c in amps[k]]

    u = {}
    for k in ball(M):
        a = amps.get(k)
        u[k] = cross_int_g(k, a) if a is not None else [ZERO, ZERO, ZERO]
    return u


def u_at(u, k):
    return u.get(k, [ZERO, ZERO, ZERO])


def convective(M, u, k):
    """FourierDynamicsZ3.convective: sum over p in ball of (-i)(q.u_p) u_q, with q = k - p."""
    out = [ZERO, ZERO, ZERO]
    for p in ball(M):
        q = sub(k, p)
        coef = (-I) * fourier_dot(q, u_at(u, p))
        uq = u_at(u, q)
        for i in range(3):
            out[i] = out[i] + coef * uq[i]
    return out


def B(M, u, k):
    return apply_leray(k, convective(M, u, k))


# ---------------------------------------------------------------------------
# The two productions, and the closed form.
# ---------------------------------------------------------------------------

def production(M, u, weight):
    out = ZERO
    for k in ball(M):
        out = out + G(weight(k)) * pairing(u_at(u, k), B(M, u, k))
    return out


def triad_set(M):
    bm = set(ball(M))
    return [(p, q) for p in ball(M) for q in ball(M) if neg(add(p, q)) in bm]


def closed_form(M, u, weight, use_sum=False):
    """-i * sum over triadSet of (w(r) -/+ w(q)) * (q.u_p) * (u_q.u_r)."""
    out = ZERO
    for p, q in triad_set(M):
        r = neg(add(p, q))
        coeff = weight(r) + weight(q) if use_sum else weight(r) - weight(q)
        if coeff == 0:
            continue
        term = fourier_dot(q, u_at(u, p)) * bilinear(u_at(u, q), u_at(u, r))
        out = out + G(coeff) * term
    return (-I) * out


# ---------------------------------------------------------------------------

M = 2

SEEDS = [
    ((1, 0, 0), ((1, 0), (0, 1), (2, -1))),
    ((0, 1, 0), ((0, 1), (3, 0), (1, 1))),
    ((1, 1, 0), ((2, 1), (-1, 2), (0, 1))),
    ((1, -1, 1), ((1, 1), (1, 0), (-2, 1))),
    ((2, 0, 0), ((0, 2), (1, -1), (1, 0))),
]

ONE_WEIGHT = lambda k: 1          # noqa: E731  -- energy
KSQ_WEIGHT = k_sq                 # enstrophy


def check_state(M, u):
    div_ok = all(not fourier_dot(k, u_at(u, k)) for k in ball(M))
    conj_ok = all(all(u_at(u, neg(k))[i] == u_at(u, k)[i].conj() for i in range(3))
                  for k in ball(M))
    mean_ok = not any(u_at(u, (0, 0, 0))[i] for i in range(3))
    return div_ok, conj_ok, mean_ok


def main() -> int:
    print("== TIER B: the 3-D Fourier enstrophy production, on a GENUINE Galerkin state ==")
    print(f"   ball M = {M} ({len(ball(M))} modes), {len(SEEDS)} seeded mode pairs,")
    print("   exact Gaussian rationals; no float is constructed anywhere in this file.\n")

    u = make_state(M, SEEDS)
    ok = True

    div_ok, conj_ok, mean_ok = check_state(M, u)
    print("-- the test field satisfies every GalerkinState constraint, exactly")
    print(f"   divergence-free   k . u_k = 0        : {div_ok}")
    print(f"   conjugate-symmetric u(-k) = conj u_k : {conj_ok}")
    print(f"   zero mean         u_0 = 0            : {mean_ok}")
    ok &= div_ok and conj_ok and mean_ok
    if not ok:
        print("FOURIER ENSTROPHY GATE: FAIL (the test field is not a Galerkin state)")
        return 1

    nonzero = sum(1 for k in ball(M) if any(u_at(u, k)))
    print(f"   modes with nonzero amplitude         : {nonzero} / {len(ball(M))}\n")

    print("-- Task 2.2 confirmed on a concrete state: the ENERGY production vanishes")
    ep = production(M, u, ONE_WEIGHT)
    print(f"   sum_k <u_k, B_k> = {ep}"
          f"   {'-> EXACTLY ZERO' if not ep else '-> NONZERO, contradicting energy_conservation'}")
    ok &= not ep

    print("\n-- the gap this file closes: the ENSTROPHY production does NOT vanish")
    zp = production(M, u, KSQ_WEIGHT)
    print(f"   sum_k |k|^2 <u_k, B_k> = {zp}")
    if not zp:
        print("   -> FAILED: it vanished, so enstrophy_production_identity is about nothing")
        ok = False
    else:
        print("   -> NONZERO on a field carrying ALL THREE constraints, conjugate symmetry")
        print("      included. The identity is non-vacuous for the class it quantifies over.")

    print("\n-- the Lean identity, checked against brute force")
    lhs = G(2) * zp
    rhs = closed_form(M, u, KSQ_WEIGHT)
    print(f"   2 * production : {lhs}")
    print(f"   closed form    : {rhs}")
    agree = lhs == rhs
    print(f"   {'-> AGREE' if agree else '-> DISAGREE'}")
    ok &= agree

    print("\n-- and at constant weight the same closed form returns the energy statement")
    lhs_c, rhs_c = G(2) * ep, closed_form(M, u, ONE_WEIGHT)
    both_zero = (not lhs_c) and (not rhs_c)
    print(f"   2 * energy production = {lhs_c}, closed form = {rhs_c}"
          f"   {'-> both zero' if both_zero else '-> FAILED'}")
    ok &= both_zero

    print("\n-- the production comes out REAL, as a physical production must")
    print(f"   imaginary part of sum_k |k|^2 <u_k, B_k> : {zp.im}")
    print("   (not asserted by the Lean identity, which is a complex equation; the physical")
    print("    production is its real part, and on a conjugate-symmetric field it is the whole)")
    ok &= zp.im == 0

    print("\n== negative controls (each MUST fail) ==")

    n1 = closed_form(M, u, KSQ_WEIGHT, use_sum=True) != lhs
    print(f"  N1 sum of the weights instead of the difference : "
          f"{'rejected as required' if n1 else '*** DID NOT FAIL ***'}")
    ok &= n1

    n2 = closed_form(M, u, lambda k: 0) != lhs
    print(f"  N2 assert enstrophy conserves as energy does    : "
          f"{'rejected as required' if n2 else '*** DID NOT FAIL ***'}")
    ok &= n2

    # Divergence-freeness is the one hypothesis the whole derivation turns on. Break it at a
    # single mode -- keeping conjugate symmetry, so ONLY that hypothesis is lost -- and the
    # identity must break.
    u_bad = make_state(M, SEEDS)
    e1 = (1, 0, 0)
    u_bad[e1] = [u_bad[e1][0] + ONE, u_bad[e1][1], u_bad[e1][2]]
    u_bad[neg(e1)] = [u_bad[neg(e1)][0] + ONE, u_bad[neg(e1)][1], u_bad[neg(e1)][2]]
    div_bad, conj_bad, _ = check_state(M, u_bad)
    lhs_bad = G(2) * production(M, u_bad, KSQ_WEIGHT)
    rhs_bad = closed_form(M, u_bad, KSQ_WEIGHT)
    n3 = (not div_bad) and conj_bad and (lhs_bad != rhs_bad)
    print(f"  N3 break divergence-freeness at one mode        : "
          f"{'rejected as required' if n3 else '*** DID NOT FAIL ***'}")
    print(f"     divergence-free now {div_bad}, conjugate symmetry preserved {conj_bad}, "
          f"identity holds {lhs_bad == rhs_bad}")
    ok &= n3

    print("\n== a second state, reported rather than over-read ==")
    shell_seeds = [((1, 0, 0), ((1, 0), (0, 1), (2, -1))),
                   ((0, 1, 0), ((0, 1), (3, 0), (1, 1))),
                   ((0, 0, 1), ((1, 1), (2, 0), (0, 1)))]
    u_shell = make_state(M, shell_seeds)
    zp_shell = production(M, u_shell, KSQ_WEIGHT)
    lhs_s, rhs_s = G(2) * zp_shell, closed_form(M, u_shell, KSQ_WEIGHT)
    print(f"  seeds all on the unit sphere: production = {zp_shell}, identity holds = "
          f"{lhs_s == rhs_s}")
    print("  DO NOT read this as evidence for the same-sphere criterion. The production is")
    print("  zero here for a DEGENERATE reason: three vectors drawn from +-{e1,e2,e3} cannot")
    print("  sum to zero (three odd contributions cannot cancel coordinatewise), so the")
    print("  support admits no non-degenerate triad at all and every term dies for want of a")
    print("  triad, not for want of a weight difference.")
    ok &= (lhs_s == rhs_s)

    if not ok:
        print("\nFOURIER ENSTROPHY GATE: FAIL")
        return 1

    print("\nFOURIER ENSTROPHY GATE: PASS")
    print("  Scope: an identity checked on concrete states. Not a bound, and not a statement")
    print("  about uniformity in M, which is the whole content of Hypothesis U. O5 stands.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
