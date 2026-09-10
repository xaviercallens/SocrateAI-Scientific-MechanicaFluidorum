"""TIER B — the pre-registered phase-mixing baseline: cancellation in the production sum.

REGISTRATION: docs/designs/HELICAL_PRODUCTION_EXPANSION.md section 4, including the three
exactness amendments recorded there BEFORE this file's first run (l1 modulus; rational
circle points for phases; k_sq-power spectral decay). Ordered by the owner's adjudication of
2026-09-10, Q3: phase mixing via transversality is the only live track, and its first
empirical contact must be measured against nulls before anything is interpreted (LL-11).

THE QUANTITY. Over triadSet M, with r = -(p+q), the production terms of the kernel-checked
identity 2P = -i * Sum t,   t(p,q) = (|r|^2 - |q|^2) (q.u_p) (u_q .bil u_r):

    rho(M)  =  l1( Sum t )  /  Sum l1( t ),      l1(z) = |Re z| + |Im z|  (exact rational).

rho near 1: the terms add coherently. rho near 0: they cancel. The sum is polynomial in the
amplitudes -- no square root anywhere -- so every number below is an exact Fraction.

THE FAMILIES (all conjugate-symmetric, divergence-free, zero-mean, exactly):
  F1 coherent     phases all 1, flat spectrum          (deterministic)
  F2 random-phase phases = rational circle points from a seeded LCG, flat spectrum
                  -- THE NULL: same moduli as F1, only the phases differ
  F3 decay        random phases, modulus (k_sq)^-gamma, gamma in {1, 2}

WHAT IS ASSERTED (gate) vs REPORTED (measurement). The gate checks INSTRUMENT INTEGRITY
only: state constraints hold exactly; each term equals its swap3 partner exactly (a free
identity: the weight difference and the divergence-free contraction both flip sign under
q <-> r); rho lies in [0,1]; the same seed reproduces the same numbers; and the term sum
agrees with the independently computed 2P of enstrophy_production_identity on a spot check.
The pre-registered comparisons (does F3 cancel at least as fast as the null F2? does F1
show coherence the instrument can detect?) are PRINTED AS FINDINGS with no verdict language:
verdicts belong to the owner.

STOP REASON (LL-18): the sweep runs the registered range M = 1..3 and stops because the
range is exhausted -- no adaptive stopping, no data-dependent horizon.
"""

import pathlib
import sys
from fractions import Fraction

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from tier_b_fourier_enstrophy import (  # noqa: E402
    G, ball, k_sq, neg, add, cross_int_g, fourier_dot, bilinear,
    production, closed_form, KSQ_WEIGHT, check_state, u_at,
)

ZERO = G(0, 0)
ONE_G = G(1, 0)

M_RANGE = (1, 2, 3)
SEEDS = list(range(1, 21))          # 20 seeds, registered
GAMMAS = (1, 2)                     # F3's registered exponents (gamma = 0 is F2)
LCG_A, LCG_C, LCG_MOD = 1103515245, 12345, 2 ** 31
PHASE_DEN = 97                      # denominator grid for the rational circle points


def l1(z: G) -> Fraction:
    return abs(z.re) + abs(z.im)


def lcg_stream(seed: int):
    x = (seed * 2654435761) % LCG_MOD
    while True:
        x = (LCG_A * x + LCG_C) % LCG_MOD
        yield x


def circle_point(t: Fraction) -> G:
    """((1 - t^2) + 2 t i) / (1 + t^2): exact unit l2-modulus, rational components."""
    den = 1 + t * t
    return G((1 - t * t) / den, 2 * t / den)


def half_ball(M: int):
    """One representative of each {k, -k} pair, k != 0."""
    out = []
    for k in ball(M):
        if k == (0, 0, 0):
            continue
        if k > neg(k):          # lexicographic representative
            out.append(k)
    return out


def direction(k):
    d = (1, 2, 3)
    if cross_int_g(k, [G(x) for x in d]) == [ZERO, ZERO, ZERO]:
        d = (1, 0, 0)
    return d


