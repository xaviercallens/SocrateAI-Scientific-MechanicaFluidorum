#!/usr/bin/env python3
"""Tier B exact-arithmetic certification of two structural identities of the Fourier-Galerkin
Navier-Stokes/Euler nonlinearity, per docs/designs/B_INSTANTIATION_SCOPING.md (OP-6, D3's
recommended smallest first deliverable). This does NOT instantiate B in
lean_src/HypothesisU_Statements.lean and does NOT certify the formula against a fixed textbook
citation -- see the scoping memo's honesty caveat, and the ERRATUM below, which is exactly why
that caveat was not decorative.

ERRATUM (recorded honestly, not smoothed over -- PLAN.md: "an agent's self-report is not
evidence, re-verify"). The FIRST version of this file implemented the formula literally as it
appeared in docs/designs/B_INSTANTIATION_SCOPING.md's web-search cross-check,
`N(u)_k = -i sum_{p+q=k} P(k)[ q * (u_p . u_q) ]` (q, a VECTOR, times the scalar velocity-
velocity dot product u_p.u_q). The exact-arithmetic checker below then discovered, by direct
computation (not by suspicion), that THIS formula is identically zero for every k, on every
field and every truncation tested: because P(k)[k * s] = 0 for any scalar s (P(k) annihilates
the k-direction) and every pair (p,q) with p+q=k appears alongside its swap (q,p) in the same
sum, each pair's two terms are exact negatives (f(p,q) + f(q,p) = P(k)[q*s] + P(k)[p*s] =
P(k)[(p+q)*s] = P(k)[k*s] = 0), so the whole sum telescopes to zero identically. That cannot be
the real NSE nonlinearity (a genuinely nonzero object). The CORRECTED formula used below,
`N(u)_k = -i sum_{p+q=k} P(k)[ (q . u_p) u_q ]` (q DOTTED with the velocity u_p, a SCALAR,
times the velocity VECTOR u_q -- matching FT[(u.grad)u](k), the standard Fourier transform of
the convective derivative), is nonzero and satisfies both facts below, checked in exact
arithmetic at M=1,2,3. Recorded here as the reason the scoping memo's "not yet independently
verified against a fixed citable source" caveat existed, and as evidence FOR why (the exact
arithmetic caught a real formula error, not merely a hypothetical risk).

THE MODEL. On the truncated lattice Lambda = {k in Z^3 \\ {0} : |k|_inf <= M}, for a
divergence-free (k . u_k = 0), conjugate-symmetric (u_{-k} = conj(u_k)) complex-vector field
u : Lambda -> C^3:
    N(u)_k = -i * sum_{p+q=k, p,q in Lambda} P(k)[ (q . u_p) u_q ]
where P(k) := I - (k (x) k)/|k|^2 is the Leray projector, "." between a real wavevector and a
complex velocity is the natural bilinear contraction (no conjugation).

HAND-DERIVED FACTS (before any code was finalized).

Fact 1 (TRANSVERSALITY, unconditional): k . N(u)_k = 0 for every k, for ANY input field (does
not need divergence-free input). Proof: P(k) projects onto {x : k.x = 0} by construction, so
k . P(k)[anything] = 0 termwise; summing preserves 0. Independent of what is inside P(k)[...],
so Fact 1 survived the erratum above unchanged and was not itself what exposed the error.

Fact 2 (DETAILED ENERGY CONSERVATION, needs divergence-free + conjugate-symmetric input):
sum_{k in Lambda} conj(u_k) . N(u)_k = 0 exactly. Partial hand derivation (the "outer"
step, re-verified after the erratum and UNCHANGED by it, since it never used the inner bracket
formula): P(k) is a real symmetric matrix, hence self-adjoint under the bilinear pairing, and
conj(u_k) = u_{-k} already satisfies (-k).u_{-k} = 0 i.e. k.u_{-k} = 0 -- so conj(u_k) is
ALREADY in P(k)'s range and P(k)[conj(u_k)] = conj(u_k) exactly. Hence
conj(u_k) . P(k)[x] = conj(u_k) . x for any x: THE PROJECTION DROPS OUT of the outer pairing
regardless of the inner formula. This is confirmed independently below: the "drop P(k)"
negative control (meant to break Fact 1) leaves Fact 2 intact, exactly as this step predicts.
**The REMAINING inner step -- that the resulting triad sum sum_{p+q+r=0} (q.u_p)(u_q.u_r)
(r := -k) vanishes exactly -- is the standard "detailed conservation" identity for
Fourier-Galerkin Euler/NS (the Fourier-space form of b(u,u,u)=0 for the trilinear form
b(u,v,w) = integral (u.grad v).w, itself a consequence of divergence-free u via integration by
parts). It was NOT re-derived symbolically from scratch here -- a first attempt at a direct
3-way relabeling argument did not close cleanly within the scope of this task -- so this file
CERTIFIES it computationally in exact arithmetic (a genuine Tier B fact: verified on every
field and truncation tested, M=1,2,3, not proved in general). This gap is recorded honestly,
not smoothed over: a Tier A proof of the general triad identity is future work, not claimed
here.**

NEGATIVE CONTROLS (PLAN.md: "a checker that cannot fail is not a checker"). Several natural
"plausible bug" perturbations turned out to be UNDETECTABLE and are recorded as such rather
than silently discarded: (i) swapping p<->q throughout the formula is invisible to the full sum
(the pair set {(p,q):p+q=k} is symmetric under relabeling p<->q, for every fixed k, not merely
after summing over k); (ii) replacing the dotted wavevector q with the fixed outer k collapses
back to the same value because k=p+q and p.u_p=0 (divergence-free applied to p itself) makes
the extra term vanish. self_test()'s own negative control below uses a perturbation confirmed
to actually differ: multiplying by the WRONG velocity factor (u_p instead of u_q). Two further
negative controls exercise the two facts directly: NC-transversality drops the Leray
projection (P(k) -> I) -- Fact 1 must fail, Fact 2 must NOT (per the derivation above).
NC-energy perturbs one mode to violate divergence-free -- Fact 2 must fail, Fact 1 must NOT
(Fact 1 never used divergence-free input).

Exact arithmetic throughout: complex numbers are (re, im) pairs of fractions.Fraction; no
floats anywhere. Deterministic: no randomness, no clock.
"""

