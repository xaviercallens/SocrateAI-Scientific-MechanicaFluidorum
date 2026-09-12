"""TIER B — dynamic access: does the Galerkin dynamics scramble adversarial alignment?

REGISTRATION: docs/designs/DYNAMIC_ACCESS.md section 3, with AMENDMENT 7 (scheme-fidelity
criterion; amplitude-scaled regime) recorded there before this version's first run. Ordered
by the Deep Think adjudication of 2026-09-12 and the owner's order to continue on the harder
part.

THE MAP. Forward Euler on Gaussian-rational Galerkin states, exactly:
    Phi(u) = u + dt * F(u),   F_k = -nu |k|^2 u_k + B(u,u)_k,   dt, nu in Q.
Not the flow. Its energy budget is E' - E = -2 dt nu D + dt^2 ||F||^2, with the second term a
pure discretisation artifact. A step COUNTS only if that artifact is at most one tenth of the
physical dissipation (the fidelity criterion); a run with any disqualified step is reported
DISQUALIFIED and no hypothesis is read from it.

THE EXACT INVARIANT, a gift from Task 2.2: since Re<u,B(u,u)> = 0 is Tier A,
    E(Phi u) - E(u) + 2 dt nu D(u) - dt^2 ||F(u)||^2 = 0   EXACTLY,
asserted at every step -- a DYNAMIC regression of energy_conservation. Divergence-freeness and
conjugate symmetry are asserted at every step too.

REGIMES: lambda = 1 (the original amplitudes; expected DISQUALIFIED -- kept as the control on
the criterion itself) and lambda = 1/20 (weakly nonlinear; injection ratio ~ lambda^2).

HYPOTHESES, registered, read only from qualified runs:
  H-scramble  from the adversarial IC, rho falls toward the null level.
  H-quiet     from the null IC, rho does not rise.
  consistency the dt = 1/32 and dt = 1/64 runs must agree in DIRECTION at the common time.

STOP REASON (LL-18): fixed step counts (4 and 8) to a common time 1/8; no adaptive horizon.
Exact rationals; no float anywhere; integer sizes reported by bit length, never by string.
"""

import pathlib
import sys
from fractions import Fraction

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from tier_b_fourier_enstrophy import (  # noqa: E402
    G, ball, k_sq, B, check_state, u_at,
)
from tier_b_production_cancellation import (  # noqa: E402
    make_family_state, measure, phases_random, half_ball, SEEDS,
)
from tier_b_production_cancellation import dec as _dec  # noqa: E402
from tier_b_adversarial_alignment import (  # noqa: E402
    geometric_table, greedy_align,
)

ZERO = G(0, 0)
M = 2
NU = Fraction(1, 20)
T_END = Fraction(1, 8)
FIDELITY = Fraction(1, 10)
LAMBDAS = (Fraction(1), Fraction(1, 20))
DTS = (Fraction(1, 32), Fraction(1, 64))


def dec(x, places=4):
    return _dec(x, places)


def norm_sq_vec(v):
    return sum(c.re * c.re + c.im * c.im for c in v)


def energy(u):
    return sum(norm_sq_vec(u_at(u, k)) for k in ball(M))


def dissipation(u):
    return sum(k_sq(k) * norm_sq_vec(u_at(u, k)) for k in ball(M))


def rhs(u):
    F = {}
    for k in ball(M):
        b = B(M, u, k)
        uk = u_at(u, k)
        F[k] = [G(-NU * k_sq(k)) * uk[i] + b[i] for i in range(3)]
    return F


def euler_step(u, dt):
    F = rhs(u)
    return {k: [u_at(u, k)[i] + G(dt) * F[k][i] for i in range(3)] for k in ball(M)}, F


def scale(u, lam):
    return {k: [G(lam) * c for c in u_at(u, k)] for k in ball(M)}


def adversarial_ic():
    table = geometric_table(M)
    classes = sorted({c for a, b, c2, _, _ in table for c in (a, b, c2)})
    signs, _, _ = greedy_align(table, classes, {c: 1 for c in classes})
    phases = {c: G(0, signs[c]) for c in classes}
    for k in half_ball(M):
        phases.setdefault(k, G(0, 1))
    return make_family_state(M, phases, 0)


def bits(u):
    return max(c.re.denominator.bit_length() for k in ball(M) for c in u_at(u, k))


