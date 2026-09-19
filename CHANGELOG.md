# Changelog

Notable changes to **unsga3-bend**.

This file tracks the Bend **hub** package (content-hash). It is **not** the C# / NuGet changelog for PackageId `Unsga3` ([AppSprout-dev/Unsga3](https://github.com/AppSprout-dev/Unsga3)).

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The first planned hub version is **0.1.0**. That version is **not published yet**: no `v0.1.0` tag, and `bend … --publish` waits until maintainers fill the import hash.

## [Unreleased] — planned 0.1.0 (hub)

First content-hash hub package. After publish, consumers import the printed line (`import 0x…/src/lib.bend as …`). Until then the hash is a placeholder — **hash filled at publish**. Not nuget.org. Not GitHub Packages.

### In this tree (what 0.1.0 would ship)

- v0 core: non-dominated sort, NSGA-III normalization, Das–Dennis directions, niching / association, survival
- Pass 2: decision variables, SBX (η=30), polynomial mutation (η=20), ZDT1 / ZDT2 / DTLZ2 (3-obj), `PymooCompatible` tournament, `Unsga3Algorithm.Run`
- Parallel independent maps, NDS row peel, last-front `NRow` + list-walk SBX/PM/G12, native `bend … -o` dump path
- A/B helpers under `ab/` (optional C# / pymoo). Do not invent IGD / HV / Wilcoxon numbers.
- Public docs: [CONTRIBUTING.md](CONTRIBUTING.md), [docs/EQUIVALENCE.md](docs/EQUIVALENCE.md)

### Protocol

- ZDT2 **quality** A/B: gens=**250**, `PymooCompatible`, p=12, pop=52 ([`ab/protocol.py`](ab/protocol.py), [docs/EQUIVALENCE.md](docs/EQUIVALENCE.md))
- ZDT2 **gens=100** is an early-stress snapshot ([docs/ZDT2_COLLAPSE.md](docs/ZDT2_COLLAPSE.md))
- ZDT1 gens=100; DTLZ2 gens=150

### GitHub About (apply with org permission)

`gh repo edit` from this agent returned **HTTP 403**. Jason / maintainers:

```bash
gh repo edit AppSprout-dev/unsga3-bend \
  --description "Bend 2 port of U-NSGA-III. Planned 0.1.0 content-hash hub package (not NuGet). C# Unsga3 is the NuGet/GitHub Packages reference. A/B via ZDT/DTLZ + IGD." \
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

[Unreleased]: https://github.com/AppSprout-dev/unsga3-bend/commits/main