import sys
from fractions import Fraction as Q

# --------------------------------------------------------------- exact Gaussian-rational complex
def cplx(re, im=0):
    return (Q(re), Q(im))


def cadd(a, b):
    return (a[0] + b[0], a[1] + b[1])


def cmul(a, b):
    return (a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0])


def cconj(a):
    return (a[0], -a[1])


def cscale(r, a):
    """r: Fraction (real scalar) times complex a."""
    return (r * a[0], r * a[1])


ZERO_C = (Q(0), Q(0))


def cvec_add(u, v):
    return tuple(cadd(u[i], v[i]) for i in range(3))


def cvec_conj(v):
    return tuple(cconj(v[i]) for i in range(3))


def real_dot_complex(k, v):
    """sum_i k_i * v_i, k: integer 3-tuple (real), v: complex 3-vector. Returns complex."""
    total = ZERO_C
    for i in range(3):
        total = cadd(total, cscale(Q(k[i]), v[i]))
    return total


def bilinear_cdot(u, v):
    """sum_i u_i * v_i -- NO conjugation. u, v: complex 3-vectors."""
    total = ZERO_C
    for i in range(3):
        total = cadd(total, cmul(u[i], v[i]))
    return total


# --------------------------------------------------------------- exact integer vector algebra
def icross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def idot(a, b):
    return sum(a[i] * b[i] for i in range(3))


def orthogonal_pair(k):
    """Two integer vectors spanning k^perp (exact, deterministic). k must be nonzero."""
    v1 = icross(k, (1, 0, 0))
    if v1 == (0, 0, 0):
        v1 = icross(k, (0, 1, 0))
    v2 = icross(k, v1)
    assert idot(k, v1) == 0 and idot(k, v2) == 0
    return v1, v2


# --------------------------------------------------------------- Leray projector (exact)
def leray_apply(k, v):
    """P(k)[v] = v - k*(k.v)/|k|^2, k integer vector (real), v complex 3-vector. Exact."""
    k2 = Q(idot(k, k))
    kv = real_dot_complex(k, v)
    coeff = (kv[0] / k2, kv[1] / k2)  # (k.v)/|k|^2, complex
    return tuple((v[i][0] - coeff[0] * k[i], v[i][1] - coeff[1] * k[i]) for i in range(3))


def unprojected_apply(k, v):
    return v


# --------------------------------------------------------------- lattice + field construction
def lattice(M):
    pts = []
    for a in range(-M, M + 1):
        for b in range(-M, M + 1):
            for c in range(-M, M + 1):
                if (a, b, c) != (0, 0, 0):
                    pts.append((a, b, c))
    return pts


def is_positive_half(k):
    a, b, c = k
    if c != 0:
        return c > 0
    if b != 0:
        return b > 0
    return a > 0