def run(u0, dt, label):
    steps = int(T_END / dt)
    u = u0
    rhos = []
    ok = True
    qualified = True
    worst_ratio = Fraction(0)
    for n in range(steps + 1):
        rho, _, _, _, integ = measure(M, u)
        ok &= integ
        div_ok, conj_ok, mean_ok = check_state(M, u)
        ok &= div_ok and conj_ok and mean_ok
        rhos.append(rho)
        if n == steps:
            print(f"   {label} dt={str(dt):>4} step {n:>2} t={dec(n * dt)} rho {dec(rho)} "
                  f"E {dec(energy(u), 3)} [den {bits(u)} bits]")
            break
        u_new, F = euler_step(u, dt)
        inj = dt * dt * sum(norm_sq_vec(F[k]) for k in ball(M))
        diss = 2 * dt * NU * dissipation(u)
        residual = energy(u_new) - energy(u) + diss - inj
        if residual != 0:
            print(f"      ENERGY-STEP IDENTITY VIOLATED: residual {residual}")
            ok = False
        ratio = inj / diss if diss else Fraction(10 ** 9)
        worst_ratio = max(worst_ratio, ratio)
        if ratio > FIDELITY:
            qualified = False
        print(f"   {label} dt={str(dt):>4} step {n:>2} t={dec(n * dt)} rho {dec(rho)} "
              f"E {dec(energy(u), 3)} [den {bits(u)} bits] inj/diss {dec(ratio, 3)}"
              f"{'' if ratio <= FIDELITY else '  <- step DISQUALIFIED'}")
        u = u_new
    return rhos, ok, qualified, worst_ratio


def main() -> int:
    print("== TIER B: dynamic access — the Euler map on adversarial and null states ==")
    print(f"   M={M}, nu={NU}, horizon t={T_END}, dt in {tuple(str(d) for d in DTS)}, "
          f"lambda in {tuple(str(l) for l in LAMBDAS)}; fidelity: inj/diss <= {FIDELITY}.\n")
    ok = True
    base_adv = adversarial_ic()
    base_null = make_family_state(M, phases_random(M, SEEDS[0]), 0)

    verdicts = []
    for lam in LAMBDAS:
        print(f"-- lambda = {lam} " + "-" * 50)
        results = {}
        for label, u0 in (("ADV ", scale(base_adv, lam)), ("NULL", scale(base_null, lam))):
            for dt in DTS:
                rhos, ok_run, qual, worst = run(u0, dt, label)
                ok &= ok_run
                results[(label.strip(), dt)] = (rhos, qual, worst)
            print()
        for label in ("ADV", "NULL"):
            (r32, q32, w32), (r64, q64, w64) = results[(label, DTS[0])], results[(label, DTS[1])]
            qual = q32 and q64
            start, e32, e64 = r32[0], r32[-1], r64[-1]
            d32 = "fell" if e32 < start else ("rose" if e32 > start else "held")
            d64 = "fell" if e64 < start else ("rose" if e64 > start else "held")
            agree = d32 == d64
            tag = "QUALIFIED" if qual else "DISQUALIFIED by fidelity"
            print(f"   {label} lambda={lam}: {tag}; worst inj/diss {dec(max(w32, w64), 3)}; "
                  f"rho {dec(start)} -> {dec(e32)} ({d32}) | -> {dec(e64)} ({d64}); "
                  f"directions agree: {agree}")
            verdicts.append((lam, label, qual and agree, d32 if agree else "n/a", start,
                             min(e32, e64), max(e32, e64)))
        print()

    print("== registered hypotheses, read ONLY from qualified, consistent runs ==")
    for lam, label, readable, d, s, lo, hi in verdicts:
        if not readable:
            print(f"   lambda={lam} {label}: not readable (disqualified or inconsistent)")
            continue
        if label == "ADV":
            print(f"   lambda={lam} ADV : H-scramble (rho falls): {d == 'fell'}   "
                  f"[{dec(s)} -> {dec(lo)}..{dec(hi)}]")
        else:
            print(f"   lambda={lam} NULL: H-quiet (rho does not rise): {d != 'rose'}   "
                  f"[{dec(s)} -> {dec(lo)}..{dec(hi)}]")
    print("   Scope: a few Euler steps at M = 2 in the weakly nonlinear regime are a direction")
    print("   of travel, not a result about the limit or Hypothesis U. O5 stands.")

    if not ok:
        print("\nDYNAMIC ACCESS GATE: FAIL (integrity)")
        return 1
    print("\nDYNAMIC ACCESS GATE: PASS (integrity; findings above are data)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
