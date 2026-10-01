# Equivalence / A/B protocol (Bend)

Public protocol for **unsga3-bend**. Same problems, pops, gens, and IGD definition as C# [Unsga3 `docs/EQUIVALENCE.md`](https://github.com/AppSprout-dev/Unsga3/blob/main/docs/EQUIVALENCE.md). Dump defaults live in [`ab/protocol.py`](../ab/protocol.py). Scripts: [ab/README.md](../ab/README.md).

This is **not** a NuGet package. PackageId `Unsga3` stays the C# / NuGet / GitHub Packages stack. Current Bend hub version is **0.2.1** (content hash `0x2bc7fb472c80bd6a0e04725c117edb2a`; `import 0x2bc7fb472c80bd6a0e04725c117edb2a/lib.bend as Unsga3`). A/B stays `PymooCompatible`. GitHub 0.1.2 (`0x527a2a4fa91b05a0250d7be0e11d232a`) includes the RankNicheDistance fix (rank, niche count, perpendicular distance, coin). GitHub 0.2.0 (`0xa2f9d6ef8c474468bf1de15ebe70c512`) adds the catalog, Deb constraint-domination, the offspring duplicate contract, and the odd-N SBX fix. GitHub 0.2.1 adds the DTLZ3 axis clamp, OSY / TNK / C1-DTLZ1, and the CV-fill overflow fix. `unified-nsga-iii@0.2.0.0` still names the 0.2.0 hash.

Do **not** invent IGD / HV / Wilcoxon numbers. A/B scripts dump a real front or print `skip: …`.

## Quality budgets

Operators: SBX η=30, PM η=20, p_c=1.0, p_m=1/n. Tournament for A/B: `PymooCompatible`.

| Label | Problem | Partitions | Pop | Gens | Seed |
|-------|---------|------------|-----|------|------|
| oracle ZDT1 | ZDT1 n=30 | 12 | 52 | 100 | 1 |
| oracle ZDT2 | ZDT2 n=30 | 12 | 52 | **250** | 1 |
| oracle DTLZ2 | DTLZ2 M=3 k=10 | 12 | 92 | 150 | 1 |
| smoke ZDT1 | ZDT1 n=30 | 4 | 8 | 3 | 1 |

