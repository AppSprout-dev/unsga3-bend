# Bend 2 performance notes (unsga3-bend)

Toolchain used for this note: **`bend` 2.0.13** (`bend --version`).
Language text: `bend guide` (621 lines, same as `~/.bend/guide/GUIDE.md`).
Extra: `bend guide shaders`, `bend guide effects`, https://bend-lang.com, https://github.com/bendlang/bend README.

There is **no Bend 2 sampling profiler**. The official README limitations list:

> Error messages are terse; no debugger, profiler, formatter, REPL or LSP.

Phase numbers below are **warm-cache native** wall clocks from `ab/profile_bend_run.py` (`IO.now()` milliseconds; native `io_tick()/1000000` in `~/.bend/bend2/effs/now.c`). Compile time is reported separately as `compile_s` and is **not** part of `run_s`.

`--threads` is a **binary** flag (`./bin --threads N`), not a `bend` compile flag. GPU bangs (`f!(x)`) are unused on this Run path; `--gpu off` is only relevant if a `!` call exists. There is no `-O` switch in `bend --help` / the Tooling section.

## Guide citations (what we checked)

### Parallel form

`bend guide` § Parallelism:

> Bend's parallelism primitive is the parallel call notation:
> `a b = pow2(p) pow2(p) # parallel call`
>
> A parallel call promises the compiler two things: (1) The calls are independent. (2) They run in roughly the same time.
>
> Bend's current scheduler is a contention-free, binary fork-join machine: every task is handed to a core exactly once and never moved afterwards. […] you must keep the workload balanced.
>
> A `!` after a function name marks a parallel call: `pow2!(20n)` hands that call, and every parallel call inside it, to the GPU. When compiled to a native executable, `pow2(20n)` runs in parallel on the CPU, while `pow2!(20n)` runs on the GPU.
>
> The JavaScript target ignores all that and just runs sequentially.

So `a b = f(lo) f(hi)` mid-split is the **documented** (and only) parallel form. It is not “one of several APIs”; there are no threads/locks/kernels to write. Our `Util.map_halves` / `filter_halves` and the association / NDS split walks already use that shape. Removing them without measuring would fight the guide.

`bend guide shaders` (cost model):

> Host: one parallel let per def (a second costs an iteration […]); a 0.3 ms job loses to the pool wake-up; a heavy branch serializes a 16-ring chunk […]: split it.

Independent maps with one fork per def match that. Nested extra parallel lets in one def are what the shader note warns against.

### Native flags

`bend guide` § Tooling:

```
bend file.bend -o file    # compile to a native binary (clang 14+; 19+ with `!`)
./file --threads 8        # run a native binary on 8 CPU threads
./file --gpu off          # run ! calls on the CPU (the GPU is on by default)
./file --gpu 4GB          # cap the GPU's heap at 4GB
```

> A `main` that returns `IO` runs compiled; one that returns a value is normalized by the checker (slow for big work) and printed.

Oracle dumps must use `bend … -o` + the binary. `bend file.bend` on a value-`main` is the checker (slow). Our drivers return `IO(Unit)`, so `bend file.bend` still compiles the IO, but the native `-o` path is the intended warm-cache measurement.

No `-O`, no `HVM_THREADS` (that is Bend 1 / HVM). `--profile-json` from older HVM PRs is **not** in Bend 2.0.13.

### Lists vs arrays

`bend guide` § Arrays: `Array<T>` is a `Type` (one owner), in-place `a[i] <- v`, slot count is a power of two. `a[i]` sugar is `Array<U32>` only.

`bend guide` § Recursion: tail calls compile to loops; the shrinking argument must come first.

`bend guide shaders` § Data / Any scene:

> The list is the one shape a flat loop walks with no stack.
> An `Array` has one owner, so it cannot go down a fork tree: build lists.
>
> A per-ray tree walk fails three ways: a fold over a tree is a non-tail recursion (a frame per node), the lanes of a SIMD group diverge, and a `+` tree pays an atomic per node per pixel.

Official README limitations:

> Strings are linked lists of characters, so text processing is slow.
> Parallelism requires balanced calls.

`List.get` / `List.set` / `List.take` / `List.drop` in Base are cons walks. NDS `dominates_idx` uses `List.get` per compare; mid-split pays `take`/`drop` at each fork. That is the documented list layout, and it is also the layout that can be forked. Arrays would be O(1) index but cannot be shared down the fork tree without cloning.

### Things the docs call slow / unsupported that we do or avoid

