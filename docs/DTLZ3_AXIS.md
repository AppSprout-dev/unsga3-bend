# DTLZ3 axis cosine

DTLZ3 Bend IGD at the DTLZ2 budget (p=12, pop=92, gens=150, `PymooCompatible`) was worse than C# Unsga3 and pymoo NSGA-III on every seed in the 2026-09-30 catalog. The formulas match. The gap was an F32 boundary value on the shared DTLZ2 map, amplified by DTLZ3's large `g`.

## Cause

For `x ∈ [0, 1]`, `cos(x·π/2)` and `sin(x·π/2)` are in `[0, 1]`. Bend `F32.cos(π/2)` is **-4.371139e-8**, not 0. SBX and polynomial mutation clamp to the box, so `x = 1` is common.

DTLZ3 is the DTLZ2 spherical map with DTLZ1's multimodal `g`. On a local front `1+g` is tens to thousands. An in-bound axis point then has one objective equal to `(1+g)·cos(π/2)`, which is **strictly negative**. Every feasible point has `f ≥ 0`, so nothing dominates that row. It stays on the ND front and wins the ASF extreme on that axis, which pins the intercept near `1+g`.

DTLZ2 uses the same cosine. There `1+g ≈ 1`, so the negative is about `1e-8` and does not move IGD at the published precision. DTLZ1 does not use this map. The objective clamp is only on `dtlz3_f`. DTLZ2's map is unchanged.

Checked on the pre-fix seed-1 front (`ab/igd_vs_pymoo.py`, `pf_source=pymoo-das-dennis`, `pf_rows=91`):

- `igd=19.077455046194125` (the catalog cell 19.077455)
- 92 ND rows, 71 strictly negative objectives
- radii min 19.719578, median 110.462790, max 1284.579600
- the farthest row was `[-6.9428720e-05, 1.5883441e+03, 0]`. The ratio of those two nonzero entries is **-4.3711385e-8**, the F32 cosine

C# `double` `Math.Cos(π/2)` is about `+6e-17`. pymoo evaluates in float64. Neither stack grows a negative objective from `x = 1`.

The DTLZ3 formula itself matches C# `Dtlz3Problem` (`GDtlz1` plus the DTLZ2 sine/cosine map) and pymoo at `x = 0.5` (`f ≈ (0.5, 0.5, 0.707)`). Initial `g` from Bend's LCG and from NumPy, seeds 1–15, both have medians near 1100. That is not the gap.

## Fix

`dtlz3_f` clamps each objective to `≥ 0` after the DTLZ2 map. At `x_i = 1` the sign that used to be negative becomes 0. A product of two negative cosines stays a positive dust (`4.7958203e-13` on that point) and can be dominated. `src/catalog_smoke.bend` prints `axis dtlz3` and `ab/test_catalog_smoke.py` checks `f ≥ 0`.

## After, same budget

Bend only. `dump_bend_run.py --native --threads 4`, Bend **2.0.34**, 2026-10-01. Scored by `ab/igd_vs_pymoo.py` (`pf_source=pymoo-das-dennis`, `pf_rows=91`). C# and pymoo columns below are the 2026-09-30 catalog cells, not a new run. Pre-fix Bend is that same catalog.

