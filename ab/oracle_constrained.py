#!/usr/bin/env python3
"""Measured IGD for OSY / TNK / C1-DTLZ1.

Knobs are ``constrained_knobs`` (PymooCompatible). C# NEW-SURFACES used
RankNicheDistance; this script does not switch the A/B default and does
not copy those numbers.

Bend dumps the feasible non-dominated set (``Algo.feas_nd``). pymoo
NSGA-III, when installed, dumps the same filter. C# is ``skip:`` unless
``UNSGA3_CS_ROOT`` is set — and even then this tree has no constrained
C# dumper (``OracleCompare`` does not accept these names).

Every cell is ``igd=`` or ``skip:``. No HV / Wilcoxon.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

from protocol import CONSTRAINED_PROBLEMS, constrained_knobs

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "ab" / "out" / "constrained"


def run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, check=False, capture_output=True, text=True)


def igd_of(front: Path, problem: str, partitions: int) -> str:
    if not front.is_file():
        return "skip: front file missing"
    text = front.read_text(encoding="utf-8")
    rows = [
        ln.strip()
        for ln in text.splitlines()
        if ln.strip() and not ln.strip().startswith("#")
    ]
    if not rows:
        return "skip: no feasible points"
    proc = run(
        [
            sys.executable,
            str(ROOT / "ab" / "igd_vs_pymoo.py"),
            "--front",
            str(front),
            "--problem",
            problem,
            "--partitions",
            str(partitions),
        ]
    )
    blob = (proc.stdout or "") + (proc.stderr or "")
    for ln in blob.splitlines():
        if ln.startswith("igd=") or ln.startswith("skip:"):
            return ln.strip()
    return f"skip: igd scorer failed rc={proc.returncode}"


def dump_bend(problem: str, knobs: dict, seed: int, dest: Path) -> str | None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    proc = run(
        [
            sys.executable,
            str(ROOT / "ab" / "dump_bend_run.py"),
            "--native",
            "--problem",
            problem,
            "--partitions",
            str(knobs["partitions"]),
            "--pop",
            str(knobs["pop"]),
            "--gens",
            str(knobs["gens"]),
            "--seed",
            str(seed),
            "--tournament",
            "pymoo",
            "--out",
            str(dest),
        ]
    )
    err = proc.stderr or ""
    sys.stderr.write(err)
    if proc.returncode != 0 or not dest.is_file():
        fault = "bend dump failed"
        for ln in err.splitlines():
            if "fail-stop" in ln or "memory fault" in ln or "stack overflow" in ln:
                fault = ln.strip()
        return f"skip: {fault} rc={proc.returncode}"
    return None


def dump_pymoo(problem: str, knobs: dict, seed: int, dest: Path) -> str | None:
    proc = run(
        [
            sys.executable,
            str(ROOT / "ab" / "dump_pymoo_nsga3.py"),
            "--problem",
            problem,
            "--partitions",
            str(knobs["partitions"]),
            "--pop",
            str(knobs["pop"]),
            "--gens",
            str(knobs["gens"]),
            "--seed",
            str(seed),
            "--out",
            str(dest),
        ]
    )
    sys.stderr.write(proc.stderr or "")
    blob = (proc.stdout or "") + (proc.stderr or "")
    for ln in blob.splitlines():
        if ln.startswith("skip:"):
            return ln.strip()
    if proc.returncode != 0 or not dest.is_file():
        return f"skip: pymoo dump failed rc={proc.returncode}"
    return None


def csharp_cell() -> str:
    if not os.environ.get("UNSGA3_CS_ROOT"):
        return "skip: UNSGA3_CS_ROOT unset; this tree does not clone Unsga3"
    return "skip: no constrained C# dumper (OracleCompare does not accept these names)"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--problems", nargs="+", default=list(CONSTRAINED_PROBLEMS))
    parser.add_argument("--seeds", nargs="+", type=int, default=[1])
    parser.add_argument("--markdown", type=Path, default=None)
    args = parser.parse_args()

    lines = [
        "| problem | seed | Bend | C# | pymoo NSGA-III |",
        "|---------|-----:|------|----|----------------|",
    ]
    for problem in args.problems:
        knobs = constrained_knobs(problem)
        for seed in args.seeds:
            bend_path = OUT / f"bend_{problem}_s{seed}.csv"
            pymoo_path = OUT / f"pymoo_{problem}_s{seed}.csv"
            bend_err = dump_bend(problem, knobs, seed, bend_path)
            bend_cell = bend_err or igd_of(bend_path, problem, int(knobs["partitions"]))
            pymoo_err = dump_pymoo(problem, knobs, seed, pymoo_path)
            pymoo_cell = pymoo_err or igd_of(pymoo_path, problem, int(knobs["partitions"]))
            row = f"| {problem} | {seed} | {bend_cell} | {csharp_cell()} | {pymoo_cell} |"
            lines.append(row)
            print(row, flush=True)
    text = "\n".join(lines) + "\n"
    print(text)
    if args.markdown is not None:
        args.markdown.parent.mkdir(parents=True, exist_ok=True)
        args.markdown.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
