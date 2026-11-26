# Multi-seed IGD + Layer-1 fixture check

Confidence tables for **unsga3-bend** vs C# [Unsga3](https://github.com/AppSprout-dev/Unsga3) vs a **pymoo NSGA-III** run. Same public knobs as [EQUIVALENCE.md](EQUIVALENCE.md) / [`ab/protocol.py`](../ab/protocol.py). Same IGD yardstick: [`ab/igd_vs_pymoo.py`](../ab/igd_vs_pymoo.py).

**No invented numbers.** Every IGD cell is a real `igd=` line from a dumped front. Reproduce with [`ab/oracle_multiseed.py`](../ab/oracle_multiseed.py) and [`ab/fixture_check.py`](../ab/fixture_check.py).

These tables were refreshed on **2026-11-26** across all 15 seeds (135/135 scored, 0 skips) against C# `Unsga3` @ `b350a88` and Bend `2.0.40` (post-audit `next_pair` wrap fix, `@unsafe`-free proof wall, and C# PR #19). Current published hub package remains **0.2.2** (`import 0xd1de66b5d9157913a654c39186289f3d/lib.bend as Unsga3`). `unified-nsga-iii@0.2.0.0` still names `0xa2f9d6ef8c474468bf1de15ebe70c512`. The runs use `PymooCompatible`. The 0.1.2 RankNicheDistance fix is outside this default. Catalog measurements are a separate protocol: [ORACLE-CATALOG.md](ORACLE-CATALOG.md).

## Protocol knobs

Operators: SBX η=30, PM η=20, p_c=1.0, p_m=1/n. Bend and C# tournament: `PymooCompatible`. pymoo column is **NSGA-III** (no U-NSGA-III mating tournament) with those same operator knobs. C# published seed-1 tables compare to pymoo **UNSGA3** with library PM default (`prob=0.9`) — that is a different algorithm / mutation column and is **not** copied here.

