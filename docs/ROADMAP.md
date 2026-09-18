# Roadmap

Living plan for **unsga3-bend**. This is a Bend rewrite, not a NuGet package.

## v0 — core (implemented)

Enough to A/B a front when a population of **objectives** is provided.

- [x] `Individual` (objectives; pass 2 added variables + evaluated)
- [x] Fast non-dominated sort + Pareto compare (`NonDominatedSort`)
- [x] NSGA-III adaptive hyperplane normalization (`Normalization`: persistent ideal/worst, ASF extremes, intercept nadir + C# fallbacks)
- [x] Das–Dennis reference directions + count (`ReferenceDirections`)
- [x] Niching / reference-point association
- [x] Environmental survival selection (deterministic / C# `rng == null`)
- [x] `LAWS.bend` v0 claims: empty-input / M=1 / `binomial(n,0)` / `das_dennis_count` proven; quantified size laws remain `?TODO`
- [x] Core A/B: Bend dump of a selected front from an objective fixture (`ab/dump_bend_front.py`)

**Not in v0:** `Unsga3Algorithm.Run`, ZDT/DTLZ, samples that need a generational loop.

## Pass A/B — core match

- [x] Wire [ab/](../ab/README.md) Bend dump + compare (C# / pymoo still optional)
- [ ] C# Unsga3 and Bend agree on sort / normalize / associate / select for shared fixtures (C# dump runs when `UNSGA3_CS_ROOT` + `dotnet` work; this repo does not clone Unsga3)
- [x] Document remaining intentional deltas (constraint-domination, RNG niching)

Full-run IGD vs pymoo is **not** required to close this pass; that needs `Run`.

**Intentional remaining deltas vs C#:** v0 sort is still Pareto-only (no constraint-domination). Survival is the deterministic `rng == null` branch; pymoo-style random niching is later. Empty-input / `target==0` / empty dirs stay total so the closed empty laws hold (C# `Select` throws on `targetSize < 1`).

## Pass 2 — variation, Run, samples

Jason unlocked pass 2. **First slice (this tree):** decision variables on `Individual`, SBX, polynomial mutation, tiny box bounds, injectable RNG. Not `Run`, not ZDT/DTLZ, not algorithm A/B.

- [x] `Individual` decision variables + evaluated flag (`from_objectives` still feeds sort / normalize / survival)
- [x] Tiny bounds / box surface (variable count + per-var `[lo, hi]`; not ZDT/DTLZ)
- [x] Seeded RNG (`NextDouble`; portable LCG, not .NET `System.Random`)
- [x] SBX crossover (default η=30, pair probability=1.0)
- [x] Polynomial mutation (default η=20; **probability per variable is passed in** — C# `Run` uses `1/n` when unset)
- [x] Operator smoke: `bend src/op_smoke.bend` on a 2-var unit box, seed 42, prints child variables
- [x] Laws for operator defaults + concrete probability-0 copy smokes
- [ ] `Unsga3Algorithm.Run` generational loop
- [ ] Shared ZDT / DTLZ problem definitions
- [ ] Samples that exercise variation
- [ ] Algorithm A/B: dump fronts, IGD vs pymoo, same protocol as C# Unsga3 `docs/EQUIVALENCE.md`
- [ ] Laws for `Run` / ZDT (not in this slice)

## Hub publish

- [ ] `bend … --publish` content-hash hub
- [ ] README install line for the published hash
- [ ] Still not NuGet; PackageId `Unsga3` remains the C# package only
