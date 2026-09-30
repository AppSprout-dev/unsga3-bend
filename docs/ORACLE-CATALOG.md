# Catalog IGD

Measured fronts for the unconstrained catalog in [`src/problems.bend`](../src/problems.bend). This is **not** the ZDT1 / ZDT2 / DTLZ2 quality table ([ORACLE-MULTISEED.md](ORACLE-MULTISEED.md)). Those budgets are unchanged and were not re-run here.

**No invented numbers.** Every IGD cell below is a real `igd=` line from [`ab/igd_vs_pymoo.py`](../ab/igd_vs_pymoo.py), or `skip:` with the reason the dumper printed. Reproduce with [`ab/oracle_catalog.py`](../ab/oracle_catalog.py).

## Protocol

C# `tools/OracleCompare` accepts only zdt1, zdt2, and dtlz2. There is no published C# catalog IGD table. This file uses the sibling quality budgets already in [`ab/protocol.py`](../ab/protocol.py) `catalog_knobs`, tournament `PymooCompatible` on Bend and C#:

| Problems | Sibling budget | Partitions | Pop | Gens | Decision n |
|----------|----------------|------------|-----|------|------------|
| ZDT3, ZDT4, ZDT6 | ZDT1 | 12 | 52 | 100 | 30, 10, 10 |
| DTLZ1, DTLZ3, DTLZ4, DTLZ7 | DTLZ2 | 12 | 92 | 150 | 7, 12, 12, 22 |
| Sphere, Ackley, Rosenbrock | short smoke | 1 | 20 | 40 | 10, 30, 10 |

Operators: SBX η=30, PM η=20, p_c=1.0, p_m=1/n. pymoo column is **NSGA-III** (`res.F`), not U-NSGA-III. Bend column is `nd_front`. C# column is the feasible non-dominated front (`NonDominatedSolutions`), same definition as `OracleCompare`. C# runs through [`ab/dump_csharp_catalog.py`](../ab/dump_csharp_catalog.py) because `OracleCompare` rejects these names.

Omitted flags on `dump_bend_run.py` for these names stay the 4/8/3 smoke. That smoke is not this table.

Single-objective IGD is mean distance to the known minimum `f = 0` (`pf_rows=1`). C# CI smokes use smaller `n`, `RankNicheDistance`, and different pop/gens. They are not this budget.

pymoo `sphere` is `[0,1]^n` and is not Bend/C# Sphere (`[-5.12, 5.12]^n`, `f = Σ x²`). That pymoo cell must skip.

## How to reproduce

```bash
export PATH="$HOME/.bend/bin:$HOME/.dotnet:$PATH"
export BEND_NO_TELEMETRY=1
export DOTNET_ROOT="$HOME/.dotnet"
# C# checkout *outside* this repo (do not vendor Unsga3)
export UNSGA3_CS_ROOT=/path/to/Unsga3

python3 ab/oracle_catalog.py
```

`--reuse` keeps an existing non-empty CSV. `--seeds` / `--problems` / `--stacks` select a subset. A missing stack prints `skip:`.

## Constrained problems

OSY, TNK, and C1-DTLZ1 are not implemented in this tree. C# Unsga3 owns those demos (`ConstrainedProblemTests`). C# `docs/EQUIVALENCE.md` records no IGD table for them, and `tools/OracleCompare` does not accept those names. Bend has Deb constraint-domination; the shipped catalog writes no constraint vector.

No front was dumped. No IGD was computed.

| Problem | Bend | C# | pymoo NSGA-III |
|---------|------|----|----------------|
| OSY | skip: problem not in this tree | skip: not measured; C# demo, no OracleCompare protocol | skip: not run |
| TNK | skip: problem not in this tree | skip: not measured; C# demo, no OracleCompare protocol | skip: not run |
| C1-DTLZ1 | skip: problem not in this tree | skip: not measured; C# demo, no OracleCompare protocol | skip: not run |

## Measured IGD tables

Seed tables are pasted from `python3 ab/oracle_catalog.py` stdout (`igd=` / `skip:` only). They are not in this file until that run is recorded.
