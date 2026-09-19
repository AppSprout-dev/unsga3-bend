# ZDT2 collapse on both stacks (investigation)

Diagnosis of oracle ZDT2 (n=30, Das–Dennis **p=12**, **pop=52**, **gens=100**, `PymooCompatible`) looking messy on **both** unsga3-bend and C# [Unsga3](https://github.com/AppSprout-dev/Unsga3). This is **not** a Bend-only bug hunt. No algorithm “fix” in the PR that added this note unless a later revision finds a shared bug with a minimal patch.

**Collapse** (same observational rule as [PERF_NOTES.md](PERF_NOTES.md) / PR #16): `front_rows ≤ 10` **and** `IGD ≥ 0.3` vs the analytic 500-pt ZDT2 PF (`f2 = 1 − f1²`).

Do **not** invent IGD. Numbers below are either already recorded on `main` / PR #16, or recomputed from dumped CSVs by `ab/characterize_front.py` / `ab/igd_vs_pymoo.py`.

## Root-cause hypothesis (short)

**Shared + problem-inherent, not Bend-specific.** U-NSGA-III last-front niching + Das–Dennis rays on ZDT2’s **concave** PF lose `x0` (hence `f1`) diversity on many RNG streams. C# `System.Random` and Bend’s LCG collapse **different seeds**, so this is not “Bend LCG is broken.” ZDT1 (convex) and DTLZ2 (3-obj sphere) stay stable on the same protocol. C# never published a ZDT2 Wilcoxon / oracle table; the smoke bar is `IGD < 0.75`.

Bend-specific extras (`2×best+0.01` near-ray filter from PR #7) rescued **seed=1** after uniform `inNiche[Next]` + LCG piled the front at `f1≈0`. They do **not** stop multi-seed collapse. C# still uses uniform `inNiche[rng.Next]` and still collapses 8/15 seeds.

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

**Shape (this investigation):** see [Measured fronts](#measured-fronts-this-pr) — dumped CSVs under `ab/out/zdt2_probe/` (gitignored). Characterization: `n`, `f1` span, counts with `f1<0.05` vs `f1>0.95`, Das–Dennis association histogram (raw + min–max), `shape` (`pile_at_f1_near_0` / `two_extremes_only` / `one_ray` / `spread`).

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

**Not in repo/docs before this note.** Searched `docs/`, `ab/`, PRs, C# `docs/` and smoke tests.

What **is** in tree / C#:

| Probe | Where | What it found |
|-------|--------|----------------|
| gens=100, PymooCompatible, seeds 1–15 | PERF_NOTES / PR #16 | Bend 10/15 collapse, C# 8/15; seed 1 healthier |
| gens ~5–10, Bend uniform extras, seed=1 | PR #7 | Early `x0` death |
| gens=150, RankNicheDistance, C# seed=2 | `IgdSmokeTests` | Loose `IGD<0.75` only (not a published front) |
| C# Wilcoxon ZDT2 | script only, unpublished | Protocol = RankNicheDistance, 100 gens |

This PR’s dumps (when present): [Measured fronts](#measured-fronts-this-pr).

## Measured fronts (this PR)

Dumps: `python3 ab/zdt2_collapse_probe.py` (Bend `--native`, optional `UNSGA3_CS_ROOT` + pymoo). Characterization: `python3 ab/characterize_front.py --front … --problem zdt2`.

*Filled after the probe runs on this agent. Until then, use the PR #16 table above — do not invent new IGD.*

### Geometry (no Run)

`python3 ab/zdt2_geometry.py` — analytic 500-pt PF vs p=12 rays (13 dirs). Both PFs occupy **all 13** refs. ZDT1 `f1+f2` ∈ [0.75, 1] (inside simplex). ZDT2 `f1+f2` ∈ [1, 1.25] (outside; peak at mid-front). Collapse is therefore a **search** failure, not “the PF is one ray.”

### Time series / RankNiche / gens=250 / pymoo

See probe JSONL (`ab/out/zdt2_probe/summary.jsonl`, gitignored) and the filled table in the revision that ran the dumps.

## Recommended next experiments (no silent “fix”)

1. **Confirm recovery is hard after early `x0` death** — if gens=10 already has `f1_max < 0.05`, gens=250 will not rebuild the PF (SBX/PM from a piled parent set).
2. **RankNicheDistance vs PymooCompatible** on the same seeds (C# Wilcoxon protocol for ZDT2). If both modes collapse, mating pressure is not the main lever.
3. **pymoo `UNSGA3`** on the same `p=12 pop=52 gens=100` seeds. If pymoo is stable, look at C#/Bend extras + RNG + G12. If pymoo also dies, the **protocol** (13 rays, 4× fold, 100 gens) is the story.
4. **Do not** ship always-closest extras without re-checking ZDT1 / DTLZ2 (PR #7 tradeoff).
5. If a later PR changes niching, require ZDT1 + DTLZ2 + ZDT2 multi-seed, not seed=1 alone.

## How to reproduce

```bash
export PATH="$HOME/.bend/bin:$HOME/.dotnet:$PATH"
export BEND_NO_TELEMETRY=1
export DOTNET_ROOT="$HOME/.dotnet"
# C# checkout *outside* this repo (do not merge stacks)
export UNSGA3_CS_ROOT=/path/to/Unsga3   # e.g. f99fdac

python3 ab/zdt2_geometry.py
python3 ab/zdt2_collapse_probe.py --stacks bend csharp pymoo \
  --seeds 1 2 7 11 --gens 10 50 100 --tournament pymoo
python3 ab/characterize_front.py --front ab/out/zdt2_probe/bend_zdt2_p12_pop52_g100_s1_pymoo_F.csv --problem zdt2
```

`dump_csharp_run.py` / the csharp stack skip (exit 0) without `UNSGA3_CS_ROOT` / `dotnet`. The pymoo stack skips without pymoo. Do not invent a front or IGD.

Diagnostic flags (no math change): `ab/dump_bend_run.py --tournament rank_niche`, `ab/dump_csharp_run.py --tournament rank_niche`, `--no-elim-dups` on the Bend dumper.