| Pattern | Doc | Our tree |
|---------|-----|----------|
| Mid-split `a b = f(lo) f(hi)` | required parallel form | used on eval / associate / NDS candidate split / maps |
| `f!(x)` GPU bang | native CPU vs GPU | unused (divergent NDS/niching is a bad GPU fit per shaders: “divergent work like n-queens stays faster on the CPU”) |
| Checker-normalize a value `main` | “slow for big work” | Run drivers are `IO` |
| `List.get` in a hot index loop | cons walk (Base) | NDS peel walks `Row` cons (no `Individual` get); tournament still indexes |
| `take`/`drop` at every fork | O(n) spine copy | `map_halves` / `split_walk` |
| Generic `Bool.pick` on words | shaders: boxes words | used for F32/Nat picks (not the shader U32 path) |
| Non-tail recursion | shaders: frame per call | NDS `is_dominated` is a sequential OR (intentional: first hit skips); peel is fuel-bounded |
| Mutual recursion | forbidden | avoided |
| `@unsafe` | skips termination | only Das–Dennis index walk in proofs |
| JS target | sequential | not used for A/B |
| String-as-list | “text processing is slow” | CSV emit only |

### Missed Bend 2 features (not used, on purpose or not yet)

1. **`!` GPU** — documented; skipped because NDS/niching is divergent (guide: GPU for uniform numeric work).
2. **`Array`** — documented for in-place numeric tables; cannot ride a fork tree. A host-side array rebuild of the population each generation would be a later experiment, not a silent rewrite.
3. **`~` templates** — `List.map` in Base is a template; our maps are closed top-level `~f` already (`map_halves`).
4. **`IO.now` probes** — shaders “Measuring” uses `IO.now()` between host and bang. That is the path we copied. No other profiler exists.
5. **`--threads N`** — we pass it on the binary; default is CPU count.

## Phase labels

`ab/profile_run.bend` clocks the same public calls as `src/algorithm.bend` `one_gen` / `select_st.big` / `Tour.prepare` (same RNG order → same front).

| Bucket | What is timed |
|--------|----------------|
| `init_pop` | `Algo.init_pop` (once) |
| `evaluate` | `Prob.evaluate_all` (init + each offspring batch) |
| `nds_select` | `NDS.sort` inside survival (`select_st`) |
| `nds_prepare` | `NDS.sort` inside `Tour.prepare` (every generation, including gen 0) |
| `nds_final` | `Algo.nd_front` after the last gen |
| `nds` | sum of the three peels |
| `normalize_*` | `Norm.normalize_nd` on the select pool vs the surviving pop |
| `associate_*` | `Surv.associate` (+ stamp_ranks/stamp_asgs on prepare) |
| `niche` | `fill.wrap.rng` + `size_lock` + `gather` |
| `tournament` | `Tour.select_parents` |
| `offspring_sbx_pm_g12` | `Algo.create_offspring` (SBX, polynomial mutation, and G12 dup-key `try_add` are **interleaved per pair**, so they are one bucket) |

Two NDS peels per generation is real Run behavior (`select_st` then `prepare`), not profiler overhead.

## Measured warm native (this machine)

Host: 4-core Xeon (KVM), clang 18.1.3, Bend **2.0.13**, `--threads 4` (CPU count). Seed=1, `PymooCompatible`. `compile_s` is the first `bend … -o` of that hashed driver; tables below are the **second** invocation (`compile_s` omitted, cache hit). `pct` is of `profile_sum_ms` (`IO.now` buckets), not of Python `run_s`. Do not treat interpreter `bend file.bend` milliseconds as native `run_s`. No IGD / HV is claimed here.

Calibration first (DTLZ2 pop=92 gens=5) so the full oracle sizes were not a blind wait: cold `compile_s=7.818`, warm `run_s=2.391`, `nds=90%`. Linear scale said ~70 s for 150 gens; the full DTLZ2 warm run was 55.948 s.

### DTLZ2 M=3 k=10, partitions=12, pop=92, gens=150, seed=1

- cold: `compile_s=8.470`, first-binary `run_s=63.580` (92 front rows)
- warm: `compile_s` omitted, `run_s=55.948`, `profile_sum_ms=55708`, `profile_wall_ms=55943` (92 front rows)

| phase | ms | s | pct |
|-------|---:|---:|----:|
| init_pop | 0 | 0.000 | 0 |
| evaluate | 36 | 0.036 | 0 |
| nds_select | 34529 | 34.529 | 61 |
| nds_prepare | 4662 | 4.662 | 8 |
| nds_final | 0 | 0.000 | 0 |
| **nds** | **39191** | **39.191** | **70** |
| normalize_select | 408 | 0.408 | 0 |
| normalize_prepare | 328 | 0.328 | 0 |
| normalize | 736 | 0.736 | 1 |
| associate_select | 891 | 0.891 | 1 |
| associate_prepare | 602 | 0.602 | 1 |
| associate | 1493 | 1.493 | 2 |
| niche | 9536 | 9.536 | 17 |
| tournament | 79 | 0.079 | 0 |
| offspring_sbx_pm_g12 | 4637 | 4.637 | 8 |
| unaccounted | 235 | 0.235 | |

### ZDT1 n=30, partitions=12, pop=52, gens=100, seed=1

