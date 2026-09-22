# Multi-seed IGD + Layer-1 fixture check

Confidence tables for **unsga3-bend** vs C# [Unsga3](https://github.com/AppSprout-dev/Unsga3) vs a **pymoo NSGA-III** run. Same public knobs as [EQUIVALENCE.md](EQUIVALENCE.md) / [`ab/protocol.py`](../ab/protocol.py). Same IGD yardstick: [`ab/igd_vs_pymoo.py`](../ab/igd_vs_pymoo.py).

**No invented numbers.** Every IGD cell is a real `igd=` line from a dumped front. Reproduce with [`ab/oracle_multiseed.py`](../ab/oracle_multiseed.py) and [`ab/fixture_check.py`](../ab/fixture_check.py).

These tables shipped with GitHub **0.1.1** (docs/ab only; that tag did not hub-publish). Current hub package is **0.1.2** (`import 0x527a2a4fa91b05a0250d7be0e11d232a/lib.bend as Unsga3`). The runs use `PymooCompatible`. The 0.1.2 RankNicheDistance fix is outside this default.

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

`--reuse` skips a dump when the CSV already exists. `--seeds` / `--problems` / `--stacks` select a subset; list every seed you actually ran.

`dump_csharp_run.py` skips without `UNSGA3_CS_ROOT` / `dotnet`. `dump_pymoo_nsga3.py` skips without pymoo. Do not invent a front or IGD.

## Host for the tables below

- Date: 2026-09-21
- Bend: **2.0.22** (`dump_bend_run.py --native`, warm cache per generated driver; each seed recompiles)
- C# Unsga3: sibling checkout **`6dd91b5`** (`UNSGA3_CS_ROOT=/home/ubuntu/Unsga3`, `OracleCompare` Release / net10.0, `--pymoo-mode`)
- pymoo: **0.6.2** `NSGA3` (`ab/dump_pymoo_nsga3.py`: SBX η=30 p_c=1.0, PM η=20 p_m=1/n)
- .NET: 10.0.401
- Host: 4-core, clang 18.1.3, Linux 6.12.94+
- Seeds requested: **1–15**
- Seeds actually run: **1–15** on all three stacks, all three problems (135/135 `igd=` lines; 0 skips)

Independent re-score of three CSVs matched the table cells to printed precision (`igd_vs_pymoo.py`). Bend/C# ZDT1 and DTLZ2 IGD match the earlier [PERF_NOTES.md](PERF_NOTES.md) 15-seed columns; ZDT2 gens=250 Bend/C# match [ZDT2_COLLAPSE.md](ZDT2_COLLAPSE.md). That is a yardstick check, not a copied invention.

## Layer-1 fixture bit-check

`ab/fixture_check.py` dumps Bend `Survival.select` and C# `NondominatedSortingSurvival.Select(rng: null)` on the same objective fixture, then `ab/compare.py` row-set equality. That is the end-to-end of sort → normalize → associate → select. Intermediate ranks are not serialized; selected objective rows are the contract.

| Fixture | Bend dump | C# dump | `row_set_equal` | Verdict |
|---------|-----------|---------|-----------------|--------|
| `ab/fixtures/core_2obj.json` | ok (5 rows) | ok (5 rows) | **True** | **pass** |

Selected row-set (parsed floats): `(0,1)`, `(0.2,0.9)`, `(0.5,0.5)`, `(0.9,0.2)`, `(1,0)`. Dominated `(0.8,0.8)` and `(1,1)` are dropped; `(0.1,0.95)` is not taken at `target_size=5`.

C# writes G17 doubles (`0.20000000000000001`); Bend prints shorter F32 text (`0.2`). `compare.py` equality is after Python `float` parse — same contract as Layer-1 smoke. No other shared fixtures are checked in.

Intentional Run-path deltas (LCG ≠ `System.Random`, Pareto-only, last-front extras) do **not** apply to this deterministic select. No law was weakened.

## Measured IGD tables

Ratios are Bend/C# and Bend/pymoo from the same `igd=` cells only. `n` is ND front rows on that dump.

### Summary

| Problem | Seeds | median Bend | median C# | median pymoo NSGA-III | Bend ≤ C# | notes |
|---------|------:|------------:|----------:|----------------------:|----------:|-------|
| ZDT1 | 1–15 | 0.071475 | 0.082152 | 0.289958 | 9/15 | Bend/C# keep ~52 pts; pymoo NSGA-III reports ~12 ND (one per ray) |
| ZDT2 | 1–15 | 0.025621 | 0.018684 | 0.646092 | 2/15 | Bend/C# 0/15 collapse (`n=52`). pymoo NSGA-III + p_m=1/n often piles (n=1–3) |
| DTLZ2 | 1–15 | 0.004243 | 0.004512 | 0.002194 | 10/15 | all `n=92` / `91`; PF `pymoo-das-dennis` 91 pts |

