#!/usr/bin/env python3
"""IGD of a dumped front vs pymoo, when pymoo is installed.

No invented numbers: if pymoo is missing, skip with a clear message (exit 0).
Reference sets:

- simplex: analytic 2-obj unit simplex (v0 core fixture)
- zdt1: analytic f2 = 1 - sqrt(f1), f1 ∈ [0, 1]
- zdt2: analytic f2 = 1 - f1^2, f1 ∈ [0, 1]
- dtlz2: pymoo get_problem('dtlz2').pareto_front() when pymoo can build it

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
        help="samples for analytic 2-obj PFs",
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
    if args.problem == "simplex":
        if n_obj != 2:
            print(
                f"skip: analytic simplex PF is 2-objective; front has {n_obj} columns.",
                file=sys.stderr,
            )
            return 0
        pf = simplex_pf(args.pf_points)
    elif args.problem == "zdt1":
        if n_obj != 2:
            print(
                f"skip: ZDT1 PF is 2-objective; front has {n_obj} columns.",
                file=sys.stderr,
            )
            return 0
        pf = zdt1_pf(args.pf_points)
    elif args.problem == "zdt2":
        if n_obj != 2:
            print(
                f"skip: ZDT2 PF is 2-objective; front has {n_obj} columns.",
                file=sys.stderr,
            )
            return 0
        pf = zdt2_pf(args.pf_points)
    else:
        try:
            from pymoo.problems import get_problem
            pf_arr = get_problem("dtlz2", n_obj=3, n_var=12).pareto_front()
            pf = [list(map(float, row)) for row in pf_arr]
        except Exception as exc:
            print(
                f"skip: pymoo DTLZ2 Pareto front unavailable ({exc}). "
                "Refusing to invent a PF or IGD.",
                file=sys.stderr,
            )
            return 0

    igd = float(IGD(np.asarray(pf, dtype=float))(np.asarray(front, dtype=float)))
    print(f"igd={igd}")
    print(f"problem={args.problem}")
    print(f"front_rows={len(front)}")
    print(f"pf_rows={len(pf)}")
    print(f"front={args.front}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
