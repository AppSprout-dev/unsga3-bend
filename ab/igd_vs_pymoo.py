#!/usr/bin/env python3
"""IGD of a dumped front vs pymoo, when pymoo is installed.

No invented numbers: if pymoo is missing, skip with a clear message (exit 0).
Reference sets:

- simplex: analytic 2-obj unit simplex (v0 core fixture)
- zdt1: analytic f2 = 1 - sqrt(f1), f1 ∈ [0, 1]
- zdt2: analytic f2 = 1 - f1^2, f1 ∈ [0, 1]
- zdt3: C# `ParetoFronts.Zdt3` disconnected segments (100 points each)
- zdt4: same geometry as zdt1 (C# `ParetoFronts.Zdt4`)
- zdt6: C# `ParetoFronts.Zdt6`, f1 from 0.280775 to 1, f2 = 1 - f1^2
- dtlz1: Das–Dennis simplex scaled by 1/2 (C# `ParetoFronts.Dtlz1`)
- dtlz2 / dtlz3 / dtlz4: Das–Dennis unit-sphere PF at the run's partitions
  (C# `ParetoFronts.Dtlz2`; DTLZ3 and DTLZ4 share that front). Default
  pymoo `pareto_front()` is a different ~136-point sample and is **not**
  the oracle yardstick.
- dtlz7: pymoo `pareto_front()` only. C# `ParetoFronts` has no DTLZ7. If that
  call fails, this script skips. It does not invent a front.
- sphere / ackley / rosenbrock: one-point PF at f = 0 (known minimum).

Never fabricates IGD / HV / Wilcoxon values.
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_FRONT = ROOT / "ab" / "out" / "bend_F.csv"


def load_csv(path: Path) -> list[list[float]]:
    rows: list[list[float]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        rows.append([float(x) for x in line.split(",")])
    return rows


def simplex_pf(n_points: int) -> list[list[float]]:
    if n_points < 2:
        n_points = 2
    pf = []
    for i in range(n_points):
        t = i / (n_points - 1)
        pf.append([t, 1.0 - t])
    return pf


def zdt1_pf(n_points: int) -> list[list[float]]:
    if n_points < 2:
        n_points = 2
    pf = []
    for i in range(n_points):
        t = i / (n_points - 1)
        pf.append([t, 1.0 - math.sqrt(t)])
    return pf


def zdt2_pf(n_points: int) -> list[list[float]]:
    if n_points < 2:
        n_points = 2
    pf = []
    for i in range(n_points):
        t = i / (n_points - 1)
        pf.append([t, 1.0 - t * t])
    return pf


def das_dennis(n_obj: int, partitions: int) -> list[list[float]]:
    """C# ReferenceDirections.DasDennis: first coordinate 0..p, DFS."""
    rows: list[list[float]] = []

    def rec(left: int, dims: int, prefix: list[int]) -> None:
        if dims == 1:
            comps = prefix + [left]
            rows.append([c / partitions for c in comps])
            return
        for i in range(left + 1):
            rec(left - i, dims - 1, prefix + [i])

    if n_obj < 1:
        return []
    if n_obj == 1:
        return [[1.0]]
    if partitions < 1:
        return []
    rec(partitions, n_obj, [])
    return rows


def dtlz2_pf_analytic(n_obj: int, partitions: int) -> list[list[float]]:
    """C# ParetoFronts.Dtlz2: Das–Dennis directions, L2-normalized to the sphere."""
    pf: list[list[float]] = []
    for w in das_dennis(n_obj, partitions):
        nrm = math.sqrt(sum(x * x for x in w))
        pf.append([x / nrm for x in w])
    return pf


# C# ParetoFronts.Zdt3. The second left endpoint is 0.1822287280.
# pymoo 0.6.2 writes 0.182228780; this tree keeps the C# literal.
ZDT3_INTERVALS = (
    (0.0, 0.0830015349),
    (0.1822287280, 0.2577623634),
    (0.4093136748, 0.4538821041),
    (0.6183967944, 0.6525117038),
    (0.8233317983, 0.8518328654),
)
ZDT3_POINTS_PER_SEGMENT = 100
# C# ParetoFronts.Zdt6 truncated floor.
ZDT6_F1_MIN = 0.280775


def zdt3_f2(f1: float) -> float:
    return 1.0 - math.sqrt(f1) - f1 * math.sin(10.0 * math.pi * f1)


