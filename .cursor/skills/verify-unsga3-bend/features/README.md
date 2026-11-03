# unsga3-bend verification map

This directory is where verification of unsga3-bend's user-facing behavior is kept up to date. Read this index before you drive anything, then follow the matching feature file as the recipe.

## Baseline preconditions

- Use a disposable detached worktree on the ref under proof (`origin/main` for upkeep).
- Put `$HOME/.bend/bin` on PATH, set `BEND_NO_TELEMETRY=1`, and run `bend update` so Bend is current. Never pin a version.
- Have clang 14+ on PATH (system package, or `scripts/zig_clang_shim.sh`).
- `scripts/doctor.sh` must exit 0.
- Optional oracles: pymoo in a venv, plus dotnet with `UNSGA3_CS_ROOT` pointing outside this repo. A missing oracle means a `skip:` line, and that cell stays unverified.

## Driving conventions

- Every drive is one short process from the repo root: `bend <file.bend>`, `bend <file.bend> -o <bin>` and then the binary, or `python3 ab/<script>.py`.
- Run the commands exactly as written. Keep protocol knobs explicit (`--problem`, `--partitions`, `--pop`, `--gens`, `--seed`). Omitted flags have their own defaults (`ab/protocol.py`).
- Write all output under `$EVIDENCE`, never into tracked files.

## Proof and skip reporting

- CLI proof is the command, its stdout/stderr log, and the exit code. Keep the log, not just a verdict.
- Name the main SHA, the date, `bend version`, and the clang used.
- Report `skip:` as unverified, with the missing oracle named. Never report a skipped column as verified through a different column.
- Never invent IGD, HV, or Wilcoxon numbers. Never edit `LAWS.bend` or `PROOF.bend` to pass a gate.

## Feature entry contract

Each feature file opens with an H1 and one paragraph. Then come four H2s in this order: `Sub-features`, `How to get to it (user POV)`, `Driving it with bend + ab scripts`, and `Gotchas`.

## Features

- [Proof wall](./proof-wall.md): LAWS.bend / PROOF.bend closure, the documented @unsafe taint, and the challenge fixture.
- [Run smoke and native build](./run-smoke.md): `Unsga3Algorithm.Run` drivers, interpreter vs `bend -o` parity, operator and forensic locks.
- [Problem catalog and constraints](./catalog-constrained.md): ZDT/DTLZ/single-objective catalog and the OSY / TNK / C1-DTLZ1 constrained path.
- [Layer-1 fixture vs C#](./layer1-fixture.md): deterministic `Survival.select` row-set equality with C# `Select(rng: null)`.
- [IGD yardstick](./igd-yardstick.md): 15-seed ZDT1/ZDT2/DTLZ2 IGD for Bend, C#, and pymoo, checked against docs/ORACLE-MULTISEED.md.
