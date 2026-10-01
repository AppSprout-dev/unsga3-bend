# Catalog IGD

Measured fronts for the unconstrained catalog in [`src/problems.bend`](../src/problems.bend). This is **not** the ZDT1 / ZDT2 / DTLZ2 quality table ([ORACLE-MULTISEED.md](ORACLE-MULTISEED.md)). Those budgets were not re-run, and their published cells are unchanged.

**No invented numbers.** Every IGD cell below is a real `igd=` line from [`ab/igd_vs_pymoo.py`](../ab/igd_vs_pymoo.py), or the `skip:` line the dumper printed. The per-seed tables are the stdout of [`ab/oracle_catalog.py`](../ab/oracle_catalog.py) from the run recorded in this file, except the DTLZ3 Bend column, which is the 2026-10-01 remeasure in [DTLZ3_AXIS.md](DTLZ3_AXIS.md).

## Protocol

C# `tools/OracleCompare` accepts only zdt1, zdt2, and dtlz2. There is no published C# catalog IGD table. This file uses [`ab/protocol.py`](../ab/protocol.py) `catalog_knobs`. Tournament on Bend and C# is `PymooCompatible`.

| Problems | Sibling budget | Partitions | Pop | Gens | Decision n |
|----------|----------------|------------|-----|------|------------|
| ZDT3, ZDT4, ZDT6 | ZDT1 | 12 | 52 | 100 | 30, 10, 10 |
| DTLZ1, DTLZ3, DTLZ4, DTLZ7 | DTLZ2 | 12 | 92 | 150 | 7, 12, 12, 22 |
| Sphere, Ackley, Rosenbrock | short smoke | 1 | 20 | 40 | 10, 30, 10 |

Operators: SBX η=30, PM η=20, p_c=1.0, p_m=1/n. The pymoo column is **NSGA-III** (`res.F`), not U-NSGA-III. The Bend column is `nd_front`. The C# column is the feasible non-dominated front (`NonDominatedSolutions`), the same definition as `OracleCompare`. C# runs through [`ab/dump_csharp_catalog.py`](../ab/dump_csharp_catalog.py) because `OracleCompare` rejects these names.

Omitted flags on `dump_bend_run.py` for these names stay the 4/8/3 smoke. That smoke is not this table.

Single-objective IGD is mean distance to the known minimum `f = 0` (`pf_rows=1`). On this run every single-objective front has `n=1`, so the cell is that point's objective. C# CI smokes use smaller `n`, `RankNicheDistance`, and different pop/gens. They are not this budget.

