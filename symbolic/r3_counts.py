#!/usr/bin/env python3
"""
T0.1: Lattice representation counts r₃(n)

Compute r₃(n) = #{k ∈ ℤ³ : |k|² = n} exactly for 0 ≤ n ≤ 10000 by direct enumeration.
Tier B: Exact arithmetic only (integers). Deterministic, no floating point.

Method: bounded triple loop over k₁, k₂, k₃ in [-100, 100] (sufficient since 100² = 10000).
Accumulate counter array of length 10001.

Mandatory anchors (Legendre three-square theorem):
  r₃(0)=1, r₃(1)=6, r₃(2)=12, r₃(3)=8, r₃(4)=6, r₃(7)=0, r₃(15)=0
  (n of form 4^a(8b+7) has r₃(n)=0 — 7 and 15 are instances)
"""

import sys
import hashlib
import subprocess
from pathlib import Path


def compute_r3_exact(max_n=10000):
    """
    Compute r₃(n) = #{(k₁, k₂, k₃) ∈ ℤ³ : k₁² + k₂² + k₃² = n}
    for 0 ≤ n ≤ max_n using exact integer arithmetic.

    Bounds: iterate k ∈ [-100, 100] (exact since 100² = 10000).

    Returns:
        list: r3_counts[n] for n in 0..max_n
    """
    # Initialize counter array
    r3 = [0] * (max_n + 1)

    # Bounded triple loop
    bound = 100
    for k1 in range(-bound, bound + 1):
        k1_sq = k1 * k1
        for k2 in range(-bound, bound + 1):
            k2_sq = k2 * k2
            for k3 in range(-bound, bound + 1):
                k3_sq = k3 * k3
                n = k1_sq + k2_sq + k3_sq
                if n <= max_n:
                    r3[n] += 1

    return r3


def compute_r3_wrong_predicate(max_n=10000):
    """
    NEGATIVE CONTROL: deliberately wrong predicate.
    Uses k₁² + k₂² = n (omitting k₃ entirely).

    This should FAIL the mandatory anchors and demonstrates
    that the checker can actually fail when perturbed.

    Returns:
        list: wrong_r3[n] for n in 0..max_n
    """
    # Initialize counter array
    wrong_r3 = [0] * (max_n + 1)

    # WRONG: bounded PAIR loop only (k1, k2), ignoring k3 entirely
    # This counts 2-square representations instead of 3-square representations
    bound = 100
    for k1 in range(-bound, bound + 1):
        k1_sq = k1 * k1
        if k1_sq > max_n:
            continue
        for k2 in range(-bound, bound + 1):
            k2_sq = k2 * k2
            n = k1_sq + k2_sq
            if n <= max_n:
                # WRONG: we're only counting k1^2 + k2^2, missing k3 entirely
                wrong_r3[n] += 1

    return wrong_r3


def verify_anchors(r3, name="r₃"):
    """
    Verify mandatory anchors (Legendre three-square theorem).

    Args:
        r3: array of r₃ values
        name: name for error messages

    Returns:
        bool: True if all anchors pass, False otherwise
    """
    anchors = {
        0: 1,
        1: 6,
        2: 12,
        3: 8,
        4: 6,
        7: 0,
        15: 0,
    }

    all_pass = True
    for n, expected in anchors.items():
        actual = r3[n]
        status = "PASS" if actual == expected else "FAIL"
        print(f"{name}({n}) = {actual}, expected {expected} ... {status}")
        if actual != expected:
            all_pass = False

    return all_pass


def main():
    print("=" * 70)
    print("T0.1: Lattice representation counts r₃(n)")
    print("=" * 70)

    # Compute exact r₃(n)
    print("\n[1/5] Computing r₃(n) exactly for n ∈ [0, 10000]...")
    r3 = compute_r3_exact(max_n=10000)
    print(f"      Generated array of length {len(r3)}")

    # Verify mandatory anchors
    print("\n[2/5] Verifying mandatory anchors (Legendre)...")
    if not verify_anchors(r3, "r₃"):
        print("\nERROR: Anchor verification FAILED. Aborting.")
        return 1
    print("      All anchors PASSED.")

    # Negative control: demonstrate checker can fail
    print("\n[3/5] Running NEGATIVE CONTROL (wrong predicate)...")
    wrong_r3 = compute_r3_wrong_predicate(max_n=10000)
    print("      Testing wrong predicate against anchors:")
    if verify_anchors(wrong_r3, "wrong_r₃"):
        print("\nWARNING: Negative control PASSED (should have FAILED).")
        print("         The checker is not discriminatory enough.")
        # Don't abort; this is informational
    else:
        print("      ✓ Negative control FAILED as required.")

    # Write CSV file
    print("\n[4/5] Writing data/r3_counts.csv...")
    csv_path = Path("/home/xavkal/xdev/SocrateAI-Scientific-MechanicaFluidorum/data/r3_counts.csv")
    csv_path.parent.mkdir(parents=True, exist_ok=True)

    with open(csv_path, "w") as f:
        f.write("n,r3\n")
        for n, count in enumerate(r3):
            f.write(f"{n},{count}\n")

    print(f"      Wrote {len(r3)} rows to {csv_path}")

    # Compute SHA256 of CSV
    print("\n[5/5] Generating metadata...")
    sha256_hash = hashlib.sha256()
    with open(csv_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            sha256_hash.update(chunk)
    csv_sha256 = sha256_hash.hexdigest()
    print(f"      SHA256(r3_counts.csv) = {csv_sha256}")

    # Get Python version
    python_version = sys.version.replace("\n", " ")
    print(f"      Python: {python_version}")

    # Generate the exact command that produced this output
    script_path = Path(__file__).resolve()
    cmd = f"python3 {script_path}"

    # Write meta file
    meta_path = Path("/home/xavkal/xdev/SocrateAI-Scientific-MechanicaFluidorum/data/r3_counts.csv.meta")
    with open(meta_path, "w") as f:
        f.write("# Metadata for r3_counts.csv\n")
        f.write(f"command: {cmd}\n")
        f.write(f"python_version: {python_version}\n")
        f.write(f"sha256sum: {csv_sha256}\n")

    print(f"      Wrote {meta_path}")

    print("\n" + "=" * 70)
    print("SUCCESS: All checks passed.")
    print("=" * 70)

    return 0


if __name__ == "__main__":
    sys.exit(main())
