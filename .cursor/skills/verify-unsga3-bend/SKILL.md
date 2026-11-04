---
name: verify-unsga3-bend
description: Re-prove unsga3-bend (Bend 2 rewrite of U-NSGA-III) on a checkout. Covers the LAWS/PROOF wall, the Bend smoke drivers, native vs interpreter builds, the ab/ Python gates, the Layer-1 fixture vs C# Unsga3, and the ZDT1/ZDT2/DTLZ2 IGD yardstick vs docs/ORACLE-MULTISEED.md. Use it before a PR, after a Bend toolchain update, or for periodic verification upkeep.
---

# Verify unsga3-bend

This is a library plus CLI drivers. Nothing runs as a server. The user surface is `bend <file.bend>` (check, then run `main`), `bend <file.bend> -o <bin>` (native build), and the `ab/*.py` scripts that dump fronts and score them. "Launch" means getting the toolchain ready. Each drive is a separate short process.

Feature map: [features/README.md](features/README.md). Read it before claiming any feature is verified.

CI runs this skill on every PR to main and every push to main: the `verify` job in [`.github/workflows/ci.yml`](../../../.github/workflows/ci.yml) installs current Bend, runs `doctor.sh`, `gates.sh` (all gates), the Layer-1 fixture, and the seed-1 IGD yardstick with Bend, C# (Unsga3 at a pinned SHA) and pymoo, with no `--allow-skip`. Evidence is uploaded as the `verify-evidence` artifact.

## Launch

Work in a disposable worktree on the ref you are proving. Don't use someone's working branch:

```bash
git -C <clone> fetch origin
git -C <clone> worktree add --detach /tmp/unsga3-bend-verify/tree origin/main
cd /tmp/unsga3-bend-verify/tree
export PATH="$HOME/.bend/bin:$PATH" BEND_NO_TELEMETRY=1
bend update            # current Bend. Never pin a version.
export EVIDENCE=/tmp/unsga3-bend-verify/evidence-$(date +%Y%m%dT%H%M%S)
```

Native builds need **clang 14+** on PATH. Prefer the system package (`apt install clang`, or `https://apt.llvm.org/llvm.sh`). If you can't install a package (no mirror, no sudo), use zig's bundled clang. This is verification scaffolding, so never commit it:

```bash
eval "$(.cursor/skills/verify-unsga3-bend/scripts/zig_clang_shim.sh /tmp/unsga3-bend-verify/toolchain)"
```

Optional oracles. Without them, those cells print `skip:` and stay unverified:

- pymoo (IGD yardstick and the pymoo NSGA-III column): `python3 -m venv /tmp/unsga3-bend-verify/venv && /tmp/unsga3-bend-verify/venv/bin/pip install pymoo numpy`, then put that venv's `bin` first on PATH.
- C# column and the Layer-1 fixture: `export PATH="$HOME/.dotnet:$PATH" DOTNET_ROOT="$HOME/.dotnet"` and `UNSGA3_CS_ROOT=<Unsga3 checkout outside this repo>`. A `git archive <sha> | tar -x -C /tmp/unsga3-cs` export of AppSprout-dev/Unsga3 works. Never clone Unsga3 into this tree (AGENTS.md product lock).

Ready means `doctor.sh` exits 0.

## Doctor

Read-only. Run it first, and again whenever something looks off:

```bash
.cursor/skills/verify-unsga3-bend/scripts/doctor.sh
```

It prints the HEAD SHA and date, the Bend version, clang (needs 14+), python3/numpy, pymoo, dotnet, and whether `UNSGA3_CS_ROOT` is valid. It exits 1 if bend, clang 14+, python3, or numpy is missing, or if `UNSGA3_CS_ROOT` points inside this repo.

## Drive

1. Gates (about 1 minute):

   ```bash
   .cursor/skills/verify-unsga3-bend/scripts/gates.sh
   ```

   This runs the proof wall (`scripts/check_proof_wall.py`) and its self-test, every CONTRIBUTING.md "Check the tree" command, the `ab/test_*.py` suites, `ab/check_forensic.py`, `dump_bend_front.py` (writing to `$EVIDENCE`), and the ZDT1 smoke dump twice (native and interpreter). The two dumps must be byte-identical. A final `tracked_clean` gate fails if any gate changed a tracked file. It writes one line per gate to `$EVIDENCE/gates/summary.txt` and exits 0 only when every gate passes.

2. Layer-1 fixture (needs dotnet and `UNSGA3_CS_ROOT`, a few seconds):

   ```bash
   python3 ab/fixture_check.py --out-dir "$EVIDENCE/fixture" | tee "$EVIDENCE/fixture_check.log"
   ```

   Pass is `verdict=pass ... row_set_equal=True`.

