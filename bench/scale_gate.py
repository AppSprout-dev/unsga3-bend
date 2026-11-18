# Scaling gate for the Bend U-NSGA-III core.
#
# Each point is the median of several runs of a fresh process, after one
# discarded warmup. A log-log fit passes when its 95% confidence interval's
# upper bound is at or under the allowed slope and r^2 clears the floor.
# The absolute check is one-sided at one reference size, with a margin taken
# from two real sweeps. Controls must be caught by a named check.

import argparse
import hashlib
import json
import math
import os
import platform
import shutil
import statistics
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BENCH = Path(__file__).resolve().parent
CONFIG_PATH = BENCH / "gate.config.json"
BASELINE_PATH = BENCH / "baseline.json"
RUN_SRC = BENCH / "scale_run.bend"
OUT_DIR = BENCH / "out"
DEV_BIN = OUT_DIR / "scale_run-dev"

# Student's t, two-sided 95% (one-sided 97.5%). df = n - 2. df >= 31 uses
# the normal quantile. The df=2 entry is the published 4.302652729911275.
STUDENT_T_975 = {
    1: 12.706204736432095,
    2: 4.302652729911275,
    3: 3.182446305284263,
    4: 2.7764451051977987,
    5: 2.570581836614739,
    6: 2.4469118487916806,
    7: 2.364624251592784,
    8: 2.306004135204166,
    9: 2.262157162798205,
    10: 2.228138851986274,
    11: 2.200985160946347,
    12: 2.178812829663417,
    13: 2.1603686564610127,
    14: 2.144786687916927,
    15: 2.131449545559323,
    16: 2.119905299221252,
    17: 2.1098155778333156,
    18: 2.100922040241038,
    19: 2.093024054408307,
    20: 2.085963447265861,
    21: 2.079613844727662,
    22: 2.0738730679040147,
    23: 2.0686576104190406,
    24: 2.0638985616280206,
    25: 2.059538552753294,
    26: 2.055529438642871,
    27: 2.051830516480284,
    28: 2.048407141795244,
    29: 2.045229642132703,
    30: 2.042272456301238,
}
T_NORMAL = 1.959963984540054

# Point-estimate ceilings from the first gate. Not raised.
LEGACY_CEILINGS = {
    "time_vs_n": 2.5,
    "time_vs_r": 1.5,
    "rss_vs_n": 1.0,
}
LEGACY_EXPONENT_MARGIN = 0.40
LEGACY_RATIO_MARGIN = 1.75
LEGACY_RSS_RATIO_MARGIN = 1.15


def load_config(path=None):
    with open(path or CONFIG_PATH, encoding="utf-8") as f:
        return json.load(f)


def workload_by_id(config, name):
    for w in config["workloads"]:
        if w["id"] == name:
            return w
    raise KeyError(name)


def student_t_975(df):
    if df < 1:
        raise ValueError("df")
    if df >= 31:
        return T_NORMAL
    return STUDENT_T_975[df]


