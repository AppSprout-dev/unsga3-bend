# Contributing

This repository is **standalone public OSS**. It is **not** a NuGet package and **not** PackageId `Unsga3`. The C# library ([AppSprout-dev/Unsga3](https://github.com/AppSprout-dev/Unsga3)) stays the NuGet / GitHub Packages stack. Planned first Bend hub version is **0.1.0** (content-hash).

Read [AGENTS.md](AGENTS.md) for language + product locks. Protocol: [docs/EQUIVALENCE.md](docs/EQUIVALENCE.md). License: [LICENSE](LICENSE) (MIT).

## Check the tree

Bend is **not** assumed to be on `PATH`. Install from the official script, then:

```bash
curl -fsSL https://bend-lang.com/install.sh | sh
export PATH="$HOME/.bend/bin:$PATH"
export BEND_NO_TELEMETRY=1

bend guide
bend src/lib.bend       # module graph
bend src/op_smoke.bend  # SBX + polynomial mutation
bend src/run_smoke.bend # short ZDT1 Run (pop=8, gens=3) — not oracle
bend PROOF.bend         # 0 ?TODO

python3 ab/dump_bend_front.py
python3 ab/dump_bend_run.py --native
```

Native dumps need clang 14+. `ab/dump_bend_run.py --native` prefers `bend … -o` and falls back to `bend file.bend` if the build fails.

## A/B

See [ab/README.md](ab/README.md) and [`ab/protocol.py`](ab/protocol.py).

- ZDT2 **quality** = gens=**250**. gens=**100** is early-stress ([docs/ZDT2_COLLAPSE.md](docs/ZDT2_COLLAPSE.md)).
- C# compare is optional: set `UNSGA3_CS_ROOT` to a checkout **outside** this repo. Do **not** clone Unsga3 into this tree.
- Scripts print `skip: …` when an oracle is missing. **Do not invent IGD / HV / Wilcoxon numbers.**

## Do not

- Run `bend … --publish` or create a `v0.1.0` tag until maintainers fill the README import hash.
- Mention private product repos or internal application names.
- Silently weaken, delete, or “pass” a law in `LAWS.bend` by changing the claim to match a stub.
