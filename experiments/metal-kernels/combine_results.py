#!/usr/bin/env python3
"""Combine Swift/Metal and Bend bench logs into results JSON + markdown."""
from __future__ import annotations

import json
from pathlib import Path


def parse_bend(text: str) -> dict:
    out: dict = {}
    for line in text.splitlines():
        if not line or line.startswith("ASSIGNMENTS") or line.startswith("COUNTS"):
            continue
        if "ALL PROOFS" in line or line.startswith("Use --verdict"):
            continue
        for part in line.split():
            if "=" not in part:
                continue
            k, v = part.split("=", 1)
            if k in {
                "n", "r", "m", "seed", "warmup", "reps", "total_ms",
                "sum_idx", "n_asg", "counts_sum", "keep",
            }:
                try:
                    out[k] = int(v)
                except ValueError:
                    out[k] = v
            else:
                out[k] = v
    if "total_ms" in out and out.get("reps"):
        out["per_ms"] = out["total_ms"] / out["reps"]
    return out


def main() -> int:
    here = Path(__file__).resolve().parent
    res = here / "results"
    res.mkdir(exist_ok=True)
    rows = []
    payload = {"cells": []}
    for path in sorted(res.glob("msl_*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        data["_file"] = path.name
        payload["cells"].append(data)
        size = f"{data.get('n')}x{data.get('r')}x{data.get('m')}"
        rows.append({
            "size": size,
            "impl": data.get("impl", "hand_msl"),
            "e2e_median_ms": data.get("e2e_median_ms"),
            "e2e_min_ms": data.get("e2e_min_ms"),
            "e2e_max_ms": data.get("e2e_max_ms"),
            "kernel_median_ms": data.get("kernel_median_ms"),
            "kernel_min_ms": data.get("kernel_min_ms"),
            "kernel_max_ms": data.get("kernel_max_ms"),
            "reps": data.get("reps"),
            "sum_idx": data.get("sum_idx"),
            "ok": data.get("ok"),
        })
    for path in sorted(res.glob("bend_*.txt")):
        parsed = parse_bend(path.read_text(encoding="utf-8"))
        parsed["_file"] = path.name
        payload["cells"].append(parsed)
        size = f"{parsed.get('n')}x{parsed.get('r')}x{parsed.get('m')}"
        rows.append({
            "size": size,
            "impl": parsed.get("kind", path.stem),
            "e2e_median_ms": parsed.get("per_ms"),
            "e2e_min_ms": None,
            "e2e_max_ms": None,
            "kernel_median_ms": None,
            "note": f"total_ms={parsed.get('total_ms')} over {parsed.get('reps')} in-process reps (Bend IO.now)",
            "reps": parsed.get("reps"),
            "sum_idx": parsed.get("sum_idx"),
            "ok": None,
        })
    payload["table_rows"] = rows
    (res / "bench.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    lines = [
        "| size (N x R x M) | impl | e2e (ms) | e2e min-max (ms) | kernel-only (ms) | reps | sum_idx | ok |",
        "|---|---|---:|---|---:|---:|---:|---|",
    ]
    for r in rows:
        e2e = r.get("e2e_median_ms")
        e2e_s = f"{e2e:.4f}" if isinstance(e2e, float) else ("" if e2e is None else str(e2e))
        if r.get("e2e_min_ms") is not None:
            spread = f"{r['e2e_min_ms']:.4f}-{r['e2e_max_ms']:.4f}"
        else:
            spread = r.get("note", "")
        kern = r.get("kernel_median_ms")
        kern_s = f"{kern:.4f}" if isinstance(kern, float) else "n/a"
        lines.append(
            f"| {r.get('size')} | {r.get('impl')} | {e2e_s} | {spread} | {kern_s} | {r.get('reps')} | {r.get('sum_idx')} | {r.get('ok')} |"
        )
    (res / "bench.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {res / 'bench.json'} and {res / 'bench.md'} ({len(rows)} rows)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
