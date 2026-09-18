#!/usr/bin/env python3
"""Dump a C# Unsga3 front or v0 core selection. Not wired — no fake numbers."""

from __future__ import annotations

import sys


def main() -> int:
    print("not wired", file=sys.stderr)
    print(
        "ab/dump_csharp_front.py: C# dump is not wired. "
        "Use AppSprout-dev/Unsga3 tools/oracle once this hook exists. "
        "Refusing to invent a front or IGD.",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
