#!/usr/bin/env python3
"""Compare dumped fronts. Uses only files that exist — no invented metrics.

v0: compare Bend vs optional C# CSV row-sets. IGD is a separate script
(ab/igd_vs_pymoo.py) and is skipped when pymoo is missing.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "ab" / "out"


def load_rows(path: Path) -> list[tuple[float, ...]]:
    rows: list[tuple[float, ...]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        rows.append(tuple(float(x) for x in line.split(",")))
    return rows


def fmt_row(row: tuple[float, ...]) -> str:
    return ",".join(str(x) for x in row)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bend", type=Path, default=OUT / "bend_F.csv")
    parser.add_argument("--csharp", type=Path, default=OUT / "csharp_F.csv")
    args = parser.parse_args()

    if not args.bend.is_file():
        print(
            f"missing Bend front: {args.bend}. Run ab/dump_bend_front.py first.",
            file=sys.stderr,
        )
        return 2

    bend = load_rows(args.bend)
    print(f"bend_rows={len(bend)}")
    print(f"bend_file={args.bend}")
    for row in bend:
        print(f"bend:{fmt_row(row)}")

    if not args.csharp.is_file():
        print(
            "csharp_front=absent (optional; dump_csharp_front.py skips unless "
            "UNSGA3_CS_ROOT is set and a C# dump is written)",
            file=sys.stderr,
        )
        return 0

    csharp = load_rows(args.csharp)
    print(f"csharp_rows={len(csharp)}")
    bset = set(bend)
    cset = set(csharp)
    print(f"row_set_equal={bset == cset}")
    only_b = bset - cset
    only_c = cset - bset
    print(f"only_bend={len(only_b)}")
    print(f"only_csharp={len(only_c)}")
    return 0 if bset == cset else 1


if __name__ == "__main__":
    raise SystemExit(main())
