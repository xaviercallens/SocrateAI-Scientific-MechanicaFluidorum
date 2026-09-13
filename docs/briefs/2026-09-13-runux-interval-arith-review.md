# Cross-stream review — `runux-ai-runtime/crates/interval_arith`

**For:** programme owner. **Author:** this session (MechanicaFluidorum). **Date:** 2026-09-13.
**Scope:** the interval-arithmetic crate that the RunuX Navier–Stokes brief designates as the
foundation of the Generate-and-Verify architecture — everything the Lean judge ingests passes
through it. Read-only review plus locally-executed probes; **nothing in the RunuX tree was
modified.**

**Headline: the crate's `sqrt` violates containment on subnormal inputs, and its test suite
cannot detect the removal of the crate's entire safety mechanism.** A validated fix is given in
§4. Neither finding is visible to `cargo test`, which passes 13/13 today.

---

## 1. What the crate does, and what is right about it

`Interval{lo, hi}` over `f64`, with `+ − × ÷ √ abs scale`, each followed by `widen(1)` — one
Unit in the Last Place outward on both ends, via bit-pattern arithmetic (`ulp_widen`).

**The central design choice is the correct one and deserves saying so.** The brief calls this
"directed rounding", which suggested manipulating the FPU rounding mode — a known trap in Rust,
where there is no stable API for it, and where LLVM may constant-fold under round-to-nearest,
contract `a*b+c` into an FMA, or reassociate. The implementation does **not** do that. It
computes in the default mode and then widens outward after the fact, which is robust against all
three hazards. That is the right call, and it is what makes the rest of this review a matter of
fixable bugs rather than a wrong foundation.

For a single IEEE operation (`+ − × ÷`) the error is at most ½ ULP, so `widen(1)` is sound.
`Mul` and `Div` take the min/max over the four endpoint products, which is the standard correct
form. `Div` refuses a divisor interval containing zero. `Neg` and `abs` are exact. No complaints.

## 2. Finding 1 (soundness) — `sqrt` loses containment on subnormals

`Interval::sqrt` calls `soft_sqrt`, a Quake-style bit-hack seed
(`(bits >> 1) + 0x1FF8_0000_0000_0000`) followed by 8 Newton–Raphson steps, then widens by 1 ULP.
**The seed assumes a normalised exponent field.** Subnormals (`< 2.2250738585072014e-308`) have
exponent field zero, so the seed is wrong by orders of magnitude, and 8 Newton steps — which
merely halve the error until the quadratic regime is reached — cannot recover.

Measured by faithful replication of the algorithm (Python `float` *is* IEEE-754 `f64`; the
expression `0.5*(x + val/x)` contains no `a*b+c` pattern, so no FMA contraction can differ):

| input class | containment failures |
|---|---|
| normal, `1e-300 … 1e300` | **0 / 30 000** |
| normal, just above min-normal | **0 / 20 000** |
| **subnormal** | **60 / 20 000** |

Worst case found: `v = 8.095e-320` returns `4.370122139616469e-157` where the true root is
`2.8451311993408992e-160` — wrong by a factor of ~1500, or **4.7 × 10¹⁶ ULP**, against a 1 ULP
widening. Convergence for that input needs ~30 iterations, not 8:

```
 8 iterations -> 4.370122139616469e-157      <- what ships
12 iterations -> 2.7314247399278287e-158
20 iterations -> 2.8727367800164274e-160
30 iterations -> 2.8451311993408992e-160     <- correct
```

**Reachability.** Not demonstrated in the NS driver, and it should not be asserted without that:
the honest statement is that this is a latent unsoundness in a proof kernel. It is, however,
plausible in exactly this application — the Core–Tail construction is *about* exponentially small
tails, and `|u_k|` for large `|k|` at late time is precisely where `f64` runs into subnormals.
The fix in §4 removes the question rather than answering it.

## 3. Finding 2 (methodology) — the test suite cannot fail

All 13 shipped tests pass. They also pass with the safety mechanism **deleted**.

Every numeric constant in the suite — `1, 2, 3, 4, 5, 6, 7, 9, 12, 15, 0.5, 8` — is a dyadic
rational, on which `f64` `+ − × ÷` and the tested square roots are **exact**. The rounding path
the crate exists to protect is therefore never exercised.

Demonstrated rather than argued: the shipped arithmetic and the shipped tests were copied to a
scratch crate with `widen` replaced by the identity function, and

```
running 10 tests
..........
test result: ok. 10 passed; 0 failed
```

while on real (non-dyadic) values the same zero-widening path loses containment on
**7 468 / 30 000** inputs. **The suite cannot distinguish a working interval library from one
with no interval semantics at all.**

