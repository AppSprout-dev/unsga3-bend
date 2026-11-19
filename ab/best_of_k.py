#!/usr/bin/env python3
"""Best-of-k fidelity of a front-only association energy.

Pre-registered. Thresholds, k, the seed list, and the shuffle seed are
fixed below. Do not edit them to fit a measured table. See docs/BEST_OF_K.md.

Question: among k Bend runs, does a score that sees only the final
non-dominated front pick the seed with the better IGD?

The selection job is the one an energy does in Energy-Based Reasoners
(arXiv:2611.08977): keep the lowest-energy sample. Inside one Run, niching
already associates points to Das–Dennis rays. This script does not change
that algorithm. E_assoc is computed afterwards, in Python, from the dumped
front.

E_assoc
    Ideal = component-wise minimum of the dumped ND front.
    Nadir = component-wise maximum of that same front.
    A span below 1e-12 uses denominator 1, matching Util.denom.
    Each normalized point is tied to its nearest Das–Dennis ray
    (igd_vs_pymoo.das_dennis, the same partitions as the run).
    Distance is the perpendicular residual used by Survival.perp.
    Ties keep the earlier ray. E_assoc is the mean of those distances.
    Uncovered is the fraction of rays with no point. It is reported
    and is not part of the pass rule.

Compare E_assoc only across Bend seeds. A Bend ZDT1 front keeps on the
order of 52 points; a pymoo NSGA-III front on the same knobs keeps about
one point per ray. Those energies are not on the same scale.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import random
import subprocess
import sys
from datetime import datetime, timezone
from itertools import combinations
from pathlib import Path
from statistics import median

from igd_vs_pymoo import das_dennis, load_csv
from oracle_multiseed import dump_stack, score_front, stem
from protocol import oracle_knobs

ROOT = Path(__file__).resolve().parent.parent
DUMP_DIR = ROOT / "ab" / "out" / "oracle_multiseed"
OUT_DIR = ROOT / "ab" / "out" / "best_of_k"

# Locked with the protocol text in docs/BEST_OF_K.md. Not a search.
PROBLEMS = ("zdt1", "zdt2", "dtlz2")
SEEDS = tuple(range(1, 16))
K = 3
SHUFFLE_SEED = 0
RHO_MIN = 0.5
RHO_PROBLEMS_MIN = 2
IMPROVE_MIN = 0.05
WORSE_MAX = 0.05
CONTROL_BAND = 0.02
PF_POINTS = 500
SPAN_FLOOR = 1e-12
TINY_WW = 1e-16
# Survival.nearest_go starts at this sentinel and keeps the first ray
# unless a later distance is strictly smaller.
DIST_SENTINEL = 1_000_000_000.0

# What oracle_knobs must resolve to. A drift here is a refusal, not a retune.
REGISTERED_KNOBS = {
    "zdt1": {"partitions": 12, "pop": 52, "gens": 100, "tournament": "pymoo"},
    "zdt2": {"partitions": 12, "pop": 52, "gens": 250, "tournament": "pymoo"},
    "dtlz2": {"partitions": 12, "pop": 92, "gens": 150, "tournament": "pymoo"},
}

DISJOINT_TRIPLES = (
    (1, 2, 3),
    (4, 5, 6),
    (7, 8, 9),
    (10, 11, 12),
    (13, 14, 15),
)

CSV_FIELDS = ("problem", "seed", "E_assoc", "uncovered", "IGD", "n")

NEGATIVE_SENTENCE = "a front-only energy does not find the better seed here."
PASS_SENTENCE = (
    "A front-only association energy meets the pre-registered best-of-3 bar "
    "on these Bend seeds."
)


def registered_knobs(problem: str) -> dict[str, int | str]:
    """Knobs from protocol.py, checked against the registered tuple."""
    knobs = oracle_knobs(problem)
    want = REGISTERED_KNOBS[problem]
    got = {
        "partitions": int(knobs["partitions"]),
        "pop": int(knobs["pop"]),
        "gens": int(knobs["gens"]),
        "tournament": str(knobs["tournament"]),
    }
    if got != want:
        raise SystemExit(
            f"skip: protocol.py knobs for {problem} are {got}; "
            f"best-of-k is registered at {want}. Refusing to retune."
        )
    return knobs


def dominates(a: list[float], b: list[float]) -> bool:
    """Minimization. Unequal lengths do not dominate (mutual non-domination)."""
    if len(a) != len(b) or not a:
        return False
    better = False
    for x, y in zip(a, b):
        if x > y:
            return False
        if x < y:
            better = True
    return better


def nondominated(front: list[list[float]]) -> list[list[float]]:
    """Pareto filter. nd_front dumps are already this set."""
    kept: list[list[float]] = []
    for i, row in enumerate(front):
        if any(dominates(other, row) for j, other in enumerate(front) if j != i):
            continue
        kept.append(row)
    return kept


def normalize_front(front: list[list[float]]) -> list[list[float]]:
    """Translate by the front's own ideal and divide by its own nadir span."""
    n_obj = len(front[0])
    ideal = [min(row[j] for row in front) for j in range(n_obj)]
    nadir = [max(row[j] for row in front) for j in range(n_obj)]
    out: list[list[float]] = []
    for row in front:
        scaled: list[float] = []
        for j, value in enumerate(row):
            span = nadir[j] - ideal[j]
            denom = 1.0 if span < SPAN_FLOOR else span
            scaled.append((value - ideal[j]) / denom)
        out.append(scaled)
    return out


