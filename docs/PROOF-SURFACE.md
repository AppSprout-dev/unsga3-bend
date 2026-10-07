# Proof surface

Public copy in this repo names the surface that backs a sentence. Three surfaces:

```text
proof_surface ∈ { Lean Comparator pass, Bend PROOF, human RLE }
```

| Surface | What it is |
|---------|------------|
| `Lean Comparator pass` | A named statement whose Comparator challenge config is green (openai/math-style). This tree does not vendor that stack. |
| `Bend PROOF` | `bend PROOF.bend` closes a named `Laws.*` in this repo. |
| `human RLE` | Reviewed lab evidence: an A/B table, a dump, or a measured script. Kernel-unchecked. |

One claim has one surface. A doc page, a yaml catalog, and a challenge file are different layers. Do not collapse them into a fraction of U-NSGA-III “formalized.” The packaged challenge fixture is `Laws.niche_count_sum` ([challenges/NicheCountSum.SCOPE.md](../challenges/NicheCountSum.SCOPE.md)). Other closed laws stay on the wall without a fixture here.

`BendTT recheck` is not a value of this enum until that tooling is what a sentence cites.

## Verb gate

| Public verb | Allowed only if | Else write |
|-------------|-----------------|------------|
| proves / proof / theorem / QED | `Bend PROOF` for a named `Laws.*`, or `Lean Comparator pass` for that named statement | claims / implements / matches oracle on … |
| resolved / settles / solves | Same as proves, **and** a scope doc names the selected statement. Never a family blurb. | the selected-statement sentence, or drop the verb |
| verified / machine-checked | `Bend PROOF` or `Lean Comparator pass` | tested / A/B’d / measured |
| equivalent / matches pymoo / IGD | `human RLE` plus a cited table or script. Never “proved equivalent.” | measured IGD / dump agrees on the fixture |

`closed wall` / `0 ?TODO` means `bend PROOF.bend` for the **listed** laws. It does not mean the algorithm is correct. Das–Dennis length laws that the wall accepts with `@unsafe` (`comps_all_len`, `das_ge2_len`, `LAWS.das_dennis_m1_len`, `LAWS.das_dennis_len`) stay `proof_surface: Bend PROOF` for those length claims only, with the unsafe caveat in [CONTRIBUTING.md](../CONTRIBUTING.md). That is not full Das–Dennis correctness.

Changing which verbs a doc may use is docs-only. Adding, weakening, or rewriting `LAWS.bend` / `PROOF.bend`, or adding Jev Choice/Score fields, is the schema-change gate in [AGENTS.md](../AGENTS.md).

## Copy

The Bend proof wall closes `Laws.niche_count_sum`: the mid-split niche histogram sums to the in-bin assignment count (`proof_surface: Bend PROOF`). [NicheCountSum.SCOPE.md](../challenges/NicheCountSum.SCOPE.md) names that equality. Niche-tie policy, ASF geometry, simplex membership, IGD, Run-front identity, and algorithm correctness sit outside it.

Refuse the family blurb: “unsga3-bend proves U-NSGA-III”, “niching is resolved”, “formally equivalent to pymoo.”

IGD and pymoo dumps stay `human RLE` and cite the table: [EQUIVALENCE.md](EQUIVALENCE.md), [ORACLE-MULTISEED.md](ORACLE-MULTISEED.md), [ORACLE-CATALOG.md](ORACLE-CATALOG.md).
