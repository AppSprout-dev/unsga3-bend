# Scaling gate

CI job `scaling` fails when a short DTLZ2 run scales worse than the ceilings below, or when its shape regresses past the committed baseline. The required job `verify` is unchanged. This job is not a branch-protection check until someone marks it required.

It is not an IGD, HV, or Wilcoxon claim. Quality budgets stay in [`ab/protocol.py`](../ab/protocol.py) (DTLZ2 oracle is pop 92, gens 150). The gate uses **gens=16** so the exponent is the cost of the generational loop, not a 150-generation search.

Bend is whatever `https://bend-lang.com/install.sh` installs. Nothing in this directory pins a version. CPU only: the binary is run with `--threads 1`. There is no GPU and no Metal path. Phase context for the real `Run` loop is [docs/PERF_NOTES.md](../docs/PERF_NOTES.md).

## Run

From the repo root, with `bend` and clang 14+ on `PATH`:

```bash
python3 bench/test_scale_gate.py
python3 bench/scale_gate.py --check
python3 bench/scale_gate.py --check --variant slow --expect fail
```

`--check` must exit 0. The slow command must also exit 0, which happens only when the gate **rejects** the slow variant. A slow run that passes the ceilings and the margins exits 1.

`--record` rewrites [`baseline.json`](baseline.json) from a fast run and keeps the existing ceilings. Do that only to refresh medians after a real Bend or algorithm change. Do not raise a ceiling or a margin so the slow variant passes.

Native build: `bend bench/scale_run.bend -o …`, then `./scale_run --threads 1 <cell> gens=16 burn=<weight> [slow]`. The script caches the binary under `bench/out/` (gitignored) by a hash of `src/*.bend` and the two bench sources.

## What is measured

One process per cell. The driver prints `algo_ms` from `IO.now` around `Unsga3Algorithm.Run` and, on the slow variant, the extra walk. The Python harness times that process (`wall_s`) and reads the child's peak RSS (`ru_maxrss`, kilobytes) from a fresh interpreter so earlier cells do not stick to `RUSAGE_CHILDREN`.

The gate fits **medians of 3 repeats**. Absolute milliseconds are printed and stored. The pass/fail checks use log-log exponents and ratios, so a runner that is uniformly slower does not fail.

| Check | Fails when |
|---|---|
| Scaling bound | OLS slope of log(time) or log(RSS) vs log(N) or log(R) is above the ceiling |
| Regression | That slope is above the baseline slope plus `exponent_margin`, or a high/low endpoint ratio (or a cell/anchor ratio) grows by more than the ratio margin |

`N` is population. `R` is `ReferenceDirections.count` (Das–Dennis `C(p+M-1, M-1)`). Anchor cell is `m3p12n92`.

## Grid

DTLZ2, k=10, seed 1, `PymooCompatible`, duplicate elimination on. Same operators as `Unsga3Algorithm.Run`.

| Cell | M | p | R | pop | Why this point |
|---|---:|---:|---:|---:|---|
| `m0idle` | 0 | 0 | 0 | 0 | Process floor. No `Run`. Not in a fit |
| `m3p12n23` | 3 | 12 | 91 | 23 | Oracle reference set, quarter of the oracle pop |
| `m3p12n46` | 3 | 12 | 91 | 46 | Same reference set, half the oracle pop |
| `m3p12n92` | 3 | 12 | 91 | 92 | Oracle DTLZ2 shape (`ab/protocol.py`: pop 92, p 12). Anchor |
| `m3p4n92` | 3 | 4 | 15 | 92 | Smoke partition count, oracle pop |
| `m3p8n92` | 3 | 8 | 45 | 92 | Midpoint partitions so the R fit has three points |
| `m5p4n70` | 5 | 4 | 70 | 70 | p=4 is already used. pop = R, same rule as 92 ≈ 91 |
| `m8p2n36` | 8 | 2 | 36 | 36 | pop = R. This tree has no two-layer generator |
| `m8p3n120` | 8 | 3 | 120 | 120 | pop = R |

