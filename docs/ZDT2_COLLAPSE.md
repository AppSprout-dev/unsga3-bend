# ZDT2 collapse on both stacks (investigation)

Diagnosis of oracle ZDT2 (n=30, Das–Dennis **p=12**, **pop=52**, **gens=100**, `PymooCompatible`) looking messy on **both** unsga3-bend and C# [Unsga3](https://github.com/AppSprout-dev/Unsga3). This is **not** a Bend-only bug hunt. No algorithm “fix” in the PR that added this note unless a later revision finds a shared bug with a minimal patch.

**Collapse** (same observational rule as [PERF_NOTES.md](PERF_NOTES.md) / PR #16): `front_rows ≤ 10` **and** `IGD ≥ 0.3` vs the analytic 500-pt ZDT2 PF (`f2 = 1 − f1²`).

Do **not** invent IGD. Numbers below are either already recorded on `main` / PR #16, or recomputed from dumped CSVs by `ab/characterize_front.py` / `ab/igd_vs_pymoo.py`.

## Root-cause hypothesis (short)

**Shared + problem-inherent + too-short oracle budget. Not Bend-specific.**

1. **Geometry.** ZDT2’s concave PF (`f2 = 1 − f1²`) plus early `g ≫ x0` makes `f2 ≈ g`, so last-front niching / tournament barely see `x0`. By **gen 10** every stack we dumped (Bend, C#, pymoo 0.6.2) is already a **few points near `f1≈0`** (axis pile, not a healthy interior ray).
2. **Budget.** Oracle **gens=100** is a premature snapshot. The same PymooCompatible protocol at **gens=250** recovered **all four probe seeds on all three stacks** (Bend/C# IGD ≈ 0.017–0.043, 52 ND pts; pymoo IGD ≈ 0.031–0.045, 13 ND pts = one per Das–Dennis ray). **gens=150** (C# ZDT2 smoke length) is mid-recovery: some seeds are already spread, seed 11 still has `f1_max ≈ 0.21`.
3. **RNG / extras explain which seed is ugly at 100, not the phenomenon.** C# and Bend collapse **different** seeds at 100 gens (PR #16: 10/15 vs 8/15). pymoo seed 1 **also** collapses at 100 (2 pts, IGD 0.499) while Bend/C# seed 1 are the healthier pair.
4. **Tournament is a lever, not a root bug.** C#’s unpublished Wilcoxon ZDT2 protocol is **RankNicheDistance** (ctor default), not PymooCompatible. On the four probe seeds at 100 gens, RankNicheDistance **cleared Bend collapse** (seed 2: 3→52 pts, IGD 0.593→0.079). C# was mixed (seed 11 saved, seed 2 got *worse* than PymooCompatible).

ZDT1 and DTLZ2 stay stable at the published 100/150-gen budgets. C# never published a ZDT2 oracle / Wilcoxon table; the smoke bar is `IGD < 0.75`.

Bend’s PR #7 near-ray extras rescued **seed=1** after uniform `inNiche[Next]` + LCG. They do **not** stop multi-seed collapse at 100 gens. C# still uses uniform extras and still collapses 8/15 seeds at that budget.

## What the collapsed front looks like

From PR #7 (Bend, post-#6 uniform extras, seed=1): **2** ND points near **`f1≈0`, `f2≈1.05–1.06`**, IGD≈0.639 — a pile at the **left axis extreme**, not a spread along one interior ray. Pre-#6 deterministic niching on the same seed: ~50 pts, IGD≈0.094.

PR #16 15-seed table (PymooCompatible, gens=100) — **cite only**, not re-invented:

| seed | Bend n / IGD | C# n / IGD | collapse |
|-----:|-------------:|-----------:|----------|
| 1 | 33 / 0.147170 | 41 / 0.111885 | (healthier) |
| 2 | 3 / 0.592805 | 52 / 0.101012 | Bend only |
| 7 | 3 / 0.515859 | 10 / 0.472835 | both |
| 11 | 3 / 0.699747 | 2 / 0.646897 | both |
| 4 | 31 / 0.150038 | 2 / 0.661220 | C# only |
| 13 | 46 / 0.085241 | 2 / 0.652186 | C# only |

Full 1–15: [PERF_NOTES.md](PERF_NOTES.md#zdt2-p12-pop52-gens100). Bend 10/15, C# 8/15. Some only one side.

**Shape (this investigation):** collapsed ND fronts are a **left-axis pile** — a handful of points with `f1` at ~0 and `f2` just above 1 (still `g>1`). Example seed **11**, gens=100, PymooCompatible:

```
# Bend (3 pts, IGD 0.700)
3.58e-13, 1.151
3.49e-13, 1.157
3.49e-13, 1.176

# C# (2 pts, IGD 0.647)
0,        1.079
7.88e-17, 1.070

# pymoo seed 1 (2 pts, IGD 0.499) — same pile, one slightly larger f1
2.25e-17, 1.056
0.199,    1.035
```

Healthy seed **1** Bend at 100 gens spans `f1` ≈ 0 … 0.91 (33 pts). Raw Das–Dennis association of a piled front is **one ray** (ref 0 = `(0,1)`). After min–max normalize a 1e-13 `f1` span, the histogram is noise — do not read that as diversity.

Dumps: `ab/out/zdt2_probe/` (gitignored). `ab/characterize_front.py`.

## Is concave ZDT2 known to stress NSGA-III / U-NSGA-III?

Yes, as **geometry + niching**, not as “ZDT2 is unsolvable.”

- **ZDT2 PF is non-convex (concave):** `f2 = 1 − f1²` (pymoo / Deb). ZDT1 is convex: `f2 = 1 − √f1`.
- **Das–Dennis 2-obj p=12** is 13 rays on the unit simplex (`(k/12, 1−k/12)`). A **true** analytic ZDT2 PF occupies **many** of those rays (`ab/zdt2_geometry.py`). Collapse is **not** “the PF only maps to one ray.”
- On the PF with `g=1`, ZDT1 has `f1+f2 ≤ 1` (inside the simplex). ZDT2 has `f1+f2 = 1 + f1(1−f1) > 1` in the open interval (outside / farther from the origin). After intercept normalization the association still works if `f1` is spread; it fails when the **search** loses `x0` diversity.
- Early ZDT2: `f2 = g·(1 − (x0/g)²) ≈ g` when `g ≫ x0`, so `f2` barely depends on `x0`. ZDT1’s `f2 = g − √(g·x0)` keeps `x0` visible. Weak `x0` pressure + last-front extras can drop large-`x0` members before `g` converges.
- **NSGA-III** (Deb & Jain 2014) associates to rays and fills **under-represented** niches — it preserves direction coverage, not arc-length on a concave curve.
- **U-NSGA-III** (Seada & Deb, COIN 2014022 / TEVC 2016) treats ZDT1/ZDT2 as easy bi-objective cases and uses tournament pressure. The paper’s ZDT2 plots use longer runs / fold settings (`N` vs `H`); it does **not** claim oracle `p=12 pop=52 gens=100` robustness. pymoo `UNSGA3` is that tournament (`comp_by_rank_and_ref_line_dist` = our `PymooCompatible`).
- Irregular-front literature (e.g. adaptive refs on inverted/disconnected PFs) notes unused Das–Dennis points and pile-up on “popular” rays. ZDT2 is a mild version of that mismatch.

C# library signals the same:

- `docs/ORACLE-RESULTS.md` / `WILCOXON-RESULTS.md`: **ZDT1 + DTLZ2 only**.
- `tools/oracle/run_multiseed_wilcoxon.py` **defines** a ZDT2 protocol (`p=12 pop=52 gens=100`, **RankNicheDistance**, not PymooCompatible) but those results were never published.
- `IgdSmokeTests.Zdt2_runs_with_measurable_igd`: seed **2**, **150** gens, **default RankNicheDistance**, bar **`IGD < 0.75`** — “non-convex; not oracle parity.”

## Shared algorithm causes (C# vs Bend)

| Piece | C# (`f99fdac`) | Bend (`main` @ 9ea29d6 / #16) | Role in collapse |
|-------|----------------|-------------------------------|------------------|
| ZDT2 Evaluate | `f1=x0`, `f2=g(1−(x0/g)²)` | same | Match. Not a port bug. |
| Das–Dennis / associate | perp. distance to rays | same formula | Shared. |
| Normalization | persistent ideal, ND ASF extremes, intercepts | ported | Shared; not isolated here. |
| Last-front **empty** niche | closest unused | closest unused | Shared. |
| Last-front **extra** | **uniform** `inNiche[rng.Next]` | **near-best** (`dist ≤ 2×best+0.01`), then random | **Intentional Bend delta** (PR #7). C# still uniform. Both still collapse often. |
| Min-count ref pick | random among ties if `rng` | same | Shared. |
| Tournament A/B | `--pymoo-mode` → PymooCompatible | `Tour.pymoo()` | Shared for the 15-seed table. |
| Tournament C# default | RankNicheDistance | implemented, not A/B default | See probes. |
| G12 dups | 12-decimal decision keys | same | PR #7: elim_dups **off** still collapsed (1 pt, IGD≈0.695). Not the cause. |
| RNG | `System.Random` | portable LCG | Explains **which** seeds die, not **that** they die. |

PR #7 (Bend-only at the time): between gens **5–10**, `f1` max **0.93 → 0.009** with uniform extras + LCG. Deterministic niching restored seed=1. Always-closest extras restored ZDT2 but **worsened ZDT1** (IGD 0.146 vs 0.087). So “always closest” is not a free shared fix.

## Prior probes (gens=250, RankNicheDistance)

**Not in repo/docs before this note** (searched `docs/`, `ab/`, PRs, C# `docs/` / smoke). This PR **ran them**.

| Probe | Where / this PR | What it found |
|-------|-----------------|---------------|
| gens=100, PymooCompatible, seeds 1–15 | PERF_NOTES / PR #16 | Bend 10/15 collapse, C# 8/15; seed 1 healthier |
| gens ~5–10, Bend uniform extras, seed=1 | PR #7 | Early `x0` death (`f1` max 0.93→0.009) |
| gens=10, PymooCompatible, seeds 1/2/7/11 | **this PR**, all 3 stacks | **All** piled near `f1≈0` (early, not stack-specific) |
| gens=150, RankNicheDistance, C# seed=2 | `IgdSmokeTests` | Loose `IGD<0.75` only |
| gens=150, PymooCompatible, seeds 2/7/11 | **this PR** | Mid-recovery (seed 2 often spread; seed 11 still `f1_max≈0.21`) |
| gens=250, PymooCompatible, seeds 1/2/7/11 | **this PR** | **Recovered on Bend, C#, and pymoo** |
| RankNicheDistance, gens=100, seeds 1/2/7/11 | **this PR** | Bend: all 4 spread. C#: mixed (11 saved, 2 worse than PymooCompatible) |
| C# Wilcoxon ZDT2 | script only, unpublished | Protocol = RankNicheDistance, 100 gens |

## Measured fronts (this PR)

Host: 4-core, Bend **2.0.16** `--native`, C# Unsga3 **`f99fdac`** (`UNSGA3_CS_ROOT` outside this repo), pymoo **0.6.2** `UNSGA3`. IGD = pymoo `IGD` vs analytic ZDT2 **500** pts. Collapse rule: `n≤10` and `IGD≥0.3`.

Dumps: `python3 ab/zdt2_collapse_probe.py`. JSONL under `ab/out/zdt2_probe/` (gitignored).

### Geometry (no Run)

`python3 ab/zdt2_geometry.py` — analytic 500-pt PF vs p=12 rays (13 dirs). Both PFs occupy **all 13** refs. ZDT1 `f1+f2` ∈ [0.75, 1] (inside simplex). ZDT2 `f1+f2` ∈ [1, 1.25] (outside; peak at mid-front). Collapse is a **search** failure, not “the PF is one ray.”

### Time series — PymooCompatible (p=12, pop=52)

| stack | seed | g=10 n / IGD / f1max | g=50 | g=100 | g=150 | g=250 |
|-------|-----:|----------------------|------|-------|-------|-------|
| Bend | 1 | 8 / 2.785 / 0.031 **coll** | 18 / 0.802 / 0.964 | 33 / 0.147 / 0.914 | — | 52 / 0.025 / 1.000 |
| Bend | 2 | 6 / 2.701 / 0.011 **coll** | 3 / 1.129 / 0.000 **coll** | 3 / 0.593 / 0.074 **coll** | 52 / 0.138 / 0.644 | 52 / 0.026 / 1.000 |
| Bend | 7 | 9 / 2.294 / 0.082 **coll** | 11 / 0.985 / 0.000 | 3 / 0.516 / 0.165 **coll** | 52 / 0.289 / 0.406 | 52 / 0.022 / 0.999 |
| Bend | 11 | 6 / 2.501 / 0.023 **coll** | 8 / 1.199 / 0.000 **coll** | 3 / 0.700 / 0.000 **coll** | 31 / 0.426 / 0.235 | 52 / 0.033 / 0.862 |
| C# | 1 | 9 / 2.199 / 0.268 **coll** | 12 / 0.742 / 0.726 | 41 / 0.112 / 0.959 | — | 52 / 0.019 / 1.000 |
| C# | 2 | 5 / 2.327 / 0.146 **coll** | 14 / 0.567 / 0.904 | 52 / 0.101 / 0.992 | 52 / 0.032 / 0.994 | 52 / 0.018 / 1.000 |
| C# | 7 | 7 / 2.380 / 0.190 **coll** | 6 / 1.048 / 0.000 **coll** | 10 / 0.473 / 0.242 **coll** | 52 / 0.073 / 0.773 | 52 / 0.017 / 1.000 |
| C# | 11 | 4 / 2.783 / 0.040 **coll** | 5 / 1.083 / 0.000 **coll** | 2 / 0.647 / 0.000 **coll** | 37 / 0.440 / 0.208 | 52 / 0.043 / 0.849 |
| pymoo | 1 | 3 / 2.694 / 0.076 **coll** | 2 / 0.898 / 0.000 **coll** | 2 / 0.499 / 0.199 **coll** | — | 13 / 0.031 / 0.999 |
| pymoo | 2 | 4 / 2.173 / 0.321 **coll** | 2 / 1.087 / 0.000 **coll** | 2 / 0.636 / 0.000 **coll** | — | 13 / 0.045 / 0.851 |
| pymoo | 7 | 3 / 2.620 / 0.061 **coll** | 2 / 1.148 / 0.000 **coll** | 4 / 0.559 / 0.158 **coll** | — | 13 / 0.032 / 0.935 |
| pymoo | 11 | 2 / 2.573 / 0.934 **coll** | 5 / 0.582 / 0.895 **coll** | 7 / 0.135 / 0.995 | — | 13 / 0.031 / 1.000 |

g=100 Bend/C# IGD matches PR #16 (same fronts). g=10: **every** stack is an `f1≈0` pile. Recovery is **late** (100→250), not “stuck forever.” pymoo’s recovered n=13 is one point per ray (NSGA-III-typical); Bend/C# keep the extra 52−13 members on the PF.

### RankNicheDistance vs PymooCompatible at gens=100

C# Wilcoxon ZDT2 protocol = RankNicheDistance. Same four seeds:

| seed | Bend Pymoo n / IGD | Bend RankNiche | C# Pymoo | C# RankNiche |
|-----:|-------------------:|---------------:|---------:|-------------:|
| 1 | 33 / 0.147 | 50 / 0.103 | 41 / 0.112 | 52 / 0.049 |
| 2 | 3 / 0.593 **coll** | 52 / 0.079 | 52 / 0.101 | 11 / 0.517 |
| 7 | 3 / 0.516 **coll** | 52 / 0.126 | 10 / 0.473 **coll** | 16 / 0.406 |
| 11 | 3 / 0.700 **coll** | 38 / 0.153 | 2 / 0.647 **coll** | 52 / 0.058 |

Bend RankNicheDistance cleared these four at 100 gens. C# RankNicheDistance is **not** a free win (seed 2 worse than PymooCompatible). Tournament changes which streams look healthy at the oracle budget; it does not remove the early pile.

## Recommended next experiments (no silent “fix”)

1. **If ZDT2 A/B should look like ZDT1 at 100 gens:** try the C# Wilcoxon ZDT2 settings — **RankNicheDistance** and/or **gens=250** — on seeds 1–15 (both stacks + pymoo). Do not change last-front extras from seed=1 alone (PR #7 ZDT1 regression).
2. **15-seed gens=250 PymooCompatible** — this PR only did seeds 1/2/7/11. Confirm the 10/15 “collapse” rate drops before calling 100 gens a Bend bug.
3. **ZDT1 at gens=10** as a control (expect `f1` span stays large). Not run here.
4. **Do not** ship always-closest extras without re-checking ZDT1 / DTLZ2 (PR #7 tradeoff).
5. If a later PR changes niching or the oracle gens, require ZDT1 + DTLZ2 + ZDT2 multi-seed, not seed=1 alone.

## How to reproduce

```bash
export PATH="$HOME/.bend/bin:$HOME/.dotnet:$PATH"
export BEND_NO_TELEMETRY=1
export DOTNET_ROOT="$HOME/.dotnet"
# C# checkout *outside* this repo (do not merge stacks)
export UNSGA3_CS_ROOT=/path/to/Unsga3   # e.g. f99fdac

python3 ab/zdt2_geometry.py
python3 ab/zdt2_collapse_probe.py --stacks bend csharp pymoo \
  --seeds 1 2 7 11 --gens 10 50 100 250 --tournament pymoo
python3 ab/zdt2_collapse_probe.py --stacks bend csharp \
  --seeds 1 2 7 11 --gens 100 --tournament rank_niche
python3 ab/characterize_front.py --front ab/out/zdt2_probe/bend_zdt2_p12_pop52_g100_s11_pymoo_F.csv --problem zdt2
```

`dump_csharp_run.py` / the csharp stack skip (exit 0) without `UNSGA3_CS_ROOT` / `dotnet`. The pymoo stack skips without pymoo. Do not invent a front or IGD.

Diagnostic flags (no math change): `ab/dump_bend_run.py --tournament rank_niche`, `ab/dump_csharp_run.py --tournament rank_niche`, `--no-elim-dups` on the Bend dumper.