def perp(point: list[float], direction: list[float]) -> float:
    """Euclidean distance from point to the line through direction."""
    ww = sum(w * w for w in direction)
    if ww < TINY_WW:
        return math.sqrt(sum(x * x for x in point))
    dot = sum(x * w for x, w in zip(point, direction))
    t = dot / ww
    return math.sqrt(sum((x - t * w) ** 2 for x, w in zip(point, direction)))


def nearest(point: list[float], dirs: list[list[float]]) -> tuple[int, float]:
    best_i = 0
    best_d = DIST_SENTINEL
    for i, direction in enumerate(dirs):
        dist = perp(point, direction)
        if dist < best_d:
            best_d = dist
            best_i = i
    return best_i, best_d


def e_assoc(front: list[list[float]], partitions: int) -> dict[str, float | int] | None:
    """Mean nearest-ray distance of the ND front, plus the uncovered fraction.

    Returns None on an empty front. Does not invent a distance.
    """
    nd = nondominated(front)
    if not nd:
        return None
    n_obj = len(nd[0])
    if any(len(row) != n_obj for row in nd):
        raise ValueError("ragged objective front")
    dirs = das_dennis(n_obj, partitions)
    if not dirs:
        raise ValueError(f"das_dennis({n_obj}, {partitions}) is empty")
    hits = [0] * len(dirs)
    dists: list[float] = []
    for point in normalize_front(nd):
        index, dist = nearest(point, dirs)
        hits[index] += 1
        dists.append(dist)
    uncovered = sum(1 for hit in hits if hit == 0) / len(dirs)
    return {
        "E_assoc": sum(dists) / len(dists),
        "uncovered": uncovered,
        "n": len(nd),
    }


def position_permutation(n: int, seed: int) -> list[int]:
    """Fisher–Yates over 0..n-1. CPython random.Random(seed), not retuned."""
    rng = random.Random(seed)
    perm = list(range(n))
    for i in range(n - 1, 0, -1):
        j = rng.randrange(i + 1)
        perm[i], perm[j] = perm[j], perm[i]
    return perm


def ranks(values: list[float]) -> list[float]:
    """Average ranks, 1-based. Ties share the mean of the tied places."""
    order = sorted(range(len(values)), key=lambda i: values[i])
    out = [0.0] * len(values)
    i = 0
    while i < len(values):
        j = i
        while j + 1 < len(values) and values[order[j + 1]] == values[order[i]]:
            j += 1
        average = 0.5 * ((i + 1) + (j + 1))
        for k in range(i, j + 1):
            out[order[k]] = average
        i = j + 1
    return out


def pearson(xs: list[float], ys: list[float]) -> float | None:
    n = len(xs)
    if n != len(ys) or n < 2:
        return None
    mean_x = sum(xs) / n
    mean_y = sum(ys) / n
    var_x = sum((x - mean_x) ** 2 for x in xs)
    var_y = sum((y - mean_y) ** 2 for y in ys)
    if var_x == 0.0 or var_y == 0.0:
        return None
    cov = sum((x - mean_x) * (y - mean_y) for x, y in zip(xs, ys))
    return cov / math.sqrt(var_x * var_y)