- ZDT2 **gens=250** is the quality bar. **gens=100** is an early-stress snapshot (collapse on Bend, C#, and pymoo at that budget). See [ZDT2_COLLAPSE.md](ZDT2_COLLAPSE.md).
- Smoke is labeled smoke and is **not** an oracle claim.
- RankNicheDistance (`--tournament rank_niche`) is an optional lever, not the A/B default. Its key order is rank → niche count → perpendicular distance → coin (`WinnerRankNicheDistance`). Recorded RankNiche IGD in [ZDT2_COLLAPSE.md](ZDT2_COLLAPSE.md) is the earlier two-key operator (distance unused); it is not a rescore of this key order.
- IGD is mean nearest-neighbor distance. DTLZ2 must use a Das–Dennis-density PF at the run’s partitions (not pymoo’s default ~136-pt sample).

## Catalog problems (not the ZDT1 / ZDT2 / DTLZ2 quality bar)

[`src/problems.bend`](../src/problems.bend) also evaluates the rest of the unconstrained C# catalog: ZDT3, ZDT4, ZDT6, DTLZ1, DTLZ3, DTLZ4, DTLZ7, Sphere, Ackley, Rosenbrock. [`ab/dump_bend_run.py`](../ab/dump_bend_run.py) can dump a front for those names. Omitted gens / pop / partitions on a catalog name are a short smoke (3 / 8 / 4), not the table above and not the catalog A/B below. [`ab/protocol.py`](../ab/protocol.py) `oracle_knobs` for ZDT1, ZDT2, and DTLZ2 are unchanged.

C# `tools/OracleCompare` accepts only zdt1, zdt2, and dtlz2, and C# has no published catalog IGD table. [`ab/oracle_catalog.py`](../ab/oracle_catalog.py) still measures the catalog, under `catalog_knobs`, with tournament `PymooCompatible`:

| Problems | Why these knobs | Partitions | Pop | Gens | n |
|----------|-----------------|------------|-----|------|---|
| ZDT3, ZDT4, ZDT6 | ZDT1 quality budget | 12 | 52 | 100 | 30, 10, 10 |
| DTLZ1, DTLZ3, DTLZ4, DTLZ7 | DTLZ2 quality budget | 12 | 92 | 150 | 7, 12, 12, 22 (M=3; k=5 / 10 / 10 / 20) |
| Sphere, Ackley, Rosenbrock | short smoke, one reference direction | 1 | 20 | 40 | 10, 30, 10 |

C# CI smokes use smaller n on the single-objective problems, `RankNicheDistance`, and different pop/gens. That is not this budget.

Pareto sets in [`ab/igd_vs_pymoo.py`](../ab/igd_vs_pymoo.py): ZDT3 segments, ZDT4 = ZDT1, ZDT6 floor `0.280775`, and DTLZ1 half-simplex follow C# `ParetoFronts`. DTLZ3 and DTLZ4 use the DTLZ2 Das–Dennis sphere. DTLZ7 uses pymoo `pareto_front()` or `skip:` (C# has no DTLZ7 front). Sphere / Ackley / Rosenbrock use the one-point minimum `f = 0`. pymoo's `sphere` is `[0,1]^n` with a different objective; that column must `skip:` rather than score a different problem.

OSY, TNK, and C1-DTLZ1 are in this checkout. Their budgets are `constrained_knobs` in [`ab/protocol.py`](../ab/protocol.py) (PymooCompatible; C# NEW-SURFACES used RankNicheDistance). Measured cells are in [CONSTRAINED-SURFACES.md](CONSTRAINED-SURFACES.md). They are not `catalog_knobs` rows. They are in the 0.2.1 hub hash. The 0.2.0 hash (`0xa2f9d6ef8c474468bf1de15ebe70c512`) does not include them.

The 2026-09-30 run (seeds 1–15) is recorded in [ORACLE-CATALOG.md](ORACLE-CATALOG.md). Every cell there is an `igd=` or `skip:` line from that run, except the DTLZ3 Bend column, which was remeasured on 2026-10-01 after the axis-cosine clamp ([DTLZ3_AXIS.md](DTLZ3_AXIS.md)). C# and pymoo DTLZ3 cells were not re-run. Do not invent IGD / HV / Wilcoxon numbers. The ZDT1 / ZDT2 / DTLZ2 tables in [ORACLE-MULTISEED.md](ORACLE-MULTISEED.md) are a different protocol and were not recomputed for this catalog.

## Constraints

`Individual` carries a constraint vector `g` (`g ≤ 0`) and `cv`, the sum of the positive parts. Feasible means `cv ≤ 0`. Empty `g` is `cv = 0`. ZDT1 / ZDT2 / DTLZ2 write no constraints, so those runs stay on the Pareto path. An all-feasible pool still takes ideal and worst from the whole pool. A pool with any infeasible member builds the hyperplane from the feasible subset (or projects with the stored hyperplane when nobody is feasible) and niches only that subset, filling a shortfall by ascending CV. OSY, TNK, and C1-DTLZ1 are the constrained demos.

`NDS.sort` uses Deb constraint-domination:

- a feasible point beats an infeasible point
- both infeasible, unequal `cv` → the smaller `cv` wins
- both infeasible, equal `cv` → mutual non-domination (objectives are not compared)
- both feasible → Pareto, including the existing unequal-length rule (mutual non-domination)

Published C# `CompareConstraintDominated` still falls through to Pareto when both are infeasible and the violations are equal. This tree follows Deb: equal `cv` does not Pareto-compare. `NDS.dominates` stays the Pareto predicate locked by `dominates_irreflexive`. [`src/cd_contract.bend`](../src/cd_contract.bend) locks the split.

Both tournament modes take `cv` first. `PymooCompatible` (A/B default): if either parent is infeasible, the smaller `cv` wins and equal `cv` is a coin (rank and distance are not consulted). `RankNicheDistance`: a feasible parent beats an infeasible one; both infeasible and unequal `cv` → smaller `cv`; equal `cv` falls through to rank, then niche count, then perpendicular distance, then a coin. Feasible-only behavior of both modes is unchanged. A/B is not switched to `RankNicheDistance`.

## Intentional deltas vs C#

- Bend RNG is a portable LCG, not `System.Random` — fronts will not match bit-for-bit.
- Equal infeasible `cv` is mutual non-domination. Published C# `CompareConstraintDominated` Pareto-compares that case.
- `Run` niching threads rng for min-count niche ties; last-front extras are random among near-best on the ray.
- Duplicate keys round each decision variable to 12 decimal places (`round(x*1e12)/1e12`). C# `DecisionKey` is `ToString("G12")` (12 significant digits). Those formats diverge for small variables (`1.234567e-8` → Bend `1.2346e-8`). The 12-dp key is intentional; it is not a unit-box match to C#.

## Offspring duplicates and odd N

Elimination hashes the **survivor** population, then each accepted child. A member of P who lost every tournament is still forbidden. The key stays 12 decimal places. After `pop·40` SBX pair attempts, up to `max(pop·20, 1)` further mutations must still be a new key. Remaining slots may then be duplicates so the loop terminates. That is the C# `CreateOffspring` cap shape. [`src/cd_contract.bend`](../src/cd_contract.bend) rejects a child that copies an unpicked survivor and accepts one the mating sample alone would have allowed.

The pair cursor is still `0, 2, 4, …`. For even N the lookup is unchanged: use the cursor while `cursor+1 < N`, otherwise parent `0` with parent `1`. For odd N, cursor `N-1` is parent `N-1` crossed with parent `0` (that parent used to be skipped). Later cursors still resolve to pair `(0, 1)`. N = 1 crosses the only parent with itself. Oracle pops 52 and 92 are even, so this lookup does not move those pair sequences.

## How to dump (no invented fronts)

```bash
# smoke (checked-in driver)
python3 ab/dump_bend_run.py --native

# quality protocol (omitted --gens/--pop on a generated driver match this table)
python3 ab/dump_bend_run.py --native --problem zdt2 --partitions 12 --pop 52 --seed 1
python3 ab/igd_vs_pymoo.py --front ab/out/bend_run_F.csv --problem zdt2 --pf-points 500 --partitions 12
```

Omitted `--gens` / `--pop` on a generated driver follow [`ab/protocol.py`](../ab/protocol.py): ZDT2 250/52, ZDT1 100/52, DTLZ2 **150/92**. Explicit flags win. No `--problem` is the checked-in smoke, not that table. C# dump is optional (`UNSGA3_CS_ROOT`); it skips rather than inventing a front.

## Das–Dennis `count` vs `das_dennis` at p = 0

`Refs.count(2, 0)` is 1 (`C(1, 1)`). `Refs.das_dennis(2, 0)` is empty. C# throws when `partitions < 1`. The closed law `das_dennis_len` is quantified on `p+1`; the comment on that law in `LAWS.bend` already says v0 returns `Nil{}` for `M>1` / `p==0` while `Count` is `C(M-1, M-1)`. Oracles use `p≥4` (protocol partitions 12). This is a documented split, not a rewrite of the law. `count` and the generator are not the same function.

## Unequal-length objectives

`compare_pareto` returns mutual non-domination (`0`) when the objective lists have different lengths, including when the shared prefix is strictly better. C# `ComparePareto` throws. This tree stays total. ZDT / DTLZ populations use one length, so the oracle path does not hit it. Equal-length domination is unchanged (`1` = a dominates b, `2` = the reverse). [`src/nds_unequal.bend`](../src/nds_unequal.bend) locks that: the unequal pair shares front `0,1`; `[0,0]` still strictly dominates `[1,1]`.

Measured native phase tables (not IGD): [PERF_NOTES.md](PERF_NOTES.md). Multi-seed IGD (Bend / C# / pymoo NSGA-III) + Layer-1 fixture check: [ORACLE-MULTISEED.md](ORACLE-MULTISEED.md).
