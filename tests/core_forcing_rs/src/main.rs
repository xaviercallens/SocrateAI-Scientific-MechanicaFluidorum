//! TIER B — the Core-Tail forcing evaluator, exact, with NO floating point.
//!
//! REGISTRATION: docs/designs/CORE_TAIL_CAP.md section 5. The Python reference implementation
//! and the gate-wired checker is tests/tier_b_core_forcing_bound.py; this crate is the scaled
//! evaluator that the certificate at M_core <= 8 will use, and it is validated against that
//! reference rather than trusted (CLAUDE.md: "agent/tool self-reports are not evidence").
//!
//! THE ARITHMETIC. Every quantity is a non-negative fixed-point rational n / 2^FRAC on i128,
//! and every operation rounds in a DECLARED direction. Rounding up everywhere on the
//! right-hand side of an upper bound keeps the result a rigorous upper bound; the precision
//! FRAC buys tightness, never validity. This is the reconciliation of "interval arithmetic"
//! with the standing ban on floating point in Tier B artifacts: the intervals are rational.
//!
//! WHAT IT COMPUTES. For a Galerkin state on ball(M), for every mode k,
//!     forcing(k) = |k| * sum_{p+q=k} ||u_p|| ||u_q||           (T-2', PROPOSED)
//! with |k| and every ||u_p|| replaced by certified fixed-point upper bounds. T-2' awaits
//! owner adoption (rule E-1); this crate computes it, it does not claim it.
//!
//! MODES
//!   verify <reference.json>   recompute the bound and check it against the two-sided exact
//!                             rational reference produced by
//!                             `python3 tests/tier_b_core_forcing_bound.py --export <path> <M>`
//!   bench  <M>                time the evaluator at a given ball radius (no claims)

use rayon::prelude::*;

// ---------------------------------------------------------------------------
// Non-negative fixed-point rationals: n / 2^FRAC on i128, explicit rounding.
// ---------------------------------------------------------------------------

const FRAC: u32 = 40;
const ONE: i128 = 1i128 << FRAC;

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Debug)]
struct Fx(i128);

impl Fx {
    const ZERO: Fx = Fx(0);

    /// The exact value of a non-negative integer.
    fn from_int(n: i64) -> Fx {
        Fx((n as i128) << FRAC)
    }

    /// Exact addition: no rounding is possible, and overflow would be a bug, not a rounding.
    fn add(self, o: Fx) -> Fx {
        Fx(self.0.checked_add(o.0).expect("fixed-point overflow in add"))
    }

    /// Multiplication rounded UP (ceiling), so a product of upper bounds stays an upper bound.
    fn mul_up(self, o: Fx) -> Fx {
        let p = self.0.checked_mul(o.0).expect("fixed-point overflow in mul");
        Fx((p + (ONE - 1)) >> FRAC)
    }

    /// Multiplication rounded DOWN, used only to build the lower comparison in `verify`.
    fn mul_down(self, o: Fx) -> Fx {
        let p = self.0.checked_mul(o.0).expect("fixed-point overflow in mul");
        Fx(p >> FRAC)
    }

    /// An upper bound on sqrt(self). sqrt(n / 2^FRAC) = sqrt(n * 2^FRAC) / 2^FRAC, so the
    /// numerator is isqrt(n << FRAC) + 1, and (isqrt(N)+1)^2 > N certifies it.
    fn sqrt_up(self) -> Fx {
        assert!(self.0 >= 0, "sqrt of a negative fixed-point value");
        if self.0 == 0 {
            return Fx::ZERO;
        }
        let scaled = self.0.checked_shl(FRAC).expect("fixed-point overflow in sqrt");
        Fx(isqrt_i128(scaled) + 1)
    }

    /// Rational numerator/denominator of the exact value this Fx represents.
    fn as_ratio(self) -> (i128, i128) {
        (self.0, ONE)
    }
}

/// Integer square root on i128 by Newton's method, exact (floor).
fn isqrt_i128(n: i128) -> i128 {
    if n < 2 {
        return n;
    }
    let mut x = 1i128 << ((128 - n.leading_zeros() as i128 + 1) / 2);
    loop {
        let y = (x + n / x) >> 1;
        if y >= x {
            break;
        }
        x = y;
    }
    while x * x > n {
        x -= 1;
    }
    while (x + 1) * (x + 1) <= n {
        x += 1;
    }
    x
}

