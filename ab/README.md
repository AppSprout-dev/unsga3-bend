# A/B

Compare **unsga3-bend** to C# [Unsga3](https://github.com/AppSprout-dev/Unsga3) and, when installed, a pymoo IGD. Same public protocol as [docs/EQUIVALENCE.md](../docs/EQUIVALENCE.md) and C# `docs/EQUIVALENCE.md`: Das–Dennis partitions, pop, gens, seed, IGD as mean nearest-neighbor distance. Dump defaults: [`protocol.py`](protocol.py).

This repo is not a NuGet package and is not a drop-in into C# consumers. PackageId `Unsga3` stays C# / NuGet / GitHub Packages; Bend is the hub package beside it (planned **0.1.0**, hash filled at publish). Do not invent IGD / HV / Wilcoxon numbers.

## Layer 1 — v0 core (wired)

Feed a **population of objective vectors** through Bend `NonDominatedSort` → `Normalization` → associate → `Survival.select`.

1. Fixture JSON: same `M`, same order, plus Das–Dennis `(n_obj, partitions)` and `target_size`. Checked-in smoke: [fixtures/core_2obj.json](fixtures/core_2obj.json) (mirrored in `src/ab_select.bend`).
2. **Bend dump:** `ab/dump_bend_front.py` runs `bend src/ab_select.bend` (or a generated program from `--fixture`) and writes `ab/out/bend_F.csv`.
3. **C# dump (optional):** `ab/dump_csharp_front.py` skips (exit 0) when `UNSGA3_CS_ROOT` is unset.
4. **Compare:** `ab/compare.py` prints the Bend rows and, if `ab/out/csharp_F.csv` exists, whether the row-sets match.
5. **IGD vs pymoo (optional):** `ab/igd_vs_pymoo.py` (default `--problem simplex`) or `skip: pymoo is not installed`. DTLZ2 uses a Das–Dennis-density PF (`--partitions`, default 12 → 91 pts at M=3), matching C# `ParetoFronts.Dtlz2`. pymoo’s default `pareto_front()` (~136 pts) is a different sample and will inflate IGD on the same front.

## Layer 2 — algorithm A/B (`Run`)

`Unsga3Algorithm.Run`: init → evaluate → tournament parents → SBX → polynomial mutation → evaluate offspring → survival `Select` with persistent Normalization.

### Protocol

| Label | Problem | Partitions | Pop | Gens | Seed | Tournament |
|-------|---------|------------|-----|------|------|------------|
| **oracle ZDT1** | ZDT1 n=30 | 12 | 52 | 100 | 1 | PymooCompatible |
| **oracle ZDT2** | ZDT2 n=30 | 12 | 52 | **250** | 1 | PymooCompatible |
| **oracle DTLZ2** | DTLZ2 M=3 k=10 | 12 | 92 | 150 | 1 | PymooCompatible |
| **smoke ZDT1** | ZDT1 n=30 | 4 | 8 | 3 | 1 | PymooCompatible |

Operators match C#: SBX η=30, PM η=20, p_c=1.0, p_m=1/n. Smoke is **not** an oracle claim.

