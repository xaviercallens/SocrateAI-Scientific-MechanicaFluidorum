// TIER C — EXPLORATORY, NO CLAIMS — NEVER GATES A CLAIM (SPEC bars floats from Tier B/A)
//! Triadic "frustration index" D(M) on the Galerkin ball Λ_M = {k ∈ ℤ³∖0 : |k|² ≤ M²}.
//!
//! WHY THIS FILE EXISTS. The 2026-09-09 memorandum (archived verbatim, Tier C, in
//! `docs/narrative/MANIFESTE_THEORIQUE_NS.md`) defines D(M) in words as
//!     (sum of ABSOLUTE triadic transfers on the ball) / (NET SIGNED transfer),
//! predicts D(M) ∝ M³ from a random-walk heuristic, and asks for the computation to be pushed
//! from M = 5 to M ≥ 20. The words leave three things open, and each choice changes the number:
//!   (1) WHICH signed sum — over the whole ball it is EXACTLY ZERO by detailed energy
//!       conservation (Tier A `triad_sum_zero`, Tier B fact 2), so that reading is vacuous;
//!   (2) ON WHICH FIELD — the transfers are cubic in u, so a field must be chosen;
//!   (3) AGAINST WHICH NULL — "random walk ⇒ M³" is what INDEPENDENT PHASES give, i.e. it is
//!       the null model's own prediction, not evidence for anything about dynamics.
//! Owner decision 2026-09-09: compute the three readings side by side, with the null model.
//! This file does exactly that and nothing else. It issues no verdict.
//!
//! THE MODEL (fixed by the repository's Tier B-certified formula, tests/tier_b_nse_triad_convolution.py):
//!     N(u)_k = -i Σ_{p+q=k} P(k)[ (q·u_p) u_q ]            (Leray-projected convective term)
//! Energy transfer INTO mode k:  T_k = Re[ conj(u_k) · N(u)_k ].  Because u_k is transverse, the
//! projection drops out of the pairing (Tier B derivation), so per ORDERED pair (p, q = k−p):
//!     t(k;p,q) = Re[ conj(u_k) · (−i (q·u_p) u_q) ] = Im[ (q·u_p) · (conj(u_k)·u_q) ].
//!     T_k = Σ_{p} t(k;p,k−p)          (signed)        A_k = Σ_{p} |t(k;p,k−p)|   (absolute)
//!
//! THE THREE READINGS (pre-registered in docs/designs/TRIAD_FRUSTRATION_DM.md):
//!   (a) mid-sphere flux:  D_a = Σ_{|k|>M/2} A_k / |Σ_{|k|>M/2} T_k|
//!       (numerator: absolute transfer into the outer half; denominator: net flux across the
//!       sphere of radius M/2, which is the only signed sum that is NOT identically zero).
//!   (b) outer shell:      D_b1 = Σ_{shell} A_k / Σ_{shell} |T_k|,   D_b2 = Σ_{shell} A_k / |Σ_{shell} T_k|
//!       with shell = {(M−1)² < |k|² ≤ M²}  (the "far-UV mode k*" of the memorandum, averaged).
//!   (c) pure geometry:    Waleffe helical coefficients C = g·(s_p|p| − s_q|q|), no field:
//!       D_c = Σ|C| / |Σ C| per chirality class. Summed over ALL classes the signed sum is
//!       exactly zero by the chirality-flip symmetry (derived in the memo, verified here), so
//!       the all-class reading is VACUOUS; per-class sums are reported instead.
//!
//! FIELDS (the null model and two phase-structured comparators, all divergence-free and
//! conjugate-symmetric by construction, envelope |u_k| ∝ |k|^{-γ}):
//!   random   : independent uniform phases on the two helical amplitudes, seeded xorshift64* —
//!              THE NULL MODEL. Several seeds give the ensemble spread.
//!   locked   : every helical amplitude real and positive (all phases zero) — the
//!              "phase-locked" extreme the memorandum says the lattice forbids.
//!   arith    : the deterministic arithmetic construction of the Tier B harness
//!              (A = ((a+2b+3c) mod 5 + 1)/3, B = ((2a−b+c) mod 4 + 1)/2 on an integer basis of k⊥),
//!              a third, non-random, non-locked phase structure.
//! What can be read off: if D grows the same way for `locked` as for `random`, the growth is a
//! property of the lattice geometry; if `locked` gives a much smaller D, the growth is the
//! random-walk null and says nothing about the dynamics. Either way NO statement about
//! Navier–Stokes or Euler follows: no field here is a solution of anything.
//!
//! CONTROLS (SPEC §7.3, both directions, run before any measurement, abort on failure):
//!   P1 helical basis is a curl eigenbasis: |h|²=2, k·h=0, i k×h = s|k| h, every k in the ball.
//!      NEGATIVE (demonstrated): the opposite-sign vector must FAIL the eigen-equation.
//!   P2 detailed energy conservation Σ_k T_k = 0 (theorem-backed: Tier A `triad_sum_zero`,
//!      Tier B fact 2) for every field kind, to 1e-10 relative.
//!      NEGATIVE (demonstrated): inject a longitudinal component on one mode pair; the residual
//!      must exceed 1e-6 (fact 2 needs divergence-free input).
//!   P3 the chirality-flip symmetry Σ_all-classes C = 0 (derived), to 1e-10 relative.
//!
//! NUMERICS: f64; per-mode sums accumulated separately and reduced in index order (bitwise
//! reproducible regardless of thread count); no wall-clock enters any number.