def make_family_state(M: int, phases, gamma: int):
    """phases: dict k -> G on the half ball. Returns u on ball M."""
    amps = {}
    for k in half_ball(M):
        mod = Fraction(1, k_sq(k) ** gamma) if gamma else Fraction(1)
        d = direction(k)
        a = [phases[k] * G(mod * x) for x in d]
        amps[k] = a
        amps[neg(k)] = [-c.conj() for c in a]
    u = {}
    for k in ball(M):
        a = amps.get(k)
        u[k] = cross_int_g(k, a) if a is not None else [ZERO, ZERO, ZERO]
    return u


def phases_coherent(M: int):
    return {k: ONE_G for k in half_ball(M)}


def phases_coherent_tilted(M: int):
    """F1' (registration amendment 4): one fixed NON-real phase for every mode.
    c != +-1 breaks the parity degeneracy that made F1 vanish identically, while keeping
    all phases aligned -- which is what 'coherent' was meant to mean."""
    c = circle_point(Fraction(1, 3))
    return {k: c for k in half_ball(M)}


def phases_random(M: int, seed: int):
    gen = lcg_stream(seed)
    out = {}
    for k in half_ball(M):
        r = next(gen) % (2 * PHASE_DEN)      # r in [0, 2*PHASE_DEN)
        t = Fraction(r - PHASE_DEN + 1, PHASE_DEN)   # t in (-1, 1]
        out[k] = circle_point(t)
    return out


def triad_terms(M: int, u):
    """Yields ((p,q), t) over triadSet M."""
    bm = set(ball(M))
    for p in ball(M):
        for q in ball(M):
            r = neg(add(p, q))
            if r not in bm:
                continue
            w = k_sq(r) - k_sq(q)
            t = G(w) * fourier_dot(q, u_at(u, p)) * bilinear(u_at(u, q), u_at(u, r))
            yield (p, q), t


def measure(M: int, u):
    """Returns (rho or None, l1_of_sum, sum_of_l1, n_terms, integrity_ok).

    Integrity folds two exact invariants: each term equals its swap3 partner, and the REAL
    part of the total is exactly zero — the negation pairing sends each term to minus its own
    conjugate for every conjugate-symmetric state (memo, second-run outcome, item 1)."""
    terms = {}
    total = ZERO
    denom = Fraction(0)
    for pq, t in triad_terms(M, u):
        terms[pq] = t
        total = total + t
        denom += l1(t)
    swap_ok = True
    for (p, q), t in terms.items():
        r = neg(add(p, q))
        if terms.get((p, r)) != t:
            swap_ok = False
            break
    re_zero = (total.re == 0)
    num = l1(total)
    rho = (num / denom) if denom else None
    return rho, num, denom, len(terms), swap_ok and re_zero


def dec(x, places=4):
    """Exact fixed-point decimal string of a Fraction; no float is constructed."""
    if x is None:
        return "  n/a "
    neg_s = "-" if x < 0 else ""
    x = abs(x)
    scaled = (x.numerator * 10 ** places) // x.denominator
    return f"{neg_s}{scaled // 10 ** places}.{str(scaled % 10 ** places).zfill(places)}"