3. IGD yardstick (15 seeds × ZDT1/ZDT2/DTLZ2 × Bend/C#/pymoo, about 11 minutes on 8 cores):

   ```bash
   python3 ab/oracle_multiseed.py --out-dir "$EVIDENCE/multiseed" --markdown "$EVIDENCE/multiseed/tables.md" \
     > "$EVIDENCE/oracle_multiseed.log" 2>&1
   python3 .cursor/skills/verify-unsga3-bend/scripts/compare_yardstick.py "$EVIDENCE/multiseed/summary.jsonl"
   ```

   Pass is `yardstick=pass`: at least one cell compared, `drifted=0`, and `skipped=0`. Every fresh `igd=` cell and front size must match the published per-seed table to 6 decimals. Zero compared cells always fails, because a run with no oracles proves nothing. Any `skip:` row fails unless you pass `--allow-skip`, and then you report those columns as unverified. For a quick check, use `--seeds 1` and list the seeds you actually ran.

## Evidence

- Everything goes under `$EVIDENCE`, outside the worktree: `gates/*.log`, `gates/summary.txt`, `gates/env.txt` (HEAD, bend, clang), `fixture/`, and `multiseed/summary.jsonl` plus the CSV fronts.
- A proof states the main SHA, the date, `bend version`, the clang used (system or the zig shim), and every command run.
- Drive the real user path: `bend <file>`, `bend -o` plus the binary, and the `ab/` scripts. Don't call internals.
- A `skip:` line is a missing oracle, not a pass. Report it as unverified. Never invent IGD, HV, or Wilcoxon numbers.
- Never edit `LAWS.bend` or `PROOF.bend` to make a gate pass. A wall change goes through the AGENTS.md schema-change gate (`level:schema`).
- Never run `bend --publish` or `bend link` during verification. Both write to the public hub.

## Cleanup

```bash
git -C <clone> worktree remove --force /tmp/unsga3-bend-verify/tree
rm -rf /tmp/unsga3-bend-verify/toolchain /tmp/unsga3-bend-verify/venv /tmp/unsga3-cs
```

`ab/out/` (run caches, generated drivers) lives inside the worktree, so it goes with it. Keep `$EVIDENCE`. Kill only PIDs you started; never kill by process name.

## Helpers

| Script | Run | Exit 0 means |
|---|---|---|
| `scripts/doctor.sh` | `scripts/doctor.sh` | required toolchain present |
| `scripts/gates.sh` | `EVIDENCE=… scripts/gates.sh` | every gate passed |
| `scripts/check_proof_wall.py` | `scripts/check_proof_wall.py [--evidence DIR] [--root DIR]` | wall matches CONTRIBUTING.md "Proof wall" |
| `scripts/check_proof_wall.py --self-test` | `scripts/check_proof_wall.py --self-test` | the checker passes the clean wall and fails synthetic bad output plus planted `?TODO` / type-error copies (temp dir; checkout untouched) |
| `scripts/compare_yardstick.py` | `scripts/compare_yardstick.py SUMMARY.jsonl [--allow-skip]` | ≥1 cell compared, all equal the published ones, no skips (unless `--allow-skip`) |
| `scripts/zig_clang_shim.sh` | `eval "$(scripts/zig_clang_shim.sh DIR)"` | prints a PATH export for a zig-backed `clang` |

All paths are relative to `.cursor/skills/verify-unsga3-bend/`. Run them from anywhere inside the checkout.

## Gotchas

- `bend PROOF.bend` **exits 1 with `SOME PROOFS FAIL` even when the wall is closed**. The accepted `@unsafe` Das–Dennis defs taint 14 names (11 for `bend src/lib.bend`). That's the documented state (CONTRIBUTING.md "Proof wall"), and it's the same on Bend 2.0.34 and 2.0.39. Use `check_proof_wall.py`, which compares the exact tainted set with no TODOs and parses Bend's output strictly. The only lines allowed are `SOME PROOFS FAIL`, the `Error: <N> defs rely on unsafe or foreign code:` header (N must equal the names listed), and the names. Anything else fails, including a type error's `Error:` / `- expected :` block. A new or vanished name is a finding. If you change the parser, rerun `--self-test`.
- `bend LAWS.bend --check-only` reports 31 TODOs, one per law. Laws are open claims and `PROOF.bend` closes them. `bend challenges/NicheCountSum.challenge.bend` must report exactly `1 TODO found`. Filling that hole would be a second proof, so don't.
- `ab/dump_bend_run.py --native` silently falls back to the interpreter when `bend -o` fails (for example, no clang). Look for `native: compile_s=` or `native: cache hit` on stderr. `gates.sh` checks this.
- The published tables (2026-09-21, Bend 2.0.22, clang 18, C# `6dd91b5`) still reproduce exactly on later Bend and the zig clang. If a cell drifts, rerun that one seed first. Then report whether the Bend, C#, or pymoo column moved before calling it a product bug.
- ZDT2's A/B default is gens=250. gens=100 is early stress and collapses on both stacks (docs/ZDT2_COLLAPSE.md). That's not a regression.
