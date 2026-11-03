# Layer-1 fixture vs C#

On the same objective fixture, the deterministic selection path (sort, normalize, associate, select) must pick the same row set in Bend `Survival.select` as in C# `NondominatedSortingSurvival.Select(rng: null)`.

## Sub-features

- `fixture-core2`: `ab/fixtures/core_2obj.json` selects `(0,1) (0.2,0.9) (0.5,0.5) (0.9,0.2) (1,0)` on both stacks.

## How to get to it (user POV)

- `python3 ab/fixture_check.py` (docs/ORACLE-MULTISEED.md "Layer-1 fixture bit-check").

## Driving it with bend + ab scripts

Preconditions: dotnet is on PATH, `DOTNET_ROOT` is set, and `UNSGA3_CS_ROOT` points to an Unsga3 checkout outside this repo.

- **Run.** `python3 ab/fixture_check.py --out-dir "$EVIDENCE/fixture" | tee "$EVIDENCE/fixture_check.log"`. The log ends with `fixture=ab/fixtures/core_2obj.json verdict=pass bend=ok csharp=ok row_set_equal=True`.
- **Evidence.** `$EVIDENCE/fixture/fixture_core_2obj_{bend,csharp}_F.csv` each hold 5 rows.

## Gotchas

- Without dotnet or `UNSGA3_CS_ROOT`, the C# side prints `skip:` and the verdict is not a pass. Report it as unverified.
- C# writes G17 doubles (`0.20000000000000001`) and Bend writes F32 text (`0.2`). Equality is checked after a Python `float` parse.
