# Roadmap

Living plan for **unsga3-bend**. This is a Bend rewrite, not a NuGet package.

## v0 — core (implemented)

Enough to A/B a front when a population of **objectives** is provided.

- [x] `Individual` (objectives; pass 2 added variables + evaluated + tournament bookkeeping)
- [x] Fast non-dominated sort + Pareto compare (`NonDominatedSort`)
- [x] NSGA-III adaptive hyperplane normalization (`Normalization`: persistent ideal/worst, ASF extremes, intercept nadir + C# fallbacks)
- [x] Das–Dennis reference directions + count (`ReferenceDirections`)
- [x] Niching / reference-point association
- [x] Environmental survival selection (deterministic / C# `rng == null`)
- [x] `LAWS.bend` v0 claims: empty-input / M=1 / `binomial(n,0)` / `das_dennis_count` proven; quantified size laws remain `?TODO`
- [x] Core A/B: Bend dump of a selected front from an objective fixture (`ab/dump_bend_front.py`)

## Pass A/B — core match

- [x] Wire [ab/](../ab/README.md) Bend dump + compare (C# / pymoo still optional)
- [ ] C# Unsga3 and Bend agree on sort / normalize / associate / select for shared fixtures (C# dump runs when `UNSGA3_CS_ROOT` + `dotnet` work; this repo does not clone Unsga3)
- [x] Document remaining intentional deltas (constraint-domination, RNG niching)

**Intentional remaining deltas vs C#:** v0 sort is still Pareto-only (no constraint-domination). Survival is the deterministic `rng == null` branch even inside `Run` (C# `Run` passes rng for random-among-equal-niches). Empty-input / `target==0` / empty dirs stay total so the closed empty laws hold (C# `Select` throws on `targetSize < 1`). Bend RNG is a portable LCG, not `System.Random`.

## Pass 2 — variation, Run, samples

- [x] `Individual` decision variables + evaluated flag (`from_objectives` still feeds sort / normalize / survival)
- [x] Tiny bounds / box surface (variable count + per-var `[lo, hi]`)
- [x] Seeded RNG (`NextDouble` / `Next` / `NextExcept`; portable LCG, not .NET `System.Random`)
- [x] SBX crossover (default η=30, pair probability=1.0)
- [x] Polynomial mutation (default η=20; **probability per variable is passed in** — C# `Run` uses `1/n` when unset)
- [x] Operator smoke: `bend src/op_smoke.bend` on a 2-var unit box, seed 42
- [x] Shared ZDT1 / ZDT2 / DTLZ2 (3-obj, k=10) bounds + Evaluate matching C# `IProblem`
- [x] Mating tournament: `PymooCompatible` (A/B default) + `RankNicheDistance` (C# ctor default)
- [x] `Unsga3Algorithm.Run` generational loop (persistent Normalization, v0 survival)
- [x] Samples: `src/run_smoke.bend` + `ab/dump_bend_run.py` dump a real front under `ab/out/`
- [x] Algorithm A/B scripts: Bend Run dump; optional C# `OracleCompare` when `UNSGA3_CS_ROOT` is set; `igd_vs_pymoo.py` vs analytic / pymoo PF or `skip:`
- [x] Laws for operator defaults (closed) + ZDT/DTLZ dimensions / zero-pop Run (closed) + `|Run|==pop` (`?TODO`)
- [ ] Bit-for-bit / IGD match vs C# + pymoo on oracle-sized ZDT/DTLZ (needs a real C# checkout + pymoo; do not invent numbers)

## Hub publish

- [ ] `bend … --publish` content-hash hub
- [ ] README install line for the published hash
- [ ] Still not NuGet; PackageId `Unsga3` remains the C# package only
