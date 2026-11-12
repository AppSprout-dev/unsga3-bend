#!/usr/bin/env python3
"""Write a tiny Bend main that calls assoc_array.run with baked Nat literals."""
from __future__ import annotations

import argparse
from pathlib import Path

KIND = {"list": 0, "clone": 1, "fork": 2}


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--out", type=Path, required=True)
    p.add_argument("--kind", choices=sorted(KIND), required=True)
    p.add_argument("--chunk", type=int, default=32)
    p.add_argument("--bang", action="store_true")
    p.add_argument("--n", type=int, required=True)
    p.add_argument("--r", type=int, required=True)
    p.add_argument("--m", type=int, default=3)
    p.add_argument("--seed", type=int, default=1)
    p.add_argument("--warmup", type=int, default=1)
    p.add_argument("--reps", type=int, default=5)
    p.add_argument("--dump", type=int, default=0)
    args = p.parse_args()
    bang = "True{}" if args.bang else "False{}"
    args.out.write_text(
        "# Generated wrapper ({kind}, chunk={chunk}, bang={bang_flag}).\n"
        "# Isolated Array.clone/fork experiment, not Run.\n"
        "import Base\n"
        "import ./assoc_array.bend as A\n"
        "\n"
        "def main() -> IO(Unit):\n"
        "  A.run({n}n, {r}n, {m}n, {seed}n, {warmup}n, {reps}n, {dump}n, {bang}, {kind_n}n, {chunk}n)\n"
        .format(
            kind=args.kind,
            chunk=args.chunk,
            bang_flag=int(args.bang),
            n=args.n,
            r=args.r,
            m=args.m,
            seed=args.seed,
            warmup=args.warmup,
            reps=args.reps,
            dump=args.dump,
            bang=bang,
            kind_n=KIND[args.kind],
        ),
        encoding="utf-8",
    )
    print(args.out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
