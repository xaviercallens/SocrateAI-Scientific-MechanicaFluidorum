#!/usr/bin/env python3
"""symbolic/percolation_exact.py — Tier B exact 3-D site-percolation instrument.

PLAN.md task T0.3. This is a *generic combinatorial instrument*: union-find
cluster labelling with 6-neighbour connectivity, periodic in all three axes,
over a *given* boolean occupancy field on an n x n x n grid (n <= 16).

NO PHYSICS CLAIMS. This module makes no statement about any percolation
threshold, critical exponent, physical model, or the Navier-Stokes /
Katz-Pavlović program. It is ready-instrument tooling for track T4, which
remains BLOCKED-ON-DEFINITION (OP-5, PLAN.md §6) until the coupling of the
percolation field to Sym^2 is authored and audited. Until then this module
only ever operates on fields supplied explicitly by the caller.

Arithmetic discipline (SPEC/PLAN Tier B): every value here is a Python
`int` or `bool`. No floats, no probabilities, no randomness, no clock reads.

--------------------------------------------------------------------------
Algorithm (periodic wrap detection via the "universal cover" trick)
--------------------------------------------------------------------------
Represent the occupied sites as vertices of a graph with an edge between
every pair of 6-neighbours on the periodic n x n x n torus. A cluster
"wraps" along an axis iff, when the torus is unrolled to its universal
cover Z^3 (i.e. positions are tracked as unbounded integer vectors rather
than reduced mod n), the cluster's own connectivity forces two *different*
integer vectors to be identified with the same grid site — equivalently,
the cluster is invariant under a nonzero lattice translation with a
nonzero component along that axis.

This is tracked with a union-find over the occupied sites in which every
node additionally carries an integer displacement-vector *offset* to its
parent, maintained so that for every site s,

    vpos(s) = vpos(root(s)) + cumulative_offset(s)

where vpos(root) is fixed, arbitrarily, to root's own grid coordinate at
the moment it becomes a root of its own tree (i.e. the very first virtual
position ever assigned along that tree, taken literally, never reduced
mod n). Every graph edge (s, s + delta) with delta in
{(1,0,0),(0,1,0),(0,0,1)} — using the ACTUAL periodic-wrapped grid
neighbour for connectivity, but the literal small integer `delta` for the
implied unwrapped displacement — is processed once. Two cases arise:

  * s and t are in different trees: union them, choosing the new offset so
    that vpos(t) = vpos(s) + delta holds exactly (no wrap discovered yet).
  * s and t are already in the same tree: the tree already implies a
    displacement vpos(t) - vpos(s) = off_t - off_s ("path 1"). The direct
    edge implies vpos(t) - vpos(s) = delta ("path 2"). If these two paths
    disagree, the disagreement vector is exactly the nonzero lattice
    translation under which this cluster maps to itself — i.e. a wrap.
    A component of that vector along axis i is nonzero iff the cluster
    wraps along axis i.

`percolates(field)` is `wraps` along any of the three axes.
"""

from dataclasses import dataclass
from typing import Dict, FrozenSet, List, Sequence, Tuple, Union

Site = Tuple[int, int, int]
Vec3 = Tuple[int, int, int]

# The three "positive" unit steps. Because the graph is undirected and the
# torus is periodic, iterating every occupied site and taking only these
# three directions (with grid-wrapped targets) visits every edge exactly
# once — the edge that would be found from the wrapped-around ("negative")
# side is the very same edge found here from its other endpoint.
_POS_DELTAS: Tuple[Vec3, Vec3, Vec3] = ((1, 0, 0), (0, 1, 0), (0, 0, 1))
_DELTA_AXIS: Dict[Vec3, int] = {(1, 0, 0): 0, (0, 1, 0): 1, (0, 0, 1): 2}

_AXIS_INDEX = {"x": 0, "y": 1, "z": 2, 0: 0, 1: 1, 2: 2}


def _axis_index(axis) -> int:
    if axis not in _AXIS_INDEX:
        raise ValueError(f"axis must be one of 'x','y','z',0,1,2 — got {axis!r}")
    return _AXIS_INDEX[axis]


def _add(a: Vec3, b: Vec3) -> Vec3:
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def _sub(a: Vec3, b: Vec3) -> Vec3:
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


ZERO3: Vec3 = (0, 0, 0)


# --------------------------------------------------------------- Field type
@dataclass(frozen=True)
class Field:
    """An occupancy field on a periodic n x n x n grid.

    Canonical representation is `sites`: a frozenset of occupied
    (x, y, z) integer triples with 0 <= coord < n. Construct via
    `Field.from_array` (nested boolean list, arr[x][y][z]) or
    `Field.from_sites` (explicit set/iterable of triples).
    """

    n: int
    sites: FrozenSet[Site]

    @staticmethod
    def from_array(arr: Sequence[Sequence[Sequence[object]]]) -> "Field":
        n = len(arr)
        if not (1 <= n <= 16):
            raise ValueError(f"grid size n must satisfy 1 <= n <= 16, got {n}")
        sites = set()
        for x in range(n):
            row = arr[x]
            if len(row) != n:
                raise ValueError("array is not n x n x n (x-slice wrong length)")
            for y in range(n):
                col = row[y]
                if len(col) != n:
                    raise ValueError("array is not n x n x n (y-slice wrong length)")
                for z in range(n):
                    if col[z]:
                        sites.add((x, y, z))
        return Field(n=n, sites=frozenset(sites))

    @staticmethod
    def from_sites(sites: Union[Sequence[Site], FrozenSet[Site]], n: int) -> "Field":
        if not (1 <= n <= 16):
            raise ValueError(f"grid size n must satisfy 1 <= n <= 16, got {n}")
        sites = frozenset(sites)
        for (x, y, z) in sites:
            if not (0 <= x < n and 0 <= y < n and 0 <= z < n):
                raise ValueError(f"site {(x, y, z)} out of range for n={n}")
        return Field(n=n, sites=sites)

    @staticmethod
    def empty(n: int) -> "Field":
        return Field.from_sites(frozenset(), n)

    @staticmethod
    def full(n: int) -> "Field":
        sites = frozenset(
            (x, y, z) for x in range(n) for y in range(n) for z in range(n)
        )
        return Field.from_sites(sites, n)


