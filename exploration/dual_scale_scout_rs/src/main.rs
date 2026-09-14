// TIER C — EXPLORATORY, NO CLAIMS.
//
// Pseudo-spectral f64 scout for the Galerkin-truncated 3-D Navier–Stokes system on Z^3
// (the sharp projection, i.e. the dual-scale system under M <-> 1/sqrt(alpha')).
//
// DISCRETISATION — must match tests/tier_b_fourier_enstrophy.py EXACTLY, so that the
// forward-Euler mode reproduces the exact rational eight-step trajectory to round-off:
//   modes on the ball k_sq <= M^2; u_q = 0 off the ball;
//   convective_k = -i * sum_{p in ball} (q . u_p) u_q,  q = k - p;
//   B_k = Leray(k)[convective_k],  Leray = delta - k k^T / k_sq  (identity at k = 0);
//   F_k = -nu k_sq(k) u_k + B_k.
// Two convolution engines: DIRECT (O(|ball|^2), the calibration reference) and FFT with exact
// 2/3 de-aliasing (N >= 3M+1 puts every aliased product outside the retained band). The FFT
// engine is trusted only where it agrees with DIRECT to round-off.
//
// Observables per step: E = sum |u_k|^2, D = sum k_sq |u_k|^2, P = sum k_sq <u_k, B_k>, and the
// adopted trajectory ratio Re(P) / (nu D).
//
// Modes:
//   calibrate <json>               Euler dt from the file, compare to the exact states
//   scout --M m --ic adv|null --nu x --dt x --steps n [--every e] [--engine fft|direct]
//                                  RK4 long-horizon run, prints observables

use rayon::prelude::*;
use rustfft::num_complex::Complex;
use rustfft::{Fft, FftPlanner};
use std::sync::Arc;

type C = Complex<f64>;

// ------------------------------------------------------------------ lattice

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Debug)]
struct K([i64; 3]);

impl K {
    fn sq(&self) -> i64 { self.0.iter().map(|x| x * x).sum() }
    fn neg(&self) -> K { K([-self.0[0], -self.0[1], -self.0[2]]) }
    fn add(&self, o: &K) -> K { K([self.0[0] + o.0[0], self.0[1] + o.0[1], self.0[2] + o.0[2]]) }
    fn sub(&self, o: &K) -> K { K([self.0[0] - o.0[0], self.0[1] - o.0[1], self.0[2] - o.0[2]]) }
    fn dot(&self, o: &K) -> i64 { self.0[0] * o.0[0] + self.0[1] * o.0[1] + self.0[2] * o.0[2] }
    fn cross(&self, o: &K) -> K {
        K([self.0[1] * o.0[2] - self.0[2] * o.0[1],
           self.0[2] * o.0[0] - self.0[0] * o.0[2],
           self.0[0] * o.0[1] - self.0[1] * o.0[0]])
    }
}

/// The ball in the SAME order as the Python `ball(M)`: lexicographic over (k0,k1,k2) in [-M,M].
fn ball(m: i64) -> Vec<K> {
    let mut v = Vec::new();
    for a in -m..=m { for b in -m..=m { for c in -m..=m {
        let k = K([a, b, c]);
        if k.sq() <= m * m { v.push(k); }
    }}}
    v
}

fn half_ball(m: i64) -> Vec<K> {
    ball(m).into_iter().filter(|k| *k != K([0, 0, 0]) && *k > k.neg()).collect()
}

fn rep(k: &K) -> K { if *k > k.neg() { *k } else { k.neg() } }

// ------------------------------------------------------------------ state on the ball

#[derive(Clone)]
struct State {
    m: i64,
    modes: Vec<K>,
    index: std::collections::HashMap<K, usize>,
    u: Vec<[C; 3]>,
}

impl State {
    fn zero(m: i64) -> State {
        let modes = ball(m);
        let index = modes.iter().enumerate().map(|(i, k)| (*k, i)).collect();
        let n = modes.len();
        State { m, modes, index, u: vec![[C::new(0.0, 0.0); 3]; n] }
    }
    fn get(&self, k: &K) -> [C; 3] {
        match self.index.get(k) { Some(&i) => self.u[i], None => [C::new(0.0, 0.0); 3] }
    }
    fn axpy(&self, a: f64, f: &[[C; 3]]) -> State {
        let mut s = self.clone();
        for (i, row) in s.u.iter_mut().enumerate() {
            for c in 0..3 { row[c] = row[c] + f[i][c] * a; }
        }
        s
    }
    fn energy(&self) -> f64 { self.u.iter().map(|r| r.iter().map(|c| c.norm_sqr()).sum::<f64>()).sum() }
    /// Energy dissipation sum D = sum k_sq |u_k|^2 (also the enstrophy).
    fn dissipation(&self) -> f64 {
        self.modes.iter().zip(&self.u).map(|(k, r)| k.sq() as f64 * r.iter().map(|c| c.norm_sqr()).sum::<f64>()).sum()
    }
    /// Enstrophy dissipation sum D2 = sum k_sq^2 |u_k|^2 -- the one enstrophy growth is decided
    /// against: the enstrophy balance is d/dt Z = -2 nu D2 + 2 Re P, so ratio2 = Re P/(nu D2) > 1
    /// means enstrophy is INCREASING.
    fn dissipation2(&self) -> f64 {
        self.modes.iter().zip(&self.u).map(|(k, r)| (k.sq() * k.sq()) as f64 * r.iter().map(|c| c.norm_sqr()).sum::<f64>()).sum()
    }
}

fn leray(k: &K, v: [C; 3]) -> [C; 3] {
    let ks = k.sq();
    if ks == 0 { return v; }
    let kd = C::new(k.0[0] as f64, 0.0) * v[0] + C::new(k.0[1] as f64, 0.0) * v[1] + C::new(k.0[2] as f64, 0.0) * v[2];
    let mut out = v;
    for i in 0..3 { out[i] = v[i] - kd * (k.0[i] as f64 / ks as f64); }
    out
}

// ------------------------------------------------------------------ DIRECT convolution

fn b_direct(s: &State) -> Vec<[C; 3]> {
    let mi = C::new(0.0, -1.0);
    s.modes.par_iter().map(|k| {
        let mut acc = [C::new(0.0, 0.0); 3];
        for (p, up) in s.modes.iter().zip(&s.u) {
            let q = k.sub(p);
            if q.sq() > s.m * s.m { continue; }
            let uq = s.get(&q);
            let qd = C::new(q.0[0] as f64, 0.0) * up[0] + C::new(q.0[1] as f64, 0.0) * up[1] + C::new(q.0[2] as f64, 0.0) * up[2];
            let coef = mi * qd;
            for i in 0..3 { acc[i] = acc[i] + coef * uq[i]; }
        }
        leray(k, acc)
    }).collect()
}

// ------------------------------------------------------------------ FFT convolution

struct Grid {
    n: usize,
    fwd: Arc<dyn Fft<f64>>,
    inv: Arc<dyn Fft<f64>>,
}

impl Grid {
    fn new(m: i64) -> Grid {
        let mut n = 8usize;
        while (n as i64) < 3 * m + 1 { n *= 2; }
        let mut planner = FftPlanner::<f64>::new();
        Grid { n, fwd: planner.plan_fft_forward(n), inv: planner.plan_fft_inverse(n) }
    }
    fn wave(&self, i: usize) -> i64 { if i < self.n / 2 { i as i64 } else { i as i64 - self.n as i64 } }
    fn idx_of(&self, k: &K) -> usize {
        let w = |x: i64| ((x % self.n as i64 + self.n as i64) % self.n as i64) as usize;
        (w(k.0[0]) * self.n + w(k.0[1])) * self.n + w(k.0[2])
    }
    /// 3-D transform in place; `inverse` selects the sign convention (unnormalised both ways).
    fn fft3(&self, data: &mut [C], inverse: bool) {
        let n = self.n;
        let f = if inverse { &self.inv } else { &self.fwd };
        // Serial internally, on purpose: b_fft runs the fifteen independent transforms of one
        // right-hand side in parallel instead, which scales far better than splitting a single
        // transform (measured 1.18x on 8 cores the old way; see the compute-plan brief).
        data.chunks_mut(n).for_each(|line| f.process(line));
        // axes 0 and 1: gather / scatter
        let mut buf = vec![C::new(0.0, 0.0); n];
        for axis in 0..2 {
            for a in 0..n { for b in 0..n {
                for t in 0..n {
                    let idx = match axis { 0 => (t * n + a) * n + b, _ => (a * n + t) * n + b };
                    buf[t] = data[idx];
                }
                f.process(&mut buf);
                for t in 0..n {
                    let idx = match axis { 0 => (t * n + a) * n + b, _ => (a * n + t) * n + b };
                    data[idx] = buf[t];
                }
            }}
        }
    }
    fn to_grid(&self, s: &State, comp: usize) -> Vec<C> {
        let mut g = vec![C::new(0.0, 0.0); self.n * self.n * self.n];
        for (k, row) in s.modes.iter().zip(&s.u) { g[self.idx_of(k)] = row[comp]; }
        g
    }
}

