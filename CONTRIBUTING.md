# Contributing

This repository is **standalone public OSS**. It is **not** a NuGet package and **not** PackageId `Unsga3`. The C# library ([AppSprout-dev/Unsga3](https://github.com/AppSprout-dev/Unsga3)) stays the NuGet / GitHub Packages stack. First Bend hub version is **0.1.0** (content hash `0xcd07e24a626a62e74603d48f436cd679`; `import 0xcd07e24a626a62e74603d48f436cd679/lib.bend as Unsga3`).

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
python3 ab/check_forensic.py  # audit locks (no IGD)
python3 ab/test_dump_defaults.py  # omitted DTLZ2 pop/gens = 92/150

python3 ab/dump_bend_front.py
python3 ab/dump_bend_run.py --native
```

Native dumps need clang 14+. `ab/dump_bend_run.py --native` prefers `bend … -o` and falls back to `bend file.bend` if the build fails.

## A/B

See [ab/README.md](ab/README.md) and [`ab/protocol.py`](ab/protocol.py).

- ZDT2 **quality** = gens=**250**. gens=**100** is early-stress ([docs/ZDT2_COLLAPSE.md](docs/ZDT2_COLLAPSE.md)).
- C# compare is optional: set `UNSGA3_CS_ROOT` to a checkout **outside** this repo. Do **not** clone Unsga3 into this tree.
- Scripts print `skip: …` when an oracle is missing. **Do not invent IGD / HV / Wilcoxon numbers.**
- Multi-seed IGD + Layer-1 fixture check: `python3 ab/oracle_multiseed.py`, `python3 ab/fixture_check.py` — [docs/ORACLE-MULTISEED.md](docs/ORACLE-MULTISEED.md).

## Do not

- Mention private product repos or internal application names.
- Silently weaken, delete, or “pass” a law in `LAWS.bend` by changing the claim to match a stub.
- Invent IGD / HV / Wilcoxon numbers.

## Proof wall

`bend PROOF.bend` closes every law in `LAWS.bend` (0 `?TODO`). What that buys is empty-input totality, literal defaults, Nat dimensions, list-length locks, irreflexivity of the coded dominance predicate, a bit-zero copy when crossover or mutation probability is the `0.0` word, and conservation of a niche histogram. It does not buy simplex membership, nondominated-front identity, ASF or intercept values, SBX or polynomial-mutation algebra, tournament order, or IGD.

Das–Dennis length proofs are accepted with `@unsafe`: `comps_all_len`, `das_ge2_len`, `LAWS.das_dennis_m1_len`, `LAWS.das_dennis_len`. `nth_comp.go` in `src/reference_directions.bend` is `@unsafe`, and `bend src/lib.bend` also taints `das_dennis_m1`.

Laws stay human-owned. Edits that add, weaken, delete, or rewrite `LAWS.bend` or `PROOF.bend` use the schema-change gate in [AGENTS.md](AGENTS.md) (`level:schema` plus a paired `bend PROOF.bend` bench). This tree does not write those files from a loop.
