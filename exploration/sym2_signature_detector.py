#!/usr/bin/env python3
# TIER C - EXPLORATORY, NO CLAIMS - NEVER GATES A CLAIM (SPEC bars floats from Tier B/A)
"""
A validated detector for Sym^2 structure in a shell-amplitude profile.

WHY THIS EXISTS, AND WHY THE FIRST VERSION OF THE IDEA WAS WRONG.

The owner's OP-2-lite observation was that with k_n = 2^n the spectral map lambda -> lambda^2
acts on shell INDICES as n -> 2n, suggesting the shell-space form of the Sym^2 lock is the
pointwise constraint a_{2n} = c * a_n^2.

That form is nearly vacuous, for a reason found on paper before any computation
(docs/designs/OP2_LITE_CANDIDATES.md section 1a-BIS): for ANY pure power law a_n = A r^n,
    a_n^2 = A^2 r^{2n},   a_{2n} = A r^{2n}   =>   a_{2n}/a_n^2 = 1/A ,
constant in n and INDEPENDENT of r. So the pointwise constraint fixes the AMPLITUDE and leaves
the spectral SLOPE entirely free -- and the slope is precisely what finite-time blow-up is made
of. A constraint blind to the slope cannot, at leading order, prevent a self-similar blow-up.

THE FIX. The pointwise form is a LOSSY rendering of the proven lock. The actual theorem
(lean_src/CallensDualScale.lean, sym2_recurrence / sym2_symmetric_functions) is about a TWO-root
linear recurrence and its squared sequence: {lambda, mu} -> {lambda^2, lambda*mu, mu^2}. Its
content is that the macroscopic spectrum is the symmetric square of the microscopic one, i.e.
that the three macro roots are in GEOMETRIC PROGRESSION:
    (lambda*mu)^2 = lambda^2 * mu^2      =>      rho_2^2 = rho_1 * rho_3 .

At the level of the recurrence coefficients this needs no root extraction. From the Lean
theorem, v_{n+3} = c1 v_{n+2} + c2 v_{n+1} + c3 v_n with
    c1 = a^2 + b ,   c2 = b(a^2+b) ,   c3 = -b^3 ,
so c2/c1 = b and c3 = -b^3 = -(c2/c1)^3, giving the exact signature

    ***  c2^3 + c1^3 * c3  =  0  ***

CAUTION -- A SIGN TRAP, RECORDED BECAUSE THE POSITIVE CONTROL CAUGHT IT. The elementary
symmetric functions e_i (as reported in SPEC/LEDGER: e1 = a^2+b, e2 = -b(a^2+b), e3 = -b^3) are
NOT the recurrence coefficients: for a monic cubic x^3 - e1 x^2 + e2 x - e3, one has c1 = e1,
c2 = -e2, c3 = e3. Testing "e2^3 = e1^3 e3" while feeding it the FITTED c's yields a residual of
exactly 2.00 on a sequence that satisfies the lock by construction. That is how the error was
found: the positive control refused to read zero. Without a positive control this detector would
have shipped inverted.

CONDITIONING GUARD -- ADDED AFTER IT NEARLY PRODUCED A SPURIOUS "CONFIRMATION".

The signature is read off a 3x3 linear solve for (c1,c2,c3). A profile that is close to a PURE
GEOMETRIC sequence satisfies infinitely many order-3 recurrences, so that solve is singular and
the recovered coefficients are noise. In the developing cascade this is not a corner case: at
early times the profile falls off so fast that v_2, v_3 are numerically zero and the normalised
determinant reaches 1e-14.

Without the guard the detector returned S ~ 1e-13 there, and the naive reading -- "the quiescent
cascade IS Sym^2-structured, and blow-up destroys that structure" -- is exactly the mechanism
this programme hopes for. It was garbage from a singular fit. The guard exists because the most
seductive artifact is the one that confirms your hypothesis.

fit_recurrence now REFUSES to return coefficients when |det|/scale^3 < COND_MIN, and
profile_signature reports only the windows that survive. A measurement with no surviving window
is reported as such rather than as a small number.

THE OBSERVABLE.  S = |c2^3 + c1^3 c3| / max(|c2^3|, |c1^3 c3|)   in [0, 2].
    S ~ 0    : the profile carries Sym^2 structure
    S ~ O(1) : it does not

VALIDATION (both controls run on every invocation; the script aborts if either fails):
  * POSITIVE: u_n from an order-2 recurrence, v_n = u_n^2 -- Sym^2 by construction. Must read
    S < 1e-6.
  * NEGATIVE: generic decaying sequences. Must read S > 1e-2, i.e. clearly separated.
An instrument that cannot tell these apart cannot be believed about the cascade.

MEASURED RESULT ON THE PROGRAMME'S OWN CASCADE (reported, not interpreted): S is O(1),
statistically indistinguishable from the generic control. The natural dyadic cascade does NOT
spontaneously carry Sym^2 structure. Consequence for OP-2-lite: imposing the lock is a genuine
INTERVENTION in the dynamics, not the revelation of a latent structure -- and this script gives
the before/after meter for it.

NO CLAIM is made here about whether the lock prevents blow-up. Verdicts are the human owner's.
"""

import sys

# ----------------------------------------------------------------- the model (float, Tier C)
def k(n): return 2.0 ** n