- cold: `compile_s=8.053`, first-binary `run_s=11.125` (52 front rows)
- warm: `compile_s` omitted, `run_s=10.964`, `profile_sum_ms=10901`, `profile_wall_ms=10961` (52 front rows)

| phase | ms | s | pct |
|-------|---:|---:|----:|
| init_pop | 1 | 0.001 | 0 |
| evaluate | 15 | 0.015 | 0 |
| nds_select | 7444 | 7.444 | 68 |
| nds_prepare | 838 | 0.838 | 7 |
| nds_final | 0 | 0.000 | 0 |
| **nds** | **8282** | **8.282** | **75** |
| normalize_select | 81 | 0.081 | 0 |
| normalize_prepare | 69 | 0.069 | 0 |
| normalize | 150 | 0.150 | 1 |
| associate_select | 85 | 0.085 | 0 |
| associate_prepare | 70 | 0.070 | 0 |
| associate | 155 | 0.155 | 1 |
| niche | 371 | 0.371 | 3 |
| tournament | 22 | 0.022 | 0 |
| offspring_sbx_pm_g12 | 1905 | 1.905 | 17 |
| unaccounted | 60 | 0.060 | |

Checked-in smoke (ZDT1 pop=8 gens=3 partitions=4) warm `run_s=0.023`; most buckets are 0–2 ms, so `%` there is quantization, not a ranking.

### Findings (top bottlenecks)

**Hypothesis: NDS rank peel dominates DTLZ2 — confirmed**, not discarded.

1. **`nds` (rank peel)** is the top bucket on both oracles: **70%** DTLZ2, **75%** ZDT1. Almost all of that is `nds_select` (survival on the combined parent+offspring pool: ~184 on DTLZ2, ~104 on ZDT1). `nds_prepare` is the second peel on the surviving pop (`Tour.prepare`): 8% / 7%. `nds_final` is one `nd_front` after the last gen and rounds to 0 ms. Two peels per generation is real `Run` behavior.
2. **DTLZ2 #2 = `niche` (17%)**. Last-front fill grows with gens: calibration gens=5 had niche at 1%; gens=150 is 17%. **DTLZ2 #3 = `offspring_sbx_pm_g12` (8%)**.
3. **ZDT1 #2 = `offspring_sbx_pm_g12` (17%)**; niche is only 3% (2-obj last front is cheaper than 3-obj DTLZ2 crowding). **ZDT1 #3 = `nds_prepare` (7%)** if you split the NDS sum, else niche.

`evaluate` is ~0% — analytic ZDT1 / DTLZ2. `normalize` + `associate` together stay ~3%. `tournament` is a sequential pair walk and is still cheap next to the peels.

Why the peel was expensive on main @ a6ebf2d (guide-backed): `NDS.sort` = `peel` of remaining **indices**; each peel `split_walk`s every leftover candidate; `is_dominated` is a sequential OR so a first hit skips; each compare was `List.get` of a fat `Individual` on a cons list (Base). Mid-split `a b = f(lo) f(hi)` parallelizes candidates, but each fork still paid `take`/`drop` and `List.get` into the shared pop. `bend guide shaders`: an `Array` cannot ride a fork tree.

## After NDS row peel

Same dominance definition. Same mid-split front/leftover **index order**. One sequential pass builds `Row{index, objectives}`; leftover peels reuse those rows. `is_dominated` walks the row list (no `List.get` of `Individual`). Arrays still unused (cannot ride a fork tree). Nested dominate-parallel still unused.

Host for these rows: 4-core Xeon (KVM), clang 18.1.3, Bend **2.0.15**, `--threads 4`, seed=1, `PymooCompatible`. Warm-cache native `ab/profile_bend_run.py` (second invocation; `compile_s` omitted). Fronts vs main @ a6ebf2d seed=1 are **byte-identical** (checked-in smoke, core fixture, oracle ZDT1, oracle DTLZ2). No IGD / HV claimed — the dumps matched, so pymoo was not needed (and is not installed here).

### Headline before (PERF_NOTES main) vs after (this tree)

`pct` is of that run’s `profile_sum_ms`. Niche / offspring **absolute** ms stay in the same band; their % rose because the peel shrank.

| run | | run_s | nds ms (%) | niche ms (%) | offspring ms (%) |
|-----|--|------:|-----------:|-------------:|-----------------:|
| DTLZ2 92×150 | before | 55.948 | 39191 (70%) | 9536 (17%) | 4637 (8%) |
| DTLZ2 92×150 | after | 15.736 | 901 (5%) | 8987 (57%) | 3876 (24%) |
| ZDT1 52×100 | before | 10.964 | 8282 (75%) | 371 (3%) | 1905 (17%) |
| ZDT1 52×100 | after | 2.920 | 270 (9%) | 376 (13%) | 1898 (66%) |

NDS wall ms dropped ~43× on DTLZ2 and ~31× on ZDT1. Warm `run_s` dropped ~3.6× / ~3.8×. New DTLZ2 #1 is `niche`; new ZDT1 #1 is `offspring_sbx_pm_g12`.

