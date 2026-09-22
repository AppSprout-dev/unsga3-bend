# Equivalence / A/B protocol (Bend)

Public protocol for **unsga3-bend**. Same problems, pops, gens, and IGD definition as C# [Unsga3 `docs/EQUIVALENCE.md`](https://github.com/AppSprout-dev/Unsga3/blob/main/docs/EQUIVALENCE.md). Dump defaults live in [`ab/protocol.py`](../ab/protocol.py). Scripts: [ab/README.md](../ab/README.md).

This is **not** a NuGet package. PackageId `Unsga3` stays the C# / NuGet / GitHub Packages stack. First Bend hub version is **0.1.0** (content hash `0xcd07e24a626a62e74603d48f436cd679`; `import 0xcd07e24a626a62e74603d48f436cd679/lib.bend as Unsga3`).

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
- Duplicate keys use C# G12-style 12-decimal rounding.

## How to dump (no invented fronts)

```bash
# smoke (checked-in driver)
python3 ab/dump_bend_run.py --native

# quality protocol (pass the table knobs; see ab/README.md for DTLZ2 omitted-flag traps)
python3 ab/dump_bend_run.py --native --problem zdt2 --partitions 12 --pop 52 --seed 1
python3 ab/igd_vs_pymoo.py --front ab/out/bend_run_F.csv --problem zdt2 --pf-points 500 --partitions 12
```

Omitted `--gens` on `--problem zdt2` is 250 (`ab/protocol.py`). C# dump is optional (`UNSGA3_CS_ROOT`); it skips rather than inventing a front.

Measured native phase tables (not IGD): [PERF_NOTES.md](PERF_NOTES.md). Multi-seed IGD (Bend / C# / pymoo NSGA-III) + Layer-1 fixture check: [ORACLE-MULTISEED.md](ORACLE-MULTISEED.md).