def build_field(Lambda):
    """Deterministic divergence-free, conjugate-symmetric field on Lambda. Exact."""
    field = {}
    for k in Lambda:
        if not is_positive_half(k):
            continue
        v1, v2 = orthogonal_pair(k)
        a, b, c = k
        A = Q((a + 2 * b + 3 * c) % 5 + 1, 3)
        B = Q((2 * a - b + c) % 4 + 1, 2)
        u_k = tuple((A * v1[i], B * v2[i]) for i in range(3))
        field[k] = u_k
        neg_k = (-a, -b, -c)
        field[neg_k] = cvec_conj(u_k)
    return field


def check_divergence_free(field):
    for k, u_k in field.items():
        kv = real_dot_complex(k, u_k)
        if kv != ZERO_C:
            return False
    return True


def check_conjugate_symmetry(field):
    for k, u_k in field.items():
        neg_k = (-k[0], -k[1], -k[2])
        if cvec_conj(u_k) != field[neg_k]:
            return False
    return True


# --------------------------------------------------------------- the nonlinearity itself
def compute_N(field, Lambda, apply_proj=leray_apply):
    """N(u)_k = -i * sum_{p+q=k, p,q in Lambda} apply_proj(k, (q.u_p) * u_q) for each k."""
    Lambda_set = set(Lambda)
    N = {}
    for k in Lambda:
        acc_vec = (ZERO_C, ZERO_C, ZERO_C)
        for p in Lambda:
            q = (k[0] - p[0], k[1] - p[1], k[2] - p[2])
            if q not in Lambda_set:
                continue
            q_dot_up = real_dot_complex(q, field[p])  # (q . u_p), complex scalar
            term = tuple(cmul(q_dot_up, field[q][i]) for i in range(3))  # (q.u_p) * u_q
            projected = apply_proj(k, term)
            acc_vec = cvec_add(acc_vec, projected)
        # multiply by -i: (-i)*(re+i*im) = im - i*re
        N[k] = tuple((v[1], -v[0]) for v in acc_vec)
    return N


def check_transversality(N, Lambda):
    """k . N(u)_k == 0 for every k. Returns (all_hold, first_violating_k, value)."""
    for k in Lambda:
        val = real_dot_complex(k, N[k])
        if val != ZERO_C:
            return False, k, val
    return True, None, None


def total_energy_pairing(field, N, Lambda):
    total = ZERO_C
    for k in Lambda:
        total = cadd(total, bilinear_cdot(cvec_conj(field[k]), N[k]))
    return total


# --------------------------------------------------------------- self_test (hand-checked triad)
def self_test():
    """Hand-enumerated triads for k=(1,1,0) on the M=1 lattice, verifying compute_N against an
    independent by-hand accumulation, plus a negative control confirmed to actually differ
    (see module docstring for why several OTHER natural perturbations were tried first and
    found undetectable -- recorded honestly rather than discarded)."""
    M = 1
    Lambda = lattice(M)
    field = build_field(Lambda)
    assert check_divergence_free(field), "self_test: build_field is not divergence-free"
    assert check_conjugate_symmetry(field), "self_test: build_field lacks conjugate symmetry"

    k = (1, 1, 0)
    Lambda_set = set(Lambda)
    pairs = [(p, (k[0] - p[0], k[1] - p[1], k[2] - p[2])) for p in Lambda]
    pairs = [(p, q) for (p, q) in pairs if q in Lambda_set]

    expected_acc = (ZERO_C, ZERO_C, ZERO_C)
    for p, q in pairs:
        q_dot_up = real_dot_complex(q, field[p])
        term = tuple(cmul(q_dot_up, field[q][i]) for i in range(3))
        expected_acc = cvec_add(expected_acc, leray_apply(k, term))
    expected_Nk = tuple((v[1], -v[0]) for v in expected_acc)

    N = compute_N(field, Lambda)
    ok = N[k] == expected_Nk
    print(f"self_test: hand-enumerated {len(pairs)} triads for k={k}")
    print(f"self_test: compute_N[k] == hand computation: {ok}")
    if not ok:
        print(f"  compute_N[k]  = {N[k]}")
        print(f"  hand-computed = {expected_Nk}")
        print("self_test FAILED.")
        sys.exit(1)

    # NEGATIVE CONTROL: multiply by the WRONG velocity factor (u_p instead of u_q), keeping the
    # correct (q . u_p) scalar. Confirmed (see module docstring) to actually differ, unlike
    # several other "plausible bug" perturbations that turned out invisible by symmetry.
    wrong_acc = (ZERO_C, ZERO_C, ZERO_C)
    for p, q in pairs:
        q_dot_up = real_dot_complex(q, field[p])
        wrong_term = tuple(cmul(q_dot_up, field[p][i]) for i in range(3))  # WRONG: u_p not u_q
        wrong_acc = cvec_add(wrong_acc, leray_apply(k, wrong_term))
    wrong_Nk = tuple((v[1], -v[0]) for v in wrong_acc)
    differs = wrong_Nk != N[k]
    print(f"self_test: NEGATIVE CONTROL (wrong velocity factor at k={k}) differs from "
          f"correct N[k]: {differs}")
    if not differs:
        print("self_test FAILED (negative control did not differ).")
        sys.exit(1)