def zdt3_pf(points_per_segment: int = ZDT3_POINTS_PER_SEGMENT) -> list[list[float]]:
    if points_per_segment < 2:
        points_per_segment = 2
    pf: list[list[float]] = []
    for lo, hi in ZDT3_INTERVALS:
        for i in range(points_per_segment):
            t = i / (points_per_segment - 1)
            f1 = lo + t * (hi - lo)
            pf.append([f1, zdt3_f2(f1)])
    return pf


def zdt6_pf(n_points: int, f1_min: float = ZDT6_F1_MIN) -> list[list[float]]:
    if n_points < 2:
        n_points = 2
    pf: list[list[float]] = []
    for i in range(n_points):
        f1 = f1_min + (1.0 - f1_min) * i / (n_points - 1)
        pf.append([f1, 1.0 - f1 * f1])
    return pf


def dtlz1_pf(n_obj: int, partitions: int) -> list[list[float]]:
    """C# ParetoFronts.Dtlz1: Das–Dennis directions scaled by 0.5."""
    return [[0.5 * x for x in w] for w in das_dennis(n_obj, partitions)]


def dtlz7_pf() -> tuple[list[list[float]], str]:
    """pymoo's own DTLZ7 sample. No analytic stand-in."""
    from pymoo.problems import get_problem

    arr = get_problem("dtlz7", n_obj=3, n_var=22).pareto_front()
    if arr is None or len(arr) == 0:
        raise RuntimeError("pymoo dtlz7 pareto_front() returned no points")
    pf = [list(map(float, row)) for row in arr]
    return pf, "pymoo-pareto_front"


def optimum_pf() -> list[list[float]]:
    return [[0.0]]


