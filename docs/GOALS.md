# GOALS.md — the goal register (living; subordinate to `PLAN.md`)

**What this is.** One page a session loads before acting: the programme's goals, each with its
status, its next falsifiable milestone, its kill criterion, and the owner decision it is waiting
on if any. It does not define tasks (that is `PLAN.md`), rules (`SPEC.md`), claims (`LEDGER.md`)
or reasons (`LL.md`). It answers the question those four do not: *what are we trying to do right
now, and what would make us stop?* Maintained by the `goal-management` skill
(`docs/harness/skill-goal-management.md`). Precedence: below `PLAN.md`; a conflict here is
resolved by `PLAN.md`, then recorded here.

**Proposed for owner decision:** `PLAN.md` §0 should list this file as the first thing a
session reads. Not edited into `PLAN.md` by the session that wrote this (normative documents go
through review).

Last refreshed: 2026-09-18, after release v1.10.2.

---

## Programme goal (unchanged since 2026-08-12)

**Hypothesis U** — for the frequency-truncated 3-D Navier–Stokes system, the enstrophy is bounded
uniformly in the cutoff. **Status: OPEN.** No verdict. Obstruction O5 (the argument must break at
$\nu = 0$) stands against every strategy tried. **Explicit non-goal:** any claim that the
Millennium problem is solved; verdicts are the owner's after external audit.

## Active goals

| ID | Goal | Status | Next falsifiable milestone | Kill criterion | Waiting on |
|---|---|---|---|---|---|
| G-CT | **Core–Tail computer-assisted proof**: an interval certificate on the core $|k| \le M_{\text{core}} \le 8$ plus a self-consistent Gevrey tail envelope | Blocked on the self-consistency closure. The certificate's arithmetic exists (Tier B, `tests/tier_b_core_forcing_bound.py`, 32 ms at $M_{\text{core}} = 8$); the closure does not | Owner adopts T-2′ (E-1); a first closure attempt on one explicit envelope, reported as a number that either closes or does not | The forcing bound's factor 2–3 loss makes every envelope fail to close at every $M_{\text{core}} \le 8$ | **Owner: adopt T-2′** (proposed 2026-09-13) |
| G-S | **Adversarial transient series** $Z_{\max}/Z_0$ at $M = 2..64$ | Closed through $M = 64$ (S-5), both float and exact records certified; growing, decelerating, not turned over | $M = 128$ only if a fresh cost model says it is affordable and a pre-registered bracket can discriminate | Two more points inside a decelerating trend with no turnover would not change any decision → do not spend | **Owner: is $M = 128$ worth pursuing?** |
| G-D2 | **Door #2** (leave the Riccati route; positivity audit of Cheskidov §5) | Paused since 2026-08-25 | Owner answers the three questions in `DOOR2_MEMO_SIGN_AUDIT.md` §7 | Answer to Q3 closes the door on paper | **Owner: three decisions** |
| G-56 | **The 5/6 spherical-gap conjecture** | Half proved (gap $\le 5/6$ with an explicit witness); six exact points $M = 2..7$ | Prove $1/2$ is the largest odd eigenvalue (`BALL_SPECTRAL_PROBLEM.md` §5), or compute the continuum kernel's second eigenvalue | A seventh exact point that breaks monotonicity | — |
| G-PUB | **Publications** | Triad paper archived (10.5281/zenodo.22823607); methodology paper v2 archived (10.5281/zenodo.22829767, all versions 10.5281/zenodo.22827933); report publication-ready at v1.10.0 | Any new claim → `manuscript-auditor` → `publish-gate` | A published sentence found false → tombstone via new version, never silent edit | — |
| G-M | **The method** (tiers, controls, pre-registration, ledger, harness) | 36 lessons; 6 skills + 2 agents proposed in `docs/harness/`; none installed | Owner installs the harness; the neuro-symbolic harness memo's first milestone (`docs/designs/NEURO_SYMBOLIC_HARNESS.md` §7) | A proposed hook with a false-positive rate on the clean commit history above the memo's threshold is dropped | **Owner: install `docs/harness/`** |

## Standing owner decisions (none urgent, all blocking something)

1. **T-2′ adoption** (E-1) — unblocks G-CT.
2. **Door #2**: validate/reject the sign audit; authorise observables O1/O2; rule on the
   $|u_n u_{n+1}|$ cross-term question — unblocks G-D2.
3. **$M = 128$** — settles G-S.
4. **Merge `concurrent-stream`** only after its own two gates pass there (D-4).
5. **Install `docs/harness/`** into `.claude/` — the session may not (LL-23).
6. **Rotate the Zenodo token** pasted into the 2026-09-18 transcript.

## Recently closed (for the record; details in `LEDGER.md`)

- S-5 at $M = 64$: float 1.043082 inside the registered bracket [1.041, 1.047]; exact
  $S(\sigma) = 13\,477\,832\,078\,223\,027\,252\,042\,752$, zero polish flips (2026-09-17).
- Six mechanisms proposed and six killed (phase mixing, frustration index, Beltrami shield,
  Sym² lock, radial embedding, planar confinement).
- Report review: 8 blocking + ~30 substantive findings applied; counting convention stated.

## How to update this file

Every session that changes a status, closes a milestone, or receives an owner decision edits the
relevant row **in the same commit** as the artefact, and bumps "Last refreshed". Never add a goal
without a kill criterion; a goal that cannot be stopped is a slogan (the sister laboratory's
phrase for a lock without a test).