| Problem | Partitions | Pop | Gens | Tournament (Bend / C#) |
|---------|------------|-----|------|------------------------|
| ZDT1 n=30 | 12 | 52 | 100 | PymooCompatible |
| ZDT2 n=30 | 12 | 52 | **250** | PymooCompatible |
| DTLZ2 M=3 k=10 | 12 | 92 | 150 | PymooCompatible |

IGD = pymoo `IGD` mean nearest-neighbor distance.

| Problem | PF | `pf_rows` | `pf_source` |
|---------|----|----------:|-------------|
| ZDT1 | analytic `f2 = 1 − √f1`, 500 pts | 500 | `analytic-zdt1 n=500` |
| ZDT2 | analytic `f2 = 1 − f1²`, 500 pts | 500 | `analytic-zdt2 n=500` |
| DTLZ2 | Das–Dennis density at partitions (not pymoo default ~136-pt sample) | 91 | `pymoo-das-dennis` |

ZDT2 **gens=100** is an early-stress snapshot, not this table — [ZDT2_COLLAPSE.md](ZDT2_COLLAPSE.md).

Intentional Run-path deltas (not Layer-1): Bend RNG is a portable LCG, not `System.Random`. Fronts will not match bit-for-bit. These measured runs are unconstrained (CV = 0), so constraint-domination agrees with Pareto. Last-front extras on Bend are random among near-best on the ray.

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

`--reuse` skips a dump when the CSV already exists. `--seeds` / `--problems` / `--stacks` select a subset; list every seed you actually ran.

`dump_csharp_run.py` skips without `UNSGA3_CS_ROOT` / `dotnet`. `dump_pymoo_nsga3.py` skips without pymoo. Do not invent a front or IGD.

## Host for the tables below

- Date: 2026-11-26
- Bend: **2.0.40** (`dump_bend_run.py --native`, warm cache per generated driver; each seed compiles against current `src/*.bend`)
- C# Unsga3: sibling checkout **`b350a88`** (`OracleCompare` Release / net10.0, `--pymoo-mode`)
- pymoo: **0.6.2** `NSGA3` (`ab/dump_pymoo_nsga3.py`: SBX η=30 p_c=1.0, PM η=20 p_m=1/n)
- .NET: 10.0.115
- Host: 2-core, clang 18.1.3, Linux 6.18.57
- Seeds requested: **1–15**
- Seeds actually run: **1–15** on all three stacks, all three problems (135/135 `igd=` lines; 0 skips)

## Layer-1 fixture bit-check

`ab/fixture_check.py` dumps Bend `Survival.select` and C# `NondominatedSortingSurvival.Select(rng: null)` on the same objective fixtures, then `ab/compare.py` checks row-set equality. That is the end-to-end of sort → normalize → associate → select. Intermediate ranks are not serialized; selected objective rows are the contract.

| Fixture | Bend dump | C# dump | `row_set_equal` | Verdict |
|---------|-----------|---------|-----------------|--------|
| `ab/fixtures/core_2obj.json` | ok (5 rows) | ok (5 rows) | **True** | **pass** |
| `ab/fixtures/core_3obj.json` | ok (6 rows) | ok (6 rows) | **True** | **pass** |
| `ab/fixtures/collapsed_span_2obj.json` | ok (4 rows) | ok (4 rows) | **True** | **pass** |

- `core_2obj.json` selected row-set (parsed floats): `(0,1)`, `(0.2,0.9)`, `(0.5,0.5)`, `(0.9,0.2)`, `(1,0)`. Dominated `(0.8,0.8)` and `(1,1)` are dropped; `(0.1,0.95)` is not taken at `target_size=5`.
- `core_3obj.json` exercises 3-objective normalization and Das–Dennis association (`target_size=6`).
- `collapsed_span_2obj.json` exercises collapsed objective-span fallback (`f2 <= 4e-7`, `target_size=4`).

C# writes G17 doubles (`0.20000000000000001`); Bend prints shorter F32 text (`0.2`). `compare.py` equality is after Python `float` parse — same contract as Layer-1 smoke.

Intentional Run-path deltas (LCG ≠ `System.Random`, last-front extras) do **not** apply to this deterministic select. The fixtures have no constraints, so constraint-domination matches Pareto. No law was weakened.

## Measured IGD tables

Ratios are Bend/C# and Bend/pymoo from the same `igd=` cells only. `n` is ND front rows on that dump.

### Summary

| Problem | Seeds | median Bend | median C# | median pymoo NSGA-III | Bend ≤ C# | notes |
|---------|------:|------------:|----------:|----------------------:|----------:|-------|
| ZDT1 | 1–15 | 0.071400 | 0.076420 | 0.289958 | 10/15 | Bend/C# keep ~52 pts; pymoo NSGA-III reports ~12 ND (one per ray) |
| ZDT2 | 1–15 | 0.024344 | 0.018612 | 0.646092 | 6/15 | Bend/C# 0/15 collapse (`n=52`). pymoo NSGA-III + p_m=1/n often piles (n=1–3) |
| DTLZ2 | 1–15 | 0.004172 | 0.004090 | 0.002194 | 6/15 | all `n=92` / `91`; PF `pymoo-das-dennis` 91 pts |

pymoo NSGA-III on ZDT2 at this mutation rate is **not** the recovered UNSGA3 column in [ZDT2_COLLAPSE.md](ZDT2_COLLAPSE.md). That is algorithm + operator honesty, not a Bend regression. No niching patch was applied to chase IGD.

### ZDT1 (p=12, pop=52, gens=100, PymooCompatible / pymoo NSGA-III)

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 0.061603 | 0.071683 | 0.238437 | 0.859 | 0.258 | 52 | 52 | 12 |
| 2 | 0.066580 | 0.072663 | 0.285081 | 0.916 | 0.234 | 52 | 52 | 13 |
| 3 | 0.114314 | 0.097428 | 0.220101 | 1.173 | 0.519 | 52 | 52 | 13 |
| 4 | 0.084756 | 0.081014 | 0.332924 | 1.046 | 0.255 | 52 | 52 | 12 |
| 5 | 0.106098 | 0.115365 | 0.327970 | 0.920 | 0.324 | 52 | 52 | 13 |
| 6 | 0.052643 | 0.060626 | 0.280822 | 0.868 | 0.187 | 52 | 52 | 13 |
| 7 | 0.060400 | 0.043666 | 0.289958 | 1.383 | 0.208 | 52 | 52 | 12 |
| 8 | 0.082262 | 0.104367 | 0.290704 | 0.788 | 0.283 | 52 | 50 | 12 |
| 9 | 0.058095 | 0.059591 | 0.313130 | 0.975 | 0.186 | 52 | 52 | 12 |
| 10 | 0.072398 | 0.076420 | 0.319706 | 0.947 | 0.226 | 48 | 52 | 12 |
| 11 | 0.071400 | 0.076397 | 0.239232 | 0.935 | 0.298 | 52 | 52 | 10 |
| 12 | 0.078086 | 0.051271 | 0.181463 | 1.523 | 0.430 | 52 | 52 | 12 |
| 13 | 0.060973 | 0.078523 | 0.319146 | 0.777 | 0.191 | 52 | 51 | 12 |
| 14 | 0.166313 | 0.160072 | 0.302604 | 1.039 | 0.550 | 41 | 52 | 13 |
| 15 | 0.071199 | 0.162866 | 0.222955 | 0.437 | 0.319 | 52 | 52 | 13 |

Seeds actually scored: Bend 1–15; C# 1–15; pymoo 1–15.
Median IGD: Bend 0.071400, C# 0.076420, pymoo NSGA-III 0.289958.
PF yardstick: `pf_source=analytic-zdt1 n=500`, `pf_rows=500`, partitions=12.

### ZDT2 (p=12, pop=52, gens=250, PymooCompatible / pymoo NSGA-III)

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 0.024344 | 0.031728 | 0.316146 | 0.767 | 0.077 | 52 | 52 | 7 |
| 2 | 0.023485 | 0.017507 | 0.264467 | 1.341 | 0.089 | 52 | 52 | 10 |
| 3 | 0.024610 | 0.016959 | 0.304997 | 1.451 | 0.081 | 52 | 52 | 12 |
| 4 | 0.024199 | 0.018612 | 0.727625 | 1.300 | 0.033 | 52 | 52 | 3 |
| 5 | 0.023420 | 0.023800 | 0.366770 | 0.984 | 0.064 | 52 | 52 | 13 |
| 6 | 0.025106 | 0.016451 | 0.828926 | 1.526 | 0.030 | 52 | 52 | 2 |
| 7 | 0.020639 | 0.060917 | 0.822242 | 0.339 | 0.025 | 52 | 52 | 3 |
| 8 | 0.022109 | 0.014185 | 0.292348 | 1.559 | 0.076 | 52 | 52 | 13 |
| 9 | 0.028772 | 0.062308 | 0.646092 | 0.462 | 0.045 | 52 | 52 | 2 |
| 10 | 0.019068 | 0.019110 | 0.829461 | 0.998 | 0.023 | 52 | 52 | 1 |
| 11 | 0.023115 | 0.019731 | 0.342188 | 1.171 | 0.068 | 52 | 52 | 12 |
| 12 | 0.024725 | 0.018524 | 0.142780 | 1.335 | 0.173 | 52 | 52 | 11 |
| 13 | 0.025579 | 0.075641 | 0.767055 | 0.338 | 0.033 | 52 | 52 | 1 |
| 14 | 0.026210 | 0.016963 | 0.669197 | 1.545 | 0.039 | 52 | 52 | 2 |
| 15 | 0.024750 | 0.017966 | 0.840356 | 1.378 | 0.029 | 52 | 52 | 5 |

Seeds actually scored: Bend 1–15; C# 1–15; pymoo 1–15.
Median IGD: Bend 0.024344, C# 0.018612, pymoo NSGA-III 0.646092.
PF yardstick: `pf_source=analytic-zdt2 n=500`, `pf_rows=500`, partitions=12.

### DTLZ2 (p=12, pop=92, gens=150, PymooCompatible / pymoo NSGA-III)

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 0.004294 | 0.004084 | 0.001733 | 1.051 | 2.478 | 92 | 92 | 91 |
| 2 | 0.004250 | 0.003743 | 0.001677 | 1.135 | 2.535 | 92 | 92 | 91 |
| 3 | 0.003681 | 0.004379 | 0.001935 | 0.841 | 1.902 | 92 | 92 | 91 |
| 4 | 0.005359 | 0.004869 | 0.001948 | 1.101 | 2.751 | 92 | 92 | 91 |
| 5 | 0.003590 | 0.003258 | 0.001767 | 1.102 | 2.031 | 92 | 92 | 91 |
| 6 | 0.003808 | 0.004577 | 0.002859 | 0.832 | 1.332 | 92 | 92 | 91 |
| 7 | 0.003603 | 0.006085 | 0.003620 | 0.592 | 0.995 | 92 | 92 | 91 |
| 8 | 0.004240 | 0.004090 | 0.001695 | 1.037 | 2.501 | 92 | 92 | 91 |
| 9 | 0.004172 | 0.004921 | 0.002194 | 0.848 | 1.902 | 92 | 92 | 91 |
| 10 | 0.004882 | 0.004327 | 0.002529 | 1.128 | 1.930 | 92 | 92 | 91 |
| 11 | 0.003181 | 0.004019 | 0.001502 | 0.791 | 2.118 | 92 | 92 | 91 |
| 12 | 0.004901 | 0.003815 | 0.002740 | 1.284 | 1.788 | 92 | 92 | 91 |
| 13 | 0.003984 | 0.004606 | 0.002652 | 0.865 | 1.502 | 92 | 92 | 91 |
| 14 | 0.004247 | 0.002949 | 0.002715 | 1.440 | 1.565 | 92 | 92 | 91 |
| 15 | 0.003993 | 0.003552 | 0.003116 | 1.124 | 1.282 | 92 | 92 | 91 |

Seeds actually scored: Bend 1–15; C# 1–15; pymoo 1–15.
Median IGD: Bend 0.004172, C# 0.004090, pymoo NSGA-III 0.002194.
PF yardstick: `pf_source=pymoo-das-dennis`, `pf_rows=91`, partitions=12.

## Reading the columns

- **Bend vs C#** is the U-NSGA-III port comparison (same tournament, same p_m=1/n). Residual IGD scatter is expected (LCG ≠ `System.Random`). DTLZ2 stays in the published C# band (~0.003–0.006). ZDT2 gens=250 is recovered on both stacks (52 ND points).
- **pymoo NSGA-III** is a third algorithm with the same operators / refs / pop / gens. It is not U-NSGA-III and not the C# `UNSGA3` oracle. On 2-obj ZDT it typically emits ~one point per Das–Dennis ray (or fewer when the search piles). On DTLZ2 it emits 91 points (one per ref) and is ahead on IGD — a denser-on-the-sphere 91-pt front vs a 92-pt U-NSGA-III pop that still carries extras.
- Do not compare these IGD cells to a score against pymoo’s default DTLZ2 `pareto_front()` (~136 pts). That is a yardstick mismatch.
