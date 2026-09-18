#!/usr/bin/env python3
"""Optional C# Unsga3 dump for the same objective fixture.

This repo does not vendor or clone AppSprout-dev/Unsga3. The C# oracle is
optional: if UNSGA3_CS_ROOT is unset or the expected dump tool is missing,
the script skips with a clear message (exit 0).

When a local C# checkout exists, expected layout (documented, not invented):
  $UNSGA3_CS_ROOT/tools/oracle  — see that repo's docs/EQUIVALENCE.md
Write the selected front as CSV to --out (default ab/out/csharp_F.csv).
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "ab" / "out"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fixture", type=Path, default=ROOT / "ab" / "fixtures" / "core_2obj.json")
    parser.add_argument("--out", type=Path, default=OUT_DIR / "csharp_F.csv")
    args = parser.parse_args()

    cs_root = os.environ.get("UNSGA3_CS_ROOT", "").strip()
    if not cs_root:
        print(
            "skip: C# Unsga3 dump is optional. Set UNSGA3_CS_ROOT to a local "
            "checkout of https://github.com/AppSprout-dev/Unsga3 and use that "
            "repo's tools/oracle on the same fixture. This tree does not clone Unsga3.",
            file=sys.stderr,
        )
        return 0

    root = Path(cs_root)
    oracle = root / "tools" / "oracle"
    if not oracle.exists():
        print(
            f"skip: UNSGA3_CS_ROOT={root} has no tools/oracle. "
            "See AppSprout-dev/Unsga3 docs/EQUIVALENCE.md. Refusing to invent a front.",
            file=sys.stderr,
        )
        return 0

    print(
        f"skip: tools/oracle is present at {oracle} but this v0 hook does not "
        "invoke it (no clone-into-repo workflow). Dump the same fixture with the "
        f"C# NondominatedSortingSurvival.Select path and write {args.out} yourself.",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