Pareto sets: ZDT3 segments (100 points each, C# endpoint `0.1822287280`), ZDT4 = ZDT1 (500 points), ZDT6 floor `0.280775` (500 points), DTLZ1 half-simplex (91 points at p=12), DTLZ3 / DTLZ4 = DTLZ2 Das–Dennis sphere (`pf_source=pymoo-das-dennis`, 91 points). DTLZ7 is pymoo `pareto_front()` (`pf_rows=9409`). C# `ParetoFronts` has no DTLZ7 sample.

pymoo `sphere` is `[0,1]^n`. Bend/C# Sphere is `Σ x²` on `[-5.12, 5.12]^n`. That pymoo column skips.

## How to reproduce

```bash
export PATH="$HOME/.bend/bin:$HOME/.dotnet:$PATH"
export BEND_NO_TELEMETRY=1
export DOTNET_ROOT="$HOME/.dotnet"
# C# checkout *outside* this repo (do not vendor Unsga3)
export UNSGA3_CS_ROOT=/path/to/Unsga3

python3 ab/oracle_catalog.py
```

`--reuse` keeps an existing non-empty CSV. `--seeds` / `--problems` / `--stacks` select a subset.

## Host for the tables below

- Date: 2026-09-30
- Bend: **2.0.34** (`dump_bend_run.py --native`; each seed recompiles because the seed is in the driver source)
- C# Unsga3: sibling checkout **`ef30350`** (`UNSGA3_CS_ROOT=/home/ubuntu/Unsga3`, generated `CatalogDump` Release / net10.0, `TournamentMode.PymooCompatible`). Not `OracleCompare`.
- pymoo: **0.6.2** `NSGA3` (SBX η=30 p_c=1.0, PM η=20 p_m=1/n)
- .NET: 10.0.401
- Host: 4-core, clang 18.1.3, Linux 6.12.94+
- Seeds requested: **1–15**
- Seeds actually run: **1–15** on Bend and C# for all ten problems, and on pymoo for every problem except Sphere (450 cells: 435 `igd=`, 15 `skip:`). DTLZ3 Bend cells in the table below were replaced on 2026-10-01; see that section. C# and pymoo DTLZ3 cells are still this run.

Independent re-score of five CSVs matched `summary.jsonl` exactly: Bend ZDT3 seed 1, C# DTLZ1 seed 1, pymoo DTLZ4 seed 7, Bend Sphere seed 1, C# DTLZ3 seed 1.

## Summary

Medians are the middle of the 15 scored values (same `median` as `oracle_catalog.py`). `Bend ≤ C#` counts seeds where both IGD cells exist and the Bend value is less than or equal to the C# value.

| Problem | Seeds scored Bend / C# / pymoo | median Bend | median C# | median pymoo NSGA-III | Bend ≤ C# |
|---------|-------------------------------:|------------:|----------:|----------------------:|----------:|
| ZDT3 | 15 / 15 / 15 | 0.064373 | 0.085054 | 0.191695 | 8/15 |
| ZDT4 | 15 / 15 / 15 | 1.114062 | 1.436214 | 2.729499 | 10/15 |
| ZDT6 | 15 / 15 / 15 | 0.428493 | 0.458743 | 1.886953 | 10/15 |
| DTLZ1 | 15 / 15 / 15 | 0.041311 | 0.039917 | 0.300591 | 10/15 |
| DTLZ3 | 15 / 15 / 15 | 8.239578 | 8.879998 | 8.366071 | 11/15 |
| DTLZ4 | 15 / 15 / 15 | 0.005314 | 0.005176 | 0.005338 | 7/15 |
| DTLZ7 | 15 / 15 / 15 | 0.086268 | 0.079355 | 0.174674 | 1/15 |
| Sphere | 15 / 15 / 0 | 0.082017 | 0.115043 |  | 9/15 |
| Ackley | 15 / 15 / 15 | 15.227343 | 15.805896 | 17.081400 | 9/15 |
| Rosenbrock | 15 / 15 / 15 | 11.394421 | 14.083640 | 85.959115 | 8/15 |

ZDT4 at the ZDT1 generation budget keeps Bend median IGD 1.114062, and the Bend `n` column is below 52 on 14 of 15 seeds. DTLZ3 Bend was remeasured on 2026-10-01 after the axis-cosine clamp ([DTLZ3_AXIS.md](DTLZ3_AXIS.md)); median IGD is 8.239578 and Bend ≤ C# on 11/15 seeds. The 2026-09-30 Bend median was 26.249240 (0/15). C# and pymoo in that row were not re-run. DTLZ4 `pf_rows=91`. Sphere pymoo is the only algorithm skip. Ackley and Rosenbrock are the short smoke (`n=1` on every scored front).

## Constrained problems

OSY, TNK, and C1-DTLZ1 are not implemented in this tree. C# Unsga3 owns those demos (`ConstrainedProblemTests`). C# `docs/EQUIVALENCE.md` records no IGD table for them, and `tools/OracleCompare` does not accept those names. Bend has Deb constraint-domination; the shipped catalog writes no constraint vector.

No front was dumped. No IGD was computed.

| Problem | Bend | C# | pymoo NSGA-III |
|---------|------|----|----------------|
| OSY | skip: problem not in this tree | skip: not measured; C# demo, no OracleCompare protocol | skip: not run |
| TNK | skip: problem not in this tree | skip: not measured; C# demo, no OracleCompare protocol | skip: not run |
| C1-DTLZ1 | skip: problem not in this tree | skip: not measured; C# demo, no OracleCompare protocol | skip: not run |


### ZDT3 (n_var=30, n_obj=2, p=12, pop=52, gens=100, PymooCompatible / pymoo NSGA-III; sibling `zdt1`)

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 0.082128 | 0.052106 | 0.166849 | 1.576 | 0.492 | 52 | 52 | 11 |
| 2 | 0.052972 | 0.120937 | 0.285115 | 0.438 | 0.186 | 52 | 52 | 11 |
| 3 | 0.072785 | 0.073637 | 0.215422 | 0.988 | 0.338 | 52 | 52 | 11 |
| 4 | 0.087683 | 0.055497 | 0.216943 | 1.580 | 0.404 | 52 | 52 | 11 |
| 5 | 0.133492 | 0.060755 | 0.182292 | 2.197 | 0.732 | 52 | 52 | 11 |
| 6 | 0.043277 | 0.132342 | 0.293826 | 0.327 | 0.147 | 52 | 52 | 12 |
| 7 | 0.052991 | 0.039049 | 0.186797 | 1.357 | 0.284 | 52 | 52 | 12 |
| 8 | 0.059249 | 0.131617 | 0.217912 | 0.450 | 0.272 | 52 | 52 | 12 |
| 9 | 0.117105 | 0.101646 | 0.202813 | 1.152 | 0.577 | 52 | 52 | 11 |
| 10 | 0.068151 | 0.050136 | 0.191695 | 1.359 | 0.356 | 52 | 52 | 11 |
| 11 | 0.134024 | 0.116504 | 0.217505 | 1.150 | 0.616 | 52 | 52 | 12 |
| 12 | 0.052062 | 0.097551 | 0.176388 | 0.534 | 0.295 | 52 | 52 | 11 |
| 13 | 0.064373 | 0.085054 | 0.182236 | 0.757 | 0.353 | 52 | 52 | 12 |
| 14 | 0.034961 | 0.051772 | 0.141694 | 0.675 | 0.247 | 52 | 52 | 11 |
| 15 | 0.044327 | 0.096528 | 0.177342 | 0.459 | 0.250 | 52 | 52 | 13 |

Seeds actually scored: Bend [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; C# [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; pymoo [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15].
Median IGD (Bend 0.064373, C# 0.085054, pymoo NSGA-III 0.191695).
PF yardstick: pf_source=`analytic-zdt3 segments=5 points_per=100`, pf_rows=500, partitions=12.

### ZDT4 (n_var=10, n_obj=2, p=12, pop=52, gens=100, PymooCompatible / pymoo NSGA-III; sibling `zdt1`)

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 0.655620 | 1.175931 | 3.011480 | 0.558 | 0.218 | 10 | 10 | 7 |
| 2 | 1.096338 | 1.535809 | 2.198752 | 0.714 | 0.499 | 17 | 11 | 5 |
| 3 | 2.106545 | 0.528737 | 0.850924 | 3.984 | 2.476 | 7 | 32 | 3 |
| 4 | 0.978996 | 1.624865 | 1.557012 | 0.603 | 0.629 | 8 | 8 | 8 |
| 5 | 1.568711 | 1.186097 | 2.513655 | 1.323 | 0.624 | 13 | 7 | 10 |
| 6 | 2.236642 | 1.339476 | 7.037234 | 1.670 | 0.318 | 10 | 13 | 3 |
| 7 | 0.476676 | 1.152009 | 0.518181 | 0.414 | 0.920 | 28 | 8 | 4 |
| 8 | 1.454509 | 1.808940 | 4.452907 | 0.804 | 0.327 | 4 | 11 | 10 |
| 9 | 1.114062 | 2.140888 | 8.426129 | 0.520 | 0.132 | 23 | 10 | 3 |
| 10 | 2.275411 | 1.428500 | 2.729499 | 1.593 | 0.834 | 11 | 16 | 3 |
| 11 | 2.456453 | 1.299978 | 3.319881 | 1.890 | 0.740 | 16 | 5 | 10 |
| 12 | 0.961000 | 2.177797 | 3.079390 | 0.441 | 0.312 | 14 | 12 | 4 |
| 13 | 0.547531 | 1.460128 | 3.615460 | 0.375 | 0.151 | 36 | 10 | 9 |
| 14 | 0.962730 | 1.907781 | 1.512030 | 0.505 | 0.637 | 52 | 18 | 8 |
| 15 | 1.183941 | 1.436214 | 1.383795 | 0.824 | 0.856 | 8 | 5 | 6 |

Seeds actually scored: Bend [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; C# [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; pymoo [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15].
Median IGD (Bend 1.114062, C# 1.436214, pymoo NSGA-III 2.729499).
PF yardstick: pf_source=`analytic-zdt4 n=500`, pf_rows=500, partitions=12.

### ZDT6 (n_var=10, n_obj=2, p=12, pop=52, gens=100, PymooCompatible / pymoo NSGA-III; sibling `zdt1`)

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 0.558819 | 0.453689 | 1.886953 | 1.232 | 0.296 | 16 | 14 | 6 |
| 2 | 0.428493 | 0.642843 | 2.349408 | 0.667 | 0.182 | 28 | 18 | 3 |
| 3 | 0.453720 | 0.405031 | 2.002592 | 1.120 | 0.227 | 18 | 23 | 5 |
| 4 | 0.438862 | 0.418976 | 1.873881 | 1.047 | 0.234 | 14 | 16 | 4 |
| 5 | 0.380211 | 0.493238 | 1.849839 | 0.771 | 0.206 | 25 | 16 | 6 |
| 6 | 0.304106 | 0.337747 | 1.701408 | 0.900 | 0.179 | 32 | 35 | 5 |
| 7 | 0.559048 | 0.458743 | 1.621840 | 1.219 | 0.345 | 12 | 26 | 3 |
| 8 | 0.494155 | 0.536383 | 2.197579 | 0.921 | 0.225 | 19 | 20 | 6 |
| 9 | 0.419828 | 0.430404 | 1.178379 | 0.975 | 0.356 | 26 | 28 | 7 |
| 10 | 0.283537 | 0.446247 | 2.521945 | 0.635 | 0.112 | 22 | 24 | 2 |
| 11 | 0.420065 | 0.531323 | 1.971543 | 0.791 | 0.213 | 22 | 16 | 3 |
| 12 | 0.338316 | 0.381292 | 2.267994 | 0.887 | 0.149 | 19 | 24 | 2 |
| 13 | 0.433125 | 0.568436 | 1.570726 | 0.762 | 0.276 | 32 | 13 | 3 |
| 14 | 0.397539 | 0.463652 | 1.884640 | 0.857 | 0.211 | 20 | 32 | 4 |
| 15 | 0.540658 | 0.505444 | 2.033435 | 1.070 | 0.266 | 26 | 22 | 2 |

Seeds actually scored: Bend [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; C# [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; pymoo [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15].
Median IGD (Bend 0.428493, C# 0.458743, pymoo NSGA-III 1.886953).
PF yardstick: pf_source=`analytic-zdt6 n=500 f1min=0.280775`, pf_rows=500, partitions=12.

### DTLZ1 (n_var=7, n_obj=3, p=12, pop=92, gens=150, PymooCompatible / pymoo NSGA-III; sibling `dtlz2`)

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 0.015281 | 0.043113 | 0.299157 | 0.354 | 0.051 | 92 | 92 | 89 |
| 2 | 0.391685 | 0.055160 | 0.301819 | 7.101 | 1.298 | 92 | 92 | 63 |
| 3 | 0.041311 | 0.023484 | 0.006564 | 1.759 | 6.294 | 92 | 92 | 86 |
| 4 | 0.019816 | 0.086106 | 0.295850 | 0.230 | 0.067 | 92 | 91 | 84 |
| 5 | 0.043732 | 0.091618 | 0.313341 | 0.477 | 0.140 | 92 | 76 | 69 |
| 6 | 0.308067 | 0.039917 | 0.588358 | 7.718 | 0.524 | 92 | 92 | 84 |
| 7 | 0.022377 | 0.023038 | 0.294302 | 0.971 | 0.076 | 92 | 92 | 91 |
| 8 | 0.021984 | 0.030286 | 0.020926 | 0.726 | 1.051 | 92 | 92 | 69 |
| 9 | 0.021314 | 0.302513 | 1.453034 | 0.070 | 0.015 | 92 | 92 | 91 |
| 10 | 0.076754 | 0.027797 | 0.300591 | 2.761 | 0.255 | 92 | 92 | 79 |
| 11 | 0.018830 | 0.035062 | 0.023983 | 0.537 | 0.785 | 92 | 92 | 74 |
| 12 | 0.020299 | 0.028620 | 0.296629 | 0.709 | 0.068 | 92 | 92 | 85 |
| 13 | 0.086397 | 0.036281 | 0.332547 | 2.381 | 0.260 | 89 | 92 | 58 |
| 14 | 0.042501 | 0.083292 | 0.877915 | 0.510 | 0.048 | 92 | 74 | 88 |
| 15 | 0.042729 | 0.115700 | 0.876548 | 0.369 | 0.049 | 92 | 84 | 84 |

Seeds actually scored: Bend [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; C# [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; pymoo [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15].
Median IGD (Bend 0.041311, C# 0.039917, pymoo NSGA-III 0.300591).
PF yardstick: pf_source=`analytic-dtlz1-half-simplex`, pf_rows=91, partitions=12.

### DTLZ3 (n_var=12, n_obj=3, p=12, pop=92, gens=150, PymooCompatible / pymoo NSGA-III; sibling `dtlz2`)

Bend cells are the 2026-10-01 remeasure after the F32 axis clamp (`dump_bend_run.py --native --threads 4`, Bend 2.0.34, scored by `igd_vs_pymoo.py`). C# and pymoo cells are the 2026-09-30 run and were not repeated. Cause and the pre-fix Bend column: [DTLZ3_AXIS.md](DTLZ3_AXIS.md).

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 12.820729 | 16.438212 | 5.032098 | 0.780 | 2.548 | 77 | 61 | 43 |
| 2 | 10.552080 | 17.450459 | 20.061152 | 0.605 | 0.526 | 27 | 53 | 63 |
| 3 | 4.235343 | 8.614599 | 9.222801 | 0.492 | 0.459 | 55 | 59 | 53 |
| 4 | 8.723205 | 13.753291 | 7.100755 | 0.634 | 1.228 | 57 | 63 | 47 |
| 5 | 5.888764 | 8.879998 | 8.366071 | 0.663 | 0.704 | 62 | 73 | 44 |
| 6 | 14.755559 | 4.597384 | 8.893172 | 3.210 | 1.659 | 84 | 71 | 40 |
| 7 | 9.243434 | 11.963956 | 15.122474 | 0.773 | 0.611 | 61 | 77 | 54 |
| 8 | 7.299384 | 7.117607 | 4.063408 | 1.026 | 1.796 | 40 | 70 | 56 |
| 9 | 5.023930 | 15.670052 | 2.185604 | 0.321 | 2.299 | 61 | 88 | 23 |
| 10 | 11.456296 | 8.213816 | 7.084399 | 1.395 | 1.617 | 73 | 73 | 47 |
| 11 | 2.911215 | 6.943016 | 8.131713 | 0.419 | 0.358 | 44 | 54 | 46 |
| 12 | 10.265392 | 5.351800 | 12.176215 | 1.918 | 0.843 | 51 | 88 | 60 |
| 13 | 6.445288 | 9.323371 | 5.063550 | 0.691 | 1.273 | 63 | 74 | 55 |
| 14 | 6.200517 | 7.473292 | 10.168770 | 0.830 | 0.610 | 44 | 60 | 55 |
| 15 | 8.239578 | 10.739241 | 22.118049 | 0.767 | 0.373 | 81 | 78 | 52 |

Seeds actually scored: Bend [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] (2026-10-01); C# [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] (2026-09-30); pymoo [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] (2026-09-30).
Median IGD (Bend 8.239578, C# 8.879998, pymoo NSGA-III 8.366071).
PF yardstick: pf_source=`pymoo-das-dennis`, pf_rows=91, partitions=12.

### DTLZ4 (n_var=12, n_obj=3, p=12, pop=92, gens=150, PymooCompatible / pymoo NSGA-III; sibling `dtlz2`)

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 0.533444 | 0.005176 | 0.003346 | 103.063 | 159.417 | 92 | 92 | 91 |
| 2 | 0.004516 | 0.005127 | 0.950354 | 0.881 | 0.005 | 92 | 92 | 2 |
| 3 | 0.007582 | 0.530975 | 0.532168 | 0.014 | 0.014 | 92 | 92 | 14 |
| 4 | 0.003268 | 0.005153 | 0.002921 | 0.634 | 1.119 | 92 | 92 | 91 |
| 5 | 0.535225 | 0.004304 | 0.532236 | 124.343 | 1.006 | 92 | 92 | 15 |
| 6 | 0.536119 | 0.531164 | 0.532266 | 1.009 | 1.007 | 92 | 92 | 16 |
| 7 | 0.005314 | 0.004769 | 0.531894 | 1.114 | 0.010 | 92 | 92 | 20 |
| 8 | 0.007248 | 0.004367 | 0.532060 | 1.660 | 0.014 | 92 | 92 | 22 |
| 9 | 0.004064 | 0.004159 | 0.002361 | 0.977 | 1.721 | 92 | 92 | 91 |
| 10 | 0.004847 | 0.003901 | 0.002830 | 1.242 | 1.713 | 92 | 92 | 91 |
| 11 | 0.005085 | 0.531201 | 0.002650 | 0.010 | 1.919 | 92 | 92 | 91 |
| 12 | 0.005231 | 0.530851 | 0.005338 | 0.010 | 0.980 | 92 | 92 | 91 |
| 13 | 0.533565 | 0.531274 | 0.531540 | 1.004 | 1.004 | 92 | 92 | 21 |
| 14 | 0.005261 | 0.531118 | 0.002980 | 0.010 | 1.766 | 92 | 92 | 91 |
| 15 | 0.533205 | 0.006788 | 0.002141 | 78.555 | 249.041 | 92 | 92 | 91 |

Seeds actually scored: Bend [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; C# [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; pymoo [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15].
Median IGD (Bend 0.005314, C# 0.005176, pymoo NSGA-III 0.005338).
PF yardstick: pf_source=`pymoo-das-dennis`, pf_rows=91, partitions=12.

### DTLZ7 (n_var=22, n_obj=3, p=12, pop=92, gens=150, PymooCompatible / pymoo NSGA-III; sibling `dtlz2`)

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 0.082009 | 0.079439 | 0.193075 | 1.032 | 0.425 | 92 | 92 | 40 |
| 2 | 0.085153 | 0.077457 | 0.234955 | 1.099 | 0.362 | 92 | 92 | 43 |
| 3 | 0.086540 | 0.073737 | 0.165439 | 1.174 | 0.523 | 92 | 92 | 44 |
| 4 | 0.086268 | 0.080455 | 0.164459 | 1.072 | 0.525 | 92 | 92 | 46 |
| 5 | 0.086250 | 0.359189 | 0.147197 | 0.240 | 0.586 | 92 | 92 | 44 |
| 6 | 0.090258 | 0.083694 | 0.435684 | 1.078 | 0.207 | 92 | 92 | 46 |
| 7 | 0.362612 | 0.080780 | 0.156896 | 4.489 | 2.311 | 92 | 92 | 42 |
| 8 | 0.081636 | 0.079355 | 0.174674 | 1.029 | 0.467 | 92 | 92 | 44 |
| 9 | 0.084749 | 0.075841 | 0.167830 | 1.117 | 0.505 | 92 | 92 | 44 |
| 10 | 0.087616 | 0.077611 | 0.240570 | 1.129 | 0.364 | 92 | 92 | 44 |
| 11 | 0.086638 | 0.077694 | 0.166746 | 1.115 | 0.520 | 92 | 92 | 42 |
| 12 | 0.086038 | 0.084853 | 0.277387 | 1.014 | 0.310 | 92 | 92 | 44 |
| 13 | 0.361897 | 0.074214 | 0.245330 | 4.876 | 1.475 | 92 | 92 | 46 |
| 14 | 0.084710 | 0.077655 | 0.143192 | 1.091 | 0.592 | 92 | 92 | 44 |
| 15 | 0.087508 | 0.080367 | 0.235248 | 1.089 | 0.372 | 92 | 92 | 43 |

Seeds actually scored: Bend [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; C# [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; pymoo [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15].
Median IGD (Bend 0.086268, C# 0.079355, pymoo NSGA-III 0.174674).
PF yardstick: pf_source=`pymoo-pareto_front`, pf_rows=9409, partitions=12.

### SPHERE (n_var=10, n_obj=1, p=1, pop=20, gens=40, PymooCompatible / pymoo NSGA-III; sibling `short-smoke`)

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 0.197374 | 0.053798 | skip: pymoo sphere bounds xl0=0.0 xu0=1.0 n=10 differ from Bend/C# xl0=-5.12 xu0=5.12 n=10. Refusing to score a different problem. | 3.669 |  | 1 | 1 |  |
| 2 | 0.168011 | 0.139556 | skip: pymoo sphere bounds xl0=0.0 xu0=1.0 n=10 differ from Bend/C# xl0=-5.12 xu0=5.12 n=10. Refusing to score a different problem. | 1.204 |  | 1 | 1 |  |
| 3 | 0.068316 | 0.050291 | skip: pymoo sphere bounds xl0=0.0 xu0=1.0 n=10 differ from Bend/C# xl0=-5.12 xu0=5.12 n=10. Refusing to score a different problem. | 1.358 |  | 1 | 1 |  |
| 4 | 0.135601 | 0.282653 | skip: pymoo sphere bounds xl0=0.0 xu0=1.0 n=10 differ from Bend/C# xl0=-5.12 xu0=5.12 n=10. Refusing to score a different problem. | 0.480 |  | 1 | 1 |  |
| 5 | 0.040956 | 0.108726 | skip: pymoo sphere bounds xl0=0.0 xu0=1.0 n=10 differ from Bend/C# xl0=-5.12 xu0=5.12 n=10. Refusing to score a different problem. | 0.377 |  | 1 | 1 |  |
| 6 | 0.070019 | 0.192160 | skip: pymoo sphere bounds xl0=0.0 xu0=1.0 n=10 differ from Bend/C# xl0=-5.12 xu0=5.12 n=10. Refusing to score a different problem. | 0.364 |  | 1 | 1 |  |
| 7 | 0.075372 | 0.068947 | skip: pymoo sphere bounds xl0=0.0 xu0=1.0 n=10 differ from Bend/C# xl0=-5.12 xu0=5.12 n=10. Refusing to score a different problem. | 1.093 |  | 1 | 1 |  |
| 8 | 0.105184 | 0.115043 | skip: pymoo sphere bounds xl0=0.0 xu0=1.0 n=10 differ from Bend/C# xl0=-5.12 xu0=5.12 n=10. Refusing to score a different problem. | 0.914 |  | 1 | 1 |  |
| 9 | 0.054085 | 0.169092 | skip: pymoo sphere bounds xl0=0.0 xu0=1.0 n=10 differ from Bend/C# xl0=-5.12 xu0=5.12 n=10. Refusing to score a different problem. | 0.320 |  | 1 | 1 |  |
| 10 | 0.082017 | 0.139069 | skip: pymoo sphere bounds xl0=0.0 xu0=1.0 n=10 differ from Bend/C# xl0=-5.12 xu0=5.12 n=10. Refusing to score a different problem. | 0.590 |  | 1 | 1 |  |
| 11 | 0.020589 | 0.220292 | skip: pymoo sphere bounds xl0=0.0 xu0=1.0 n=10 differ from Bend/C# xl0=-5.12 xu0=5.12 n=10. Refusing to score a different problem. | 0.093 |  | 1 | 1 |  |
| 12 | 0.119575 | 0.093797 | skip: pymoo sphere bounds xl0=0.0 xu0=1.0 n=10 differ from Bend/C# xl0=-5.12 xu0=5.12 n=10. Refusing to score a different problem. | 1.275 |  | 1 | 1 |  |
| 13 | 0.028004 | 0.053337 | skip: pymoo sphere bounds xl0=0.0 xu0=1.0 n=10 differ from Bend/C# xl0=-5.12 xu0=5.12 n=10. Refusing to score a different problem. | 0.525 |  | 1 | 1 |  |
| 14 | 0.119576 | 0.156327 | skip: pymoo sphere bounds xl0=0.0 xu0=1.0 n=10 differ from Bend/C# xl0=-5.12 xu0=5.12 n=10. Refusing to score a different problem. | 0.765 |  | 1 | 1 |  |
| 15 | 0.136290 | 0.019094 | skip: pymoo sphere bounds xl0=0.0 xu0=1.0 n=10 differ from Bend/C# xl0=-5.12 xu0=5.12 n=10. Refusing to score a different problem. | 7.138 |  | 1 | 1 |  |

Seeds actually scored: Bend [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; C# [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; pymoo none.
Median IGD (Bend 0.082017, C# 0.115043).
PF yardstick: pf_source=`analytic-optimum f=0`, pf_rows=1, partitions=1.

### ACKLEY (n_var=30, n_obj=1, p=1, pop=20, gens=40, PymooCompatible / pymoo NSGA-III; sibling `short-smoke`)

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 14.483542 | 17.233740 | 17.081400 | 0.840 | 0.848 | 1 | 1 | 1 |
| 2 | 16.659447 | 15.623913 | 17.715359 | 1.066 | 0.940 | 1 | 1 | 1 |
| 3 | 13.937778 | 15.805896 | 14.528973 | 0.882 | 0.959 | 1 | 1 | 1 |
| 4 | 15.157275 | 14.858833 | 17.137113 | 1.020 | 0.884 | 1 | 1 | 1 |
| 5 | 16.111538 | 15.318148 | 16.024412 | 1.052 | 1.005 | 1 | 1 | 1 |
| 6 | 14.339580 | 18.111193 | 17.570615 | 0.792 | 0.816 | 1 | 1 | 1 |
| 7 | 16.541864 | 10.830930 | 16.884164 | 1.527 | 0.980 | 1 | 1 | 1 |
| 8 | 18.157883 | 16.991360 | 15.044172 | 1.069 | 1.207 | 1 | 1 | 1 |
| 9 | 15.438061 | 16.391823 | 17.256831 | 0.942 | 0.895 | 1 | 1 | 1 |
| 10 | 15.775872 | 16.438689 | 17.861538 | 0.960 | 0.883 | 1 | 1 | 1 |
| 11 | 13.757619 | 14.860714 | 16.804484 | 0.926 | 0.819 | 1 | 1 | 1 |
| 12 | 15.088251 | 18.469847 | 17.846301 | 0.817 | 0.845 | 1 | 1 | 1 |
| 13 | 15.227343 | 13.825979 | 16.434754 | 1.101 | 0.927 | 1 | 1 | 1 |
| 14 | 14.176331 | 14.909803 | 17.336757 | 0.951 | 0.818 | 1 | 1 | 1 |
| 15 | 15.977540 | 16.380989 | 16.725190 | 0.975 | 0.955 | 1 | 1 | 1 |

Seeds actually scored: Bend [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; C# [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; pymoo [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15].
Median IGD (Bend 15.227343, C# 15.805896, pymoo NSGA-III 17.081400).
PF yardstick: pf_source=`analytic-optimum f=0`, pf_rows=1, partitions=1.

### ROSENBROCK (n_var=10, n_obj=1, p=1, pop=20, gens=40, PymooCompatible / pymoo NSGA-III; sibling `short-smoke`)

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 59.927273 | 21.384032 | 120.461656 | 2.802 | 0.497 | 1 | 1 | 1 |
| 2 | 10.918201 | 66.495394 | 30.551141 | 0.164 | 0.357 | 1 | 1 | 1 |
| 3 | 93.128820 | 8.108717 | 30.177066 | 11.485 | 3.086 | 1 | 1 | 1 |
| 4 | 5.905213 | 76.481285 | 21.866167 | 0.077 | 0.270 | 1 | 1 | 1 |
| 5 | 11.394421 | 11.069157 | 88.702722 | 1.029 | 0.128 | 1 | 1 | 1 |
| 6 | 7.859034 | 12.012709 | 55.301241 | 0.654 | 0.142 | 1 | 1 | 1 |
| 7 | 65.766450 | 13.883703 | 95.988653 | 4.737 | 0.685 | 1 | 1 | 1 |
| 8 | 95.108700 | 9.855642 | 99.314092 | 9.650 | 0.958 | 1 | 1 | 1 |
| 9 | 24.292133 | 9.790853 | 93.935082 | 2.481 | 0.259 | 1 | 1 | 1 |
| 10 | 10.106291 | 13.536645 | 93.632749 | 0.747 | 0.108 | 1 | 1 | 1 |
| 11 | 10.847264 | 14.083640 | 84.892784 | 0.770 | 0.128 | 1 | 1 | 1 |
| 12 | 13.533486 | 17.478765 | 85.881085 | 0.774 | 0.158 | 1 | 1 | 1 |
| 13 | 70.889760 | 35.129738 | 54.976008 | 2.018 | 1.289 | 1 | 1 | 1 |
| 14 | 9.823738 | 24.280416 | 147.119711 | 0.405 | 0.067 | 1 | 1 | 1 |
| 15 | 10.664533 | 73.045916 | 85.959115 | 0.146 | 0.124 | 1 | 1 | 1 |

Seeds actually scored: Bend [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; C# [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; pymoo [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15].
Median IGD (Bend 11.394421, C# 14.083640, pymoo NSGA-III 85.959115).
PF yardstick: pf_source=`analytic-optimum f=0`, pf_rows=1, partitions=1.
Constrained names not dumped: osy, tnk, c1dtlz1. See the constrained section above.