def main() -> int:
    print("== TIER B: pre-registered phase-mixing baseline (production-sum cancellation) ==")
    print(f"   registered range M = {M_RANGE}, {len(SEEDS)} seeds, l1 modulus, exact rationals.\n")

    ok = True

    # -- instrument integrity: spot identity check on one random-phase state at M = 2
    u_spot = make_family_state(2, phases_random(2, SEEDS[0]), 0)
    div_ok, conj_ok, mean_ok = check_state(2, u_spot)
    twoP = G(2) * production(2, u_spot, KSQ_WEIGHT)
    cf = closed_form(2, u_spot, KSQ_WEIGHT)
    ident = (twoP == cf)
    print(f"-- integrity: F2 seed {SEEDS[0]} at M=2: constraints "
          f"{div_ok and conj_ok and mean_ok}, 2P == closed form {ident}")
    ok &= div_ok and conj_ok and mean_ok and ident

    # -- determinism: the same seed twice
    a = measure(2, make_family_state(2, phases_random(2, 7), 0))
    b = measure(2, make_family_state(2, phases_random(2, 7), 0))
    det = (a == b)
    print(f"-- integrity: seed 7 reproduces identically: {det}\n")
    ok &= det

    print(f"{'M':>2} {'family':<12} {'rho mean':>9} {'rho min':>9} {'rho max':>9} "
          f"{'terms':>6}")
    results = {}
    for M in M_RANGE:
        # F1 coherent (real phases; parity-degenerate -- see the memo's first-run outcome)
        u1 = make_family_state(M, phases_coherent(M), 0)
        ok &= all(check_state(M, u1))
        rho1, num1, _, nterms, swap1 = measure(M, u1)
        ok &= swap1 and (rho1 is None or 0 <= rho1 <= 1)
        results[(M, "F1")] = [rho1] if rho1 is not None else []
        exact0 = " (sum EXACTLY 0: parity)" if (rho1 is not None and num1 == 0) else ""
        print(f"{M:>2} {'F1 coherent':<12} {dec(rho1):>9} {dec(rho1):>9} {dec(rho1):>9} "
              f"{nterms:>6}{exact0}")

        # F1' tilted-coherent (amendment 4), deterministic
        u1t = make_family_state(M, phases_coherent_tilted(M), 0)
        ok &= all(check_state(M, u1t))
        rho1t, _, _, _, swap1t = measure(M, u1t)
        ok &= swap1t and (rho1t is None or 0 <= rho1t <= 1)
        results[(M, "F1'")] = [rho1t] if rho1t is not None else []
        print(f"{M:>2} {chr(39).join(['F1', ' tilted']):<12} {dec(rho1t):>9} {dec(rho1t):>9} "
              f"{dec(rho1t):>9}")

        for label, gamma in (("F2 null", 0),) + tuple(
                (f"F3 g={g}", g) for g in GAMMAS):
            rhos = []
            for seed in SEEDS:
                u = make_family_state(M, phases_random(M, seed), gamma)
                rho, _, _, _, swap_ok = measure(M, u)
                ok &= swap_ok and (rho is None or 0 <= rho <= 1)
                if rho is not None:
                    rhos.append(rho)
            results[(M, label)] = rhos
            mean = sum(rhos) / len(rhos) if rhos else None
            lo = min(rhos) if rhos else None
            hi = max(rhos) if rhos else None
            print(f"{M:>2} {label:<12} {dec(mean):>9} {dec(lo):>9} "
                  f"{dec(hi):>9} {'':>6}")

    print("\n-- stop reason (LL-18): registered range exhausted; no adaptive stopping.\n")

    print("== pre-registered comparisons, printed as findings (verdicts are the owner's) ==")
    for M in M_RANGE:
        f2 = results[(M, "F2 null")]
        if not f2:
            print(f"  M={M}: degenerate — every term is exactly zero (each unit-ball triad"
                  f" puts the zero mode in a killing slot); no ratio exists")
            continue
        m2 = sum(f2) / len(f2)
        line = [f"  M={M}: null mean {dec(m2)}"]
        for g in GAMMAS:
            f3 = results[(M, f"F3 g={g}")]
            m3 = sum(f3) / len(f3)
            rel = "<=" if m3 <= m2 else "> "
            line.append(f"F3(g={g}) {dec(m3)} {rel} null")
        r1 = results[(M, "F1")]
        r1t = results[(M, "F1'")]
        line.append(f"F1 {dec(r1[0]) if r1 else 'n/a'}")
        line.append(f"F1' {dec(r1t[0]) if r1t else 'n/a'}")
        print("   ".join(line))

    print("\n  Registered instrument control: F1 (coherent) must show rho well above the")
    print("  null, or the observable cannot detect coherence and measures nothing.")
    print("  Registered failure modes: F1 ~ F2 ~ F3 -> artifact; F3 slower than F2 ->")
    print("  phase mixing refuted for this observable.")

    if not ok:
        print("\nCANCELLATION BASELINE GATE: FAIL (instrument integrity)")
        return 1
    print("\nCANCELLATION BASELINE GATE: PASS (integrity only; findings above are data)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
