#!/usr/bin/env python3
"""IGD of a dumped front vs pymoo, when pymoo is installed.

No invented numbers: if pymoo is missing, skip with a clear message (exit 0).
Reference sets:

- simplex: analytic 2-obj unit simplex (v0 core fixture)
- zdt1: analytic f2 = 1 - sqrt(f1), f1 ∈ [0, 1]
- zdt2: analytic f2 = 1 - f1^2, f1 ∈ [0, 1]
- dtlz2: Das–Dennis unit-sphere PF at the run's partitions (C# OracleCompare
  `ParetoFronts.Dtlz2(M, partitions)`). Default pymoo `pareto_front()` is a
  different ~136-point sample and is **not** the oracle yardstick.

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
        choices=("simplex", "zdt1", "zdt2", "dtlz2"),
        default="simplex",
        help="analytic / pymoo PF family (default simplex for the v0 core fixture)",
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
        help="Das–Dennis partitions for the DTLZ2 PF (oracle default 12 → 91 pts at M=3)",
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
    else:
        if n_obj != 3:
            print(
                f"skip: DTLZ2 PF helper is M=3; front has {n_obj} columns.",
                file=sys.stderr,
            )
            return 0
        try:
            pf, pf_source = dtlz2_pf(3, args.partitions)
        except Exception as exc:
            # pymoo is installed (IGD import succeeded) but ref_dirs PF failed.
            # Analytic L2 Das–Dennis matches C# ParetoFronts.Dtlz2 — not a made-up PF.
            print(
                f"note: pymoo get_reference_directions / pareto_front(ref_dirs=...) "
                f"failed ({exc}); using analytic Das–Dennis L2 PF.",
                file=sys.stderr,
            )
            pf = dtlz2_pf_analytic(3, args.partitions)
            pf_source = "analytic-das-dennis-l2"
        if not pf:
            print(
                "skip: DTLZ2 Das–Dennis PF is empty. Refusing to invent a PF or IGD.",
                file=sys.stderr,
            )
            return 0

    igd = float(IGD(np.asarray(pf, dtype=float))(np.asarray(front, dtype=float)))
    print(f"igd={igd}")
    print(f"problem={args.problem}")
    print(f"front_rows={len(front)}")
    print(f"pf_rows={len(pf)}")
    print(f"pf_source={pf_source}")
    if args.problem == "dtlz2":
        print(f"partitions={args.partitions}")
    print(f"front={args.front}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
