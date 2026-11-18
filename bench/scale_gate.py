#!/usr/bin/env python3
"""Scaling gate for U-NSGA-III on DTLZ2.

Builds one native binary (``bend bench/scale_run.bend -o …``) and runs a
fixed grid at ``--threads 1``. Each cell prints ``IO.now`` milliseconds
around ``Unsga3Algorithm.Run`` (and, on the slow variant, the extra walk
in ``bench/slow_pass.bend``). This script also records process wall time
and peak RSS (Linux ``ru_maxrss``, kilobytes).

Two checks, both on medians:

1. Scaling bound. Log-log OLS exponent of time vs population and vs
   Das–Dennis reference-point count, and the same for peak RSS, must sit
   at or under the ceilings in ``bench/baseline.json``.
2. Regression. Those exponents, the series endpoint ratios, and each
   cell's ratio to the anchor must stay within the committed margins.
   Ratios and exponents, not absolute milliseconds, so a uniformly
   slower runner does not fail the job.

``--variant slow`` is the negative control. CI runs it with ``--expect fail``
and fails the job if the gate accepts it.

No IGD / HV numbers. This does not change ``LAWS.bend`` or ``PROOF.bend``.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import statistics
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BENCH = ROOT / "bench"
SRC = ROOT / "src"
DRIVER = BENCH / "scale_run.bend"
OUT_DIR = BENCH / "out"
BASELINE_PATH = BENCH / "baseline.json"
REPORT_PATH = OUT_DIR / "report.json"

ANCHOR = "m3p12n92"
GENS = 16
REPEATS = 3
THREADS = 1
# Inner List.get repeats on the slow variant. Fast runs pass burn=0.
# Chosen so the slow N-exponent clears the time-vs-N ceiling; see README.
SLOW_BURN_WEIGHT = 600
CELL_TIMEOUT_S = 120

# id -> (m, partitions, pop). Keep in lockstep with bench/scale_run.bend.
CELLS: dict[str, tuple[int, int, int]] = {
    "m0idle": (0, 0, 0),
    "m3p12n23": (3, 12, 23),
    "m3p12n46": (3, 12, 46),
    "m3p12n92": (3, 12, 92),
    "m3p4n92": (3, 4, 92),
    "m3p8n92": (3, 8, 92),
    "m5p4n70": (5, 4, 70),
    "m8p2n36": (8, 2, 36),
    "m8p3n120": (8, 3, 120),
}

# x is the measured key. y is the median key. cells are low x -> high x.
SERIES: list[dict[str, object]] = [
    {
        "name": "time_vs_n",
        "x": "pop",
        "y": "algo_ms",
        "cells": ["m3p12n23", "m3p12n46", "m3p12n92"],
        "ceiling": "time_vs_n_max",
        "ratio_key": "ratio_margin",
    },
    {
        "name": "time_vs_r",
        "x": "ref_points",
        "y": "algo_ms",
        "cells": ["m3p4n92", "m3p8n92", "m3p12n92"],
        "ceiling": "time_vs_r_max",
        "ratio_key": "ratio_margin",
    },
    {
        "name": "wall_vs_n",
        "x": "pop",
        "y": "wall_s",
        "cells": ["m3p12n23", "m3p12n46", "m3p12n92"],
        "ceiling": "time_vs_n_max",
        "ratio_key": "ratio_margin",
    },
    {
        "name": "wall_vs_r",
        "x": "ref_points",
        "y": "wall_s",
        "cells": ["m3p4n92", "m3p8n92", "m3p12n92"],
        "ceiling": "time_vs_r_max",
        "ratio_key": "ratio_margin",
    },
    {
        "name": "rss_vs_n",
        "x": "pop",
        "y": "rss_kb",
        "cells": ["m3p12n23", "m3p12n46", "m3p12n92"],
        "ceiling": "rss_vs_n_max",
        "ratio_key": "rss_ratio_margin",
    },
    {
        "name": "rss_vs_r",
        "x": "ref_points",
        "y": "rss_kb",
        "cells": ["m3p4n92", "m3p8n92", "m3p12n92"],
        "ceiling": "rss_vs_r_max",
        "ratio_key": "rss_ratio_margin",
    },
]

# Ceilings are expected complexity plus headroom, not a fit to one sample.
# time vs N: NDS is O(M N^2) and association at fixed R is O(N), so the
# leading term is quadratic. +0.5 headroom -> 2.5.
# time vs R: association is O(R) at fixed N, NDS does not read R. +0.5 -> 1.5.
# RSS: live data is O(N + R). Exponent 1 is the linear ceiling. At this
# grid the runtime floor dominates, so the observed exponent is ~0; the
# ceiling still rejects a super-linear footprint once it lifts off the floor.
# exponent_margin / ratio_margin are the regression bands. See bench/README.md.
LOCKED_BOUNDS = {
    "time_vs_n_max": 2.5,
    "time_vs_r_max": 1.5,
    "rss_vs_n_max": 1.0,
    "rss_vs_r_max": 1.0,
    "exponent_margin": 0.40,
    "ratio_margin": 1.75,
    "rss_ratio_margin": 1.15,
}

HELPER = r"""
import resource, subprocess, sys, time
t0 = time.perf_counter()
p = subprocess.run(sys.argv[1:], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
wall = time.perf_counter() - t0
rss = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss
sys.stdout.buffer.write(p.stdout)
sys.stdout.write("WALL_S %.6f\n" % wall)
sys.stdout.write("MAXRSS_KB %d\n" % rss)
sys.stderr.buffer.write(p.stderr)
raise SystemExit(p.returncode)
"""


def das_dennis_count(m: int, p: int) -> int:
    """C(p + M - 1, M - 1). M < 2 is not a simplex count this gate uses."""
    if m < 2:
        return 0
    return math.comb(p + m - 1, m - 1)


def log_log_exponent(xs: list[float], ys: list[float]) -> float:
    """OLS slope of log y on log x. Units cancel, so a slower clock does not move it."""
    if len(xs) != len(ys) or len(xs) < 2:
        raise ValueError("need at least two points")
    if any(x <= 0 or y <= 0 for x, y in zip(xs, ys)):
        raise ValueError("log-log inputs must be positive")
    n = len(xs)
    lx = [math.log(x) for x in xs]
    ly = [math.log(y) for y in ys]
    mx = sum(lx) / n
    my = sum(ly) / n
    var = sum((x - mx) ** 2 for x in lx)
    if var == 0:
        raise ValueError("x values are identical")
    cov = sum((x - mx) * (y - my) for x, y in zip(lx, ly))
    return cov / var


def median(values: list[float]) -> float:
    return float(statistics.median(values))


def source_hash() -> str:
    digest = hashlib.sha256()
    files = sorted(SRC.glob("*.bend")) + [DRIVER, BENCH / "slow_pass.bend"]
    for path in files:
        digest.update(path.relative_to(ROOT).as_posix().encode())
        digest.update(b"\0")
        digest.update(path.read_bytes())
    return digest.hexdigest()[:16]


def binary_path() -> Path:
    return OUT_DIR / f"scale_run-{source_hash()}"


def build_binary(dest: Path) -> float:
    dest.parent.mkdir(parents=True, exist_ok=True)
    t0 = time.perf_counter()
    proc = subprocess.run(
        ["bend", str(DRIVER), "-o", str(dest)],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    elapsed = time.perf_counter() - t0
    if proc.returncode != 0 or not os.access(dest, os.X_OK):
        sys.stderr.write(proc.stdout)
        sys.stderr.write(proc.stderr)
        raise SystemExit(2)
    return elapsed


def ensure_binary() -> tuple[Path, float | None]:
    dest = binary_path()
    if os.access(dest, os.X_OK):
        return dest, None
    return dest, build_binary(dest)


def parse_bend_lines(text: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for line in text.splitlines():
        if line.startswith("# ") and "=" in line:
            key, value = line[2:].split("=", 1)
            out[key] = value
    return out


def run_cell(binary: Path, cell: str, *, gens: int, burn: int, slow: bool) -> dict[str, float | str]:
    cmd = [str(binary), "--threads", str(THREADS), cell, f"gens={gens}", f"burn={burn}"]
    if slow and cell != "m0idle":
        cmd.append("slow")
    proc = subprocess.run(
        [sys.executable, "-c", HELPER, *cmd],
        capture_output=True,
        text=True,
        timeout=CELL_TIMEOUT_S,
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stdout)
        sys.stderr.write(proc.stderr)
        raise SystemExit(2)
    fields = parse_bend_lines(proc.stdout)
    wall_s = None
    rss_kb = None
    for line in proc.stdout.splitlines():
        if line.startswith("WALL_S "):
            wall_s = float(line.split()[1])
        elif line.startswith("MAXRSS_KB "):
            rss_kb = int(line.split()[1])
    if wall_s is None or rss_kb is None:
        sys.stderr.write("measurer did not report wall and rss\n")
        raise SystemExit(2)
    expect_m, expect_p, expect_n = CELLS[cell]
    got = {
        "cell": fields.get("cell", ""),
        "variant": fields.get("variant", ""),
        "m": int(fields["m"]),
        "partitions": int(fields["partitions"]),
        "pop": int(fields["pop"]),
        "gens": int(fields["gens"]),
        "ref_points": int(fields["ref_points"]),
        "algo_ms": int(fields["algo_ms"]),
        "run_ms": int(fields["run_ms"]),
        "burn_ms": int(fields["burn_ms"]),
        "pop_len": int(fields["pop_len"]),
        "burn_weight": int(fields["burn_weight"]),
        "wall_s": wall_s,
        "rss_kb": rss_kb,
    }
    if got["cell"] != cell or got["m"] != expect_m or got["partitions"] != expect_p or got["pop"] != expect_n:
        sys.stderr.write(f"cell mismatch for {cell}: {got}\n")
        raise SystemExit(2)
    if got["gens"] != gens:
        sys.stderr.write(f"gens mismatch for {cell}: {got['gens']}\n")
        raise SystemExit(2)
    if cell != "m0idle":
        if got["ref_points"] != das_dennis_count(expect_m, expect_p):
            sys.stderr.write(f"ref_points mismatch for {cell}: {got['ref_points']}\n")
            raise SystemExit(2)
        if got["pop_len"] != expect_n:
            sys.stderr.write(f"pop_len mismatch for {cell}: {got['pop_len']}\n")
            raise SystemExit(2)
        if got["algo_ms"] <= 0 or got["wall_s"] <= 0 or got["rss_kb"] <= 0:
            sys.stderr.write(f"non-positive measurement for {cell}: {got}\n")
            raise SystemExit(2)
        expect_variant = "slow" if slow else "fast"
        if got["variant"] != expect_variant:
            sys.stderr.write(f"variant mismatch for {cell}: {got['variant']}\n")
            raise SystemExit(2)
    return got


def measure(
    *,
    gens: int,
    repeats: int,
    slow: bool,
    burn: int,
    cells: list[str],
) -> dict[str, dict]:
    binary, compile_s = ensure_binary()
    if compile_s is None:
        print(f"native: cache hit {binary.name}", file=sys.stderr)
    else:
        print(f"native: compile_s={compile_s:.3f} {binary.name}", file=sys.stderr)
    out: dict[str, dict] = {}
    for cell in cells:
        samples = [
            run_cell(binary, cell, gens=gens, burn=burn, slow=slow) for _ in range(repeats)
        ]
        def col(key: str) -> list[float]:
            return [float(sample[key]) for sample in samples]

        algo = col("algo_ms")
        wall = col("wall_s")
        rss = col("rss_kb")
        run_ms = col("run_ms")
        burn_ms = col("burn_ms")
        blob = {
            "m": int(samples[0]["m"]),
            "partitions": int(samples[0]["partitions"]),
            "pop": int(samples[0]["pop"]),
            "ref_points": int(samples[0]["ref_points"]),
            "algo_ms": {"median": median(algo), "repeats": algo},
            "wall_s": {"median": median(wall), "repeats": wall},
            "rss_kb": {"median": median(rss), "repeats": rss},
            "run_ms": {"median": median(run_ms), "repeats": run_ms},
            "burn_ms": {"median": median(burn_ms), "repeats": burn_ms},
        }
        out[cell] = blob
        print(
            f"{cell} algo_ms={blob['algo_ms']['median']:.0f} "
            f"wall_s={blob['wall_s']['median']:.3f} "
            f"rss_kb={blob['rss_kb']['median']:.0f} "
            f"run_ms={blob['run_ms']['median']:.0f} "
            f"burn_ms={blob['burn_ms']['median']:.0f} "
            f"R={blob['ref_points']}",
            file=sys.stderr,
        )
    return out


def view(cells: dict[str, dict]) -> dict[str, dict[str, float]]:
    """Medians plus the x-axis fields the fitter reads."""
    out: dict[str, dict[str, float]] = {}
    for name, blob in cells.items():
        out[name] = {
            "pop": float(blob["pop"]),
            "ref_points": float(blob["ref_points"]),
            "algo_ms": float(blob["algo_ms"]["median"]),
            "wall_s": float(blob["wall_s"]["median"]),
            "rss_kb": float(blob["rss_kb"]["median"]),
        }
    return out


def series_exponent(samples: dict[str, dict[str, float]], spec: dict[str, object]) -> float:
    names = spec["cells"]
    assert isinstance(names, list)
    xs = [samples[name][str(spec["x"])] for name in names]
    ys = [samples[name][str(spec["y"])] for name in names]
    return log_log_exponent(xs, ys)


def endpoint_ratio(samples: dict[str, dict[str, float]], spec: dict[str, object]) -> float:
    names = spec["cells"]
    assert isinstance(names, list)
    y = str(spec["y"])
    return samples[names[-1]][y] / samples[names[0]][y]


def evaluate(samples: dict[str, dict[str, float]], baseline: dict) -> list[str]:
    """Return human-readable failures. Empty means the gate passed."""
    bounds = baseline["bounds"]
    base = view(baseline["cells"])
    failures: list[str] = []
    margin = float(bounds["exponent_margin"])
    for spec in SERIES:
        name = str(spec["name"])
        current = series_exponent(samples, spec)
        recorded = series_exponent(base, spec)
        ceiling = float(bounds[str(spec["ceiling"])])
        if current > ceiling:
            failures.append(
                f"{name} exponent {current:.4f} exceeds ceiling {ceiling:.4f}"
            )
        if current > recorded + margin:
            failures.append(
                f"{name} exponent {current:.4f} exceeds baseline {recorded:.4f} "
                f"+ margin {margin:.4f}"
            )
        ratio_margin = float(bounds[str(spec["ratio_key"])])
        current_ratio = endpoint_ratio(samples, spec)
        recorded_ratio = endpoint_ratio(base, spec)
        rel = current_ratio / recorded_ratio
        if rel > ratio_margin:
            failures.append(
                f"{name} endpoint ratio {current_ratio:.4f} / baseline {recorded_ratio:.4f} "
                f"= {rel:.4f} exceeds margin {ratio_margin:.4f}"
            )
    for cell in CELLS:
        if cell in ("m0idle", ANCHOR):
            continue
        for metric, key in (("algo_ms", "ratio_margin"), ("rss_kb", "rss_ratio_margin")):
            current = samples[cell][metric] / samples[ANCHOR][metric]
            recorded = base[cell][metric] / base[ANCHOR][metric]
            rel = current / recorded
            limit = float(bounds[key])
            if rel > limit:
                failures.append(
                    f"{cell} {metric} / anchor = {current:.4f} vs baseline {recorded:.4f} "
                    f"(rel {rel:.4f} > {limit:.4f})"
                )
    return failures


def fit_table(samples: dict[str, dict[str, float]]) -> dict[str, float]:
    return {str(spec["name"]): series_exponent(samples, spec) for spec in SERIES}


def tool_version(cmd: list[str]) -> str:
    proc = subprocess.run(cmd, capture_output=True, text=True)
    line = (proc.stdout or proc.stderr or "").strip().splitlines()
    return line[0] if line else "unknown"


def recorded_with() -> dict[str, str]:
    return {
        "bend": tool_version(["bend", "version"]),
        "clang": tool_version(["clang", "--version"]),
        "python": sys.version.split()[0],
        "platform": os.uname().machine + " " + os.uname().release,
    }


def load_baseline() -> dict:
    return json.loads(BASELINE_PATH.read_text())


def bounds_for_record() -> dict:
    if BASELINE_PATH.is_file():
        existing = load_baseline()
        if "bounds" in existing:
            return existing["bounds"]
    return dict(LOCKED_BOUNDS)


def write_baseline(cells: dict[str, dict], *, gens: int, repeats: int, bounds: dict) -> None:
    payload = {
        "schema": 1,
        "problem": "dtlz2",
        "k": 10,
        "gens": gens,
        "seed": 1,
        "tournament": "pymoo",
        "threads": THREADS,
        "repeats": repeats,
        "anchor": ANCHOR,
        "note": "Bounds and margins are explained in bench/README.md. Medians are from this file's repeats.",
        "recorded_with": recorded_with(),
        "bounds": bounds,
        "cells": cells,
    }
    BASELINE_PATH.write_text(json.dumps(payload, indent=2) + "\n")


def check_protocol(baseline: dict, *, gens: int) -> None:
    if int(baseline["gens"]) != gens:
        sys.stderr.write(f"baseline gens={baseline['gens']} but this run uses gens={gens}\n")
        raise SystemExit(2)
    if int(baseline["threads"]) != THREADS:
        sys.stderr.write("baseline threads do not match this runner\n")
        raise SystemExit(2)
    missing = [cell for cell in CELLS if cell not in baseline["cells"]]
    if missing:
        sys.stderr.write(f"baseline missing cells: {missing}\n")
        raise SystemExit(2)


def format_report(
    *,
    samples: dict[str, dict[str, float]],
    cells: dict[str, dict],
    baseline: dict | None,
    failures: list[str],
    variant: str,
    expect_fail: bool,
    gens: int,
) -> str:
    lines: list[str] = []
    accepted = not failures
    if expect_fail:
        verdict = "control_rejected" if failures else "control_accepted"
    else:
        verdict = "pass" if accepted else "fail"
    lines.append(f"verdict={verdict} variant={variant}")
    lines.append(
        f"threads={THREADS} gens={gens} "
        f"anchor={ANCHOR}"
    )
    lines.append("")
    lines.append(
        f"{'cell':<12} {'M':>2} {'p':>3} {'R':>4} {'N':>4} "
        f"{'algo_ms':>8} {'wall_s':>8} {'rss_kb':>8} {'burn_ms':>8}"
    )
    for name, blob in cells.items():
        lines.append(
            f"{name:<12} {blob['m']:2d} {blob['partitions']:3d} {blob['ref_points']:4d} {blob['pop']:4d} "
            f"{blob['algo_ms']['median']:8.1f} {blob['wall_s']['median']:8.3f} "
            f"{blob['rss_kb']['median']:8.0f} {blob['burn_ms']['median']:8.1f}"
        )
    lines.append("")
    lines.append("exponents (log-log OLS on medians)")
    fits = fit_table(samples)
    base_fits = fit_table(view(baseline["cells"])) if baseline else None
    for spec in SERIES:
        name = str(spec["name"])
        current = fits[name]
        extra = ""
        if baseline is not None:
            ceiling = float(baseline["bounds"][str(spec["ceiling"])])
            recorded = base_fits[name] if base_fits else float("nan")
            extra = f"  ceiling={ceiling:.2f}  baseline={recorded:.4f}"
        lines.append(f"  {name:<12} {current:.4f}{extra}")
    if baseline is not None:
        lines.append("")
        lines.append("endpoint ratios (high / low) and rel to baseline")
        base = view(baseline["cells"])
        for spec in SERIES:
            name = str(spec["name"])
            current_ratio = endpoint_ratio(samples, spec)
            recorded_ratio = endpoint_ratio(base, spec)
            rel = current_ratio / recorded_ratio
            lines.append(
                f"  {name:<12} {current_ratio:.4f}  baseline={recorded_ratio:.4f}  rel={rel:.4f}"
            )
    if failures:
        lines.append("")
        lines.append("failures:")
        for item in failures:
            lines.append(f"  - {item}")
    else:
        lines.append("")
        lines.append("failures: none")
    return "\n".join(lines) + "\n"


def finish(report: str, *, failures: list[str], expect_fail: bool, payload: dict) -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(payload, indent=2) + "\n")
    sys.stdout.write(report)
    if expect_fail:
        if failures:
            sys.stdout.write("negative control: gate rejected the slow variant\n")
            return 0
        sys.stdout.write("negative control was accepted; the gate is too loose\n")
        return 1
    return 1 if failures else 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="DTLZ2 scaling gate")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--measure", action="store_true", help="run the grid and print it")
    mode.add_argument("--record", action="store_true", help="rewrite bench/baseline.json from a fast run")
    mode.add_argument("--check", action="store_true", help="run the grid and compare to the baseline")
    parser.add_argument("--variant", choices=("fast", "slow"), default="fast")
    parser.add_argument("--expect", choices=("pass", "fail"), default="pass")
    parser.add_argument("--gens", type=int, default=GENS)
    parser.add_argument("--repeats", type=int, default=REPEATS)
    parser.add_argument("--burn-weight", type=int, default=None)
    parser.add_argument("--cells", nargs="*", default=None)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    if args.repeats < 1 or args.gens < 1:
        sys.stderr.write("gens and repeats must be positive\n")
        return 2
    slow = args.variant == "slow"
    if args.record and slow:
        sys.stderr.write("--record writes the fast baseline; it does not record the slow variant\n")
        return 2
    burn = args.burn_weight
    if burn is None:
        burn = SLOW_BURN_WEIGHT if slow else 0
    cells = args.cells if args.cells else list(CELLS)
    unknown = [cell for cell in cells if cell not in CELLS]
    if unknown:
        sys.stderr.write(f"unknown cells: {unknown}\n")
        return 2
    if args.check or args.record:
        if not BASELINE_PATH.is_file() and args.check:
            sys.stderr.write(f"missing {BASELINE_PATH}\n")
            return 2
    try:
        measured = measure(
            gens=args.gens,
            repeats=args.repeats,
            slow=slow,
            burn=burn,
            cells=cells,
        )
    except subprocess.TimeoutExpired:
        sys.stderr.write(f"cell exceeded {CELL_TIMEOUT_S}s\n")
        return 2
    samples = view(measured)
    payload: dict = {
        "variant": args.variant,
        "burn_weight": burn,
        "gens": args.gens,
        "repeats": args.repeats,
        "threads": THREADS,
        "fits": fit_table(samples),
        "cells": measured,
    }
    if args.measure or args.record:
        if args.record:
            if set(cells) != set(CELLS):
                sys.stderr.write("--record runs the full grid\n")
                return 2
            write_baseline(
                measured,
                gens=args.gens,
                repeats=args.repeats,
                bounds=bounds_for_record(),
            )
            payload["baseline_path"] = str(BASELINE_PATH)
        baseline_now = load_baseline() if BASELINE_PATH.is_file() else None
        report = format_report(
            samples=samples,
            cells=measured,
            baseline=baseline_now,
            failures=[],
            variant=args.variant,
            expect_fail=False,
            gens=args.gens,
        )
        return finish(report, failures=[], expect_fail=False, payload=payload)

    baseline = load_baseline()
    check_protocol(baseline, gens=args.gens)
    if set(cells) != set(CELLS):
        sys.stderr.write("--check runs the full grid\n")
        return 2
    failures = evaluate(samples, baseline)
    expect_fail = args.expect == "fail"
    payload["failures"] = failures
    payload["fits_baseline"] = fit_table(view(baseline["cells"]))
    report = format_report(
        samples=samples,
        cells=measured,
        baseline=baseline,
        failures=failures,
        variant=args.variant,
        expect_fail=expect_fail,
        gens=args.gens,
    )
    return finish(report, failures=failures, expect_fail=expect_fail, payload=payload)


if __name__ == "__main__":
    raise SystemExit(main())