/// Parse "num/den" (or "int") into an exact rational, then round it in the given direction.
fn parse_frac_round(s: &str, up: bool) -> Fx {
    let (num, den) = match s.split_once('/') {
        Some((a, b)) => (a.parse::<i128>().expect("numerator"), b.parse::<i128>().expect("denominator")),
        None => (s.parse::<i128>().expect("integer"), 1i128),
    };
    assert!(num >= 0 && den > 0, "only non-negative rationals are represented");
    // num/den = (num << FRAC) / den / 2^FRAC
    let scaled = num.checked_shl(FRAC).expect("overflow parsing a rational");
    Fx(if up { (scaled + den - 1) / den } else { scaled / den })
}

// ---------------------------------------------------------------------------
// The lattice, mirroring FourierDynamicsZ3.ball exactly.
// ---------------------------------------------------------------------------

type K = [i64; 3];

fn k_sq(k: &K) -> i64 {
    k[0] * k[0] + k[1] * k[1] + k[2] * k[2]
}

fn ball(m: i64) -> Vec<K> {
    let mut out = Vec::new();
    for x in -m..=m {
        for y in -m..=m {
            for z in -m..=m {
                let k = [x, y, z];
                if k_sq(&k) <= m * m {
                    out.push(k);
                }
            }
        }
    }
    out
}

// ---------------------------------------------------------------------------
// The evaluator.
// ---------------------------------------------------------------------------

struct Field {
    m: i64,
    modes: Vec<K>,
    index: std::collections::HashMap<K, usize>,
    /// beta[i] >= ||u_{modes[i]}||, a certified fixed-point upper bound.
    beta: Vec<Fx>,
    /// gamma[i] >= |modes[i]|.
    gamma: Vec<Fx>,
}

impl Field {
    /// From per-mode ||u_k||^2 given as exact rationals, rounded UP into fixed point.
    fn from_norm_sq(m: i64, modes: Vec<K>, norm_sq: &[&str]) -> Field {
        let index: std::collections::HashMap<K, usize> =
            modes.iter().enumerate().map(|(i, k)| (*k, i)).collect();
        let beta = norm_sq
            .iter()
            .map(|s| parse_frac_round(s, true).sqrt_up())
            .collect();
        let gamma = modes
            .iter()
            .map(|k| Fx::from_int(k_sq(k)).sqrt_up())
            .collect();
        Field { m, modes, index, beta, gamma }
    }

    /// T-2' at one mode: |k| * sum_{p+q=k} ||u_p|| ||u_q||, every operation rounded UP.
    fn forcing_upper(&self, ki: usize) -> Fx {
        let k = self.modes[ki];
        let mut acc = Fx::ZERO;
        for (pi, p) in self.modes.iter().enumerate() {
            let bp = self.beta[pi];
            if bp == Fx::ZERO {
                continue;
            }
            let q = [k[0] - p[0], k[1] - p[1], k[2] - p[2]];
            if k_sq(&q) > self.m * self.m {
                continue;
            }
            match self.index.get(&q) {
                Some(&qi) if self.beta[qi] != Fx::ZERO => {
                    acc = acc.add(bp.mul_up(self.beta[qi]));
                }
                _ => {}
            }
        }
        self.gamma[ki].mul_up(acc)
    }

    /// The same sum with every operation rounded DOWN -- not a rigorous bound, used only to
    /// bracket the reference in `verify` and to show the rounding direction is doing work.
    fn forcing_lower(&self, ki: usize) -> Fx {
        let k = self.modes[ki];
        let mut acc = Fx::ZERO;
        for (pi, p) in self.modes.iter().enumerate() {
            let bp = self.beta[pi];
            if bp == Fx::ZERO {
                continue;
            }
            let q = [k[0] - p[0], k[1] - p[1], k[2] - p[2]];
            if k_sq(&q) > self.m * self.m {
                continue;
            }
            if let Some(&qi) = self.index.get(&q) {
                acc = acc.add(bp.mul_down(self.beta[qi]));
            }
        }
        self.gamma[ki].mul_down(acc)
    }

    fn all_forcing_upper(&self) -> Vec<Fx> {
        (0..self.modes.len())
            .into_par_iter()
            .map(|i| self.forcing_upper(i))
            .collect()
    }
}

// ---------------------------------------------------------------------------
// Modes.
// ---------------------------------------------------------------------------

