# A/B

Compare **unsga3-bend** v0 core selection to C# [Unsga3](https://github.com/AppSprout-dev/Unsga3) and, when installed, a pymoo IGD. Same public protocol as the C# docs (`docs/EQUIVALENCE.md`): shared fixtures / later ZDT–DTLZ, Das–Dennis partitions, IGD as mean nearest-neighbor distance.

This repo is not a NuGet package and is not a drop-in into C# consumers. Do not invent IGD / HV / Wilcoxon numbers.

## Layer 1 — v0 core (wired)

Feed a **population of objective vectors** through Bend `NonDominatedSort` → `Normalization` → associate → `Survival.select`. No SBX, mutation, or `Run` loop.

1. Fixture JSON: same `M`, same order, plus Das–Dennis `(n_obj, partitions)` and `target_size`. Checked-in smoke: [fixtures/core_2obj.json](fixtures/core_2obj.json) (mirrored in `src/ab_select.bend`).
2. **Bend dump:** `ab/dump_bend_front.py` runs `bend src/ab_select.bend` (or a generated program from `--fixture`) and writes `ab/out/bend_F.csv`.
3. **C# dump (optional):** `ab/dump_csharp_front.py` skips unless you have a local AppSprout-dev/Unsga3 checkout (`UNSGA3_CS_ROOT`). This tree does not clone Unsga3.
4. **Compare:** `ab/compare.py` prints the Bend rows and, if `ab/out/csharp_F.csv` exists, whether the row-sets match.
5. **IGD vs pymoo (optional):** `ab/igd_vs_pymoo.py` computes IGD of the dumped front against the analytic 2-obj unit simplex when pymoo is installed; otherwise it prints `skip: pymoo is not installed` and exits 0.

## Layer 2 — later algorithm A/B (after pass 2)

Once SBX, polynomial mutation, and `Unsga3Algorithm.Run` exist: dump C# / Bend fronts on shared ZDT/DTLZ settings and IGD vs pymoo. Not in v0.

## Smoke

From the repo root (Bend 2.0.9 on `PATH`):

```bash
python3 ab/dump_bend_front.py
python3 ab/dump_csharp_front.py    # optional; skips without UNSGA3_CS_ROOT
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
| `dump_csharp_front.py` | optional C# dump; skips if Unsga3 is not available locally |
| `igd_vs_pymoo.py` | IGD vs pymoo when installed; otherwise skip |
| `compare.py` | prints Bend rows; compares to C# CSV when present |