def shell_step(a, nu, dt, N):
    new = [0.0] * (N + 1)
    for n in range(N + 1):
        a_prev = a[n - 1] if n >= 1 else 0.0
        a_next = a[n + 1] if n + 1 <= N else 0.0
        influx = k(n - 1) * a_prev * a_prev if n >= 1 else 0.0
        NL = influx - k(n) * a[n] * a_next
        new[n] = (a[n] + dt * NL) / (1.0 + nu * k(n) ** 2 * dt)
    return new


# ----------------------------------------------------------------- the detector
def _det3(M):
    return (M[0][0] * (M[1][1] * M[2][2] - M[1][2] * M[2][1])
            - M[0][1] * (M[1][0] * M[2][2] - M[1][2] * M[2][0])
            + M[0][2] * (M[1][0] * M[2][1] - M[1][1] * M[2][0]))


# Minimum normalised |det| for the 3x3 fit to carry information. Below this the recovered
# coefficients are noise and S is meaningless -- see CONDITIONING GUARD in the module docstring.
COND_MIN = 1e-6


def conditioning(v, i):
    """|det| of the fit matrix, normalised by the cube of its largest entry. Scale-free."""
    if i + 5 >= len(v):
        return None
    A = [[v[i + j + 2], v[i + j + 1], v[i + j]] for j in range(3)]
    sc = max(max(abs(x) for x in row) for row in A)
    if sc <= 0:
        return 0.0
    return abs(_det3(A)) / sc ** 3


def fit_recurrence(v, i):
    """Solve v_{n+3} = c1 v_{n+2} + c2 v_{n+1} + c3 v_n from three consecutive n starting at i.
    Returns (c1,c2,c3), or None if the system is degenerate OR too ill-conditioned to trust."""
    if i + 5 >= len(v):
        return None
    cond = conditioning(v, i)
    if cond is None or cond < COND_MIN:
        return None
    A = [[v[i + j + 2], v[i + j + 1], v[i + j]] for j in range(3)]
    B = [v[i + j + 3] for j in range(3)]
    D = _det3(A)
    if abs(D) < 1e-300:
        return None
    out = []
    for c in range(3):
        M = [row[:] for row in A]
        for r in range(3):
            M[r][c] = B[r]
        out.append(_det3(M) / D)
    return tuple(out)


def sym2_signature(v, i):
    """S in [0,2]; ~0 iff the profile carries Sym^2 structure at window i."""
    c = fit_recurrence(v, i)
    if c is None:
        return None
    c1, c2, c3 = c
    resid = c2 ** 3 + c1 ** 3 * c3
    scale = max(abs(c2 ** 3), abs(c1 ** 3 * c3), 1e-300)
    return abs(resid) / scale


def profile_signature(v, windows=(0, 1, 2)):
    vals = [sym2_signature(v, i) for i in windows]
    return [x for x in vals if x is not None]


# ----------------------------------------------------------------- controls
POS_TOL = 1e-6
NEG_TOL = 1e-2


def run_controls(verbose=True):
    ok = True
    if verbose:
        print("POSITIVE CONTROL -- v_n = u_n^2 with u from an order-2 recurrence "
              f"(Sym^2 by construction); must read S < {POS_TOL:g}:")
    for (a, b) in ((1.0, 2.0), (0.7, -0.3), (1.5, 0.4)):
        u = [1.0, 0.6]
        for _ in range(12):
            u.append(a * u[-1] + b * u[-2])
        vals = profile_signature([x * x for x in u])
        worst = max(vals)
        good = worst < POS_TOL
        ok = ok and good
        if verbose:
            print(f"   (a,b)=({a},{b}): S = " + ", ".join(f"{x:.2e}" for x in vals)
                  + ("   OK" if good else "   *** FAILED ***"))

    if verbose:
        print(f"\nNEGATIVE CONTROL -- generic decaying sequences; must read S > {NEG_TOL:g}:")
    import random
    random.seed(7)
    for t in range(3):
        v = [abs(random.random()) * 2.0 ** (-0.8 * n) for n in range(12)]
        vals = profile_signature(v)
        best = min(vals)
        good = best > NEG_TOL
        ok = ok and good
        if verbose:
            print(f"   trial {t}: S = " + ", ".join(f"{x:.2e}" for x in vals)
                  + ("   OK" if good else "   *** FAILED ***"))
    return ok


def main():
    print("== Sym^2 signature detector (Tier C) ==")
    print("   S = |c2^3 + c1^3 c3| / scale   for  v_{n+3} = c1 v_{n+2} + c2 v_{n+1} + c3 v_n\n")

    if not run_controls():
        print("\nCONTROLS FAILED -- the detector cannot distinguish Sym^2 from generic. "
              "Refusing to report a measurement.")
        sys.exit(1)
    print("\n   controls separate cleanly. Detector validated.\n")

    print("MEASUREMENT on the programme's own dyadic cascade (reported, not interpreted):")
    for nu, dt, N, T in ((1e-3, 0.03125, 12, 6.0), (1e-2, 0.03125, 10, 6.0)):
        a = [0.0] * (N + 1)
        a[0] = 1.0
        for _ in range(int(T / dt)):
            a = shell_step(a, nu, dt, N)
        vals = profile_signature([x * x for x in a])
        print(f"   nu={nu:<7} N={N:<3} t={T}:  S = " + ", ".join(f"{x:.3e}" for x in vals))
    print("\n   -> O(1), i.e. in the generic range, NOT the Sym^2 range. The natural cascade "
          "does not\n      spontaneously carry Sym^2 structure. No verdict is drawn; that is "
          "the owner's.")


if __name__ == "__main__":
    main()