fn b_fft(s: &State, grid: &Grid) -> Vec<[C; 3]> {
    let n = grid.n;
    let n3 = (n * n * n) as f64;
    // ALL TWELVE inverse transforms in one flat parallel loop -- the three velocity
    // components (slots 0..3) and the nine gradients d_j v_i (slot 3 + 3*i + j). They are
    // mutually independent, so one twelve-way loop keeps every core busy where two loops of
    // three and nine would leave five idle in the first stage.
    let fields: Vec<Vec<C>> = (0..12).into_par_iter().map(|slot| {
        if slot < 3 {
            let mut g = grid.to_grid(s, slot);
            grid.fft3(&mut g, true);
            return g;
        }
        let (i, j) = ((slot - 3) / 3, (slot - 3) % 3);
        let mut g = grid.to_grid(s, i);
        for a in 0..n { for b in 0..n { for c in 0..n {
            let kj = match j { 0 => grid.wave(a), 1 => grid.wave(b), _ => grid.wave(c) } as f64;
            let idx = (a * n + b) * n + c;
            g[idx] = g[idx] * C::new(0.0, kj);
        }}}
        grid.fft3(&mut g, true);
        g
    }).collect();
    let (v, dv) = fields.split_at(3);
    // w_i = sum_j v_j d_j v_i in physical space, then back to Fourier, normalised.
    // Three more independent transforms; the pointwise product is serial inside each.
    let w: Vec<Vec<C>> = (0..3).into_par_iter().map(|i| {
        let mut g: Vec<C> = (0..n * n * n).map(|idx| {
            let mut acc = C::new(0.0, 0.0);
            for j in 0..3 { acc = acc + v[j][idx] * dv[3 * i + j][idx]; }
            acc
        }).collect();
        grid.fft3(&mut g, false);
        for x in g.iter_mut() { *x = *x / n3; }
        g
    }).collect();
    // convective_k = -(u . grad u)_k on the ball, then Leray
    s.modes.iter().map(|k| {
        let idx = grid.idx_of(k);
        leray(k, [-w[0][idx], -w[1][idx], -w[2][idx]])
    }).collect()
}

// ------------------------------------------------------------------ dynamics

struct Model { nu: f64, engine: Engine, grid: Option<Grid> }
#[derive(Clone, Copy, PartialEq)] enum Engine { Direct, Fft }

impl Model {
    fn b(&self, s: &State) -> Vec<[C; 3]> {
        match self.engine { Engine::Direct => b_direct(s), Engine::Fft => b_fft(s, self.grid.as_ref().unwrap()) }
    }
    fn rhs(&self, s: &State) -> (Vec<[C; 3]>, Vec<[C; 3]>) {
        let b = self.b(s);
        let f: Vec<[C; 3]> = s.modes.iter().zip(&s.u).zip(&b).map(|((k, u), bk)| {
            let damp = -self.nu * k.sq() as f64;
            [u[0] * damp + bk[0], u[1] * damp + bk[1], u[2] * damp + bk[2]]
        }).collect();
        (f, b)
    }
    fn production(&self, s: &State, b: &[[C; 3]]) -> C {
        s.modes.iter().zip(&s.u).zip(b).map(|((k, u), bk)| {
            let pair = u[0].conj() * bk[0] + u[1].conj() * bk[1] + u[2].conj() * bk[2];
            pair * (k.sq() as f64)
        }).sum()
    }
    fn euler(&self, s: &State, dt: f64) -> State { let (f, _) = self.rhs(s); s.axpy(dt, &f) }
    fn rk4(&self, s: &State, dt: f64) -> State {
        let (k1, _) = self.rhs(s);
        let (k2, _) = self.rhs(&s.axpy(dt / 2.0, &k1));
        let (k3, _) = self.rhs(&s.axpy(dt / 2.0, &k2));
        let (k4, _) = self.rhs(&s.axpy(dt, &k3));
        let mut out = s.clone();
        for i in 0..out.u.len() { for c in 0..3 {
            out.u[i][c] = s.u[i][c] + (k1[i][c] + k2[i][c] * 2.0 + k3[i][c] * 2.0 + k4[i][c]) * (dt / 6.0);
        }}
        out
    }
}

// ------------------------------------------------------------------ initial conditions (ports of the Python constructions)

fn nondegenerate(k: &K, d: &K) -> bool { *d != K([0, 0, 0]) && k.cross(d) != K([0, 0, 0]) }

fn direction_varied(k: &K) -> K {
    for d in [K([1 + k.0[1], 2 + k.0[2], 3 + k.0[0]]), K([1, 0, 0]), K([0, 1, 0])] {
        if nondegenerate(k, &d) { return d; }
    }
    panic!("no admissible director for {:?}", k);
}

/// u_k = k x a_k with a_{-k} = -conj(a_k), from phases on the half ball.
fn make_state(m: i64, phases: &std::collections::HashMap<K, C>, lam: f64) -> State {
    let mut s = State::zero(m);
    let mut amps: std::collections::HashMap<K, [C; 3]> = Default::default();
    for k in half_ball(m) {
        let d = direction_varied(&k);
        let ph = phases[&k];
        let a = [ph * (d.0[0] as f64), ph * (d.0[1] as f64), ph * (d.0[2] as f64)];
        amps.insert(k, a);
        amps.insert(k.neg(), [-a[0].conj(), -a[1].conj(), -a[2].conj()]);
    }
    for (i, k) in s.modes.clone().iter().enumerate() {
        if let Some(a) = amps.get(k) {
            let kf = [k.0[0] as f64, k.0[1] as f64, k.0[2] as f64];
            s.u[i] = [
                (a[2] * kf[1] - a[1] * kf[2]) * lam,
                (a[0] * kf[2] - a[2] * kf[0]) * lam,
                (a[1] * kf[0] - a[0] * kf[1]) * lam,
            ];
        }
    }
    s
}

fn circle_point(t: f64) -> C { C::new((1.0 - t * t) / (1.0 + t * t), 2.0 * t / (1.0 + t * t)) }

fn phases_random(m: i64, seed: u64) -> std::collections::HashMap<K, C> {
    let mut x: u64 = (seed.wrapping_mul(2654435761)) % (1u64 << 31);
    let mut map: std::collections::HashMap<K, C> = std::collections::HashMap::new();
    for k in half_ball(m) {
        x = (1103515245u64.wrapping_mul(x).wrapping_add(12345)) % (1u64 << 31);
        let r = (x % (2 * 97)) as i64;
        let t = (r - 97 + 1) as f64 / 97.0;
        map.insert(k, circle_point(t));
    }
    map
}

