---
name: cost-model
description: State a computation's cost model in O(·) and its memory in counted bytes, and check the measured scaling against it, BEFORE scaling that computation to a new size or asking for hardware. Use when raising M (or any size parameter) on a scout, harness, or optimiser; when a job is taking longer than expected; when writing or believing a risk declaration about memory or runtime; and always before proposing a cloud VM. A superlinear surprise is a defect to find, not a budget line to fund.
---

# Cost-model it before you scale it, and before you buy a machine

Both gates in this repository check whether an answer is **right**. Neither can see that it cost
2846× more than necessary, and **a correct answer is the most effective possible camouflage for a
bad algorithm** (`LL.md` LL-22). Neither can see that a declared memory figure was 6.6× optimistic
either, because the failing run has not happened yet (LL-21). This skill is the audit those gates
cannot perform.

## 1. Count the quantities — never estimate them

Write down every quantity the cost depends on, as an **exact count** obtained by computation, not
by a mental order of magnitude. Cheap ways to count without running the thing:

- lattice/ball sizes: enumerate, or use an exact volume argument;
- pair or triad counts: **FFT autocorrelation of the indicator** is exact and takes seconds where
  the double loop takes minutes (this is how the `1.367 × 10⁸` triad count was obtained);
- loop trip counts: derive them; do not infer them from a wall-clock reading.

Record the counts in the memo. "Order 10⁸" is not a count.

## 2. Convert to bytes with an explicit `sizeof`

This is the step LL-21 skipped. For every array, write:

```
entries × sizeof(element) = bytes
```

and spell out `sizeof(element)` from the actual declared type, **including padding**. The failure
case: `(K, K, K, i64)` where `K = [i64; 3]` is not 24 bytes but 80, so `1.37e8` entries is
10.2 GB, not the declared 3 GB.

Then find every **transient** that stands at the same time as the main array:

- a `flat_map` before its `dedup` materialises the whole un-deduplicated list (this was a second
  9.8 GB in LL-21);
- `Vec` growth doubles, briefly holding two copies — `with_capacity(exact_count)` removes it;
- an index-form copy built from a wavevector-form original holds **both** until the original is
  dropped.

**Peak, not steady state, is the number that decides whether the run survives.** Compare it
against measured free memory (`free -g`), not total.

## 3. State the cost model in O(·), then look for the algorithmic win

Write the per-iteration cost as a formula in the counted quantities. Then ask the question that
was never asked for three campaigns: **does each step need to touch everything?**

The canonical win, and the one this repository has already paid for: an objective evaluated over
a large table, perturbed one variable at a time, does **not** need re-summing. Maintain the total
and update it by the delta:

```
S ↦ S − 2 · (sum of the terms that actually change)
```

reducing `O(variables × terms)` to `O(terms)`. Watch the multiplicity subtlety that makes it
correct: a variable appearing an **even** number of times in a term leaves that term fixed, since
`(−1)² = 1`. Restrict to odd incidence.

Second canonical win: if the table is only ever read per-variable, **do not store it** — enumerate
each variable's terms from the underlying structure on the fly. Memory goes to zero and the cost
model often improves too. This is what turns `M = 32` from "195 GB, 108 days" into "no memory,
1–2 hours".

## 4. Verify any optimisation as a refactor, never as an argument

A cost change that alters the answer is not an optimisation. Hold it to the standard that caught
nothing and proved everything in this cycle:

- **Reproduce an archived artifact byte for byte** — re-run a committed CSV, `diff` it.
- **Reproduce intermediate state, not just the final answer** — the sweep-by-sweep objective
  values, matched digit for digit. Keep the slow run alive alongside the fast one for exactly
  this comparison; the old job is the reference and costs nothing extra once it is already going.
- Flag any arithmetic change that is *not* semantics-preserving (an `i64` → `i128` accumulator,
  say) and state why it cannot alter an archived result.

## 5. Report the measured factor, never the operation-count ratio

LL-18 and LL-22 both. The operation count promised 2846×; the measurement gave ~12× under
contention, because random gathers into a multi-GB table are far less efficient per byte than the
sequential scan they replaced. **Quote what the clock said, name the contention, and keep the
theoretical factor clearly labelled as theoretical.**

Then check the measured scaling against the model from step 3. Disagreement means the model is
wrong, and the model being wrong is the finding.

## 6. Only now, the hardware question

Answer these in order; stop at the first "no".

1. Is the cost model **linear-or-better in the size parameter**, after step 3? If not, fix the
   algorithm — do not rent a machine to run a quadratic. *This is the first failure here that a
   rented machine would have concealed rather than exposed.*
2. Does the workload actually **scale with cores**? Measure it. The scout's honest figure is
   1.18× on eight threads before restructuring and ~2.4× after, saturating near twelve busy
   threads and then memory-bandwidth bound — so 16 vCPU is the right shape and 64 vCPU
   quadruples the bill for almost nothing.
3. Is the point being computed **decision-relevant**? Run the `preregister` discrimination check.
   Extending an uninformative null series is not worth VM-hours.
4. Only then: quote a duration and a cost, say "confirm current pricing before provisioning",
   and bring it to the owner as an ask rather than provisioning it.

## Definition of done

- [ ] Every quantity counted exactly, by computation, with the method named.
- [ ] Bytes computed from explicit `sizeof`, padding included; every concurrent transient found.
- [ ] **Peak** memory compared against measured free memory.
- [ ] Cost model written in O(·); the "must each step touch everything?" question asked.
- [ ] Any optimisation verified bit-for-bit against an archived artifact **and** on intermediate
      state.
- [ ] Measured factor reported with contention named; theoretical factor labelled theoretical.
- [ ] Measured scaling checked against the model.
- [ ] Hardware asked for only after steps 1–3 of §6 pass.
