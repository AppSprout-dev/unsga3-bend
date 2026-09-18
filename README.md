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

## v0 vs pass 2

**v0 core** — enough to A/B a front when a **population of objectives** is already provided:

| Module | C# surface it mirrors |
|--------|------------------------|
| `Individual` | objectives (v0) + decision variables + evaluated (pass 2) |
| `NonDominatedSort` | fast non-dominated sort + Pareto compare |
| `Normalization` | NSGA-III adaptive hyperplane (ASF extremes + intercepts; C# front/pop/unit fallbacks) |
| `ReferenceDirections` | Das–Dennis directions / count |
| `Survival` | niching association + environmental selection |

**Pass 2, first slice (in tree)** — variation operators, not a full run:

| Module | C# surface it mirrors |
|--------|------------------------|
| `bounds` | tiny `IProblem` box: variable count + per-var `[lo, hi]` (not ZDT/DTLZ) |
| `rng` | `RandomProvider` (seed + `NextDouble`; portable LCG, not .NET `System.Random`) |
| `sbx` | `SimulatedBinaryCrossover` — default η=30, pair probability=1.0 |
| `polynomial_mutation` | `PolynomialMutation` — default η=20; **per-variable probability is passed in** (C# `Run` uses `1/n` when unset) |

**Still next:** `Unsga3Algorithm.Run`, shared ZDT/DTLZ, samples, algorithm A/B / IGD vs pymoo.

See [docs/ROADMAP.md](docs/ROADMAP.md).

## How A/B works

Two layers; do not invent IGD numbers in this repo.

1. **v0 core A/B** — feed the **same objective population** to C# and Bend sort / normalize / associate / select. Compare ranks, associations, and the selected index set. No full evolutionary run required.
2. **Later algorithm A/B** — once `Run` + ZDT/DTLZ exist, dump non-dominated fronts from C# Unsga3 and from Bend on the same settings, compute IGD vs pymoo, compare. Protocol: same Das–Dennis partitions, pop size, generations, and seed as the C# oracle docs. SBX + polynomial mutation are in; the generational loop is not.

v0 core path: [ab/README.md](ab/README.md). `dump_bend_front.py` runs Bend selection. The C# dump runs `NondominatedSortingSurvival.Select` when `UNSGA3_CS_ROOT` and `dotnet` work, otherwise both it and the pymoo IGD script skip with a clear message. No invented metrics.

## Install Bend

Bend is **not** assumed to be on `PATH` in every environment. Install from the official script, then check this tree:

```bash
curl -fsSL https://bend-lang.com/install.sh | sh
bend guide
bend src/lib.bend       # core + SBX/mutation: All terms check (Bend 2.0.9+)
bend src/ab_select.bend # v0 selection smoke (prints CSV front)
bend src/op_smoke.bend  # SBX + poly mutation on a 2-var box, seed 42
bend PROOF.bend         # gate: v0 empty/M=1/binomial/count + operator defaults / p=0 copies; remaining ?TODO
python3 ab/dump_bend_front.py
python3 ab/igd_vs_pymoo.py   # skip if pymoo missing
```

Language: [bend-lang.com](https://bend-lang.com/) · [github.com/bendlang/bend](https://github.com/bendlang/bend).

Modules are `.bend` files: `import Base`, `import ./x.bend as M`. Laws live in `LAWS.bend` (human-owned). Proofs live in `PROOF.bend`. `bend PROOF.bend` is the gate; empty-input / M=1 / `binomial(n,0)` / `das_dennis_count` plus operator-default and probability-0 copy laws are closed, quantified size laws stay `?TODO`.

## Layout

```
unsga3-bend/
├── AGENTS.md                 # Bend agent rules + product locks
├── LAWS.bend                 # core + operator claims (human-owned)
├── PROOF.bend                # imports LAWS; open / stub proofs
├── src/                      # core + SBX / mutation + ab_select / op_smoke
├── ab/                       # v0 selection dump / optional IGD / optional C#
├── docs/ROADMAP.md
└── LICENSE                   # MIT
```

## License

MIT — see [LICENSE](LICENSE).

**Not affiliated with pymoo.** The planned oracle compares against pymoo as an external tool; this repo does not vendor pymoo.
