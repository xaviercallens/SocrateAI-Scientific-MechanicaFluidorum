#!/usr/bin/env python3
"""Tier B exact-arithmetic validation harness (spec §1, §4).

All checks run in exact rational arithmetic (fractions.Fraction) — floating
point is barred by the Tier B gate.  Deterministic: no randomness, no clock.

Checks:
  B1. Sym² lock, constant coefficients (mirrors Lean `sym2_recurrence`,
      Tier A): if u_{n+2} = a u_{n+1} + b u_n and v = u², then
      v_{n+3} = (a²+b) v_{n+2} + b(a²+b) v_{n+1} − b³ v_n.
  B2. Sym² lock, variable coefficients (mirrors prior-tree
      `sym2_recurrence_variable`, convention u_{n+2} + aₙ u_{n+1} + bₙ uₙ = 0).
  B3. Reff laws over ℚ, sqrt-free forms (squares comparison):
      bounce, inertial invisibility, T-duality, and Reff² ≥ α.
  B4. Guess-and-prove probe: recover the L3 = Sym²(L2) coefficients by exact
      linear solving from sequence data alone, and confirm they match the
      closed forms of B1 (counterexample-before-attack, §5.3).

Exit status 0 iff every check passes.
"""

from fractions import Fraction as Q
from itertools import product
import sys

FAILURES = []


def check(name, cond, detail=""):
    if not cond:
        FAILURES.append((name, detail))
        print(f"  FAIL {name}: {detail}")


# ---------------------------------------------------------------- B1
def b1_sym2_constant():
    print("[B1] Sym² lock, constant coefficients (exact ℚ sweep)")
    vals = [Q(-2), Q(-1), Q(-1, 3), Q(1, 2), Q(1), Q(3), Q(7, 5)]
    cases = 0
    for a, b, u0, u1 in product(vals, vals, [Q(1), Q(-1, 2)], [Q(0), Q(2, 3)]):
        u = [u0, u1]
        for n in range(12):
            u.append(a * u[-1] + b * u[-2])
        v = [x * x for x in u]
        for n in range(len(u) - 3):
            lhs = v[n + 3]
            rhs = (a * a + b) * v[n + 2] + b * (a * a + b) * v[n + 1] - b**3 * v[n]
            check("B1", lhs == rhs, f"a={a} b={b} n={n}: {lhs} != {rhs}")
        cases += 1
    print(f"  {cases} (a,b,u0,u1) cases × 11 indices, all exact")


# ---------------------------------------------------------------- B2
def b2_sym2_variable():
    print("[B2] Sym² lock, variable coefficients (exact ℚ sweep)")
    # Convention of the prior Lean proof: u_{n+2} + a_n u_{n+1} + b_n u_n = 0,
    # A_n = -a_{n+1}(a_{n+1} a_n - b_{n+1})/a_n,
    # B_n =  a_{n+1} a_n b_{n+1} - b_{n+1}²,
    # C_n = -a_{n+1} b_{n+1} b_n² / a_n.
    def a(n):  # nonzero polynomial coefficients
        return Q(n + 1, 2)

    def b(n):
        return Q(2 * n - 3, 5)

    u = [Q(1), Q(1, 3)]
    for n in range(14):
        u.append(-(a(n) * u[-1] + b(n) * u[-2]))
    v = [x * x for x in u]
    for n in range(len(u) - 3):
        A = -a(n + 1) * (a(n + 1) * a(n) - b(n + 1)) / a(n)
        B = a(n + 1) * a(n) * b(n + 1) - b(n + 1) ** 2
        C = -a(n + 1) * b(n + 1) * b(n) ** 2 / a(n)
        residual = v[n + 3] + A * v[n + 2] + B * v[n + 1] + C * v[n]
        check("B2", residual == 0, f"n={n}: residual {residual}")
    print(f"  {len(u) - 3} indices, all exact")


