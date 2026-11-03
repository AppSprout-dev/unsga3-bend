# Run smoke and native build

A user runs `Unsga3Algorithm.Run` through the checked-in drivers, either with the interpreter (`bend file.bend`) or as a native binary (`bend file.bend -o bin`). The same seed must print the same front both ways.

## Sub-features

- `smoke-run`: `bend src/run_smoke.bend` prints a `# smoke: zdt1 n=30 partitions=4 pop=8 gens=3 seed=1 tournament=PymooCompatible` header and 7 objective rows.
- `smoke-native`: `bend src/run_smoke.bend -o <bin>` builds, and the binary prints the same rows.
- `smoke-dump`: `ab/dump_bend_run.py --native` and `--interpreter` write byte-identical CSVs.
- `smoke-ops`: `bend src/op_smoke.bend` prints SBX/PM children (`c1=…`, `c2=…`).
- `smoke-forensic`: `ab/check_forensic.py` prints `ok` for every locked driver (trn_seed682, g12_key, nds_unequal, cd_contract).
- `smoke-select`: `bend src/ab_select.bend` and `ab/dump_bend_front.py` (v0 `Survival.select`). Without `--out`, the dump writes the gitignored `ab/out/bend_F.csv`. `gates.sh` passes `--out "$EVIDENCE/gates/bend_F.csv"`.

## How to get to it (user POV)

- `bend src/run_smoke.bend`, then `bend src/run_smoke.bend -o ab/out/run_smoke && ./ab/out/run_smoke --threads 8`.
- `python3 ab/dump_bend_run.py --native` (ab/README.md "Smoke").

## Driving it with bend + ab scripts

Preconditions: doctor passes, including clang 14+.

- **Gates.** Run `scripts/gates.sh`. Rows `run_smoke`, `op_smoke`, `ab_select`, `check_forensic`, `dump_front`, `dump_run_native`, `dump_run_interp`, `native_parity`, `native_built`, and `tracked_clean` all read `pass`.
- **Parity proof.** `$EVIDENCE/gates/bend_run_F_native.csv` and `bend_run_F_interp.csv` are identical (`cmp` exit 0). `dump_run_native.log` contains `native: compile_s=` or `native: cache hit`.
- **Hand check.** Run `bend src/run_smoke.bend -o /tmp/unsga3-bend-verify/run_smoke && /tmp/unsga3-bend-verify/run_smoke --threads 8 | diff - <(bend src/run_smoke.bend)`. It prints nothing.

## Gotchas

- Without clang, `bend -o` fails with `bend needs clang 14 or newer`, and `dump_bend_run.py --native` falls back to the interpreter. The CSV still appears, so check the `native:` line.
- A cache hit reuses `ab/out/run_cache/<sha256 of driver>`. A stale cache from another Bend version is still keyed by driver bytes only. If a Bend update is under test, delete `ab/out/run_cache` in the scratch worktree first.
- `--threads` goes only to the binary. Fronts must not depend on it.