def dtlz2_pf(n_obj: int, partitions: int) -> tuple[list[list[float]], str]:
    """Das–Dennis-density DTLZ2 PF via pymoo ref_dirs; analytic fallback."""
    from pymoo.problems import get_problem
    from pymoo.util.ref_dirs import get_reference_directions

    ref_dirs = get_reference_directions("das-dennis", n_obj, n_partitions=partitions)
    pf_arr = get_problem("dtlz2", n_obj=n_obj, n_var=n_obj + 9).pareto_front(
        ref_dirs=ref_dirs
    )
    pf = [list(map(float, row)) for row in pf_arr]
    if not pf:
        raise RuntimeError("pymoo DTLZ2 pareto_front(ref_dirs=...) returned no points")
    return pf, "pymoo-das-dennis"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--front", type=Path, default=DEFAULT_FRONT)
    parser.add_argument(
        "--problem",
        choices=(
            "simplex",
            "zdt1",
            "zdt2",
            "zdt3",
            "zdt4",
            "zdt6",
            "dtlz1",
            "dtlz2",
            "dtlz3",
            "dtlz4",
            "dtlz7",
            "sphere",
            "ackley",
            "rosenbrock",
        ),
        default="simplex",
        help="PF family (default simplex for the v0 core fixture)",
    )
    parser.add_argument(
        "--pf-points",
        type=int,
        default=101,
        help="samples for analytic 2-obj PFs (C# OracleCompare ZDT uses 500)",
    )
    parser.add_argument(
        "--partitions",
        type=int,
        default=12,
        help="Das–Dennis partitions for DTLZ1/2/3/4 PFs (oracle default 12 → 91 pts at M=3)",
    )
    parser.add_argument(
        "--points-per-segment",
        type=int,
        default=ZDT3_POINTS_PER_SEGMENT,
        help="ZDT3 only: C# ParetoFronts.Zdt3 points per disconnected segment (default 100)",
    )
    args = parser.parse_args()

    try:
        from pymoo.indicators.igd import IGD
        import numpy as np
    except ImportError:
        print(
            "skip: pymoo is not installed; IGD vs pymoo oracle not run. "
            "Install pymoo to compute IGD(front, PF) for simplex/ZDT/DTLZ.",
            file=sys.stderr,
        )
        return 0

    if not args.front.is_file():
        print(f"skip: front file missing: {args.front}", file=sys.stderr)
        return 0

    front = load_csv(args.front)
    if not front:
        print(f"skip: empty front: {args.front}", file=sys.stderr)
        return 0

    n_obj = len(front[0])
    pf: list[list[float]]
    pf_source: str
    if args.problem == "simplex":
        if n_obj != 2:
            print(
                f"skip: analytic simplex PF is 2-objective; front has {n_obj} columns.",
                file=sys.stderr,
            )
            return 0
        pf = simplex_pf(args.pf_points)
        pf_source = f"analytic-simplex n={args.pf_points}"
    elif args.problem == "zdt1":
        if n_obj != 2:
            print(
                f"skip: ZDT1 PF is 2-objective; front has {n_obj} columns.",
                file=sys.stderr,
            )
            return 0
        pf = zdt1_pf(args.pf_points)
        pf_source = f"analytic-zdt1 n={args.pf_points}"
    elif args.problem == "zdt2":
        if n_obj != 2:
            print(
                f"skip: ZDT2 PF is 2-objective; front has {n_obj} columns.",
                file=sys.stderr,
            )
            return 0
        pf = zdt2_pf(args.pf_points)
        pf_source = f"analytic-zdt2 n={args.pf_points}"
    elif args.problem == "zdt3":
        if n_obj != 2:
            print(
                f"skip: ZDT3 PF is 2-objective; front has {n_obj} columns.",
                file=sys.stderr,
            )
            return 0
        pf = zdt3_pf(args.points_per_segment)
        pf_source = (
            f"analytic-zdt3 segments={len(ZDT3_INTERVALS)} "
            f"points_per={args.points_per_segment}"
        )
    elif args.problem == "zdt4":
        if n_obj != 2:
            print(
                f"skip: ZDT4 PF is 2-objective; front has {n_obj} columns.",
                file=sys.stderr,
            )
            return 0
        pf = zdt1_pf(args.pf_points)
        pf_source = f"analytic-zdt4 n={args.pf_points}"
    elif args.problem == "zdt6":
        if n_obj != 2:
            print(
                f"skip: ZDT6 PF is 2-objective; front has {n_obj} columns.",
                file=sys.stderr,
            )
            return 0
        pf = zdt6_pf(args.pf_points)
        pf_source = f"analytic-zdt6 n={args.pf_points} f1min={ZDT6_F1_MIN}"
    elif args.problem == "dtlz1":
        if n_obj != 3:
            print(
                f"skip: DTLZ1 PF helper is M=3; front has {n_obj} columns.",
                file=sys.stderr,
            )
            return 0
        pf = dtlz1_pf(3, args.partitions)
        pf_source = "analytic-dtlz1-half-simplex"
        if not pf:
            print(
                "skip: DTLZ1 Das–Dennis PF is empty. Refusing to invent a PF or IGD.",
                file=sys.stderr,
            )
            return 0
    elif args.problem in ("dtlz2", "dtlz3", "dtlz4"):
        if n_obj != 3:
            print(
                f"skip: {args.problem} PF helper is M=3; front has {n_obj} columns.",
                file=sys.stderr,
            )
            return 0
        try:
            pf, pf_source = dtlz2_pf(3, args.partitions)
        except Exception as exc:
            # pymoo is installed (IGD import succeeded) but ref_dirs PF failed.
            # Analytic L2 Das–Dennis matches C# ParetoFronts.Dtlz2 — not a made-up PF.
            # DTLZ3 and DTLZ4 share that sphere.
            print(
                f"note: pymoo get_reference_directions / pareto_front(ref_dirs=...) "
                f"failed ({exc}); using analytic Das–Dennis L2 PF.",
                file=sys.stderr,
            )
            pf = dtlz2_pf_analytic(3, args.partitions)
            pf_source = "analytic-das-dennis-l2"
        if not pf:
            print(
                f"skip: {args.problem} Das–Dennis PF is empty. Refusing to invent a PF or IGD.",
                file=sys.stderr,
            )
            return 0
    elif args.problem == "dtlz7":
        if n_obj != 3:
            print(
                f"skip: DTLZ7 PF helper is M=3; front has {n_obj} columns.",
                file=sys.stderr,
            )
            return 0
        try:
            pf, pf_source = dtlz7_pf()
        except Exception as exc:
            print(
                "skip: C# ParetoFronts has no DTLZ7, and pymoo pareto_front() "
                f"failed ({exc}). Refusing to invent a PF or IGD.",
                file=sys.stderr,
            )
            return 0
    else:
        if n_obj != 1:
            print(
                f"skip: {args.problem} optimum PF is 1-objective; front has {n_obj} columns.",
                file=sys.stderr,
            )
            return 0
        pf = optimum_pf()
        pf_source = "analytic-optimum f=0"

    igd = float(IGD(np.asarray(pf, dtype=float))(np.asarray(front, dtype=float)))
    print(f"igd={igd}")
    print(f"problem={args.problem}")
    print(f"front_rows={len(front)}")
    print(f"pf_rows={len(pf)}")
    print(f"pf_source={pf_source}")
    if args.problem in ("dtlz1", "dtlz2", "dtlz3", "dtlz4"):
        print(f"partitions={args.partitions}")
    if args.problem == "zdt3":
        print(f"points_per_segment={args.points_per_segment}")
    print(f"front={args.front}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
