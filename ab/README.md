# A/B

Compare **unsga3-bend** to C# [Unsga3](https://github.com/AppSprout-dev/Unsga3) and, when installed, a pymoo IGD. Same public protocol as the C# docs (`docs/EQUIVALENCE.md`): Das–Dennis partitions, pop, gens, seed, IGD as mean nearest-neighbor distance.

This repo is not a NuGet package and is not a drop-in into C# consumers. Do not invent IGD / HV / Wilcoxon numbers.

## Layer 1 — v0 core (wired)

Feed a **population of objective vectors** through Bend `NonDominatedSort` → `Normalization` → associate → `Survival.select`.

1. Fixture JSON: same `M`, same order, plus Das–Dennis `(n_obj, partitions)` and `target_size`. Checked-in smoke: [fixtures/core_2obj.json](fixtures/core_2obj.json) (mirrored in `src/ab_select.bend`).
2. **Bend dump:** `ab/dump_bend_front.py` runs `bend src/ab_select.bend` (or a generated program from `--fixture`) and writes `ab/out/bend_F.csv`.
3. **C# dump (optional):** `ab/dump_csharp_front.py` skips (exit 0) when `UNSGA3_CS_ROOT` is unset.
4. **Compare:** `ab/compare.py` prints the Bend rows and, if `ab/out/csharp_F.csv` exists, whether the row-sets match.
5. **IGD vs pymoo (optional):** `ab/igd_vs_pymoo.py` (default `--problem simplex`) or `skip: pymoo is not installed`.

## Layer 2 — algorithm A/B (`Run`)

`Unsga3Algorithm.Run`: init → evaluate → tournament parents → SBX → polynomial mutation → evaluate offspring → survival `Select` with persistent Normalization.

### Protocol

| Label | Problem | Partitions | Pop | Gens | Seed | Tournament |
|-------|---------|------------|-----|------|------|------------|
| **oracle ZDT1** | ZDT1 n=30 | 12 | 52 | 100 | 1 | PymooCompatible |
| **oracle ZDT2** | ZDT2 n=30 | 12 | 52 | 100 | 1 | PymooCompatible |
| **oracle DTLZ2** | DTLZ2 M=3 k=10 | 12 | 92 | 150 | 1 | PymooCompatible |
| **smoke ZDT1** | ZDT1 n=30 | 4 | 8 | 3 | 1 | PymooCompatible |

Operators match C#: SBX η=30, PM η=20, p_c=1.0, p_m=1/n. Smoke is **not** an oracle claim.

C# side (when `UNSGA3_CS_ROOT` points at a local Unsga3 checkout):

```bash
dotnet run --project tools/OracleCompare -c Release -- \
  --problem zdt1 --partitions 12 --pop 52 --gens 100 --seed 1 --pymoo-mode
```

### Deltas vs C#

- Bend RNG is a portable LCG, not `System.Random` — fronts will not match bit-for-bit.
- Survival niching is the v0 deterministic (`rng == null`) branch; C# `Run` passes rng.
- Duplicate elimination uses exact F32 equality, not C# G12 decision keys.
- Unconstrained problems only (no constraint-domination).
- A/B / smoke tournament is `PymooCompatible`. C# ctor default is `RankNicheDistance` (also implemented).

## Smoke

From the repo root (Bend 2.0.10 on `PATH`):

```bash
python3 ab/dump_bend_front.py
python3 ab/dump_bend_run.py          # src/run_smoke.bend → ab/out/bend_run_F.csv
python3 ab/dump_csharp_front.py      # optional; skips without UNSGA3_CS_ROOT / dotnet
python3 ab/dump_csharp_run.py --smoke
python3 ab/igd_vs_pymoo.py           # v0 simplex; skips if pymoo missing
python3 ab/igd_vs_pymoo.py --front ab/out/bend_run_F.csv --problem zdt1
python3 ab/compare.py
```

Or run the Bend drivers directly:

```bash
bend src/ab_select.bend
bend src/run_smoke.bend
```

Dumps go under `ab/out/` (gitignored).

## Scripts

| Script | Role |
|--------|------|
| `dump_bend_front.py` | v0 `Survival.select`, writes `ab/out/bend_F.csv` |
| `dump_bend_run.py` | `Unsga3Algorithm.Run` smoke (or generated custom), writes `ab/out/bend_run_F.csv` |
| `dump_csharp_front.py` | optional C# `Select` dump; skips if `UNSGA3_CS_ROOT` / `dotnet` is missing |
| `dump_csharp_run.py` | optional C# `OracleCompare` dump; skips if `UNSGA3_CS_ROOT` / `dotnet` is missing |
| `csharp_core_dump/` | one-shot `dotnet` helper for layer-1 `Select` |
| `igd_vs_pymoo.py` | IGD vs pymoo when installed (`--problem simplex\|zdt1\|zdt2\|dtlz2`); otherwise skip |
| `compare.py` | prints Bend rows; compares to C# CSV when present |
