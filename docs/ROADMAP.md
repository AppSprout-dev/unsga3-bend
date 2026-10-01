# Roadmap

Living plan for **unsga3-bend**. This is a Bend rewrite, not a NuGet package. PackageId `Unsga3` stays the C# / NuGet / GitHub Packages stack. This tree is the Bend hub package beside it. Current hub version: **0.2.1** (content hash `0x2bc7fb472c80bd6a0e04725c117edb2a`). Previous hub version: **0.2.0** (`0xa2f9d6ef8c474468bf1de15ebe70c512`). Earlier hub versions: **0.1.2** (`0x527a2a4fa91b05a0250d7be0e11d232a`), **0.1.0** (`0xcd07e24a626a62e74603d48f436cd679`).

Public protocol: [EQUIVALENCE.md](EQUIVALENCE.md). How to check the tree: [CONTRIBUTING.md](../CONTRIBUTING.md).

## 0.1.0 scope (hub)

Treat as **shipped** for a first hub visitor: v0 core, Pass 2 `Run` + samples, parallel maps, native `-o` dumps, closed `PROOF.bend`, ZDT2 quality protocol gens=250. GitHub **0.1.1** adds measured 15-seed IGD + Layer-1 fixture pass ([ORACLE-MULTISEED.md](ORACLE-MULTISEED.md)) and did not change the 0.1.0 hub hash. **0.1.2** re-published the hub (`import 0x527a2a4fa91b05a0250d7be0e11d232a/lib.bend as Unsga3`) and includes the RankNicheDistance fix. **0.2.0** re-published again (`import 0xa2f9d6ef8c474468bf1de15ebe70c512/lib.bend as Unsga3`) and adds the unconstrained catalog, Deb constraint-domination, the offspring duplicate contract, and the odd-N SBX fix. **0.2.1** re-published again (`import 0x2bc7fb472c80bd6a0e04725c117edb2a/lib.bend as Unsga3`) after the DTLZ3 axis clamp, OSY / TNK / C1-DTLZ1, and the CV-fill overflow fix. A/B stays `PymooCompatible`.

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
- [x] C# Unsga3 and Bend agree on sort / normalize / associate / select for shared fixtures (`ab/fixture_check.py`: `core_2obj.json` `row_set_equal=True` when `UNSGA3_CS_ROOT` + `dotnet` work; this repo does not clone Unsga3). Results: [ORACLE-MULTISEED.md](ORACLE-MULTISEED.md)
- [x] Document remaining intentional deltas (LCG RNG, equal-CV vs published C# Pareto fall-through, 12-dp keys, near-best last front)
- [x] `Run` survival niching threads rng (random among equal min-count niches; near-best extras on the ray)
- [x] Duplicate keys round decision variables to 12 decimal places (`round(x*1e12)/1e12`). Not C# `ToString("G12")` significant digits; `1.234567e-8` diverges (`src/g12_key.bend`)
- [x] DTLZ2 IGD yardstick is Das–Dennis-density PF (not pymoo default ~136-pt sample)

**Intentional remaining deltas vs C#:** equal infeasible `cv` is mutual non-domination (Deb). Published C# `CompareConstraintDominated` still Pareto-compares that tie. Unequal-length objectives are mutual non-domination (C# `ComparePareto` throws; [`src/nds_unequal.bend`](../src/nds_unequal.bend)). Empty-input / `target==0` / empty dirs stay total so the closed empty laws hold (C# `Select` throws on `targetSize < 1`). Bend RNG is a portable LCG, not `System.Random`. v0 `select` stays the deterministic `rng == null` branch. `Run` randomizes min-count niche ties like C# `Select(..., rng)`. Empty niches take closest; extras are random among near-best on the ray, not uniform `inNiche[rng.Next]` — that LCG path collapsed oracle ZDT2. Duplicate keys stay 12 decimal places, not `ToString("G12")`. A mixed pool niches only the feasible subset and fills by ascending CV; the hyperplane uses that feasible subset. An all-feasible pool stays on the previous path. OSY / TNK / C1-DTLZ1 are in `src/problems.bend` and in the 0.2.1 hub hash (`0x2bc7fb472c80bd6a0e04725c117edb2a`). The 0.2.0 hash (`0xa2f9d6ef8c474468bf1de15ebe70c512`) does not include them.

## Pass 2 — variation, Run, samples

- [x] `Individual` decision variables + evaluated flag (`from_objectives` still feeds sort / normalize / survival)
- [x] Tiny bounds / box surface (variable count + per-var `[lo, hi]`)
- [x] Seeded RNG (`NextDouble` / `Next` / `NextExcept`; portable LCG, not .NET `System.Random`)
- [x] SBX crossover (default η=30, pair probability=1.0)
- [x] Polynomial mutation (default η=20; **probability per variable is passed in** — C# `Run` uses `1/n` when unset)
- [x] Operator smoke: `bend src/op_smoke.bend` on a 2-var unit box, seed 42
- [x] Shared ZDT1 / ZDT2 / DTLZ2 (3-obj, k=10) bounds + Evaluate matching C# `IProblem`
- [x] Mating tournament: `PymooCompatible` (A/B default) + `RankNicheDistance` (C# ctor default). Both modes take `cv` first. A/B stays `PymooCompatible`
- [x] Constraint-domination in `NDS.sort` (Deb: equal infeasible `cv` does not Pareto-compare). `cv` on `Individual` is the sum of positive `g`. Zero constraints keep the Pareto path ([`src/cd_contract.bend`](../src/cd_contract.bend))
- [x] Offspring duplicate contract: seen set is the survivor population; after `pop·40` pair attempts, `max(pop·20, 1)` mutations must be a new 12-dp key, then duplicates are accepted. Odd N pairs parent `N-1` with parent `0`. Even-N pair lookups are unchanged
- [x] `Unsga3Algorithm.Run` generational loop (persistent Normalization, rng niching)
- [x] Samples: `src/run_smoke.bend` + `ab/dump_bend_run.py` dump a real front under `ab/out/`
- [x] Algorithm A/B scripts: Bend Run dump; optional C# `OracleCompare` when `UNSGA3_CS_ROOT` is set; `igd_vs_pymoo.py` vs analytic / pymoo PF or `skip:`
- [x] ZDT2 A/B / oracle default gens=**250** (PymooCompatible, p=12, pop=52). gens=100 kept as an early-stress snapshot — [ZDT2_COLLAPSE.md](ZDT2_COLLAPSE.md). ZDT1 100 / DTLZ2 150 unchanged. RankNicheDistance stays optional.
- [x] Laws for operator defaults (closed) + ZDT/DTLZ dimensions / zero-pop Run (closed) + `|Run|==pop` (take-pad lock; identity when the inner Run already has `pop_size`) + SBX/poly p=0 copy (bit-zero branch before any `NextDouble`)
- [x] Multi-seed IGD vs C# + pymoo NSGA-III on oracle-sized ZDT/DTLZ (`ab/oracle_multiseed.py`; seeds 1–15, same knobs, same `igd_vs_pymoo.py` yardstick). Run fronts are not bit-identical (LCG ≠ `System.Random` — intentional). Tables: [ORACLE-MULTISEED.md](ORACLE-MULTISEED.md)

## Pass 3 — Bend-shaped speed (in tree)

CPU parallel calls on independent per-individual work. Not a better-IGD bet. No fabricated timings.

- [x] `Prob.evaluate_all` — mid-split, `a b = evaluate_all(lo) evaluate_all(hi)`
- [x] `Surv.associate_raw` — nearest-ref per individual (dirs shared); `with_counts` / `gather` same shape
- [x] `Norm.map_norm` / `gather_objs` — independent given ideal/nadir or the population
- [x] Native `bend … -o` dump path — compile `src/run_smoke.bend` (or a generated driver) to a binary; `ab/dump_bend_run.py --native` prefers it and falls back to `bend file.bend` if the build fails. Same driver source reuses `ab/out/run_cache/<sha256>`; stderr splits `compile_s` from `run_s` (earlier dump wall times included compile)
- [x] Close `dominates_irreflexive`, `normalize_len`, `associate_len` (same-list verdict / mid-split map length)
- [x] Close remaining `PROOF.bend` laws: `sort_index_count`, `das_dennis_len`, `select_size`, `sbx_prob0_child1_vars`, `sbx_prob0_child2_vars`, `poly_prob0_vars`, `run_pop_size`. `bend PROOF.bend` is 0 `?TODO`. Das–Dennis length proofs are `@unsafe` (`comps_all_len`, `das_ge2_len`, `das_dennis_m1_len`, `das_dennis_len`) because `nth_comp.go` is `@unsafe`. The wall is lengths, literals, irreflexivity, and p=0 copies — not simplex membership, front identity, or SBX/PM/ASF algebra.
- [x] Close `niche_count_sum`: mid-split `count_raw.go` histogram conservation (sum of bins = in-range assignment count). Bend-wall only — Bend+Jev is the compounding architecture bet; this spike does not touch Jev / TypeSafe.
- [x] Remaining independent Run-path maps — NDS `split_walk` / `first_scan` (inner `is_dominated` stays sequential for OR short-circuit), niche `cand_refs` / `in_ref` / `near_members` / `refs_at` / count histograms, `col_min`/`col_max`/`col_max_idx`/`pick_extremes`, `stamp_asgs`, `g12_vec` / `vars_of`. Same fronts given the same RNG (tournament / SBX / mutation / `niche_loop.rng` stay sequential)

- [x] Warm-cache native phase profile (`ab/profile_bend_run.py`, `docs/PERF_NOTES.md`) — wall `IO.now()` buckets; no fabricated IGD
- [x] NDS peel on pre-materialized `Row{index, objectives}` (no `List.get` of `Individual` during the rank walk). Same Pareto definition; same Split partition law. Mid-split on candidates kept; inner `is_dominated` still sequential OR
- [x] Last-front niching on `NRow{index, ref, dist}` + SBX/PM/G12 list walks (no repeated `List.get` / `set_var_at` on fat Individuals). Same pick rules and RNG order; tournament / `niche_loop.rng` stay sequential

## Hub publish — 0.1.0

**0.1.0** is the first content-hash hub version. Publish already ran: `bend src/lib.bend --publish`.

- Content hash: `0xcd07e24a626a62e74603d48f436cd679`
- Printed import: `import 0xcd07e24a626a62e74603d48f436cd679/lib.bend as Lib`
- Consumer import: `import 0xcd07e24a626a62e74603d48f436cd679/lib.bend as Unsga3`

Hub entry is `/lib.bend` (what bend printed), not `/src/lib.bend`.

- [x] Public docs: not NuGet; PackageId `Unsga3` stays C# / NuGet + GitHub Packages; Bend is the hub package beside it
- [x] Consumer import (`import 0xcd07e24a626a62e74603d48f436cd679/lib.bend as Unsga3`)
- [x] ZDT2 quality protocol gens=250; gens=100 = early stress ([ZDT2_COLLAPSE.md](ZDT2_COLLAPSE.md), [`ab/protocol.py`](../ab/protocol.py))
- [x] `bend src/lib.bend --publish` (content hash `0xcd07e24a626a62e74603d48f436cd679`)
- [x] Still not NuGet; PackageId `Unsga3` remains the C# package only
- [ ] GitHub About description / topics (exact strings in [CHANGELOG.md](../CHANGELOG.md); `gh repo edit` needs org permission)

## Hub publish — 0.1.2

**0.1.2** re-published the hub: `bend src/lib.bend --publish` (Bend 2.0.25). GitHub 0.1.2 includes the RankNicheDistance fix (rank, then niche count, then perpendicular distance, then a coin). A/B stays `PymooCompatible`.

- Content hash: `0x527a2a4fa91b05a0250d7be0e11d232a`
- Printed import: `import 0x527a2a4fa91b05a0250d7be0e11d232a/lib.bend as Lib`
- Consumer import: `import 0x527a2a4fa91b05a0250d7be0e11d232a/lib.bend as Unsga3`
- Previous hub hash (0.1.0 through GitHub 0.1.1): `0xcd07e24a626a62e74603d48f436cd679`

Hub entry is `/lib.bend` (what bend printed), not `/src/lib.bend`.

- [x] `bend src/lib.bend --publish` (content hash `0x527a2a4fa91b05a0250d7be0e11d232a`)
- [x] Consumer import (`import 0x527a2a4fa91b05a0250d7be0e11d232a/lib.bend as Unsga3`)

## Hub publish — 0.2.0

**0.2.0** re-published the hub: `bend src/lib.bend --publish` (Bend 2.0.34). GitHub 0.2.0 adds the unconstrained problem catalog (#26), Deb constraint-domination, the offspring duplicate contract, and the odd-N SBX fix (#27). A/B stays `PymooCompatible`. No new IGD / HV / Wilcoxon cells.

- Content hash: `0xa2f9d6ef8c474468bf1de15ebe70c512`
- Printed import: `import 0xa2f9d6ef8c474468bf1de15ebe70c512/lib.bend as Lib`
- Consumer import: `import 0xa2f9d6ef8c474468bf1de15ebe70c512/lib.bend as Unsga3`
- Previous hub hash (0.1.2): `0x527a2a4fa91b05a0250d7be0e11d232a`

Hub entry is `/lib.bend` (what bend printed), not `/src/lib.bend`.

`unified-nsga-iii@0.1.2.0` still names the 0.1.2 hash. `unified-nsga-iii@0.2.0.0` resolves to `0xa2f9d6ef8c474468bf1de15ebe70c512` (`import unified-nsga-iii@0.2.0.0/lib.bend` pulls that hash). Git tag `v0.2.0` and the GitHub Release already exist (2026-09-30).

- [x] `bend src/lib.bend --publish` (content hash `0xa2f9d6ef8c474468bf1de15ebe70c512`)
- [x] Consumer import (`import 0xa2f9d6ef8c474468bf1de15ebe70c512/lib.bend as Unsga3`)
- [x] `bend link unified-nsga-iii@0.2.0.0 0xa2f9d6ef8c474468bf1de15ebe70c512` (name resolves to that hash)
- [x] Git tag `v0.2.0` and GitHub Release (https://github.com/AppSprout-dev/unsga3-bend/releases/tag/v0.2.0)

## Hub publish — 0.2.1

**0.2.1** re-published the hub: `bend src/lib.bend --publish` (Bend 2.0.34). GitHub 0.2.1 adds the DTLZ3 axis clamp (#30), constrained demos and GD+ (#31), and the CV-fill overflow fix with the measured IGD already on main (#32). The content hash changed. `src/lib.bend` does not re-export new symbols; the published package is the import closure, which includes those edits. A/B stays `PymooCompatible`. Not nuget.org. Not GitHub Packages.

- Content hash: `0x2bc7fb472c80bd6a0e04725c117edb2a`
- Printed import: `import 0x2bc7fb472c80bd6a0e04725c117edb2a/lib.bend as Lib`
- Consumer import: `import 0x2bc7fb472c80bd6a0e04725c117edb2a/lib.bend as Unsga3`
- Previous hub hash (0.2.0): `0xa2f9d6ef8c474468bf1de15ebe70c512`

Hub entry is `/lib.bend` (what bend printed), not `/src/lib.bend`.

`unified-nsga-iii@0.2.0.0` still names the 0.2.0 hash. After merge, `bend link unified-nsga-iii@0.2.1.0 0x2bc7fb472c80bd6a0e04725c117edb2a`. Git tag `v0.2.1` and the GitHub Release are cut after merge.

- [x] `bend src/lib.bend --publish` (content hash `0x2bc7fb472c80bd6a0e04725c117edb2a`)
- [x] Consumer import (`import 0x2bc7fb472c80bd6a0e04725c117edb2a/lib.bend as Unsga3`)
- [ ] `bend link unified-nsga-iii@0.2.1.0 0x2bc7fb472c80bd6a0e04725c117edb2a` (after merge)
- [ ] Git tag `v0.2.1` and GitHub Release (after merge)

## 0.2.x Bend speed (patch lane)

Not C# / feature 0.3. One branch, logical commits, one PR after measured verification and Jason's go.

**Contract:** same RNG order / same fronts (byte-identical seed=1 oracle dumps when claiming the same ops). No invented IGD. Warm-native `ab/profile_bend_run.py` yardstick (`run_s` + phase ms). When parallelism is claimed, also `--threads 1` vs omit / N. GPU claims need `--gpu off` vs bang on the same kernel.

- [x] **Phase A** — CPU baseline, no algorithm change. Re-measure tip 0.2.1 ZDT1 52×100 and DTLZ2 92×150 seed=1 warm, `--threads 1` and default. Frozen into [PERF_NOTES.md](PERF_NOTES.md) as the 0.2.x before line.
- [x] **Phase B — niche** — DTLZ2 last-front fill groups `NRow`s into per-ref bags (counts on the bag; re-sort by the earliest remaining row so min-count ref order stays first-seen). Pick rules unchanged. Seed=1 fronts byte-identical. `--threads 1` warm: DTLZ2 niche 2001 ms → 602 ms, `run_s` 5.492 → 4.119. ZDT1 niche was already 33 ms (23 ms after). [PERF_NOTES.md](PERF_NOTES.md).
- [x] **Phase B — associate** — `perp.big` squares `f - t*w` in one walk (same F32 order as `vec_scale` then `vec_sub`). Take/drop stays: `assoc_raw_len` / `niche_count_sum` unfold that shape. Seed=1 fronts byte-identical. `--threads 1` warm: DTLZ2 associate 1702 ms → 1334 ms, `run_s` 4.119 → 3.783. ZDT1 associate 95 → 80 ms. [PERF_NOTES.md](PERF_NOTES.md).
- [ ] **Phase B — offspring** — ZDT1 SBX/PM/G12 list-walk only if it removes work without an RNG reorder. Smoke + seed=1 front match. Before/after table.
- [ ] **Phase C** — Array host-rebuild spike on the sequential host between generations. Lists keep the forks. Discard if fronts drift or the wall is flat.
- [ ] **Phase D** — GPU uniform-kernel dig (associate distances, col min/max, Das–Dennis, heavier `evaluate_all`). Bang only that kernel. NDS / niche / tournament stay CPU. Bench CPU `--threads 1 --gpu off` vs bang. Ship only if the wall drops. Document misses honestly.

## Problem catalog (implemented, not oracle-tabled)

The unconstrained C# suite beside ZDT1 / ZDT2 / DTLZ2. Formulas live in [`src/problems.bend`](../src/problems.bend). These names can be dumped. They are **not** rows of the ZDT1 / ZDT2 / DTLZ2 quality protocol ([EQUIVALENCE.md](EQUIVALENCE.md), [`ab/protocol.py`](../ab/protocol.py)). No IGD / HV / Wilcoxon numbers are recorded here.

- [x] ZDT3, ZDT4, ZDT6 (bounds + Evaluate)
- [x] DTLZ1 (k=5), DTLZ3, DTLZ4 (α=100), DTLZ7 (k=20)
- [x] Sphere, Ackley, Rosenbrock (M=1; `Run` still accepts pop ≥ 1, including the existing zero-pop law)
- [x] `ab/dump_bend_run.py --problem` writes a real front. Omitted knobs for these names are a short smoke (partitions=4, pop=8, gens=3), not oracle gens
- [x] Smoke: `bend src/catalog_smoke.bend` (evaluate at 0.5, short Run). Checker: `python3 ab/test_catalog_smoke.py`
- [x] Measured IGD table for the catalog ([ORACLE-CATALOG.md](ORACLE-CATALOG.md), `ab/oracle_catalog.py`, seeds 1–15). pymoo Sphere is `skip:` (different box). The constrained rows in that file are the 2026-09-30 skips. Later cells are in [CONSTRAINED-SURFACES.md](CONSTRAINED-SURFACES.md). No HV / Wilcoxon.
- [x] OSY, TNK, and C1-DTLZ1 (C# formulas, bounds, constraints). Feasible-only niching plus CV fill. Smoke: `bend src/constrained_smoke.bend -o`. In the 0.2.1 hub hash (`src/lib.bend` does not re-export new symbols; the import closure does).
- [x] GD+ in [`ab/indicators.py`](../ab/indicators.py) (C# `GenerationalDistancePlus`). Hand case in `ab/test_gd_plus.py`. Bend has no indicator module; A/B IGD stays on the Python path.
