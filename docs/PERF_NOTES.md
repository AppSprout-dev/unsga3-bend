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
| `List.get` in a hot index loop | cons walk (Base) | NDS peel + tournament indexing |
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

Why the peel is expensive on this tree (guide-backed, not a silent rewrite): `NDS.sort` = `peel` of remaining indices; each peel `split_walk`s every leftover candidate; `is_dominated` is a sequential OR so a first hit skips; each compare is `List.get` on a cons list (Base). Mid-split `a b = f(lo) f(hi)` parallelizes candidates, but each fork still pays `take`/`drop` and `List.get` into the shared pop. `bend guide shaders`: an `Array` cannot ride a fork tree. That is the measured cost, not a missed `-O` flag (Bend 2.0.13 has none).

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
