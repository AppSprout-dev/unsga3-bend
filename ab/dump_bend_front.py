#!/usr/bin/env python3
"""Dump a Bend unsga3-bend front or v0 core selection. Not wired — no fake numbers."""

from __future__ import annotations

import sys


def main() -> int:
    print("not wired", file=sys.stderr)
    print(
        "ab/dump_bend_front.py: Bend dump is not wired. "
        "v0 can only A/B an objective population after core functions are implemented. "
        "Refusing to invent a front or IGD.",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