This is `LL.md` LL-19 in its purest form — a checker that cannot fail is not a checker — and the
remedy is this repository's standing rule: every gate ships a negative control *demonstrated* to
fail. Concretely, the crate needs (a) tests on non-dyadic inputs (`0.1`, `1/3`, `π`), (b) a
randomised containment sweep against a higher-precision reference, and (c) a test that fails when
`widen` is neutered.

## 4. Finding 3 and the fix — argument reduction, then self-certification

The obvious fix — "verify `hi*hi >= v >= lo*lo`, widen until it holds" — is the `sqrt_upper`
pattern this programme uses at Tier B, and **it does not work here as stated**: in the subnormal
range the certifying multiplication itself underflows, and it failed **3 311 / 20 000**. That is
worth recording, because it is the fix one would reach for first.

What works is argument reduction *before* rooting, so that both the iteration and the check
happen where `f64` behaves:

```
sqrt(v) = 2^-k · sqrt(v · 4^k),   k chosen so that v·4^k ∈ [1, 4]
```

Multiplication by 4 and by `2^-k` are exact (powers of two), so the reduction introduces no
error. Then root in the normal range, certify by `lo*lo <= v' <= hi*hi` widening outward until it
holds, and scale back. Measured containment of the corrected routine:

| suite | failures |
|---|---|
| normal `1e-300 … 1e300` | 0 / 30 000 |
| subnormal | 0 / 30 000 |
| deep subnormal | 0 / 10 000 |
| **every power of two, `2^-1070 … 2^1023`** | **0 / 2 094** |

**Total: 0 containment failures in 72 094 cases.** The cost is two multiplications and a loop
that almost always runs zero times.

## 5. Finding 4 (minor) — the overflow clamp breaks containment

`widen` clamps its result to `[f64::MIN, f64::MAX]` (lib.rs:78), with the comment that widening
"won't reach Inf unless already huge". When it does, clamping an upper bound of `+∞` down to
`f64::MAX` produces an interval that **does not contain** the true value. `±∞` is a soundness-
preserving bound; a clamped finite one is not. Verified: `ulp_widen(f64::MAX, +1)` is `inf`, and
the clamp then returns `f64::MAX`.

## 6. What this means for the GCP 16-vCPU phase

- **Fix the kernel before renting cores.** Every certificate the Lean judge ingests is only as
  sound as this crate. Compute spent on an unsound `sqrt` produces a certificate that is
  *verified* and *wrong* — and, per §3, verified by a suite that would not notice.
- **The local machine cannot validate the brief's performance premise.** This workstation is an
  i7-4930MX (Haswell, 2013): `avx`, `avx2`, `fma`, and **no AVX-512 of any kind**; 4 physical
  cores with hyperthreading, not 8. The brief's rule #1 is SoA layout "for AVX-512
  vectorization", which cannot be measured here at all. If AVX-512 is the point, the spot
  instance must be N2/C2/C3 (Cascade Lake or later) — a generic N1 may hand back Broadwell and
  the design will look like it failed for reasons unrelated to the design.
- **"16 vCPU" is 8 physical cores.** Against this machine's 4, the honest ceiling is ~2×, which
  matches the measured scaling of this repository's own scout (1.18× on 8 threads before
  restructuring, 2.4× after, saturating near twelve busy threads and then memory-bandwidth bound).
- **SoA/AVX-512 is right for one kernel and wrong for the other.** The `O(M⁶)` direct triadic
  convolution is compute-bound with high arithmetic intensity — wide vectors help. Any FFT-based
  path is memory-bandwidth bound, where wider vectors buy ~nothing and AVX-512 downclocking can
  make it slower. The brief states the rule unconditionally.
- **`O(M⁶)` is a committed architectural cost, and cost is the axis no gate here can see.** In
  this repository, two days ago, an optimiser was found to be `O(classes × triads)` where
  `O(triads)` sufficed — a factor of **2 846** at `M = 16` — surviving three campaigns precisely
  *because its answers were correct* (`LL.md` LL-22). Before renting cores to run an `O(M⁶)`
  kernel, the hour spent asking whether the exponent is necessary is the cheapest hour available.

## 7. Recommended order

1. Apply the §4 `sqrt` fix and the §5 clamp fix.
2. Add the three test classes of §3, including the neutered-`widen` control that must fail.
3. Re-run `cargo test -p interval_arith`; only then extend to `navier_stokes` and `cert_forge`.
4. Audit the `O(M⁶)` cost model before provisioning.
5. Pin the spot instance family if AVX-512 is load-bearing.

**Nothing in this review promotes a tier, and none of it bears on Hypothesis U.** It is an
engineering audit of a sibling stream, conducted because that stream's kernel is proposed as the
foundation of a regularity certificate. The standing cross-stream rule still applies: LeanFlow
and RunuX solve a different regularised system from this programme's sharp Galerkin truncation,
so **engineering may be leveraged and certificates may not.**
