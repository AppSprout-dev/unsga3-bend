# Multi-seed IGD + Layer-1 fixture check

Confidence tables for **unsga3-bend** vs C# [Unsga3](https://github.com/AppSprout-dev/Unsga3) vs a **pymoo NSGA-III** run. Same public knobs as [EQUIVALENCE.md](EQUIVALENCE.md) / [`ab/protocol.py`](../ab/protocol.py). Same IGD yardstick: [`ab/igd_vs_pymoo.py`](../ab/igd_vs_pymoo.py).

**No invented numbers.** Every IGD cell is a real `igd=` line from a dumped front, or `skip:`. Reproduce with [`ab/oracle_multiseed.py`](../ab/oracle_multiseed.py) and [`ab/fixture_check.py`](../ab/fixture_check.py).

This is a GitHub **0.1.1** docs/ab confidence bump. Hub package **0.1.0** is unchanged (`import 0xcd07e24a626a62e74603d48f436cd679/lib.bend as Unsga3`). No hub re-publish.

## Protocol knobs (do not change the algorithm)

Operators: SBX η=30, PM η=20, p_c=1.0, p_m=1/n. Bend and C# tournament: `PymooCompatible`. pymoo column is **NSGA-III** (no U-NSGA-III mating tournament). C# published seed-1 tables compare to pymoo **UNSGA3** — that is a different algorithm column and is **not** copied here.

| Problem | Partitions | Pop | Gens | Tournament (Bend / C#) |
|---------|------------|-----|------|------------------------|
| ZDT1 n=30 | 12 | 52 | 100 | PymooCompatible |
| ZDT2 n=30 | 12 | 52 | **250** | PymooCompatible |
| DTLZ2 M=3 k=10 | 12 | 92 | 150 | PymooCompatible |

IGD = pymoo `IGD` mean nearest-neighbor distance.

| Problem | PF | Expected `pf_rows` | `pf_source` |
|---------|----|-------------------:|-------------|
| ZDT1 | analytic `f2 = 1 − √f1`, 500 pts | 500 | `analytic-zdt1 n=500` |
| ZDT2 | analytic `f2 = 1 − f1²`, 500 pts | 500 | `analytic-zdt2 n=500` |
| DTLZ2 | Das–Dennis density at partitions (not pymoo default ~136-pt sample) | 91 | `pymoo-das-dennis` |

ZDT2 **gens=100** is an early-stress snapshot, not this table — [ZDT2_COLLAPSE.md](ZDT2_COLLAPSE.md).

Intentional Run-path deltas (not Layer-1): Bend RNG is a portable LCG, not `System.Random`. Fronts will not match bit-for-bit. v0 sort is Pareto-only. Last-front extras on Bend are random among near-best on the ray.

## How to reproduce

```bash
export PATH="$HOME/.bend/bin:$HOME/.dotnet:$PATH"
export BEND_NO_TELEMETRY=1
export DOTNET_ROOT="$HOME/.dotnet"
# C# checkout *outside* this repo (do not vendor Unsga3)
export UNSGA3_CS_ROOT=/path/to/Unsga3

python3 ab/oracle_multiseed.py
python3 ab/fixture_check.py
```

`--reuse` skips a dump when the CSV already exists. `--seeds 1` / `--problems zdt1` are subsets; document every seed you actually ran.

`dump_csharp_run.py` and the csharp stack skip without `UNSGA3_CS_ROOT` / `dotnet`. `dump_pymoo_nsga3.py` skips without pymoo. Do not invent a front or IGD.

## Host for the tables below

Filled after a real driver run on this PR. Empty / `skip:` cells mean that stack was not dumped.

- Date:
- Bend:
- C# Unsga3 (`UNSGA3_CS_ROOT`):
- pymoo:
- .NET:
- Host:
- Seeds requested: 1–15
- Seeds actually run: *(fill after the driver)*

## Layer-1 fixture bit-check

`ab/fixture_check.py` dumps Bend `Survival.select` and C# `NondominatedSortingSurvival.Select(rng: null)` on the same objective fixture, then `ab/compare.py` row-set equality. That is the end-to-end of sort → normalize → associate → select. Intermediate ranks are not serialized; selected objective rows are the contract.

| Fixture | Bend dump | C# dump | `row_set_equal` | Verdict |
|---------|-----------|---------|-----------------|--------|
| `ab/fixtures/core_2obj.json` | *(pending)* | *(pending)* | *(pending)* | *(pending)* |

No other shared fixtures are checked in. Intentional Run-path deltas (LCG ≠ `System.Random`, Pareto-only, last-front extras) do **not** apply to this deterministic select. A fail is diagnosed, not “fixed” by weakening `LAWS.bend` or changing dominance.

## Measured IGD tables

Cells are `igd=` from `ab/igd_vs_pymoo.py` on a real CSV, or `skip:`. Ratios are Bend/C# and Bend/pymoo from those same numbers only.

### ZDT1 / ZDT2 / DTLZ2

Tables are written by `python3 ab/oracle_multiseed.py` (stdout markdown). This revision’s measured block is filled after the driver finishes; see the PR for the run log if a stack skipped.

*(tables pending a real `ab/oracle_multiseed.py` run on this branch)*
