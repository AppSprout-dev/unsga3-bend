# IGD yardstick

This is the public A/B: Bend `Run` fronts for ZDT1 (p=12, pop=52, gens=100), ZDT2 (p=12, pop=52, gens=250), and DTLZ2 (p=12, pop=92, gens=150) with the PymooCompatible tournament, scored by `ab/igd_vs_pymoo.py` alongside C# Unsga3 and pymoo NSGA-III over seeds 1–15.

## Sub-features

- `igd-zdt1`, `igd-zdt2`, `igd-dtlz2`: every fresh `igd=` and front size equals the per-seed cells in docs/ORACLE-MULTISEED.md.
- `igd-pf`: the PF yardstick lines are `analytic-zdt1 n=500`, `analytic-zdt2 n=500`, and `pymoo-das-dennis` with 91 rows.

## How to get to it (user POV)

- `python3 ab/oracle_multiseed.py` (CONTRIBUTING.md "A/B").
- Single front: `python3 ab/dump_bend_run.py --native --problem zdt2 --partitions 12 --pop 52 --seed 1 --out F.csv`, then `python3 ab/igd_vs_pymoo.py --front F.csv --problem zdt2 --pf-points 500 --partitions 12`.

## Driving it with bend + ab scripts

Preconditions: doctor passes and pymoo is importable. dotnet and `UNSGA3_CS_ROOT` are needed for the C# column.

- **Dump and score.** `python3 ab/oracle_multiseed.py --out-dir "$EVIDENCE/multiseed" --markdown "$EVIDENCE/multiseed/tables.md" > "$EVIDENCE/oracle_multiseed.log" 2>&1`. The run writes `summary.jsonl` with 135 rows and no `skipped: true`.
- **Compare.** `python3 .cursor/skills/verify-unsga3-bend/scripts/compare_yardstick.py "$EVIDENCE/multiseed/summary.jsonl"` prints `cells_compared=135 matched=135 drifted=0 skipped=0` and `yardstick=pass`. Zero compared cells, or any skip without `--allow-skip`, prints `FAIL …` and `yardstick=fail` (exit 1).
- **Quick check.** Add `--seeds 1` to both steps. You get 9 cells. Report only the seeds you ran.

## Gotchas

- The published tables come from Bend 2.0.22, clang 18, and C# `6dd91b5`. Later Bend and the zig clang still reproduce them exactly. When a cell drifts, find out which column moved before blaming Bend: C# moves with `UNSGA3_CS_ROOT`, and pymoo moves with its version.
- With pymoo missing, even the Bend column skips, because IGD needs pymoo. A run with no oracles compares 0 cells and must fail, never pass.
- `summary.jsonl` is written only when the run ends. Partial progress is in the log as JSON lines.
- Scoring a DTLZ2 front against pymoo's default ~136-point PF is a yardstick mismatch. Use `--partitions 12` (Das–Dennis, 91 points).
