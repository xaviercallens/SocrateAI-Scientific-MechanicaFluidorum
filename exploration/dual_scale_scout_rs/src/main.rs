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
    let mut signs: Vec<i64> = vec![1; classes.len()];
    let total = |signs: &Vec<i64>| -> i128 {
        tab.par_iter()
            .map(|&(a, b, c, g)| (signs[a as usize] * signs[b as usize] * signs[c as usize] * g) as i128)
            .sum::<i128>().abs()
    };
    let mut best = total(&signs);
    let t0 = std::time::Instant::now();
    for sweep in 1.. {
        let mut improved = false;
        for i in 0..classes.len() {
            signs[i] *= -1;
            let v = total(&signs);
            if v > best { best = v; improved = true; } else { signs[i] *= -1; }
        }
        eprintln!("   [align] sweep {} done, best={} ({:.1} s elapsed){}", sweep, best,
            t0.elapsed().as_secs_f64(), if improved { "" } else { " -- converged" });
        if !improved { break; }
    }
    half_ball(m).into_iter().map(|k| (k, C::new(0.0, idx.get(&k).map_or(1, |&i| signs[i as usize]) as f64))).collect()
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
    let phases = if ic == "adv" {
        if pin.is_empty() {
            let p = phases_adversarial(m);
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
        _ => eprintln!("usage: calibrate <json> | scout --M m --ic adv|null --nu x --dt x --steps n [--every e] [--lambda l] [--engine fft|direct] [--seed s] [--phases-out f | --phases-in f]"),
    }
}