p=12 at M=8 is `C(19, 7) = 50388` directions. That does not fit this budget. M=5 and M=8 stay on a single Das–Dennis layer with pop = count, which is the oracle's pop≈R rule, at partition counts the tree already uses (p=4) or the smallest layers that keep R near the oracle's 91.

Fits:

- **time / wall vs N** — `m3p12n23`, `m3p12n46`, `m3p12n92` (M and R fixed)
- **time / wall vs R** — `m3p4n92`, `m3p8n92`, `m3p12n92` (M and pop fixed)
- **RSS vs N** and **RSS vs R** — the same two series

M=5 and M=8 are in the per-cell ratio checks against the anchor. They are not one exponent: M, N, and R move together.

## Ceilings and margins

Recorded 2026-11-17 on a 4-core Intel Xeon (`/proc/cpuinfo` model string `Intel(R) Xeon(R) Processor`), Linux 6.12.113+, Bend **2.0.40** (the installer that day; not pinned), clang 18.1.3. `native: compile_s=7.123`. Warm `--check` after that was **5.3 s**. The slow grid below was **109 s**.

### Fast baseline (the committed medians)

`algo_ms` is the median of the three repeats in [`baseline.json`](baseline.json).

| Cell | algo_ms | wall_s | rss_kb | algo repeat span |
|---|---:|---:|---:|---|
| m0idle | 0 | 0.001 | 11776 | 0 |
| m3p12n23 | 38 | 0.039 | 11780 | 36–39 |
| m3p12n46 | 90 | 0.092 | 11776 | 89–93 |
| m3p12n92 | 255 | 0.257 | 11776 | 255–258 |
| m3p4n92 | 211 | 0.212 | 11780 | 209–225 |
| m3p8n92 | 212 | 0.213 | 11764 | 211–225 |
| m5p4n70 | 175 | 0.176 | 11776 | 174–175 |
| m8p2n36 | 76 | 0.077 | 11776 | 75–78 |
| m8p3n120 | 572 | 0.574 | 11780 | 545–579 |

A fast-path `burn_ms` of 0 or 1 is the `IO.now` bracket around an empty checksum (`burn_weight=0`), not the slow walk. On this recording `m3p8n92` median `burn_ms` is 1 because two of the three repeats ticked 1 ms.

Log-log OLS on those medians:

| Series | Exponent | Ceiling | Endpoint high/low |
|---|---:|---:|---:|
| time vs N | 1.3732 | 2.50 | 6.7105 (255/38) |
| time vs R | 0.0962 | 1.50 | 1.2085 (255/211) |
| wall vs N | 1.3631 | 2.50 | 6.6175 |
| wall vs R | 0.0975 | 1.50 | 1.2115 |
| RSS vs N | −0.0002 | 1.00 | 0.9997 |
| RSS vs R | −0.0003 | 1.00 | 0.9997 |

A second fast `--check` on the same host, same binary, moved time-vs-N from 1.3732 to **1.3211** and time-vs-R from 0.0962 to **0.0996**. Endpoint-ratio rel to the baseline was 0.930 (N) and 0.996 (R). RSS rel was 0.999.

### Why these ceilings

**Time vs N ≤ 2.5.** Per generation the dominant term is non-dominated sorting. Deb's fast sort is `O(M N²)` comparisons; this tree peels the same dominance relation, twice per generation (survival on the combined pool, then `prepare` on the survivors). Association with R held fixed is `O(M N R) = O(N)`. Evaluation, SBX, and mutation are lower order on analytic DTLZ2 ([PERF_NOTES](../docs/PERF_NOTES.md): NDS is the top bucket, evaluate is ~0). The leading term is quadratic. The measured slope on N=23..92 is **1.37**, not 2, because that range is still mixed with the linear association term and with list overhead. The ceiling is the leading term **2 plus 0.5**, not the sample plus a pad. The extra 0.5 covers that short range and run-to-run fit noise (0.05 on the rerun above).

**Time vs R ≤ 1.5.** Nearest-reference association walks the direction list once per individual, so it is linear in R at fixed N. NDS does not read R. Expected slope ≤ 1. Measured slope is **0.096** (211 ms at R=15, 255 ms at R=91): NDS dominates, so R barely moves the total. Ceiling is **1 plus 0.5**. An association that became quadratic in R would push the slope toward 2 and fail.