C# DTLZ2 seed 1 IGD **0.004032** matches the published C# `docs/ORACLE-RESULTS.md` PymooCompatible cell (~0.00403).

pymoo NSGA-III on ZDT2 at this mutation rate is **not** the recovered UNSGA3 column in [ZDT2_COLLAPSE.md](ZDT2_COLLAPSE.md). That is algorithm + operator honesty, not a Bend regression. No niching patch was applied to chase IGD.

### ZDT1 (p=12, pop=52, gens=100, PymooCompatible / pymoo NSGA-III)

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 0.061603 | 0.097733 | 0.238437 | 0.630 | 0.258 | 52 | 52 | 12 |
| 2 | 0.062526 | 0.156085 | 0.285081 | 0.401 | 0.219 | 52 | 52 | 13 |
| 3 | 0.114314 | 0.074783 | 0.220101 | 1.529 | 0.519 | 52 | 52 | 13 |
| 4 | 0.084756 | 0.130272 | 0.332924 | 0.651 | 0.255 | 52 | 41 | 12 |
| 5 | 0.083329 | 0.101950 | 0.327970 | 0.817 | 0.254 | 52 | 52 | 13 |
| 6 | 0.045916 | 0.082152 | 0.280822 | 0.559 | 0.164 | 52 | 52 | 13 |
| 7 | 0.060659 | 0.060123 | 0.289958 | 1.009 | 0.209 | 52 | 52 | 12 |
| 8 | 0.082262 | 0.112883 | 0.290704 | 0.729 | 0.283 | 52 | 52 | 12 |
| 9 | 0.061749 | 0.072583 | 0.313130 | 0.851 | 0.197 | 52 | 52 | 12 |
| 10 | 0.084640 | 0.072246 | 0.319706 | 1.172 | 0.265 | 52 | 52 | 12 |
| 11 | 0.151236 | 0.066878 | 0.239232 | 2.261 | 0.632 | 48 | 51 | 10 |
| 12 | 0.126977 | 0.067323 | 0.181463 | 1.886 | 0.700 | 52 | 52 | 12 |
| 13 | 0.061183 | 0.051285 | 0.319146 | 1.193 | 0.192 | 52 | 52 | 12 |
| 14 | 0.069462 | 0.103394 | 0.302604 | 0.672 | 0.230 | 52 | 51 | 13 |
| 15 | 0.071475 | 0.112429 | 0.222955 | 0.636 | 0.321 | 52 | 52 | 13 |

Seeds actually scored: Bend 1–15; C# 1–15; pymoo 1–15.
Median IGD: Bend 0.071475, C# 0.082152, pymoo NSGA-III 0.289958.
PF yardstick: `pf_source=analytic-zdt1 n=500`, `pf_rows=500`, partitions=12.

### ZDT2 (p=12, pop=52, gens=250, PymooCompatible / pymoo NSGA-III)

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 0.024550 | 0.019230 | 0.316146 | 1.277 | 0.078 | 52 | 52 | 7 |
| 2 | 0.025621 | 0.017794 | 0.264467 | 1.440 | 0.097 | 52 | 52 | 10 |
| 3 | 0.028093 | 0.018684 | 0.304997 | 1.504 | 0.092 | 52 | 52 | 12 |
| 4 | 0.023679 | 0.033702 | 0.727625 | 0.703 | 0.033 | 52 | 52 | 3 |
| 5 | 0.108520 | 0.029099 | 0.366770 | 3.729 | 0.296 | 52 | 52 | 13 |
| 6 | 0.024795 | 0.021193 | 0.828926 | 1.170 | 0.030 | 52 | 52 | 2 |
| 7 | 0.022320 | 0.016622 | 0.822242 | 1.343 | 0.027 | 52 | 52 | 3 |
| 8 | 0.075328 | 0.021164 | 0.292348 | 3.559 | 0.258 | 52 | 52 | 13 |
| 9 | 0.025847 | 0.017039 | 0.646092 | 1.517 | 0.040 | 52 | 52 | 2 |
| 10 | 0.023553 | 0.018429 | 0.764973 | 1.278 | 0.031 | 52 | 52 | 3 |
| 11 | 0.033346 | 0.042790 | 0.342188 | 0.779 | 0.097 | 52 | 52 | 12 |
| 12 | 0.092069 | 0.016716 | 0.142780 | 5.508 | 0.645 | 52 | 52 | 11 |
| 13 | 0.024122 | 0.014222 | 0.767055 | 1.696 | 0.031 | 52 | 52 | 1 |
| 14 | 0.061379 | 0.017277 | 0.669197 | 3.553 | 0.092 | 52 | 52 | 2 |
| 15 | 0.022635 | 0.019121 | 0.662086 | 1.184 | 0.034 | 52 | 52 | 3 |

