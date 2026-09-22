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
- Laws live in `LAWS.bend` (human-owned open claims). Do not silently weaken, delete, or “pass” a law by changing it to match a stub. Schema edits use the schema-change gate below.
- Proofs live in `PROOF.bend`, which must `import ./LAWS.bend`. A law named `foo` is proven by `def Laws.foo`. Use `?TODO` for open proofs. `bend PROOF.bend` is the gate even when proofs are incomplete. Bend+Jev is the compounding architecture bet (proof wall + triage wall); gym spikes in this tree close **Bend-wall** laws only.
- Prefer something that typechecks. If the Bend toolchain is missing, keep valid-looking `.bend` structure and note install in the README.

## Schema-change gate

`LAWS.bend` / `PROOF.bend` are a schema/proof wall, not self-evolving Content. Claims stay human-owned.

A bot pull request that **adds, weakens, deletes, or rewrites** `LAWS.bend` or `PROOF.bend`, or that proposes Jev Choice/Score schema changes used with this stack, must:

- Attribute `level:schema` in the PR title or body.
- Include **paired parent/candidate bench** evidence on the gates already in this tree. Minimum: `bend PROOF.bend` on the parent and on the candidate. Algorithm-facing changes also follow [`ab/protocol.py`](ab/protocol.py) and the [EQUIVALENCE](docs/EQUIVALENCE.md) A/B protocol. When fronts matter, also run [`ab/fixture_check.py`](ab/fixture_check.py) and/or [`ab/oracle_multiseed.py`](ab/oracle_multiseed.py).
- Never invent IGD, HV, or Wilcoxon numbers. Never weaken a law so the claim matches a stub.

Hard refuse:

- Content evolution of `LAWS.bend` / `PROOF.bend`.
- Vendor ontology plugins writing laws into this tree.

How to run the gates: [CONTRIBUTING.md](CONTRIBUTING.md).

## Product locks (do not invent past this)

- **Name:** `unsga3-bend`. Greenfield Bend rewrite of U-NSGA-III.
- **Reference:** existing C# library [AppSprout-dev/Unsga3](https://github.com/AppSprout-dev/Unsga3). Read it via `gh` / GitHub API only; do **not** clone it into this repo.
- **PackageId `Unsga3` stays C# / NuGet / GitHub Packages only.** This tree is not a NuGet package. Hub version **0.1.0** is published (`bend src/lib.bend --publish`, content hash `0xcd07e24a626a62e74603d48f436cd679`), not nuget.org / GitHub Packages.
- **Not a drop-in** for C# consumers. Shared plan is A/B of fronts and ZDT/DTLZ + IGD vs a pymoo oracle using the same protocol as the C# Unsga3 docs.
- **v0 core (done):** non-dominated sort, normalization, Das–Dennis reference directions, niching / reference-point association, survival selection.
- **Pass 2 (in tree):** `Individual` variables, SBX, polynomial mutation, ZDT1 / ZDT2 / DTLZ2 (3-obj), PymooCompatible mating tournament, `Unsga3Algorithm.Run`, smoke + algorithm A/B scripts.
- **Parallel hot loops (landed):** `evaluate_all`, association (`associate_raw` / `with_counts` / `gather`), `map_norm` / `gather_objs`, NDS `split_walk`, niche filters / histograms, `col_min`/`col_max`/`pick_extremes`, and `stamp_asgs` use balanced `a b = f(lo) f(hi)` mid-splits. Inner `is_dominated` and nearest-ref stay sequential (short-circuit / already parallel per individual). Tournament / SBX / mutation / last-front niching stay sequential so the same seed yields the same fronts.
- **NDS row peel (landed):** `sort` materializes `Row{index, objectives}` once and peels those rows (no `List.get` of `Individual` on the pair walk). Same dominance definition; seed=1 smoke and oracle fronts match main @ a6ebf2d.
- **Niching / offspring walks (landed):** last-front fill uses `NRow{index, ref, dist}`; SBX / polynomial mutation / G12 walk variable lists (no per-index `List.get` / `set_var_at`). Same RNG order so seed=1 fronts stay byte-identical. Tournament / last-front pick order stay sequential.
- **Native `-o` dump path (in tree):** `bend src/run_smoke.bend -o …` (or a generated driver) then run the binary; `ab/dump_bend_run.py --native` prefers that path and falls back to `bend file.bend` if the build fails. `bend PROOF.bend` is 0 `?TODO`.
- **Hub 0.1.0:** first content-hash package. Consumers `import 0xcd07e24a626a62e74603d48f436cd679/lib.bend as Unsga3`. `bend --publish` printed `import 0xcd07e24a626a62e74603d48f436cd679/lib.bend as Lib`. Checkout development still uses `import ./src/lib.bend as Unsga3`. GitHub tree **0.1.1** is docs/ab confidence only (multi-seed IGD + fixture check); do not hub-publish — the hash stays `0xcd07e24a626a62e74603d48f436cd679`.
- **Standalone OSS:** no mentions of private product repos or internal application names. Consumers wire their own Unsga3 usage; this repo does not know about them.
- **No fabricated benchmark numbers.** A/B scripts dump a real Bend front or print `skip: …` when an oracle is missing. Do not invent IGD, HV, or Wilcoxon results.
- **ZDT2 A/B / oracle default:** gens=**250**, still `PymooCompatible`, p=12, pop=52 (`ab/protocol.py`). gens=100 is an early-stress snapshot (PR #16 Bend 10/15, C# 8/15 collapse; 15-seed gens=250 is 0/15 — [docs/ZDT2_COLLAPSE.md](docs/ZDT2_COLLAPSE.md)). ZDT1 stays 100; DTLZ2 stays 150. RankNicheDistance is `--tournament rank_niche`, not the new default.

## Module surface (mirror C# names)

| Bend module | Intended C# surface |
|-------------|---------------------|
| `src/individual.bend` | `Individual` — objectives + decision variables + evaluated + tournament bookkeeping |
| `src/non_dominated_sort.bend` | `NonDominatedSort` |
| `src/normalization.bend` | `Normalization` (persistent across `Run`) |
| `src/reference_directions.bend` | `ReferenceDirections.DasDennis` |
| `src/survival.bend` | `ReferencePointManager` + `NondominatedSortingSurvival` |
| `src/bounds.bend` | `IProblem` box `[lo, hi]` |
| `src/problems.bend` | `Zdt1Problem` / `Zdt2Problem` / `Dtlz2Problem` |
| `src/rng.bend` | `RandomProvider` (LCG; not `System.Random`) |
| `src/sbx.bend` | `SimulatedBinaryCrossover` (η=30, probability=1.0) |
| `src/polynomial_mutation.bend` | `PolynomialMutation` (η=20; per-variable p at call site, typically 1/n) |
| `src/tournament.bend` | `TournamentSelection` / `TournamentMode` |
| `src/algorithm.bend` | `Unsga3Algorithm.Run` |

`src/lib.bend` imports the graph. `src/run_smoke.bend` is the checked-in short ZDT1 Run driver.

How to check the tree: [CONTRIBUTING.md](CONTRIBUTING.md). Public protocol: [docs/EQUIVALENCE.md](docs/EQUIVALENCE.md).
