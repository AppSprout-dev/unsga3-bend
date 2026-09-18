# Roadmap

Living plan for **unsga3-bend**. This is a Bend rewrite, not a NuGet package.

## v0 — core (current scaffold)

Enough to A/B a front when a population of **objectives** is provided.

- [ ] `Individual` (objectives only)
- [ ] Fast non-dominated sort + Pareto compare (`NonDominatedSort`)
- [ ] NSGA-III hyperplane normalization (`Normalization`)
- [ ] Das–Dennis reference directions + count (`ReferenceDirections`)
- [ ] Niching / reference-point association
- [ ] Environmental survival selection
- [ ] `LAWS.bend` v0 claims proven in `PROOF.bend` (or remaining `?TODO` closed)
- [ ] Core A/B: same objective population → C# vs Bend ranks / associations / selected set

**Not in v0:** SBX, polynomial mutation, `Unsga3Algorithm.Run`, samples that need variation.

## Pass A/B — core match

- [ ] Wire [ab/](../ab/README.md) dump + compare (still no invented numbers)
- [ ] C# Unsga3 and Bend agree on sort / normalize / associate / select for shared fixtures
- [ ] Document remaining intentional deltas (if any) against C# / pymoo

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