### DTLZ2 M=3 k=10, partitions=12, pop=92, gens=150, seed=1 (after)

- warm: `compile_s` omitted, `run_s=15.736`, `profile_sum_ms=15574`, `profile_wall_ms=15732` (92 front rows)

| phase | ms | s | pct |
|-------|---:|---:|----:|
| init_pop | 0 | 0.000 | 0 |
| evaluate | 31 | 0.031 | 0 |
| nds_select | 699 | 0.699 | 4 |
| nds_prepare | 202 | 0.202 | 1 |
| nds_final | 0 | 0.000 | 0 |
| **nds** | **901** | **0.901** | **5** |
| normalize_select | 298 | 0.298 | 1 |
| normalize_prepare | 205 | 0.205 | 1 |
| normalize | 503 | 0.503 | 3 |
| associate_select | 720 | 0.720 | 4 |
| associate_prepare | 465 | 0.465 | 2 |
| associate | 1185 | 1.185 | 7 |
| niche | 8987 | 8.987 | 57 |
| tournament | 91 | 0.091 | 0 |
| offspring_sbx_pm_g12 | 3876 | 3.876 | 24 |
| unaccounted | 158 | 0.158 | |

### ZDT1 n=30, partitions=12, pop=52, gens=100, seed=1 (after)

- warm: `compile_s` omitted, `run_s=2.920`, `profile_sum_ms=2855`, `profile_wall_ms=2917` (52 front rows)

| phase | ms | s | pct |
|-------|---:|---:|----:|
| init_pop | 0 | 0.000 | 0 |
| evaluate | 17 | 0.017 | 0 |
| nds_select | 216 | 0.216 | 7 |
| nds_prepare | 54 | 0.054 | 1 |
| nds_final | 0 | 0.000 | 0 |
| **nds** | **270** | **0.270** | **9** |
| normalize_select | 67 | 0.067 | 2 |
| normalize_prepare | 53 | 0.053 | 1 |
| normalize | 120 | 0.120 | 4 |
| associate_select | 81 | 0.081 | 2 |
| associate_prepare | 72 | 0.072 | 2 |
| associate | 153 | 0.153 | 5 |
| niche | 376 | 0.376 | 13 |
| tournament | 21 | 0.021 | 0 |
| offspring_sbx_pm_g12 | 1898 | 1.898 | 66 |
| unaccounted | 62 | 0.062 | |

## After niching / offspring walks

Same pick rules. Same SBX / PM / G12 RNG order. Last-front fill builds `NRow{index, ref, dist}` once and walks that list (no `List.get` of `Assignment` per remaining candidate per pick). SBX and polynomial mutation peel variable lists with the box intervals (no per-index `List.get` / `set_var_at`). G12 is a sequential tail walk; `try_add` hashes once. Tournament / `niche_loop.rng` stay sequential. Arrays still unused (cannot ride a fork tree).

