# Niche-count histogram conservation

Selected statement: `Laws.niche_count_sum` in [`LAWS.bend`](../LAWS.bend), closed by `def Laws.niche_count_sum` in [`PROOF.bend`](../PROOF.bend).

`proof_surface: Bend PROOF`.

## What this statement asserts

For every assignment list `asgs` and every bin count `n_dirs`:

```text
nats_sum(count_raw.go(n_dirs, |asgs|, asgs)) == in_bin_count(asgs, n_dirs)
```

`count_raw.go` in [`src/survival.bend`](../src/survival.bend) builds the niche-count histogram by a mid-split (`List.take` / `List.drop`, then `nats_add`). `in_bin_count` counts assignments whose `reference_index` is `< n_dirs` (`bin_hit`). `inc_at` / `List.set` leaves an index `>= n_dirs` unchanged, so an out-of-range ref does not increment a bin. When every ref is in range, the sum is `|asgs|`. The equality is on `Nat`. It does not mention `F32` or the RNG.

The challenge file restates that proposition and leaves it open. The closure is the named def in `PROOF.bend`. Running `bend` on the challenge file reports one `?TODO`. That hole is the fixture. It is not a second proof.

## Outside this statement

- Niche-tie policy: which min-count niche is chosen, rng among ties, lowest index, empty-niche closest member, or the 2×best extras draw.
- ASF / perpendicular-distance geometry, intercepts, and the normalization hyperplane.
- Simplex membership of Das–Dennis reference directions.
- IGD, hypervolume, or any oracle table.
- Run-front identity: that a dumped front equals a pymoo or C# front.
- Algorithm correctness of U-NSGA-III, survival, or niching optimality.

A family sentence such as “niching is resolved” is outside this statement. The scope of the claim is the equality above.

## Where it is checked

| Result | Surface | Role |
|--------|---------|------|
| Niche histogram conservation | [`NicheCountSum.challenge.bend`](NicheCountSum.challenge.bend) | Trusted statement. Hole (`?TODO`). |
| `Laws.niche_count_sum` | [`PROOF.bend`](../PROOF.bend) | Closure. |
| Machine index | [`NicheCountSum.json`](NicheCountSum.json) | Points the statement at the named theorem and at `bend PROOF.bend`. |

Gate: `bend PROOF.bend`. These files do not replace the wall.
