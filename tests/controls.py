#!/usr/bin/env python3
"""Shared control primitives for Tier B/C harnesses — the mechanical half of SPEC §7.3.

WHY THIS EXISTS. Six of this repository's lessons are about controls, and by 2026-08-25 they
had a shape: the control is necessary and not sufficient, because it can pass or fail for
reasons unrelated to what it was built to test (LL.md's synthesis table). Prose rules did not
prevent the recurrence — LL-6 ("verify literature before citing") was already in force when a
threshold was taken from an abstract and shipped inside a gate's own positive control (LL-16).
So the rules that CAN be mechanised are mechanised here, and harnesses import them instead of
re-implementing the discipline each time.

Four primitives, one per failure mode in the synthesis table:

  require_hypothesis(...)   LL-17: a theorem-backed control is void if the RUN violates the
                            theorem's hypotheses. Enforce them at runtime; refuse to run.
  StopReason                LL-18: distinct termination causes get distinct names, and an
                            aggregate containing a bookkeeping stop refuses to be interpreted.
  demonstrated_negative(..) LL-19: a negative control's perturbation is a CLAIM. This runs it
                            and asserts it actually fails, so an inert perturbation is caught.
  cite_threshold(...)       LL-16: a literature constant must carry its source AND the
                            hypotheses that scope it, at the point of definition.

Self-tested: running this file exercises every primitive in both directions.
"""

from __future__ import annotations

import sys
from dataclasses import dataclass, field


class ControlViolation(Exception):
    """Raised when a harness may not proceed. Always fatal: never caught to 'continue anyway'."""


# ---------------------------------------------------------------- LL-17: hypothesis guards
def require_hypothesis(condition: bool, statement: str, detail: str = "") -> None:
    """Refuse to run when the run violates a hypothesis the controls depend on.

    Example (the incident that motivated it): a probe seeded with u_n = A*2^{-beta n} has finite
    enstrophy only for beta > alpha. Run with beta <= alpha and the theorem-backed positive
    control fails — not because the code is wrong, but because u_0 is not in V. The guard turns
    a confusing failure into a refusal that names the cause.
    """
    if not condition:
        raise ControlViolation(
            f"HYPOTHESIS VIOLATED: {statement}"
            + (f"\n  {detail}" if detail else "")
            + "\n  The controls below are void under this violation; refusing to run (LL-17)."
        )


# ---------------------------------------------------------------- LL-18: stop reasons
class StopReason:
    """Distinct names for terminations that mean opposite things.

    PHYSICAL   the observable genuinely diverged / the guard fired  -> a finding
    BUDGET     the integrator ran out of steps or wall time         -> NOT a finding
    COMPLETE   ran to the requested end                             -> a finding
    """

    COMPLETE = "ok"
    PHYSICAL = "GUARD(magnitude)"
    BUDGET = "CAP(compute budget)"

    @staticmethod
    def is_budget(reason: str) -> bool:
        return reason == StopReason.BUDGET


@dataclass
class Aggregate:
    """A block of runs that refuses to be read when any member stopped for budget reasons."""

    label: str
    reasons: list = field(default_factory=list)

    def record(self, reason: str) -> None:
        self.reasons.append(reason)

    @property
    def admissible(self) -> bool:
        return not any(StopReason.is_budget(r) for r in self.reasons)

    def verdict_banner(self) -> str:
        if self.admissible:
            return f"[{self.label}] admissible"
        return (
            f"[{self.label}] *** NO READING OF THIS BLOCK IS ADMISSIBLE: "
            f"{sum(StopReason.is_budget(r) for r in self.reasons)} run(s) hit the compute "
            f"budget. Shrinking horizons here mean the computation ran out, not that anything "
            f"diverged (LL-18). ***"
        )