def median(values):
    xs = sorted(values)
    n = len(xs)
    if n == 0:
        raise ValueError("empty")
    if n % 2 == 1:
        return float(xs[n // 2])
    return (xs[n // 2 - 1] + xs[n // 2]) / 2.0


def sample_stdev(values):
    if len(values) < 2:
        return 0.0
    return float(statistics.stdev(values))


def coefficient_of_variation(values):
    mean = statistics.fmean(values)
    if mean == 0.0:
        return 0.0
    return sample_stdev(values) / abs(mean)


def round_up_milli(need):
    """Smallest 0.001 that is >= need. An exact thousandth stays put."""
    scaled = need * 1000.0
    # 1e-9 keeps a value that is already a thousandth from rounding up.
    return math.ceil(scaled - 1e-9) / 1000.0


def margin_need(cv, median_a, median_b):
    """max(5 * CV, 2 * |ratio - 1|). medians are the two sweep medians."""
    if median_b == 0.0:
        raise ValueError("median")
    ratio = median_a / median_b
    return max(5.0 * cv, 2.0 * abs(ratio - 1.0))


def ols(xs, ys):
    """Log-log OLS of ln(y) on ln(x). Returns slope, intercept, r^2, se, low, high."""
    n = len(xs)
    if n != len(ys) or n < 3:
        raise ValueError("need at least 3 points")
    if any(x <= 0 or y <= 0 for x, y in zip(xs, ys)):
        raise ValueError("positive x and y required")
    lx = [math.log(x) for x in xs]
    ly = [math.log(y) for y in ys]
    x_bar = statistics.fmean(lx)
    y_bar = statistics.fmean(ly)
    ss_xx = sum((x - x_bar) ** 2 for x in lx)
    ss_yy = sum((y - y_bar) ** 2 for y in ly)
    ss_xy = sum((x - x_bar) * (y - y_bar) for x, y in zip(lx, ly))
    if ss_xx == 0.0:
        raise ValueError("x does not vary")
    slope = ss_xy / ss_xx
    intercept = y_bar - slope * x_bar
    r2 = 1.0 if ss_yy == 0.0 else (ss_xy * ss_xy) / (ss_xx * ss_yy)
    df = n - 2
    residual = ss_yy - slope * ss_xy
    if residual < 0.0 and residual > -1e-12:
        residual = 0.0
    se = math.sqrt((residual / df) / ss_xx) if df > 0 else 0.0
    half = student_t_975(df) * se
    return {
        "n": n,
        "slope": slope,
        "intercept": intercept,
        "r2": r2,
        "se": se,
        "df": df,
        "low": slope - half,
        "high": slope + half,
    }


def allowed_exponent(workload, config):
    source = workload
    name = workload.get("allowed_from")
    if name:
        source = workload_by_id(config, name)
    override = source.get("max_exponent")
    if override is not None:
        return float(override)
    return float(source["expected_exponent"]) + float(config["slack"])


def growth_ratio(values):
    lo = min(values)
    hi = max(values)
    if lo <= 0.0:
        return float("inf")
    return hi / lo


def classify_fit(fit, workload, config):
    """within / worse / inconclusive / skipped.

    A flat series (growth under the configured ratio) whose upper bound still
    sits at or under the allowed slope is skipped when the workload says
    flat_ok. That is the time-vs-R case: NDS does not read R, so the series
    is supposed to stay flat, and a low r^2 there is not a failed fit.
    """
    allowed = allowed_exponent(workload, config)
    metric = workload["metric"]
    grew = growth_ratio(fit["ys"])
    if metric == "time":
        grew_enough = grew >= float(config["min_time_ratio"])
    else:
        grew_enough = grew >= float(config["memory_min_ratio"])
    if not grew_enough and fit["high"] <= allowed + 1e-12 and workload.get("flat_ok"):
        return "skipped", allowed
    if fit["r2"] + 1e-12 < float(config["min_r_squared"]):
        return "inconclusive", allowed
    if fit["high"] <= allowed + 1e-12:
        return "within", allowed
    if fit["low"] > allowed:
        return "worse", allowed
    return "inconclusive", allowed


def legacy_point_failures(fit, workload, baseline_fit):
    """The first gate's point-estimate checks. Kept, not loosened."""
    ceiling = workload.get("legacy_ceiling")
    out = []
    if ceiling is not None and fit["slope"] > float(ceiling) + 1e-12:
        out.append("ceiling")
    if baseline_fit is None:
        return out
    base_slope = float(baseline_fit["slope"])
    if fit["slope"] > base_slope + LEGACY_EXPONENT_MARGIN + 1e-12:
        out.append("exponent-drift")
    base_ratio = float(baseline_fit["endpoint_ratio"])
    ratio = endpoint_ratio(fit["ys"])
    if base_ratio > 0.0 and ratio / base_ratio > _legacy_ratio_margin(workload) + 1e-12:
        out.append("endpoint-ratio")
    return out


def _legacy_ratio_margin(workload):
    if workload["metric"] == "rss":
        return LEGACY_RSS_RATIO_MARGIN
    return LEGACY_RATIO_MARGIN


def endpoint_ratio(ys):
    if ys[0] <= 0.0:
        return float("inf")
    return ys[-1] / ys[0]


def span_ok(xs, config):
    return max(xs) / min(xs) + 1e-12 >= float(config["min_n_span"])


def machine_info():
    model = "unknown"
    cpuinfo = Path("/proc/cpuinfo")
    if cpuinfo.exists():
        for line in cpuinfo.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.lower().startswith("model name"):
                model = line.split(":", 1)[1].strip()
                break
    return {
        "cpu_model": model,
        "logical_cpus": os.cpu_count() or 0,
        "platform": platform.platform(),
        "machine": platform.machine(),
    }


def same_machine(a, b):
    return (
        a.get("cpu_model") == b.get("cpu_model")
        and int(a.get("logical_cpus") or 0) == int(b.get("logical_cpus") or 0)
    )


def parse_kv(text):
    fields = {}
    for line in text.splitlines():
        line = line.strip()
        if not line.startswith("# ") or "=" not in line:
            continue
        key, value = line[2:].split("=", 1)
        fields[key.strip()] = value.strip()
    return fields


def _to_int(fields, key):
    if key not in fields:
        raise RuntimeError(f"missing {key}")
    return int(fields[key])


# ru_maxrss on RUSAGE_CHILDREN is a high-water mark for the calling process,
# so each sample runs in its own interpreter. Otherwise a later, smaller
# child would be reported as the earlier peak.
_CHILD = """
import resource, subprocess, sys, time
t0 = time.perf_counter()
proc = subprocess.run(sys.argv[1:], stdout=subprocess.PIPE)
wall = time.perf_counter() - t0
rss = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss
sys.stdout.buffer.write(proc.stdout)
sys.stdout.write("\\n# wall_s=%.9f\\n# rss_kb=%d\\n" % (wall, rss))
sys.exit(proc.returncode)
"""


def run_once(binary, cell, mode, gens, burn, threads=1):
    """Fresh process. Wall time and peak RSS belong to that process only."""
    args = [str(binary), "--threads", str(threads), cell, f"mode={mode}"]
    if gens:
        args.append(f"gens={gens}")
    if burn:
        args.append(f"burn={burn}")
    proc = subprocess.run(
        [sys.executable, "-c", _CHILD, *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise RuntimeError(
            f"{cell} mode={mode} exited {proc.returncode}\n{proc.stderr[-500:]}"
        )
    fields = parse_kv(proc.stdout)
    if fields.get("cell") != cell:
        raise RuntimeError(f"expected cell {cell}, got {fields.get('cell')}")
    if fields.get("variant") != mode:
        raise RuntimeError(f"{cell}: expected variant {mode}, got {fields.get('variant')}")
    return {
        "cell": cell,
        "mode": mode,
        "algo_ms": _to_int(fields, "algo_ms"),
        "run_ms": _to_int(fields, "run_ms"),
        "burn_ms": _to_int(fields, "burn_ms"),
        "wall_s": float(fields["wall_s"]),
        "rss_kb": _to_int(fields, "rss_kb"),
        "pop": _to_int(fields, "pop"),
        "objectives": _to_int(fields, "m"),
        "ref_points": _to_int(fields, "ref_points"),
        "pop_len": _to_int(fields, "pop_len"),
    }


def metric_of(sample, metric):
    if metric == "time":
        return float(sample["algo_ms"])
    if metric == "wall":
        return float(sample["wall_s"]) * 1000.0
    if metric == "rss":
        return float(sample["rss_kb"])
    raise KeyError(metric)


def measure_cell(binary, workload, cell, config, cache):
    mode = workload["mode"]
    gens = int(workload.get("gens") or 0)
    burn = int(workload.get("burn") or 0)
    if mode == "quad":
        burn = int(config["quad_reps"])
    key = (mode, cell, gens, burn)
    if key in cache:
        return cache[key]
    warmup = int(config["warmup_runs"])
    repeats = int(config["measured_runs"])
    for _ in range(warmup):
        run_once(binary, cell, mode, gens, burn)
    samples = [run_once(binary, cell, mode, gens, burn) for _ in range(repeats)]
    cache[key] = samples
    return samples


def series_from_cells(cells, metric, x_key):
    points = []
    for cell, samples in cells:
        xs = [s[x_key] for s in samples]
        if len(set(xs)) != 1:
            raise RuntimeError(f"{cell}: x varies across repeats")
        values = [metric_of(s, metric) for s in samples]
        points.append(
            {
                "cell": cell,
                "x": xs[0],
                "median": median(values),
                "samples": values,
                "cv": coefficient_of_variation(values),
            }
        )
    points.sort(key=lambda p: p["x"])
    return points


def fit_points(points):
    xs = [p["x"] for p in points]
    ys = [p["median"] for p in points]
    fit = ols(xs, ys)
    fit["xs"] = xs
    fit["ys"] = ys
    fit["endpoint_ratio"] = endpoint_ratio(ys)
    return fit


def hash_sources():
    files = [RUN_SRC, BENCH / "quad_pass.bend", BENCH / "alloc_pass.bend", BENCH / "slow_pass.bend"]
    files.extend(sorted((ROOT / "src").glob("*.bend")))
    digest = hashlib.sha256()
    for path in files:
        digest.update(path.name.encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()[:16]


def bend_exe():
    found = shutil.which("bend")
    if found:
        return found
    home = Path.home() / ".bend" / "bin" / "bend"
    if home.exists():
        return str(home)
    return "bend"


def ensure_binary():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    stamp = OUT_DIR / "scale_run.sha"
    digest = hash_sources()
    if DEV_BIN.exists() and stamp.exists() and stamp.read_text(encoding="utf-8").strip() == digest:
        return DEV_BIN
    proc = subprocess.run(
        [bend_exe(), str(RUN_SRC), "-o", str(DEV_BIN)],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0 or not DEV_BIN.exists():
        raise RuntimeError(f"bend -o failed\n{proc.stderr[-800:]}")
    stamp.write_text(digest + "\n", encoding="utf-8")
    return DEV_BIN


def run_workload(binary, workload, config, cache):
    cells = []
    for cell in workload["cells"]:
        samples = measure_cell(binary, workload, cell, config, cache)
        cells.append((cell, samples))
    return {"id": workload["id"], "cells": cells}


def reference_point(measured, cell_id):
    for cell, samples in measured["cells"]:
        if cell == cell_id:
            return cell, samples
    raise KeyError(cell_id)


def summarize_workload(measured, workload, config, baseline, machine):
    """One workload's verdicts. Does not decide the process exit."""
    result = {"id": workload["id"], "role": workload["role"], "metric": workload["metric"]}
    if workload.get("fit", True) and workload["role"] != "record":
        points = series_from_cells(measured["cells"], workload["metric"], workload["x"])
        result["points"] = points
        xs = [p["x"] for p in points]
        result["span"] = max(xs) / min(xs)
        if len(points) < int(config["min_fit_points"]) or not span_ok(xs, config):
            result["fit_status"] = "inconclusive"
            result["fit_reason"] = "span or point count"
        else:
            fit = fit_points(points)
            status, allowed = classify_fit(fit, workload, config)
            result["fit"] = {k: fit[k] for k in ("slope", "low", "high", "r2", "se", "df", "endpoint_ratio")}
            result["fit_status"] = status
            result["allowed"] = allowed
            base_fit = None
            if baseline and baseline.get("recorded"):
                base_fit = (baseline.get("fits") or {}).get(workload["id"])
            result["legacy"] = legacy_point_failures(fit, workload, base_fit)
    ref = workload.get("reference")
    if ref:
        _, samples = reference_point(measured, ref)
        values = [metric_of(s, workload["metric"]) for s in samples]
        result["reference"] = {
            "cell": ref,
            "median": median(values),
            "samples": values,
            "cv": coefficient_of_variation(values),
        }
        result["absolute"] = absolute_status(result["reference"], workload, baseline, machine)
    return result


def absolute_status(reference, workload, baseline, machine):
    if workload["role"] not in ("measure", "uniform"):
        return "n/a"
    if not baseline or not baseline.get("recorded"):
        return "skipped-no-baseline"
    base_machine = baseline.get("machine") or {}
    policy = (baseline.get("absolute") or {}).get("on_different_machine", "skip")
    if not same_machine(machine, base_machine):
        if policy == "skip":
            return "skipped-machine"
        return "fail"
    base_refs = baseline.get("references") or {}
    # A uniform slowdown is compared with the fast workload's reference.
    # Storing the slowed median as its own baseline would make 2× look normal.
    key = workload.get("baseline_of") or workload["id"]
    if key not in base_refs:
        return "skipped-no-baseline"
    base = base_refs[key]
    margin = float(base["margin"])
    limit = float(base["median"]) * (1.0 + margin)
    if reference["median"] > limit + 1e-9:
        return "fail"
    return "pass"


def control_caught(summary):
    """A scaling control is caught only when its gated metric is worse."""
    return summary.get("fit_status") == "worse"


def uniform_caught(summary):
    """A uniform slowdown must miss the slope and trip the absolute check."""
    return summary.get("fit_status") == "within" and summary.get("absolute") == "fail"


def measure_ok(summary):
    if summary["role"] != "measure":
        return True
    fit_ok = summary.get("fit_status") in (None, "within", "skipped")
    legacy_ok = not summary.get("legacy")
    absolute = summary.get("absolute")
    abs_ok = absolute in (None, "n/a", "pass", "skipped-machine")
    return fit_ok and legacy_ok and abs_ok


def decide(summaries):
    """Exit 0 when every measure passes and every control is caught the intended way.

    Exit 2 when the only miss is a missing baseline (absolute skipped).
    Exit 1 when a measure fails or a control is not caught by its named check.
    """
    missing_baseline = False
    problems = []
    for s in summaries:
        role = s["role"]
        if role == "record":
            continue
        if role == "measure":
            if not measure_ok(s):
                if s.get("absolute") == "skipped-no-baseline" and s.get("fit_status") in (
                    None,
                    "within",
                    "skipped",
                ) and not s.get("legacy"):
                    missing_baseline = True
                    problems.append(f"{s['id']}:absolute:skipped-no-baseline")
                else:
                    problems.append(f"{s['id']}:fail")
        elif role == "control":
            if not control_caught(s):
                problems.append(f"{s['id']}:{s['metric']}:not-worse")
        elif role == "uniform":
            if s.get("fit_status") != "within":
                problems.append(f"{s['id']}:time:not-within")
            if s.get("absolute") == "skipped-no-baseline":
                missing_baseline = True
                problems.append(f"{s['id']}:absolute:skipped-no-baseline")
            elif s.get("absolute") != "fail":
                problems.append(f"{s['id']}:absolute:not-fail")
    real = [p for p in problems if "skipped-no-baseline" not in p]
    if real:
        return 1, problems
    if missing_baseline:
        return 2, problems
    return 0, problems


def margin_from_sweeps(ref_a, ref_b):
    cv = max(ref_a["cv"], ref_b["cv"])
    need = margin_need(cv, ref_a["median"], ref_b["median"])
    return {"cv": cv, "need": need, "margin": round_up_milli(need)}


def apply_config_overrides(config, args):
    if args.warmup is not None:
        config["warmup_runs"] = args.warmup
    if args.repeats is not None:
        config["measured_runs"] = args.repeats
    return config


def select_workloads(config, only):
    if not only:
        return config["workloads"]
    wanted = set(only)
    return [w for w in config["workloads"] if w["id"] in wanted]


def run_sweep(binary, workloads, config):
    cache = {}
    return [run_workload(binary, w, config, cache) for w in workloads]


def tool_versions():
    bend = bend_exe()
    try:
        out = subprocess.run([bend, "version"], capture_output=True, text=True, timeout=30)
        bend_v = (out.stdout or out.stderr).strip().splitlines()
        bend_v = bend_v[-1] if bend_v else "unknown"
    except (OSError, subprocess.TimeoutExpired):
        bend_v = "unknown"
    return {"bend": bend_v, "python": platform.python_version()}


def build_draft(config, sweep_a, sweep_b, machine):
    """Baseline body from two sweeps. The confirmation sweep's medians are stored."""
    references = {}
    fits = {}
    by_id_b = {m["id"]: m for m in sweep_b}
    by_id_a = {m["id"]: m for m in sweep_a}
    for workload in config["workloads"]:
        if workload["role"] != "measure":
            continue
        if "reference" not in workload:
            continue
        summary_a = summarize_workload(by_id_a[workload["id"]], workload, config, None, machine)
        summary_b = summarize_workload(by_id_b[workload["id"]], workload, config, None, machine)
        margin = margin_from_sweeps(summary_a["reference"], summary_b["reference"])
        ref = summary_b["reference"]
        references[workload["id"]] = {
            "cell": ref["cell"],
            "metric": workload["metric"],
            "median": ref["median"],
            "samples": ref["samples"],
            "cv": ref["cv"],
            "other_median": summary_a["reference"]["median"],
            "other_cv": summary_a["reference"]["cv"],
            "margin": margin["margin"],
            "margin_need": margin["need"],
        }
        if "fit" in summary_b:
            fits[workload["id"]] = summary_b["fit"]
    return {
        "schema": 2,
        "recorded": True,
        "machine": machine,
        "absolute": config["absolute"],
        "references": references,
        "fits": fits,
        "source_hash": hash_sources(),
        "tools": tool_versions(),
    }


def format_report(summaries, code, problems):
    lines = [f"verdict={'pass' if code == 0 else 'fail'}", f"exit={code}"]
    for s in summaries:
        if s["role"] == "record":
            cells = ",".join(cell for cell, _ in []) if False else ""
            bits = []
            for cell, samples in s.get("cells_raw", []) or []:
                bits.append(cell)
            # measured cells are not on the summary; points may be absent.
            line = f"{s['id']} record"
            if "reference" in s:
                line += f" ref={s['reference']['median']:.4g}"
            lines.append(line)
            continue
        fit = s.get("fit")
        if fit:
            lines.append(
                f"{s['id']} {s['metric']} {s['fit_status']} "
                f"slope={fit['slope']:.4f} low={fit['low']:.4f} high={fit['high']:.4f} "
                f"allowed={s['allowed']:.4f} r2={fit['r2']:.4f} "
                f"ratio={fit['endpoint_ratio']:.4f}"
            )
        elif "fit_status" in s:
            lines.append(f"{s['id']} {s['metric']} {s['fit_status']}")
        if s.get("legacy"):
            lines.append(f"{s['id']} legacy {','.join(s['legacy'])}")
        if "absolute" in s:
            ref = s.get("reference") or {}
            lines.append(
                f"{s['id']} absolute {s['absolute']} median={ref.get('median', float('nan')):.4g}"
            )
    if problems:
        lines.append("problems: " + "; ".join(problems))
    return "\n".join(lines) + "\n"


def attach_raw(summaries, measured):
    by_id = {m["id"]: m for m in measured}
    for s in summaries:
        raw = by_id.get(s["id"])
        if raw:
            s["cells_raw"] = [
                (
                    cell,
                    [
                        {
                            "algo_ms": sample["algo_ms"],
                            "wall_s": sample["wall_s"],
                            "rss_kb": sample["rss_kb"],
                            "pop": sample["pop"],
                            "ref_points": sample["ref_points"],
                        }
                        for sample in samples
                    ],
                )
                for cell, samples in raw["cells"]
            ]
    return summaries


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", action="store_true")
    parser.add_argument("--sweeps", type=int, default=1)
    parser.add_argument("--warmup", type=int)
    parser.add_argument("--repeats", type=int)
    parser.add_argument("--only", action="append", default=[])
    parser.add_argument("--draft", type=Path)
    parser.add_argument("--report", type=Path, default=OUT_DIR / "report.json")
    parser.add_argument("--baseline", type=Path, default=BASELINE_PATH)
    parser.add_argument("--config", type=Path, default=CONFIG_PATH)
    args = parser.parse_args(argv)
    if not args.run:
        parser.error("pass --run")
    config = apply_config_overrides(load_config(args.config), args)
    workloads = select_workloads(config, args.only)
    if args.sweeps < 1:
        parser.error("--sweeps must be >= 1")
    binary = ensure_binary()
    machine = machine_info()
    baseline = None
    if args.baseline.exists():
        baseline = json.loads(args.baseline.read_text(encoding="utf-8"))
    measure = [w for w in workloads if w["role"] == "measure"]
    sweep_a = run_sweep(binary, workloads, config)
    sweep_b = run_sweep(binary, measure, config) if args.sweeps >= 2 else None
    by_id = {m["id"]: m for m in sweep_a}
    summaries = [
        summarize_workload(by_id[w["id"]], w, config, baseline, machine) for w in workloads
    ]
    attach_raw(summaries, sweep_a)
    if sweep_b is not None:
        by_b = {m["id"]: m for m in sweep_b}
        for w in measure:
            extra = summarize_workload(by_b[w["id"]], w, config, baseline, machine)
            extra["sweep"] = "confirm"
            summaries.append(extra)
    code, problems = decide([s for s in summaries if s.get("sweep") != "confirm"])
    # A confirmation sweep that fails its own checks fails the run too.
    if sweep_b is not None:
        code_b, problems_b = decide([s for s in summaries if s.get("sweep") == "confirm"])
        if code_b == 1 or (code_b == 2 and code == 0):
            code = code_b
        problems.extend(f"confirm {p}" for p in problems_b)
    draft = None
    if args.draft and sweep_b is not None:
        draft = build_draft(config, sweep_a, sweep_b, machine)
        args.draft.parent.mkdir(parents=True, exist_ok=True)
        args.draft.write_text(json.dumps(draft, indent=2) + "\n", encoding="utf-8")
    report = {
        "exit": code,
        "problems": problems,
        "machine": machine,
        "tools": tool_versions(),
        "source_hash": hash_sources(),
        "summaries": summaries,
        "draft_written": str(args.draft) if draft else None,
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    sys.stdout.write(format_report(summaries, code, problems))
    return code


if __name__ == "__main__":
    sys.exit(main())