/// The greedy sign alignment of tests/tier_b_adversarial_alignment.py, ported.
///
/// MEMORY (2026-09-13, to make M = 16 reachable on an 8-core/31 GB machine). The triad table
/// is 1.37e8 entries at M = 16, counted exactly. Materialising it as `(K, K, K, i64)` is
/// 10.2 GB, and the class list built by `flat_map` before its `dedup` is a further 9.8 GB
/// transient — together more than this machine has free, which is the memory wall declared as
/// a risk in CORE_TAIL_CAP.md section 4.3. The same table in index form is 2.2 GB, so the
/// wavevector form is never built: pass 1 discovers which rep classes occur and counts the
/// entries, pass 2 writes the table already indexed into a vector reserved to that exact
/// count. The class SET, its sorted order and the sweep order are untouched, so the alignment
/// this returns is the same one — checked by reproducing the archived M = 8 runs bit-for-bit.
///
/// OVERFLOW. The objective is summed in `i128`. At M = 16 a single `g` reaches ~6e11 and the
/// table has 1.37e8 of them, so an `i64` accumulator could wrap silently on a badly-cancelling
/// sign pattern; the i128 sum costs nothing measurable (the loop is memory-bound) and the
/// values at M <= 8 are far too small for the change to alter any archived result.
fn phases_adversarial(m: i64) -> std::collections::HashMap<K, C> {
    let bm: std::collections::HashSet<K> = ball(m).into_iter().collect();
    let dirs: std::collections::HashMap<K, K> = half_ball(m).into_iter().map(|r| (r, direction_varied(&r))).collect();
    let bv = ball(m);
    // The (rep class triple, weight) of one (p, q), or None when the triad is absent or g = 0.
    let entry = |p: &K, q: &K| -> Option<(K, K, K, i64)> {
        let r = p.add(q).neg();
        if !bm.contains(&r) || *p == K([0,0,0]) || *q == K([0,0,0]) || r == K([0,0,0]) { return None; }
        let (rp, rq, rr) = (rep(p), rep(q), rep(&r));
        let w = r.sq() - q.sq();
        let g = w * q.dot(&p.cross(&dirs[&rp])) * q.cross(&dirs[&rq]).dot(&r.cross(&dirs[&rr]));
        if g == 0 { None } else { Some((rp, rq, rr, g)) }
    };
    // pass 1 — the class set and the entry count, nothing retained per entry.
    let mut present: std::collections::HashSet<K> = std::collections::HashSet::new();
    let mut count: usize = 0;
    for p in &bv { for q in &bv {
        if let Some((rp, rq, rr, _)) = entry(p, q) {
            present.insert(rp); present.insert(rq); present.insert(rr);
            count += 1;
        }
    }}
    let mut classes: Vec<K> = present.into_iter().collect();
    classes.sort();
    assert!(classes.len() <= u32::MAX as usize, "class index does not fit u32");
    let idx: std::collections::HashMap<K, u32> = classes.iter().enumerate().map(|(i, c)| (*c, i as u32)).collect();
    // pass 2 — the table, indexed, in a vector reserved to its exact size so no doubling
    // ever holds two copies at once.
    let mut tab: Vec<(u32, u32, u32, i64)> = Vec::with_capacity(count);
    for p in &bv { for q in &bv {
        if let Some((rp, rq, rr, g)) = entry(p, q) { tab.push((idx[&rp], idx[&rq], idx[&rr], g)); }
    }}
    eprintln!("   [align] M={} classes={} triads={} table={:.2} GB", m, classes.len(), tab.len(),
        (tab.len() * std::mem::size_of::<(u32, u32, u32, i64)>()) as f64 / (1u64 << 30) as f64);
    // -----------------------------------------------------------------------------------
    // THE GREEDY SWEEP, MADE INCREMENTAL (2026-09-13). Flipping one class's sign does not
    // change the objective's other terms, so re-summing the whole table per flip -- which is
    // what the original loop did -- is pure waste. Maintain the signed total S instead and
    // update it:
    //
    //     S_after_flipping_i  =  S  -  2 * (sum of the terms that flip)
    //
    // and the terms that flip are exactly those whose triad contains class i an ODD number of
    // times: if i appears twice, the term is multiplied by (-1)^2 = 1 and does not move. That
    // is the whole trick, and it is why the incidence below is an ODD incidence.
    //
    // Cost per sweep falls from O(classes x triads) to O(sum of odd degrees) <= O(3 x triads),
    // a factor of classes/3 -- 2846x at M = 16, 22876x at M = 32. The arithmetic stays integer
    // and exact (i128), the classes are visited in the same order, and the accept test is the
    // same strict improvement, so this is the SAME greedy and must return the SAME alignment.
    // It is held to that: it reproduces the archived M = 8 run bit-for-bit and the
    // sweep-by-sweep `best` of the pre-change M = 16 run.
    let n = classes.len();
    // The classes occurring an odd number of times in one triad.
    let odd_of = |a: u32, b: u32, c: u32| -> [Option<u32>; 3] {
        if a == b && b == c { [Some(a), None, None] }        // three times: odd
        else if a == b { [Some(c), None, None] }             // a twice: even, drops out
        else if a == c { [Some(b), None, None] }
        else if b == c { [Some(a), None, None] }
        else { [Some(a), Some(b), Some(c)] }
    };
    let mut deg = vec![0u32; n];
    for &(a, b, c, _) in &tab {
        for o in odd_of(a, b, c).into_iter().flatten() { deg[o as usize] += 1; }
    }
    let mut off = vec![0usize; n + 1];
    for i in 0..n { off[i + 1] = off[i] + deg[i] as usize; }
    let mut fill = off.clone();
    let mut adj = vec![0u32; off[n]];
    for (t, &(a, b, c, _)) in tab.iter().enumerate() {
        for o in odd_of(a, b, c).into_iter().flatten() {
            adj[fill[o as usize]] = t as u32;
            fill[o as usize] += 1;
        }
    }
    eprintln!("   [align] odd incidence: {} entries, {:.2} GB; mean degree {:.0}",
        off[n], (off[n] * 4) as f64 / (1u64 << 30) as f64, off[n] as f64 / n as f64);

    let mut signs: Vec<i64> = vec![1; n];
    let mut s: i128 = tab.par_iter()
        .map(|&(a, b, c, g)| (signs[a as usize] * signs[b as usize] * signs[c as usize] * g) as i128)
        .sum();
    let mut best = s.abs();
    let t0 = std::time::Instant::now();
    for sweep in 1.. {
        let mut improved = false;
        for i in 0..n {
            // The terms that would flip, at the CURRENT signs.
            let contrib: i128 = adj[off[i]..off[i + 1]].par_iter()
                .map(|&t| {
                    let (a, b, c, g) = tab[t as usize];
                    (signs[a as usize] * signs[b as usize] * signs[c as usize] * g) as i128
                })
                .sum();
            let s_new = s - 2 * contrib;
            if s_new.abs() > best {
                best = s_new.abs();
                s = s_new;
                signs[i] *= -1;
                improved = true;
            }
        }
        eprintln!("   [align] sweep {} done, best={} ({:.1} s elapsed){}", sweep, best,
            t0.elapsed().as_secs_f64(), if improved { "" } else { " -- converged" });
        if !improved { break; }
    }
    half_ball(m).into_iter().map(|k| (k, C::new(0.0, idx.get(&k).map_or(1, |&i| signs[i as usize]) as f64))).collect()
}

