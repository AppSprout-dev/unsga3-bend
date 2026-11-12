# Array.clone / Array.fork associate bench

Host: JMac-mini.local, Apple M4. `bend version` = `bend 2.0.40`.
When: 2026-11-10, about 10:09–10:34 PM America/New_York.
Native binaries, `+RTS --threads 1`. Method: median over independent process
runs of (`IO.now` `total_ms` / in-process reps), after 1 warmup map.
CPU used 5 process runs (80 in-process reps at 184×91, 10 at 2048×276) and
3 process runs × 2 reps at 32000×3003. Metal used 3 process runs × 20 reps
at 184×91, and 1 attempt at 2048×276.

`match_list=1` means every argmin index matched `assoc_map.map_nearest` on
the same generated points/refs (seed=1). `sum_idx` matched the earlier
kernel-experiment values (8819 / 279827 / 47882676), and `sum_idx_acc`
equaled `reps * sum_idx`.

Scripts: `experiments/metal-kernels/assoc_array.bend`,
`write_array_wrapper.py`, `run_array_bench.py`.
Mac checkout used for the compiled runs:
`/Users/jkb/unsga3-array-bench/experiments/metal-kernels/`.

The cons-list numbers below are this harness (indices folded out of
`Surv.nearest_one`), not the earlier posted product-path figures
(0.550 / 19.8 / 2195 ms/rep).

## CPU

| N x R x M | variant | chunk | median ms/rep | min-max | runs x reps | match_list | sum_idx |
|---|---|---:|---:|---|---:|---|---:|
| 184 x 91 x 3 | list | — | 0.3875 | 0.3875-0.4000 | 5 x 80 | 1 | 8819 |
| 184 x 91 x 3 | clone | 1 | 2.4375 | 2.4125-2.5000 | 5 x 80 | 1 | 8819 |
| 184 x 91 x 3 | clone | 32 | 2.0500 | 2.0375-2.1250 | 5 x 80 | 1 | 8819 |
| 184 x 91 x 3 | clone | 128 | 1.6875 | 1.6625-1.7125 | 5 x 80 | 1 | 8819 |
| 184 x 91 x 3 | fork | 1 | 3.2875 | 3.2625-3.3500 | 5 x 80 | 1 | 8819 |
| 184 x 91 x 3 | fork | 32 | 3.2875 | 3.2625-3.3000 | 5 x 80 | 1 | 8819 |
| 184 x 91 x 3 | fork | 128 | 3.3125 | 3.2625-3.8500 | 5 x 80 | 1 | 8819 |
| 2048 x 276 x 3 | list | — | 13.3000 | 12.2000-14.3000 | 5 x 10 | 1 | 279827 |
| 2048 x 276 x 3 | clone | 1 | 71.9000 | 71.5000-74.1000 | 5 x 10 | 1 | 279827 |
| 2048 x 276 x 3 | clone | 32 | 55.9000 | 55.5000-56.2000 | 5 x 10 | 1 | 279827 |
| 2048 x 276 x 3 | clone | 128 | 61.2000 | 60.9000-61.3000 | 5 x 10 | 1 | 279827 |
| 2048 x 276 x 3 | fork | 1 | 112.3000 | 111.9000-113.2000 | 5 x 10 | 1 | 279827 |
| 2048 x 276 x 3 | fork | 32 | 112.8000 | 111.9000-113.2000 | 5 x 10 | 1 | 279827 |
| 2048 x 276 x 3 | fork | 128 | 112.6000 | 111.9000-113.8000 | 5 x 10 | 1 | 279827 |
| 32000 x 3003 x 3 | list | — | 2046.5000 | 2041.5000-2073.5000 | 3 x 2 | 1 | 47882676 |
| 32000 x 3003 x 3 | clone | 1 | 13957.0000 | 13891.0000-14051.5000 | 3 x 2 | 1 | 47882676 |
| 32000 x 3003 x 3 | clone | 32 | 9480.5000 | 9466.5000-9522.0000 | 3 x 2 | 1 | 47882676 |
| 32000 x 3003 x 3 | clone | 128 | 9425.0000 | 9362.5000-9459.0000 | 3 x 2 | 1 | 47882676 |
| 32000 x 3003 x 3 | fork | 1 | 19534.0000 | 19518.0000-19638.0000 | 3 x 2 | 1 | 47882676 |
| 32000 x 3003 x 3 | fork | 32 | 19689.0000 | 19638.5000-19803.5000 | 3 x 2 | 1 | 47882676 |
| 32000 x 3003 x 3 | fork | 128 | 19666.0000 | 19657.0000-19712.5000 | 3 x 2 | 1 | 47882676 |

## Metal (`!`)

| N x R x M | variant | chunk | median ms/rep | min-max | runs x reps | match_list | notes |
|---|---|---:|---:|---|---:|---|---|
| 184 x 91 x 3 | list | — | 6.0000 | 6.0000-6.0500 | 3 x 20 | 1 | |
| 184 x 91 x 3 | clone | 1 | 47.1000 | 45.2500-47.6000 | 3 x 20 | 1 | |
| 184 x 91 x 3 | clone | 32 | 297.6000 | 297.6000-297.6000 | 3 x 20 | 1 | |
| 184 x 91 x 3 | clone | 128 | 1139.6000 | 1139.5000-1139.9000 | 3 x 20 | 1 | |
| 184 x 91 x 3 | fork | 1 | 1156.0000 | 1155.9500-1156.0000 | 3 x 20 | 1 | |
| 184 x 91 x 3 | fork | 32 | 1147.1500 | 1147.1000-1147.1500 | 3 x 20 | 1 | |
| 184 x 91 x 3 | fork | 128 | 1144.5500 | 1144.5000-1144.6000 | 3 x 20 | 1 | |
| 2048 x 276 x 3 | list | — | — | — | — | — | `bend: memory fault (machine stack overflow?)` |
| 2048 x 276 x 3 | clone | 32 | — | — | — | — | same stack overflow |
| 2048 x 276 x 3 | fork | 32 | — | — | — | — | same stack overflow |
