# Constrained surfaces

OSY, TNK, and C1-DTLZ1 formulas, bounds, and constraints are in [`src/problems.bend`](../src/problems.bend). They match C# `ConstrainedProblems`. Smoke (formulas, feasible ideal, CV fill, `lnk` clear, short seeded `Run`): `bend src/constrained_smoke.bend -o <bin>`.

This is not the ZDT1 / ZDT2 / DTLZ2 quality table and not the 2026-09-30 catalog snapshot in [ORACLE-CATALOG.md](ORACLE-CATALOG.md).

## Budget

`constrained_knobs` in [`ab/protocol.py`](../ab/protocol.py). Tournament stays `PymooCompatible`. C# NEW-SURFACES scored these problems with `RankNicheDistance`. This table does not use that mode and does not copy those numbers.

| Problem | Partitions | Pop | Gens | n | M |
|---------|------------|-----|------|---|---|
| OSY | 12 | 52 | 250 | 6 | 2 |
| TNK | 12 | 52 | 250 | 2 | 2 |
| C1-DTLZ1 | 12 | 92 | 150 | 7 (k=5) | 3 |

Operators: SBX η=30, p_c=1; polynomial mutation η=20, p_m=1/n. The scored set is the feasible non-dominated front (`Algo.feas_nd`, and the same filter on pymoo `G` / non-dominated sort). An empty feasible set is `skip: no feasible points`.

Reference sets:

- OSY / TNK: pymoo `pareto_front()`
- C1-DTLZ1: DTLZ1 half-simplex at the run's partitions (same yardstick as DTLZ1; `n_var` does not change the PF)

C# cells stay `skip:` when `UNSGA3_CS_ROOT` is unset. This tree does not clone Unsga3, and `OracleCompare` does not accept these names. pymoo here is NSGA-III, not U-NSGA-III.

GD+ is [`ab/indicators.py`](../ab/indicators.py) (C# `GenerationalDistancePlus`: Euclidean norm of `max(a_j − z_j, 0)`). The hand case is `ab/test_gd_plus.py`. No protocol front below was scored with GD+.

## Seed 1 (2026-10-01)

Only seed 1 was run. Other seeds are `skip: not run`.

| problem | seed | Bend | C# | pymoo NSGA-III |
|---------|-----:|------|----|----------------|
| osy | 1 | skip: native Run memory fault (stack overflow) after the header; pop=52 gens=250 | skip: UNSGA3_CS_ROOT unset; this tree does not clone Unsga3 | igd=79.74966152754332 |
| tnk | 1 | skip: native Run runtime fail-stop after the header; pop=52 gens=250 | skip: UNSGA3_CS_ROOT unset; this tree does not clone Unsga3 | igd=0.031004225027454972 |
| c1dtlz1 | 1 | skip: native Run memory fault (stack overflow) after the header; pop=92 gens=150 | skip: UNSGA3_CS_ROOT unset; this tree does not clone Unsga3 | skip: pymoo NSGA-III returned no F. Refusing to invent a front. |

pymoo OSY: `front_rows=13`, `pf_rows=99`, `pf_source=pymoo-pareto_front osy`. pymoo TNK: `front_rows=11`, `pf_rows=104`, `pf_source=pymoo-pareto_front tnk`. Both use the knobs above. A native TNK dump at the omitted-flag smoke (partitions=4, pop=12, gens=3, seed=1) wrote 3 feasible-ND rows. That smoke is not this budget and is not scored.

No HV. No Wilcoxon.
