# unsga3-bend

Greenfield [Bend](https://bend-lang.com/) **2** port of **U-NSGA-III** (Seada & Deb, 2016).

This repository is **standalone public OSS**. It is **not** a NuGet package, **not** PackageId `Unsga3`, **not** a drop-in replacement for C# consumers, and **not** a dependency of any private product. Consumers that already use the C# library keep using that library; this repo does not know about those applications.

```text
https://github.com/AppSprout-dev/unsga3-bend
```

## Relation to C# Unsga3

The reference implementation is the existing C# library:

- Source: [AppSprout-dev/Unsga3](https://github.com/AppSprout-dev/Unsga3)
- **PackageId `Unsga3` stays C# only** — NuGet / [GitHub Packages](https://github.com/AppSprout-dev/Unsga3#install)

`unsga3-bend` is a from-scratch Bend 2 port of the algorithm core, not a binding and not a republish of that package. The two stacks sit **beside** each other: C# remains the .NET package; this tree is the Bend **hub** package. The shared validation plan is the same public protocol the C# docs use: ZDT / DTLZ problems and IGD against a [pymoo](https://pymoo.org/) `UNSGA3` oracle ([C# `docs/EQUIVALENCE.md`](https://github.com/AppSprout-dev/Unsga3/blob/main/docs/EQUIVALENCE.md)).

## Hub package (0.1.2)

**0.1.2** is the current Bend content-hash hub package. `bend src/lib.bend --publish` ran again for this tree (Bend 2.0.25). Artifacts do **not** go to nuget.org or GitHub Packages.

**0.1.0** was the first hub publish (`0xcd07e24a626a62e74603d48f436cd679`). GitHub **0.1.1** was a docs/ab confidence bump (multi-seed IGD tables + Layer-1 fixture check) and did not re-publish. GitHub **0.1.2** includes the RankNicheDistance fix. A/B stays `PymooCompatible`.

### How consumers import

Bend fetches a published package by content hash (`bend guide` § Modules). Consumer-facing import (package alias `Unsga3`):

```bend
import 0x527a2a4fa91b05a0250d7be0e11d232a/lib.bend as Unsga3
```

`bend src/lib.bend --publish` printed this exact line (alias `Lib`):

```bend
import 0x527a2a4fa91b05a0250d7be0e11d232a/lib.bend as Lib
```

The hub entry path is `/lib.bend` (what bend printed), not `/src/lib.bend`. Content hash: `0x527a2a4fa91b05a0250d7be0e11d232a`.

Develop against `src/` in this checkout with a local path:

```bend
import ./src/lib.bend as Unsga3
```

`src/lib.bend` is the module-graph facade (core + variation + problems + `Run`). See [CHANGELOG.md](CHANGELOG.md).

## What is in this tree

Shipped in the **0.1.2** hub package (algorithm + A/B helpers):

- **Core** — non-dominated sort, NSGA-III normalization, Das–Dennis directions, niching / association, survival
- **Variation + Run** — decision variables, SBX (η=30, p=1.0), polynomial mutation (η=20, p=1/n), ZDT1 / ZDT2 / DTLZ2 (3-obj), `PymooCompatible` tournament, `Unsga3Algorithm.Run`
- **Parallel maps** — independent per-individual work uses Bend `a b = f(lo) f(hi)` mid-splits. Tournament, SBX, mutation, and last-front niching stay sequential so a fixed seed consumes RNG in the same order
- **Native dumps** — `bend src/….bend -o …` then run the binary. `ab/dump_bend_run.py --native` prefers that path and falls back to `bend file.bend` if the build fails
- **Proofs** — `bend PROOF.bend` is 0 `?TODO`

Measured native phase tables (not IGD): [docs/PERF_NOTES.md](docs/PERF_NOTES.md). Protocol: [docs/EQUIVALENCE.md](docs/EQUIVALENCE.md).

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

## How A/B works

Two layers; do not invent IGD numbers in this repo.

1. **v0 core A/B** — feed the **same objective population** to C# and Bend sort / normalize / associate / select. Compare ranks, associations, and the selected index set.
2. **Algorithm A/B** — dump ND fronts from Bend `Run` (and optionally C# `OracleCompare` when `UNSGA3_CS_ROOT` is set) on shared ZDT/DTLZ settings; IGD vs pymoo when installed.

Protocol (same as C# `docs/EQUIVALENCE.md` / `tools/OracleCompare`; dump defaults in [`ab/protocol.py`](ab/protocol.py)):

| Label | Problem | Partitions | Pop | Gens | Seed | Tournament |
|-------|---------|------------|-----|------|------|------------|
| **oracle ZDT1** | ZDT1 n=30 | 12 | 52 | 100 | 1 | PymooCompatible |
| **oracle ZDT2** | ZDT2 n=30 | 12 | 52 | **250** | 1 | PymooCompatible |
| **oracle DTLZ2** | DTLZ2 M=3 k=10 | 12 | 92 | 150 | 1 | PymooCompatible |
| **smoke ZDT1** (checked-in) | ZDT1 n=30 | 4 | 8 | 3 | 1 | PymooCompatible |

Operators: SBX η=30, PM η=20, p_c=1.0, p_m=1/n. Smoke is labeled smoke and is **not** an oracle claim. ZDT2 **quality protocol is gens=250**; **gens=100 is an early-stress snapshot** (PR #16: Bend 10/15 and C# 8/15 collapse), not the A/B default — see [docs/ZDT2_COLLAPSE.md](docs/ZDT2_COLLAPSE.md) and [`ab/protocol.py`](ab/protocol.py). RankNicheDistance is an optional dump flag (`--tournament rank_niche`), not the new default.

**Intentional deltas vs C#:** Bend RNG is a portable LCG (not `System.Random`), so fronts will not match bit-for-bit. `Run` survival niching threads rng for min-count niche ties (C# `Select(..., rng)`); last-front extras are random among near-best on the ray, not uniform `inNiche[rng.Next]` (that LCG path collapsed oracle ZDT2). v0 `select` stays deterministic. Duplicate keys round decision variables to 12 decimal places (`round(x*1e12)/1e12`), which is not C# `ToString("G12")` significant digits (small variables diverge; see `src/g12_key.bend`). Unequal-length objectives are mutual non-domination (C# `ComparePareto` throws; see `src/nds_unequal.bend`). C# ctor default tournament is `RankNicheDistance`; Bend A/B / smoke uses `PymooCompatible`. GitHub **0.1.2** orders that optional key as rank, then niche count, then perpendicular distance, then a coin. DTLZ2 IGD uses a Das–Dennis-density PF (see [ab/README.md](ab/README.md)); pymoo’s default ~136-pt PF is a different yardstick.

## Install Bend and check this tree

Bend is **not** assumed to be on `PATH`. Install from the official script:

```bash
curl -fsSL https://bend-lang.com/install.sh | sh
export PATH="$HOME/.bend/bin:$PATH"
export BEND_NO_TELEMETRY=1
bend guide
```

**Smoke** (not the quality protocol — ZDT1 pop=8, gens=3):

```bash
bend src/lib.bend       # module graph: All terms check (Bend 2.0.10+)
bend src/ab_select.bend # v0 selection smoke (prints CSV front)
bend src/op_smoke.bend  # SBX + poly mutation on a 2-var box, seed 42
bend src/run_smoke.bend # short fixed-seed ZDT1 Run; prints ND front CSV
bend PROOF.bend         # gate: all LAWS.bend claims closed (0 ?TODO)
mkdir -p ab/out
bend src/run_smoke.bend -o ab/out/run_smoke   # clang 14+
./ab/out/run_smoke --threads 8
python3 ab/dump_bend_front.py
python3 ab/dump_bend_run.py --native          # same smoke; fallback to `bend file.bend`
```

**Quality A/B** (optional; pass the table knobs — see [docs/EQUIVALENCE.md](docs/EQUIVALENCE.md)):

```bash
python3 ab/dump_bend_run.py --native --problem zdt1 --partitions 12 --pop 52 --gens 100 --seed 1
python3 ab/dump_bend_run.py --native --problem zdt2 --partitions 12 --pop 52 --seed 1
# omitted --gens on zdt2 is 250 (ab/protocol.py). --gens 100 is early-stress only.
python3 ab/dump_bend_run.py --native --problem dtlz2 --partitions 12 --pop 92 --gens 150 --seed 1
python3 ab/dump_csharp_front.py   # skip if UNSGA3_CS_ROOT unset
python3 ab/dump_csharp_run.py     # skip if UNSGA3_CS_ROOT unset
python3 ab/igd_vs_pymoo.py --front ab/out/bend_run_F.csv --problem zdt1 --pf-points 500
```

`dump_bend_run.py` writes the `#` header plus objective rows (Bend's `All terms check` banner is stripped so interpreter and native dumps match). `--bin PATH` runs an already-built binary. `UNSGA3_BEND_NATIVE=1` is the same as `--native`. `--interpreter` forces `bend file.bend`. Do not invent timings or IGD.

Language: [bend-lang.com](https://bend-lang.com/) · [github.com/bendlang/bend](https://github.com/bendlang/bend). How to contribute: [CONTRIBUTING.md](CONTRIBUTING.md).

Modules are `.bend` files: `import Base`, `import ./x.bend as M`. Laws live in `LAWS.bend` (human-owned). Proofs live in `PROOF.bend`. `bend PROOF.bend` is the gate.

## Layout

```
unsga3-bend/
├── AGENTS.md                 # Bend agent rules + product locks
├── CHANGELOG.md              # 0.1.2 hub re-publish + 0.1.1 docs/ab notes
├── CONTRIBUTING.md           # install / smoke / proofs / do-nots
├── LAWS.bend                 # core + operator + Run/ZDT claims (human-owned)
├── PROOF.bend                # imports LAWS; closed proofs
├── src/                      # core + variation + problems + Run + smokes
├── ab/                       # core + algorithm dump / optional IGD / optional C#
├── ab/protocol.py            # A/B defaults (ZDT2 gens=250)
├── docs/EQUIVALENCE.md       # public protocol (this tree)
├── docs/ORACLE-MULTISEED.md  # 15-seed IGD + Layer-1 fixture check
├── docs/ROADMAP.md
├── docs/PERF_NOTES.md        # measured warm-native phases (not IGD)
├── docs/ZDT2_COLLAPSE.md     # ZDT2 gens=100 early-stress vs gens=250 quality
└── LICENSE                   # MIT
```

| Doc | Role |
|-----|------|
| [CONTRIBUTING.md](CONTRIBUTING.md) | how to check the tree |
| [docs/EQUIVALENCE.md](docs/EQUIVALENCE.md) | quality protocol + C# pointer |
| [docs/ORACLE-MULTISEED.md](docs/ORACLE-MULTISEED.md) | 15-seed IGD (Bend / C# / pymoo NSGA-III) + fixture bit-check |
| [docs/ZDT2_COLLAPSE.md](docs/ZDT2_COLLAPSE.md) | why ZDT2 gens=100 is early-stress |
| [docs/PERF_NOTES.md](docs/PERF_NOTES.md) | warm-native phase tables |
| [docs/ROADMAP.md](docs/ROADMAP.md) | shipped vs open |
| [ab/README.md](ab/README.md) | dump / IGD scripts |

## License

MIT — see [LICENSE](LICENSE).

**Not affiliated with pymoo.** A/B scripts compare against pymoo as an external tool when it is installed; this repo does not vendor pymoo.
