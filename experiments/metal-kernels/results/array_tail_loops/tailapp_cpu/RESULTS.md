# Array.clone / Array.fork associate bench

- host: JMac-mini.local
- uname: Darwin JMac-mini.local 27.0.0 Darwin Kernel Version 27.0.0: Tue Aug 11 21:02:57 PDT 2026; root:xnu-13432.1.9~1/RELEASE_ARM64_T8132 arm64
- bend: bend 2.0.40
- mode: binary; bang=False
- when: 2026-11-17T11:02:19
- method: median over independent process runs of (IO.now total_ms / in-process reps); +RTS --threads 1 when running a native binary

| N x R x M | variant | chunk | backend | median ms/rep | min-max | runs x reps | match_list | sum_idx | notes |
|---|---|---:|---|---:|---|---:|---|---:|---|
| 184 x 91 x 3 | list | — | CPU | 0.3875 | 0.3875-0.4000 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | clone | 1 | CPU | 0.9625 | 0.9375-1.0375 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | clone | 32 | CPU | 0.1750 | 0.1750-0.1875 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | clone | 128 | CPU | 0.1500 | 0.1375-0.1625 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | fork | 1 | CPU | 0.1750 | 0.1750-0.1750 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | fork | 32 | CPU | 0.1625 | 0.1625-0.1750 | 5 x 80 | 1 | 8819 | |
| 184 x 91 x 3 | fork | 128 | CPU | 0.1500 | 0.1500-0.1500 | 5 x 80 | 1 | 8819 | |
| 2048 x 276 x 3 | list | — | CPU | 12.5000 | 12.4000-12.8000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | clone | 1 | CPU | 22.0000 | 22.0000-22.5000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | clone | 32 | CPU | 4.8000 | 4.8000-5.0000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | clone | 128 | CPU | 4.3000 | 4.3000-4.4000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | fork | 1 | CPU | 4.9000 | 4.9000-5.0000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | fork | 32 | CPU | 4.7000 | 4.6000-4.8000 | 5 x 10 | 1 | 279827 | |
| 2048 x 276 x 3 | fork | 128 | CPU | 4.6000 | 4.6000-4.7000 | 5 x 10 | 1 | 279827 | |