/// TABLE-FREE ALIGNMENT (2026-09-13) — the same greedy with no triad table at all.
///
/// The incremental version above still stores every triad (3.03 GB at M = 16, ~195 GB at
/// M = 32, which does not exist). But the incremental objective only ever reads ONE class's
/// triads at a time, so they need not be stored: they can be enumerated from the lattice on
/// demand. For a rep class `c`, every triad containing it has `c` or `-c` in one of the three
/// legs, so ~6|ball| candidate ordered pairs cover it, enumerated in three disjoint groups so
/// that each ordered pair is produced EXACTLY once:
///
///   (1) p = +-c,  q over the ball;
///   (2) q = +-c,  p over the ball with rep(p) != c;
///   (3) r = +-c   (so q = -r - p), p over the ball with rep(p) != c and rep(q) != c.
///
/// Cost per sweep becomes O(classes x |ball|) with O((2M+1)^3) bytes of state, against
/// O(classes x triads) and O(triads) bytes for the original. At M = 32 that is the difference
/// between 195 GB / ~108 days and a few megabytes / hours.
///
/// Every hot-path lookup is a dense array indexed by the wavevector, never a HashMap: at
/// M = 32 a sweep evaluates ~5.6e10 candidates, and three hash lookups apiece would dominate
/// everything. `direction_varied` is pure arithmetic and is simply recomputed.
///
/// This returns the SAME alignment as the table version — same class set and order, same sweep
/// order, same accept test — and is checked by reproducing it exactly at M = 8 and M = 16.
fn phases_adversarial_free(m: i64, ckpt: &str, start: &str) -> std::collections::HashMap<K, C> {
    let bv = ball(m);
    let side = (2 * m + 1) as usize;
    let lin = |k: &K| -> Option<usize> {
        if k.0.iter().any(|&x| x < -m || x > m) { return None; }
        Some((((k.0[0] + m) as usize * side) + (k.0[1] + m) as usize) * side + (k.0[2] + m) as usize)
    };
    let mut inball = vec![false; side * side * side];
    for k in &bv { inball[lin(k).unwrap()] = true; }

    // The (rep triple, weight) of one ordered pair, or None when absent/degenerate. Identical
    // arithmetic to `entry` in the table version; only the lookups differ.
    let entry = |p: &K, q: &K| -> Option<(K, K, K, i64)> {
        let r = p.add(q).neg();
        // ALL THREE legs must be in the ball. In the table version both p and q ranged over the
        // ball by construction so only r was tested; here group (3) builds q = -r - p, which can
        // land outside, so the test has to be explicit or an out-of-ball class index is read.
        for k in [p, q, &r] {
            match lin(k) { Some(i) if inball[i] => {}, _ => return None }
        }
        if *p == K([0,0,0]) || *q == K([0,0,0]) || r == K([0,0,0]) { return None; }
        let (rp, rq, rr) = (rep(p), rep(q), rep(&r));
        let w = r.sq() - q.sq();
        let g = w * q.dot(&p.cross(&direction_varied(&rp)))
                  * q.cross(&direction_varied(&rq)).dot(&r.cross(&direction_varied(&rr)));
        if g == 0 { None } else { Some((rp, rq, rr, g)) }
    };

    // Pass 1: the class SET, in the table version's order. O(|ball|^2) once, nothing stored.
    let present: std::collections::HashSet<K> = bv.par_iter().map(|p| {
        let mut s = std::collections::HashSet::new();
        for q in &bv {
            if let Some((rp, rq, rr, _)) = entry(p, q) { s.insert(rp); s.insert(rq); s.insert(rr); }
        }
        s
    }).reduce(std::collections::HashSet::new, |mut a, b| { a.extend(b); a });
    let mut classes: Vec<K> = present.into_iter().collect();
    classes.sort();
    let n = classes.len();
    let mut cidx = vec![u32::MAX; side * side * side];
    for (i, c) in classes.iter().enumerate() { cidx[lin(c).unwrap()] = i as u32; }
    let cls = |k: &K| -> u32 { lin(&rep(k)).map_or(u32::MAX, |i| cidx[i]) };
    eprintln!("   [align/free] M={} classes={} dense state {:.1} MB",
        m, n, (side * side * side * 5) as f64 / 1e6);

    let term = |rp: &K, rq: &K, rr: &K, g: i64, signs: &Vec<i64>| -> i128 {
        (signs[cls(rp) as usize] * signs[cls(rq) as usize] * signs[cls(rr) as usize] * g) as i128
    };
    // Sum of the terms that flip when class `ci` flips: triads containing it an ODD number of
    // times. The three groups are disjoint by construction, so no pair is counted twice.
    let contrib = |ci: usize, signs: &Vec<i64>| -> i128 {
        let c = classes[ci];
        [c, c.neg()].iter().map(|&s| {
            bv.par_iter().map(|x| {
                let mut acc: i128 = 0;
                let mut take = |p: K, q: K| {
                    if let Some((rp, rq, rr, g)) = entry(&p, &q) {
                        let mult = (rp == c) as u32 + (rq == c) as u32 + (rr == c) as u32;
                        if mult % 2 == 1 { acc += term(&rp, &rq, &rr, g, signs); }
                    }
                };
                take(s, *x);                                   // (1) p = s
                if rep(x) != c {
                    take(*x, s);                               // (2) q = s, rep(p) != c
                    let q = s.neg().sub(x);                    // (3) r = s  =>  q = -s - p
                    let inb = matches!(lin(&q), Some(i) if inball[i]);
                    if inb && rep(&q) != c { take(*x, q); }
                }
                acc
            }).sum::<i128>()
        }).sum()
    };

    // CHECKPOINTING (2026-09-13). At M = 32 this loop runs 20-50 h, and the intended host is a
    // PREEMPTIBLE spot instance -- so without this the job may simply never finish, and locally
    // it is one OOM away from losing everything (LL-26, which cost 1.5 h of trajectory the same
    // day). The signs vector is the entire state: dumped after each completed sweep, written to
    // a temp file and renamed so a kill mid-write cannot corrupt it. Resume is EXACT rather than
    // approximate -- the greedy visits i = 0..n-1 in order and accepts strict improvements, so
    // restarting at the top of a sweep from saved signs is precisely what an uninterrupted run
    // would do next. Only the running total is recomputed on load, in one cheap pass.
    let mut signs: Vec<i64> = vec![1; n];
    let mut sweep0 = 0usize;
    if !ckpt.is_empty() {
        if let Ok(text) = std::fs::read_to_string(ckpt) {
            let mut it = text.lines();
            let hdr = it.next().unwrap_or("");
            let parts: Vec<&str> = hdr.split_whitespace().collect();
            assert!(parts.len() >= 4 && parts[1] == format!("M={}", m),
                "checkpoint {} is for another M", ckpt);
            sweep0 = parts[2].trim_start_matches("sweep=").parse().unwrap();
            let v: Vec<i64> = it.filter_map(|l| l.trim().parse().ok()).collect();
            assert_eq!(v.len(), n, "checkpoint has {} signs, expected {}", v.len(), n);
            assert!(v.iter().all(|&x| x == 1 || x == -1), "checkpoint holds a non-sign");
            signs = v;
            eprintln!("   [align/free] RESUMED from {} after sweep {}", ckpt, sweep0);
        }
    }
    // `--phases-start`: seed the greedy from a sign vector produced elsewhere (the spectral
    // optimiser of docs/designs/SPECTRAL_ALIGNMENT.md), mapped by WAVEVECTOR so the file's
    // order never matters; classes absent from the file stay +1. The sweeps that follow are the
    // exact polish, and their count is the measurement the memo's section 3.3 asks for. Not
    // combined with a checkpoint: a checkpoint already carries the signs.
    if sweep0 == 0 && !start.is_empty() {
        let ph = phases_read(start, m);
        let mut seeded = 0usize;
        for (k, c) in &ph {
            let ci = cls(k);
            if ci != u32::MAX { signs[ci as usize] = c.im as i64; seeded += 1; }
        }
        eprintln!("   [align/free] seeded {} of {} classes from {}", seeded, n, start);
    }
    let mut s: i128 = bv.par_iter().map(|p| {
        let mut acc: i128 = 0;
        for q in &bv {
            if let Some((rp, rq, rr, g)) = entry(p, q) { acc += term(&rp, &rq, &rr, g, &signs); }
        }
        acc
    }).sum();
    let mut best = s.abs();
    eprintln!("   [align/free] initial exact |S| = {} (before any sweep)", best);
    let save = |sweep: usize, best: i128, signs: &Vec<i64>| {
        if ckpt.is_empty() { return; }
        let mut t = format!("# M={} sweep={} best={}\n", m, sweep, best);
        for &x in signs { t.push_str(&format!("{}\n", x)); }
        let tmp = format!("{}.tmp", ckpt);
        std::fs::write(&tmp, t).expect("write checkpoint");
        std::fs::rename(&tmp, ckpt).expect("rename checkpoint");   // atomic
    };
    let t0 = std::time::Instant::now();
    for sweep in (sweep0 + 1).. {
        let mut improved = false;
        for i in 0..n {
            let s_new = s - 2 * contrib(i, &signs);
            if s_new.abs() > best {
                best = s_new.abs();
                s = s_new;
                signs[i] *= -1;
                improved = true;
            }
        }
        save(sweep, best, &signs);
        eprintln!("   [align/free] sweep {} done, best={} ({:.1} s elapsed){}", sweep, best,
            t0.elapsed().as_secs_f64(), if improved { "" } else { " -- converged" });
        if !improved { break; }
    }
    half_ball(m).into_iter()
        .map(|k| (k, C::new(0.0, match cls(&k) { u32::MAX => 1, i => signs[i as usize] } as f64)))
        .collect()
}

