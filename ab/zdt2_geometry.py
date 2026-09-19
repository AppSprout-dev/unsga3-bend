#!/usr/bin/env python3
"""How analytic ZDT1/ZDT2 PFs associate to Das–Dennis rays (no algorithm).

This is geometry, not a Run. Used by docs/ZDT2_COLLAPSE.md to show that a
true ZDT2 PF occupies many rays — collapse is not “the PF is one ray.”
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from characterize_front import associate, das_dennis_2, zdt_pf


def pf_on_simplex(problem: str, t: float) -> float:
    """f1+f2 on the analytic PF (unit-box, g=1)."""
    if problem == "zdt1":
        return t + (1.0 - math.sqrt(t))
    return t + (1.0 - t * t)


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--partitions", type=int, default=12)
    p.add_argument("--pf-points", type=int, default=500)
    args = p.parse_args()
    dirs = das_dennis_2(args.partitions)
    out: dict = {"partitions": args.partitions, "n_refs": len(dirs), "problems": {}}
    for name in ("zdt1", "zdt2"):
        pf = zdt_pf(name, args.pf_points)
        refs = associate(pf, dirs)
        hist: dict[str, int] = {}
        for r in refs:
            hist[str(r)] = hist.get(str(r), 0) + 1
        mid_t = [i / (args.pf_points - 1) for i in range(args.pf_points)]
        simplex = [pf_on_simplex(name, t) for t in mid_t]
        out["problems"][name] = {
            "occupied_refs": len(hist),
            "ref_hist": dict(sorted(hist.items(), key=lambda kv: int(kv[0]))),
            "f1_plus_f2_min": min(simplex),
            "f1_plus_f2_max": max(simplex),
            "vs_simplex": (
                "inside (convex; f1+f2 ≤ 1 on PF)"
                if max(simplex) <= 1.0 + 1e-12
                else "outside (concave; f1+f2 > 1 in the middle)"
            ),
        }
    print(json.dumps(out, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
