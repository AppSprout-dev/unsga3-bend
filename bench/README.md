# Scaling gate

CI job `scaling` fails when DTLZ2 runtime or peak RSS scales worse than the bound for that series, or when the reference-size median on this runner's CPU model regresses past the baseline recorded for that model. A CPU model with no time baseline fails the job. RSS is compared on every model. The job also fails when a negative control is not caught by the check named for it. It is not the required `verify` check. Branch protection is unchanged.

Bend is whatever `https://bend-lang.com/install.sh` installs. Nothing here pins a version. CPU only: every sample is `--threads 1`. There is no GPU and no Metal path. `BEND_NO_TELEMETRY=1` is set on the workflow and again on the scaling job.

```bash
python3 bench/test_scale_gate.py
python3 bench/scale_gate.py --run
```

`--run` exits 0 only when every measure workload passes and every control is caught by its named check. Time and wall rows in [`baseline.json`](baseline.json) are per CPU model (EPYC 7763, EPYC 9V74, EPYC 9V45, Xeon 6975P-C, Xeon Platinum 8573C), taken from GitHub Actions runs on those hosts. An unlisted model fails the absolute check instead of skipping it. Do not replace a row from a dev VM, and do not raise a ceiling, `max_exponent`, or a margin to make a control pass. A model needs five separate VMs before it gains a row. Xeon 6973P-C has two and has none.

## Method