def spearman(xs: list[float], ys: list[float]) -> float | None:
    """Spearman rho via Pearson correlation of average ranks."""
    if len(xs) != len(ys) or len(xs) < 2:
        return None
    rho = pearson(ranks(xs), ranks(ys))
    if rho is None:
        return None
    try:
        from scipy.stats import spearmanr
    except ImportError:
        return rho
    other = spearmanr(xs, ys).statistic
    if other is None or not math.isfinite(float(other)):
        if rho is None:
            return None
        raise RuntimeError("scipy Spearman was non-finite while the rank rho was not")
    if abs(float(other) - rho) > 1e-9:
        raise RuntimeError(f"Spearman mismatch: rank {rho} vs scipy {other}")
    return rho


def rel_lower(method: float, baseline: float) -> float:
    """Positive when method's IGD is lower than the baseline."""
    if baseline == 0.0:
        raise ValueError("baseline IGD is 0; refusing to invent a ratio")
    return (baseline - method) / baseline


def argmin_seed(seeds: tuple[int, ...] | list[int], value_of) -> int:
    """Lowest value. Equal values keep the smaller seed."""
    best = seeds[0]
    best_v = value_of(best)
    for seed in seeds[1:]:
        value = value_of(seed)
        if value < best_v or (value == best_v and seed < best):
            best = seed
            best_v = value
    return best


def _by_seed(rows: list[dict]) -> dict[int, dict]:
    return {int(row["seed"]): row for row in rows}


def _triple_view(
    by_seed: dict[int, dict],
    triple: tuple[int, ...],
    shuffled_e: dict[int, float],
) -> dict:
    energy_seed = argmin_seed(triple, lambda s: float(by_seed[s]["E_assoc"]))
    oracle_seed = argmin_seed(triple, lambda s: float(by_seed[s]["IGD"]))
    shuffled_seed = argmin_seed(triple, lambda s: shuffled_e[s])
    igds = [float(by_seed[s]["IGD"]) for s in triple]
    return {
        "seeds": list(triple),
        "energy_seed": energy_seed,
        "energy_igd": float(by_seed[energy_seed]["IGD"]),
        "random_igd": sum(igds) / len(igds),
        "oracle_seed": oracle_seed,
        "oracle_igd": float(by_seed[oracle_seed]["IGD"]),
        "shuffled_seed": shuffled_seed,
        "shuffled_igd": float(by_seed[shuffled_seed]["IGD"]),
    }


def analyze_problem(rows: list[dict]) -> dict:
    """One problem. rows must carry seed, E_assoc, IGD. Order does not matter."""
    ordered = sorted(rows, key=lambda row: int(row["seed"]))
    seeds = [int(row["seed"]) for row in ordered]
    if len(seeds) != len(set(seeds)):
        raise ValueError("duplicate seed")
    by_seed = _by_seed(ordered)
    energies = [float(by_seed[s]["E_assoc"]) for s in seeds]
    igds = [float(by_seed[s]["IGD"]) for s in seeds]
    perm = position_permutation(len(seeds), SHUFFLE_SEED)
    shuffled_e = {seeds[i]: energies[perm[i]] for i in range(len(seeds))}
    triples = list(combinations(seeds, K))
    views = [_triple_view(by_seed, triple, shuffled_e) for triple in triples]
    med_energy = float(median(view["energy_igd"] for view in views))
    med_random = float(median(view["random_igd"] for view in views))
    med_oracle = float(median(view["oracle_igd"] for view in views))
    med_shuffled = float(median(view["shuffled_igd"] for view in views))
    rho = spearman(energies, igds)
    rel_e = rel_lower(med_energy, med_random)
    rel_s = rel_lower(med_shuffled, med_random)
    rel_o = rel_lower(med_oracle, med_random)
    disjoint = []
    for triple in DISJOINT_TRIPLES:
        if all(seed in by_seed for seed in triple):
            disjoint.append(_triple_view(by_seed, triple, shuffled_e))
    return {
        "seeds": seeds,
        "n_triples": len(views),
        "rho": rho,
        "rho_pass": rho is not None and rho >= RHO_MIN,
        "median_igd_energy": med_energy,
        "median_igd_random": med_random,
        "median_igd_oracle": med_oracle,
        "median_igd_shuffled": med_shuffled,
        "rel_energy": rel_e,
        "rel_oracle": rel_o,
        "rel_shuffled": rel_s,
        "improve_pass": rel_e >= IMPROVE_MIN,
        "not_worse_pass": rel_e >= -WORSE_MAX,
        "control_pass": abs(rel_s) <= CONTROL_BAND,
        "shuffle_perm": perm,
        "disjoint": disjoint,
    }