/// DIRTY-TRACKED ALIGNMENT (2026-09-14). `phases_adversarial_free` re-evaluates every one of the
/// `n` classes on every sweep, even though measurement shows 45% of M=16's sweeps and 58% of
/// M=32's gain under 0.01% -- i.e. touch almost nothing -- while still paying the full
/// O(classes x |ball|) cost. This function is the SAME greedy, provably giving the SAME
/// sequence of accept/reject decisions, but skips a class's re-evaluation whenever nothing that
/// could change its answer has happened since it was last checked.
///
/// THE ARGUMENT, so the optimisation can be trusted rather than merely timed. contrib(i) sums
/// term(T) over triads T where class i has ODD multiplicity; term(T) is unchanged by flipping a
/// class k unless k ALSO has odd multiplicity in T (flipping multiplies term(T) by (-1)^{mult of
/// k in T}). So contrib(i) can change upon k's flip only if some triad T has BOTH i and k at odd
/// multiplicity -- and every such T is, by definition, one of the triads `contrib(k)` itself
/// sums over. Marking EVERY class appearing in every triad counted toward contrib(k) (a safe
/// over-approximation: it also marks a leg with even multiplicity in that same triad, which
/// cannot actually be affected, at the cost of a few needless rechecks) therefore marks every
/// class whose contrib truly could have changed, and only those plus a small, bounded excess.
/// A class left unmarked since its last (non-improving) check is PROVABLY unchanged, so skipping
/// it reproduces the exact decision a full recheck would have given.
///
/// Consequently: same class order, same Gauss-Seidel in-sweep update semantics, same accept
/// criterion (strict improvement) -- the only difference from `phases_adversarial_free` is which
/// contrib() calls are skipped as provably redundant. It is held to that claim, not merely
/// timed: validated by reproducing the FULL per-sweep `best` sequence already on record for
/// M = 16 (42 sweeps) and M = 32 (113 sweeps) exactly, not just a final answer.
fn phases_adversarial_dirty(m: i64, ckpt: &str) -> std::collections::HashMap<K, C> {
    use std::sync::atomic::{AtomicBool, Ordering::Relaxed};
    let bv = ball(m);
    let side = (2 * m + 1) as usize;
    let lin = |k: &K| -> Option<usize> {
        if k.0.iter().any(|&x| x < -m || x > m) { return None; }
        Some((((k.0[0] + m) as usize * side) + (k.0[1] + m) as usize) * side + (k.0[2] + m) as usize)
    };
    let mut inball = vec![false; side * side * side];
    for k in &bv { inball[lin(k).unwrap()] = true; }

    let entry = |p: &K, q: &K| -> Option<(K, K, K, i64)> {
        let r = p.add(q).neg();
        for k in [p, q, &r] {
            match lin(k) { Some(i) if inball[i] => {}, _ => return None }
        }
        if *p == K([0,0,0]) || *q == K([0,0,0]) || r == K([0,0,0]) { return None; }
        let (rp, rq, rr) = (rep(p), rep(q), rep(&r));
        let w = r.sq() - q.sq();
        let g = w * q.dot(&p.cross(&direction_varied(&rp)))
                  * q.cross(&direction_varied(&rq)).dot(&r.cross(&direction_varied(&rr)));
        if g == 0 { None } else { Some((rp, rq, rr, g)) }
    };

    let present: std::collections::HashSet<K> = bv.par_iter().map(|p| {
        let mut s = std::collections::HashSet::new();
        for q in &bv {
            if let Some((rp, rq, rr, _)) = entry(p, q) { s.insert(rp); s.insert(rq); s.insert(rr); }
        }
        s
    }).reduce(std::collections::HashSet::new, |mut a, b| { a.extend(b); a });
    let mut classes: Vec<K> = present.into_iter().collect();
    classes.sort();
    let n = classes.len();
    let mut cidx = vec![u32::MAX; side * side * side];
    for (i, c) in classes.iter().enumerate() { cidx[lin(c).unwrap()] = i as u32; }
    let cls = |k: &K| -> u32 { lin(&rep(k)).map_or(u32::MAX, |i| cidx[i]) };
    eprintln!("   [align/dirty] M={} classes={} dense state {:.1} MB",
        m, n, (side * side * side * 5) as f64 / 1e6);

    let term = |rp: &K, rq: &K, rr: &K, g: i64, signs: &Vec<i64>| -> i128 {
        (signs[cls(rp) as usize] * signs[cls(rq) as usize] * signs[cls(rr) as usize] * g) as i128
    };
    // Identical triad selection to phases_adversarial_free's contrib -- kept textually parallel
    // to it on purpose, so a diff between the two is easy to audit.
    let contrib = |ci: usize, signs: &Vec<i64>| -> i128 {
        let c = classes[ci];
        [c, c.neg()].iter().map(|&s| {
            bv.par_iter().map(|x| {
                let mut acc: i128 = 0;
                let mut take = |p: K, q: K| {
                    if let Some((rp, rq, rr, g)) = entry(&p, &q) {
                        let mult = (rp == c) as u32 + (rq == c) as u32 + (rr == c) as u32;
                        if mult % 2 == 1 { acc += term(&rp, &rq, &rr, g, signs); }
                    }
                };
                take(s, *x);
                if rep(x) != c {
                    take(*x, s);
                    let q = s.neg().sub(x);
                    let inb = matches!(lin(&q), Some(i) if inball[i]);
                    if inb && rep(&q) != c { take(*x, q); }
                }
                acc
            }).sum::<i128>()
        }).sum()
    };
    // Marks dirty every class appearing (in any leg, any multiplicity) in any triad counted
    // toward contrib(ci) -- the safe over-approximation the correctness argument above relies
    // on. Same triad-selection predicate as `contrib`, deliberately duplicated rather than
    // shared, so the two can be diffed by eye for exact agreement.
    let mark_dirty = |ci: usize, dirty: &[AtomicBool]| {
        let c = classes[ci];
        [c, c.neg()].iter().for_each(|&s| {
            bv.par_iter().for_each(|x| {
                let mark3 = |rp: K, rq: K, rr: K| {
                    dirty[cls(&rp) as usize].store(true, Relaxed);
                    dirty[cls(&rq) as usize].store(true, Relaxed);
                    dirty[cls(&rr) as usize].store(true, Relaxed);
                };
                let take = |p: K, q: K| {
                    if let Some((rp, rq, rr, _g)) = entry(&p, &q) {
                        let mult = (rp == c) as u32 + (rq == c) as u32 + (rr == c) as u32;
                        if mult % 2 == 1 { mark3(rp, rq, rr); }
                    }
                };
                take(s, *x);
                if rep(x) != c {
                    take(*x, s);
                    let q = s.neg().sub(x);
                    let inb = matches!(lin(&q), Some(i) if inball[i]);
                    if inb && rep(&q) != c { take(*x, q); }
                }
            });
        });
    };

    let mut signs: Vec<i64> = vec![1; n];
    let mut sweep0 = 0usize;
    if !ckpt.is_empty() {
        if let Ok(text) = std::fs::read_to_string(ckpt) {
            let mut it = text.lines();
            let hdr = it.next().unwrap_or("");
            let parts: Vec<&str> = hdr.split_whitespace().collect();
            assert!(parts.len() >= 4 && parts[1] == format!("M={}", m),
                "checkpoint {} is for another M", ckpt);
            sweep0 = parts[2].trim_start_matches("sweep=").parse().unwrap();
            let v: Vec<i64> = it.filter_map(|l| l.trim().parse().ok()).collect();
            assert_eq!(v.len(), n, "checkpoint has {} signs, expected {}", v.len(), n);
            assert!(v.iter().all(|&x| x == 1 || x == -1), "checkpoint holds a non-sign");
            signs = v;
            eprintln!("   [align/dirty] RESUMED from {} after sweep {}", ckpt, sweep0);
        }
    }
    // Dirty state is NOT checkpointed (only signs are). On resume every class starts dirty,
    // which is always safe (it is exactly what a fresh run's first sweep does) and costs at
    // most one full sweep of otherwise-avoidable work, once, after a restart.
    let dirty: Vec<AtomicBool> = (0..n).map(|_| AtomicBool::new(true)).collect();

    let mut s: i128 = bv.par_iter().map(|p| {
        let mut acc: i128 = 0;
        for q in &bv {
            if let Some((rp, rq, rr, g)) = entry(p, q) { acc += term(&rp, &rq, &rr, g, &signs); }
        }
        acc
    }).sum();
    let mut best = s.abs();
    let save = |sweep: usize, best: i128, signs: &Vec<i64>| {
        if ckpt.is_empty() { return; }
        let mut t = format!("# M={} sweep={} best={}\n", m, sweep, best);
        for &x in signs { t.push_str(&format!("{}\n", x)); }
        let tmp = format!("{}.tmp", ckpt);
        std::fs::write(&tmp, t).expect("write checkpoint");
        std::fs::rename(&tmp, ckpt).expect("rename checkpoint");
    };
    let t0 = std::time::Instant::now();
    for sweep in (sweep0 + 1).. {
        let mut improved = false;
        let mut checked: u64 = 0;
        for i in 0..n {
            if !dirty[i].load(Relaxed) { continue; }
            checked += 1;
            let s_new = s - 2 * contrib(i, &signs);
            if s_new.abs() > best {
                best = s_new.abs();
                s = s_new;
                signs[i] *= -1;
                improved = true;
                mark_dirty(i, &dirty);
            } else {
                dirty[i].store(false, Relaxed);
            }
        }
        save(sweep, best, &signs);
        eprintln!("   [align/dirty] sweep {} done, best={} ({:.1} s elapsed, {}/{} classes checked){}",
            sweep, best, t0.elapsed().as_secs_f64(), checked, n,
            if improved { "" } else { " -- converged" });
        if !improved { break; }
    }
    half_ball(m).into_iter()
        .map(|k| (k, C::new(0.0, match cls(&k) { u32::MAX => 1, i => signs[i as usize] } as f64)))
        .collect()
}

/// The alignment is deterministic and, at M = 16, the most expensive part of a run, while the
/// six adversarial runs of protocol S-3 (two signs x two step sizes, plus the every-step pair)
/// all need the SAME phases. `--phases-out` writes them, `--phases-in` reads them back, so the
/// alignment is paid once. The file records M and one sign per half-ball wavevector in the
/// half-ball's own order; loading checks both, so a file from another M cannot be used.
fn phases_write(path: &str, m: i64, phases: &std::collections::HashMap<K, C>) {
    let mut s = format!("# scout adversarial phases M={}\n", m);
    for k in half_ball(m) {
        s.push_str(&format!("{} {} {} {}\n", k.0[0], k.0[1], k.0[2], phases[&k].im as i64));
    }
    std::fs::write(path, s).expect("write phases");
    eprintln!("   [align] phases written to {}", path);
}

