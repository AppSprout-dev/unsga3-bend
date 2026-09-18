# A/B

Compare **unsga3-bend** v0 core selection to C# [Unsga3](https://github.com/AppSprout-dev/Unsga3) and, when installed, a pymoo IGD. Same public protocol as the C# docs (`docs/EQUIVALENCE.md`): shared fixtures / later ZDT–DTLZ, Das–Dennis partitions, IGD as mean nearest-neighbor distance.

This repo is not a NuGet package and is not a drop-in into C# consumers. Do not invent IGD / HV / Wilcoxon numbers.

## Layer 1 — v0 core (wired)

Feed a **population of objective vectors** through Bend `NonDominatedSort` → `Normalization` → associate → `Survival.select`. No `Run` loop. Variation operators live in `src/sbx.bend` / `src/polynomial_mutation.bend` (`bend src/op_smoke.bend`).

1. Fixture JSON: same `M`, same order, plus Das–Dennis `(n_obj, partitions)` and `target_size`. Checked-in smoke: [fixtures/core_2obj.json](fixtures/core_2obj.json) (mirrored in `src/ab_select.bend`).
2. **Bend dump:** `ab/dump_bend_front.py` runs `bend src/ab_select.bend` (or a generated program from `--fixture`) and writes `ab/out/bend_F.csv`.
3. **C# dump (optional):** `ab/dump_csharp_front.py` skips (exit 0) when `UNSGA3_CS_ROOT` is unset. When set, it runs `ab/csharp_core_dump` with `dotnet` against `$UNSGA3_CS_ROOT/src/Unsga3/Unsga3.csproj` and writes `ab/out/csharp_F.csv` via C# `NondominatedSortingSurvival.Select` (`rng == null`) on the same fixture. Missing `dotnet` or a build/run failure prints `skip: …` and exits 0 (no invented front). This tree does not clone Unsga3.
4. **Compare:** `ab/compare.py` prints the Bend rows and, if `ab/out/csharp_F.csv` exists, whether the row-sets match.
5. **IGD vs pymoo (optional):** `ab/igd_vs_pymoo.py` computes IGD of the dumped front against the analytic 2-obj unit simplex when pymoo is installed; otherwise it prints `skip: pymoo is not installed` and exits 0.

## Layer 2 — later algorithm A/B (after `Run`)

SBX and polynomial mutation are in. Once `Unsga3Algorithm.Run` and shared ZDT/DTLZ exist: dump C# / Bend fronts on those settings and IGD vs pymoo. Not in this slice.

## Smoke

From the repo root (Bend 2.0.9 on `PATH`):

```bash
python3 ab/dump_bend_front.py
python3 ab/dump_csharp_front.py    # optional; skips without UNSGA3_CS_ROOT / dotnet
python3 ab/igd_vs_pymoo.py         # skips if pymoo missing
python3 ab/compare.py
```

Or run the Bend driver directly:

```bash
bend src/ab_select.bend
```

Dumps go under `ab/out/` (gitignored).

## Scripts

| Script | Role |
|--------|------|
| `dump_bend_front.py` | runs v0 `Survival.select`, writes `ab/out/bend_F.csv` |
| `dump_csharp_front.py` | optional C# `Select` dump via `ab/csharp_core_dump`; skips if `UNSGA3_CS_ROOT` / `dotnet` / build is missing |
| `csharp_core_dump/` | one-shot `dotnet` helper; `ProjectReference` is `$UNSGA3_CS_ROOT/src/Unsga3/Unsga3.csproj` |
| `igd_vs_pymoo.py` | IGD vs pymoo when installed; otherwise skip |
| `compare.py` | prints Bend rows; compares to C# CSV when present |
