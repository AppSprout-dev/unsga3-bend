# Roadmap

Living plan for **unsga3-bend**. This is a Bend rewrite, not a NuGet package. PackageId `Unsga3` stays the C# / NuGet / GitHub Packages stack. This tree is the Bend hub package beside it. Planned first hub version: **0.1.0**.

Public protocol: [EQUIVALENCE.md](EQUIVALENCE.md). How to check the tree: [CONTRIBUTING.md](../CONTRIBUTING.md).

## 0.1.0 scope (planned hub)

Treat as **shipped** for a first hub visitor: v0 core, Pass 2 `Run` + samples, parallel maps, native `-o` dumps, closed `PROOF.bend`, ZDT2 quality protocol gens=250. Open boxes below (C# fixture bit-match, bit-for-bit IGD, hub hash) are remaining work — only the paused `--publish` hash fill is the 0.1.0 publish gate.

## v0 — core (implemented)

Enough to A/B a front when a population of **objectives** is provided.

- [x] `Individual` (objectives; pass 2 added variables + evaluated + tournament bookkeeping)
- [x] Fast non-dominated sort + Pareto compare (`NonDominatedSort`)
- [x] NSGA-III adaptive hyperplane normalization (`Normalization`: persistent ideal/worst, ASF extremes, intercept nadir + C# fallbacks)
- [x] Das–Dennis reference directions + count (`ReferenceDirections`)
- [x] Niching / reference-point association
- [x] Environmental survival selection (deterministic / C# `rng == null`)
- [x] `LAWS.bend` v0 claims: empty-input / M=1 / `binomial(n,0)` / `das_dennis_count` proven; `dominates_irreflexive`, `|Normalize|`, `|associate|` closed; `sort_index_count` (Split partition + fuel peel), `das_dennis_len` (enumerate `range(Count)`), `select_size` (take-pad length lock) closed
- [x] Core A/B: Bend dump of a selected front from an objective fixture (`ab/dump_bend_front.py`)

## Pass A/B — core match

- [x] Wire [ab/](../ab/README.md) Bend dump + compare (C# / pymoo still optional)
- [ ] C# Unsga3 and Bend agree on sort / normalize / associate / select for shared fixtures (C# dump runs when `UNSGA3_CS_ROOT` + `dotnet` work; this repo does not clone Unsga3)
- [x] Document remaining intentional deltas (constraint-domination, LCG RNG)
- [x] `Run` survival niching threads rng (random among equal min-count niches; near-best extras on the ray)
- [x] Duplicate keys use C# G12-style 12-decimal rounding
- [x] DTLZ2 IGD yardstick is Das–Dennis-density PF (not pymoo default ~136-pt sample)

**Intentional remaining deltas vs C#:** v0 sort is still Pareto-only (no constraint-domination). Empty-input / `target==0` / empty dirs stay total so the closed empty laws hold (C# `Select` throws on `targetSize < 1`). Bend RNG is a portable LCG, not `System.Random`. v0 `select` stays the deterministic `rng == null` branch. `Run` randomizes min-count niche ties like C# `Select(..., rng)`. Empty niches take closest; extras are random among near-best on the ray, not uniform `inNiche[rng.Next]` — that LCG path collapsed oracle ZDT2.

## Pass 2 — variation, Run, samples

- [x] `Individual` decision variables + evaluated flag (`from_objectives` still feeds sort / normalize / survival)
- [x] Tiny bounds / box surface (variable count + per-var `[lo, hi]`)
- [x] Seeded RNG (`NextDouble` / `Next` / `NextExcept`; portable LCG, not .NET `System.Random`)
- [x] SBX crossover (default η=30, pair probability=1.0)
- [x] Polynomial mutation (default η=20; **probability per variable is passed in** — C# `Run` uses `1/n` when unset)
- [x] Operator smoke: `bend src/op_smoke.bend` on a 2-var unit box, seed 42
- [x] Shared ZDT1 / ZDT2 / DTLZ2 (3-obj, k=10) bounds + Evaluate matching C# `IProblem`
- [x] Mating tournament: `PymooCompatible` (A/B default) + `RankNicheDistance` (C# ctor default)
- [x] `Unsga3Algorithm.Run` generational loop (persistent Normalization, rng niching)
- [x] Samples: `src/run_smoke.bend` + `ab/dump_bend_run.py` dump a real front under `ab/out/`
- [x] Algorithm A/B scripts: Bend Run dump; optional C# `OracleCompare` when `UNSGA3_CS_ROOT` is set; `igd_vs_pymoo.py` vs analytic / pymoo PF or `skip:`
- [x] ZDT2 A/B / oracle default gens=**250** (PymooCompatible, p=12, pop=52). gens=100 kept as an early-stress snapshot — [ZDT2_COLLAPSE.md](ZDT2_COLLAPSE.md). ZDT1 100 / DTLZ2 150 unchanged. RankNicheDistance stays optional.
- [x] Laws for operator defaults (closed) + ZDT/DTLZ dimensions / zero-pop Run (closed) + `|Run|==pop` (take-pad lock; identity when the inner Run already has `pop_size`) + SBX/poly p=0 copy (bit-zero branch before any `NextDouble`)
- [ ] Bit-for-bit / IGD match vs C# + pymoo on oracle-sized ZDT/DTLZ (needs a real C# checkout + pymoo; do not invent numbers)

## Pass 3 — Bend-shaped speed (in tree)

CPU parallel calls on independent per-individual work. Not a better-IGD bet. No fabricated timings.

- [x] `Prob.evaluate_all` — mid-split, `a b = evaluate_all(lo) evaluate_all(hi)`
- [x] `Surv.associate_raw` — nearest-ref per individual (dirs shared); `with_counts` / `gather` same shape
- [x] `Norm.map_norm` / `gather_objs` — independent given ideal/nadir or the population
- [x] Native `bend … -o` dump path — compile `src/run_smoke.bend` (or a generated driver) to a binary; `ab/dump_bend_run.py --native` prefers it and falls back to `bend file.bend` if the build fails. Same driver source reuses `ab/out/run_cache/<sha256>`; stderr splits `compile_s` from `run_s` (earlier dump wall times included compile)
- [x] Close `dominates_irreflexive`, `normalize_len`, `associate_len` (same-list verdict / mid-split map length)
- [x] Close remaining `PROOF.bend` laws: `sort_index_count`, `das_dennis_len`, `select_size`, `sbx_prob0_child1_vars`, `sbx_prob0_child2_vars`, `poly_prob0_vars`, `run_pop_size`. `bend PROOF.bend` is 0 `?TODO` (one `@unsafe` Das–Dennis index walk)
- [x] Remaining independent Run-path maps — NDS `split_walk` / `first_scan` (inner `is_dominated` stays sequential for OR short-circuit), niche `cand_refs` / `in_ref` / `near_members` / `refs_at` / count histograms, `col_min`/`col_max`/`col_max_idx`/`pick_extremes`, `stamp_asgs`, `g12_vec` / `vars_of`. Same fronts given the same RNG (tournament / SBX / mutation / `niche_loop.rng` stay sequential)

- [x] Warm-cache native phase profile (`ab/profile_bend_run.py`, `docs/PERF_NOTES.md`) — wall `IO.now()` buckets; no fabricated IGD
- [x] NDS peel on pre-materialized `Row{index, objectives}` (no `List.get` of `Individual` during the rank walk). Same Pareto definition; same Split partition law. Mid-split on candidates kept; inner `is_dominated` still sequential OR
- [x] Last-front niching on `NRow{index, ref, dist}` + SBX/PM/G12 list walks (no repeated `List.get` / `set_var_at` on fat Individuals). Same pick rules and RNG order; tournament / `niche_loop.rng` stay sequential

## Hub publish — planned 0.1.0

**0.1.0** is the first planned content-hash hub version. **Paused:** do not run `bend … --publish` or create a `v0.1.0` tag until maintainers fill the README import hash.

- [x] Public docs: not NuGet; PackageId `Unsga3` stays C# / NuGet + GitHub Packages; Bend is the hub package beside it
- [x] Consumer import placeholder (`import 0x…` — hash filled at publish)
- [x] ZDT2 quality protocol gens=250; gens=100 = early stress ([ZDT2_COLLAPSE.md](ZDT2_COLLAPSE.md), [`ab/protocol.py`](../ab/protocol.py))
- [ ] `bend src/lib.bend --publish` (fills the README hash — after this docs review)
- [ ] Still not NuGet; PackageId `Unsga3` remains the C# package only
- [ ] GitHub About description / topics (exact strings in [CHANGELOG.md](../CHANGELOG.md); `gh repo edit` needs org permission)
