#!/usr/bin/env python3
"""Optional C# Unsga3Algorithm.Run dump via OracleCompare.

This repo does not vendor or clone AppSprout-dev/Unsga3. When
UNSGA3_CS_ROOT is unset, the script skips (exit 0).

When set, it runs tools/OracleCompare with the same flags the C# docs
use (or the smoke defaults if --smoke). Missing dotnet / project / a
build failure prints `skip: …` and exits 0. No invented fronts.

OracleCompare also prints IGD on its stdout; this script only copies the
front CSV. It does not invent or rewrite metrics.
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


def skip(msg: str) -> int:
    print(f"skip: {msg}", file=sys.stderr)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--problem", default="zdt1")
    parser.add_argument("--partitions", type=int, default=None)
    parser.add_argument("--pop", type=int, default=None)
    parser.add_argument("--gens", type=int, default=None)
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument(
        "--smoke",
        action="store_true",
        help="use Bend smoke settings (zdt1 partitions=4 pop=8 gens=3 seed=1), not oracle",
    )
    parser.add_argument("--out", type=Path, default=OUT_DIR / "csharp_run_F.csv")
    args = parser.parse_args()

    cs_root = os.environ.get("UNSGA3_CS_ROOT", "").strip()
    if not cs_root:
        return skip(
            "C# Unsga3 Run dump is optional. Set UNSGA3_CS_ROOT to a local "
            "checkout of https://github.com/AppSprout-dev/Unsga3 and run "
            "tools/OracleCompare (see C# docs/EQUIVALENCE.md). This tree "
            "does not clone Unsga3."
        )

    root = Path(cs_root).expanduser().resolve()
    proj = root / "tools" / "OracleCompare" / "OracleCompare.csproj"
    if not proj.is_file():
        # some checkouts may use a folder-only project
        alt = root / "tools" / "OracleCompare"
        if (alt / "Program.cs").is_file():
            proj = alt
        else:
            return skip(
                f"UNSGA3_CS_ROOT={root} has no tools/OracleCompare. "
                "Refusing to invent a front. Documented invocation: "
                "dotnet run --project tools/OracleCompare -- --problem zdt1 "
                "--partitions 12 --pop 52 --gens 100 --seed 1 --pymoo-mode"
            )

    dotnet = shutil.which("dotnet")
    if not dotnet:
        return skip(
            "dotnet is not on PATH; cannot run C# OracleCompare. "
            "Refusing to invent a front."
        )

    if args.smoke:
        problem, partitions, pop, gens, seed = "zdt1", 4, 8, 3, 1
    else:
        problem = args.problem
        partitions = args.partitions if args.partitions is not None else 12
        pop = args.pop if args.pop is not None else (92 if problem == "dtlz2" else 52)
        gens = args.gens if args.gens is not None else (150 if problem == "dtlz2" else 100)
        seed = args.seed

    args.out.parent.mkdir(parents=True, exist_ok=True)
    tmp_dir = OUT_DIR / "csharp_oracle"
    tmp_dir.mkdir(parents=True, exist_ok=True)
    cmd = [
        dotnet,
        "run",
        "--project",
        str(proj),
        "-c",
        "Release",
        "-v",
        "q",
        "--",
        "--problem",
        problem,
        "--partitions",
        str(partitions),
        "--pop",
        str(pop),
        "--gens",
        str(gens),
        "--seed",
        str(seed),
        "--pymoo-mode",
        "--out-dir",
        str(tmp_dir.resolve()),
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
        return skip(f"C# OracleCompare build/run failed: {detail}")

    csvs = sorted(tmp_dir.glob("csharp_*_F.csv"))
    if not csvs:
        return skip(
            f"OracleCompare exited 0 but no csharp_*_F.csv under {tmp_dir}. "
            "Refusing to invent a front."
        )
    src = csvs[-1]
    args.out.write_text(src.read_text(encoding="utf-8"), encoding="utf-8")
    n = sum(1 for line in args.out.read_text(encoding="utf-8").splitlines() if line.strip())
    print(f"wrote {args.out} from {src.name} ({n} rows)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
