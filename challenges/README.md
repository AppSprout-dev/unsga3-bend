# Challenge fixtures

Comparator-style packaging for claims the Bend wall already owns. Each fixture pairs a trusted statement with a named theorem. The statement is not a second proof. The gate is still:

```bash
bend PROOF.bend
```

`LAWS.bend` and `PROOF.bend` stay the wall. Nothing in this directory is imported by `PROOF.bend`. A green wall is a closed `Laws.*` def, not a green `bend` of a challenge file.

## Files (one claim)

| File | Role |
|------|------|
| [`NicheCountSum.json`](NicheCountSum.json) | Machine index: theorem `Laws.niche_count_sum`, gate `bend PROOF.bend`, `proof_surface: "Bend PROOF"`. |
| [`NicheCountSum.challenge.bend`](NicheCountSum.challenge.bend) | The same proposition as `law niche_count_sum`, left open with `?TODO`. |
| [`NicheCountSum.SCOPE.md`](NicheCountSum.SCOPE.md) | What that equality buys, and what stays outside it. |

## How to read a pass

1. The JSON names `Laws.niche_count_sum` and `proof_surface: "Bend PROOF"`.
2. `bend PROOF.bend` is the gate for that name. The def is `Laws.niche_count_sum` in `PROOF.bend`.
3. `bend challenges/NicheCountSum.challenge.bend` reports `1 TODO found`. That is the hole. Filling it here would be a second proof; do not.

Public verbs for this claim (“proves”, “resolved”, “machine-checked”) follow [docs/PROOF-SURFACE.md](../docs/PROOF-SURFACE.md) and name this statement. They do not extend to niching, IGD, or Run-front identity. See the scope file.
