# Array.clone / Array.fork associate bench

- host: JMac-mini.local
- uname: Darwin JMac-mini.local 27.0.0 Darwin Kernel Version 27.0.0: Tue Aug 11 21:02:57 PDT 2026; root:xnu-13432.1.9~1/RELEASE_ARM64_T8132 arm64
- bend: bend 2.0.40
- mode: binary; bang=True
- when: 2026-11-17T10:54:07
- method: median over independent process runs of (IO.now total_ms / in-process reps); +RTS --threads 1 when running a native binary

| N x R x M | variant | chunk | backend | median ms/rep | min-max | runs x reps | match_list | sum_idx | notes |
|---|---|---:|---|---:|---|---:|---|---:|---|
| 2048 x 276 x 3 | list | — | Metal/bang | 34.2000 | 34.0000-34.5000 | 3 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | clone | 32 | Metal/bang | 79.3000 | 79.3000-79.4000 | 3 x 10 | 1 | 279827 | |
