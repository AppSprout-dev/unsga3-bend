#!/usr/bin/env python3
"""Characterize a dumped 2-obj ND front (ZDT collapse geometry).

Reads a CSV of objective rows (optional `#` header). Does not invent IGD:
when pymoo is installed, IGD is pymoo's mean nearest-neighbor distance vs
the analytic PF. Without pymoo, IGD is the same formula in this file
(documented, not a made-up metric).

Prints one JSON object to stdout. Used by ab/zdt2_collapse_probe.py and
as a standalone helper for docs/ZDT2_COLLAPSE.md.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

# Same collapse rule as docs/PERF_NOTES.md / PR #16.
COLLAPSE_N = 10
COLLAPSE_IGD = 0.3


def load_csv(path: Path) -> list[list[float]]:
    rows: list[list[float]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        rows.append([float(x) for x in line.split(",")])
    return rows


def das_dennis_2(partitions: int) -> list[tuple[float, float]]:
    return [(k / partitions, (partitions - k) / partitions) for k in range(partitions + 1)]


def perp(f: list[float], w: tuple[float, float]) -> float:
    ww = w[0] * w[0] + w[1] * w[1]
    if ww < 1e-16:
        return math.sqrt(f[0] * f[0] + f[1] * f[1])
    t = (f[0] * w[0] + f[1] * w[1]) / ww
    dx = f[0] - t * w[0]
    dy = f[1] - t * w[1]
    return math.sqrt(dx * dx + dy * dy)


def associate(front: list[list[float]], dirs: list[tuple[float, float]]) -> list[int]:
    refs: list[int] = []
    for f in front:
        best_i = 0
        best_d = float("inf")
        for i, w in enumerate(dirs):
            d = perp(f, w)
            if d < best_d:
                best_d = d
                best_i = i
        refs.append(best_i)
    return refs


def minmax_norm(front: list[list[float]]) -> list[list[float]]:
    if not front:
        return []
    m = len(front[0])
    lo = [min(row[j] for row in front) for j in range(m)]
    hi = [max(row[j] for row in front) for j in range(m)]
    out: list[list[float]] = []
    for row in front:
        nr = []
        for j, v in enumerate(row):
            span = hi[j] - lo[j]
            nr.append(0.0 if span < 1e-12 else (v - lo[j]) / span)
        out.append(nr)
    return out


def zdt_pf(problem: str, n: int) -> list[list[float]]:
    if n < 2:
        n = 2
    pf = []
    for i in range(n):
        t = i / (n - 1)
        if problem == "zdt1":
            pf.append([t, 1.0 - math.sqrt(t)])
        else:
            pf.append([t, 1.0 - t * t])
    return pf


def igd_mean(front: list[list[float]], pf: list[list[float]]) -> float:
    """Mean nearest Euclidean distance from each PF point to the front."""
    if not front or not pf:
        return float("nan")
    total = 0.0
    for p in pf:
        best = min(sum((a - b) ** 2 for a, b in zip(p, f)) for f in front)
        total += math.sqrt(best)
    return total / len(pf)


def median(xs: list[float]) -> float:
    if not xs:
        return float("nan")
    s = sorted(xs)
    n = len(s)
    if n % 2:
        return s[n // 2]
    return 0.5 * (s[n // 2 - 1] + s[n // 2])


def characterize(
    front: list[list[float]],
    problem: str = "zdt2",
    partitions: int = 12,
    pf_points: int = 500,
) -> dict:
    n = len(front)
    if n == 0:
        return {
            "n": 0,
            "collapse": True,
            "note": "empty front",
        }
    if any(len(r) != 2 for r in front):
        return {
            "n": n,
            "n_obj": len(front[0]),
            "note": "characterize_front is for 2-obj ZDT fronts",
        }

    f1 = [r[0] for r in front]
    f2 = [r[1] for r in front]
    dirs = das_dennis_2(partitions)
    raw_refs = associate(front, dirs)
    norm_refs = associate(minmax_norm(front), dirs)

    def hist(refs: list[int]) -> dict[str, int]:
        h: dict[str, int] = {}
        for r in refs:
            h[str(r)] = h.get(str(r), 0) + 1
        return dict(sorted(h.items(), key=lambda kv: int(kv[0])))

    raw_h = hist(raw_refs)
    norm_h = hist(norm_refs)
    occupied = len(raw_h)
    max_niche = max(raw_h.values()) if raw_h else 0

    n_lo = sum(1 for x in f1 if x < 0.05)
    n_hi = sum(1 for x in f1 if x > 0.95)
    n_mid = n - n_lo - n_hi

    # One-ray pile: ≥80% of points share a single Das–Dennis association.
    one_ray = max_niche >= max(2, math.ceil(0.8 * n))

    igd = None
    igd_source = None
    pf = zdt_pf(problem, pf_points)
    try:
        from pymoo.indicators.igd import IGD
        import numpy as np

        igd = float(IGD(np.asarray(pf, dtype=float))(np.asarray(front, dtype=float)))
        igd_source = f"pymoo-IGD analytic-{problem} n={pf_points}"
    except ImportError:
        igd = igd_mean(front, pf)
        igd_source = f"local-mean-nn analytic-{problem} n={pf_points}"

    collapsed = n <= COLLAPSE_N and igd is not None and igd >= COLLAPSE_IGD

    shape = "other"
    if collapsed and n_lo >= max(1, n - 1) and f1 and max(f1) < 0.15:
        shape = "pile_at_f1_near_0"
    elif collapsed and n_hi >= max(1, n - 1) and f1 and min(f1) > 0.85:
        shape = "pile_at_f1_near_1"
    elif collapsed and one_ray:
        shape = "one_ray"
    elif collapsed and n_lo > 0 and n_hi > 0 and n_mid == 0:
        shape = "two_extremes_only"
    elif not collapsed and occupied >= partitions // 2:
        shape = "spread"

    return {
        "n": n,
        "f1_min": min(f1),
        "f1_max": max(f1),
        "f1_median": median(f1),
        "f1_span": max(f1) - min(f1),
        "f2_min": min(f2),
        "f2_max": max(f2),
        "n_f1_lt_0.05": n_lo,
        "n_f1_gt_0.95": n_hi,
        "n_f1_interior": n_mid,
        "unique_rounded_4": len({(round(a, 4), round(b, 4)) for a, b in front}),
        "das_dennis_partitions": partitions,
        "n_refs": len(dirs),
        "occupied_refs_raw": occupied,
        "max_niche_raw": max_niche,
        "one_ray_raw": one_ray,
        "ref_hist_raw": raw_h,
        "occupied_refs_minmax": len(norm_h),
        "max_niche_minmax": max(norm_h.values()) if norm_h else 0,
        "ref_hist_minmax": norm_h,
        "igd": igd,
        "igd_source": igd_source,
        "collapse": collapsed,
        "shape": shape,
    }


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--front", type=Path, required=True)
    p.add_argument("--problem", choices=("zdt1", "zdt2"), default="zdt2")
    p.add_argument("--partitions", type=int, default=12)
    p.add_argument("--pf-points", type=int, default=500)
    args = p.parse_args()
    if not args.front.is_file():
        print(f"skip: front file missing: {args.front}", file=sys.stderr)
        return 0
    front = load_csv(args.front)
    rec = characterize(front, args.problem, args.partitions, args.pf_points)
    rec["front"] = str(args.front)
    rec["problem"] = args.problem
    print(json.dumps(rec, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
