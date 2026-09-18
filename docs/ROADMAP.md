# Roadmap

Living plan for **unsga3-bend**. This is a Bend rewrite, not a NuGet package.

## v0 — core (implemented)

Enough to A/B a front when a population of **objectives** is provided.

- [x] `Individual` (objectives only)
- [x] Fast non-dominated sort + Pareto compare (`NonDominatedSort`)
- [x] NSGA-III min/max normalization (`Normalization`; ASF intercepts are pass-2)
- [x] Das–Dennis reference directions + count (`ReferenceDirections`)
- [x] Niching / reference-point association
- [x] Environmental survival selection (deterministic / C# `rng == null`)
- [x] `LAWS.bend` v0 claims: empty-input / M=1 / `binomial(n,0)` proven; quantified size laws remain `?TODO`
- [x] Core A/B: Bend dump of a selected front from an objective fixture (`ab/dump_bend_front.py`)

**Not in v0:** SBX, polynomial mutation, `Unsga3Algorithm.Run`, samples that need variation.

## Pass A/B — core match

- [x] Wire [ab/](../ab/README.md) Bend dump + compare (C# / pymoo still optional)
- [ ] C# Unsga3 and Bend agree on sort / normalize / associate / select for shared fixtures (C# dump is optional; this repo does not clone Unsga3)
- [x] Document remaining intentional deltas (ASF intercepts, constraint-domination, RNG niching)

Full-run IGD vs pymoo is **not** required to close this pass; that needs variation.

## Pass 2 — variation, Run, samples

After v0 core matches:

- [ ] SBX crossover
- [ ] Polynomial mutation
- [ ] `Unsga3Algorithm.Run` generational loop
- [ ] Shared ZDT / DTLZ problems
- [ ] Samples that exercise variation
- [ ] Algorithm A/B: dump fronts, IGD vs pymoo, same protocol as C# Unsga3 `docs/EQUIVALENCE.md`
- [ ] Laws for variation / `Run` (not before this pass)

## Hub publish

- [ ] `bend … --publish` content-hash hub
- [ ] README install line for the published hash
- [ ] Still not NuGet; PackageId `Unsga3` remains the C# package only
