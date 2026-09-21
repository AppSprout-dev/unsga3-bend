#!/usr/bin/env python3
"""Multi-seed IGD table: Bend vs C# Unsga3 vs pymoo NSGA-III.

Public protocol knobs (docs/EQUIVALENCE.md, ab/protocol.py) — always
passed explicitly (no omitted-flag traps):

  ZDT1  p=12 pop=52 gens=100  PymooCompatible
  ZDT2  p=12 pop=52 gens=250  PymooCompatible
  DTLZ2 p=12 pop=92 gens=150  PymooCompatible

Every dumped front is scored with the same yardstick:
  python3 ab/igd_vs_pymoo.py --front … --problem … --pf-points 500 --partitions 12

Never invents IGD. Missing Bend / C# / pymoo prints skip: and leaves
that cell blank. Reuses dump_bend_run.py --native (warm cache),
dump_csharp_run.py, dump_pymoo_nsga3.py.

Examples:

  python3 ab/oracle_multiseed.py
  python3 ab/oracle_multiseed.py --problems zdt1 --seeds 1 --stacks bend pymoo
  python3 ab/oracle_multiseed.py --reuse --markdown docs/ORACLE-MULTISEED.md
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

from protocol import oracle_knobs

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "ab" / "out" / "oracle_multiseed"
DUMP_BEND = ROOT / "ab" / "dump_bend_run.py"
DUMP_CS = ROOT / "ab" / "dump_csharp_run.py"
DUMP_PYMOO = ROOT / "ab" / "dump_pymoo_nsga3.py"
IGD = ROOT / "ab" / "igd_vs_pymoo.py"

STACKS = ("bend", "csharp", "pymoo")
PROBLEMS = ("zdt1", "zdt2", "dtlz2")
IGD_RE = re.compile(r"^igd=([0-9eE.+-]+)$", re.M)
KV_RE = re.compile(r"^([a-z_]+)=(.*)$", re.M)


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


def stem(stack: str, problem: str, partitions: int, pop: int, gens: int, seed: int) -> str:
    return f"{stack}_{problem}_p{partitions}_pop{pop}_g{gens}_s{seed}_pymoo"


def score_front(front: Path, problem: str, partitions: int) -> dict:
    proc = run_py(
        IGD,
        [
            "--front",
            str(front),
            "--problem",
            problem,
            "--pf-points",
            "500",
            "--partitions",
            str(partitions),
        ],
    )
    text = (proc.stdout or "") + "\n" + (proc.stderr or "")
    if "skip:" in text:
        skip_line = next(
            (ln.strip() for ln in text.splitlines() if ln.strip().startswith("skip:")),
            "skip: igd_vs_pymoo",
        )
        return {"skipped": True, "skip": skip_line}
    meta = {k: v for k, v in KV_RE.findall(proc.stdout or "")}
    igd_m = IGD_RE.search(proc.stdout or "")
    if igd_m is None:
        return {"skipped": True, "skip": "skip: igd_vs_pymoo printed no igd= line"}
    rec = {
        "skipped": False,
        "igd": float(igd_m.group(1)),
        "front_rows": int(meta["front_rows"]) if "front_rows" in meta else None,
        "pf_rows": int(meta["pf_rows"]) if "pf_rows" in meta else None,
        "pf_source": meta.get("pf_source"),
    }
    if "partitions" in meta:
        rec["pf_partitions"] = int(meta["partitions"])
    return rec


def dump_stack(
    stack: str,
    problem: str,
    partitions: int,
    pop: int,
    gens: int,
    seed: int,
    dest: Path,
    reuse: bool,
) -> dict:
    if reuse and dest.is_file() and dest.stat().st_size > 0:
        return {"dumped": True, "reused": True, "front": str(dest)}

    if stack == "bend":
        extra = [
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
            "pymoo",
            "--out",
            str(dest),
        ]
        proc = run_py(DUMP_BEND, extra)
        sys.stderr.write(proc.stderr or "")
        if proc.returncode != 0:
            return {
                "dumped": False,
                "skip": f"skip: bend dump failed rc={proc.returncode}",
            }
        if not dest.is_file():
            return {"dumped": False, "skip": "skip: bend CSV not written"}
        return {"dumped": True, "front": str(dest), "stderr": proc.stderr or ""}

    if stack == "csharp":
        if not os.environ.get("UNSGA3_CS_ROOT", "").strip():
            return {
                "dumped": False,
                "skip": "skip: UNSGA3_CS_ROOT unset; C# dump is optional",
            }
        extra = [
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
            "pymoo",
            "--out",
            str(dest),
        ]
        proc = run_py(DUMP_CS, extra)
        sys.stderr.write(proc.stderr or "")
        err = (proc.stderr or "").strip()
        if err.startswith("skip:") or not dest.is_file():
            return {
                "dumped": False,
                "skip": err.splitlines()[-1] if err else "skip: C# dump absent",
            }
        return {"dumped": True, "front": str(dest)}

    if stack == "pymoo":
        extra = [
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
            "--out",
            str(dest),
        ]
        proc = run_py(DUMP_PYMOO, extra)
        sys.stderr.write(proc.stderr or "")
        err = (proc.stderr or "").strip()
        if err.startswith("skip:") or not dest.is_file():
            return {
                "dumped": False,
                "skip": err.splitlines()[-1] if err else "skip: pymoo NSGA-III dump absent",
            }
        return {"dumped": True, "front": str(dest)}

    return {"dumped": False, "skip": f"skip: unknown stack {stack}"}


def fmt_igd(val: float | None) -> str:
    if val is None:
        return ""
    return f"{val:.6f}"


def median(xs: list[float]) -> float | None:
    if not xs:
        return None
    s = sorted(xs)
    n = len(s)
    if n % 2:
        return s[n // 2]
    return 0.5 * (s[n // 2 - 1] + s[n // 2])


def markdown_table(rows: list[dict], problem: str, knobs: dict) -> str:
    seeds = sorted({r["seed"] for r in rows if r["problem"] == problem})
    by: dict[tuple[str, int], dict] = {
        (r["stack"], r["seed"]): r for r in rows if r["problem"] == problem
    }
    lines = [
        f"### {problem.upper()} (p={knobs['partitions']}, pop={knobs['pop']}, "
        f"gens={knobs['gens']}, PymooCompatible / pymoo NSGA-III)",
        "",
        "| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |",
        "|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|",
    ]
    igds: dict[str, list[float]] = {s: [] for s in STACKS}
    pf_rows = None
    pf_source = None
    for seed in seeds:
        cells = {}
        ns = {}
        for stack in STACKS:
            rec = by.get((stack, seed), {})
            if rec.get("skipped") or rec.get("igd") is None:
                cells[stack] = rec.get("skip", "skip:") if rec else ""
                ns[stack] = ""
            else:
                cells[stack] = fmt_igd(rec["igd"])
                ns[stack] = str(rec.get("front_rows") or "")
                igds[stack].append(float(rec["igd"]))
                pf_rows = rec.get("pf_rows") or pf_rows
                pf_source = rec.get("pf_source") or pf_source
        bend_igd = by.get(("bend", seed), {}).get("igd")
        cs_igd = by.get(("csharp", seed), {}).get("igd")
        py_igd = by.get(("pymoo", seed), {}).get("igd")
        ratio_cs = (
            f"{bend_igd / cs_igd:.3f}"
            if isinstance(bend_igd, float) and isinstance(cs_igd, float) and cs_igd
            else ""
        )
        ratio_py = (
            f"{bend_igd / py_igd:.3f}"
            if isinstance(bend_igd, float) and isinstance(py_igd, float) and py_igd
            else ""
        )
        lines.append(
            f"| {seed} | {cells['bend']} | {cells['csharp']} | {cells['pymoo']} "
            f"| {ratio_cs} | {ratio_py} | {ns['bend']} | {ns['csharp']} | {ns['pymoo']} |"
        )
    lines.append("")
    med = {s: median(igds[s]) for s in STACKS}
    ran = {s: sorted({r["seed"] for r in rows if r["problem"] == problem and r["stack"] == s and not r.get("skipped") and r.get("igd") is not None}) for s in STACKS}
    lines.append(
        f"Seeds actually scored: Bend {ran['bend'] or 'none'}; "
        f"C# {ran['csharp'] or 'none'}; pymoo {ran['pymoo'] or 'none'}."
    )
    med_bits = []
    for s, label in (("bend", "Bend"), ("csharp", "C#"), ("pymoo", "pymoo NSGA-III")):
        if med[s] is not None:
            med_bits.append(f"{label} {fmt_igd(med[s])}")
    if med_bits:
        lines.append("Median IGD (" + ", ".join(med_bits) + ").")
    if pf_rows is not None or pf_source:
        extra = []
        if pf_source:
            extra.append(f"pf_source=`{pf_source}`")
        if pf_rows is not None:
            extra.append(f"pf_rows={pf_rows}")
        extra.append(f"partitions={knobs['partitions']}")
        lines.append("PF yardstick: " + ", ".join(extra) + ".")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--problems", nargs="+", default=list(PROBLEMS), choices=PROBLEMS)
    parser.add_argument(
        "--seeds",
        nargs="+",
        type=int,
        default=list(range(1, 16)),
        help="seeds to run (default 1–15)",
    )
    parser.add_argument("--stacks", nargs="+", default=list(STACKS), choices=STACKS)
    parser.add_argument(
        "--reuse",
        action="store_true",
        help="reuse an existing non-empty CSV instead of re-dumping",
    )
    parser.add_argument("--out-dir", type=Path, default=OUT)
    parser.add_argument(
        "--summary",
        type=Path,
        default=None,
        help="JSONL path (default: <out-dir>/summary.jsonl)",
    )
    parser.add_argument(
        "--markdown",
        type=Path,
        default=None,
        help="optional markdown tables path (does not invent numbers)",
    )
    args = parser.parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    summary_path = args.summary or (args.out_dir / "summary.jsonl")

    rows: list[dict] = []
    for problem in args.problems:
        knobs = oracle_knobs(problem)
        partitions = int(knobs["partitions"])
        pop = int(knobs["pop"])
        gens = int(knobs["gens"])
        for seed in args.seeds:
            for stack in args.stacks:
                dest = args.out_dir / f"{stem(stack, problem, partitions, pop, gens, seed)}_F.csv"
                dump = dump_stack(
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
                    "front": dump.get("front"),
                    "skipped": not dump.get("dumped"),
                    "skip": dump.get("skip"),
                    "reused": bool(dump.get("reused")),
                }
                if dump.get("dumped"):
                    rec.update(score_front(dest, problem, partitions))
                    # score_front may set skipped if IGD cannot run
                rows.append(rec)
                print(json.dumps(rec, sort_keys=True), flush=True)

    summary_path.parent.mkdir(parents=True, exist_ok=True)
    with summary_path.open("w", encoding="utf-8") as fh:
        for rec in rows:
            fh.write(json.dumps(rec, sort_keys=True) + "\n")
    print(f"wrote {summary_path} ({len(rows)} rows)", file=sys.stderr)

    tables = []
    for problem in args.problems:
        tables.append(markdown_table(rows, problem, oracle_knobs(problem)))
    md = "\n".join(tables)
    print(md)
    if args.markdown is not None:
        args.markdown.parent.mkdir(parents=True, exist_ok=True)
        args.markdown.write_text(md, encoding="utf-8")
        print(f"wrote {args.markdown}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
