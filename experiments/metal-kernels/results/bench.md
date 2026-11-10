| size (N x R x M) | impl | e2e (ms) | e2e min-max (ms) | kernel-only (ms) | reps | sum_idx | ok |
|---|---|---:|---|---:|---:|---:|---|
| 184x91x3 | hand_msl | 0.3650 | 0.3350-0.3690 | 0.1158 | 7 | 8819 | True |
| 2048x276x3 | hand_msl | 0.3920 | 0.3840-0.4330 | 0.2163 | 7 | 279827 | True |
| 32000x3003x3 | hand_msl | 7.9340 | 7.9280-10.5770 | 7.6746 | 5 | 47882676 | True |
| 8x5x3 | hand_msl | 3.3190 | 3.3190-3.3190 | 0.0109 | 1 | 23 | True |
| 184x91x3 | bend_bang | 1.0000 | total_ms=7 over 7 in-process reps (Bend IO.now) | n/a | 7 | 8819 | None |
| 184x91x3 | bend_bang | 6.5500 | total_ms=131 over 20 in-process reps (Bend IO.now) | n/a | 20 | 8819 | None |
| 184x91x3 | bend_bang | 0.1400 | total_ms=7 over 50 in-process reps (Bend IO.now) | n/a | 50 | 8819 | None |
| 2048x276x3 | bend_bang |  | total_ms=None over None in-process reps (Bend IO.now) | n/a | None | None | None |
| NonexNonexNone | bend_bang_n2048r276_fw |  | total_ms=None over None in-process reps (Bend IO.now) | n/a | None | None | None |
| NonexNonexNone | bend_bang_n32kr3003 |  | total_ms=None over None in-process reps (Bend IO.now) | n/a | None | None | None |
| NonexNonexNone | bend_bang_n32kr3003_fw |  | total_ms=None over None in-process reps (Bend IO.now) | n/a | None | None | None |
| 184x91x3 | bend_bang | 0.0000 | total_ms=0 over 7 in-process reps (Bend IO.now) | n/a | 7 | 8819 | None |
| 184x91x3 | bend_bang | 0.5000 | total_ms=10 over 20 in-process reps (Bend IO.now) | n/a | 20 | 8819 | None |
| 184x91x3 | bend_bang | 0.0000 | total_ms=0 over 50 in-process reps (Bend IO.now) | n/a | 50 | 8819 | None |
| 2048x276x3 | bend_bang | 2.0000 | total_ms=14 over 7 in-process reps (Bend IO.now) | n/a | 7 | 279827 | None |
| 2048x276x3 | bend_bang | 18.6250 | total_ms=149 over 8 in-process reps (Bend IO.now) | n/a | 8 | 279827 | None |
| 32000x3003x3 | bend_bang | 2004.0000 | total_ms=2004 over 1 in-process reps (Bend IO.now) | n/a | 1 | 47882676 | None |
| 32000x3003x3 | bend_bang | 2235.5000 | total_ms=4471 over 2 in-process reps (Bend IO.now) | n/a | 2 | 47882676 | None |
| 184x91x3 | bend_product | 0.0000 | total_ms=0 over 7 in-process reps (Bend IO.now) | n/a | 7 | 8819 | None |
| 184x91x3 | bend_product | 0.5500 | total_ms=44 over 80 in-process reps (Bend IO.now) | n/a | 80 | 8819 | None |
| 184x91x3 | bend_product | 0.0025 | total_ms=1 over 400 in-process reps (Bend IO.now) | n/a | 400 | 8819 | None |
| 2048x276x3 | bend_product | 1.7143 | total_ms=12 over 7 in-process reps (Bend IO.now) | n/a | 7 | 279827 | None |
| 2048x276x3 | bend_product | 19.8000 | total_ms=198 over 10 in-process reps (Bend IO.now) | n/a | 10 | 279827 | None |
| 2048x276x3 | bend_product | 0.4000 | total_ms=12 over 30 in-process reps (Bend IO.now) | n/a | 30 | 279827 | None |
| 32000x3003x3 | bend_product | 671.6667 | total_ms=2015 over 3 in-process reps (Bend IO.now) | n/a | 3 | 47882676 | None |
| 32000x3003x3 | bend_product | 2195.3333 | total_ms=6586 over 3 in-process reps (Bend IO.now) | n/a | 3 | 47882676 | None |
