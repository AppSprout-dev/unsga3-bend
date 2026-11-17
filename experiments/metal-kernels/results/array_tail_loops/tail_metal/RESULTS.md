# Array.clone / Array.fork associate bench

- host: JMac-mini.local
- uname: Darwin JMac-mini.local 27.0.0 Darwin Kernel Version 27.0.0: Tue Aug 11 21:02:57 PDT 2026; root:xnu-13432.1.9~1/RELEASE_ARM64_T8132 arm64
- bend: bend 2.0.40
- mode: binary; bang=True
- when: 2026-11-17T10:51:12
- method: median over independent process runs of (IO.now total_ms / in-process reps); +RTS --threads 1 when running a native binary

| N x R x M | variant | chunk | backend | median ms/rep | min-max | runs x reps | match_list | sum_idx | notes |
|---|---|---:|---|---:|---|---:|---|---:|---|
| 184 x 91 x 3 | list | — | Metal/bang | 5.6500 | 5.6250-5.7375 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | clone | 1 | Metal/bang | 10.4375 | 10.4000-10.5125 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | clone | 32 | Metal/bang | 15.8750 | 15.8500-15.9000 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | clone | 128 | Metal/bang | 38.5375 | 38.4250-38.5875 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | fork | 1 | Metal/bang | 66.1500 | 66.0750-66.1875 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | fork | 32 | Metal/bang | 58.4125 | 58.3500-58.4375 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | fork | 128 | Metal/bang | 56.5375 | 56.5125-56.5750 | 5 x 80 | 1 | 8819 | |
| 2048 x 276 x 3 | list | — | Metal/bang |  |  |  | None | None | run_failed rc=1: bend: memory fault (machine stack overflow?)
 |
| 2048 x 276 x 3 | clone | 1 | Metal/bang |  |  |  | None | None | run_failed rc=1: bend: memory fault (machine stack overflow?)
 |
| 2048 x 276 x 3 | clone | 32 | Metal/bang |  |  |  | None | None | run_failed rc=1: bend: memory fault (machine stack overflow?)
 |
| 2048 x 276 x 3 | clone | 128 | Metal/bang |  |  |  | None | None | run_failed rc=1: bend: memory fault (machine stack overflow?)
 |
| 2048 x 276 x 3 | fork | 1 | Metal/bang |  |  |  | None | None | run_failed rc=1: bend: memory fault (machine stack overflow?)
 |
| 2048 x 276 x 3 | fork | 32 | Metal/bang |  |  |  | None | None | run_failed rc=1: bend: memory fault (machine stack overflow?)
 |
| 2048 x 276 x 3 | fork | 128 | Metal/bang |  |  |  | None | None | run_failed rc=1: bend: memory fault (machine stack overflow?)
 |