# --------------------------------------------------------- Union-find core
class _UnionFindOffsets:
    """Union-find with path compression + union by rank over a fixed set of
    sites, each node carrying an integer Z^3 displacement offset to its
    parent (see module docstring)."""

    __slots__ = ("parent", "rank", "offset")

    def __init__(self, sites) -> None:
        self.parent: Dict[Site, Site] = {s: s for s in sites}
        self.rank: Dict[Site, int] = {s: 0 for s in sites}
        self.offset: Dict[Site, Vec3] = {s: ZERO3 for s in sites}  # to parent

    def find(self, s: Site) -> Tuple[Site, Vec3]:
        """Returns (root, off) with vpos(s) = vpos(root) + off. Recursive
        path compression: every visited node ends up pointing straight at
        the root with its offset updated to match."""
        p = self.parent[s]
        if p == s:
            return s, ZERO3
        root, off_p_to_root = self.find(p)
        total = _add(self.offset[s], off_p_to_root)
        self.parent[s] = root
        self.offset[s] = total
        return root, total

    def union(self, s: Site, t: Site, delta: Vec3):
        """s, t are occupied sites joined by a direct lattice edge whose
        *unwrapped* displacement is `delta` (vpos(t) - vpos(s) = delta).
        Returns the nonzero loop-closure vector if s, t were already
        connected inconsistently with `delta` (a periodic wrap), else None.
        """
        root_s, off_s = self.find(s)  # vpos(s) = vpos(root_s) + off_s
        root_t, off_t = self.find(t)  # vpos(t) = vpos(root_t) + off_t

        if root_s == root_t:
            existing = _sub(off_t, off_s)  # tree's own vpos(t) - vpos(s)
            loop = _sub(existing, delta)
            return loop if loop != ZERO3 else None

        # vpos(root_t) must satisfy vpos(root_t) = vpos(root_s) + off_s + delta - off_t
        if self.rank[root_s] >= self.rank[root_t]:
            self.parent[root_t] = root_s
            self.offset[root_t] = _sub(_add(off_s, delta), off_t)
            if self.rank[root_s] == self.rank[root_t]:
                self.rank[root_s] += 1
        else:
            self.parent[root_s] = root_t
            self.offset[root_s] = _sub(_sub(off_t, off_s), delta)
        return None


def _build(field: Field, periodic: Tuple[bool, bool, bool] = (True, True, True)):
    """Builds the union-find over field.sites and returns (uf, loop_vectors).

    `periodic` toggles wraparound per axis independently — default is fully
    periodic (True, True, True), matching the spec. Setting a component to
    False severs connectivity across that axis's boundary; this exists
    only to drive the required negative control (see tests/test_percolation.py)
    and must never be relied on for the primary (fully periodic) checks.
    """
    n = field.n
    uf = _UnionFindOffsets(field.sites)
    loops: List[Vec3] = []
    for (x, y, z) in field.sites:
        for d in _POS_DELTAS:
            axis = _DELTA_AXIS[d]  # which axis this delta steps along
            gx, gy, gz = x + d[0], y + d[1], z + d[2]
            crosses_boundary = gx == n or gy == n or gz == n
            if crosses_boundary and not periodic[axis]:
                continue
            t = (gx % n, gy % n, gz % n)
            if t not in field.sites:
                continue
            loop = uf.union((x, y, z), t, d)
            if loop is not None:
                loops.append(loop)
    return uf, loops


# -------------------------------------------------------------- Public API
def cluster_sizes(
    field: Field, periodic: Tuple[bool, bool, bool] = (True, True, True)
) -> List[int]:
    """Sorted (ascending) list of cluster sizes (each an int, sum == number
    of occupied sites)."""
    if not field.sites:
        return []
    uf, _ = _build(field, periodic)
    counts: Dict[Site, int] = {}
    for s in field.sites:
        root, _ = uf.find(s)
        counts[root] = counts.get(root, 0) + 1
    return sorted(counts.values())


def wraps(
    field: Field, axis, periodic: Tuple[bool, bool, bool] = (True, True, True)
) -> bool:
    """True iff some cluster is connected to itself across the periodic
    boundary along `axis` ('x'/'y'/'z' or 0/1/2) — i.e. carries a nonzero
    lattice-translation self-map with a nonzero component along that axis."""
    idx = _axis_index(axis)
    if not field.sites:
        return False
    _, loops = _build(field, periodic)
    return any(vec[idx] != 0 for vec in loops)


def percolates(
    field: Field, periodic: Tuple[bool, bool, bool] = (True, True, True)
) -> bool:
    """True iff `field` wraps along any of the three axes."""
    if not field.sites:
        return False
    _, loops = _build(field, periodic)
    return len(loops) > 0
