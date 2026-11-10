# Experimental hand-written associate kernels

Isolated experiment. **Not** on the product `Run` path. Nothing here is
imported by `src/algorithm.bend`.

U-NSGA-III association (see `src/survival.bend` `perp` / `nearest_go`):
for each of `N` normalized objective rows and each of `R` reference
directions, compute the perpendicular distance (right-fold F32 residual)
and take the strict-`<` argmin (ties keep the lower index). Niche count
is the histogram of those argmin indices.

## Files

| File | What |
|------|------|
| `associate.metal` | Metal Shading Language kernels (`associate`, `niche_count`) |
| `associate.cu` | CUDA source with the same algorithm (compile-check only; no timings) |
| `AssociateHarness.swift` | Metal host: LCG data, CPU ref, dispatch, e2e + kernel-only times |
| `ref_associate.py` | Python F32 reference matching Bend's right-fold |
| `assoc_map.bend` | Isolated map calling product `Surv.nearest_one` |
| `bench_product.bend` | Current-path bench (no `!`) |
| `bench_bang.bend` | Same map with `map_nearest.go!` (Bend GPU backend) |
| `run_mac_bench.sh` | Compile + run on an Apple GPU machine |

## How to run (Mac, Metal)

```bash
# from a unsga3-bend checkout, current bend on PATH (never pin)
./experiments/metal-kernels/run_mac_bench.sh
```

The script writes `results/msl_*.json`, `results/bend_*.txt`, and
`results/bench.md`. End-to-end Metal times include shared-buffer write,
dispatch, wait, and a readback touch. Kernel-only times use
`MTLCommandBuffer` GPU timestamps. Bend times are `IO.now()` around the
associate map (implicit transfer included; no separate kernel-only
counter).

## Correctness

`ref_associate.py --compare DUMP` checks argmin indices for exact
equality and distances against abs `1e-6` / rel `1e-5`. The product
`Run` IGD path is unchanged: this folder is not imported by it.

## Timing note

`assoc_map.bend` folds each timed repeat's argmin indices into `sum_idx_acc`.
That sum must equal `reps * sum_idx`. Without it, Bend can drop unused
repeats and the wall clock stops scaling with `reps`. See
`results/TABLES.md`.

## CUDA

`associate.cu` is the same algorithm as `associate.metal`. This tree does
not claim CUDA timings. `nvcc` is not required to check the rest of the
experiment.
