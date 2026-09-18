#!/usr/bin/env python3
"""IGD of a dumped front vs pymoo, when pymoo is installed.

No invented numbers: if pymoo is missing, skip with a clear message (exit 0).
For the checked-in 2-obj smoke fixture the reference set is the analytic
unit simplex (f1 + f2 = 1, fi >= 0), sampled; not a fabricated IGD value.
"""

from __future__ import annotations

import argparse
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


def simplex_pf(n_obj: int, n_points: int) -> list[list[float]]:
    if n_obj != 2:
        raise ValueError("analytic smoke PF is only defined for n_obj == 2")
    if n_points < 2:
        n_points = 2
    pf = []
    for i in range(n_points):
        t = i / (n_points - 1)
        pf.append([t, 1.0 - t])
    return pf


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--front", type=Path, default=DEFAULT_FRONT)
    parser.add_argument(
        "--pf-points",
        type=int,
        default=101,
        help="number of analytic unit-simplex samples for the 2-obj smoke PF",
    )
    args = parser.parse_args()

    try:
        from pymoo.indicators.igd import IGD
        import numpy as np
    except ImportError:
        print(
            "skip: pymoo is not installed; IGD vs pymoo oracle not run. "
            "Install pymoo to compute IGD(front, unit-simplex PF) for the smoke fixture.",
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
    if n_obj != 2:
        print(
            f"skip: analytic smoke PF is 2-objective; front has {n_obj} columns. "
            "Pass a 2-obj front or compute IGD elsewhere against a real PF.",
            file=sys.stderr,
        )
        return 0

    pf = simplex_pf(2, args.pf_points)
    igd = float(IGD(np.asarray(pf, dtype=float))(np.asarray(front, dtype=float)))
    print(f"igd={igd}")
    print(f"front_rows={len(front)}")
    print(f"pf_rows={len(pf)}")
    print(f"front={args.front}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
