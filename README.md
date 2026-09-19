# unsga3-bend

Greenfield [Bend](https://bend-lang.com/) rewrite of **U-NSGA-III** (Seada & Deb, 2016).

This repository is **standalone public OSS**. It is **not** a NuGet package, **not** a drop-in replacement for C# consumers, and **not** a dependency of any private product. Consumers that already use the C# library keep using that library; this repo does not know about those applications.

```text
https://github.com/AppSprout-dev/unsga3-bend
```

## Relation to C# Unsga3

The reference implementation is the existing C# library:

- Source: [AppSprout-dev/Unsga3](https://github.com/AppSprout-dev/Unsga3)
- **PackageId `Unsga3` stays C# / NuGet only**

`unsga3-bend` is a from-scratch Bend 2 port of the algorithm core, not a binding and not a republish of that package. The shared validation plan is the same public protocol the C# docs use: ZDT / DTLZ problems and IGD against a [pymoo](https://pymoo.org/) `UNSGA3` oracle ([C# `docs/EQUIVALENCE.md`](https://github.com/AppSprout-dev/Unsga3/blob/main/docs/EQUIVALENCE.md)).

Bend artifacts publish later via `bend … --publish` (content-hash hub). They do **not** go to NuGet.

## What is in this tree

**v0 core** — sort / normalize / Das–Dennis / niching / survival on a population of objectives.

**Pass 2** — decision variables, SBX (η=30, p=1.0), polynomial mutation (η=20, p=1/n), ZDT1 / ZDT2 / DTLZ2 (3-obj), PymooCompatible mating tournament, and `Unsga3Algorithm.Run`.

**Parallel maps (landed)** — `evaluate_all`, reference-point association, and per-individual normalization use Bend parallel calls (`a b = f(lo) f(hi)`), mid-split fork-join. Observationally the same fronts as the sequential maps.

**Native `-o` dump path (landed)** — compile a Run driver with `bend src/….bend -o …` and execute the binary for the same CSV front. `ab/dump_bend_run.py --native` prefers that path and falls back to `bend file.bend` if the build fails. Proofs are still next. Hub publish is later.

| Module | C# surface it mirrors |
|--------|------------------------|
| `Individual` | objectives + variables + evaluated + rank/niche bookkeeping |
| `NonDominatedSort` | fast non-dominated sort + Pareto compare |
| `Normalization` | NSGA-III adaptive hyperplane (persistent across `Run`) |
| `ReferenceDirections` | Das–Dennis directions / count |
| `Survival` | niching association + environmental selection |
| `problems` | `Zdt1Problem` / `Zdt2Problem` / `Dtlz2Problem` |
| `tournament` | `TournamentSelection` / `TournamentMode` |
| `algorithm` | `Unsga3Algorithm.Run` |

Hub publish is still later.

## How A/B works

Two layers; do not invent IGD numbers in this repo.

1. **v0 core A/B** — feed the **same objective population** to C# and Bend sort / normalize / associate / select. Compare ranks, associations, and the selected index set.
2. **Algorithm A/B** — dump ND fronts from Bend `Run` (and optionally C# `OracleCompare` when `UNSGA3_CS_ROOT` is set) on shared ZDT/DTLZ settings; IGD vs pymoo when installed.

Protocol (same as C# `docs/EQUIVALENCE.md` / `tools/OracleCompare`):

| Label | Problem | Partitions | Pop | Gens | Seed | Tournament |
|-------|---------|------------|-----|------|------|------------|
| **oracle ZDT1** | ZDT1 n=30 | 12 | 52 | 100 | 1 | PymooCompatible |
| **oracle ZDT2** | ZDT2 n=30 | 12 | 52 | 100 | 1 | PymooCompatible |
| **oracle DTLZ2** | DTLZ2 M=3 k=10 | 12 | 92 | 150 | 1 | PymooCompatible |
| **smoke ZDT1** (checked-in) | ZDT1 n=30 | 4 | 8 | 3 | 1 | PymooCompatible |

Operators: SBX η=30, PM η=20, p_c=1.0, p_m=1/n. Smoke is labeled smoke and is **not** an oracle claim.

**Intentional deltas vs C#:** Bend RNG is a portable LCG (not `System.Random`), so fronts will not match bit-for-bit. `Run` survival niching threads rng for min-count niche ties (C# `Select(..., rng)`); last-front extras are random among near-best on the ray, not uniform `inNiche[rng.Next]` (that LCG path collapsed oracle ZDT2). v0 `select` stays deterministic. Duplicate keys use C# G12-style 12-decimal rounding. C# ctor default tournament is `RankNicheDistance`; Bend A/B / smoke uses `PymooCompatible`. DTLZ2 IGD uses a Das–Dennis-density PF (see [ab/README.md](ab/README.md)); pymoo’s default ~136-pt PF is a different yardstick.

## Install Bend

Bend is **not** assumed to be on `PATH` in every environment. Install from the official script, then check this tree:

```bash
curl -fsSL https://bend-lang.com/install.sh | sh
bend guide
bend src/lib.bend       # module graph: All terms check (Bend 2.0.10+)
bend src/ab_select.bend # v0 selection smoke (prints CSV front)
bend src/op_smoke.bend  # SBX + poly mutation on a 2-var box, seed 42
bend src/run_smoke.bend # short fixed-seed ZDT1 Run; prints ND front CSV
bend PROOF.bend         # gate: closed Nat laws + remaining ?TODO
# Native Run dump (clang 14+). Same CSV front as `bend src/run_smoke.bend`.
mkdir -p ab/out
bend src/run_smoke.bend -o ab/out/run_smoke
./ab/out/run_smoke --threads 8
python3 ab/dump_bend_front.py
python3 ab/dump_bend_run.py --native   # build+run binary; fallback to `bend file.bend`
python3 ab/dump_csharp_front.py   # skip if UNSGA3_CS_ROOT unset
python3 ab/dump_csharp_run.py     # skip if UNSGA3_CS_ROOT unset
python3 ab/igd_vs_pymoo.py --front ab/out/bend_run_F.csv --problem zdt1
python3 ab/igd_vs_pymoo.py --front ab/out/bend_run_F.csv --problem dtlz2 --partitions 12
```

`dump_bend_run.py` writes the `#` header plus objective rows (Bend's `All terms check` banner is stripped so interpreter and native dumps match). `--bin PATH` runs an already-built binary. `UNSGA3_BEND_NATIVE=1` is the same as `--native`. `--interpreter` forces `bend file.bend`. Do not invent timings.

Language: [bend-lang.com](https://bend-lang.com/) · [github.com/bendlang/bend](https://github.com/bendlang/bend).

Modules are `.bend` files: `import Base`, `import ./x.bend as M`. Laws live in `LAWS.bend` (human-owned). Proofs live in `PROOF.bend`. `bend PROOF.bend` is the gate.

## Layout

```
unsga3-bend/
├── AGENTS.md                 # Bend agent rules + product locks
├── LAWS.bend                 # core + operator + Run/ZDT claims (human-owned)
├── PROOF.bend                # imports LAWS; open / stub proofs
├── src/                      # core + variation + problems + Run + smokes
├── ab/                       # core + algorithm dump / optional IGD / optional C#
├── docs/ROADMAP.md
└── LICENSE                   # MIT
```

## License

MIT — see [LICENSE](LICENSE).

**Not affiliated with pymoo.** The planned oracle compares against pymoo as an external tool; this repo does not vendor pymoo.
