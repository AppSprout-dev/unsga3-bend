#!/usr/bin/env python3
"""Catalog IGD table: Bend vs C# Unsga3 vs pymoo NSGA-III.

Not the ZDT1 / ZDT2 / DTLZ2 quality table (that stays
``ab/oracle_multiseed.py``). Knobs are ``protocol.catalog_knobs``:

  ZDT3 / ZDT4 / ZDT6     ZDT1 sibling budget  p=12 pop=52 gens=100
  DTLZ1 / DTLZ3 / DTLZ4 / DTLZ7
                         DTLZ2 sibling budget p=12 pop=92 gens=150
  Sphere / Ackley / Rosenbrock
                         short smoke          p=1  pop=20 gens=40

Tournament is PymooCompatible. Every cell is a real ``igd=`` line or
``skip:`` with a reason. OSY / TNK / C1-DTLZ1 are not ``catalog_knobs``
rows. This driver does not dump them. Measured cells live in
``docs/CONSTRAINED-SURFACES.md``.

Examples:

  python3 ab/oracle_catalog.py --problems zdt3 --seeds 1 --stacks bend pymoo
  python3 ab/oracle_catalog.py --reuse
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import oracle_multiseed as om
from oracle_multiseed import STACKS, markdown_table, score_front
from protocol import CONSTRAINED_ABSENT, CATALOG_PROBLEMS, catalog_knobs

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "ab" / "out" / "oracle_catalog"
DUMP_CS = ROOT / "ab" / "dump_csharp_catalog.py"

CONSTRAINT_MD = """## Constrained problems

Not part of `catalog_knobs`. This driver does not dump OSY / TNK / C1-DTLZ1. Formulations are in `src/problems.bend`. Measured `igd=` / `skip:` cells are in `docs/CONSTRAINED-SURFACES.md` (`ab/oracle_constrained.py`). The 2026-09-30 catalog snapshot in `docs/ORACLE-CATALOG.md` still shows the skips from that run.

| Problem | Bend | C# | pymoo NSGA-III |
|---------|------|----|----------------|
| OSY | skip: not dumped by oracle_catalog; see docs/CONSTRAINED-SURFACES.md | skip: not measured; no OracleCompare name | skip: not dumped by oracle_catalog |
| TNK | skip: not dumped by oracle_catalog; see docs/CONSTRAINED-SURFACES.md | skip: not measured; no OracleCompare name | skip: not dumped by oracle_catalog |
| C1-DTLZ1 | skip: not dumped by oracle_catalog; see docs/CONSTRAINED-SURFACES.md | skip: not measured; no OracleCompare name | skip: not dumped by oracle_catalog |
"""


def dump_catalog(
    stack: str,
    problem: str,
    partitions: int,
    pop: int,
    gens: int,
    seed: int,
    dest: Path,
    reuse: bool,
) -> dict:
    if stack != "csharp":
        return om.dump_stack(stack, problem, partitions, pop, gens, seed, dest, reuse)
    # Quality dump_stack calls OracleCompare, which rejects catalog names.
    saved = om.DUMP_CS
    om.DUMP_CS = DUMP_CS
    try:
        return om.dump_stack(stack, problem, partitions, pop, gens, seed, dest, reuse)
    finally:
        om.DUMP_CS = saved


def heading(problem: str, knobs: dict) -> str:
    return (
        f"### {problem.upper()} "
        f"(n_var={knobs['n_var']}, n_obj={knobs['n_obj']}, "
        f"p={knobs['partitions']}, pop={knobs['pop']}, gens={knobs['gens']}, "
        f"PymooCompatible / pymoo NSGA-III; sibling `{knobs['sibling']}`)"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--problems",
        nargs="+",
        default=list(CATALOG_PROBLEMS),
        choices=CATALOG_PROBLEMS,
    )
    parser.add_argument(
        "--seeds",
        nargs="+",
        type=int,
        default=list(range(1, 16)),
        help="seeds to run (default 1–15)",
    )
    parser.add_argument("--stacks", nargs="+", default=list(STACKS), choices=STACKS)
    parser.add_argument("--reuse", action="store_true")
    parser.add_argument("--out-dir", type=Path, default=OUT)
    parser.add_argument("--summary", type=Path, default=None)
    parser.add_argument("--markdown", type=Path, default=None)
    args = parser.parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    summary_path = args.summary or (args.out_dir / "summary.jsonl")

    rows: list[dict] = []
    for problem in args.problems:
        knobs = catalog_knobs(problem)
        partitions = int(knobs["partitions"])
        pop = int(knobs["pop"])
        gens = int(knobs["gens"])
        for seed in args.seeds:
            for stack in args.stacks:
                dest = (
                    args.out_dir
                    / f"{stack}_{problem}_p{partitions}_pop{pop}_g{gens}_s{seed}_pymoo_F.csv"
                )
                dump = dump_catalog(
                    stack, problem, partitions, pop, gens, seed, dest, args.reuse
                )
                rec: dict = {
                    "stack": stack,
                    "problem": problem,
                    "partitions": partitions,
                    "pop": pop,
                    "gens": gens,
                    "seed": seed,
                    "tournament": "pymoo",
                    "n_var": knobs["n_var"],
                    "n_obj": knobs["n_obj"],
                    "sibling": knobs["sibling"],
                    "front": dump.get("front"),
                    "skipped": not dump.get("dumped"),
                    "skip": dump.get("skip"),
                    "reused": bool(dump.get("reused")),
                }
                if dump.get("dumped"):
                    rec.update(score_front(dest, problem, partitions))
                rows.append(rec)
                print(json.dumps(rec, sort_keys=True), flush=True)

    summary_path.parent.mkdir(parents=True, exist_ok=True)
    with summary_path.open("w", encoding="utf-8") as fh:
        for rec in rows:
            fh.write(json.dumps(rec, sort_keys=True) + "\n")
    print(f"wrote {summary_path} ({len(rows)} rows)", file=sys.stderr)

    tables = [CONSTRAINT_MD, ""]
    for problem in args.problems:
        knobs = catalog_knobs(problem)
        body = markdown_table(rows, problem, knobs)
        lines = body.splitlines()
        if lines:
            lines[0] = heading(problem, knobs)
        tables.append("\n".join(lines))
    absent = ", ".join(CONSTRAINED_ABSENT)
    tables.append(
        f"Constrained names not dumped by this catalog driver: {absent}. "
        "See docs/CONSTRAINED-SURFACES.md.\n"
    )
    md = "\n".join(tables)
    print(md)
    if args.markdown is not None:
        args.markdown.parent.mkdir(parents=True, exist_ok=True)
        args.markdown.write_text(md, encoding="utf-8")
        print(f"wrote {args.markdown}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