Each point is the median of 5 runs after one discarded warmup. Each run is its own process (`ru_maxrss` is a high-water mark, so a later sample cannot reuse the parent's child peak). The fitted series span at least 8× in the size parameter.

The fit is log-log OLS of ln(value) on ln(n). The 95% interval uses Student's t with df = points − 2 (df = 2 is 4.302652729911275; df ≥ 31 uses 1.959963984540054). A fit is **within** when the interval's upper bound is at or under the allowed slope and r² is at least 0.75. It is **worse** when the lower bound is above the allowed slope. A straddling interval, or r² under 0.75, is **inconclusive** and fails a measure workload. The allowed slope is the workload's expected exponent plus 0.35, unless that workload sets `max_exponent`.

A time series that grows by less than 2×, and whose upper bound is still at or under the allowed slope, is **skipped** when the workload says `flat_ok`. A memory series that grows by less than 1.25× is treated the same way. Skipping is how a fixed footprint avoids a fake slope. An upper bound that clears the allowance still fails.

The absolute check is one-sided, at one reference size: fail when the median is over baseline × (1 + margin). The margin is not chosen by hand. Two sweeps supply it:

```
need = max(5 × larger reference CV, 2 × |median_a / median_b − 1|)
margin = need rounded up to the next 0.001
```

Sample CV is the n−1 standard deviation divided by the absolute mean. An exact thousandth stays put. The published check of that rounding is 0.5200370151746644 → 0.521, 0.13263110427830926 → 0.133, and 0.4511025764755765 → 0.452.

Time and wall use one baseline per CPU model. `ubuntu-latest` has already been an EPYC 7763 (208 ms at N=92), an EPYC 9V74 (221 ms), an EPYC 9V45 (147 ms), a Xeon 6975P-C (234 ms), and a Xeon Platinum 8573C (271 ms). A model that is not in the table is `skipped-machine`, which fails the job: the uniform control is not caught, and a measure workload emits `::warning` and does not pass. RSS ignores the model string. The cross-run RSS spread (15208–15324 KB, and 103508–103600 KB) sits inside the within-machine margins 0.109 and 0.003, so those margins were not raised.

A model seen on five or more separate VMs uses that same formula across the VMs. Each VM median is already five fresh processes after one warmup. The committed median is the median of the VM medians. The CV in the formula is the largest within-VM sample CV, and the two medians are the smallest and largest VM medians (`margin_need(cv, min, max)`). A two-sided 95% CI of the mean of the VM medians (Student's t, df = VMs − 1) is stored as `ci95` and is not the limit. Fewer than five VMs leaves the table as it was. EPYC 9V74 stays the single run 44212931647 (221 ms, margin 0.077, limit 238.017 ms). Later VMs of that model were faster, and folding them in would widen that margin, so the row stays. Xeon 6973P-C has two VMs (runs 44590362350 and 44597186408) and no row. Xeon Platinum 8573C has two VMs; the committed row stays the single run 44213844582. EPYC 7763 stays the two-sweep confirmation from run 44210506592. Later VMs of that model stay out of the row: folding them in would widen the 0.043 margin, and the top-level medians and the ratio ceiling stay tied to that run.

A same-job ratio to the N² loop does not replace those rows. On the three hosts the N=92 algorithm time divided by that loop was 1.61, 1.55, and 2.95. A margin wide enough to accept 2.95 also accepts the uniform spin, whose ratio to the same loop was 3.34 and 3.10 on the first two hosts. A second copy of the algorithm would track the clock, and a real slowdown would move both copies, so the ratio would stay put. The millisecond table is the check that still sees the reference size.

The previous point-estimate checks are still applied and are not raised: time-vs-N ceiling 2.5, time-vs-R ceiling 1.5, exponent drift 0.40 above the committed slope, endpoint-ratio margins 1.75 (time) and 1.15 (RSS).

## What each workload must do

| Workload | Series | Caught by |
|---|---|---|
| `dtlz2-time` | DTLZ2 M=3 p=12, N=46..368 (8×), gens=16, `algo_ms` | within, allowed 2.190, and the legacy 2.5 ceiling; endpoint ratio at or under 46.671; absolute at `m3p12n92` |
| `dtlz2-wall` | same cells, process wall time | within, allowed 2.35, legacy ceiling 2.5; absolute at `m3p12n92` |
| `dtlz2-r` | N=92, p=4,8,12,20 (R=15..231, 15.4×) | skipped or within; upper bound and the 1.5 ceiling still fail a steep series |
| `dtlz2-rss` | N=3000, gens=1, one cell | absolute RSS only. No slope: one cell cannot span 8× |
| `alloc-linear` | cons cells `1000·n`, n=400..3200 (8×) | RSS within, allowed 1.35; absolute at `a3200` |
| `control-quadratic` | same N grid, `16000` repeats of an N² add loop | endpoint ratio **over** 46.671. The slope interval meets the algorithm's, so `worse` is not the check |
| `control-alloc` | cons cells `n·n`, n=800..6400 (8×) | **worse** on RSS. Exit 1 otherwise |
| `control-uniform` | same N grid, then a spin of another `run_ms` | time stays **within**, and absolute time **fails** against the `dtlz2-time` reference |

`dtlz2-extra` (M=5 and M=8) and `dtlz2-floor` (`m0idle`) are recorded and not fitted. A miss on one named check fails the run even when some other check already failed.

`m3p12n92` on the uniform control is compared with the fast reference, not with a stored copy of the slowed median. A stored copy would make 2× look normal.

## Runner results

GitHub Actions run 44210506592, `ubuntu-latest`, Bend 2.0.40, 4 vCPU, `AMD EPYC 7763 64-Core Processor`. Five measured runs after one warmup, each its own process. The baseline medians are the confirmation sweep. The other sweep is what the margin is measured against. `scaling` on that run exited 2 because the baseline was not committed yet; replaying both sweeps against this file passes, and the three controls are caught.

Time, confirmation sweep, `algo_ms`:

| N | 46 | 92 | 138 | 184 | 276 | 368 |
|---|---:|---:|---:|---:|---:|---:|
| ms | 76 | 208 | 429 | 730 | 1678 | 3087 |

Slope 1.7895, interval [1.5895, 1.9896], r² 0.9936, endpoint ratio 40.618. The other sweep's ratio was 39.282 and its upper bound was 1.9855. **Within** 2.190.

`max_exponent` 2.190 is that confirmation upper bound 1.9895696937018328 plus the interval half-width 0.20005906222086245, rounded up to 0.001. The N² loop's interval is [1.9907, 1.9970]. The two intervals meet, so this raise accepts the loop as well. The endpoint ratio is the check that still separates them.

Reference `m3p12n92`: confirmation median 208 ms (samples 212, 210, 208, 208, 208, CV 0.008551), other sweep 205 ms (CV 0.008147). `need = max(5 × 0.008551, 2 × |205/208 − 1|) = 0.042755`, margin **0.043**. Limit 208 × 1.043 = 216.9 ms.

Endpoint-ratio ceiling: end-point CVs combine to 0.029608, `need = 0.148039`, margin **0.149**. Ceiling 40.618 × 1.149 = **46.671**.

N² loop, one sweep (controls are not repeated): 32, 127, 285, 506, 1137, 2022 ms. Slope 1.9939, interval [1.9907, 1.9970], r² 1.0000, endpoint ratio **63.1875**. That is **within** 2.190 and **35.4% over** the 46.671 ceiling (63.1875 / 46.671 − 1). The ratio check catches it. The slope check does not.

Linear cons cells, confirmation RSS KB: the reference `a3200` median is 103536 (CV 0.000328), other sweep 103508 (CV 0.000515). Slope 0.9299, interval [0.9019, 0.9579], r² 0.9999. **Within** 1.35. Margin **0.003**, limit 103847 KB.

N² cons cells, RSS KB: 22464, 83564, 323568, 1283556 at n=800, 1600, 3200, 6400. Slope 1.9462, interval [1.8828, 2.0097], r² 0.9999. **Worse** than 1.35. The lower bound clears the allowance by 0.533.

Time vs R, confirmation: slope 0.1557, high 0.3029, ratio 1.543. **Skipped** (growth under 2× and the upper bound under 1.35). The other sweep was slope 0.1576, high 0.3303, ratio 1.555, also skipped.

N=3000, gens=1, RSS. Confirmation median 15284 KB (samples 15464, 15412, 14664, 15024, 15284, CV 0.021748), other sweep 15212 KB (CV 0.008511). Margin **0.109**, limit 16950 KB. The idle floor on the same run was 11816 KB.

Uniform spin, N=92, against the fast limit for that same CPU:

| CPU | Fast median | Margin | Limit | Spin median | Over the limit |
|---|---:|---:|---:|---:|---:|
| EPYC 7763 | 208 ms | 0.043 | 216.944 ms | 424 ms | 95.4% |
| EPYC 9V74 | 221 ms | 0.077 | 238.017 ms | 444 ms | 86.5% |
| EPYC 9V45 | 147 ms | 0.149 | 168.903 ms | 266 ms | 57.5% |
| Xeon 6975P-C | 234 ms | 0.091 | 255.294 ms | 462 ms | 81.0% |
| Xeon Platinum 8573C | 271 ms | 0.056 | 286.176 ms | 560 ms | 95.7% |

The 7763 margin is the two-sweep formula, and its spin is the confirmation sweep. The 9V74 and 8573C margins are `5 ×` that one run's sample CV, rounded up, and their spins are that run. The 9V45 and 6975P-C spins are the smallest uniform median on the VMs in the row, which is the closest the control came to the limit. On every model the spin is **within** on the slope and **fail** on the absolute check.

Wall time on the confirmation sweep: slope 1.7810, interval [1.5780, 1.9840], r² 0.9933. **Within** 2.35. Reference median 210.357 ms, margin **0.044**. Wall reference medians: 9V74 stays 223.044 ms (margin 0.074, limit 239.549 ms). On the multi-VM rows, 9V45 is 149.411 ms (margin 0.139) and 6975P-C is 235.984 ms (margin 0.095).

The lowest r² on a fit that was required to clear 0.75 was the time series at 0.9936. The floor stays 0.75.

## Local one-shots

These are single processes on this dev VM (Bend 2.0.40, 4 vCPU, `Intel(R) Xeon(R) Processor`). They are not the baseline. The committed medians and the margin come from the GitHub draft.

Time, N = 46, 92, 138, 184, 276, 368, gens=16, two separate one-shots:

| | N=46 | 92 | 138 | 184 | 276 | 368 | slope | low | high | r² |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| first `algo_ms` | 85 | 223 | 435 | 710 | 1462 | 2563 | 1.6409 | 1.4945 | 1.7873 | 0.9959 |
| second `algo_ms` | 81 | 218 | 427 | 691 | 1468 | 2571 | 1.6649 | 1.5181 | 1.8116 | 0.9960 |

A dev-VM one-shot upper bound of 1.7873 plus its half-width 0.1464 rounded up to 1.934. The runner's upper bound was 1.9896, so the committed override is the runner figure 2.190 above, not 1.934.

Quadratic loop, `burn=16000` (one pass is under the 1 ms clock: N=368 with one repeat measured 0 ms):

| N | 46 | 92 | 138 | 184 | 276 | 368 |
|---|---:|---:|---:|---:|---:|---:|
| ms | 17 | 68 | 153 | 272 | 610 | 1086 |

Slope 1.9987, interval [1.9969, 2.0005], r² 1.0000. That is **within** 2.35. On this VM the interval sat above 1.934, so a slope check could catch it. On the runner the algorithm's interval reaches 1.990 and the loop's starts at 1.991, so the committed check is the endpoint ratio.

Linear cons cells, RSS KB: n=400 → 14968, 800 → 27532, 1600 → 52440, 3200 → 102500. Slope 0.9257, interval [0.8659, 0.9854], r² 0.9995. **Within** 1.35.

Quadratic cons cells, RSS KB: n=800 → 22464, 1600 → 82520, 3200 → 322528, 6400 → 1282524 (about 1.25 GB, 1170 ms). Slope 1.9472, interval [1.8670, 2.0275], r² 0.9998. **Worse** against 1.35. n=400 (`160000` cells) was 11752 KB, the runtime floor, and including it left the fit inconclusive (slope 1.6211, interval [0.8740, 2.3681]).

Time vs R, one shot: R=15 → 187 ms, 45 → 199, 91 → 223, 231 → 283. Slope 0.1501, high 0.3035, endpoint ratio 1.513. Growth is under 2× and the upper bound is under 1.35, so the fit is **skipped**. RSS on every one of these cells was 11772–11796 KB.

N=3000, gens=1, one process: `algo_ms` 18434, wall 18.437 s, RSS 14496 KB. The idle floor on the same binary was 11776 KB. This is the absolute RSS reference. gens=16 here would be about 16×18 s, and 8× the population is not a CI cell.

Uniform spin at N=92: fast one-shot 218 ms, uniform 448 ms. The uniform series stayed within (slope 1.4611, high 1.5526, r² 0.9980). The slope does not see a constant factor. The absolute check does, once a baseline exists.

M=5 p=4 N=70 was 169 ms, M=8 p=2 N=36 was 74 ms, M=8 p=3 N=120 was 550 ms, all on the RSS floor. They are not one exponent.

## Where this gate does not follow the sister method

- The time bound is not n log n + 0.35. Nondominated sort is quadratic asymptotically, but 2.35 does not catch an N² loop (the runner interval is [1.9907, 1.9970]). `max_exponent` 2.190 is the runner's upper bound plus one half-width. That raise also accepts the loop, because the two slope intervals meet. The loop is caught by the endpoint-ratio ceiling 46.671 (measured ratio 63.1875, 35.4% over). The old 2.5 point ceiling stays.
- Algorithm RSS cannot span 8× above the runtime floor inside the job. The slope series is the cons-cell allocation. N=3000 gens=1 is the absolute RSS cell.
- The N² allocation series starts at n=800. n=400 is still on the floor, and that single point made the interval inconclusive.
- Time vs R is allowed to be flat. Association is linear in R and the sort does not read R, so a series that stays under 2× is skipped when its upper bound is still at or under 1.35. A steep series still fails.
- `bench/slow_pass.bend` is the old N³ `List.get` walk. It stays in the tree and is not the live control. On the merged gate the N=92 burn at weight 600 was 3289 ms. The same weight at N=368 is about (368/92)³ ≈ 64× that, on the order of 200 s per sample, which does not fit six runs across an 8× grid. A synthetic cubic series is unit-tested as **worse**. The live controls are the N² loop, the N² allocation, and the uniform 2× spin.
- The previous exponent-drift and endpoint-ratio checks stay beside the new interval and the reference median.
- Slack 0.35 and r² 0.75 are adopted constants. They are not refit from this tree. A GitHub r² that lands on the floor gets written down here; the floor is not lowered to hide it.
- Two sweeps run only while the baseline is unrecorded, so the margin comes from the runner. After that draft is committed, the job is one sweep. The N=3000 cell is about 18 s, and six samples of it are not doubled on later runs.
- Absolute milliseconds for time and wall are the row for this runner's CPU model. Record that row from Actions artifacts. A baseline filled in on a dev VM will fail the runner.

## Files

[`scale_run.bend`](scale_run.bend) is the native driver. [`quad_pass.bend`](quad_pass.bend) and [`alloc_pass.bend`](alloc_pass.bend) are the controls. Neither is imported by `src/lib.bend`. [`gate.config.json`](gate.config.json) is the grid. The script caches `bench/out/scale_run-dev` by a hash of `src/*.bend` and the bench sources.