use std::fmt::Write as _;
use std::io::Write;
use std::time::Instant;

// ------------------------------------------------------------------ complex scalar
#[derive(Clone, Copy, Debug, Default, PartialEq)]
struct C {
    re: f64,
    im: f64,
}
impl C {
    const ZERO: C = C { re: 0.0, im: 0.0 };
    #[inline]
    fn new(re: f64, im: f64) -> C {
        C { re, im }
    }
    #[inline]
    fn conj(self) -> C {
        C { re: self.re, im: -self.im }
    }
    #[inline]
    fn mul(self, o: C) -> C {
        C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re }
    }
    #[inline]
    fn add(self, o: C) -> C {
        C { re: self.re + o.re, im: self.im + o.im }
    }
    #[inline]
    fn scale(self, s: f64) -> C {
        C { re: self.re * s, im: self.im * s }
    }
    #[inline]
    fn norm_sqr(self) -> f64 {
        self.re * self.re + self.im * self.im
    }
    #[inline]
    fn abs(self) -> f64 {
        self.norm_sqr().sqrt()
    }
    /// multiplication by i
    #[inline]
    fn mul_i(self) -> C {
        C { re: -self.im, im: self.re }
    }
    fn expi(t: f64) -> C {
        C { re: t.cos(), im: t.sin() }
    }
}
type V3 = [C; 3];
type R3 = [f64; 3];

