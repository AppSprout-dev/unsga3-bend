#!/usr/bin/env python3
"""Dump a pymoo NSGA-III front under the public A/B knobs.

Same operators as docs/EQUIVALENCE.md: SBX η=30, p_c=1.0; PM η=20, p_m=1/n;
Das–Dennis refs at --partitions; eliminate_duplicates=True.

This is pymoo **NSGA-III** (no U-NSGA-III tournament). C# published tables
compare to pymoo UNSGA3; this dumper is the NSGA-III column for
ab/oracle_multiseed.py. Scores live in ab/igd_vs_pymoo.py — this script
only writes the front CSV.

Skips (exit 0) when pymoo is missing. Never invents a front.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from protocol import default_gens, default_pop, n_obj, n_var

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "ab" / "out"


def skip(msg: str) -> int:
    print(f"skip: {msg}", file=sys.stderr)
    return 0


def dump(
    dest: Path,
    problem: str,
    partitions: int,
    pop: int,
    gens: int,
    seed: int,
) -> int:
    try:
        from pymoo.algorithms.moo.nsga3 import NSGA3
        from pymoo.operators.crossover.sbx import SBX
        from pymoo.operators.mutation.pm import PM
        from pymoo.optimize import minimize
        from pymoo.problems import get_problem
        from pymoo.util.ref_dirs import get_reference_directions
    except ImportError:
        return skip(
            "pymoo is not installed; pymoo NSGA-III dump not run. "
            "Install pymoo to dump a real front."
        )

    m = n_obj(problem)
    nv = n_var(problem)
    if problem == "dtlz2":
        pymoo_prob = get_problem("dtlz2", n_obj=m, n_var=nv)
    else:
        pymoo_prob = get_problem(problem)

    ref_dirs = get_reference_directions("das-dennis", m, n_partitions=partitions)
    algo = NSGA3(
        ref_dirs,
        pop_size=pop,
        crossover=SBX(eta=30, prob=1.0),
        mutation=PM(eta=20, prob=1.0 / nv),
        eliminate_duplicates=True,
    )
    res = minimize(
        pymoo_prob,
        algo,
        ("n_gen", gens),
        seed=seed,
        verbose=False,
        save_history=False,
    )
    if res.F is None:
        return skip("pymoo NSGA-III returned no F. Refusing to invent a front.")

    dest.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        f"# run: {problem} n_obj={m} partitions={partitions} pop={pop} "
        f"gens={gens} seed={seed} tournament=none source=pymoo-nsga3 "
        f"sbx_eta=30 pc=1.0 pm_eta=20 pm={1.0 / nv}"
    ]
    for row in res.F:
        lines.append(",".join(f"{float(x):.17g}" for x in row))
    dest.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {dest} ({len(res.F)} front rows)", file=sys.stderr)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--problem", choices=("zdt1", "zdt2", "dtlz2"), default="zdt1")
    parser.add_argument("--partitions", type=int, default=None)
    parser.add_argument("--pop", type=int, default=None)
    parser.add_argument(
        "--gens",
        type=int,
        default=None,
        help="generations (default: zdt2=250, dtlz2=150, else 100)",
    )
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--out", type=Path, default=OUT_DIR / "pymoo_nsga3_F.csv")
    args = parser.parse_args()

    problem = args.problem
    partitions = args.partitions if args.partitions is not None else 12
    pop = args.pop if args.pop is not None else default_pop(problem)
    gens = args.gens if args.gens is not None else default_gens(problem)
    return dump(args.out, problem, partitions, pop, gens, args.seed)


if __name__ == "__main__":
    raise SystemExit(main())
