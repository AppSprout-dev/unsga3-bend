# Problem catalog and constraints

Users pick problems from the catalog (ZDT1–6, DTLZ1–4/7, Sphere/Ackley/Rosenbrock) and the constrained set (OSY, TNK, C1-DTLZ1, which use Deb constraint-domination). The smoke drivers check dimensions, box ends, `Evaluate(x=0.5)`, and short seeded Runs. None of this measures IGD.

## Sub-features

- `cat-smoke`: `bend src/catalog_smoke.bend` prints `eval …`, `box …`, and `run … len=4 nd=…` lines for every catalog problem.
- `cat-tests`: `ab/test_catalog_smoke.py` and `ab/test_catalog_protocol.py` pass.
- `cons-smoke`: `ab/test_constrained_smoke.py` (native `src/constrained_smoke.bend`) checks formulas, survival ideal / CV / `lnk`, and short Runs.
- `cons-budget`: `ab/test_constrained_budget.py` passes.
- `dump-defaults`: `ab/test_dump_defaults.py` confirms omitted DTLZ2 pop/gens are 92/150 and catalog omissions stay smoke.

## How to get to it (user POV)

- `bend src/catalog_smoke.bend`.
- `python3 ab/dump_bend_run.py --native --problem <name> …` (ab/README.md "Scripts").

## Driving it with bend + ab scripts

Preconditions: doctor passes. The constrained tests build natively, so they need clang.

- **Gates.** Run `scripts/gates.sh`. Rows `catalog_smoke`, `catalog_smoke_t`, `catalog_proto_t`, `constrained_t`, `constr_budget_t`, and `dump_defaults` all read `pass`. Each log ends in `OK`, or in the last `run rosenbrock …` line for `catalog_smoke`.
- **Catalog IGD (optional, long).** `python3 ab/oracle_catalog.py` and `python3 ab/oracle_constrained.py` print `igd=` or `skip:` per cell. Compare them by hand with docs/ORACLE-CATALOG.md and docs/CONSTRAINED-SURFACES.md. No helper does that comparison yet.

## Gotchas

- The constrained tests take about 10 s each because they compile natively.
- Catalog budgets (`catalog_knobs`) and constrained budgets (`constrained_knobs`) are separate from the ZDT1/ZDT2/DTLZ2 protocol. Don't compare them with ORACLE-MULTISEED cells.