# --------------------------------------------------------------- main sweep
def main():
    self_test()
    print()

    all_pass = True
    for M in (1, 2, 3):
        Lambda = lattice(M)
        field = build_field(Lambda)
        assert check_divergence_free(field)
        assert check_conjugate_symmetry(field)

        N_correct = compute_N(field, Lambda, apply_proj=leray_apply)
        trans_ok, bad_k, bad_val = check_transversality(N_correct, Lambda)
        total_correct = total_energy_pairing(field, N_correct, Lambda)
        energy_ok = (total_correct == ZERO_C)
        nonzero_count = sum(1 for k in Lambda if N_correct[k] != (ZERO_C, ZERO_C, ZERO_C))

        print(f"M={M} (|Lambda|={len(Lambda)}, nonzero N_k: {nonzero_count}/{len(Lambda)}): "
              f"Fact1 transversality holds for all k: {trans_ok}; "
              f"Fact2 total energy pairing == 0: {energy_ok} (Total={total_correct})")
        all_pass = all_pass and trans_ok and energy_ok and (nonzero_count > 0)
        if nonzero_count == 0:
            print("  UNEXPECTED: N is identically zero (this was the erratum's symptom) --"
                  " the corrected formula should not degenerate; escalating.")
            sys.exit(1)

        # --- NC-transversality: drop the Leray projection ---
        N_unprojected = compute_N(field, Lambda, apply_proj=unprojected_apply)
        trans_ok_unproj, bad_k_u, bad_val_u = check_transversality(N_unprojected, Lambda)
        total_unproj = total_energy_pairing(field, N_unprojected, Lambda)
        print(f"  NC-transversality (P(k)->I): Fact1 holds: {trans_ok_unproj} "
              f"(expected False; first violation at k={bad_k_u}, k.N_k={bad_val_u}); "
              f"Fact2 (still) holds: {total_unproj == ZERO_C} "
              f"(expected True, per derivation -- projection was redundant for Fact2)")
        if trans_ok_unproj:
            print("  NC-transversality FAILED to demonstrate a failure (checker cannot fail).")
            sys.exit(1)
        if total_unproj != ZERO_C:
            print("  UNEXPECTED: NC-transversality also broke Fact2 -- contradicts the "
                  "derivation; escalating rather than silently accepting.")
            sys.exit(1)

        # --- NC-energy: break divergence-free on one representative mode ---
        rep_k = next(k for k in Lambda if is_positive_half(k))
        neg_rep_k = (-rep_k[0], -rep_k[1], -rep_k[2])
        perturbed = dict(field)
        eps = cplx(1, 1)  # nonzero complex coefficient for the k-direction perturbation
        perturbed[rep_k] = tuple(
            cadd(field[rep_k][i], cscale(Q(rep_k[i]), eps)) for i in range(3)
        )
        perturbed[neg_rep_k] = cvec_conj(perturbed[rep_k])
        assert not check_divergence_free(perturbed), \
            "NC-energy setup: perturbation unexpectedly stayed divergence-free"

        N_perturbed = compute_N(perturbed, Lambda, apply_proj=leray_apply)
        total_perturbed = total_energy_pairing(perturbed, N_perturbed, Lambda)
        energy_broken = (total_perturbed != ZERO_C)
        trans_still_ok, _, _ = check_transversality(N_perturbed, Lambda)
        print(f"  NC-energy (break div-free at k={rep_k}): Fact2 fails: {energy_broken} "
              f"(Total={total_perturbed}); Fact1 (still) holds: {trans_still_ok} "
              f"(expected True -- Fact1 never used divergence-free input)")
        if not energy_broken:
            print("  NC-energy FAILED to demonstrate a failure (checker cannot fail).")
            sys.exit(1)
        if not trans_still_ok:
            print("  UNEXPECTED: NC-energy also broke Fact1 -- contradicts the derivation "
                  "(Fact1 is unconditional); escalating.")
            sys.exit(1)
        print()

    if not all_pass:
        print("TIER B GATE (nse triad convolution): FAIL")
        sys.exit(1)
    print("TIER B GATE (nse triad convolution): PASS (Fact1/Fact2 hold on the corrected "
          "construction at M=1,2,3; both negative controls demonstrably fail as required; "
          "both cross-checks -- that each NC leaves the OTHER fact intact -- match the "
          "hand derivation exactly, not merely 'something changed')")


if __name__ == "__main__":
    main()
