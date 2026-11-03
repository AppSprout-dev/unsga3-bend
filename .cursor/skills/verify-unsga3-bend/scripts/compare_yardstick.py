#!/usr/bin/env python3
"""Compare a fresh ab/oracle_multiseed.py summary.jsonl with docs/ORACLE-MULTISEED.md.

Reads only real `igd=` cells: the fresh JSONL rows and the published per-seed
tables. Prints one line per (problem, seed, stack) that drifted beyond the
table's printed precision (6 decimals), plus a count. Never writes the doc.

Usage: compare_yardstick.py <summary.jsonl> [--doc docs/ORACLE-MULTISEED.md] [--allow-skip]
Exit 0 = at least one fresh cell was compared, every compared cell matches the
published cell, and nothing was skipped.
Exit 1 = drift, zero cells compared (a vacuous run proves nothing), or any
`skip:` row (missing pymoo / dotnet / UNSGA3_CS_ROOT). `--allow-skip` lets
skipped rows through; report those columns as unverified.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(subprocess.check_output(
    ["git", "-C", str(Path(__file__).parent), "rev-parse", "--show-toplevel"], text=True).strip())
STACKS = ("bend", "csharp", "pymoo")


def published(doc: str) -> dict[tuple[str, int, str], tuple[float, int]]:
    cells: dict[tuple[str, int, str], tuple[float, int]] = {}
    problem = None
    for line in doc.splitlines():
        h = re.match(r"^### (ZDT1|ZDT2|DTLZ2) \(", line)
        if h:
            problem = h.group(1).lower()
            continue
        if line.startswith("## "):
            problem = None
        if not problem:
            continue
        cols = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cols) == 9 and cols[0].isdigit():
            seed = int(cols[0])
            for i, st in enumerate(STACKS):
                cells[(problem, seed, st)] = (float(cols[1 + i]), int(cols[6 + i]))
    return cells


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("summary", type=Path)
    ap.add_argument("--doc", type=Path, default=ROOT / "docs" / "ORACLE-MULTISEED.md")
    ap.add_argument("--allow-skip", action="store_true",
                    help="do not fail on skipped rows (those columns stay unverified)")
    a = ap.parse_args()
    pub = published(a.doc.read_text())
    seen = match = 0
    drift: list[str] = []
    skips: list[str] = []
    for raw in a.summary.read_text().splitlines():
        r = json.loads(raw)
        key = (r["problem"], int(r["seed"]), r["stack"])
        if r.get("skipped"):
            skips.append(f"{key}: {r.get('skip')}")
            continue
        if key not in pub:
            continue
        seen += 1
        igd, n = pub[key]
        if round(r["igd"], 6) == round(igd, 6) and int(r["front_rows"]) == n:
            match += 1
        else:
            drift.append(f"DRIFT {key[0]} seed={key[1]} {key[2]}: fresh igd={r['igd']:.6f} n={r['front_rows']} "
                         f"vs doc igd={igd:.6f} n={n}")
    for d in drift:
        print(d)
    for s in skips:
        print("SKIP", s)
    print(f"cells_compared={seen} matched={match} drifted={len(drift)} skipped={len(skips)}")
    fail = []
    if seen == 0:
        fail.append("no cell compared (empty summary or no row matches a published cell)")
    if drift:
        fail.append(f"{len(drift)} cell(s) drifted")
    if skips and not a.allow_skip:
        fail.append(f"{len(skips)} row(s) skipped (pass --allow-skip to report them as unverified)")
    for f in fail:
        print("FAIL", f)
    print("yardstick=" + ("fail" if fail else "pass"))
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
