#!/usr/bin/env python3
"""Optional C# Unsga3 dump for the same objective fixture.

This repo does not vendor or clone AppSprout-dev/Unsga3. When
UNSGA3_CS_ROOT is unset, the script skips (exit 0).

When UNSGA3_CS_ROOT points at a local Unsga3 checkout, this runs a
checked-in one-shot (`ab/csharp_core_dump`) via `dotnet` that calls
NondominatedSortingSurvival.Select on the fixture with rng=null and
writes the selected front to --out (default ab/out/csharp_F.csv).

Missing dotnet, a missing Unsga3 project, or a build/run failure
prints `skip: …` and exits 0. No invented fronts.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "ab" / "out"
DUMP_PROJ = ROOT / "ab" / "csharp_core_dump" / "csharp_core_dump.csproj"
DEFAULT_FIXTURE = ROOT / "ab" / "fixtures" / "core_2obj.json"


def skip(msg: str) -> int:
    print(f"skip: {msg}", file=sys.stderr)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fixture", type=Path, default=DEFAULT_FIXTURE)
    parser.add_argument("--out", type=Path, default=OUT_DIR / "csharp_F.csv")
    args = parser.parse_args()

    cs_root = os.environ.get("UNSGA3_CS_ROOT", "").strip()
    if not cs_root:
        return skip(
            "C# Unsga3 dump is optional. Set UNSGA3_CS_ROOT to a local "
            "checkout of https://github.com/AppSprout-dev/Unsga3. This tree "
            "does not clone Unsga3."
        )

    root = Path(cs_root).expanduser().resolve()
    csproj = root / "src" / "Unsga3" / "Unsga3.csproj"
    if not csproj.is_file():
        return skip(
            f"UNSGA3_CS_ROOT={root} has no src/Unsga3/Unsga3.csproj. "
            "Refusing to invent a front."
        )

    if not DUMP_PROJ.is_file():
        return skip(f"checked-in dump project missing: {DUMP_PROJ}")

    dotnet = shutil.which("dotnet")
    if not dotnet:
        return skip(
            "dotnet is not on PATH; cannot build the C# core dump. "
            "Refusing to invent a front."
        )

    if not args.fixture.is_file():
        print(f"missing fixture: {args.fixture}", file=sys.stderr)
        return 2

    args.out.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        dotnet,
        "run",
        "--project",
        str(DUMP_PROJ),
        "-c",
        "Release",
        "-v",
        "q",
        f"--property:Unsga3Project={csproj}",
        "--",
        "--fixture",
        str(args.fixture.resolve()),
        "--out",
        str(args.out.resolve()),
    ]
    try:
        proc = subprocess.run(
            cmd,
            check=False,
            capture_output=True,
            text=True,
            env=os.environ.copy(),
        )
    except OSError as exc:
        return skip(f"dotnet failed to start ({exc}). Refusing to invent a front.")

    if proc.returncode != 0:
        detail = (proc.stderr or proc.stdout or "dotnet run failed").strip()
        if len(detail) > 800:
            detail = detail[:800] + "…"
        return skip(f"C# dump build/run failed: {detail}")

    if not args.out.is_file():
        return skip(
            f"dotnet exited 0 but {args.out} was not written. "
            "Refusing to invent a front."
        )

    n = sum(1 for line in args.out.read_text(encoding="utf-8").splitlines() if line.strip())
    print(f"wrote {args.out} ({n} rows)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