**RSS vs N and vs R ≤ 1.0.** Live data is the population, the fronts, and one assignment per individual: `O(N (n_var + M) + R M)`, linear in N and in R. Median peak RSS on this grid, idle included, is **11764–11780 KB**. Within a cell the three repeats differ by at most **40 KB**. The Bend runtime floor is the whole number; a hundred individuals are kilobytes and do not move `ru_maxrss`. The observed slope is 0. The ceiling stays at the linear expectation. It starts to bite once a super-linear allocation is large enough to lift the large-N point off that floor. `rss_ratio_margin` 1.15 is the shape check while the points still sit on the floor: 15% of ~11.8 MB is about 1.8 MB, against a measured endpoint ratio of 0.9997 and a rerun rel of 0.999.

**`exponent_margin` 0.40.** The rerun moved time-vs-N by 0.052. An earlier five-repeat N-series probe (same gens, same binary) spread by 0.013. 0.40 is several times that, for a different runner's cache and CPU mix. A uniform clock change does not move the slope.

**`ratio_margin` 1.75.** On a 4× population span, a slope increase of about 0.4 (23→92 is a factor of 4, and `4^0.4 ≈ 1.74`) multiplies the endpoint ratio by about that. The margin matches the exponent band. The rerun's N-endpoint rel was 0.93, in the direction the check ignores (only growth fails).

The slow control is rejected by the **time-vs-N ceiling itself** (2.68 > 2.5), not only by the tighter regression margin. The 0.5 of headroom above quadratic is not wide enough to hide an `N³` walk.

## Negative control

[`slow_pass.bend`](slow_pass.bend) is not imported by `src/lib.bend`. The driver calls it only when argv contains `slow`.

After `Run`, `rows` recurses once per individual and is **not** a tail call (`F32.add` waits on the recursive result; depth = N). Each index calls `List.get` `burn` times (`burn=600` in CI). `List.get` walks the cons spine from the head. That is one `O(weight · N³)` pass, not a per-generation pass, so the fixed call overhead is not multiplied by gens. The checksum is printed so the walk stays live.

Same grid, same 3 repeats, weight 600, this host:

| Cell | algo_ms | run_ms | burn_ms | rss_kb |
|---|---:|---:|---:|---:|
| m3p12n23 | 152 | 40 | 112 | 11784 |
| m3p12n46 | 861 | 87 | 774 | 11780 |
| m3p12n92 | 6268 | 227 | 6042 | 11776 |
| m3p4n92 | 6051 | 194 | 5857 | 11780 |
| m3p8n92 | 6028 | 208 | 5820 | 11776 |
| m5p4n70 | 2879 | 176 | 2703 | 11776 |
| m8p2n36 | 458 | 77 | 381 | 11788 |
| m8p3n120 | 13386 | 567 | 12819 | 11776 |

Burn roughly cubes with N: 112 → 774 → 6042 when N doubles (×6.9 then ×7.8; a pure cube is ×8).

| Series | Slow exponent | Ceiling | Endpoint rel vs fast baseline |
|---|---:|---:|---:|
| time vs N | **2.6829** | 2.50 | **6.145** (margin 1.75) |
| wall vs N | **2.6767** | 2.50 | **6.178** |
| time vs R | 0.0175 | 1.50 | 0.857 |
| RSS vs N | −0.0005 | 1.00 | 1.000 |

The R slope fell because every pop=92 cell pays about the same burn, which flattens a series that was already NDS-dominated. RSS did not move: the control is a walk, not an allocation. The time-vs-N ceiling, the exponent margin, and the N endpoint ratio all fail. That is the rejection CI requires. If those three pass, CI fails.

Weight 600 is `SLOW_BURN_WEIGHT` in [`scale_gate.py`](scale_gate.py). A much smaller weight leaves the cubic under the quadratic `Run` term and the slope stays near 1.4, which would not cross 2.5. That was measured while choosing 600 (weight 80 at N=92 was ~0.8 s of burn against a ~0.23 s run and did not clear the ceiling).