Seeds actually scored: Bend 1–15; C# 1–15; pymoo 1–15.
Median IGD: Bend 0.025621, C# 0.018684, pymoo NSGA-III 0.646092.
PF yardstick: `pf_source=analytic-zdt2 n=500`, `pf_rows=500`, partitions=12.

### DTLZ2 (p=12, pop=92, gens=150, PymooCompatible / pymoo NSGA-III)

| seed | Bend IGD | C# IGD | pymoo NSGA-III IGD | Bend/C# | Bend/pymoo | Bend n | C# n | pymoo n |
|-----:|---------:|-------:|-------------------:|--------:|-----------:|-------:|-----:|--------:|
| 1 | 0.003914 | 0.004032 | 0.001733 | 0.971 | 2.259 | 92 | 92 | 91 |
| 2 | 0.004250 | 0.005666 | 0.001677 | 0.750 | 2.535 | 92 | 92 | 91 |
| 3 | 0.003777 | 0.005130 | 0.001935 | 0.736 | 1.952 | 92 | 92 | 91 |
| 4 | 0.004369 | 0.004777 | 0.001948 | 0.915 | 2.243 | 92 | 92 | 91 |
| 5 | 0.004848 | 0.004663 | 0.001767 | 1.040 | 2.743 | 92 | 92 | 91 |
| 6 | 0.004026 | 0.005460 | 0.002859 | 0.737 | 1.408 | 92 | 92 | 91 |
| 7 | 0.003603 | 0.003610 | 0.003620 | 0.998 | 0.995 | 92 | 92 | 91 |
| 8 | 0.004243 | 0.005111 | 0.001695 | 0.830 | 2.502 | 92 | 92 | 91 |
| 9 | 0.004004 | 0.004670 | 0.002194 | 0.857 | 1.825 | 92 | 92 | 91 |
| 10 | 0.004882 | 0.003816 | 0.002529 | 1.280 | 1.930 | 92 | 92 | 91 |
| 11 | 0.003727 | 0.003974 | 0.001502 | 0.938 | 2.481 | 92 | 92 | 91 |
| 12 | 0.004901 | 0.004512 | 0.002740 | 1.086 | 1.788 | 92 | 92 | 91 |
| 13 | 0.004502 | 0.003984 | 0.002652 | 1.130 | 1.698 | 92 | 92 | 91 |
| 14 | 0.004066 | 0.004172 | 0.002715 | 0.974 | 1.498 | 92 | 92 | 91 |
| 15 | 0.004357 | 0.003627 | 0.003116 | 1.201 | 1.398 | 92 | 92 | 91 |

Seeds actually scored: Bend 1–15; C# 1–15; pymoo 1–15.
Median IGD: Bend 0.004243, C# 0.004512, pymoo NSGA-III 0.002194.
PF yardstick: `pf_source=pymoo-das-dennis`, `pf_rows=91`, partitions=12.

## Reading the columns

- **Bend vs C#** is the U-NSGA-III port comparison (same tournament, same p_m=1/n). Residual IGD scatter is expected (LCG ≠ `System.Random`). DTLZ2 stays in the published C# band (~0.0036–0.0057). ZDT2 gens=250 is recovered on both stacks (52 ND points).
- **pymoo NSGA-III** is a third algorithm with the same operators / refs / pop / gens. It is not U-NSGA-III and not the C# `UNSGA3` oracle. On 2-obj ZDT it typically emits ~one point per Das–Dennis ray (or fewer when the search piles). On DTLZ2 it emits 91 points (one per ref) and is ahead on IGD — a denser-on-the-sphere 91-pt front vs a 92-pt U-NSGA-III pop that still carries extras.
- Do not compare these IGD cells to a score against pymoo’s default DTLZ2 `pareto_front()` (~136 pts). That is a yardstick mismatch.