# ---------------------------------------------------------------- B3
def b3_reff_laws():
    print("[B3] Reff laws over ℚ (sqrt-free: square comparisons)")

    def reff(alpha, R):
        return max(R, alpha / R)

    alphas = [Q(1), Q(4), Q(1, 4), Q(9, 2), Q(100, 7)]
    Rs = [Q(1, 10), Q(1, 2), Q(1), Q(3, 2), Q(2), Q(5), Q(50)]
    for alpha, R in product(alphas, Rs):
        e = reff(alpha, R)
        # T-dual bound (squared form of Reff_ge_sqrt): Reff² ≥ α
        check("B3.bound", e * e >= alpha, f"α={alpha} R={R}")
        # Bounce (squared form): R² < α ⇒ Reff = α/R
        if R * R < alpha:
            check("B3.bounce", e == alpha / R, f"α={alpha} R={R}")
        # Inertial invisibility: R² ≥ α ⇒ Reff = R
        if R * R >= alpha:
            check("B3.inertial", e == R, f"α={alpha} R={R}")
        # T-duality: Reff(α, α/R) = Reff(α, R)
        check("B3.tdual", reff(alpha, alpha / R) == e, f"α={alpha} R={R}")
    print(f"  {len(alphas) * len(Rs)} (α,R) pairs, all exact")


# ---------------------------------------------------------------- B4
def b4_guess_and_prove():
    print("[B4] Guess-and-prove: recover L3 coefficients from data (exact ℚ)")
    # Fit v_{n+3} = X v_{n+2} + Y v_{n+1} + Z v_n from 3 equations by
    # exact Gaussian elimination; compare with the closed form.
    a, b = Q(3, 2), Q(-5, 7)
    u = [Q(2), Q(-1, 3)]
    for n in range(10):
        u.append(a * u[-1] + b * u[-2])
    v = [x * x for x in u]
    rows = [[v[n + 2], v[n + 1], v[n], v[n + 3]] for n in range(3)]
    # exact Gaussian elimination
    for i in range(3):
        piv = next(r for r in range(i, 3) if rows[r][i] != 0)
        rows[i], rows[piv] = rows[piv], rows[i]
        rows[i] = [x / rows[i][i] for x in rows[i]]
        for r in range(3):
            if r != i and rows[r][i] != 0:
                f = rows[r][i]
                rows[r] = [x - f * y for x, y in zip(rows[r], rows[i])]
    X, Y, Z = rows[0][3], rows[1][3], rows[2][3]
    expX, expY, expZ = a * a + b, b * (a * a + b), -(b**3)
    check("B4.X", X == expX, f"{X} != {expX}")
    check("B4.Y", Y == expY, f"{Y} != {expY}")
    check("B4.Z", Z == expZ, f"{Z} != {expZ}")
    # The recovered operator must also predict unseen data
    for n in range(3, len(v) - 3):
        check("B4.predict", v[n + 3] == X * v[n + 2] + Y * v[n + 1] + Z * v[n],
              f"n={n}")
    print(f"  recovered (X,Y,Z)=({X},{Y},{Z}) — matches closed form, "
          f"predicts {len(v) - 6} unseen indices")


