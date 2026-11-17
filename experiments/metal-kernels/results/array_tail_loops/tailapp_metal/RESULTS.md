# Array.clone / Array.fork associate bench

- host: JMac-mini.local
- uname: Darwin JMac-mini.local 27.0.0 Darwin Kernel Version 27.0.0: Tue Aug 11 21:02:57 PDT 2026; root:xnu-13432.1.9~1/RELEASE_ARM64_T8132 arm64
- bend: bend 2.0.40
- mode: binary; bang=True
- when: 2026-11-17T10:54:24
- method: median over independent process runs of (IO.now total_ms / in-process reps); +RTS --threads 1 when running a native binary

| N x R x M | variant | chunk | backend | median ms/rep | min-max | runs x reps | match_list | sum_idx | notes |
|---|---|---:|---|---:|---|---:|---|---:|---|
| 184 x 91 x 3 | list | — | Metal/bang | 5.8125 | 5.7125-5.8250 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | clone | 1 | Metal/bang | 10.5000 | 10.4875-10.5625 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | clone | 32 | Metal/bang | 16.3125 | 16.3000-16.3125 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | clone | 128 | Metal/bang | 39.5375 | 39.4625-39.5625 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | fork | 1 | Metal/bang | 68.0625 | 67.9875-68.1000 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | fork | 32 | Metal/bang | 60.3250 | 60.3000-60.4000 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | fork | 128 | Metal/bang | 58.4000 | 58.3625-58.4375 | 5 x 80 | 1 | 8819 | |
| 2048 x 276 x 3 | list | — | Metal/bang | 34.6000 | 34.4000-34.7000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | clone | 1 | Metal/bang | 50.2000 | 50.1000-50.3000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | clone | 32 | Metal/bang | 79.3000 | 79.3000-79.4000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | clone | 128 | Metal/bang | 198.7000 | 198.6000-198.8000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | fork | 1 | Metal/bang | 1969.5000 | 1968.5000-1969.7000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | fork | 32 | Metal/bang | 1875.5000 | 1875.1000-1876.7000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | fork | 128 | Metal/bang | 1854.6000 | 1854.2000-1855.3000 | 5 x 10 | 1 | 279827 | |
