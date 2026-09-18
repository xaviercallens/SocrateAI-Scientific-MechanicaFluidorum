# Draft: MathOverflow question on the 5/6 spectral gap

**Venue:** <https://mathoverflow.net>
**Tags:** `spectral-theory`, `integral-operators`, `fourier-analysis`, `fluid-dynamics`
**Status:** ready to paste. No blockers. Post this independently of anything else.

## Why this one stands alone

It is a real question with a clean statement, six exact data points, and an exactly solved
neighbouring case. It needs no method, no harness and no AI framing to be worth asking, and it is
worth asking whether or not any particular person ever reads it. That is the only honest reason to
post anything.

Every number below is from `docs/paper/exact_triad_structure.tex`, Open Problem on the spherical
gap. Check them against the paper before posting rather than trusting this file.

---

## The text

**Title:** Second eigenvalue of the kernel 2·1_B(x+y) + 4·1_B(x−y) on the unit ball

Let $B$ be the unit ball in $\mathbb{R}^3$ and consider the integral operator on $L^2(B)$ with
kernel

$$K(x,y) \;=\; 2\cdot\mathbf{1}_B(x+y) \;+\; 4\cdot\mathbf{1}_B(x-y).$$

**Question.** Is its second normalised eigenvalue equal to $1/6$?

The question comes from a discrete model. On the spherical truncation
$\Lambda = \{k \in \mathbb{Z}^3 : 0 < |k| \le M\}$ of the Fourier lattice, the resonant-triad
incidence matrix has a normalised spectral gap $1 - \lambda_2$ with these exact values:

| $M$ | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|
| $\lvert\Lambda\rvert$ | 32 | 122 | 256 | 514 | 924 | 1418 |
| $1-\lambda_2$ | 0.834985 | 0.833575 | 0.833419 | 0.833392 | 0.833359 | 0.833348 |

strictly decreasing toward $5/6 = 0.8333\ldots$. At $M = 7$ this is a computation over $939{,}930$
triads.

On a periodic lattice with no 2-torsion the analogous incidence structure has an exactly solvable
spectrum whose normalised gap tends to $1$, so the deviation to $5/6$ on the ball should be a pure
boundary effect of the sphere cutoff. Taking the continuum limit of the matrix gives the kernel
above, and $1 - \lambda_2 \to 5/6$ becomes $\lambda_2 = 1/6$.

I have the periodic case as a theorem and the spherical case only as data. Is the continuum
statement accessible directly? A proof, a counterexample, or a reason to expect the limit to be
something other than $5/6$ would all be useful.

---

## Notes for answering follow-ups

- **Where the operator comes from.** Two wavevectors $p, q$ in the truncation are adjacent when
  they form a resonant triad. The factor 2 and factor 4 come from the two ways a sum and a
  difference can land back inside the ball. If asked, derive it rather than asserting it.
- **Why the periodic case is easier.** Without 2-torsion the incidence structure is a Cayley graph
  and the spectrum is a character sum. The sphere has a boundary and that is the entire difficulty.
- **Do not volunteer the Lean development or the method work.** This question is not about either
  and mentioning them makes it look like a vehicle. If someone asks how the data were computed, say
  exact integer arithmetic and link the paper.
