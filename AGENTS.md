# AGENTS

This is a Bend 2 repository. Follow the language, then the product locks.

## When using Bend

- run `bend guide` to learn it
- use `LAWS.bend` to keep important rules
- run `bend PROOF.bend` before committing
- parallelize the code whenever possible

Language docs: https://bend-lang.com/ and https://github.com/bendlang/bend

- Modules are `.bend` files.
- `import Base` at the top of each module that needs the prelude.
- Local modules: `import ./x.bend as M`.
- Laws live in `LAWS.bend` (human-owned open claims). Do not silently weaken, delete, or “pass” a law by changing it to match a stub.
- Proofs live in `PROOF.bend`, which must `import ./LAWS.bend`. A law named `foo` is proven by `def Laws.foo`. Use `?TODO` for open proofs. `bend PROOF.bend` is the gate even when proofs are incomplete.
- Prefer something that typechecks. If the Bend toolchain is missing, keep valid-looking `.bend` structure and note install in the README.

## Product locks (do not invent past this)

- **Name:** `unsga3-bend`. Greenfield Bend rewrite of U-NSGA-III.
- **Reference:** existing C# library [AppSprout-dev/Unsga3](https://github.com/AppSprout-dev/Unsga3). Read it via `gh` / GitHub API only; do **not** clone it into this repo.
- **PackageId `Unsga3` stays C# / NuGet only.** This tree is not a NuGet package. Later publish is `bend … --publish` (content-hash hub), not nuget.org / GitHub Packages.
- **Not a drop-in** for C# consumers. Shared plan is A/B of fronts and, later, ZDT/DTLZ + IGD vs a pymoo oracle using the same protocol as the C# Unsga3 docs.
- **v0 scope — CORE ONLY:** non-dominated sort, normalization, Das–Dennis reference directions, niching / reference-point association, survival selection. Enough to A/B fronts when a **population of objectives** is provided.
- **OUT of v0:** SBX crossover, polynomial mutation, full `Unsga3Algorithm.Run` loop, samples that need variation operators. Those are a second pass after v0 matches. Do not add SBX / mutation / `Run` laws yet.
- **Standalone OSS:** no mentions of private product repos or internal application names. Consumers wire their own Unsga3 usage; this repo does not know about them.
- **No fabricated benchmark numbers.** A/B scripts dump a real Bend front or print `skip: …` when an oracle is missing. Do not invent IGD, HV, or Wilcoxon results.

## v0 module surface (mirror C# names)

| Bend module | Intended C# surface |
|-------------|---------------------|
| `src/individual.bend` | `Individual` — objectives only in v0 |
| `src/non_dominated_sort.bend` | `NonDominatedSort` |
| `src/normalization.bend` | `Normalization` |
| `src/reference_directions.bend` | `ReferenceDirections.DasDennis` |
| `src/survival.bend` | `ReferencePointManager` + `NondominatedSortingSurvival` |

`src/lib.bend` imports the graph. There is no `Unsga3Algorithm` in v0.
