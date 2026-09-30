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

import numpy as np

from protocol import (
    CATALOG_PROBLEMS,
    catalog_bounds,
    catalog_knobs,
    catalog_n_obj,
    catalog_n_var,
    default_gens,
    default_pop,
    n_obj,
    n_var,
)

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "ab" / "out"


def skip(msg: str) -> int:
    print(f"skip: {msg}", file=sys.stderr)
    return 0


def decision_dims(problem: str) -> tuple[int, int]:
    if problem in CATALOG_PROBLEMS:
        return catalog_n_obj(problem), catalog_n_var(problem)
    return n_obj(problem), n_var(problem)


def bounds_skip(pymoo_prob, problem: str) -> str | None:
    """Return a reason when pymoo's box is not the Bend / C# box."""
    if problem not in CATALOG_PROBLEMS:
        return None
    xl = np.asarray(pymoo_prob.xl, dtype=float).reshape(-1)
    xu = np.asarray(pymoo_prob.xu, dtype=float).reshape(-1)
    exp_xl, exp_xu = catalog_bounds(problem)
    exp_xl_a = np.asarray(exp_xl, dtype=float)
    exp_xu_a = np.asarray(exp_xu, dtype=float)
    if (
        xl.shape != exp_xl_a.shape
        or not np.allclose(xl, exp_xl_a)
        or not np.allclose(xu, exp_xu_a)
    ):
        return (
            f"pymoo {problem} bounds xl0={float(xl[0])} xu0={float(xu[0])} "
            f"n={int(xl.shape[0])} differ from Bend/C# xl0={exp_xl[0]} xu0={exp_xu[0]} "
            f"n={len(exp_xl)}. Refusing to score a different problem."
        )
    return None


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

    m, nv = decision_dims(problem)
    if problem == "dtlz2":
        pymoo_prob = get_problem("dtlz2", n_obj=m, n_var=nv)
    elif problem in ("zdt1", "zdt2"):
        pymoo_prob = get_problem(problem)
    else:
        try:
            if problem.startswith("dtlz"):
                pymoo_prob = get_problem(problem, n_obj=m, n_var=nv)
            elif problem in ("sphere", "ackley", "rosenbrock"):
                pymoo_prob = get_problem(problem, n_var=nv)
            else:
                pymoo_prob = get_problem(problem, n_var=nv)
        except Exception as exc:
            return skip(
                f"pymoo get_problem({problem}) failed ({exc}). "
                "Refusing to invent a front."
            )
        mismatch = bounds_skip(pymoo_prob, problem)
        if mismatch:
            return skip(mismatch)

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

    front = np.asarray(res.F, dtype=float)
    if front.ndim == 1:
        # Single-objective res.F is squeezed to shape (n,).
        front = front.reshape(-1, 1) if m == 1 else front.reshape(1, -1)
    if front.ndim != 2 or front.shape[1] != m:
        return skip(
            f"pymoo NSGA-III F shape {tuple(front.shape)} is not (rows, {m}). "
            "Refusing to invent a front."
        )

    dest.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        f"# run: {problem} n_obj={m} partitions={partitions} pop={pop} "
        f"gens={gens} seed={seed} tournament=none source=pymoo-nsga3 "
        f"sbx_eta=30 pc=1.0 pm_eta=20 pm={1.0 / nv}"
    ]
    for row in front:
        lines.append(",".join(f"{float(x):.17g}" for x in row))
    dest.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {dest} ({len(front)} front rows)", file=sys.stderr)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--problem",
        choices=("zdt1", "zdt2", "dtlz2", *CATALOG_PROBLEMS),
        default="zdt1",
    )
    parser.add_argument("--partitions", type=int, default=None)
    parser.add_argument("--pop", type=int, default=None)
    parser.add_argument(
        "--gens",
        type=int,
        default=None,
        help="generations (default: zdt2=250, dtlz2=150, zdt1=100; "
        "catalog names use catalog_knobs, not the 4/8/3 smoke)",
    )
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--out", type=Path, default=OUT_DIR / "pymoo_nsga3_F.csv")
    args = parser.parse_args()

    problem = args.problem
    if problem in CATALOG_PROBLEMS:
        knobs = catalog_knobs(problem)
        partitions = args.partitions if args.partitions is not None else int(knobs["partitions"])
        pop = args.pop if args.pop is not None else int(knobs["pop"])
        gens = args.gens if args.gens is not None else int(knobs["gens"])
    else:
        partitions = args.partitions if args.partitions is not None else 12
        pop = args.pop if args.pop is not None else default_pop(problem)
        gens = args.gens if args.gens is not None else default_gens(problem)
    return dump(args.out, problem, partitions, pop, gens, args.seed)


if __name__ == "__main__":
    raise SystemExit(main())