Host for these rows: 4-core Xeon (KVM), clang 18.1.3, Bend **2.0.15**, `--threads 4`, seed=1, `PymooCompatible`. Warm-cache native `ab/profile_bend_run.py` (second invocation; `compile_s` omitted). Fronts vs main @ dc2eccb (#15) seed=1 are **byte-identical** (checked-in smoke, core fixture, oracle ZDT1, oracle DTLZ2, and the profile fronts). Oracle IGD vs C# (seeds 1–15) is recorded in [Oracle A/B vs C#](#oracle-ab-vs-c-this-tree--pr-16) below.

### Headline before (#15 / main @ dc2eccb) vs after (this tree)

`pct` is of that run’s `profile_sum_ms`. NDS **absolute** ms stay in the same band.

| run | | run_s | nds ms (%) | niche ms (%) | offspring ms (%) |
|-----|--|------:|-----------:|-------------:|-----------------:|
| DTLZ2 92×150 | before | 15.736 | 901 (5%) | 8987 (57%) | 3876 (24%) |
| DTLZ2 92×150 | after | 6.779 | 883 (13%) | 2829 (42%) | 1097 (16%) |
| ZDT1 52×100 | before | 2.920 | 270 (9%) | 376 (13%) | 1898 (66%) |
| ZDT1 52×100 | after | 1.238 | 285 (23%) | 62 (5%) | 523 (43%) |

DTLZ2 niche wall ms dropped ~3.2×; offspring ~3.5×. ZDT1 offspring wall ms dropped ~3.6×; niche ~6× (small absolute). Warm `run_s` dropped ~2.3× / ~2.4×. NDS stayed ~0.9 s / ~0.3 s.

### DTLZ2 M=3 k=10, partitions=12, pop=92, gens=150, seed=1 (after niching / offspring)

- warm: `compile_s` omitted, `run_s=6.779`, `profile_sum_ms=6645`, `profile_wall_ms=6776` (92 front rows)

| phase | ms | s | pct |
|-------|---:|---:|----:|
| init_pop | 0 | 0.000 | 0 |
| evaluate | 64 | 0.064 | 0 |
| nds_select | 692 | 0.692 | 10 |
| nds_prepare | 191 | 0.191 | 2 |
| nds_final | 0 | 0.000 | 0 |
| **nds** | **883** | **0.883** | **13** |
| normalize_select | 301 | 0.301 | 4 |
| normalize_prepare | 172 | 0.172 | 2 |
| normalize | 473 | 0.473 | 7 |
| associate_select | 731 | 0.731 | 11 |
| associate_prepare | 476 | 0.476 | 7 |
| associate | 1207 | 1.207 | 18 |
| niche | 2829 | 2.829 | 42 |
| tournament | 92 | 0.092 | 1 |
| offspring_sbx_pm_g12 | 1097 | 1.097 | 16 |
| unaccounted | 131 | 0.131 | |

### ZDT1 n=30, partitions=12, pop=52, gens=100, seed=1 (after niching / offspring)

- warm: `compile_s` omitted, `run_s=1.238`, `profile_sum_ms=1196`, `profile_wall_ms=1235` (52 front rows)

| phase | ms | s | pct |
|-------|---:|---:|----:|
| init_pop | 1 | 0.001 | 0 |
| evaluate | 33 | 0.033 | 2 |
| nds_select | 225 | 0.225 | 18 |
| nds_prepare | 60 | 0.060 | 5 |
| nds_final | 0 | 0.000 | 0 |
| **nds** | **285** | **0.285** | **23** |
| normalize_select | 64 | 0.064 | 5 |
| normalize_prepare | 47 | 0.047 | 3 |
| normalize | 111 | 0.111 | 9 |
| associate_select | 89 | 0.089 | 7 |
| associate_prepare | 74 | 0.074 | 6 |
| associate | 163 | 0.163 | 13 |
| niche | 62 | 0.062 | 5 |
| tournament | 18 | 0.018 | 1 |
| offspring_sbx_pm_g12 | 523 | 0.523 | 43 |
| unaccounted | 39 | 0.039 | |

## How to reproduce

```bash
export PATH="$HOME/.bend/bin:$PATH"
export BEND_NO_TELEMETRY=1

# smoke (checked-in driver)
python3 ab/profile_bend_run.py
python3 ab/profile_bend_run.py   # second call is warm (compile_s omitted)

# oracle-sized (generated driver; hash-cached)
python3 ab/profile_bend_run.py --problem dtlz2 --partitions 12 --pop 92 --gens 150 --seed 1 --threads 4
python3 ab/profile_bend_run.py --problem dtlz2 --partitions 12 --pop 92 --gens 150 --seed 1 --threads 4
python3 ab/profile_bend_run.py --problem zdt1 --partitions 12 --pop 52 --gens 100 --seed 1 --threads 4
python3 ab/profile_bend_run.py --problem zdt1 --partitions 12 --pop 52 --gens 100 --seed 1 --threads 4
```

---

## Threads (no-flag vs `--threads N`)

This section is the `--threads` verification + bend2.dev citations. It does **not** replace the phase tables above. Those DTLZ2-150 / ZDT1-100 numbers were warm `--threads 4` runs of `ab/profile_bend_run.py`. This section only re-ran already-built binaries (smoke, a `/tmp` `pow2(26n)`, ZDT1 pop=20 gens=5, and the cached DTLZ2 pop=92 gens=5 calibration binary). No second 150-gen DTLZ2 compile.

Host for these rows: **4-core Xeon (KVM)**, `nproc=4`, `getconf _NPROCESSORS_ONLN=4`, affinity `0-3`, no cgroup `cpu.max` quota. Bend **2.0.13**. The binary does **not** print the chosen worker count on a normal run; `--help` and `/proc/<pid>/status` `Threads:` are the observables.

### What the docs say (Bend 2, not HVM2)

`bend guide` § Tooling (also `~/.bend/guide/GUIDE.md`):

```
./file --threads 8        # run a native binary on 8 CPU threads
./file --gpu off          # run ! calls on the CPU (the GPU is on by default)
./file --gpu 4GB          # cap the GPU's heap at 4GB
```

https://bend2.dev/learn/parallelism/ (updated 2026-09-17, compiler `e6676b0`):

> The native fork/join scheduler assigns these calls to CPU threads. Keep their workloads roughly equal: the scheduler does not move a slow branch to idle workers.

> Bend's native compilation example uses `bend file.bend -o file`, followed by running the executable. Run `./file --threads 8` to use eight CPU threads. […] Use `pow2!(12n)` and `./file --gpu 1GB` to send that call and its nested parallel calls to the GPU.

https://bend2.dev/learn/measuring-speedup/ (same date / revision):

> Measure Bend speedup by running the same native program on one CPU thread and several threads, checking that both produce the same result. Divide the one-thread time by the parallel time […]

```
bend main.bend -o main
./main --threads 1 --gpu off
./main --threads 16 --gpu off
```

https://bend2.dev/learn/gpu/: `./pow2 --gpu 1GB` after `bend pow2.bend -o pow2`; bangs (`f!(x)`) are unused on this Run path. https://bend2.dev/learn/concurrency/: `IO.fork` / `IO.join` is the event-loop path; “Parallel pure calls use the separate fork notation shown in parallelism.” There is no HVM2 `--profile-json` on Bend 2.0.13 (`bend --help` / native `--help`).

The native binary’s own `--help` (emitted C, Bend 2.0.13):

```
--threads N       worker threads, 1 to 128 (default: the CPU count)
```

That default is real. `bend file.bend -o file.c` shows `thr` starting at `0`, then:

```
Corpus H = corpus_setup(dev, thr > 0 ? thr : cpu_count(), mem);
```

`cpu_count()` is `sysconf(_SC_NPROCESSORS_ONLN)`, then `sched_getaffinity` `CPU_COUNT`, then a cgroup quota ceiling (`/sys/fs/cgroup/cpu.max` or the v1 `cfs_quota_us` / `cfs_period_us` pair). `pool_size` is clamped to `[1, CUBE_T]` with `CUBE_T = 128`. Omitting `--threads` is therefore **not** “one thread” and **not** a Python `nproc()` inject — it is Bend’s `cpu_count()`. On this host that equals `nproc` (4). `--threads 4` and `--threads $(nproc)` are the same request here.

`ab/dump_bend_run.py --threads` defaults to `None` and **omits** the flag, which is the correct way to get that Bend default. The previous help line (“Bend default: CPU count”) was right about the binary and easy to misread as “the Python flag defaults to `nproc` and we pass it.” The help now says omit-means-`cpu_count()`.

### `/proc` thread count (max `Threads:` while the child lived)

`/proc` counts the main thread plus worker pthreads. `--threads 1` takes the solo `work_loop` path and stays at 1. When the pool opens, observed max is **1 + N**.

| `--threads` | smoke ZDT1 (pop=8 gens=3) | `pow2(26n)` | ZDT1 pop=20 gens=5 | DTLZ2 pop=92 gens=5 |
|-------------|--------------------------:|------------:|-------------------:|--------------------:|
| omit (Bend default) | 1 (exits before the pool is visible) | **5** | **5** | **5** |
| `1` | 1 | **1** | **1** | **1** |
| `2` | 3 | **3** | **3** | **3** |
| `4` (`$(nproc)`) | 1 (too short) | **5** | **5** | **5** |

omit ≡ `--threads 4` ≡ `--threads $(nproc)` on this machine whenever the fork/join pool actually starts.

### Warm `run_s` (quiet host; median of 3 after one discarded warm)

`pow2(26n)` is the balanced tree the guide / bend2.dev page use. Same checksum (`2^26 = 67108864`) at every thread count.

| `--threads` | `pow2(26n)` median `run_s` | vs `--threads 1` | ZDT1 smoke median `run_s` | ZDT1 pop=20 gens=5 | DTLZ2 pop=92 gens=5 median `profile_wall_ms` |
|-------------|---------------------------:|-----------------:|--------------------------:|-------------------:|---------------------------------------------:|
| omit | 0.061 | 3.7× | 0.006 | 0.032 | 2412 |
| `1` | 0.226 | 1.0× | 0.004 | 0.030 | **1726** |
| `2` | 0.124 | 1.8× | 0.005 | 0.033 | 2917 |
| `4` | 0.061 | 3.7× | 0.005 | 0.032 | 4299 (spread 2978 / 4323 / 4299) |

`pow2` scales almost linearly to four cores, matching https://bend2.dev/learn/measuring-speedup/ (“divide the one-thread time by the parallel time”). Smoke and the 20×5 ZDT1 Run are too small: all ~4–33 ms, `--threads 1` is equal or slightly faster (guide shaders: “a 0.3 ms job loses to the pool wake-up”).

The cached DTLZ2 gens=5 binary is NDS-heavy (sibling calibration: `nds=90%`). On a quiet host, **`--threads 1` was faster than omit / 4** (1.73 s vs 2.41 s vs a noisy 3.0–4.3 s). That is not a claim about the 150-gen oracle table above, which was measured at `--threads 4` and was not re-run here. It is consistent with the guide: the scheduler does not steal; inner `is_dominated` is a sequential OR; each mid-split still pays `take`/`drop` + `List.get`. More workers are not automatically better for this peel.

GPU: no `!` on the Run path, so `./file --gpu 1GB` does not move Unsga3 work. `--gpu off` only matters if a bang exists.

---

## Oracle A/B vs C# (this tree / PR #16)

Honest dumps on this host. **No invented IGD.** Every cell is `ab/dump_bend_run.py --native` + `ab/dump_csharp_run.py` + `ab/igd_vs_pymoo.py` on the written CSVs.

| Knob | Value |
|------|--------|
| Protocol | [ab/README.md](../ab/README.md) / C# `docs/EQUIVALENCE.md` |
| Tournament | `PymooCompatible` |
| ZDT1 / ZDT2 | n=30, partitions=12, pop=52, gens=100 |
| DTLZ2 | M=3 k=10, partitions=12, pop=92, gens=150 |
| Seeds | 1–15 |
| Bend | 2.0.15, this tree `29cff2d`, `--threads` omitted (`cpu_count()` = 4) |
| C# | [AppSprout-dev/Unsga3](https://github.com/AppSprout-dev/Unsga3) `f99fdac`, `OracleCompare` Release / net10.0 |
| IGD | pymoo **0.6.2** `IGD`; ZDT analytic PF `--pf-points 500`; DTLZ2 `pf_source=pymoo-das-dennis` `--partitions 12` (`pf_rows=91`) |
| Host | 4-core Xeon (KVM), clang 18.1.3 |

`compile_s` (cold once, first ZDT1 seed=1 native miss): **5.098**. Each later seed rewrites the generated driver (seed is in the source hash) so those compiles are not `run_s`. Bend **`run_s`** is the native binary only. **C# wall_s** is the prebuilt `OracleCompare` binary (same flags). `dump_csharp_run.py` / `dotnet run` wall is ~1.4–1.9 s and is mostly host startup; it is not used as C# wall below.

Seed=1 objective rows vs main @ **dc2eccb** (worktree dumps, same `dump_bend_run.py --native` path) are **byte-identical**: ZDT1 52/52, ZDT2 33/33, DTLZ2 92/92.

C# DTLZ2 IGD on seeds 1–5 matches the published C# `docs/ORACLE-RESULTS.md` PymooCompatible table (0.00403 / 0.00567 / 0.00513 / 0.00478 / 0.00466). That is a yardstick check, not a copied Bend number.

**Collapse** (ZDT only, observational): `front_rows ≤ 10` and `IGD ≥ 0.3`. DTLZ2 had none.

### Summary

| Problem | n | median Bend IGD | median C# IGD | Bend ≤ C# IGD | Bend collapses | C# collapses | median Bend `run_s` | median C# wall_s |
|---------|--:|----------------:|--------------:|--------------:|---------------:|-------------:|--------------------:|-----------------:|
| ZDT1 | 5 | 0.083329 | 0.101950 | 4/5 | 0 | 0 | 0.759 | 0.234 |
| ZDT1 | 15 | 0.071475 | 0.082152 | 9/15 | 0 | 0 | 0.761 | 0.235 |
| ZDT2 | 5 | 0.549664 | 0.543600 | 2/5 | 3 | 3 | 1.087 | 0.222 |
| ZDT2 | 15 | 0.528767 | 0.472835 | 5/15 | 10 | 8 | 1.099 | 0.222 |
| DTLZ2 | 5 | 0.004250 | 0.004777 | 4/5 | 0 | 0 | 5.605 | 0.660 |
| DTLZ2 | 15 | 0.004243 | 0.004512 | 10/15 | 0 | 0 | 5.592 | 0.646 |

Overall Bend ≤ C# IGD: **24/45**. ZDT2 collapses on **both** sides (known remaining RNG / last-front issue; not a #16 regression — seed=1 matches main). DTLZ2 stays in the published C# band (~0.0036–0.0057). ZDT1 is stable (48–52 ND points).

### ZDT1 (p=12, pop=52, gens=100)

| seed | Bend IGD | C# IGD | Bend run_s | C# wall_s | Bend n | C# n |
|-----:|---------:|-------:|-----------:|----------:|-------:|-----:|
| 1 | 0.061603 | 0.097733 | 0.764 | 0.240 | 52 | 52 |
| 2 | 0.062526 | 0.156085 | 0.793 | 0.229 | 52 | 52 |
| 3 | 0.114314 | 0.074783 | 0.759 | 0.234 | 52 | 52 |
| 4 | 0.084756 | 0.130272 | 0.756 | 0.232 | 52 | 41 |
| 5 | 0.083329 | 0.101950 | 0.752 | 0.241 | 52 | 52 |
| 6 | 0.045916 | 0.082152 | 0.756 | 0.235 | 52 | 52 |
| 7 | 0.060659 | 0.060123 | 0.757 | 0.234 | 52 | 52 |
| 8 | 0.082262 | 0.112883 | 0.756 | 0.234 | 52 | 52 |
| 9 | 0.061749 | 0.072583 | 0.761 | 0.241 | 52 | 52 |
| 10 | 0.084640 | 0.072246 | 0.762 | 0.245 | 52 | 52 |
| 11 | 0.151236 | 0.066878 | 0.755 | 0.234 | 48 | 51 |
| 12 | 0.126977 | 0.067323 | 0.791 | 0.240 | 52 | 52 |
| 13 | 0.061183 | 0.051285 | 0.765 | 0.243 | 52 | 52 |
| 14 | 0.069462 | 0.103394 | 0.772 | 0.232 | 52 | 51 |
| 15 | 0.071475 | 0.112429 | 0.764 | 0.239 | 52 | 52 |

### ZDT2 (p=12, pop=52, gens=100)

| seed | Bend IGD | C# IGD | Bend run_s | C# wall_s | Bend n | C# n | collapse |
|-----:|---------:|-------:|-----------:|----------:|-------:|-----:|----------|
| 1 | 0.147170 | 0.111885 | 0.868 | 0.225 | 33 | 41 | |
| 2 | 0.592805 | 0.101012 | 1.488 | 0.239 | 3 | 52 | Bend |
| 3 | 0.549664 | 0.543600 | 1.343 | 0.222 | 8 | 7 | both |
| 4 | 0.150038 | 0.661220 | 0.849 | 0.219 | 31 | 2 | C# |
| 5 | 0.641379 | 0.655763 | 1.087 | 0.218 | 4 | 2 | both |
| 6 | 0.455388 | 0.645855 | 1.077 | 0.217 | 8 | 5 | both |
| 7 | 0.515859 | 0.472835 | 1.168 | 0.230 | 3 | 10 | both |
| 8 | 0.680160 | 0.695668 | 1.088 | 0.220 | 4 | 2 | both |
| 9 | 0.305638 | 0.243734 | 1.099 | 0.233 | 26 | 35 | |
| 10 | 0.528767 | 0.160180 | 1.177 | 0.232 | 7 | 41 | Bend |
| 11 | 0.699747 | 0.646897 | 1.081 | 0.217 | 3 | 2 | both |
| 12 | 0.550622 | 0.143003 | 1.425 | 0.234 | 7 | 25 | Bend |
| 13 | 0.085241 | 0.652186 | 0.850 | 0.219 | 46 | 2 | C# |
| 14 | 0.432479 | 0.351300 | 1.388 | 0.222 | 12 | 23 | |
| 15 | 0.540660 | 0.256799 | 1.267 | 0.252 | 5 | 31 | Bend |

### DTLZ2 (p=12, pop=92, gens=150)

| seed | Bend IGD | C# IGD | Bend run_s | C# wall_s | Bend n | C# n |
|-----:|---------:|-------:|-----------:|----------:|-------:|-----:|
| 1 | 0.003914 | 0.004032 | 5.522 | 0.660 | 92 | 92 |
| 2 | 0.004250 | 0.005666 | 5.605 | 0.708 | 92 | 92 |
| 3 | 0.003777 | 0.005130 | 5.580 | 0.654 | 92 | 92 |
| 4 | 0.004369 | 0.004777 | 5.654 | 0.674 | 92 | 92 |
| 5 | 0.004848 | 0.004663 | 5.622 | 0.543 | 92 | 92 |
| 6 | 0.004026 | 0.005460 | 5.678 | 0.566 | 92 | 92 |
| 7 | 0.003603 | 0.003610 | 5.702 | 0.557 | 92 | 92 |
| 8 | 0.004243 | 0.005111 | 5.563 | 0.540 | 92 | 92 |
| 9 | 0.004004 | 0.004670 | 5.575 | 0.682 | 92 | 92 |
| 10 | 0.004882 | 0.003816 | 5.721 | 0.551 | 92 | 92 |
| 11 | 0.003727 | 0.003974 | 5.533 | 0.552 | 92 | 92 |
| 12 | 0.004901 | 0.004512 | 5.592 | 0.585 | 92 | 92 |
| 13 | 0.004502 | 0.003984 | 5.540 | 0.649 | 92 | 92 |
| 14 | 0.004066 | 0.004172 | 5.547 | 0.670 | 92 | 92 |
| 15 | 0.004357 | 0.003627 | 5.597 | 0.646 | 92 | 92 |

Reproduce (one cell):

```bash
export PATH="$HOME/.bend/bin:$PATH"
export BEND_NO_TELEMETRY=1
export UNSGA3_CS_ROOT=/path/to/Unsga3   # optional; dump_csharp_run.py skips without it

python3 ab/dump_bend_run.py --native --problem dtlz2 --partitions 12 --pop 92 --gens 150 --seed 1 \
  --out ab/out/bend_dtlz2_F.csv
python3 ab/dump_csharp_run.py --problem dtlz2 --partitions 12 --pop 92 --gens 150 --seed 1 \
  --out ab/out/csharp_dtlz2_F.csv
python3 ab/igd_vs_pymoo.py --front ab/out/bend_dtlz2_F.csv --problem dtlz2 --partitions 12
python3 ab/igd_vs_pymoo.py --front ab/out/csharp_dtlz2_F.csv --problem dtlz2 --partitions 12
```
