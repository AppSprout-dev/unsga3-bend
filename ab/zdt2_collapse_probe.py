#!/usr/bin/env python3
"""Dump + characterize ZDT2 (or ZDT1) fronts for collapse investigation.

Runs existing dumpers; does not change U-NSGA-III math. Writes CSVs under
ab/out/zdt2_probe/ and a JSONL summary. C# / pymoo legs skip cleanly when
UNSGA3_CS_ROOT / pymoo are missing. No invented fronts.

Examples:

  python3 ab/zdt2_collapse_probe.py
  python3 ab/zdt2_collapse_probe.py --stacks bend csharp --seeds 1 2 7 11 \\
      --gens 10 50 100 --tournament pymoo
  python3 ab/zdt2_collapse_probe.py --stacks pymoo --seeds 1 7 --gens 100
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "ab" / "out" / "zdt2_probe"
DUMP_BEND = ROOT / "ab" / "dump_bend_run.py"
DUMP_CS = ROOT / "ab" / "dump_csharp_run.py"

# Local import of characterize (same directory).
sys.path.insert(0, str(ROOT / "ab"))
from characterize_front import characterize, load_csv  # noqa: E402


def run_py(script: Path, extra: list[str]) -> int:
    env = os.environ.copy()
    env.setdefault("BEND_NO_TELEMETRY", "1")
    path = env.get("PATH", "")
    home_bend = str(Path.home() / ".bend" / "bin")
    home_dotnet = str(Path.home() / ".dotnet")
    for extra_p in (home_bend, home_dotnet):
        if extra_p not in path.split(":"):
            path = extra_p + ":" + path
    env["PATH"] = path
    env.setdefault("DOTNET_ROOT", home_dotnet)
    proc = subprocess.run(
        [sys.executable, str(script), *extra],
        cwd=str(ROOT),
        env=env,
        check=False,
    )
    return proc.returncode


def dump_pymoo(
    dest: Path,
    problem: str,
    partitions: int,
    pop: int,
    gens: int,
    seed: int,
) -> int:
    try:
        from pymoo.algorithms.moo.unsga3 import UNSGA3
        from pymoo.optimize import minimize
        from pymoo.problems import get_problem
        from pymoo.util.ref_dirs import get_reference_directions
    except ImportError:
        print("skip: pymoo is not installed", file=sys.stderr)
        return 0

    dest.parent.mkdir(parents=True, exist_ok=True)
    ref_dirs = get_reference_directions("das-dennis", 2, n_partitions=partitions)
    algo = UNSGA3(ref_dirs, pop_size=pop)
    res = minimize(
        get_problem(problem),
        algo,
        ("n_gen", gens),
        seed=seed,
        verbose=False,
    )
    if res.F is None:
        print("skip: pymoo returned no F", file=sys.stderr)
        return 0
    lines = [
        f"# run: {problem} n_obj=2 partitions={partitions} pop={pop} "
        f"gens={gens} seed={seed} tournament=PymooCompatible source=pymoo"
    ]
    for row in res.F:
        lines.append(",".join(f"{float(x):.17g}" for x in row))
    dest.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {dest} ({len(res.F)} front rows)", file=sys.stderr)
    return 0


def one_dump(
    stack: str,
    problem: str,
    partitions: int,
    pop: int,
    gens: int,
    seed: int,
    tournament: str,
) -> Path | None:
    stem = f"{stack}_{problem}_p{partitions}_pop{pop}_g{gens}_s{seed}_{tournament}"
    dest = OUT / f"{stem}_F.csv"
    dest.parent.mkdir(parents=True, exist_ok=True)
    if stack == "bend":
        rc = run_py(
            DUMP_BEND,
            [
                "--native",
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
                "--tournament",
                tournament,
                "--out",
                str(dest),
            ],
        )
        if rc != 0:
            print(f"skip: bend dump failed rc={rc} {dest}", file=sys.stderr)
            return None
        return dest
    if stack == "csharp":
        if not os.environ.get("UNSGA3_CS_ROOT", "").strip():
            print("skip: UNSGA3_CS_ROOT unset", file=sys.stderr)
            return None
        rc = run_py(
            DUMP_CS,
            [
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
                "--tournament",
                tournament,
                "--out",
                str(dest),
            ],
        )
        if rc != 0:
            print(f"skip: csharp dump failed rc={rc} {dest}", file=sys.stderr)
            return None
        if not dest.is_file():
            return None
        return dest
    if stack == "pymoo":
        if tournament != "pymoo":
            print(
                "skip: pymoo UNSGA3 dump is PymooCompatible only "
                f"(asked {tournament})",
                file=sys.stderr,
            )
            return None
        rc = dump_pymoo(dest, problem, partitions, pop, gens, seed)
        if rc != 0 or not dest.is_file():
            return None
        return dest
    print(f"skip: unknown stack {stack}", file=sys.stderr)
    return None


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "--stacks",
        nargs="+",
        default=["bend", "csharp"],
        choices=("bend", "csharp", "pymoo"),
    )
    p.add_argument("--problem", default="zdt2", choices=("zdt1", "zdt2"))
    p.add_argument("--partitions", type=int, default=12)
    p.add_argument("--pop", type=int, default=52)
    p.add_argument("--seeds", nargs="+", type=int, default=[1, 2, 7, 11])
    p.add_argument("--gens", nargs="+", type=int, default=[10, 50, 100])
    p.add_argument(
        "--tournament",
        default="pymoo",
        choices=("pymoo", "rank_niche"),
    )
    p.add_argument(
        "--summary",
        type=Path,
        default=OUT / "summary.jsonl",
    )
    args = p.parse_args()

    rows: list[dict] = []
    for stack in args.stacks:
        for seed in args.seeds:
            for gens in args.gens:
                dest = one_dump(
                    stack,
                    args.problem,
                    args.partitions,
                    args.pop,
                    gens,
                    seed,
                    args.tournament,
                )
                rec: dict = {
                    "stack": stack,
                    "problem": args.problem,
                    "partitions": args.partitions,
                    "pop": args.pop,
                    "gens": gens,
                    "seed": seed,
                    "tournament": args.tournament,
                    "front": None if dest is None else str(dest),
                    "skipped": dest is None,
                }
                if dest is not None and dest.is_file():
                    front = load_csv(dest)
                    rec.update(
                        characterize(
                            front,
                            args.problem,
                            args.partitions,
                            500,
                        )
                    )
                rows.append(rec)
                print(json.dumps(rec, sort_keys=True), flush=True)

    args.summary.parent.mkdir(parents=True, exist_ok=True)
    with args.summary.open("w", encoding="utf-8") as fh:
        for rec in rows:
            fh.write(json.dumps(rec, sort_keys=True) + "\n")
    print(f"wrote {args.summary} ({len(rows)} rows)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
