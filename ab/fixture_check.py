#!/usr/bin/env python3
"""Layer-1 fixture bit-check: Bend vs C# selected fronts.

Runs the existing dumpers on checked-in fixtures (default:
ab/fixtures/core_2obj.json) and compares row-sets via ab/compare.py.

This is the end-to-end of sort → normalize → associate → select
(deterministic `rng == null` / v0 Survival.select). Intermediate ranks
are not dumped; selected objective rows are the Layer-1 contract.

C# dump skips (exit 0) without UNSGA3_CS_ROOT / dotnet. This script then
prints skip: and does not invent agreement. Never weakens LAWS.bend.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "ab" / "out"
DUMP_BEND = ROOT / "ab" / "dump_bend_front.py"
DUMP_CS = ROOT / "ab" / "dump_csharp_front.py"
COMPARE = ROOT / "ab" / "compare.py"
DEFAULT_FIXTURE = ROOT / "ab" / "fixtures" / "core_2obj.json"


def _env() -> dict[str, str]:
    env = os.environ.copy()
    env.setdefault("BEND_NO_TELEMETRY", "1")
    path = env.get("PATH", "")
    extras = (
        str(Path.home() / ".bend" / "bin"),
        str(Path.home() / ".dotnet"),
        str(Path.home() / ".local" / "bin"),
    )
    for extra in extras:
        if extra not in path.split(":"):
            path = extra + ":" + path
    env["PATH"] = path
    env.setdefault("DOTNET_ROOT", str(Path.home() / ".dotnet"))
    return env


def run_py(script: Path, extra: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(script), *extra],
        cwd=str(ROOT),
        env=_env(),
        check=False,
        capture_output=True,
        text=True,
    )


def parse_compare(stdout: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for line in stdout.splitlines():
        if "=" in line and not line.startswith("bend:"):
            k, _, v = line.partition("=")
            out[k.strip()] = v.strip()
    return out


def check_one(fixture: Path, out_dir: Path) -> dict:
    stem = fixture.stem
    bend_csv = out_dir / f"fixture_{stem}_bend_F.csv"
    cs_csv = out_dir / f"fixture_{stem}_csharp_F.csv"
    rec: dict = {
        "fixture": str(fixture.relative_to(ROOT) if fixture.is_relative_to(ROOT) else fixture),
        "bend": "unknown",
        "csharp": "unknown",
        "row_set_equal": None,
        "verdict": "unknown",
    }

    if not fixture.is_file():
        rec["bend"] = f"skip: missing fixture {fixture}"
        rec["verdict"] = "skip"
        return rec

    bp = run_py(DUMP_BEND, ["--fixture", str(fixture), "--out", str(bend_csv)])
    sys.stderr.write(bp.stderr or "")
    if bp.returncode != 0:
        rec["bend"] = f"fail: dump_bend_front rc={bp.returncode}"
        rec["verdict"] = "fail"
        return rec
    if not bend_csv.is_file():
        rec["bend"] = "fail: Bend CSV not written"
        rec["verdict"] = "fail"
        return rec
    rec["bend"] = "ok"
    rec["bend_file"] = str(bend_csv)

    cs_root = os.environ.get("UNSGA3_CS_ROOT", "").strip()
    cp = run_py(DUMP_CS, ["--fixture", str(fixture), "--out", str(cs_csv)])
    sys.stderr.write(cp.stderr or "")
    cs_skip = (cp.stderr or "").strip().startswith("skip:") or not cs_root
    if cs_skip or not cs_csv.is_file():
        reason = (cp.stderr or "").strip() or "skip: C# dump absent"
        rec["csharp"] = reason.splitlines()[-1] if reason else "skip: C# dump absent"
        rec["verdict"] = "skip"
        rec["note"] = (
            "C# dump is optional. Set UNSGA3_CS_ROOT to a sibling Unsga3 "
            "checkout and install dotnet to get a pass/fail bit-check."
        )
        return rec
    rec["csharp"] = "ok"
    rec["csharp_file"] = str(cs_csv)

    cmp = run_py(COMPARE, ["--bend", str(bend_csv), "--csharp", str(cs_csv)])
    sys.stdout.write(cmp.stdout or "")
    parsed = parse_compare(cmp.stdout or "")
    rec["bend_rows"] = parsed.get("bend_rows")
    rec["csharp_rows"] = parsed.get("csharp_rows")
    rec["row_set_equal"] = parsed.get("row_set_equal")
    rec["only_bend"] = parsed.get("only_bend")
    rec["only_csharp"] = parsed.get("only_csharp")
    if parsed.get("row_set_equal") == "True":
        rec["verdict"] = "pass"
    else:
        rec["verdict"] = "fail"
        rec["note"] = (
            "Selected-front row-sets differ. Do not weaken LAWS.bend or "
            "change dominance to force a pass. Intentional Run-path deltas "
            "(LCG, Pareto-only) do not apply to this deterministic select."
        )
    return rec


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--fixtures",
        nargs="+",
        type=Path,
        default=[DEFAULT_FIXTURE],
        help="JSON fixtures (default: ab/fixtures/core_2obj.json)",
    )
    parser.add_argument("--out-dir", type=Path, default=OUT / "fixture_check")
    args = parser.parse_args()

    args.out_dir.mkdir(parents=True, exist_ok=True)
    rows = [check_one(Path(f).resolve(), args.out_dir) for f in args.fixtures]

    print("fixture_check:")
    for rec in rows:
        print(
            f"  fixture={rec['fixture']} verdict={rec['verdict']} "
            f"bend={rec['bend']} csharp={rec['csharp']} "
            f"row_set_equal={rec['row_set_equal']}"
        )
        if rec.get("note"):
            print(f"    note={rec['note']}")

    if any(r["verdict"] == "fail" for r in rows):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
