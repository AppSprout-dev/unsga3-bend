#!/usr/bin/env python3
"""CPU reference for the experimental associate kernel.

Matches src/survival.bend `resid_sq` / `perp` / `nearest_go` F32 order:
right-fold dots and residuals, ww < 1e-16 uses ||f||, argmin on strict `<`
(ties keep the lower index). Also builds the niche-count histogram.

This is not a product code path. Used to check the Metal/CUDA kernels and
the isolated Bend bench dumps.
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path


LCG_MUL = 1664525
LCG_ADD = 1013904223
BEST_D0 = 1_000_000_000.0
TINY_WW = 1e-16
DIST_ABS = 1e-6
DIST_REL = 1e-5


def lcg(state: int) -> int:
    return (state * LCG_MUL + LCG_ADD) & 0xFFFFFFFF


def u32_to_unit(state: int) -> float:
    # (state >> 8) / 2^24 as binary32. Integers up to 2^24 are exact in F32.
    u = (state >> 8) & 0xFFFFFF
    return struct.unpack("f", struct.pack("f", u / 16777216.0))[0]


def gen_matrix(rows: int, cols: int, seed: int) -> tuple[list[list[float]], int]:
    s = seed & 0xFFFFFFFF
    out: list[list[float]] = []
    for _ in range(rows):
        row: list[float] = []
        for _ in range(cols):
            s = lcg(s)
            row.append(u32_to_unit(s))
        out.append(row)
    return out, s


def f32(x: float) -> float:
    return struct.unpack("f", struct.pack("f", x))[0]


def right_dot(a: list[float], b: list[float]) -> float:
    acc = 0.0
    for i in range(len(a) - 1, -1, -1):
        acc = f32(f32(a[i] * b[i]) + acc)
    return acc


def right_resid_sq(f: list[float], w: list[float], t: float) -> float:
    acc = 0.0
    for i in range(len(f) - 1, -1, -1):
        r = f32(f[i] - f32(t * w[i]))
        acc = f32(f32(r * r) + acc)
    return acc


def perp(f: list[float], w: list[float]) -> float:
    ww = right_dot(w, w)
    if ww < TINY_WW:
        import math
        return f32(math.sqrt(right_dot(f, f)))
    t = f32(right_dot(f, w) / ww)
    import math
    return f32(math.sqrt(right_resid_sq(f, w, t)))


def nearest_one(f: list[float], refs: list[list[float]]) -> tuple[int, float]:
    best_i = 0
    best_d = BEST_D0
    for j, w in enumerate(refs):
        d = perp(f, w)
        if d < best_d:
            best_d = d
            best_i = j
    return best_i, best_d


def associate(points: list[list[float]], refs: list[list[float]]) -> tuple[list[int], list[float]]:
    idx: list[int] = []
    dist: list[float] = []
    for f in points:
        i, d = nearest_one(f, refs)
        idx.append(i)
        dist.append(d)
    return idx, dist


def niche_count(idx: list[int], n_ref: int) -> list[int]:
    counts = [0] * n_ref
    for r in idx:
        if 0 <= r < n_ref:
            counts[r] += 1
    return counts


def dist_close(a: float, b: float) -> bool:
    if abs(a - b) <= DIST_ABS:
        return True
    scale = max(abs(a), abs(b), 1e-30)
    return abs(a - b) <= DIST_REL * scale


def compare(
    idx_a: list[int],
    dist_a: list[float],
    idx_b: list[int],
    dist_b: list[float],
    label: str,
) -> dict:
    n = min(len(idx_a), len(idx_b))
    mismatches = [i for i in range(n) if idx_a[i] != idx_b[i]]
    dist_bad = [i for i in range(n) if not dist_close(dist_a[i], dist_b[i])]
    max_abs = max((abs(dist_a[i] - dist_b[i]) for i in range(n)), default=0.0)
    ok = (
        len(idx_a) == len(idx_b)
        and not mismatches
        and not dist_bad
    )
    return {
        "label": label,
        "ok": ok,
        "n": n,
        "idx_mismatches": len(mismatches),
        "idx_mismatch_examples": mismatches[:8],
        "dist_mismatches": len(dist_bad),
        "dist_mismatch_examples": dist_bad[:8],
        "max_abs_dist_delta": max_abs,
        "sum_idx": sum(idx_a),
        "tolerance": {"abs": DIST_ABS, "rel": DIST_REL},
    }


def parse_dump(text: str) -> tuple[list[int], list[float], list[int]]:
    idx: list[int] = []
    dist: list[float] = []
    counts: list[int] = []
    mode = "head"
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or line.startswith("kind="):
            continue
        if line == "ASSIGNMENTS":
            mode = "asg"
            continue
        if line == "COUNTS":
            mode = "counts"
            continue
        if mode == "asg":
            parts = line.split()
            if len(parts) >= 2:
                idx.append(int(parts[0]))
                dist.append(float(parts[1]))
        elif mode == "counts":
            counts.extend(int(x) for x in line.split())
    return idx, dist, counts


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--n", type=int, default=8)
    p.add_argument("--r", type=int, default=5)
    p.add_argument("--m", type=int, default=3)
    p.add_argument("--seed", type=int, default=1)
    p.add_argument("--dump", type=Path, default=None)
    p.add_argument("--compare", type=Path, default=None, help="Bend/Metal dump to check")
    p.add_argument("--include-zero-ref", action="store_true")
    args = p.parse_args()

    points, s1 = gen_matrix(args.n, args.m, args.seed)
    refs, _ = gen_matrix(args.r, args.m, s1)
    if args.include_zero_ref:
        refs[0] = [0.0] * args.m

    idx, dist = associate(points, refs)
    counts = niche_count(idx, len(refs))

    payload = {
        "n": args.n,
        "r": len(refs),
        "m": args.m,
        "seed": args.seed,
        "sum_idx": sum(idx),
        "counts_sum": sum(counts),
        "idx": idx,
        "dist": dist,
        "counts": counts,
    }
    if args.dump:
        args.dump.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {args.dump}", file=sys.stderr)

    print(f"n={args.n} r={len(refs)} m={args.m} seed={args.seed}")
    print(f"sum_idx={sum(idx)} counts_sum={sum(counts)}")
    print("ASSIGNMENTS")
    for i, d in zip(idx, dist):
        print(f"{i} {d:.9g}")
    print("COUNTS")
    print(" ".join(str(c) for c in counts))

    if args.compare:
        text = args.compare.read_text(encoding="utf-8")
        c_idx, c_dist, c_counts = parse_dump(text)
        report = compare(idx, dist, c_idx, c_dist, args.compare.name)
        if c_counts and c_counts != counts:
            report["ok"] = False
            report["count_mismatch"] = True
        print(json.dumps(report, indent=2), file=sys.stderr)
        return 0 if report["ok"] else 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
