# Changelog

Notable changes to **unsga3-bend**.

This file tracks the Bend **hub** package (content-hash) and GitHub tree versions. It is **not** the C# / NuGet changelog for PackageId `Unsga3` ([AppSprout-dev/Unsga3](https://github.com/AppSprout-dev/Unsga3)).

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The first hub version is **0.1.0** (content hash `0xcd07e24a626a62e74603d48f436cd679`). Git tags `v0.1.0` and `v0.1.1` and their GitHub Releases already exist.

GitHub tree **0.1.1** is a docs/ab confidence bump only. **Do not hub-publish** for 0.1.1 — the content hash stays `0xcd07e24a626a62e74603d48f436cd679`.

## [Unreleased]

### Fixed

- `RankNicheDistance` compares rank, then niche count, then perpendicular distance, then a coin. The earlier path coined as soon as the niche counts matched. A/B stays `PymooCompatible`. Seed-682 pair: [`src/trn_seed682.bend`](src/trn_seed682.bend). No new RankNiche IGD — historical cells in [docs/ZDT2_COLLAPSE.md](docs/ZDT2_COLLAPSE.md) stay the two-key operator.

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

`gh repo edit` from this agent returned **HTTP 403**. Maintainers:

```bash
gh repo edit AppSprout-dev/unsga3-bend \
  --description "Bend 2 port of U-NSGA-III. 0.1.0 content-hash hub package (not NuGet). C# Unsga3 is the NuGet/GitHub Packages reference. A/B via ZDT/DTLZ + IGD." \
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

[Unreleased]: https://github.com/AppSprout-dev/unsga3-bend/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/AppSprout-dev/unsga3-bend/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/AppSprout-dev/unsga3-bend/releases/tag/v0.1.0
