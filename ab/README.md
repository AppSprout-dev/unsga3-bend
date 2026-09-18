# A/B outline

Compare **unsga3-bend** to C# [Unsga3](https://github.com/AppSprout-dev/Unsga3) and to a pymoo `UNSGA3` oracle. Same public protocol as the C# docs (`docs/EQUIVALENCE.md`): shared ZDT / DTLZ problems, Das–Dennis partitions, IGD as mean nearest-neighbor distance.

**This directory is not wired.** Scripts print `not wired` and refuse to invent IGD / HV / Wilcoxon numbers.

This repo is not a NuGet package and is not a drop-in into C# consumers.

## Layer 1 — v0 core (objectives already evaluated)

Enough for the current scaffold. No SBX, mutation, or `Run` loop.

1. Build a JSON fixture: a population of objective vectors (same `M`, same order) plus Das–Dennis `(M, partitions)`.
2. **C# dump:** call C# `NonDominatedSort.Sort`, `Normalization.Normalize`, `ReferencePointManager.Associate`, `NondominatedSortingSurvival.Select` on that population. Write ranks, associations, selected indices, and the selected front as CSV.
3. **Bend dump:** call the Bend v0 modules on the same population. Write the same artifacts.
4. **Compare:** ranks / front partitions, association indices, selected index set. Do not report IGD here unless you also have a true Pareto-front reference and a real computed front.

Suggested fixture schema (when wired):

```json
{
  "problem": "fixture",
  "n_obj": 2,
  "partitions": 12,
  "target_size": 13,
  "objectives": [[0.0, 1.0], [0.5, 0.5], [1.0, 0.0]]
}
```

## Layer 2 — later algorithm A/B (after pass 2)

Once SBX, polynomial mutation, and `Unsga3Algorithm.Run` exist:

1. Dump a front from **C# Unsga3** (see that repo’s `tools/oracle` / `tools/OracleCompare`): `*_F.csv` + `*_meta.json`.
2. Dump a front from **Bend** with the same problem, partitions, pop, gens, seed.
3. Run **IGD vs pymoo** on each front (pymoo `IGD` against the problem Pareto front; Das–Dennis refs for DTLZ2).
4. Compare meta files. Tolerance bar in the C# docs: median IGD within about 1–2× of pymoo on ZDT / DTLZ.

Do not copy fabricated numbers from anywhere into this tree. Commit results only after a real run.

## Scripts

| Script | Role today |
|--------|------------|
| `dump_csharp_front.py` | prints `not wired` |
| `dump_bend_front.py` | prints `not wired` |
| `igd_vs_pymoo.py` | prints `not wired` |
| `compare.py` | prints `not wired` |

When implementing, keep dumps under `ab/out/` (gitignored).
