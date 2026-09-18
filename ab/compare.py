#!/usr/bin/env python3
"""Compare C# vs Bend vs pymoo dumps. Not wired — no fake numbers."""

from __future__ import annotations

import sys


def main() -> int:
    print("not wired", file=sys.stderr)
    print(
        "ab/compare.py: comparison is not wired. "
        "v0 will compare ranks / associations / selected indices; "
        "pass 2 will compare IGD meta.json. Refusing to invent results.",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