ZDT2 **gens=100** is an early-stress snapshot (PR #16 / [PERF_NOTES.md](../docs/PERF_NOTES.md): Bend 10/15, C# 8/15 collapse), not this tree’s A/B default. The 15-seed gens=250 table recovered **0/15** on both stacks ([ZDT2_COLLAPSE.md](../docs/ZDT2_COLLAPSE.md)). `ab/protocol.py` is the dump-helper default: omitted `--gens` on `--problem zdt2` is 250. RankNicheDistance (`--tournament rank_niche`) stays an optional lever.

C# side (when `UNSGA3_CS_ROOT` points at a local Unsga3 checkout):

```bash
dotnet run --project tools/OracleCompare -c Release -- \
  --problem zdt1 --partitions 12 --pop 52 --gens 100 --seed 1 --pymoo-mode
```

### Apples-to-apples IGD (Bend vs C#, same PF)

Dump both fronts, then score **both** with this repo’s `igd_vs_pymoo.py` and the **same** PF flags. Do not compare C# `OracleCompare`’s printed IGD to a score against pymoo’s default DTLZ2 `pareto_front()` (~136 pts). That is a yardstick mismatch.

**DTLZ2** — Das–Dennis `--partitions` (default 12 → 91 pts at M=3). Expect `pf_rows=91` and `pf_source=pymoo-das-dennis` when pymoo is installed (`get_reference_directions` + `pareto_front(ref_dirs=…)`).

```bash
python3 ab/dump_bend_run.py --native --problem dtlz2 --partitions 12 --pop 92 --gens 150 --seed 1 \
  --out ab/out/bend_dtlz2_F.csv
python3 ab/dump_csharp_run.py --problem dtlz2 --partitions 12 --pop 92 --gens 150 --seed 1 \
  --out ab/out/csharp_dtlz2_F.csv

python3 ab/igd_vs_pymoo.py --front ab/out/bend_dtlz2_F.csv --problem dtlz2 --partitions 12
python3 ab/igd_vs_pymoo.py --front ab/out/csharp_dtlz2_F.csv --problem dtlz2 --partitions 12
```

**ZDT1** — analytic PF; `--pf-points 500` matches C# `ParetoFronts.Zdt1(500)`.

```bash
python3 ab/dump_bend_run.py --native --problem zdt1 --partitions 12 --pop 52 --gens 100 --seed 1 \
  --out ab/out/bend_zdt1_F.csv
python3 ab/dump_csharp_run.py --problem zdt1 --partitions 12 --pop 52 --gens 100 --seed 1 \
  --out ab/out/csharp_zdt1_F.csv

python3 ab/igd_vs_pymoo.py --front ab/out/bend_zdt1_F.csv --problem zdt1 --pf-points 500
python3 ab/igd_vs_pymoo.py --front ab/out/csharp_zdt1_F.csv --problem zdt1 --pf-points 500
```

**ZDT2** — same analytic PF; A/B default **gens=250** (omit `--gens` or pass it explicitly). `--gens 100` is the early-stress snapshot.

```bash
python3 ab/dump_bend_run.py --native --problem zdt2 --partitions 12 --pop 52 --seed 1 \
  --out ab/out/bend_zdt2_F.csv
python3 ab/dump_csharp_run.py --problem zdt2 --partitions 12 --pop 52 --seed 1 \
  --out ab/out/csharp_zdt2_F.csv

python3 ab/igd_vs_pymoo.py --front ab/out/bend_zdt2_F.csv --problem zdt2 --pf-points 500 --partitions 12
python3 ab/igd_vs_pymoo.py --front ab/out/csharp_zdt2_F.csv --problem zdt2 --pf-points 500 --partitions 12
```

`dump_csharp_run.py` skips (exit 0) without `UNSGA3_CS_ROOT` / `dotnet`. Do not invent a C# front or IGD. Compare the two `igd=` lines only when both CSVs exist and both prints show the same `pf_rows` / `partitions`.

### Deltas vs C#

- Bend RNG is a portable LCG, not `System.Random` — fronts will not match bit-for-bit.
- `Run` survival niching threads rng (random among equal min-count niches), matching C# `Select(..., rng)` for the ref pick. Empty niches take closest; extras draw among members within 2×best+0.01 of the ray. Uniform `inNiche[rng.Next]` with this LCG collapsed oracle ZDT2. v0 `Survival.select` stays deterministic (`rng == null`).
- Duplicate keys use C# G12-style 12-decimal rounding on decision vars (Bend F32 ULP is coarser than 1e-12).
- Unconstrained problems only (no constraint-domination).
- A/B / smoke tournament is `PymooCompatible`. C# ctor default is `RankNicheDistance` (also implemented; `--tournament rank_niche` is diagnostic, not the A/B default).
- DTLZ2 IGD must use the Das–Dennis PF at the run’s partitions. Scoring a C# or Bend front against pymoo’s default ~136-pt PF is a **yardstick mismatch**, not an algorithm gap (same C# seed-1 front: OracleCompare IGD ≈ 0.00403 vs ~0.051 on the old default PF).

## Smoke

From the repo root (Bend 2.0.10 on `PATH`):

```bash
python3 ab/dump_bend_front.py
python3 ab/dump_bend_run.py --native # prefer `bend … -o` binary; fallback `bend file.bend`
python3 ab/dump_csharp_front.py      # optional; skips without UNSGA3_CS_ROOT / dotnet
python3 ab/dump_csharp_run.py --smoke
python3 ab/igd_vs_pymoo.py           # v0 simplex; skips if pymoo missing
python3 ab/igd_vs_pymoo.py --front ab/out/bend_run_F.csv --problem zdt1
python3 ab/igd_vs_pymoo.py --front ab/out/bend_run_F.csv --problem dtlz2 --partitions 12
python3 ab/compare.py
```

Or run the Bend drivers directly:

```bash
bend src/ab_select.bend
bend src/run_smoke.bend
# Native (clang 14+). Same CSV front as the check-run (banner stripped in dumps).
mkdir -p ab/out
bend src/run_smoke.bend -o ab/out/run_smoke
./ab/out/run_smoke --threads 8
```

`dump_bend_run.py` prefers a native binary when `--native` / `UNSGA3_BEND_NATIVE=1` is set, when `--bin PATH` is given, or when a hash-matching cache binary is already executable. Cache key is sha256 of the driver `.bend` bytes (checked-in smoke or regenerated `ab/out/run_custom.bend`). Changing `--problem` / `--pop` / … rewrites that source (correct) and misses; an unchanged driver reuses `ab/out/run_cache/<hash>` and skips `bend -o`. If `bend … -o` fails, it prints the compiler output and falls back to `bend file.bend`. `--interpreter` skips native. `--threads N` is passed only to the binary.

Stderr on `--native`: `native: building …` plus `native: compile_s=…` on a miss; `native: cache hit …` on a warm reuse (`compile_s` omitted). `native: run_s=…` is the binary only — do not treat a cold dump’s wall time as Bend Run cost. Dumps write the `#` header plus objective rows so interpreter and native CSVs match; they do not invent IGD / HV.

Dumps go under `ab/out/` (gitignored).

## Phase profile (warm native)

`ab/profile_bend_run.py` builds a native binary (same hash cache idea as `dump_bend_run.py`) and runs it. Buckets are `IO.now()` milliseconds around evaluate / NDS / normalize / associate / niche / tournament / offspring (SBX+PM+G12 interleaved). Bend 2.0.13 has no sampling profiler. Citations and the measured table: [docs/PERF_NOTES.md](../docs/PERF_NOTES.md).

```bash
python3 ab/profile_bend_run.py
python3 ab/profile_bend_run.py --problem dtlz2 --partitions 12 --pop 92 --gens 150 --seed 1
python3 ab/profile_bend_run.py --problem zdt1 --partitions 12 --pop 52 --gens 100 --seed 1
python3 ab/profile_bend_run.py --problem zdt2 --partitions 12 --pop 52 --gens 250 --seed 1
```

`--rebuild` forces `bend -o` and prints `compile_s`. `--threads N` is passed only to the binary.

## Scripts

| Script | Role |
|--------|------|
| `dump_bend_front.py` | v0 `Survival.select`, writes `ab/out/bend_F.csv` |
| `protocol.py` | A/B defaults: ZDT2 gens=250, ZDT1=100, DTLZ2=150 (C# path / `ORACLE_GENS_*`). RankNicheDistance is not the default |
| `dump_bend_run.py` | `Unsga3Algorithm.Run` smoke (or generated custom), writes `ab/out/bend_run_F.csv`. `--native` compiles to `ab/out/run_cache/<sha256>` on miss and reuses that binary on hit; falls back to `bend <driver>` if the build fails. Stderr `compile_s` vs `run_s` splits those costs. Omitted `--gens` on `--problem zdt2` is 250. **Trap:** omitted `--gens` on `--problem dtlz2` stays historical **100**, and omitted `--pop` stays **52** — pass `--pop 92 --gens 150` for oracle DTLZ2. `dump_csharp_run.py` uses `protocol.py` (`pop=92`, `gens=150`) |
| `dump_csharp_front.py` | optional C# `Select` dump; skips if `UNSGA3_CS_ROOT` / `dotnet` is missing |
| `dump_csharp_run.py` | optional C# `OracleCompare` dump; skips if `UNSGA3_CS_ROOT` / `dotnet` is missing. Writes to a per-run `ab/out/csharp_oracle/<stem>/` so a leftover CSV from another problem is not picked (old shared-dir `glob[-1]` was wrong after multi-problem runs). |
| `csharp_core_dump/` | one-shot `dotnet` helper for layer-1 `Select` |
| `igd_vs_pymoo.py` | IGD vs pymoo when installed (`--problem simplex\|zdt1\|zdt2\|dtlz2`); DTLZ2 PF is Das–Dennis `--partitions` (prints `pf_rows` / `pf_source`); otherwise skip |
| `compare.py` | prints Bend rows; compares to C# CSV when present |
| `profile_run.bend` | IO.now() phase wrapper around the same Run calls (same RNG / front). No src/ hooks |
| `profile_smoke.bend` | checked-in smoke driver for the profiler |
| `profile_bend_run.py` | warm-cache `bend -o` + binary; prints ms/s/% per phase; `compile_s` vs `run_s`. See [docs/PERF_NOTES.md](../docs/PERF_NOTES.md) |
| `characterize_front.py` | 2-obj front geometry + IGD (pymoo or local mean-NN). Collapse = `n≤10` and `IGD≥0.3` |
| `zdt2_collapse_probe.py` | dump Bend / C# / pymoo ZDT2 (or ZDT1) over seeds×gens; JSONL summary |
| `zdt2_geometry.py` | analytic ZDT1/ZDT2 PF vs Das–Dennis rays (no Run) |

ZDT2 multi-seed collapse on **both** stacks at gens=100: [docs/ZDT2_COLLAPSE.md](../docs/ZDT2_COLLAPSE.md). A/B default is gens=250 / `pymoo`. `dump_bend_run.py --tournament rank_niche` and `dump_csharp_run.py --tournament rank_niche` are diagnostic.
