# Best-of-k energy fidelity

Does a score that sees only the final non-dominated front pick the better Bend seed?

Energy-Based Reasoners (Chen et al., [arXiv:2611.08977](https://arxiv.org/abs/2611.08977)) use one energy for three jobs. One of those jobs is selection: among candidate samples, keep the lowest-energy one. Inside a single U-NSGA-III run, niching already associates each point with a Das–Dennis ray. This check does not change that. It asks whether the same kind of distance, averaged over a finished front, ranks seeds.

**No invented numbers.** Every IGD cell is an `igd=` line from [`ab/igd_vs_pymoo.py`](../ab/igd_vs_pymoo.py). `E_assoc` is computed from that same dumped front. Thresholds below were fixed in [`ab/best_of_k.py`](../ab/best_of_k.py) before this table was filled. They were not edited afterwards.

## Caveat

Compare `E_assoc` only across Bend seeds. Do not compare it across stacks. Bend keeps about 52 points on ZDT1. pymoo NSGA-III on the same knobs keeps about one point per ray (about 12). A mean perpendicular distance on those two fronts is not the same measurement.

## Protocol (pre-registered)

Knobs come from [`ab/protocol.py`](../ab/protocol.py) `oracle_knobs`. The script refuses to run if that module no longer resolves to the tuple below.

| Problem | Partitions | Pop | Gens | Tournament |
|---------|------------|-----|------|------------|
| ZDT1 n=30 | 12 | 52 | 100 | PymooCompatible |
| ZDT2 n=30 | 12 | 52 | 250 | PymooCompatible |
| DTLZ2 M=3 k=10 | 12 | 92 | 150 | PymooCompatible |

- Seeds **1–15**, the same list as [ORACLE-MULTISEED.md](ORACLE-MULTISEED.md).
- k = **3**. The gate uses all C(15, 3) = **455** triples. The 5 disjoint triples (1–3, 4–6, 7–9, 10–12, 13–15) are reported and are not a second gate.
- IGD: `python3 ab/igd_vs_pymoo.py --pf-points 500 --partitions 12`.
- Dumps: `ab/out/oracle_multiseed` when the CSV is already there (`--reuse`). Otherwise `dump_bend_run.py --native` with the knobs above.
- A tie on energy or on IGD keeps the lower seed.

### E_assoc

Ideal is the component-wise minimum of the dumped non-dominated front. Nadir is the component-wise maximum of that same front. A span below `1e-12` uses denominator 1, matching `Util.denom`. This is **not** the run's hyperplane nadir. The CSV does not carry that state, and the score is front-only on purpose.

Each normalized point is associated with its nearest Das–Dennis ray at the run's partitions (`igd_vs_pymoo.das_dennis`, C# DFS order). The distance is the perpendicular residual: `t = (f·w)/(w·w)`, then `‖f − t w‖`. A squared norm below `1e-16` uses `‖f‖`. A tie keeps the earlier ray. `E_assoc` is the mean of those nearest distances.

Uncovered is the fraction of rays with no point. It is reported. It is not part of the pass rule. A dominated row is dropped before the mean. `nd_front` dumps are already that set.

### What is compared

For each triple:

- **Energy pick:** IGD of the seed with the lowest `E_assoc`.
- **Random:** expected IGD of a uniform pick, the mean of the three IGDs.
- **Oracle:** minimum IGD in the triple. Reported, not a pass gate.
- **Shuffled control:** one Fisher–Yates permutation of the 15 energies, `random.Random(0)` (CPython), the same index permutation on every problem. The pick is the lowest shuffled energy. The seed is part of the registration. It was not chosen after seeing the table.

The aggregated number for a method is the **median** of its 455 triple IGDs. 455 is odd, so that median is the middle order statistic. Relative change is

```text
(median_random − median_method) / median_random
```

Positive means the method's median IGD is lower than the random median. Pass flags use the full-precision values in [`ab/out/best_of_k/summary.json`](../ab/out/best_of_k/summary.json). The tables below round.

### Success

All three are required.

| | Rule |
|---|---|
| (a) | Spearman rho(`E_assoc`, IGD) ≥ 0.5 on at least 2 of 3 problems |
| (b) | Median best-of-3 IGD is at least 5% lower than random on at least 2 of 3 problems, and no more than 5% worse on any |
| (c) | The shuffled control stays within ±2% of random on every problem |

If any part fails, the verdict is a negative baseline: a front-only energy does not find the better seed here.

## How to reproduce

```bash
export PATH="$HOME/.bend/bin:$PATH"
export BEND_NO_TELEMETRY=1
python3 ab/test_best_of_k.py
python3 ab/best_of_k.py --reuse
```

Bend is whatever `bend version` prints. This check does not pin a version. Missing pymoo prints `skip:` and the script exits 2. It does not invent an IGD. `ab/out/` is gitignored; the two small files under `ab/out/best_of_k/` are tracked on purpose. Dump CSVs stay ignored.

`python3 ab/test_best_of_k.py` checks `E_assoc` on hand-built fronts (including a dominated row and a flat span) and checks that the shuffled permutation is a pure function of seed 0. It does not run Bend.

## Host for the table below

- Date: 2026-11-19
- Bend: **2.0.40** (`dump_bend_run.py --native`). Not a pin. A later Bend that moves a front should re-run this script rather than edit the cells.
- clang: 18.1.3
- Python: 3.12.3 (the shuffle uses this CPython `random.Random`)
- pymoo: **0.6.2**
- Seeds requested: **1–15**. Seeds scored: **1–15** on ZDT1, ZDT2, and DTLZ2 (45/45 `igd=` lines, 0 skips).
- One ZDT1 seed-1 CSV was already in `ab/out/oracle_multiseed`. The other 44 dumps were compiled and run for this table.

The IGD column and the front size `n` match the Bend column of [ORACLE-MULTISEED.md](ORACLE-MULTISEED.md) to the 6 decimals printed there. That is a yardstick check of this run, not a copied column. `E_assoc` and uncovered are new.

## Verdict

**Negative.** a front-only energy does not find the better seed here.

| Criterion | Result |
|-----------|--------|
| (a) Spearman ≥ 0.5 on ≥ 2/3 | **fail** (0/3) |
| (b) ≥ 5% below random on ≥ 2/3, and none worse than 5% | **pass** (2/3 improve, none worse) |
| (c) shuffled control within ±2% of random on every problem | **fail** |
| All three | **negative** |

| Problem | rho | median best-of-3 | median random | rel vs random | median oracle | median shuffled | shuffled vs random | (a) | 5% lower | not worse | (c) |
|---------|----:|-----------------:|--------------:|--------------:|--------------:|----------------:|-------------------:|:---:|:--------:|:---------:|:---:|
| ZDT1 | 0.3036 | 0.069462 | 0.079182 | 12.276% | 0.061183 | 0.069462 | 12.276% | fail | pass | pass | fail |
| ZDT2 | 0.2250 | 0.024795 | 0.040814 | 39.249% | 0.023553 | 0.024550 | 39.851% | fail | pass | pass | fail |
| DTLZ2 | 0.1250 | 0.004066 | 0.004224 | 3.755% | 0.003777 | 0.004243 | -0.440% | fail | fail | pass | pass |

(a) fails on every problem. The largest rho is 0.30.

(b) meets the registered wording. ZDT1 and ZDT2 clear 5%. DTLZ2 is 3.755% lower, which is inside the "no more than 5% worse" side and short of the 5% improvement.

(c) fails. On ZDT1 the shuffled median **equals** the energy median (0.069462). On ZDT2 the shuffle is 39.851% below the random median, a hair past the energy's 39.249%. The gap in (b) is what a seed-blind pick also gets when the median of single IGDs is compared with the median of triple-means on a right-skewed sample. It is not evidence that `E_assoc` found the better seed. DTLZ2's control does sit in the ±2% band (−0.440%).

## Disjoint triples

Reported only. Not a gate.

| Problem | Seeds | E seed | E IGD | random IGD | oracle seed | oracle IGD | shuffled seed | shuffled IGD |
|---------|-------|-------:|-------:|-----------:|------------:|-----------:|--------------:|-------------:|
| ZDT1 | 1–3 | 2 | 0.062526 | 0.079481 | 1 | 0.061603 | 2 | 0.062526 |
| ZDT1 | 4–6 | 6 | 0.045916 | 0.071334 | 6 | 0.045916 | 4 | 0.084756 |
| ZDT1 | 7–9 | 9 | 0.061749 | 0.068223 | 7 | 0.060659 | 9 | 0.061749 |
| ZDT1 | 10–12 | 11 | 0.151236 | 0.120951 | 10 | 0.084640 | 12 | 0.126977 |
| ZDT1 | 13–15 | 14 | 0.069462 | 0.067373 | 13 | 0.061183 | 15 | 0.071475 |
| ZDT2 | 1–3 | 2 | 0.025621 | 0.026088 | 1 | 0.024550 | 1 | 0.024550 |
| ZDT2 | 4–6 | 6 | 0.024795 | 0.052331 | 4 | 0.023679 | 4 | 0.023679 |
| ZDT2 | 7–9 | 9 | 0.025847 | 0.041165 | 7 | 0.022320 | 9 | 0.025847 |
| ZDT2 | 10–12 | 10 | 0.023553 | 0.049656 | 10 | 0.023553 | 11 | 0.033346 |
| ZDT2 | 13–15 | 13 | 0.024122 | 0.036045 | 15 | 0.022635 | 13 | 0.024122 |
| DTLZ2 | 1–3 | 1 | 0.003914 | 0.003980 | 3 | 0.003777 | 2 | 0.004250 |
| DTLZ2 | 4–6 | 4 | 0.004369 | 0.004414 | 6 | 0.004026 | 4 | 0.004369 |
| DTLZ2 | 7–9 | 9 | 0.004004 | 0.003950 | 7 | 0.003603 | 7 | 0.003603 |
| DTLZ2 | 10–12 | 11 | 0.003727 | 0.004503 | 11 | 0.003727 | 11 | 0.003727 |
| DTLZ2 | 13–15 | 13 | 0.004502 | 0.004308 | 14 | 0.004066 | 13 | 0.004502 |

ZDT1 seeds 10–12 are a plain counterexample: the lowest `E_assoc` is seed 11 (IGD 0.151236), the worst of the three. The oracle seed is 10 (IGD 0.084640).

## Per-seed values

Source: [`ab/out/best_of_k/per_seed.csv`](../ab/out/best_of_k/per_seed.csv). IGD is rounded to 6 decimals here. `E_assoc` is rounded to 6 decimals. Uncovered is rounded to 4 decimals. The two non-zero uncovered cells are one empty ray: ZDT2 seed 3 is 1/13, DTLZ2 seed 13 is 1/91.

| Problem | Seed | E_assoc | uncovered | IGD | n |
|---------|-----:|--------:|----------:|----:|--:|
| ZDT1 | 1 | 0.017778 | 0.0000 | 0.061603 | 52 |
| ZDT1 | 2 | 0.015569 | 0.0000 | 0.062526 | 52 |
| ZDT1 | 3 | 0.019519 | 0.0000 | 0.114314 | 52 |
| ZDT1 | 4 | 0.016281 | 0.0000 | 0.084756 | 52 |
| ZDT1 | 5 | 0.017938 | 0.0000 | 0.083329 | 52 |
| ZDT1 | 6 | 0.015762 | 0.0000 | 0.045916 | 52 |
| ZDT1 | 7 | 0.016522 | 0.0000 | 0.060659 | 52 |
| ZDT1 | 8 | 0.015693 | 0.0000 | 0.082262 | 52 |
| ZDT1 | 9 | 0.013912 | 0.0000 | 0.061749 | 52 |
| ZDT1 | 10 | 0.016109 | 0.0000 | 0.084640 | 52 |
| ZDT1 | 11 | 0.015169 | 0.0000 | 0.151236 | 48 |
| ZDT1 | 12 | 0.018219 | 0.0000 | 0.126977 | 52 |
| ZDT1 | 13 | 0.014418 | 0.0000 | 0.061183 | 52 |
| ZDT1 | 14 | 0.012705 | 0.0000 | 0.069462 | 52 |
| ZDT1 | 15 | 0.014108 | 0.0000 | 0.071475 | 52 |
| ZDT2 | 1 | 0.006669 | 0.0000 | 0.024550 | 52 |
| ZDT2 | 2 | 0.005603 | 0.0000 | 0.025621 | 52 |
| ZDT2 | 3 | 0.021230 | 0.0769 | 0.028093 | 52 |
| ZDT2 | 4 | 0.006186 | 0.0000 | 0.023679 | 52 |
| ZDT2 | 5 | 0.017850 | 0.0000 | 0.108520 | 52 |
| ZDT2 | 6 | 0.005396 | 0.0000 | 0.024795 | 52 |
| ZDT2 | 7 | 0.017321 | 0.0000 | 0.022320 | 52 |
| ZDT2 | 8 | 0.009846 | 0.0000 | 0.075328 | 52 |
| ZDT2 | 9 | 0.004252 | 0.0000 | 0.025847 | 52 |
| ZDT2 | 10 | 0.010989 | 0.0000 | 0.023553 | 52 |
| ZDT2 | 11 | 0.028938 | 0.0000 | 0.033346 | 52 |
| ZDT2 | 12 | 0.013155 | 0.0000 | 0.092069 | 52 |
| ZDT2 | 13 | 0.005431 | 0.0000 | 0.024122 | 52 |
| ZDT2 | 14 | 0.012660 | 0.0000 | 0.061379 | 52 |
| ZDT2 | 15 | 0.015380 | 0.0000 | 0.022635 | 52 |
| DTLZ2 | 1 | 0.002916 | 0.0000 | 0.003914 | 92 |
| DTLZ2 | 2 | 0.003743 | 0.0000 | 0.004250 | 92 |
| DTLZ2 | 3 | 0.005155 | 0.0000 | 0.003777 | 92 |
| DTLZ2 | 4 | 0.003330 | 0.0000 | 0.004369 | 92 |
| DTLZ2 | 5 | 0.005000 | 0.0000 | 0.004848 | 92 |
| DTLZ2 | 6 | 0.004098 | 0.0000 | 0.004026 | 92 |
| DTLZ2 | 7 | 0.006071 | 0.0000 | 0.003603 | 92 |
| DTLZ2 | 8 | 0.004107 | 0.0000 | 0.004243 | 92 |
| DTLZ2 | 9 | 0.004015 | 0.0000 | 0.004004 | 92 |
| DTLZ2 | 10 | 0.006410 | 0.0000 | 0.004882 | 92 |
| DTLZ2 | 11 | 0.003550 | 0.0000 | 0.003727 | 92 |
| DTLZ2 | 12 | 0.004562 | 0.0000 | 0.004901 | 92 |
| DTLZ2 | 13 | 0.003030 | 0.0110 | 0.004502 | 92 |
| DTLZ2 | 14 | 0.003172 | 0.0000 | 0.004066 | 92 |
| DTLZ2 | 15 | 0.005637 | 0.0000 | 0.004357 | 92 |