fn phases_read(path: &str, m: i64) -> std::collections::HashMap<K, C> {
    let text = std::fs::read_to_string(path).expect("read phases");
    let mut lines = text.lines();
    let hdr = lines.next().expect("phases header");
    assert_eq!(hdr, format!("# scout adversarial phases M={}", m), "phases file is for another M");
    let mut map = std::collections::HashMap::new();
    for (k, line) in half_ball(m).into_iter().zip(lines) {
        let f: Vec<i64> = line.split_whitespace().map(|t| t.parse().unwrap()).collect();
        assert_eq!(&f[..3], &k.0[..], "phases file is in the wrong order");
        assert!(f[3] == 1 || f[3] == -1, "phase is not a sign");
        map.insert(k, C::new(0.0, f[3] as f64));
    }
    assert_eq!(map.len(), half_ball(m).len(), "phases file is short");
    eprintln!("   [align] phases read from {}", path);
    map
}

// ------------------------------------------------------------------ modes

fn calibrate(path: &str) {
    let text = std::fs::read_to_string(path).expect("calibration file");
    let j: serde_json::Value = serde_json::from_str(&text).unwrap();
    let m = j["M"].as_i64().unwrap();
    let parse_frac = |s: &str| -> f64 { let p: Vec<&str> = s.split('/').collect(); if p.len() == 2 { p[0].parse::<f64>().unwrap() / p[1].parse::<f64>().unwrap() } else { s.parse().unwrap() } };
    let nu = parse_frac(j["nu"].as_str().unwrap());
    let dt = parse_frac(j["dt"].as_str().unwrap());
    let ball_json: Vec<K> = j["ball"].as_array().unwrap().iter().map(|a| K([a[0].as_i64().unwrap(), a[1].as_i64().unwrap(), a[2].as_i64().unwrap()])).collect();
    assert_eq!(ball_json, ball(m), "ball order must match the Python ball");
    let load = |row: &serde_json::Value| -> State {
        let mut s = State::zero(m);
        let comps = row["u"].as_array().unwrap();
        for i in 0..s.u.len() { for c in 0..3 {
            let pair = &comps[3 * i + c];
            s.u[i][c] = C::new(pair[0].as_str().unwrap().parse().unwrap(), pair[1].as_str().unwrap().parse().unwrap());
        }}
        s
    };
    for engine in [Engine::Direct, Engine::Fft] {
        let model = Model { nu, engine, grid: if engine == Engine::Fft { Some(Grid::new(m)) } else { None } };
        println!("== calibrate: M={} nu={} dt={} engine={} ==", m, nu, dt, if engine == Engine::Fft { "fft" } else { "direct" });
        for ic in ["adversarial", "null"] {
            let rows = j[ic].as_array().unwrap();
            let mut s = load(&rows[0]);
            let mut worst = 0.0f64;
            for (n, row) in rows.iter().enumerate() {
                let exact = load(row);
                let err = s.u.iter().zip(&exact.u).map(|(a, b)| (0..3).map(|c| (a[c] - b[c]).norm()).fold(0.0, f64::max)).fold(0.0, f64::max);
                let scale = exact.u.iter().map(|r| r.iter().map(|c| c.norm()).fold(0.0, f64::max)).fold(0.0, f64::max);
                let (_, b) = model.rhs(&s);
                let p = model.production(&s, &b);
                let pe: f64 = row["P_re"].as_str().unwrap().parse().unwrap();
                let ee: f64 = row["E"].as_str().unwrap().parse().unwrap();
                println!("   {:<11} step {} | max|u - exact| = {:.3e} (rel {:.3e}) | E {:.12} vs {:.12} | P_re {:.9e} vs {:.9e}",
                    ic, n, err, err / scale, s.energy(), ee, p.re, pe);
                worst = worst.max(err / scale);
                if n + 1 < rows.len() { s = model.euler(&s, dt); }
            }
            println!("   {:<11} WORST relative state error over the exact trajectory: {:.3e}", ic, worst);
        }
    }
}

// ------------------------------------------------------------------ spectral alignment
// docs/designs/SPECTRAL_ALIGNMENT.md. The greedy's integer objective S(sigma) is the scout's
// t=0 production P up to a sigma-independent constant (measured, memo section 2), so its
// gradient can be had from the FFT engine in O(N log N) instead of O(#triads).
//
// A fact the whole thing rests on, stated once: a triad with a repeated class has p = q (p = -q
// gives r = 0, excluded), and its weight contains q.(p x d_p) = p.(p x d_p) = 0. So no triad
// with a repeated class has nonzero weight, P is EXACTLY multilinear in the signs, and the real
// derivative dP/dsigma_j equals the exact single-flip delta. (It also means the "safe
// over-approximation" of CORE_TAIL_CAP.md 4.3.9 was exact: the density finding is genuine.)

/// (Ra)_k = a_{-k} on the full grid. Turns the adjoint's correlations into convolutions.
fn reflect_grid(grid: &Grid, a: &[C]) -> Vec<C> {
    let n = grid.n;
    let mut out = vec![C::new(0.0, 0.0); n * n * n];
    for i in 0..n { for j in 0..n { for l in 0..n {
        let k = K([grid.wave(i), grid.wave(j), grid.wave(l)]);
        out[grid.idx_of(&k.neg())] = a[(i * n + j) * n + l];
    }}}
    out
}

/// The three pieces of dP/du for P = sum_k |k|^2 Re<u_k, B_k(u)>, B = Leray N, N bilinear:
///   DP[h] = T(h,u,u) + T(u,h,u) + T(u,u,h), with
///   T(h,u,u) = Re sum_k |k|^2 <h_k, B_k>                       (h CONJUGATED: Hermitian pairing)
///   T(u,h,u) = Re sum_p sum_m h_p^m Y_p^m,  Y_p^m = sum_q q_m sum_i A^i_{p+q} u^i_q,
///                                            A^i_k = -i |k|^2 u^i_{-k}           (bilinear in h)
///   T(u,u,h) = Re sum_q sum_i h_q^i Z_q^i,  Z_q^i = -i sum_m q_m sum_p u^m_p ghat^i_{p+q},
///                                            ghat^i_k = |k|^2 u^i_{-k}          (bilinear in h)
/// The Leray in B drops out of the last two by self-adjointness, because u is divergence-free.
/// Each sum over p+q=k (or k-q=p, after reflecting one field) is a convolution: inverse
/// transforms, pointwise products, forward transforms -- b_fft's convention exactly, so the
/// two engines cannot disagree about normalisation. Returns (B, Y, Z) on the ball; the caller
/// applies the pairings. `drop_adjoint` and `no_reflect` are the NEGATIVE CONTROLS of the memo
/// section 4: each must make the gradient check fail.
fn grad_p_fft(s: &State, grid: &Grid, drop_adjoint: bool, no_reflect: bool)
    -> (Vec<[C; 3]>, Vec<[C; 3]>, Vec<[C; 3]>) {
    let n = grid.n;
    let n3 = (n * n * n) as f64;
    let b = b_fft(s, grid);
    let zero3 = vec![[C::new(0.0, 0.0); 3]; s.modes.len()];
    if drop_adjoint { return (b, zero3.clone(), zero3); }
    let u: Vec<Vec<C>> = (0..3).map(|i| grid.to_grid(s, i)).collect();
    let uref: Vec<Vec<C>> = if no_reflect { u.clone() } else { u.iter().map(|g| reflect_grid(grid, g)).collect() };
    let wave_at = |idx: usize| -> [i64; 3] {
        [grid.wave(idx / (n * n)), grid.wave((idx / n) % n), grid.wave(idx % n)]
    };
    // Physical-space fields, all independent -> one parallel loop of fifteen inverse transforms:
    //   slots 0..3   ghat^i_k     = |k|^2 u^i_{-k}
    //   slots 3..6   uref^i_k     = u^i_{-k}
    //   slots 6..15  Dcheck^{im}_q = -q_m u^i_{-q}      (i = (slot-6)/3, m = (slot-6)%3)
    let phys: Vec<Vec<C>> = (0..15).into_par_iter().map(|slot| {
        let mut g: Vec<C> = if slot < 3 {
            uref[slot].iter().enumerate().map(|(idx, &v)| {
                let w = wave_at(idx); v * ((w[0] * w[0] + w[1] * w[1] + w[2] * w[2]) as f64)
            }).collect()
        } else if slot < 6 {
            uref[slot - 3].clone()
        } else {
            let (i, m) = ((slot - 6) / 3, (slot - 6) % 3);
            uref[i].iter().enumerate().map(|(idx, &v)| v * (-(wave_at(idx)[m] as f64))).collect()
        };
        grid.fft3(&mut g, true);
        g
    }).collect();
    let (gh, rest) = phys.split_at(3);
    let (ur, dch) = rest.split_at(3);
    let mi = C::new(0.0, -1.0);
    // Y^m(x) = sum_i A^i(x) Dcheck^{im}(x),  A^i = -i ghat^i         -> three forward transforms
    let y: Vec<Vec<C>> = (0..3).into_par_iter().map(|m| {
        let mut g: Vec<C> = (0..n * n * n).map(|idx| {
            let mut acc = C::new(0.0, 0.0);
            for i in 0..3 { acc = acc + mi * gh[i][idx] * dch[3 * i + m][idx]; }
            acc
        }).collect();
        grid.fft3(&mut g, false);
        for x in g.iter_mut() { *x = *x / n3; }
        g
    }).collect();
    // E^{im}(x) = ghat^i(x) uref^m(x);  Z^i_q = -i sum_m q_m E^{im}_q  -> nine forward transforms
    let e: Vec<Vec<C>> = (0..9).into_par_iter().map(|slot| {
        let (i, m) = (slot / 3, slot % 3);
        let mut g: Vec<C> = (0..n * n * n).map(|idx| gh[i][idx] * ur[m][idx]).collect();
        grid.fft3(&mut g, false);
        for x in g.iter_mut() { *x = *x / n3; }
        g
    }).collect();
    let yy: Vec<[C; 3]> = s.modes.iter().map(|k| {
        let idx = grid.idx_of(k); [y[0][idx], y[1][idx], y[2][idx]]
    }).collect();
    let zz: Vec<[C; 3]> = s.modes.iter().map(|k| {
        let idx = grid.idx_of(k);
        let mut out = [C::new(0.0, 0.0); 3];
        for i in 0..3 {
            let mut acc = C::new(0.0, 0.0);
            for m in 0..3 { acc = acc + e[3 * i + m][idx] * (k.0[m] as f64); }
            out[i] = mi * acc;
        }
        out
    }).collect();
    (b, yy, zz)
}

