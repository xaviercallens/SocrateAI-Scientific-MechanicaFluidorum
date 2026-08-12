#!/usr/bin/env python3
"""
T0.2 — Unconstrained triad-count baseline.
Exact count of triads k₁ + k₂ = k₃ in the integer lattice.
All vectors in ℤ³; |kᵢ|² ≤ M² for each i.
Uses integers only (no floating point).
Includes negative control: independent recount for M=2 with naive triple loop.
"""

import sys

def get_ball_points(M_sq):
    """Return list of all vectors k in Z^3 with |k|^2 <= M_sq."""
    points = []
    M_bound = int(M_sq**0.5) + 1
    for k1 in range(-M_bound, M_bound + 1):
        for k2 in range(-M_bound, M_bound + 1):
            for k3 in range(-M_bound, M_bound + 1):
                if k1*k1 + k2*k2 + k3*k3 <= M_sq:
                    points.append((k1, k2, k3))
    return points

def ball_size(M_sq):
    """Count vectors k in Z^3 with |k|^2 <= M_sq."""
    return len(get_ball_points(M_sq))

def norm_sq(k):
    """Compute |k|^2 for a vector k."""
    return k[0]*k[0] + k[1]*k[1] + k[2]*k[2]

def count_triads_efficient(M_sq):
    """
    Count triads (k1, k2, k3) in (Z^3)^3 with:
    - k1 + k2 = k3
    - |k1|^2 <= M_sq, |k2|^2 <= M_sq, |k3|^2 <= M_sq

    Method: enumerate k1 and k3 over the ball; set k2 = k3 - k1; test |k2|^2 <= M_sq.
    """
    ball = get_ball_points(M_sq)
    count = 0
    for k1 in ball:
        for k3 in ball:
            k2 = (k3[0] - k1[0], k3[1] - k1[1], k3[2] - k1[2])
            if norm_sq(k2) <= M_sq:
                count += 1
    return count

def count_triads_naive_triple_loop(M_sq):
    """
    Naive count: loop over (k1, k2) over the ball; compute k3 = k1 + k2; test all norms.
    Used for negative control on M=2.
    """
    ball = get_ball_points(M_sq)
    count = 0
    for k1 in ball:
        for k2 in ball:
            k3 = (k1[0] + k2[0], k1[1] + k2[1], k1[2] + k2[2])
            if norm_sq(k3) <= M_sq:
                count += 1
    return count

def count_triads_broken(M_sq):
    """
    Deliberately broken version for negative control.
    Uses < instead of <= in the M_sq constraint, which will give wrong results.
    """
    ball = get_ball_points(M_sq)
    count = 0
    for k1 in ball:
        for k3 in ball:
            k2 = (k3[0] - k1[0], k3[1] - k1[1], k3[2] - k1[2])
            if norm_sq(k2) < M_sq:  # BROKEN: using < instead of <=
                count += 1
    return count

def main():
    """Main computation and validation."""
    M_values = [2, 4, 8, 16]
    results = []

    print("Computing triads for M values: 2, 4, 8, 16")
    print()

    # For each M, compute using efficient method
    for M in M_values:
        M_sq = M * M
        b_size = ball_size(M_sq)
        triad_count = count_triads_efficient(M_sq)
        results.append((M, b_size, triad_count))
        print(f"M={M}: ball_size={b_size}, triad_count={triad_count}")

    # NEGATIVE CONTROL for M=2
    print()
    print("=" * 60)
    print("NEGATIVE CONTROL (M=2)")
    print("=" * 60)
    M = 2
    M_sq = M * M

    # Compare efficient vs naive triple loop
    efficient = count_triads_efficient(M_sq)
    naive = count_triads_naive_triple_loop(M_sq)
    print(f"M=2 efficient method (loop k1, k3; set k2): {efficient}")
    print(f"M=2 naive triple loop (loop k1, k2; compute k3): {naive}")
    print()

    if efficient == naive:
        print("✓ PASS: Both methods agree!")
    else:
        print("✗ FAIL: Methods disagree!")
        sys.exit(1)

    print()

    # Deliberately break one method and show it fails
    broken = count_triads_broken(M_sq)
    print(f"M=2 broken method (using < instead of <=): {broken}")
    print()

    if broken != efficient:
        print("✓ PASS: Broken method produces DIFFERENT result (as required)!")
        print(f"      Difference: {efficient} vs {broken} = {efficient - broken} triads excluded")
    else:
        print("✗ FAIL: Broken method still agrees - negative control failed!")
        sys.exit(1)

    print()
    print("=" * 60)
    print("Writing output CSV")
    print("=" * 60)

    # Write CSV output
    csv_path = "data/triads_free.csv"
    with open(csv_path, "w") as f:
        f.write("M,ball_size,triad_count\n")
        for M, b_size, triad_count in results:
            f.write(f"{M},{b_size},{triad_count}\n")

    print(f"✓ Data written to {csv_path}")
    print()
    print("CSV contents:")
    with open(csv_path, "r") as f:
        print(f.read())

if __name__ == "__main__":
    main()
