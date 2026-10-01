# Constrained surfaces

OSY, TNK, and C1-DTLZ1 formulas, bounds, and constraints are in [`src/problems.bend`](../src/problems.bend). They match C# `ConstrainedProblems`. Smoke (formulas, feasible ideal, CV fill, `lnk` clear, short seeded `Run`): `bend src/constrained_smoke.bend -o <bin>`.

This is not the ZDT1 / ZDT2 / DTLZ2 quality table and not the 2026-09-30 catalog snapshot in [ORACLE-CATALOG.md](ORACLE-CATALOG.md).

## Budget

`constrained_knobs` in [`ab/protocol.py`](../ab/protocol.py). Tournament stays `PymooCompatible`. C# NEW-SURFACES scored these problems with `RankNicheDistance`. This table does not use that mode and does not copy those numbers.

| Problem | Partitions | Pop | Gens | n | M |
|---------|------------|-----|------|---|---|
| OSY | 12 | 52 | 250 | 6 | 2 |
| TNK | 12 | 52 | 250 | 2 | 2 |
| C1-DTLZ1 | 12 | 92 | 150 | 7 (k=5) | 3 |

Operators: SBX η=30, p_c=1; polynomial mutation η=20, p_m=1/n. The scored set is the feasible non-dominated front (`Algo.feas_nd`, and the same filter on pymoo `G` / non-dominated sort). An empty feasible set is `skip: no feasible points`.

Reference sets:

- OSY / TNK: pymoo `pareto_front()`
- C1-DTLZ1: DTLZ1 half-simplex at the run's partitions (same yardstick as DTLZ1; `n_var` does not change the PF)

C# cells stay `skip:` when `UNSGA3_CS_ROOT` is unset. This tree does not clone Unsga3. The 2026-10-01 table used checkout `ef33c08` of [AppSprout-dev/Unsga3](https://github.com/AppSprout-dev/Unsga3), whose `tools/OracleCompare` accepts `osy`, `tnk`, and `c1dtlz1` with `--pymoo-mode`. pymoo here is NSGA-III, not U-NSGA-III. pymoo 0.6.1.5. Bend 2.0.34 native.