/// dP/dsigma_j for every half-ball class j, from the (B, Y, Z) pieces of the gradient and the
/// chain rule through u_j = f lam sigma_j w_j, u_{-j} = f lam sigma_j conj(w_j), w_j = i(j x d_j).
/// `flam` = f * lam carries the SIGN of lambda: lambda < 0 in every registered protocol, and
/// without it every flip decision would be inverted.
fn dp_dsigma(s: &State, hb: &[K], bb: &[[C; 3]], yy: &[[C; 3]], zz: &[[C; 3]], flam: f64) -> Vec<f64> {
    hb.iter().map(|k| {
        let d = direction_varied(k);
        let cr = k.cross(&d);
        let w = [C::new(0.0, cr.0[0] as f64), C::new(0.0, cr.0[1] as f64), C::new(0.0, cr.0[2] as f64)];
        let wc = [w[0].conj(), w[1].conj(), w[2].conj()];
        let (i, im) = (s.index[k], s.index[&k.neg()]);
        let ks = k.sq() as f64;
        let mut acc = C::new(0.0, 0.0);
        for c in 0..3 {
            acc = acc + (w[c].conj() * bb[i][c] + wc[c].conj() * bb[im][c]) * ks;
            acc = acc + w[c] * yy[i][c] + wc[c] * yy[im][c];
            acc = acc + w[c] * zz[i][c] + wc[c] * zz[im][c];
        }
        acc.re * flam
    }).collect()
}

/// DAMPED JACOBI SIGN ASCENT -- docs/designs/SPECTRAL_ALIGNMENT.md section 3.2 (A).
///
/// The greedy's decision rule ("flip j if it increases |P|") applied to ALL classes at once
/// from ONE FFT gradient, instead of one class at a time from one triad enumeration each.
/// Because P is exactly multilinear in the signs (see the note above grad_p_fft), the single-
/// flip change is exactly delta_j = -2 sigma_j dP/dsigma_j. Flipping a SET of classes is not
/// additive (cross terms), which is why undamped Jacobi oscillates on a dense coupling; so:
///   - flip only the top fraction rho of the improvers, largest |delta| first;
///   - recompute P exactly after the flips (one RHS) and ACCEPT only if |P| grew, else revert
///     and halve rho; when rho shrinks to a single class the step is an exact greedy step and
///     progress is guaranteed;
///   - stop when no single flip improves |P| -- the same local-optimality condition the greedy
///     stops at, so the exact greedy polish that follows should need ~one confirming sweep.
/// Float throughout; the result is a sign vector whose objective is then recomputed EXACTLY by
/// the greedy path (`--align free --phases-start`), so float error can only make the search
/// worse, never the record wrong. This is a DIFFERENT adversarial family from the greedy's
/// (a different local optimum of the same objective) and is reported as one.
fn phases_adversarial_jacobi(m: i64, lam: f64, e0: f64, rho0: f64, max_iter: usize)
    -> std::collections::HashMap<K, C> {
    let hb = half_ball(m);
    let n = hb.len();
    let grid = Grid::new(m);
    let model = Model { nu: 0.0, engine: Engine::Fft, grid: None };
    let mut signs: Vec<i64> = vec![1; n];
    let build = |signs: &Vec<i64>| -> (State, f64) {
        let phases: std::collections::HashMap<K, C> =
            hb.iter().zip(signs).map(|(k, &sg)| (*k, C::new(0.0, sg as f64))).collect();
        let mut s = make_state(m, &phases, lam);
        let f = (e0 / s.energy()).sqrt();
        for row in s.u.iter_mut() { for c in 0..3 { row[c] = row[c] * f; } }
        (s, f)
    };
    let (mut s, f) = build(&signs);
    let flam = f * lam;
    let mut p = model.production(&s, &b_fft(&s, &grid)).re;
    let mut rho = rho0;
    let t0 = std::time::Instant::now();
    eprintln!("   [align/jacobi] M={} n={} grid={}^3 start |P|={:.6e} rho0={}", m, n, grid.n, p.abs(), rho0);
    let mut it = 0usize;
    let mut flips_total = 0usize;
    while it < max_iter {
        it += 1;
        let (bb, yy, zz) = grad_p_fft(&s, &grid, false, false);
        let dp = dp_dsigma(&s, &hb, &bb, &yy, &zz, flam);
        // exact single-flip gain in |P|: |P + delta_j| - |P|
        let mut gain: Vec<(f64, usize)> = (0..n).map(|j| {
            let delta = -2.0 * (signs[j] as f64) * dp[j];
            ((p + delta).abs() - p.abs(), j)
        }).filter(|&(g, _)| g > 0.0).collect();
        if gain.is_empty() {
            eprintln!("   [align/jacobi] iter {} converged: no single flip improves |P| ({:.1} s, {} flips total)",
                it, t0.elapsed().as_secs_f64(), flips_total);
            break;
        }
        gain.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap());
        // damped step with exact acceptance
        loop {
            let take = ((rho * n as f64).ceil() as usize).clamp(1, gain.len());
            let mut trial = signs.clone();
            for &(_, j) in &gain[..take] { trial[j] = -trial[j]; }
            let (st, _) = build(&trial);
            let pt = model.production(&st, &b_fft(&st, &grid)).re;
            if pt.abs() > p.abs() {
                signs = trial; s = st;
                let improvers = gain.len();
                p = pt;
                flips_total += take;
                eprintln!("   [align/jacobi] iter {:>4}: |P|={:.9e} flipped {:>6}/{:<6} improvers rho={:.4} ({:.1} s)",
                    it, p.abs(), take, improvers, rho, t0.elapsed().as_secs_f64());
                rho = (rho * 1.25).min(0.5);
                break;
            }
            if take == 1 {
                // A single exact-delta flip cannot fail to improve unless float error at the
                // 1e-16 level says otherwise; treat that as convergence.
                eprintln!("   [align/jacobi] iter {} converged: best single flip does not improve |P| in float ({:.1} s)",
                    it, t0.elapsed().as_secs_f64());
                it = max_iter; break;
            }
            rho /= 2.0;
        }
    }
    eprintln!("   [align/jacobi] final |P|={:.9e} after {} iterations, {} flips, {:.1} s", p.abs(), it, flips_total, t0.elapsed().as_secs_f64());
    hb.iter().zip(&signs).map(|(k, &sg)| (*k, C::new(0.0, sg as f64))).collect()
}

