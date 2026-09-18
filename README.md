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

## v0 vs later

**v0 (this scaffold) — core only**, enough to A/B a front when a **population of objectives** is already provided:

| Module | C# surface it mirrors |
|--------|------------------------|
| `Individual` | objectives only (no decision variables yet) |
| `NonDominatedSort` | fast non-dominated sort + Pareto compare |
| `Normalization` | NSGA-III hyperplane normalization |
| `ReferenceDirections` | Das–Dennis directions / count |
| `Survival` | niching association + environmental selection |

**Out of v0** (second pass, after v0 core matches):

- SBX crossover
- polynomial mutation
- `Unsga3Algorithm.Run` generational loop
- samples that need variation operators

See [docs/ROADMAP.md](docs/ROADMAP.md).

## How A/B works

Two layers; do not invent IGD numbers in this repo.

1. **v0 core A/B** — feed the **same objective population** to C# and Bend sort / normalize / associate / select. Compare ranks, associations, and the selected index set. No full evolutionary run required.
2. **Later algorithm A/B** — once variation + `Run` exist, dump non-dominated fronts from C# Unsga3 and from Bend on the same ZDT/DTLZ settings, compute IGD vs pymoo, compare. Protocol: same Das–Dennis partitions, pop size, generations, and seed as the C# oracle docs.

Outline and unwired stubs: [ab/README.md](ab/README.md). Scripts print `not wired` rather than fake metrics.

## Install Bend

Bend is **not** assumed to be on `PATH` in every environment. Install from the official script, then check this tree:

```bash
curl -fsSL https://bend-lang.com/install.sh | sh
bend guide
bend src/lib.bend    # v0 stubs: All terms check (Bend 2.0.9)
bend PROOF.bend      # gate: open laws, currently 13 ?TODO
```

Language: [bend-lang.com](https://bend-lang.com/) · [github.com/bendlang/bend](https://github.com/bendlang/bend).

Modules are `.bend` files: `import Base`, `import ./x.bend as M`. Laws live in `LAWS.bend` (human-owned). Proofs live in `PROOF.bend`. `bend PROOF.bend` is the gate; v0 proofs are mostly open (`?TODO`).

## Layout

```
unsga3-bend/
├── AGENTS.md                 # Bend agent rules + product locks
├── LAWS.bend                 # v0 core claims (human-owned)
├── PROOF.bend                # imports LAWS; open / stub proofs
├── src/                      # Bend modules (signatures + stubs)
├── ab/                       # A/B outline; scripts print "not wired"
├── docs/ROADMAP.md
└── LICENSE                   # MIT
```

## License

MIT — see [LICENSE](LICENSE).

**Not affiliated with pymoo.** The planned oracle compares against pymoo as an external tool; this repo does not vendor pymoo.
