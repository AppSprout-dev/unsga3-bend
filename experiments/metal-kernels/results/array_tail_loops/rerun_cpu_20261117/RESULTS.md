# Array.clone / Array.fork associate bench

- host: JMac-mini.local
- uname: Darwin JMac-mini.local 27.0.0 Darwin Kernel Version 27.0.0: Tue Aug 11 21:02:57 PDT 2026; root:xnu-13432.1.9~1/RELEASE_ARM64_T8132 arm64
- bend: bend 2.0.40
- mode: binary; bang=False
- when: 2026-11-17T10:49:57
- method: median over independent process runs of (IO.now total_ms / in-process reps); +RTS --threads 1 when running a native binary

| N x R x M | variant | chunk | backend | median ms/rep | min-max | runs x reps | match_list | sum_idx | notes |
|---|---|---:|---|---:|---|---:|---|---:|---|
| 184 x 91 x 3 | list | — | CPU | 0.4125 | 0.4000-0.4125 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | clone | 1 | CPU | 2.5375 | 2.4625-2.5375 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | clone | 32 | CPU | 2.1375 | 2.1000-2.1875 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | clone | 128 | CPU | 1.8500 | 1.7750-1.8875 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | fork | 1 | CPU | 3.4125 | 3.3875-3.5250 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | fork | 32 | CPU | 3.4000 | 3.3625-3.4750 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | fork | 128 | CPU | 3.4125 | 3.3500-3.4125 | 5 x 80 | 1 | 8819 | |
| 2048 x 276 x 3 | list | — | CPU | 12.7000 | 12.6000-13.0000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | clone | 1 | CPU | 73.5000 | 72.7000-73.7000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | clone | 32 | CPU | 56.9000 | 56.7000-57.3000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | clone | 128 | CPU | 62.1000 | 61.8000-62.4000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | fork | 1 | CPU | 114.6000 | 114.4000-118.0000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | fork | 32 | CPU | 113.9000 | 112.9000-116.5000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | fork | 128 | CPU | 113.7000 | 113.2000-113.8000 | 5 x 10 | 1 | 279827 | |