/// gradcheck --M m --phases-in f [--lambda l] [--E0 e] [--drop-adjoint] [--no-reflect]
/// Prints dP/dsigma_j for every half-ball class j, plus Euler's identity for a homogeneous
/// cubic form -- sum_j sigma_j dP/dsigma_j = 3P -- checked against the scout's own production,
/// which needs no external oracle at all. The per-class values are then compared in Python
/// against the exact-integer dS/dsigma_j (exploration/alignment_spectral/gradcheck.py): the
/// ratio must be one constant over j, the memo's 8.8586e-8 at M = 8.
fn gradcheck(args: &[String]) {
    let get = |name: &str, default: &str| -> String {
        args.iter().position(|a| a == name).map(|i| args[i + 1].clone()).unwrap_or(default.to_string())
    };
    let m: i64 = get("--M", "8").parse().unwrap();
    let lam: f64 = get("--lambda", "-0.05").parse().unwrap();
    let e0: f64 = get("--E0", "144").parse().unwrap();
    let drop_adjoint = args.iter().any(|a| a == "--drop-adjoint");
    let no_reflect = args.iter().any(|a| a == "--no-reflect");
    // `--ic null --seed s` builds a state with genuinely COMPLEX coefficients (circle phases).
    // Needed for the reflection control: on the sign family u_{-k} = -u_k, so the reflection
    // is a sign flip that every adjoint term contains twice -- `--no-reflect` cannot fail there
    // (LL-19: a control that cannot fail is not a control). On a complex field it can.
    let ic = get("--ic", "adv");
    let seed: u64 = get("--seed", "1").parse().unwrap();
    let phases = if ic == "null" { phases_random(m, seed) } else { phases_read(&get("--phases-in", ""), m) };
    let mut s = make_state(m, &phases, lam);
    let f = (e0 / s.energy()).sqrt();
    for row in s.u.iter_mut() { for c in 0..3 { row[c] = row[c] * f; } }
    let grid = Grid::new(m);
    let t0 = std::time::Instant::now();
    let (bb, yy, zz) = grad_p_fft(&s, &grid, drop_adjoint, no_reflect);
    let t_grad = t0.elapsed().as_secs_f64();
    let model = Model { nu: 0.0, engine: Engine::Fft, grid: None };
    let p = model.production(&s, &bb).re;
    // The three slots paired with h = u itself, over ALL modes. Each must equal P on any
    // divergence-free real field (homogeneity of the cubic form, slot by slot) -- an oracle-free
    // check that separates the three terms, so a wrong adjoint or a wrong reflection shows up
    // in T2/T3 individually rather than hiding in a sum.
    let (mut t1, mut t2, mut t3) = (0.0, 0.0, 0.0);
    for (i, k) in s.modes.iter().enumerate() {
        let ks = k.sq() as f64;
        for c in 0..3 {
            t1 += (s.u[i][c].conj() * bb[i][c]).re * ks;
            t2 += (s.u[i][c] * yy[i][c]).re;
            t3 += (s.u[i][c] * zz[i][c]).re;
        }
    }
    eprintln!("   [gradcheck] slot-wise Euler, h = u:  T1/P = {:.15}  T2/P = {:.15}  T3/P = {:.15}",
        t1 / p, t2 / p, t3 / p);
    if ic == "null" {
        eprintln!("   [gradcheck] M={} ic=null seed={} grid={}^3 gradient {:.3} s | P = {:.12e}{}",
            m, seed, grid.n, t_grad, p,
            if drop_adjoint { "  [NEGATIVE CONTROL: adjoint dropped]" } else if no_reflect { "  [NEGATIVE CONTROL: reflection dropped]" } else { "" });
        return;   // the per-class sigma pairing is meaningless for circle phases
    }
    let mut euler = 0.0;
    for k in half_ball(m) {
        let d = direction_varied(&k);
        let cr = k.cross(&d);
        // du_k/dsigma_k = f lam w,  du_{-k}/dsigma_k = f lam conj(w),  w = i (k x d_k)
        let w = [C::new(0.0, cr.0[0] as f64), C::new(0.0, cr.0[1] as f64), C::new(0.0, cr.0[2] as f64)];
        let wc = [w[0].conj(), w[1].conj(), w[2].conj()];
        let (i, im) = (s.index[&k], s.index[&k.neg()]);
        let ks = k.sq() as f64;
        let mut acc = C::new(0.0, 0.0);
        for c in 0..3 {
            acc = acc + (w[c].conj() * bb[i][c] + wc[c].conj() * bb[im][c]) * ks;   // T(h,u,u), h conjugated
            acc = acc + w[c] * yy[i][c] + wc[c] * yy[im][c];                          // T(u,h,u), bilinear
            acc = acc + w[c] * zz[i][c] + wc[c] * zz[im][c];                          // T(u,u,h), bilinear
        }
        let dp = acc.re * f * lam;
        euler += phases[&k].im * dp;
        println!("{} {} {} {:.17e}", k.0[0], k.0[1], k.0[2], dp);
    }
    eprintln!("   [gradcheck] M={} grid={}^3 gradient {:.3} s | P = {:.12e} | sum_j sigma_j dP/dsigma_j = {:.12e} | ratio/3P = {:.15}{}",
        m, grid.n, t_grad, p, euler, euler / (3.0 * p),
        if drop_adjoint { "  [NEGATIVE CONTROL: adjoint dropped]" } else if no_reflect { "  [NEGATIVE CONTROL: reflection dropped]" } else { "" });
}

fn scout(args: &[String]) {
    let get = |name: &str, default: &str| -> String {
        args.iter().position(|a| a == name).map(|i| args[i + 1].clone()).unwrap_or(default.to_string())
    };
    let m: i64 = get("--M", "2").parse().unwrap();
    let nu: f64 = get("--nu", "0.05").parse().unwrap();
    let dt: f64 = get("--dt", "0.001").parse().unwrap();
    let steps: usize = get("--steps", "1000").parse().unwrap();
    let every: usize = get("--every", "50").parse().unwrap();
    let lam: f64 = get("--lambda", "0.05").parse().unwrap();
    let ic = get("--ic", "adv");
    let engine = if get("--engine", "fft") == "direct" { Engine::Direct } else { Engine::Fft };
    let seed: u64 = get("--seed", "1").parse().unwrap();
    let pin = get("--phases-in", "");
    let pout = get("--phases-out", "");
    // `--align table` keeps the validated triad-table greedy; `--align free` uses the
    // table-free enumeration, which is the only one that reaches M = 32. Both are retained so
    // that either can check the other.
    let align = get("--align", "table");
    let phases = if ic == "adv" {
        if pin.is_empty() {
            let ckpt = get("--ckpt", "");
            let e0_for_align: f64 = get("--E0", "144").parse().unwrap();
            let rho0: f64 = get("--rho", "0.1").parse().unwrap();
            let max_iter: usize = get("--max-iter", "10000").parse().unwrap();
            let start = get("--phases-start", "");
            let p = match align.as_str() {
                "free" => phases_adversarial_free(m, &ckpt, &start),
                "dirty" => phases_adversarial_dirty(m, &ckpt),
                "jacobi" => phases_adversarial_jacobi(m, lam, e0_for_align, rho0, max_iter),
                _ => phases_adversarial(m),
            };
            if !pout.is_empty() { phases_write(&pout, m, &p); }
            p
        } else {
            phases_read(&pin, m)
        }
    } else {
        phases_random(m, seed)
    };
    let mut s = make_state(m, &phases, lam);
    // Optional normalisation to a prescribed initial ENERGY, so runs at different M are
    // physically comparable (same E0, same nu); the sign of lambda is preserved.
    let e0_opt = get("--E0", "");
    if !e0_opt.is_empty() {
        let e0: f64 = e0_opt.parse().unwrap();
        let f = (e0 / s.energy()).sqrt();
        for row in s.u.iter_mut() { for c in 0..3 { row[c] = row[c] * f; } }
    }
    let model = Model { nu, engine, grid: if engine == Engine::Fft { Some(Grid::new(m)) } else { None } };
    println!("== scout: M={} ic={} nu={} dt={} steps={} lambda={} E0={} engine={} modes={} ==",
        m, ic, nu, dt, steps, lam, if e0_opt.is_empty() { "-".to_string() } else { e0_opt.clone() },
        if engine == Engine::Fft { "fft" } else { "direct" }, s.modes.len());
    println!("step,t,E,D,D2,P_re,P_im,ratio_energy,ratio_enstrophy");
    for n in 0..=steps {
        if n % every == 0 {
            let (_, b) = model.rhs(&s);
            let p = model.production(&s, &b);
            let d = s.dissipation();
            let d2 = s.dissipation2();
            println!("{},{:.6},{:.9e},{:.9e},{:.9e},{:.9e},{:.3e},{:.6},{:.6}",
                n, n as f64 * dt, s.energy(), d, d2, p.re, p.im, p.re / (nu * d), p.re / (nu * d2));
        }
        if n < steps { s = model.rk4(&s, dt); }
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    match args.get(1).map(|s| s.as_str()) {
        Some("calibrate") => calibrate(&args[2]),
        Some("scout") => scout(&args[2..]),
        Some("gradcheck") => gradcheck(&args[2..]),
        _ => eprintln!("usage: calibrate <json> | scout --M m --ic adv|null --nu x --dt x --steps n [--every e] [--lambda l] [--engine fft|direct] [--seed s] [--align table|free|dirty] [--ckpt f] [--phases-out f | --phases-in f]"),
    }
}