fn verify(path: &str) {
    let text = std::fs::read_to_string(path).expect("reference file");
    let j: serde_json::Value = serde_json::from_str(&text).unwrap();
    let m = j["M"].as_i64().unwrap();
    let modes: Vec<K> = j["ball"]
        .as_array()
        .unwrap()
        .iter()
        .map(|a| {
            [a[0].as_i64().unwrap(), a[1].as_i64().unwrap(), a[2].as_i64().unwrap()]
        })
        .collect();
    assert_eq!(modes, ball(m), "ball order must match the Python ball exactly");

    let get = |key: &str| -> Vec<&str> {
        j[key].as_array().unwrap().iter().map(|v| v.as_str().unwrap()).collect()
    };
    let nsq = get("norm_sq");
    let ref_lo = get("bound_lower");
    let ref_hi = get("bound_upper");

    let f = Field::from_norm_sq(m, modes.clone(), &nsq);
    let mine = f.all_forcing_upper();

    println!("TIER B -- Rust forcing evaluator vs the Python exact-rational reference");
    println!(
        "   M = {}, {} modes, fixed point n/2^{}, reference at 2^-{}",
        m,
        modes.len(),
        FRAC,
        j["bits"].as_i64().unwrap()
    );
    println!("   weight: {}", j["weight"].as_str().unwrap());

    // The true bound T lies in [ref_lo, ref_hi] because the Python bounds round the square
    // roots down and up respectively. A rigorous evaluator must return at least ref_lo; a
    // useful one must not exceed ref_hi by more than the two precisions allow.
    let mut below = 0usize;
    let mut worst_gap_num: i128 = 0;
    let mut worst_gap_den: i128 = 1;
    let mut nonzero = 0usize;
    for i in 0..modes.len() {
        let lo = parse_frac_round(ref_lo[i], false);
        let hi = parse_frac_round(ref_hi[i], true);
        if mine[i] < lo {
            below += 1;
        }
        if hi.0 > 0 {
            nonzero += 1;
            // gap = (mine - hi) / hi, compared as fractions without division.
            let (num, _) = mine[i].as_ratio();
            let d = num - hi.0;
            if d > 0 && d * worst_gap_den > worst_gap_num * hi.0 {
                worst_gap_num = d;
                worst_gap_den = hi.0;
            }
        }
    }
    let lower_check = (0..modes.len()).filter(|&i| f.forcing_lower(i) > mine[i]).count();

    println!("   modes with a nonzero bound: {}", nonzero);
    println!(
        "   RIGOUR: results below the reference's lower bound: {} (must be 0)",
        below
    );
    println!(
        "   rounding does work: modes where the round-DOWN sum exceeds the round-UP sum: {} (must be 0)",
        lower_check
    );
    if worst_gap_num == 0 {
        println!("   TIGHTNESS: never exceeds the reference upper bound");
    } else {
        // print the gap as a rational, never as a float
        println!(
            "   TIGHTNESS: worst excess over the reference upper bound = {}/{}",
            worst_gap_num, worst_gap_den
        );
    }
    let ok = below == 0 && lower_check == 0;
    println!("\nSCOPE. This validates ARITHMETIC against an exact reference. It adopts no");
    println!("object, bounds no solution, and says nothing about uniformity in M. O5 stands.");
    println!("\nRESULT: {}", if ok { "PASS" } else { "FAIL" });
    if !ok {
        std::process::exit(1);
    }
}

fn bench(m: i64) {
    let modes = ball(m);
    let n = modes.len();
    // A deterministic non-negative ||u_k||^2 pattern; this mode makes no claims, it measures
    // throughput for the GCP/local sizing question.
    let nsq: Vec<String> = modes
        .iter()
        .map(|k| {
            let s = k_sq(k).max(1);
            format!("1/{}", s * s)
        })
        .collect();
    let refs: Vec<&str> = nsq.iter().map(|s| s.as_str()).collect();
    let f = Field::from_norm_sq(m, modes, &refs);
    let t0 = std::time::Instant::now();
    let out = f.all_forcing_upper();
    let dt = t0.elapsed();
    let nz = out.iter().filter(|x| **x != Fx::ZERO).count();
    println!(
        "bench: M = {}, {} modes, {} nonzero bounds, {} mode-evaluations, wall {:?}",
        m,
        n,
        nz,
        n * n,
        dt
    );
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    match args.get(1).map(|s| s.as_str()) {
        Some("verify") => verify(&args[2]),
        Some("bench") => bench(args[2].parse().expect("M")),
        _ => {
            eprintln!("usage: core_forcing verify <reference.json> | bench <M>");
            std::process::exit(2);
        }
    }
}
