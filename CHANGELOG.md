# Changelog

Notable changes to **unsga3-bend**.

This file tracks the Bend **hub** package (content-hash) and GitHub tree versions. It is **not** the C# / NuGet changelog for PackageId `Unsga3` ([AppSprout-dev/Unsga3](https://github.com/AppSprout-dev/Unsga3)).

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Current hub package is **0.2.2** (content hash `0xd1de66b5d9157913a654c39186289f3d`). The first hub version was **0.1.0** (`0xcd07e24a626a62e74603d48f436cd679`). Git tags `v0.1.0` through `v0.2.1` and their GitHub Releases already exist. Tag `v0.2.2`, `bend link unified-nsga-iii@0.2.2.0 0xd1de66b5d9157913a654c39186289f3d`, and the GitHub Release follow this commit once it is main's tip. `unified-nsga-iii@0.2.0.0` still resolves to `0xa2f9d6ef8c474468bf1de15ebe70c512`.

GitHub tree **0.1.1** was a docs/ab confidence bump only. That tag did not hub-publish; its content hash stayed `0xcd07e24a626a62e74603d48f436cd679`.

## [Unreleased]

## [0.2.2] - 2026-10-01

Hub re-publish of the speed dig already on main (#34). That dig landed before its version bump; this section is the cleanup cut. `bend src/lib.bend --publish` (Bend 2.0.34) printed the hash below. The hash changed because `survival.bend` is in the import closure. `src/lib.bend` does not re-export new symbols. Not nuget.org. Not GitHub Packages. Seed=1 fronts for the kept CPU edits match the 0.2.1 line. No new IGD / HV / Wilcoxon cells. A/B stays `PymooCompatible`.

A shipping PR's last commit carries the version bump, this section, and the published hash. Merge that once. Then `bend link`, the git tag, and the GitHub Release.

- Previous hub hash (0.2.1): `0x2bc7fb472c80bd6a0e04725c117edb2a`
- Content hash: `0xd1de66b5d9157913a654c39186289f3d`
- Printed import: `import 0xd1de66b5d9157913a654c39186289f3d/lib.bend as Lib`
- Consumer import: `import 0xd1de66b5d9157913a654c39186289f3d/lib.bend as Unsga3`

Hub entry is `/lib.bend` (what bend printed), not `/src/lib.bend`.

`unified-nsga-iii@0.2.0.0` still resolves to `0xa2f9d6ef8c474468bf1de15ebe70c512`. Once this commit is main's tip: `bend link unified-nsga-iii@0.2.2.0 0xd1de66b5d9157913a654c39186289f3d`.

### Changed

- Last-front niching groups `NRow`s into per-ref bags (counts on the bag; re-sort by the earliest remaining row). Pick rules and RNG order are unchanged ([`src/survival.bend`](src/survival.bend)).
- Associate perpendicular distance squares `f - t*w` in one walk, the same F32 order as scale-then-subtract. Population take/drop is unchanged.

### Performance

- Warm `--threads 1` on the 0.2.x Xeon before line (Bend 2.0.34), kept Phase B only. DTLZ2 92×150: niche 2001 ms → 615 ms, associate 1692 ms → 1334 ms, `run_s` 5.492 → 3.783. ZDT1 52×100: associate 92 ms → 80 ms, `run_s` 0.761 → 0.738. Offspring peek and the direction-Array spike were measured and discarded. Tables: [docs/PERF_NOTES.md](docs/PERF_NOTES.md).

### Docs

- Phase D Metal (Mac mini M4, bend 2.0.34) is a measured miss for default `Run` at oracle sizes. No `!` on that path. Break-even and the go-big capability notes are in [docs/PERF_NOTES.md](docs/PERF_NOTES.md).
- Big-N Metal is Bend 0.3 in [docs/ROADMAP.md](docs/ROADMAP.md) (unchecked, not C# Unsga3 feature 0.3). HIP / bendlang#979 stays parked.

## [0.2.1] - 2026-10-01

Tree cut after the DTLZ3 axis clamp (#30), constrained demos and GD+ (#31), and the CV-fill overflow fix with measured IGD (#32). `bend src/lib.bend --publish` (Bend 2.0.34) ran for this cut. The printed content hash **changed**. `src/lib.bend` does not re-export new symbols; the hash is the import closure, and that closure includes the edits in `problems.bend`, `survival.bend`, `algorithm.bend`, `individual.bend`, `normalization.bend`, and `tournament.bend` since `v0.2.0`. Not nuget.org. Not GitHub Packages. Git tag `v0.2.1` and the GitHub Release exist: https://github.com/AppSprout-dev/unsga3-bend/releases/tag/v0.2.1.

- Previous hub hash (0.2.0): `0xa2f9d6ef8c474468bf1de15ebe70c512`
- Content hash: `0x2bc7fb472c80bd6a0e04725c117edb2a`
- Printed import: `import 0x2bc7fb472c80bd6a0e04725c117edb2a/lib.bend as Lib`
- Consumer import: `import 0x2bc7fb472c80bd6a0e04725c117edb2a/lib.bend as Unsga3`

Hub entry is `/lib.bend` (what bend printed), not `/src/lib.bend`. A/B stays `PymooCompatible`. This cut does not recompute the measured IGD tables already on main.

`unified-nsga-iii@0.2.0.0` still resolves to `0xa2f9d6ef8c474468bf1de15ebe70c512`. After merge: `bend link unified-nsga-iii@0.2.1.0 0x2bc7fb472c80bd6a0e04725c117edb2a`.

### Fixed

- Constrained CV fill no longer builds an exponential infeasible list. Inserting a row in front used to recurse through a tail that already contained that row, then cons it again. Each smaller CV doubled the list. Native OSY and C1-DTLZ1 at `constrained_knobs` died with `bend: memory fault (machine stack overflow?)`. TNK died with `bend: runtime fail-stop`. The insert conses onto the original tail. Regression: [`src/constrained_budget.bend`](src/constrained_budget.bend) (OSY/TNK pop=52 gens=250, C1-DTLZ1 pop=92 gens=150, seed 1, `PymooCompatible`). Seeds 1–15 IGD: [docs/CONSTRAINED-SURFACES.md](docs/CONSTRAINED-SURFACES.md).
- DTLZ3 evaluation clamps a negative F32 `cos(π/2)` factor back to the mathematical `f ≥ 0`. In-bound `x = 1` was a strictly negative objective, so no feasible point could dominate it, and that row pinned a huge ASF extreme. Same DTLZ2 budget, seeds 1–15: Bend median IGD 26.249240 → 8.239578 ([docs/DTLZ3_AXIS.md](docs/DTLZ3_AXIS.md)). DTLZ2 / ZDT1 / ZDT2 seed 1 published cells unchanged.

### Added

- Catalog IGD driver [`ab/oracle_catalog.py`](ab/oracle_catalog.py). ZDT3 / ZDT4 / ZDT6 use the ZDT1 budget (p=12, pop=52, gens=100). DTLZ1 / DTLZ3 / DTLZ4 / DTLZ7 use the DTLZ2 budget (p=12, pop=92, gens=150). Sphere / Ackley / Rosenbrock are a short smoke (p=1, pop=20, gens=40) at library-default `n`. Tournament stays `PymooCompatible`. Every cell is a real `igd=` or `skip:`.
- Pareto sets for those names in [`ab/igd_vs_pymoo.py`](ab/igd_vs_pymoo.py): C# `ParetoFronts` for ZDT3, ZDT4, ZDT6, DTLZ1, and the DTLZ2 sphere shared by DTLZ3 / DTLZ4. DTLZ7 uses pymoo `pareto_front()` or `skip:` (C# has no DTLZ7 front). Single-objective IGD is distance to `f = 0`.
- Optional C# catalog dump [`ab/dump_csharp_catalog.py`](ab/dump_csharp_catalog.py). `tools/OracleCompare` still accepts only zdt1, zdt2, and dtlz2. pymoo NSGA-III dump accepts catalog names and skips when the box is not the Bend/C# box.
- Catalog results in [docs/ORACLE-CATALOG.md](docs/ORACLE-CATALOG.md), copied from the 2026-09-30 `ab/oracle_catalog.py` run (seeds 1–15). 435 `igd=` cells. pymoo Sphere is `skip:` because that pymoo problem is a different box. That snapshot's OSY / TNK / C1-DTLZ1 rows are historical skips. ZDT1 / ZDT2 / DTLZ2 quality numbers are not retuned.
- Constrained demos OSY, TNK, and C1-DTLZ1 in [`src/problems.bend`](src/problems.bend) (C# formulas, bounds, `g ≤ 0`). A mixed pool niches the feasible subset and fills a shortfall by ascending CV (`lnk` false on fillers). The hyperplane uses the feasible subset when any member is infeasible; an all-feasible pool stays on the previous normalize / select path. Smoke: `bend src/constrained_smoke.bend -o` and [`ab/test_constrained_smoke.py`](ab/test_constrained_smoke.py). Dump names `osy` / `tnk` / `c1dtlz1` emit `feas_nd`. Omitted dump knobs stay 4/8/3. Quality sizes are `constrained_knobs` (PymooCompatible). Measured cells: [docs/CONSTRAINED-SURFACES.md](docs/CONSTRAINED-SURFACES.md).
- GD+ in [`ab/indicators.py`](ab/indicators.py), matching C# `PerformanceIndicators.GenerationalDistancePlus` (Euclidean of `max(a_j − z_j, 0)`). Hand case: [`ab/test_gd_plus.py`](ab/test_gd_plus.py). No Bend indicator module. A/B IGD stays in [`ab/igd_vs_pymoo.py`](ab/igd_vs_pymoo.py).
- Hub name `unified-nsga-iii@0.2.0.0` still resolves to `0xa2f9d6ef8c474468bf1de15ebe70c512`. GitHub Release `v0.2.0` already exists. This cut's name is linked after merge (`bend link unified-nsga-iii@0.2.1.0 0x2bc7fb472c80bd6a0e04725c117edb2a`).
- `gh repo edit` for the About text in this file was tried from an earlier tree and returned **HTTP 403**. The command below now says **0.2.1**. It is not applied in this cut. The ROADMAP About checkbox stays open.

## [0.2.0] - 2026-09-30

Hub re-publish after the problem catalog (#26) and constraint-domination / offspring contract (#27). `bend src/lib.bend --publish` (Bend 2.0.34) already ran. Not nuget.org. Not GitHub Packages. Git tag `v0.2.0` and the GitHub Release exist: https://github.com/AppSprout-dev/unsga3-bend/releases/tag/v0.2.0.

- Previous hub hash (0.1.2): `0x527a2a4fa91b05a0250d7be0e11d232a`
- Content hash: `0xa2f9d6ef8c474468bf1de15ebe70c512`
- Printed import: `import 0xa2f9d6ef8c474468bf1de15ebe70c512/lib.bend as Lib`
- Consumer import: `import 0xa2f9d6ef8c474468bf1de15ebe70c512/lib.bend as Unsga3`

Hub entry is `/lib.bend` (what bend printed), not `/src/lib.bend`. A/B stays `PymooCompatible`. No new IGD / HV / Wilcoxon cells.

`unified-nsga-iii@0.1.2.0` still resolves to `0x527a2a4fa91b05a0250d7be0e11d232a`. `unified-nsga-iii@0.2.0.0` resolves to `0xa2f9d6ef8c474468bf1de15ebe70c512`.

### Added

- Unconstrained C# problem catalog in [`src/problems.bend`](src/problems.bend): ZDT3 (n=30), ZDT4 (n=10, `x0∈[0,1]`, `x1..∈[-5,5]`), ZDT6 (n=10), DTLZ1 (M=3, k=5), DTLZ3 (k=10, DTLZ2 map with DTLZ1 `g`), DTLZ4 (α=100, k=10), DTLZ7 (k=20), Sphere (n=10), Ackley (n=30), Rosenbrock (n=10). Formulas match [AppSprout-dev/Unsga3](https://github.com/AppSprout-dev/Unsga3) `Problems/`.
- Dump names for that catalog in [`ab/dump_bend_run.py`](ab/dump_bend_run.py). Omitted `--partitions` / `--pop` / `--gens` on those names are a short smoke (4 / 8 / 3), not the ZDT1 / ZDT2 / DTLZ2 quality budgets. Explicit flags still win. No IGD / HV / Wilcoxon cells.
- Smoke [`src/catalog_smoke.bend`](src/catalog_smoke.bend): each catalog problem evaluates at `x_i=0.5` and a pop=4, gens=1, seed=1 `Run` completes. [`ab/test_catalog_smoke.py`](ab/test_catalog_smoke.py) checks dimensions, bounds, and those objective values. It does not score a front.
- `Individual` constraint vector and aggregate CV (sum of positive `g`; feasible iff CV ≤ 0). Empty constraints stay CV 0.
- Deb constraint-domination in `NDS.sort`: feasible beats infeasible; both infeasible and unequal CV → smaller CV; equal CV is mutual non-domination (objectives are not compared). Both feasible → Pareto. Published C# `CompareConstraintDominated` still Pareto-compares an equal-CV infeasible pair; this tree does not. `NDS.dominates` stays the Pareto predicate. Zero-constraint ZDT / DTLZ stay on that path.
- CV prefixes on both tournaments. `PymooCompatible` (A/B default): if either parent is infeasible, smaller CV wins and equal CV is a coin. `RankNicheDistance`: equal CV falls through to rank, niche count, distance, then a coin. A/B is not switched to `RankNicheDistance`.

### Fixed

- Offspring duplicate elimination hashes the survivor population, then accepted children. A member who lost every tournament is still a duplicate of P. After `pop·40` pair attempts, up to `max(pop·20, 1)` mutations must be a new key; remaining slots may be duplicates. The key stays `round(x*1e12)/1e12`, not C# `ToString("G12")`.
- Odd-N SBX includes parent `N-1` (paired with parent `0`). Even-N pair lookups are unchanged. N = 1 crosses the only parent with itself.

Lock: [`src/cd_contract.bend`](src/cd_contract.bend).

## [0.1.2] - 2026-09-22

Hub re-publish of the tree after forensic #24. `bend src/lib.bend --publish` (Bend 2.0.25) already ran. Not nuget.org. Not GitHub Packages. Git tag `v0.1.2` and the GitHub Release are cut after merge.

- Previous hub hash (0.1.0, unchanged through GitHub 0.1.1): `0xcd07e24a626a62e74603d48f436cd679`
- Content hash: `0x527a2a4fa91b05a0250d7be0e11d232a`
- Printed import: `import 0x527a2a4fa91b05a0250d7be0e11d232a/lib.bend as Lib`
- Consumer import: `import 0x527a2a4fa91b05a0250d7be0e11d232a/lib.bend as Unsga3`

Hub entry is `/lib.bend` (what bend printed), not `/src/lib.bend`. GitHub 0.1.2 includes the RankNicheDistance fix below. A/B stays `PymooCompatible`.

### Fixed

- `RankNicheDistance` compares rank, then niche count, then perpendicular distance, then a coin. The earlier path coined as soon as the niche counts matched. A/B stays `PymooCompatible`. Seed-682 pair: [`src/trn_seed682.bend`](src/trn_seed682.bend). No new RankNiche IGD — historical cells in [docs/ZDT2_COLLAPSE.md](docs/ZDT2_COLLAPSE.md) stay the two-key operator.
- Duplicate-key docs no longer claim 12-decimal rounding matches C# `ToString("G12")`. The key stays `round(x*1e12)/1e12`. [`src/g12_key.bend`](src/g12_key.bend) locks `1.234567e-8` → `1.2346e-8`.
- Generated DTLZ2 drivers omit `--pop` / `--gens` at the oracle (92 / 150), same as [`ab/protocol.py`](ab/protocol.py). Explicit flags still win. No-flag `dump_bend_run.py` stays the checked-in smoke.
- Das–Dennis docs call out the existing `das_dennis_len` split: `count(2, 0) = 1` while `das_dennis(2, 0)` is empty. Law text is unchanged. Oracles stay `p≥4`.
- Unequal-length objectives stay mutual non-domination (C# throws). Locked by [`src/nds_unequal.bend`](src/nds_unequal.bend). Equal-length domination is unchanged.
- Stale `?TODO` comments in `LAWS.bend` now say the p=0 laws are closed by a bit-zero copy. Law statements are unchanged. Proof-wall scope is in [CONTRIBUTING.md](CONTRIBUTING.md).

## [0.1.1] - 2026-09-21

GitHub docs/ab confidence bump. Hub import unchanged:

```bend
import 0xcd07e24a626a62e74603d48f436cd679/lib.bend as Unsga3
```

### Added

- Multi-seed IGD driver [`ab/oracle_multiseed.py`](ab/oracle_multiseed.py): Bend vs C# Unsga3 vs pymoo NSGA-III under the public oracle knobs; every cell is a real `igd=` or `skip:`.
- pymoo NSGA-III front dump [`ab/dump_pymoo_nsga3.py`](ab/dump_pymoo_nsga3.py) (skips without pymoo).
- Layer-1 fixture bit-check [`ab/fixture_check.py`](ab/fixture_check.py) on `ab/fixtures/core_2obj.json`.
- Measured tables + pass/fail matrix: [docs/ORACLE-MULTISEED.md](docs/ORACLE-MULTISEED.md) (15/15 seeds × 3 problems × 3 stacks; `core_2obj.json` Layer-1 pass).
- ROADMAP checkboxes for that 15-seed IGD + Layer-1 fixture evidence ([docs/ROADMAP.md](docs/ROADMAP.md)).

## [0.1.0] - 2026-09-19

First content-hash hub package. Publish already ran: `bend src/lib.bend --publish`.

- Content hash: `0xcd07e24a626a62e74603d48f436cd679`
- Printed import: `import 0xcd07e24a626a62e74603d48f436cd679/lib.bend as Lib`
- Consumer import: `import 0xcd07e24a626a62e74603d48f436cd679/lib.bend as Unsga3`

Hub entry is `/lib.bend` (what bend printed), not `/src/lib.bend`. Not nuget.org. Not GitHub Packages.

### Added

- v0 core: non-dominated sort, NSGA-III normalization, Das–Dennis directions, niching / association, survival
- Pass 2: decision variables, SBX (η=30), polynomial mutation (η=20), ZDT1 / ZDT2 / DTLZ2 (3-obj), `PymooCompatible` tournament, `Unsga3Algorithm.Run`
- Parallel independent maps, NDS row peel, last-front `NRow` + list-walk SBX/PM/G12, native `bend … -o` dump path
- A/B helpers under `ab/` (optional C# / pymoo). Do not invent IGD / HV / Wilcoxon numbers.
- Public docs: [CONTRIBUTING.md](CONTRIBUTING.md), [docs/EQUIVALENCE.md](docs/EQUIVALENCE.md)

### On main after v0.1.0 tag

Landed on `main` after the hub `v0.1.0` tag and before GitHub `v0.1.1` ([#20](https://github.com/AppSprout-dev/unsga3-bend/pull/20), squash `f5687cf0`). Hub content hash unchanged.

- Closed `niche_count_sum`: mid-split niching histogram conservation (`nats_sum(count_raw.go) == in_bin_count`). Nat-only honesty property of parallel partition; no IGD / F32 / RNG claim. Bend-wall gym spike (Bend+Jev architecture bet; this change is Bend proofs only).

### Protocol

- ZDT2 **quality** A/B: gens=**250**, `PymooCompatible`, p=12, pop=52 ([`ab/protocol.py`](ab/protocol.py), [docs/EQUIVALENCE.md](docs/EQUIVALENCE.md))
- ZDT2 **gens=100** is an early-stress snapshot ([docs/ZDT2_COLLAPSE.md](docs/ZDT2_COLLAPSE.md))
- ZDT1 gens=100; DTLZ2 gens=150

### GitHub About (apply with org permission)

`gh repo edit` from an earlier agent returned **HTTP 403** and never applied. The description below tracks the current hub (**0.2.2**). Maintainers:

```bash
gh repo edit AppSprout-dev/unsga3-bend \
  --description "Bend 2 port of U-NSGA-III. 0.2.2 content-hash hub package (not NuGet). C# Unsga3 is the NuGet/GitHub Packages reference. A/B via ZDT/DTLZ + IGD." \
  --homepage "https://github.com/AppSprout-dev/unsga3-bend" \
  --add-topic bend \
  --add-topic nsga3 \
  --add-topic unsga3 \
  --add-topic multi-objective \
  --add-topic evolutionary-algorithms \
  --add-topic moea \
  --add-topic optimization
```

Replaces current description: `U-NSGA-III in Bend — greenfield rewrite; A/B vs C# Unsga3 via ZDT/DTLZ + pymoo IGD. Not a NuGet package.` (no homepage, no topics). Do **not** add a `nuget` topic.

[Unreleased]: https://github.com/AppSprout-dev/unsga3-bend/compare/v0.2.2...HEAD
[0.2.2]: https://github.com/AppSprout-dev/unsga3-bend/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/AppSprout-dev/unsga3-bend/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/AppSprout-dev/unsga3-bend/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/AppSprout-dev/unsga3-bend/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/AppSprout-dev/unsga3-bend/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/AppSprout-dev/unsga3-bend/releases/tag/v0.1.0