def _problem_order(rows: list[dict]) -> list[str]:
    seen: list[str] = []
    for problem in PROBLEMS:
        if any(row["problem"] == problem for row in rows):
            seen.append(problem)
    for row in rows:
        if row["problem"] not in seen:
            seen.append(row["problem"])
    return seen


def grid_complete(rows: list[dict]) -> bool:
    got = {
        (row["problem"], int(row["seed"]))
        for row in rows
        if not row.get("skipped") and row.get("IGD") is not None and row.get("E_assoc") is not None
    }
    need = {(problem, seed) for problem in PROBLEMS for seed in SEEDS}
    return got == need


def summarize(rows: list[dict]) -> dict:
    """Pass / negative / incomplete from the registered rules. No retune."""
    problems = _problem_order(rows)
    per: dict[str, dict] = {}
    for problem in problems:
        group = [row for row in rows if row["problem"] == problem and not row.get("skipped")]
        if len(group) < K:
            continue
        per[problem] = analyze_problem(group)
        per[problem]["problem"] = problem

    complete = grid_complete(rows) and list(per) == list(PROBLEMS)
    rhos = [per[p]["rho_pass"] for p in PROBLEMS if p in per]
    improves = [per[p]["improve_pass"] for p in PROBLEMS if p in per]
    not_worse = [per[p]["not_worse_pass"] for p in PROBLEMS if p in per]
    controls = [per[p]["control_pass"] for p in PROBLEMS if p in per]
    n_rho = sum(bool(x) for x in rhos)
    n_improve = sum(bool(x) for x in improves)
    criterion_a = {
        "rho_min": RHO_MIN,
        "need": RHO_PROBLEMS_MIN,
        "n_pass": n_rho,
        "pass": complete and n_rho >= RHO_PROBLEMS_MIN,
    }
    criterion_b = {
        "improve_min": IMPROVE_MIN,
        "worse_max": WORSE_MAX,
        "need_improve": RHO_PROBLEMS_MIN,
        "n_improve": n_improve,
        "not_worse": complete and all(not_worse) and len(not_worse) == len(PROBLEMS),
        "pass": (
            complete
            and n_improve >= RHO_PROBLEMS_MIN
            and all(not_worse)
            and len(not_worse) == len(PROBLEMS)
        ),
    }
    criterion_c = {
        "band": CONTROL_BAND,
        "pass": complete and all(controls) and len(controls) == len(PROBLEMS),
    }
    if not complete:
        verdict = "incomplete"
        sentence = "incomplete: a seed is missing or an IGD/energy cell was skipped. No verdict."
    elif criterion_a["pass"] and criterion_b["pass"] and criterion_c["pass"]:
        verdict = "pass"
        sentence = PASS_SENTENCE
    else:
        verdict = "negative"
        sentence = NEGATIVE_SENTENCE
    return {
        "verdict": verdict,
        "sentence": sentence,
        "criterion_a": criterion_a,
        "criterion_b": criterion_b,
        "criterion_c": criterion_c,
        "problems": per,
        "protocol": {
            "k": K,
            "seeds": list(SEEDS),
            "problems": list(PROBLEMS),
            "shuffle_seed": SHUFFLE_SEED,
            "pf_points": PF_POINTS,
            "knobs": REGISTERED_KNOBS,
            "tournament": "pymoo",
            "energy": "E_assoc",
            "random": "mean IGD of the triple",
            "oracle": "min IGD of the triple",
            "control": "argmin of E_assoc after one Fisher-Yates of the 15 energies",
            "tied_energy": "lower seed",
            "n_triples": math.comb(len(SEEDS), K),
        },
    }


def _fmt_num(value: float) -> str:
    return format(value, ".16g")


