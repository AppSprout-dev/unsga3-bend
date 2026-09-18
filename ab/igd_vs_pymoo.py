#!/usr/bin/env python3
"""IGD vs pymoo UNSGA3 oracle. Not wired — no fake numbers."""

from __future__ import annotations

import sys


def main() -> int:
    print("not wired", file=sys.stderr)
    print(
        "ab/igd_vs_pymoo.py: pymoo IGD oracle is not wired. "
        "Protocol (when implemented) matches C# Unsga3 docs/EQUIVALENCE.md: "
        "ZDT/DTLZ, Das-Dennis partitions, IGD = mean nearest distance. "
        "Refusing to invent IGD.",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