| seed | Bend before | Bend after | C# | pymoo NSGA-III | after n |
|-----:|------------:|-----------:|---:|---------------:|--------:|
| 1 | 19.077455 | 12.820729 | 16.438212 | 5.032098 | 77 |
| 2 | 26.249240 | 10.552080 | 17.450459 | 20.061152 | 27 |
| 3 | 17.415274 | 4.235343 | 8.614599 | 9.222801 | 55 |
| 4 | 48.393597 | 8.723205 | 13.753291 | 7.100755 | 57 |
| 5 | 14.704428 | 5.888764 | 8.879998 | 8.366071 | 62 |
| 6 | 30.198614 | 14.755559 | 4.597384 | 8.893172 | 84 |
| 7 | 28.329716 | 9.243434 | 11.963956 | 15.122474 | 61 |
| 8 | 29.036933 | 7.299384 | 7.117607 | 4.063408 | 40 |
| 9 | 17.517529 | 5.023930 | 15.670052 | 2.185604 | 61 |
| 10 | 24.818307 | 11.456296 | 8.213816 | 7.084399 | 73 |
| 11 | 35.574511 | 2.911215 | 6.943016 | 8.131713 | 44 |
| 12 | 34.802930 | 10.265392 | 5.351800 | 12.176215 | 51 |
| 13 | 22.706025 | 6.445288 | 9.323371 | 5.063550 | 63 |
| 14 | 22.005184 | 6.200517 | 7.473292 | 10.168770 | 44 |
| 15 | 33.705468 | 8.239578 | 10.739241 | 22.118049 | 81 |

Median of the 15 after values (middle of the sorted list): **8.239578**. Catalog medians: Bend before 26.249240, C# 8.879998, pymoo 8.366071. Bend after ≤ C# on **11/15** seeds (before: 0/15). Every seed improved. Seed 1 after has 0 negative objectives and radii min 13.6513, median 15.8879, max 21.7507.

`after` `igd=` lines, full printed values:

```
seed 1  igd=12.82072863418211
seed 2  igd=10.55208039162184
seed 3  igd=4.235342658899343
seed 4  igd=8.723205394545104
seed 5  igd=5.888764420726858
seed 6  igd=14.755559147105112
seed 7  igd=9.243433525710824
seed 8  igd=7.299383845897385
seed 9  igd=5.0239303686003565
seed 10 igd=11.456295909661856
seed 11 igd=2.911214749842371
seed 12 igd=10.265391572507582
seed 13 igd=6.445288413292936
seed 14 igd=6.200517376142176
seed 15 igd=8.239578363326162
```

## Locked cells

Same binary rebuild, same scorer.

| Problem | Check | Result |
|---------|--------|--------|
| DTLZ2 seed 1 | front CSV vs the pre-change dump | byte-identical (3144 bytes). `igd=0.003913783624645774` (published cell 0.003914, `pf_rows=91`) |
| ZDT1 seed 1 | `igd_vs_pymoo.py --pf-points 500` | `igd=0.06160279513969024` (published cell 0.061603, `pf_rows=500`) |
| ZDT2 seed 1 | `igd_vs_pymoo.py --pf-points 500` | `igd=0.024549599644311613` (published cell 0.024550, `pf_rows=500`) |

ZDT1 and ZDT2 do not call `dtlz3_f`. Defaults were not changed.

## What this budget still is

150 generations is the DTLZ2 sibling budget. It is not the global DTLZ3 front for any of the three stacks. pymoo 0.6.2 NSGA-III, same operators and the same Das–Dennis PF (`pf_rows=91`), scored with `pymoo.indicators.igd.IGD` (seed 1 at 150 generations reproduced the catalog cell 5.032098):

| seed | gens | igd | n | radius min | radius med | radius max |
|-----:|-----:|----:|--:|-----------:|-----------:|-----------:|
| 1 | 150 | 5.032098 | 43 | 6.0026 | 6.0062 | 6.0183 |
| 1 | 1000 | 4.000487 | 91 | 5.0005 | 5.0005 | 5.0005 |
| 5 | 150 | 8.366071 | 44 | 9.3283 | 9.3416 | 9.5459 |
| 5 | 1000 | 0.088082 | 67 | 1.0502 | 1.0504 | 1.0858 |
| 8 | 150 | 4.063408 | 56 | 5.0445 | 5.0532 | 6.0497 |
| 8 | 1000 | 1.019431 | 91 | 2.0194 | 2.0194 | 2.0194 |

Those shells are local fronts (`||F|| = 1+g`). Seed 1 is still on a radius-5 shell at 1000 generations. Closing the rest of the distance to the unit sphere is a longer run, not another operator default.
