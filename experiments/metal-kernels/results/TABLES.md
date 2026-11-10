# Associate kernel benches (2026-11-10, America/New_York)

Host: JMac-mini.local, Apple M4, 10-core GPU, Metal 4, 16 GB unified.
`bend version` = `bend 2.0.40` (updated via install.sh that night; started at 2.0.34).
Apple clang 21.0.0 / Swift 6.4.2. Load averages at start: 2.20 2.23 2.12.
Not an IGD claim. Not a product `Run` path.

## What was timed

- **hand MSL:** `AssociateHarness.swift` + `associate.metal`. End-to-end includes
  shared-buffer rewrite, encode, commit, wait, and a readback touch.
  Kernel-only is `MTLCommandBuffer.gpuEndTime - gpuStartTime` (associate +
  niche_count in one command buffer). Warmup then individual reps; median and
  min-max are reported. Library compile is outside the timed region.
- **Bend product:** `assoc_map.bend` `map_nearest` calling product
  `Surv.nearest_one` (no `!`), `+RTS --threads 1`. Time is `IO.now()` around
  the repeated map (integer milliseconds). Per-rep = `total_ms / reps`.
- **Bend Metal:** the same map with `map_nearest.go!`, GPU on (default).
- **Bend bang CPU:** same `!` binary with `+RTS --threads 1 --gpu off`.

An earlier Bend loop dropped unused repeats (total time did not scale with
`reps`). The numbers below use the forced-work loop: each repeat's argmin
indices are folded into `sum_idx_acc`, which must equal `reps * sum_idx`.
Pre-fix logs remain in this folder as `*_hi.txt` / un-suffixed files and
are not used for claims.

## Primary table

| N x R x M | impl | e2e | kernel-only | reps | sum_idx | work check |
|-----------|------|-----|-------------|-----:|--------:|------------|
| 184 x 91 x 3 (DTLZ2 combined pool) | hand MSL | median **0.365 ms** (0.335-0.369) | median **0.116 ms** (0.111-0.116) | 7 after 2 warm | 8819 | idx exact vs Swift CPU ref; max abs dist 5.6e-8 |
| 184 x 91 x 3 | Bend product (current path) | **0.550 ms/rep** (44 ms / 80) | n/a | 80 after 1 warm | 8819 | sum_idx_acc=705520 = 80 x 8819 |
| 184 x 91 x 3 | Bend Metal (`!`) | **6.55 ms/rep** (131 ms / 20) | n/a (Bend has no GPU timestamp) | 20 after 1 warm | 8819 | sum_idx_acc=176380 = 20 x 8819 |
| 184 x 91 x 3 | Bend bang, `--gpu off` | **0.500 ms/rep** (10 ms / 20) | n/a | 20 after 1 warm | 8819 | sum_idx_acc=176380 = 20 x 8819 |
| 2048 x 276 x 3 (mid) | hand MSL | median **0.392 ms** (0.384-0.433) | median **0.216 ms** (all 0.216-0.216) | 7 after 1 warm | 279827 | idx exact; max abs dist 4.8e-8 |
| 2048 x 276 x 3 | Bend product | **19.8 ms/rep** (198 ms / 10) | n/a | 10 after 1 warm | 279827 | sum_idx_acc=2798270 = 10 x 279827 |
| 2048 x 276 x 3 | Bend Metal (`!`) | **crash** | — | — | — | `bend: memory fault (machine stack overflow?)` |
| 2048 x 276 x 3 | Bend bang, `--gpu off` | **18.6 ms/rep** (149 ms / 8) | n/a | 8 after 1 warm | 279827 | sum_idx_acc=2238616 = 8 x 279827 |
| 32000 x 3003 x 3 (big-N) | hand MSL | median **7.934 ms** (7.928-10.577) | median **7.675 ms** (7.665-10.229) | 5 after 1 warm | 47882676 | idx exact; max abs dist 5.6e-8 |
| 32000 x 3003 x 3 | Bend product | **2195 ms/rep** (6586 ms / 3) | n/a | 3 after 1 warm | 47882676 | sum_idx_acc=143648028 = 3 x 47882676 |
| 32000 x 3003 x 3 | Bend Metal (`!`) | **crash** | — | — | — | same stack overflow |
| 32000 x 3003 x 3 | Bend bang, `--gpu off` | **2236 ms/rep** (4471 ms / 2) | n/a | 2, no extra warm | 47882676 | sum_idx_acc=95765352 = 2 x 47882676 |

Speedup of hand MSL e2e vs Bend product: **1.51x** at 184 x 91, **50.5x** at 2048 x 276, **277x** at 32000 x 3003.

Speedup of hand MSL e2e vs Bend Metal: **17.9x** at 184 x 91 (the only size where Bend `!` completed). Larger sizes: Bend `!` did not run.

Supporting one-shot Swift CPU ref (same process, used for correctness, not a 5-rep median): 0.108 ms at 184 x 91, 2.961 ms at 2048 x 276, 481.9 ms at 32000 x 3003.

## Fixture

`n=8 r=5 m=3 seed=1` (including Python `ref_associate.py` vs Bend product on the box, and vs hand MSL on the Mac): argmin indices identical (`4 2 3 3 4 3 3 1`, sum_idx=23), niche counts identical (`0 1 1 4 2`), max abs distance delta 5.4e-9 (Python vs Bend) and 3.0e-8 (Python vs MSL). The 8 x 5 MSL e2e of 3.32 ms had **no warmup** (first dispatch) and is not a performance claim.

## Extra MSL sizes vs the Swift CPU ref (break-even vs a flat C-like CPU)

Same harness, warmup 1, 7 reps, M=3, seed=1. Swift CPU is one-shot.

| N x R | MSL e2e median (min-max) | MSL kernel median | Swift CPU (1-shot) | e2e vs Swift CPU |
|-------|--------------------------|-------------------|--------------------|------------------|
| 128 x 91 | 0.306 (0.293-0.341) | 0.108 | 0.089 | MSL slower (dispatch) |
| 184 x 91 | 0.365 (0.335-0.369) | 0.116 | 0.108 | MSL slower |
| 256 x 91 | 0.738 (0.403-0.793) | 0.122 | 0.131 | noisy; kernel ~tied |
| 512 x 91 | 0.362 (0.317-0.743) | 0.114 | 0.262 | e2e still close; kernel 2.3x |
| 512 x 276 | 0.997 (0.743-1.054) | 0.352 | 0.746 | kernel 2.1x; e2e still behind |
| 1024 x 276 | 0.964 (0.923-1.027) | 0.351 | 1.488 | **e2e 1.54x** |
| 2048 x 276 | 0.392 (0.384-0.433) | 0.216 | 2.961 | **e2e 7.6x** |
| 8000 x 1050 | 2.507 (2.230-2.530) | 1.890 | 43.67 | **e2e 17.4x** |
| 32000 x 3003 | 7.934 (7.928-10.577) | 7.675 | 481.9 | **e2e 60.7x** |

Break-even vs the current Bend CPU path is already at the realistic DTLZ2 pool (184 x 91). Break-even vs a flat Swift CPU is between 512 x 276 (MSL e2e still slower) and 1024 x 276 (MSL e2e 1.54x).
