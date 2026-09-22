# Equivalence / A/B protocol (Bend)

Public protocol for **unsga3-bend**. Same problems, pops, gens, and IGD definition as C# [Unsga3 `docs/EQUIVALENCE.md`](https://github.com/AppSprout-dev/Unsga3/blob/main/docs/EQUIVALENCE.md). Dump defaults live in [`ab/protocol.py`](../ab/protocol.py). Scripts: [ab/README.md](../ab/README.md).

This is **not** a NuGet package. PackageId `Unsga3` stays the C# / NuGet / GitHub Packages stack. Current Bend hub version is **0.1.2** (content hash `0x527a2a4fa91b05a0250d7be0e11d232a`; `import 0x527a2a4fa91b05a0250d7be0e11d232a/lib.bend as Unsga3`). A/B stays `PymooCompatible`. GitHub 0.1.2 includes the RankNicheDistance fix (rank, niche count, perpendicular distance, coin).

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

## Intentional deltas vs C#

- Bend RNG is a portable LCG, not `System.Random` — fronts will not match bit-for-bit.
- v0 sort is Pareto-only (no constraint-domination).
- `Run` niching threads rng for min-count niche ties; last-front extras are random among near-best on the ray.
- Duplicate keys round each decision variable to 12 decimal places (`round(x*1e12)/1e12`). C# `DecisionKey` is `ToString("G12")` (12 significant digits). Those formats diverge for small variables (`1.234567e-8` → Bend `1.2346e-8`). The 12-dp key is intentional; it is not a unit-box match to C#.

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