# ---------------------------------------------------------------- B5
def b5_sharpness_and_piecewise():
    """Mirrors the Tier A theorems added from the 2026-08-12 proposal review:
    Reff_eq_sqrt_iff (sharpness at the self-dual radius), tDualRadius_eq_Reff
    (piecewise = max, only for R > 0), and its witnessed failure for R < 0."""
    print("[B5] Sharpness at the self-dual radius + piecewise equivalence")

    def reff(alpha, R):
        return max(R, alpha / R)

    def tdual(alpha, R):  # piecewise form; sqrt-free test via R² < α
        return alpha / R if R * R < alpha else R

    # Perfect squares so √α is exactly rational and the self-dual point is exact.
    for alpha in [Q(1), Q(4), Q(9), Q(1, 4), Q(25, 16)]:
        num, den = alpha.numerator, alpha.denominator
        rs, ds = round(num ** 0.5), round(den ** 0.5)
        assert rs * rs == num and ds * ds == den, "test needs exact square α"
        s = Q(rs, ds)  # s = √α exactly
        # sharpness: equality exactly at the self-dual radius
        check("B5.attained", reff(alpha, s) == s, f"α={alpha}")
        for R in [Q(1, 7), Q(1, 2), Q(3, 4), Q(2), Q(11, 3), Q(20)]:
            if R != s:
                check("B5.strict", reff(alpha, R) > s, f"α={alpha} R={R}")
        # piecewise ≡ max on R > 0
        for R in [Q(1, 9), Q(1, 2), Q(1), Q(7, 2), Q(13)]:
            check("B5.piecewise", tdual(alpha, R) == reff(alpha, R),
                  f"α={alpha} R={R}")
    # witnessed necessity of the side condition R > 0 (junk-value discipline)
    check("B5.negative_R", tdual(Q(4), Q(-1)) != reff(Q(4), Q(-1)),
          "expected disagreement at α=4, R=-1")
    check("B5.negative_R_values",
          tdual(Q(4), Q(-1)) == Q(-4) and reff(Q(4), Q(-1)) == Q(-1),
          "expected -4 vs -1")
    print("  sharpness strict off the self-dual point; piecewise ≡ max for R>0; "
          "differs at R=-1 (−4 vs −1) as required")


# ---------------------------------------------------------------- B6
def b6_spectral_lock():
    """Mirrors Tier A `sym2_symmetric_functions`: the L3 coefficients are the
    elementary symmetric functions of {λ², λμ, μ²}.  Checked over ℚ using
    root pairs, which is the spectral content of L3 = Sym²(L2)."""
    print("[B6] Spectral form of the Sym² lock (elementary symmetric functions)")
    pairs = [(Q(2), Q(3)), (Q(-1), Q(5)), (Q(1, 2), Q(-3, 4)), (Q(7), Q(7)),
             (Q(-2, 5), Q(-2, 5))]
    for lam, mu in pairs:
        a, b = lam + mu, -(lam * mu)        # x² = a x + b has roots λ, μ
        r = [lam * lam, lam * mu, mu * mu]  # Sym² spectrum
        e1 = sum(r)
        e2 = r[0] * r[1] + r[0] * r[2] + r[1] * r[2]
        e3 = r[0] * r[1] * r[2]
        # L3: v_{n+3} = (a²+b) v_{n+2} + b(a²+b) v_{n+1} − b³ v_n
        # char.: x³ − e1 x² + e2 x − e3, so e1 = a²+b, e2 = −b(a²+b), e3 = −b³
        check("B6.e1", e1 == a * a + b, f"λ={lam} μ={mu}: {e1} != {a*a+b}")
        check("B6.e2", e2 == -(b * (a * a + b)), f"λ={lam} μ={mu}")
        check("B6.e3", e3 == -(b ** 3), f"λ={lam} μ={mu}")
        # and the squares of the L2 solution really satisfy L3
        u = [Q(1), lam + mu]
        for _ in range(8):
            u.append(a * u[-1] + b * u[-2])
        v = [x * x for x in u]
        for n in range(len(v) - 3):
            check("B6.orbit",
                  v[n + 3] == (a * a + b) * v[n + 2]
                  + b * (a * a + b) * v[n + 1] - b ** 3 * v[n],
                  f"λ={lam} μ={mu} n={n}")
    print(f"  {len(pairs)} root pairs: e1/e2/e3 match L3 coefficients exactly")


if __name__ == "__main__":
    b1_sym2_constant()
    b2_sym2_variable()
    b3_reff_laws()
    b4_guess_and_prove()
    b5_sharpness_and_piecewise()
    b6_spectral_lock()
    if FAILURES:
        print(f"\nTIER B GATE: FAIL ({len(FAILURES)} failures)")
        sys.exit(1)
    print("\nTIER B GATE: PASS (all checks exact, zero floating point)")
