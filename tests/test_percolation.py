#!/usr/bin/env python3
"""tests/test_percolation.py — Tier B tests for symbolic/percolation_exact.py
(PLAN.md T0.3). Plain asserts, exact integers/booleans only, deterministic,
runnable standalone with `python3 tests/test_percolation.py`.

NO PHYSICS CLAIMS: this is a correctness test suite for a generic
combinatorial instrument (periodic union-find), nothing else.
"""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "symbolic"))

from percolation_exact import Field, cluster_sizes, percolates, wraps  # noqa: E402

PASS_COUNT = 0


def check(name, cond):
    global PASS_COUNT
    assert cond, f"FAILED: {name}"
    PASS_COUNT += 1
    print(f"  ok  {name}")


# --------------------------------------------------------------------- (1)
def test_empty_field():
    print("[1] empty field")
    field = Field.empty(4)
    check("1.no_clusters", cluster_sizes(field) == [])
    check("1.percolates_false", percolates(field) is False)
    for axis in ("x", "y", "z"):
        check(f"1.wraps_{axis}_false", wraps(field, axis) is False)


# --------------------------------------------------------------------- (2)
def test_full_field():
    print("[2] full field, n=3")
    n = 3
    field = Field.full(n)
    sizes = cluster_sizes(field)
    check("2.one_cluster", sizes == [n ** 3])
    check("2.percolates_true", percolates(field) is True)
    for axis in ("x", "y", "z"):
        check(f"2.wraps_{axis}_true", wraps(field, axis) is True)


# --------------------------------------------------------------------- (3)
def test_straight_line_x():
    print("[3] straight line along x, n=5")
    n = 5
    sites = frozenset((x, 0, 0) for x in range(n))
    field = Field.from_sites(sites, n)
    check("3.one_cluster_of_n", cluster_sizes(field) == [n])
    check("3.percolates_true", percolates(field) is True)
    check("3.wraps_x_true", wraps(field, "x") is True)
    check("3.wraps_y_false", wraps(field, "y") is False)
    check("3.wraps_z_false", wraps(field, "z") is False)
    return field, n  # reused by the negative control


# --------------------------------------------------------------------- (4)
def test_2x2x2_block_in_3x3x3():
    print("[4] 2x2x2 solid block inside 3x3x3 grid")
    n = 3
    sites = frozenset(
        (x, y, z) for x in (0, 1) for y in (0, 1) for z in (0, 1)
    )
    field = Field.from_sites(sites, n)
    check("4.one_cluster_size_8", cluster_sizes(field) == [8])
    check("4.percolates_false", percolates(field) is False)
    for axis in ("x", "y", "z"):
        check(f"4.wraps_{axis}_false", wraps(field, axis) is False)


# --------------------------------------------------------------------- (5)
def test_two_isolated_sites():
    print("[5] two disjoint isolated sites")
    n = 4
    sites = frozenset({(0, 0, 0), (2, 2, 2)})
    field = Field.from_sites(sites, n)
    check("5.two_clusters_size_1", cluster_sizes(field) == [1, 1])
    check("5.percolates_false", percolates(field) is False)
    for axis in ("x", "y", "z"):
        check(f"5.wraps_{axis}_false", wraps(field, axis) is False)


# --------------------------------------------------- required negative control
def test_negative_control_broken_periodicity(line_field, n):
    """A checker that cannot fail is not a checker (PLAN.md §2). We break
    connectivity detection by disabling the periodic wrap-around on the
    x-axis (periodic=(False, True, True)) for the SAME straight-line-along-x
    field that test 3 uses, and confirm the check that test 3 makes
    (percolates along x) now comes out FALSE — i.e. the assertion test 3
    relies on would fail against this broken configuration. Then we confirm
    the correct (fully periodic, default) computation still gives True,
    i.e. restoring periodicity restores the correct result."""
    print("[NEG] negative control: drop periodic wrap-around on x-axis")

    broken = wraps(line_field, "x", periodic=(False, True, True))
    print(f"  wraps(line, 'x', periodic x-disabled) = {broken}  (expect False: BROKEN)")
    assert broken is False, (
        "negative control did not break as expected: disabling the x-axis "
        "wrap-around should make the x-wrap undetectable, but wraps() still "
        "reported True"
    )
    try:
        assert broken is True, "test-3-style assertion (percolates along x)"
        raise AssertionError("negative control failed to trigger a checker failure")
    except AssertionError as e:
        assert "test-3-style" in str(e), (
            "expected the test-3-style assertion itself to be the one that fails"
        )
        print("  confirmed: test 3's assertion (wraps along x == True) FAILS "
              "under the broken (non-periodic-x) configuration, as required")

    restored = wraps(line_field, "x")  # default periodic=(True, True, True)
    print(f"  wraps(line, 'x') restored (fully periodic) = {restored}  (expect True)")
    assert restored is True, "restoring periodicity did not restore the correct result"

    # broken config must also leave cluster count changed: severing the x
    # wrap-around edge on a line does NOT disconnect the line itself (it's
    # still a simple path 0-1-2-3-4), so cluster_sizes is unchanged; only
    # the WRAP detection (the boundary self-identification) is lost. This
    # confirms the negative control targets connectivity-across-the-
    # periodic-boundary specifically, not gross connectivity.
    check("NEG.cluster_shape_unaffected",
          cluster_sizes(line_field, periodic=(False, True, True)) == [n])
    global PASS_COUNT
    PASS_COUNT += 1
    print("  ok  NEG.broken_then_restored")


if __name__ == "__main__":
    test_empty_field()
    test_full_field()
    line_field, n = test_straight_line_x()
    test_2x2x2_block_in_3x3x3()
    test_two_isolated_sites()
    test_negative_control_broken_periodicity(line_field, n)
    print(f"\nALL {PASS_COUNT} CHECKS PASSED (negative control demonstrably fails "
          "when triggered, and the suite passes clean with periodicity restored)")