# ---------------------------------------------------------------- LL-19: demonstrated negatives
def demonstrated_negative(name: str, run, expect_failure_of) -> bool:
    """Run a perturbed case and ASSERT it fails the property under test.

    `run` returns the perturbed result; `expect_failure_of(result)` must be False, i.e. the
    property must NOT hold on the perturbation. A perturbation that leaves the property intact
    is an inert control and is reported as such rather than passing silently.

    Motivating incident (LL-19): perturbing an exponent looked destructive and was not — it only
    moved the conserved weights. The genuinely destructive perturbation had to change the index
    structure.
    """
    result = run()
    still_holds = expect_failure_of(result)
    if still_holds:
        print(
            f"   NEGATIVE CONTROL '{name}': *** INERT — the perturbation did NOT destroy the "
            f"property, so this control cannot fail and proves nothing (LL-19). Either prove "
            f"the perturbation is destructive or replace it. ***"
        )
        return False
    print(f"   NEGATIVE CONTROL '{name}': OK (fires — the property genuinely fails)")
    return True


# ---------------------------------------------------------------- LL-16: sourced thresholds
@dataclass(frozen=True)
class Threshold:
    """A literature constant that carries its provenance and its scope at the point of use.

    A threshold quoted without its hypotheses is a DIFFERENT claim from the theorem it came
    from. `alpha >= 2/5 is regular` is true for positive data and unproven otherwise; storing
    the number alone is how a wrong band ended up inside a gate's own positive control (LL-16).
    """

    value: object
    source: str          # theorem number + paper, never "the abstract of"
    hypotheses: str      # what must hold for the number to apply

    def __post_init__(self):
        if not self.source or not self.hypotheses:
            raise ControlViolation(
                "A literature threshold must carry BOTH its source (theorem, not abstract) and "
                "the hypotheses that scope it (LL-16)."
            )

    def describe(self) -> str:
        return f"{self.value}  [{self.source}; applies when: {self.hypotheses}]"


def cite_threshold(value, source: str, hypotheses: str) -> Threshold:
    return Threshold(value=value, source=source, hypotheses=hypotheses)


# ---------------------------------------------------------------- self-test
def _self_test() -> int:
    print("== controls.py self-test (each primitive exercised in BOTH directions) ==\n")
    ok = True

    print("LL-17 require_hypothesis:")
    try:
        require_hypothesis(True, "beta > alpha")
        print("   satisfied hypothesis: proceeds   OK")
    except ControlViolation:
        print("   *** FAILED: refused a satisfied hypothesis ***"); ok = False
    try:
        require_hypothesis(False, "beta > alpha", "beta=0.7, alpha=1.0")
        print("   *** FAILED: proceeded under a violated hypothesis ***"); ok = False
    except ControlViolation:
        print("   violated hypothesis: refuses      OK")

    print("\nLL-18 StopReason / Aggregate:")
    a = Aggregate("clean block")
    a.record(StopReason.COMPLETE); a.record(StopReason.PHYSICAL)
    good = a.admissible
    print(f"   complete + physical stops -> admissible={a.admissible}   {'OK' if good else '*** FAILED ***'}")
    ok &= good
    b = Aggregate("capped block")
    b.record(StopReason.COMPLETE); b.record(StopReason.BUDGET)
    good = not b.admissible
    print(f"   any budget stop           -> admissible={b.admissible}   {'OK' if good else '*** FAILED ***'}")
    ok &= good

    print("\nLL-19 demonstrated_negative:")
    # a genuinely destructive perturbation: property "x == 0" broken by returning 1
    good = demonstrated_negative("destructive", lambda: 1, lambda r: r == 0)
    ok &= good
    # an inert perturbation: property survives, must be reported as inert
    inert = demonstrated_negative("inert", lambda: 0, lambda r: r == 0)
    good = not inert
    print(f"   inert perturbation correctly rejected   {'OK' if good else '*** FAILED ***'}")
    ok &= good

    print("\nLL-16 cite_threshold:")
    t = cite_threshold("2/5", "Barbato-Morandin-Romito, Nonlinearity 24 (2011) Thm A",
                       "positive initial data x_n >= 0 in l^2")
    print(f"   sourced threshold: {t.describe()}   OK")
    try:
        cite_threshold("2/5", "", "")
        print("   *** FAILED: accepted an unsourced threshold ***"); ok = False
    except ControlViolation:
        print("   unsourced threshold: refused      OK")

    print("\nSELF-TEST: PASS" if ok else "\nSELF-TEST: *** FAILED ***")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(_self_test())