GD+ is [`ab/indicators.py`](../ab/indicators.py) (C# `GenerationalDistancePlus`: Euclidean norm of `max(a_j − z_j, 0)`). The hand case is `ab/test_gd_plus.py`. No protocol front below was scored with GD+.

## Native completion

The CV-fill insertion used to recurse through a tail that already contained the new row, then cons that row again. Each smaller CV doubled the list. OSY and C1-DTLZ1 at the budgets above died with `bend: memory fault (machine stack overflow?)`. TNK died with `bend: runtime fail-stop`. Restoring that insert still overflows OSY at pop=52 gens=5. The insert that conses onto the original tail does not. `bend src/constrained_budget.bend -o <bin>` runs all three budgets (seed 1, `--threads 1`) and prints `ok` with `len` equal to pop.

## Seeds 1–15 (2026-10-01)

`python3 ab/oracle_constrained.py --seeds 1 … 15`. Every cell is that run. Tournament is `PymooCompatible` on Bend and C# (`--pymoo-mode`). pymoo is NSGA-III.

Reference sets for every `igd=` cell: OSY `pf_rows=99`, `pf_source=pymoo-pareto_front osy`; TNK `pf_rows=104`, `pf_source=pymoo-pareto_front tnk`; C1-DTLZ1 `pf_rows=91`, `pf_source=analytic-c1dtlz1-half-simplex`. Seed 1 Bend fronts: OSY 52 rows, TNK 52 rows, C1-DTLZ1 92 rows. Seed 1 pymoo fronts: OSY 11 rows, TNK 11 rows. C1-DTLZ1 seed 2 Bend and seed 9 C# finished with an empty feasible set (`skip: no feasible points`). pymoo C1-DTLZ1 returned no `F` on 13 of 15 seeds.

Medians of the `igd=` cells only (skips left out):

| problem | Bend | C# | pymoo NSGA-III |
|---------|------|----|----------------|
| osy | 8.883072560092275 (n=15) | 15.867453201169797 (n=15) | 17.924417244299498 (n=15) |
| tnk | 0.01608626215195549 (n=15) | 0.010425655132005617 (n=15) | 0.031060301833329657 (n=15) |
| c1dtlz1 | 0.09268039165883558 (n=14) | 0.08465440267554132 (n=14) | 0.34300910869450796 (n=2) |

| problem | seed | Bend | C# | pymoo NSGA-III |
|---------|-----:|------|----|----------------|
| osy | 1 | igd=8.883072560092275 | igd=15.867453201169797 | igd=14.556481882872603 |
| osy | 2 | igd=12.5585768456214 | igd=18.75704407223466 | igd=9.321215886327728 |
| osy | 3 | igd=7.402619451088504 | igd=7.685011959915932 | igd=8.4616180896382 |
| osy | 4 | igd=14.917332860535579 | igd=18.04175920399644 | igd=79.45811195717195 |
| osy | 5 | igd=15.78922709720071 | igd=2.948805694503057 | igd=20.379420489864433 |
| osy | 6 | igd=8.712172140691793 | igd=13.660297079876822 | igd=20.97455026646556 |
| osy | 7 | igd=6.485098234854192 | igd=20.216263820318478 | igd=20.980470913100948 |
| osy | 8 | igd=19.233499332081298 | igd=19.83588166374579 | igd=92.49937671856563 |
| osy | 9 | igd=7.68033034176095 | igd=8.869939898774192 | igd=16.019444846634713 |
| osy | 10 | igd=8.310939307573786 | igd=18.378873525627824 | igd=9.019793404529732 |
| osy | 11 | igd=90.99345817712582 | igd=3.7049864120725777 | igd=17.924417244299498 |
| osy | 12 | igd=4.214109236012235 | igd=79.08048877543364 | igd=17.47827579251764 |
| osy | 13 | igd=20.507522735328603 | igd=7.323514326079523 | igd=24.44120728275086 |
| osy | 14 | igd=18.507920371468803 | igd=19.441278921537144 | igd=21.17760888862888 |
| osy | 15 | igd=8.156369873091485 | igd=6.91805245149804 | igd=4.757540063908736 |
| tnk | 1 | igd=0.01953923401181867 | igd=0.010001904816014373 | igd=0.031196608439857627 |
| tnk | 2 | igd=0.013854783328968317 | igd=0.010411219294395774 | igd=0.030987567598804482 |
| tnk | 3 | igd=0.01820084735731802 | igd=0.011349483730777096 | igd=0.03159177407239854 |
| tnk | 4 | igd=0.0172946813097859 | igd=0.010875615828626438 | igd=0.03089732660907499 |
| tnk | 5 | igd=0.015057523513684655 | igd=0.009298008338038921 | igd=0.03372690709357115 |
| tnk | 6 | igd=0.013896696855423133 | igd=0.010425655132005617 | igd=0.03254087657634011 |
| tnk | 7 | igd=0.01701255978887433 | igd=0.009509949671825587 | igd=0.03122881004656114 |
| tnk | 8 | igd=0.01800097673737626 | igd=0.011743229814156026 | igd=0.032768537291656935 |
| tnk | 9 | igd=0.015867591530354806 | igd=0.009531852021905964 | igd=0.029898325474097456 |
| tnk | 10 | igd=0.014964687549177007 | igd=0.01019579630401532 | igd=0.030130577903503278 |
| tnk | 11 | igd=0.016003723068305623 | igd=0.009816980992088331 | igd=0.031060301833329657 |
| tnk | 12 | igd=0.016496241237350488 | igd=0.012223875524860404 | igd=0.030799005741137808 |
| tnk | 13 | igd=0.01608626215195549 | igd=0.01249489093066402 | igd=0.030845018507692827 |
| tnk | 14 | igd=0.01537731324829563 | igd=0.011088280795082476 | igd=0.03137422094183691 |
| tnk | 15 | igd=0.01908873040475028 | igd=0.01060234264419755 | igd=0.030059492052812078 |
| c1dtlz1 | 1 | igd=0.04340510039889103 | igd=0.18459246921886702 | skip: pymoo NSGA-III returned no F. Refusing to invent a front. |
| c1dtlz1 | 2 | skip: no feasible points | igd=0.1852289019604171 | skip: pymoo NSGA-III returned no F. Refusing to invent a front. |
| c1dtlz1 | 3 | igd=0.15882540223087882 | igd=0.08440647372066665 | skip: pymoo NSGA-III returned no F. Refusing to invent a front. |
| c1dtlz1 | 4 | igd=0.0418084032131666 | igd=0.084902331630416 | skip: pymoo NSGA-III returned no F. Refusing to invent a front. |
| c1dtlz1 | 5 | igd=0.07364291508022969 | igd=0.04900261540670542 | skip: pymoo NSGA-III returned no F. Refusing to invent a front. |
| c1dtlz1 | 6 | igd=0.03823030983229058 | igd=0.09298558282830945 | skip: pymoo NSGA-III returned no F. Refusing to invent a front. |
| c1dtlz1 | 7 | igd=0.038184076194215065 | igd=0.25678874822621844 | skip: pymoo NSGA-III returned no F. Refusing to invent a front. |
| c1dtlz1 | 8 | igd=0.11773351167342924 | igd=0.05823205261079091 | igd=0.3517872121657206 |
| c1dtlz1 | 9 | igd=0.19904736504918452 | skip: no feasible points | skip: pymoo NSGA-III returned no F. Refusing to invent a front. |
| c1dtlz1 | 10 | igd=0.176948380515755 | igd=0.14860234107367717 | igd=0.33423100522329535 |
| c1dtlz1 | 11 | igd=0.03839160209334437 | igd=0.06665160285629888 | skip: pymoo NSGA-III returned no F. Refusing to invent a front. |
| c1dtlz1 | 12 | igd=0.20994647944737915 | igd=0.07727767029128506 | skip: pymoo NSGA-III returned no F. Refusing to invent a front. |
| c1dtlz1 | 13 | igd=0.2436916846286259 | igd=0.10234469120308967 | skip: pymoo NSGA-III returned no F. Refusing to invent a front. |
| c1dtlz1 | 14 | igd=0.11171786823744148 | igd=0.05793269953168914 | skip: pymoo NSGA-III returned no F. Refusing to invent a front. |
| c1dtlz1 | 15 | igd=0.04715917061158158 | igd=0.0347904165964638 | skip: pymoo NSGA-III returned no F. Refusing to invent a front. |

No HV. No Wilcoxon.