#[inline]
fn cross_r(a: R3, b: R3) -> R3 {
    [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
}
#[inline]
fn dot_r(a: R3, b: R3) -> f64 {
    a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
}
#[inline]
fn cross_c(a: V3, b: V3) -> V3 {
    [
        a[1].mul(b[2]).add(a[2].mul(b[1]).scale(-1.0)),
        a[2].mul(b[0]).add(a[0].mul(b[2]).scale(-1.0)),
        a[0].mul(b[1]).add(a[1].mul(b[0]).scale(-1.0)),
    ]
}
/// bilinear dot, NO conjugation (matches the Tier B harness's `bilinear_cdot`)
#[inline]
fn dot_c(a: V3, b: V3) -> C {
    a[0].mul(b[0]).add(a[1].mul(b[1])).add(a[2].mul(b[2]))
}
/// real wavevector dotted with complex vector
#[inline]
fn dot_rc(q: R3, v: V3) -> C {
    C::new(q[0] * v[0].re + q[1] * v[1].re + q[2] * v[2].re, q[0] * v[0].im + q[1] * v[1].im + q[2] * v[2].im)
}
#[inline]
fn conj_v(v: V3) -> V3 {
    [v[0].conj(), v[1].conj(), v[2].conj()]
}

// ------------------------------------------------------------------ deterministic RNG
struct XorShift64Star(u64);
impl XorShift64Star {
    fn new(seed: u64) -> Self {
        XorShift64Star(seed.wrapping_mul(0x9E3779B97F4A7C15) | 1)
    }
    fn next_u64(&mut self) -> u64 {
        let mut x = self.0;
        x ^= x >> 12;
        x ^= x << 25;
        x ^= x >> 27;
        self.0 = x;
        x.wrapping_mul(0x2545F4914F6CDD1D)
    }
    /// uniform in [0,1)
    fn uniform(&mut self) -> f64 {
        (self.next_u64() >> 11) as f64 / (1u64 << 53) as f64
    }
}

// ------------------------------------------------------------------ lattice
struct Lattice {
    m: i64,
    modes: Vec<[i64; 3]>,
    /// dense lookup over the cube [-M, M]^3 -> mode index, or -1
    index: Vec<i32>,
}
impl Lattice {
    fn new(m: usize) -> Lattice {
        let mi = m as i64;
        let mut modes = Vec::new();
        for a in -mi..=mi {
            for b in -mi..=mi {
                for c in -mi..=mi {
                    let n2 = a * a + b * b + c * c;
                    if n2 > 0 && n2 <= mi * mi {
                        modes.push([a, b, c]);
                    }
                }
            }
        }
        let side = (2 * mi + 1) as usize;
        let mut index = vec![-1i32; side * side * side];
        for (i, k) in modes.iter().enumerate() {
            index[Self::cube_idx(mi, *k)] = i as i32;
        }
        Lattice { m: mi, modes, index }
    }
    #[inline]
    fn cube_idx(m: i64, k: [i64; 3]) -> usize {
        let side = (2 * m + 1) as usize;
        (((k[0] + m) as usize) * side + (k[1] + m) as usize) * side + (k[2] + m) as usize
    }
    #[inline]
    fn idx(&self, k: [i64; 3]) -> Option<usize> {
        if k[0].abs() > self.m || k[1].abs() > self.m || k[2].abs() > self.m {
            return None;
        }
        let v = self.index[Self::cube_idx(self.m, k)];
        if v < 0 {
            None
        } else {
            Some(v as usize)
        }
    }
    fn n(&self) -> usize {
        self.modes.len()
    }
}
#[inline]
fn ksq(k: [i64; 3]) -> i64 {
    k[0] * k[0] + k[1] * k[1] + k[2] * k[2]
}
#[inline]
fn kf(k: [i64; 3]) -> R3 {
    [k[0] as f64, k[1] as f64, k[2] as f64]
}
/// Same canonical half-space as tests/tier_b_nse_triad_convolution.py::is_positive_half
fn is_positive_half(k: [i64; 3]) -> bool {
    if k[2] != 0 {
        return k[2] > 0;
    }
    if k[1] != 0 {
        return k[1] > 0;
    }
    k[0] > 0
}

// ------------------------------------------------------------------ Waleffe helical basis
/// h^s(k) = ν×κ + i s ν,  κ = k/|k|,  ν = (e×κ)/|e×κ|,  e = ẑ (x̂ if k ∥ ẑ).  |h|² = 2.
/// Sign knob `flip` is the NEGATIVE-CONTROL perturbation (returns the −s vector under the name s).
fn helical(k: [i64; 3], s: i8, flip: bool) -> V3 {
    let kr = kf(k);
    let kn = dot_r(kr, kr).sqrt();
    let kappa = [kr[0] / kn, kr[1] / kn, kr[2] / kn];
    let mut e = [0.0, 0.0, 1.0];
    let mut nu = cross_r(e, kappa);
    if dot_r(nu, nu) < 1e-24 {
        e = [1.0, 0.0, 0.0];
        nu = cross_r(e, kappa);
    }
    let nn = dot_r(nu, nu).sqrt();
    let nu = [nu[0] / nn, nu[1] / nn, nu[2] / nn];
    let nk = cross_r(nu, kappa);
    let sgn = if flip { -(s as f64) } else { s as f64 };
    [C::new(nk[0], sgn * nu[0]), C::new(nk[1], sgn * nu[1]), C::new(nk[2], sgn * nu[2])]
}

// ------------------------------------------------------------------ fields
#[derive(Clone, Copy, Debug, PartialEq)]
enum FieldKind {
    /// THE NULL MODEL: independent uniform phases on both helical amplitudes (seeded).
    Random(u64),
    /// Coherent comparator 1: single chirality (+), every amplitude real positive (all phases 0).
    LockedPlus,
    /// Coherent comparator 2: both chiralities, fixed phases θ⁺ = 0, θ⁻ = π/2 for every k.
    LockedQuad,
    /// INERT BY PARITY (kept only as a recorded control, never as a comparator): both
    /// chiralities, all phases 0 ⇒ u_k = env·(ν×κ) is REAL for every k ⇒ u(x) is an even real
    /// field ⇒ every transfer t = Im[(q·u_p)(conj(u_k)·u_q)] is Im of a real number = 0.
    RealEven,
    /// The Tier B harness's deterministic arithmetic construction (non-random, non-locked).
    Arith,
}
impl FieldKind {
    fn name(&self) -> String {
        match self {
            FieldKind::Random(_) => "random".to_string(),
            FieldKind::LockedPlus => "locked_plus".to_string(),
            FieldKind::LockedQuad => "locked_quad".to_string(),
            FieldKind::RealEven => "real_even".to_string(),
            FieldKind::Arith => "arith".to_string(),
        }
    }
    fn seed(&self) -> u64 {
        match self {
            FieldKind::Random(s) => *s,
            _ => 0,
        }
    }
}

/// Integer basis of k⊥ exactly as the Tier B harness's `orthogonal_pair`.
fn orthogonal_pair(k: [i64; 3]) -> ([i64; 3], [i64; 3]) {
    let cross = |a: [i64; 3], b: [i64; 3]| -> [i64; 3] {
        [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
    };
    let mut v1 = cross(k, [1, 0, 0]);
    if v1 == [0, 0, 0] {
        v1 = cross(k, [0, 1, 0]);
    }
    let v2 = cross(k, v1);
    (v1, v2)
}

/// Build a divergence-free, conjugate-symmetric field with envelope |u_k| = |k|^{-gamma}.
/// `longitudinal_defect`: NEGATIVE-CONTROL knob — adds a k-parallel component on the mode pair
/// {k0, −k0} for the first positive-half mode, destroying divergence-freeness (fact 2's hypothesis).
fn build_field(lat: &Lattice, kind: FieldKind, gamma: f64, longitudinal_defect: bool) -> Vec<V3> {
    let n = lat.n();
    let mut u = vec![[C::ZERO; 3]; n];
    let mut rng = XorShift64Star::new(kind.seed());
    let mut defect_done = false;
    for (i, &k) in lat.modes.iter().enumerate() {
        if !is_positive_half(k) {
            continue;
        }
        let env = (ksq(k) as f64).sqrt().powf(-gamma);
        let mut uk: V3 = match kind {
            FieldKind::Random(_) | FieldKind::LockedPlus | FieldKind::LockedQuad | FieldKind::RealEven => {
                // helical amplitudes (a⁺, a⁻); |h|² = 2 and h⁺ ⊥ h⁻ (Hermitian), so |u_k|² = 2(|a⁺|²+|a⁻|²)
                let (ap, am): (C, C) = match kind {
                    FieldKind::Random(_) => {
                        let th_p = 2.0 * std::f64::consts::PI * rng.uniform();
                        let th_m = 2.0 * std::f64::consts::PI * rng.uniform();
                        (C::expi(th_p).scale(env / 2.0), C::expi(th_m).scale(env / 2.0))
                    }
                    FieldKind::LockedPlus => (C::new(env / 2f64.sqrt(), 0.0), C::ZERO),
                    FieldKind::LockedQuad => (C::new(env / 2.0, 0.0), C::new(0.0, env / 2.0)),
                    _ => (C::new(env / 2.0, 0.0), C::new(env / 2.0, 0.0)),
                };
                let hp = helical(k, 1, false);
                let hm = helical(k, -1, false);
                [
                    ap.mul(hp[0]).add(am.mul(hm[0])),
                    ap.mul(hp[1]).add(am.mul(hm[1])),
                    ap.mul(hp[2]).add(am.mul(hm[2])),
                ]
            }
            FieldKind::Arith => {
                let (v1, v2) = orthogonal_pair(k);
                let (a, b, c) = (k[0], k[1], k[2]);
                let aa = ((a + 2 * b + 3 * c).rem_euclid(5) + 1) as f64 / 3.0;
                let bb = ((2 * a - b + c).rem_euclid(4) + 1) as f64 / 2.0;
                let raw: V3 = [
                    C::new(aa * v1[0] as f64, bb * v2[0] as f64),
                    C::new(aa * v1[1] as f64, bb * v2[1] as f64),
                    C::new(aa * v1[2] as f64, bb * v2[2] as f64),
                ];
                let nrm = (raw[0].norm_sqr() + raw[1].norm_sqr() + raw[2].norm_sqr()).sqrt();
                [raw[0].scale(env / nrm), raw[1].scale(env / nrm), raw[2].scale(env / nrm)]
            }
        };
        if longitudinal_defect && !defect_done {
            let kr = kf(k);
            let kn = dot_r(kr, kr).sqrt();
            for j in 0..3 {
                uk[j] = uk[j].add(C::new(0.5 * env * kr[j] / kn, 0.0));
            }
            defect_done = true;
        }
        u[i] = uk;
        let neg = lat.idx([-k[0], -k[1], -k[2]]).expect("−k is in the ball");
        u[neg] = conj_v(uk);
    }
    u
}

// ------------------------------------------------------------------ transfers
/// Per mode k: (T_k signed, A_k absolute), over ORDERED pairs (p, q=k−p) with p,q ∈ Λ_M.
fn transfers(lat: &Lattice, u: &[V3], threads: usize) -> (Vec<f64>, Vec<f64>) {
    let n = lat.n();
    let mut t = vec![0.0f64; n];
    let mut a = vec![0.0f64; n];
    let chunk = (n + threads - 1) / threads;
    std::thread::scope(|sc| {
        for ((tc, ac), c) in t.chunks_mut(chunk).zip(a.chunks_mut(chunk)).zip(0..) {
            sc.spawn(move || {
                let base = c * chunk;
                for (local, (tk, ak)) in tc.iter_mut().zip(ac.iter_mut()).enumerate() {
                    let ki = base + local;
                    let k = lat.modes[ki];
                    let uk_c = conj_v(u[ki]);
                    let mut s_t = 0.0f64;
                    let mut s_a = 0.0f64;
                    for (pi, &p) in lat.modes.iter().enumerate() {
                        let q = [k[0] - p[0], k[1] - p[1], k[2] - p[2]];
                        let qi = match lat.idx(q) {
                            Some(x) => x,
                            None => continue,
                        };
                        // t = Im[(q·u_p) (conj(u_k)·u_q)]
                        let s = dot_rc(kf(q), u[pi]);
                        let d = dot_c(uk_c, u[qi]);
                        let term = s.mul(d).im;
                        s_t += term;
                        s_a += term.abs();
                    }
                    *tk = s_t;
                    *ak = s_a;
                }
            });
        }
    });
    (t, a)
}

struct Readings {
    sum_t: f64,
    sum_abs_t: f64,
    sum_a: f64,
    r_cons: f64,
    pi_half: f64,
    a_half: f64,
    d_a: f64,
    shell_n: usize,
    shell_a: f64,
    shell_abs_t: f64,
    shell_sum_t: f64,
    d_b1: f64,
    d_b2: f64,
}
fn readings(lat: &Lattice, t: &[f64], a: &[f64]) -> Readings {
    let m = lat.m;
    let (mut sum_t, mut sum_abs_t, mut sum_a) = (0.0, 0.0, 0.0);
    let (mut pi_half, mut a_half) = (0.0, 0.0);
    let (mut shell_n, mut shell_a, mut shell_abs_t, mut shell_sum_t) = (0usize, 0.0, 0.0, 0.0);
    for (i, &k) in lat.modes.iter().enumerate() {
        let n2 = ksq(k);
        sum_t += t[i];
        sum_abs_t += t[i].abs();
        sum_a += a[i];
        if 4 * n2 > m * m {
            pi_half += t[i];
            a_half += a[i];
        }
        if n2 > (m - 1) * (m - 1) {
            shell_n += 1;
            shell_a += a[i];
            shell_abs_t += t[i].abs();
            shell_sum_t += t[i];
        }
    }
    Readings {
        sum_t,
        sum_abs_t,
        sum_a,
        r_cons: sum_t.abs() / sum_abs_t.max(1e-300),
        pi_half,
        a_half,
        d_a: a_half / pi_half.abs().max(1e-300),
        shell_n,
        shell_a,
        shell_abs_t,
        shell_sum_t,
        d_b1: shell_a / shell_abs_t.max(1e-300),
        d_b2: shell_a / shell_sum_t.abs().max(1e-300),
    }
}

// ------------------------------------------------------------------ reading (c): Waleffe coefficients
/// For every ordered triad (k,p,q) with k+p+q=0 in Λ_M and chiralities (s_k,s_p,s_q):
///   g = −¼ (h_p^{s_p*} × h_q^{s_q*}) · h_k^{s_k*},   C = g · (s_p|p| − s_q|q|)   (Waleffe 1992, eq. for ∂_t a_k)
/// Returns per class index c = (s_k,s_p,s_q) ∈ {0..8}: (n_triads, Σ|C|, Σ C).
fn waleffe_sums(lat: &Lattice, threads: usize) -> [(u64, f64, C); 8] {
    let n = lat.n();
    // precompute conjugated helical vectors and |k|
    let hc: Vec<[V3; 2]> = lat.modes.iter().map(|&k| [conj_v(helical(k, 1, false)), conj_v(helical(k, -1, false))]).collect();
    let kn: Vec<f64> = lat.modes.iter().map(|&k| (ksq(k) as f64).sqrt()).collect();
    let chunk = (n + threads - 1) / threads;
    let mut partial: Vec<[(u64, f64, C); 8]> = vec![[(0, 0.0, C::ZERO); 8]; threads];
    std::thread::scope(|sc| {
        for (c, slot) in partial.iter_mut().enumerate() {
            let hc = &hc;
            let kn = &kn;
            sc.spawn(move || {
                let lo = c * chunk;
                let hi = ((c + 1) * chunk).min(n);
                let mut acc = [(0u64, 0.0f64, C::ZERO); 8];
                for ki in lo..hi {
                    let k = lat.modes[ki];
                    for pi in 0..n {
                        let p = lat.modes[pi];
                        let q = [-k[0] - p[0], -k[1] - p[1], -k[2] - p[2]];
                        let qi = match lat.idx(q) {
                            Some(x) => x,
                            None => continue,
                        };
                        for sk in 0..2 {
                            for sp in 0..2 {
                                for sq in 0..2 {
                                    let spf = if sp == 0 { 1.0 } else { -1.0 };
                                    let sqf = if sq == 0 { 1.0 } else { -1.0 };
                                    let g = dot_c(cross_c(hc[pi][sp], hc[qi][sq]), hc[ki][sk]).scale(-0.25);
                                    let coef = g.scale(spf * kn[pi] - sqf * kn[qi]);
                                    let cls = sk * 4 + sp * 2 + sq;
                                    acc[cls].0 += 1;
                                    acc[cls].1 += coef.abs();
                                    acc[cls].2 = acc[cls].2.add(coef);
                                }
                            }
                        }
                    }
                }
                *slot = acc;
            });
        }
    });
    let mut out = [(0u64, 0.0f64, C::ZERO); 8];
    for part in partial {
        for c in 0..8 {
            out[c].0 += part[c].0;
            out[c].1 += part[c].1;
            out[c].2 = out[c].2.add(part[c].2);
        }
    }
    out
}
fn class_name(c: usize) -> String {
    let s = |b: usize| if b == 0 { "+" } else { "-" };
    format!("{}{}{}", s(c / 4), s((c / 2) % 2), s(c % 2))
}

// ------------------------------------------------------------------ controls
fn controls(threads: usize) -> bool {
    println!("== CONTROLS (both directions; abort on any failure) ==");
    let mut ok = true;
    let lat = Lattice::new(4);

    // P1: helical basis is a curl eigenbasis
    let mut worst = 0.0f64;
    let mut worst_flip = f64::INFINITY;
    for &k in &lat.modes {
        let kr = kf(k);
        let kn = dot_r(kr, kr).sqrt();
        for s in [1i8, -1i8] {
            for flip in [false, true] {
                let h = helical(k, s, flip);
                let kc: V3 = [C::new(kr[0], 0.0), C::new(kr[1], 0.0), C::new(kr[2], 0.0)];
                let curl = cross_c(kc, h);
                let curl = [curl[0].mul_i(), curl[1].mul_i(), curl[2].mul_i()];
                let target = [h[0].scale(s as f64 * kn), h[1].scale(s as f64 * kn), h[2].scale(s as f64 * kn)];
                let mut res = 0.0;
                for j in 0..3 {
                    res += curl[j].add(target[j].scale(-1.0)).norm_sqr();
                }
                let res = res.sqrt() / kn;
                let nrm = (h[0].norm_sqr() + h[1].norm_sqr() + h[2].norm_sqr() - 2.0).abs();
                let tr = dot_rc(kr, h).abs() / kn;
                if !flip {
                    worst = worst.max(res).max(nrm).max(tr);
                } else {
                    worst_flip = worst_flip.min(res);
                }
            }
        }
    }
    let p1 = worst < 1e-12;
    println!("P1 curl-eigenbasis (|h|²=2, k·h=0, i k×h = s|k|h), M=4, {} modes: worst residual {:.2e}  {}", lat.n(), worst, if p1 { "OK" } else { "*** FAILED ***" });
    let n1 = worst_flip > 1e-3;
    println!("   NEGATIVE CONTROL (sign-flipped vector): smallest eigen-residual {:.2e}  {}", worst_flip, if n1 { "OK (fires)" } else { "*** INERT (LL-19) ***" });
    ok &= p1 && n1;

    // P2: detailed conservation for every field kind; negative: longitudinal defect
    for kind in [FieldKind::Random(1), FieldKind::LockedPlus, FieldKind::LockedQuad, FieldKind::Arith] {
        for gamma in [0.0, 11.0 / 6.0] {
            let u = build_field(&lat, kind, gamma, false);
            let (t, a) = transfers(&lat, &u, threads);
            let r = readings(&lat, &t, &a);
            // A control on a field with NO transfer at all is inert (0/0): require Σ|T| > 0.
            let live = r.sum_abs_t > 1e-12;
            let p2 = live && r.r_cons < 1e-10;
            println!("P2 Σ_k T_k = 0 [{} γ={:.3}]: |ΣT|/Σ|T| = {:.2e}  (Σ|T|={:.3e})  {}", kind.name(), gamma, r.r_cons, r.sum_abs_t, if p2 { "OK" } else if !live { "*** INERT: field has zero transfer (LL-19) ***" } else { "*** FAILED ***" });
            ok &= p2;
        }
    }
    // Recorded finding, not a comparator: the all-real ("both chiralities, all phases 0") field
    // has zero transfer identically, by parity. Must read Σ|T| = 0; if it does not, the parity
    // argument in the FieldKind doc is wrong.
    {
        let u = build_field(&lat, FieldKind::RealEven, 0.0, false);
        let (t, a) = transfers(&lat, &u, threads);
        let r = readings(&lat, &t, &a);
        let p2b = r.sum_abs_t < 1e-12;
        println!("P2b real-even field (both chiralities, phases 0) has Σ|T| = {:.2e}  {}", r.sum_abs_t, if p2b { "OK — identically zero by parity; excluded as a comparator" } else { "*** FAILED — parity argument wrong ***" });
        ok &= p2b;
    }
    let u = build_field(&lat, FieldKind::Random(1), 0.0, true);
    let (t, a) = transfers(&lat, &u, threads);
    let r = readings(&lat, &t, &a);
    let n2 = r.r_cons > 1e-6;
    println!("   NEGATIVE CONTROL (longitudinal component injected on one mode pair): |ΣT|/Σ|T| = {:.2e}  {}", r.r_cons, if n2 { "OK (fires)" } else { "*** INERT (LL-19) ***" });
    ok &= n2;

    // P3: chirality-flip symmetry ⇒ all-class signed Waleffe sum vanishes
    let w = waleffe_sums(&lat, threads);
    let tot_abs: f64 = w.iter().map(|x| x.1).sum();
    let mut tot = C::ZERO;
    for x in &w {
        tot = tot.add(x.2);
    }
    let p3 = tot.abs() / tot_abs < 1e-10;
    println!("P3 all-class Waleffe signed sum (must vanish by chirality flip): |ΣC|/Σ|C| = {:.2e}  {}", tot.abs() / tot_abs, if p3 { "OK — reading (c) over ALL classes is VACUOUS, as derived" } else { "*** FAILED — derivation wrong ***" });
    ok &= p3;
    println!("CONTROLS: {}\n", if ok { "PASS" } else { "*** FAILED — no measurement is admissible ***" });
    ok
}

// ------------------------------------------------------------------ main
fn main() {
    let args: Vec<String> = std::env::args().collect();
    let mut mmin = 2usize;
    let mut mmax = 20usize;
    let mut mmax_c = 14usize;
    let mut seeds = 3u64;
    let mut out_dir = String::from(".");
    let mut threads = std::thread::available_parallelism().map(|n| n.get()).unwrap_or(1);
    let gammas = [0.0f64, 11.0 / 6.0];
    let mut i = 1;
    while i < args.len() {
        match args[i].as_str() {
            "--mmin" => { mmin = args[i + 1].parse().unwrap(); i += 2; }
            "--mmax" => { mmax = args[i + 1].parse().unwrap(); i += 2; }
            "--mmax-c" => { mmax_c = args[i + 1].parse().unwrap(); i += 2; }
            "--seeds" => { seeds = args[i + 1].parse().unwrap(); i += 2; }
            "--out" => { out_dir = args[i + 1].clone(); i += 2; }
            "--threads" => { threads = args[i + 1].parse().unwrap(); i += 2; }
            "--controls-only" => { std::process::exit(if controls(threads) { 0 } else { 1 }); }
            other => { eprintln!("unknown argument {other}"); std::process::exit(2); }
        }
    }
    println!("triad_frustration (TIER C) — threads={threads} M={mmin}..{mmax} (Waleffe up to {mmax_c}) seeds={seeds} gammas={gammas:?}");
    if !controls(threads) {
        std::process::exit(1);
    }
    std::fs::create_dir_all(&out_dir).unwrap();
    let mut csv = String::new();
    writeln!(csv, "M,n_modes,gamma,field,seed,sum_T,sum_absT,sum_A,r_cons,Pi_half,A_half,D_a,shell_n,shell_A,shell_absT,shell_sumT,D_b1,D_b2,secs").unwrap();
    let mut csv_c = String::new();
    writeln!(csv_c, "M,n_modes,class,n_triads,sum_absC,sum_C_re,sum_C_im,D_c,secs").unwrap();

    for m in mmin..=mmax {
        let lat = Lattice::new(m);
        let mut kinds: Vec<FieldKind> = (1..=seeds).map(FieldKind::Random).collect();
        kinds.push(FieldKind::LockedPlus);
        kinds.push(FieldKind::LockedQuad);
        kinds.push(FieldKind::Arith);
        for &gamma in &gammas {
            for &kind in &kinds {
                let t0 = Instant::now();
                let u = build_field(&lat, kind, gamma, false);
                let (t, a) = transfers(&lat, &u, threads);
                let r = readings(&lat, &t, &a);
                let secs = t0.elapsed().as_secs_f64();
                writeln!(
                    csv,
                    "{},{},{:.6},{},{},{:.10e},{:.10e},{:.10e},{:.3e},{:.10e},{:.10e},{:.6e},{},{:.10e},{:.10e},{:.10e},{:.6e},{:.6e},{:.2}",
                    m, lat.n(), gamma, kind.name(), kind.seed(), r.sum_t, r.sum_abs_t, r.sum_a, r.r_cons, r.pi_half, r.a_half, r.d_a,
                    r.shell_n, r.shell_a, r.shell_abs_t, r.shell_sum_t, r.d_b1, r.d_b2, secs
                )
                .unwrap();
                println!(
                    "M={:2} n={:6} γ={:.3} {:7} seed={} | r_cons={:.1e} | D_a={:.4e} D_b1={:.4e} D_b2={:.4e} | {:.1}s",
                    m, lat.n(), gamma, kind.name(), kind.seed(), r.r_cons, r.d_a, r.d_b1, r.d_b2, secs
                );
            }
        }
        if m <= mmax_c {
            let t0 = Instant::now();
            let w = waleffe_sums(&lat, threads);
            let secs = t0.elapsed().as_secs_f64();
            let mut tot_abs = 0.0;
            let mut tot = C::ZERO;
            for c in 0..8 {
                tot_abs += w[c].1;
                tot = tot.add(w[c].2);
                writeln!(csv_c, "{},{},{},{},{:.10e},{:.10e},{:.10e},{:.6e},{:.2}", m, lat.n(), class_name(c), w[c].0, w[c].1, w[c].2.re, w[c].2.im, w[c].1 / w[c].2.abs().max(1e-300), secs).unwrap();
            }
            writeln!(csv_c, "{},{},ALL,{},{:.10e},{:.10e},{:.10e},{:.6e},{:.2}", m, lat.n(), w.iter().map(|x| x.0).sum::<u64>(), tot_abs, tot.re, tot.im, tot_abs / tot.abs().max(1e-300), secs).unwrap();
            println!(
                "M={:2} Waleffe: (+++) D_c={:.4e}  (++-) D_c={:.4e}  ALL |ΣC|/Σ|C|={:.1e} (vacuous by symmetry)  | {:.1}s",
                m, w[0].1 / w[0].2.abs().max(1e-300), w[1].1 / w[1].2.abs().max(1e-300), tot.abs() / tot_abs, secs
            );
        }
        // flush after every M so a killed run still leaves data
        std::fs::write(format!("{out_dir}/dm_readings.csv"), &csv).unwrap();
        std::fs::write(format!("{out_dir}/dm_waleffe.csv"), &csv_c).unwrap();
    }
    let mut meta = String::new();
    writeln!(meta, "generating_command: {}", args.join(" ")).unwrap();
    writeln!(meta, "threads: {threads}").unwrap();
    if let Ok(o) = std::process::Command::new("rustc").arg("--version").output() {
        writeln!(meta, "rustc: {}", String::from_utf8_lossy(&o.stdout).trim()).unwrap();
    }
    if let Ok(o) = std::process::Command::new("git").args(["rev-parse", "HEAD"]).output() {
        writeln!(meta, "git_commit: {}", String::from_utf8_lossy(&o.stdout).trim()).unwrap();
    }
    for f in ["dm_readings.csv", "dm_waleffe.csv"] {
        if let Ok(o) = std::process::Command::new("sha256sum").arg(format!("{out_dir}/{f}")).output() {
            writeln!(meta, "sha256sum: {}", String::from_utf8_lossy(&o.stdout).trim()).unwrap();
        }
    }
    writeln!(meta, "tier: C (floating point; no claim; no verdict)").unwrap();
    std::fs::File::create(format!("{out_dir}/dm_readings.csv.meta")).unwrap().write_all(meta.as_bytes()).unwrap();
    println!("wrote {out_dir}/dm_readings.csv, dm_waleffe.csv, dm_readings.csv.meta");
}