def write_csv(rows: list[dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    ordered = sorted(rows, key=lambda row: (PROBLEMS.index(row["problem"]) if row["problem"] in PROBLEMS else 99, int(row["seed"])))
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=CSV_FIELDS, lineterminator="\n")
        writer.writeheader()
        for row in ordered:
            writer.writerow(
                {
                    "problem": row["problem"],
                    "seed": int(row["seed"]),
                    "E_assoc": _fmt_num(float(row["E_assoc"])),
                    "uncovered": _fmt_num(float(row["uncovered"])),
                    "IGD": _fmt_num(float(row["IGD"])),
                    "n": int(row["n"]),
                }
            )


def read_csv(path: Path) -> list[dict]:
    rows: list[dict] = []
    with path.open(encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)
        if reader.fieldnames is None or tuple(reader.fieldnames) != CSV_FIELDS:
            raise SystemExit(f"skip: {path} columns are {reader.fieldnames}; expected {CSV_FIELDS}")
        for raw in reader:
            rows.append(
                {
                    "problem": raw["problem"],
                    "seed": int(raw["seed"]),
                    "E_assoc": float(raw["E_assoc"]),
                    "uncovered": float(raw["uncovered"]),
                    "IGD": float(raw["IGD"]),
                    "n": int(raw["n"]),
                }
            )
    return rows


def _tool_version(cmd: list[str]) -> str:
    try:
        proc = subprocess.run(cmd, check=False, capture_output=True, text=True)
    except FileNotFoundError:
        return "missing"
    text = (proc.stdout or proc.stderr or "").strip()
    return text.splitlines()[0] if text else "missing"


def host_block() -> dict:
    pymoo_ver = "missing"
    try:
        import pymoo

        pymoo_ver = pymoo.__version__
    except ImportError:
        pymoo_ver = "missing"
    return {
        "date": datetime.now(timezone.utc).date().isoformat(),
        "bend": _tool_version(["bend", "version"]),
        "clang": _tool_version(["clang", "--version"]),
        "python": sys.version.split()[0],
        "pymoo": pymoo_ver,
        "bend_pin": False,
    }


def markdown_report(summary: dict) -> str:
    lines = [
        f"verdict={summary['verdict']}",
        summary["sentence"],
        "",
        "| problem | rho | median E | median random | rel E | median oracle | median shuffled | rel shuffled | (a) | improve | not worse | (c) |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|",
    ]
    for problem in PROBLEMS:
        block = summary["problems"].get(problem)
        if block is None:
            lines.append(f"| {problem} | | | | | | | | | | | |")
            continue
        rho = block["rho"]
        rho_s = "" if rho is None else f"{rho:.4f}"
        lines.append(
            f"| {problem} | {rho_s} | {block['median_igd_energy']:.6f} | "
            f"{block['median_igd_random']:.6f} | {100 * block['rel_energy']:.3f}% | "
            f"{block['median_igd_oracle']:.6f} | {block['median_igd_shuffled']:.6f} | "
            f"{100 * block['rel_shuffled']:.3f}% | "
            f"{'pass' if block['rho_pass'] else 'fail'} | "
            f"{'pass' if block['improve_pass'] else 'fail'} | "
            f"{'pass' if block['not_worse_pass'] else 'fail'} | "
            f"{'pass' if block['control_pass'] else 'fail'} |"
        )
    a = summary["criterion_a"]
    b = summary["criterion_b"]
    c = summary["criterion_c"]
    lines.append("")
    lines.append(
        f"(a) Spearman rho >= {RHO_MIN} on >= {RHO_PROBLEMS_MIN}/3: "
        f"{'pass' if a['pass'] else 'fail'} ({a['n_pass']}/3)"
    )
    lines.append(
        f"(b) median best-of-3 >= {100 * IMPROVE_MIN:.0f}% below random on >= {RHO_PROBLEMS_MIN}/3, "
        f"and no problem worse than {100 * WORSE_MAX:.0f}%: "
        f"{'pass' if b['pass'] else 'fail'} "
        f"(improve {b['n_improve']}/3, not_worse={b['not_worse']})"
    )
    lines.append(
        f"(c) shuffled control within +/-{100 * CONTROL_BAND:.0f}% of random on every problem: "
        f"{'pass' if c['pass'] else 'fail'}"
    )
    lines.append("")
    lines.append("Disjoint triples (1–3, 4–6, 7–9, 10–12, 13–15), reported only:")
    lines.append("")
    lines.append("| problem | seeds | E seed | E IGD | random IGD | oracle seed | oracle IGD | shuffled seed | shuffled IGD |")
    lines.append("|---|---|---:|---:|---:|---:|---:|---:|---:|")
    for problem in PROBLEMS:
        block = summary["problems"].get(problem)
        if block is None:
            continue
        for view in block["disjoint"]:
            seeds = "-".join(str(s) for s in view["seeds"])
            lines.append(
                f"| {problem} | {seeds} | {view['energy_seed']} | {view['energy_igd']:.6f} | "
                f"{view['random_igd']:.6f} | {view['oracle_seed']} | {view['oracle_igd']:.6f} | "
                f"{view['shuffled_seed']} | {view['shuffled_igd']:.6f} |"
            )
    lines.append("")
    return "\n".join(lines)


def collect(problems: list[str], seeds: list[int], dump_dir: Path, reuse: bool) -> list[dict]:
    rows: list[dict] = []
    dump_dir.mkdir(parents=True, exist_ok=True)
    for problem in problems:
        knobs = registered_knobs(problem)
        partitions = int(knobs["partitions"])
        pop = int(knobs["pop"])
        gens = int(knobs["gens"])
        for seed in seeds:
            dest = dump_dir / f"{stem('bend', problem, partitions, pop, gens, seed)}_F.csv"
            dump = dump_stack("bend", problem, partitions, pop, gens, seed, dest, reuse)
            if not dump.get("dumped"):
                skip = dump.get("skip") or "skip: bend dump failed"
                print(f"skip: {problem} seed {seed}: {skip}", file=sys.stderr)
                rows.append(
                    {
                        "problem": problem,
                        "seed": seed,
                        "skipped": True,
                        "skip": skip,
                    }
                )
                continue
            scored = score_front(dest, problem, partitions)
            if scored.get("skipped") or scored.get("igd") is None:
                skip = scored.get("skip") or "skip: igd_vs_pymoo"
                print(f"skip: {problem} seed {seed}: {skip}", file=sys.stderr)
                rows.append(
                    {
                        "problem": problem,
                        "seed": seed,
                        "skipped": True,
                        "skip": skip,
                    }
                )
                continue
            front = load_csv(dest)
            energy = e_assoc(front, partitions)
            if energy is None:
                print(f"skip: {problem} seed {seed}: empty ND front", file=sys.stderr)
                rows.append(
                    {
                        "problem": problem,
                        "seed": seed,
                        "skipped": True,
                        "skip": "skip: empty ND front",
                    }
                )
                continue
            row = {
                "problem": problem,
                "seed": seed,
                "E_assoc": float(energy["E_assoc"]),
                "uncovered": float(energy["uncovered"]),
                "IGD": float(scored["igd"]),
                "n": int(energy["n"]),
                "reused": bool(dump.get("reused")),
                "pf_source": scored.get("pf_source"),
                "pf_rows": scored.get("pf_rows"),
                "front_rows": scored.get("front_rows"),
            }
            rows.append(row)
            print(
                f"{problem} seed {seed}: E_assoc={row['E_assoc']:.6g} "
                f"uncovered={row['uncovered']:.4f} igd={row['IGD']:.6g} n={row['n']}",
                file=sys.stderr,
            )
    return rows


def write_outputs(rows: list[dict], out_dir: Path) -> dict:
    measured = [row for row in rows if not row.get("skipped")]
    summary = summarize(measured)
    summary["host"] = host_block()
    summary["n_rows"] = len(measured)
    summary["n_reused"] = sum(1 for row in rows if row.get("reused"))
    summary["skips"] = [
        {"problem": row["problem"], "seed": row["seed"], "skip": row.get("skip")}
        for row in rows
        if row.get("skipped")
    ]
    out_dir.mkdir(parents=True, exist_ok=True)
    csv_path = out_dir / "per_seed.csv"
    json_path = out_dir / "summary.json"
    if measured:
        write_csv(measured, csv_path)
    json_path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(markdown_report(summary))
    print(f"wrote {json_path}", file=sys.stderr)
    if measured:
        print(f"wrote {csv_path}", file=sys.stderr)
    return summary


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--problems", nargs="+", default=list(PROBLEMS), choices=PROBLEMS)
    parser.add_argument("--seeds", nargs="+", type=int, default=list(SEEDS))
    parser.add_argument("--dump-dir", type=Path, default=DUMP_DIR)
    parser.add_argument("--out-dir", type=Path, default=OUT_DIR)
    parser.add_argument(
        "--reuse",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="reuse ab/out/oracle_multiseed CSVs when present (default: reuse)",
    )
    parser.add_argument(
        "--from-csv",
        type=Path,
        default=None,
        help="recompute the summary from a per-seed CSV; do not dump",
    )
    args = parser.parse_args(argv)
    for problem in args.problems:
        registered_knobs(problem)
    if args.from_csv is not None:
        rows = read_csv(args.from_csv)
    else:
        rows = collect(list(args.problems), list(args.seeds), args.dump_dir, args.reuse)
    summary = write_outputs(rows, args.out_dir)
    if summary["verdict"] == "incomplete":
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
