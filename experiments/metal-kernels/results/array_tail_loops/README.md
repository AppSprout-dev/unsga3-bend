# Tail-loop array walks (bendlang/bend#1376 follow-up)

nuxyel read `assoc_array.bend` at 31812fc and pointed out that every array read
in the four walks went through a closure and two pairs, so none was a tail call
([comment](https://github.com/bendlang/bend/issues/1376#issuecomment-6934512593)).
They pasted tail-loop versions of `sqnorm`, `dot`, `resid` and `nearest`.
Thanks to nuxyel for the rewrite, and to wakamex for the bendlang/bend#1393 append
workaround. Our reply with these numbers:
[issuecomment-6953577003](https://github.com/bendlang/bend/issues/1376#issuecomment-6953577003).

Host: JMac-mini.local, Apple M4, macOS 27.0.1. `bend version` = `bend 2.0.40`
(latest release). When: 2026-11-17, about 10:45–11:05 AM America/New_York.
Native binaries; median over 5 process runs of (`IO.now` `total_ms` /
in-process reps), after 1 warmup map. Reps: 80 at 184×91, 10 at 2048×276,
2 at 32000×3003. `total_ms` is whole ms, so 184×91 values move in steps of
about 0.0125 ms.

Every run printed `match_list=1` and the list `sum_idx` (8819 / 279827 /
47882676).

| Dir | Source | Backend |
|---|---|---|
| `rerun_cpu_20261117/` | `assoc_array.bend` (as merged), same session | CPU, `+RTS --threads 1` |
| `tail_cpu/` | `assoc_array_tail.bend` | CPU, `+RTS --threads 1` |
| `tail_metal/` | `assoc_array_tail.bend` | Metal (`!`) |
| `tailapp_cpu/` | `assoc_array_tailapp.bend` (+ #1393 append workaround) | CPU, `+RTS --threads 1` |
| `tailapp_metal/` | `assoc_array_tailapp.bend` | Metal (`!`) |
| `tailapp_metal_probe/` | `assoc_array_tailapp.bend`, 3 runs, list + clone c=32 | Metal (`!`) |

These runs used separate Mac copies of the tree, before `--src` existed. To
redo one now: `python3 run_array_bench.py --mode binary --src assoc_array_tail.bend [--bang]`.
Per-run stdout/stderr are not committed; `results.json` keeps every sample.

## CPU, one thread (ms/rep)

| N x R x M | list | clone c=1 / 32 / 128, merged | clone c=1 / 32 / 128, tail | fork c=1 / 32 / 128, merged | fork c=1 / 32 / 128, tail |
|---|---:|---|---|---|---|
| 184 x 91 x 3 | 0.39 | 2.54 / 2.14 / 1.85 | 0.93 / 0.18 / 0.14 | 3.41 / 3.40 / 3.41 | 0.18 / 0.15 / 0.15 |
| 2048 x 276 x 3 | 12.5 | 73.5 / 56.9 / 62.1 | 21.2 / 4.8 / 4.3 | 114.6 / 113.9 / 113.7 | 4.8 / 4.5 / 4.5 |
| 32000 x 3003 x 3 | 2030 | 13957 / 9481 / 9425 * | 5111 / 792 / 687 | ~19600 * | 726 / 726 / 724 |

\* from `../array_clone_fork/RESULTS.md` (2026-11-10); not rerun.
`tailapp_cpu` matches `tail_cpu` within noise (the append change costs nothing on CPU).

## CPU, default threads (10 cores), tail loops, 3 runs (ms/rep)

Run by hand (binary with no `+RTS`); not in the dirs above.

| N x R x M | list | clone c=128 | fork c=128 |
|---|---:|---:|---:|
| 184 x 91 x 3 | 0.14 | 0.15 | 0.15 |
| 2048 x 276 x 3 | 2.4 | 1.3 | 4.6 |
| 32000 x 3003 x 3 | 357 | 132 | 725 |

`Array.fork` gains nothing from more threads here.

## Metal (ms/rep)

| N x R x M | variant | list | clone c=1 / 32 / 128 | fork c=1 / 32 / 128 |
|---|---|---:|---|---|
| 184 x 91 x 3 | merged (2026-11-10) | 6.0 | 47.1 / 297.6 / 1139.6 | 1156 / 1147 / 1145 |
| 184 x 91 x 3 | tail | 5.65 | 10.4 / 15.9 / 38.5 | 66.2 / 58.4 / 56.5 |
| 184 x 91 x 3 | tail + append workaround | 5.81 | 10.5 / 16.3 / 39.5 | 68.1 / 60.3 / 58.4 |
| 2048 x 276 x 3 | tail | memory fault (#1393) | fault | fault |
| 2048 x 276 x 3 | tail + append workaround | 34.6 | 50.2 / 79.3 / 198.7 | 1970 / 1876 / 1855 |

The 2048×276 fault also hits the list variant, so it is #1393 (non-tail
`List.append` under `!`), not the walks. The workaround replaces each map
join's `List.append(lo, hi)` with `List.reverse.go(List.reverse(lo), hi)`
(two tail loops) in `assoc_array_tailapp.bend` and `assoc_map_tailapp.bend`.

Instruction counts (nuxyel measured about 0.6× the list walk) were not
re-checked: no `perf` on macOS and no hardware counters on the Linux box.
