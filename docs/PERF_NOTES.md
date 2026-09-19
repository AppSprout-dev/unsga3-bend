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

Fill-in after the warm native runs below. Host: 4-core Xeon (KVM), clang 18.1.3, Bend 2.0.13. Seed=1, PymooCompatible, `--threads` = CPU count unless noted.

See the PR body / table produced by the profile script. Do not treat interpreter `bend file.bend` milliseconds as native `run_s`.

## How to reproduce

```bash
# smoke (checked-in driver)
python3 ab/profile_bend_run.py
python3 ab/profile_bend_run.py   # second call is warm (compile_s omitted)

# oracle-sized (generated driver; hash-cached)
python3 ab/profile_bend_run.py --problem dtlz2 --partitions 12 --pop 92 --gens 150 --seed 1
python3 ab/profile_bend_run.py --problem zdt1 --partitions 12 --pop 52 --gens 100 --seed 1
```
