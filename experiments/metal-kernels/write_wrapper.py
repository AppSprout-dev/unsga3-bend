#!/usr/bin/env python3
"""Write a tiny Bend main that calls assoc_map.run with baked Nat literals."""
from __future__ import annotations

import argparse
from pathlib import Path


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--out", type=Path, required=True)
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
    kind = "bang" if args.bang else "product"
    args.out.write_text(
        "# Generated wrapper ({kind}). Isolated experiment, not Run.\n"
        "import Base\n"
        "import ./assoc_map.bend as M\n"
        "\n"
        "def main() -> IO(Unit):\n"
        "  M.run({n}n, {r}n, {m}n, {seed}n, {warmup}n, {reps}n, {dump}n, {bang})\n"
        .format(
            kind=kind,
            n=args.n,
            r=args.r,
            m=args.m,
            seed=args.seed,
            warmup=args.warmup,
            reps=args.reps,
            dump=args.dump,
            bang=bang,
        ),
        encoding="utf-8",
    )
    print(args.out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
