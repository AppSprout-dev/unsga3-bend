# Core + pass-2 operator laws. Human-owned. Do not add Run / ZDT claims.
# A law with no proof in PROOF.bend is an open claim.

import Base
import ./src/individual.bend as Ind
import ./src/non_dominated_sort.bend as NDS
import ./src/normalization.bend as Norm
import ./src/reference_directions.bend as Refs
import ./src/survival.bend as Surv
import ./src/util.bend as Util
import ./src/bounds.bend as Bounds
import ./src/rng.bend as Rng
import ./src/sbx.bend as Sbx
import ./src/polynomial_mutation.bend as Poly

# LAW: empty population → empty fronts
law sort_empty:
  {NDS.sort(Nil{}) == Nil{} : List<&2, List<&2, Nat>>}

# LAW: every index appears in the returned fronts exactly as many
# slots as there are individuals (intended: a partition of 0..n-1)
law sort_index_count:
  for +pop: List<&2, Ind.Individual>
  {NDS.front_index_count(NDS.sort(pop)) == Util.list_len(Ind.Individual, pop) : Nat}

# LAW: an individual does not Pareto-dominate itself
law dominates_irreflexive:
  for +ind: Ind.Individual
  {NDS.dominates(ind, ind) == False{} : Bool}

# LAW: empty population → empty normalized matrix
law normalize_empty:
  {Norm.normalize(Norm.new_state(2n), Nil{}) == (Norm.new_state(2n), Nil{}) : Norm.State & List<&2, List<&2, F32>>}

# LAW: |Normalize(P)| = |P|
law normalize_len:
  for +pop: List<&2, Ind.Individual>
  {Util.list_len(List<&2, F32>, Norm.normalize_vecs(pop)) == Util.list_len(Ind.Individual, pop) : Nat}

# LAW: C(n, 0) = 1
law binomial_k0:
  for n: Nat
  {Refs.binomial(n, 0n) == 1n : Nat}

# LAW: one-objective Das–Dennis count is 1
law das_dennis_count_m1:
  for p: Nat
  {Refs.count(1n, p) == 1n : Nat}

# LAW: M ≥ 2 count is C(p + M - 1, M - 1)
# Here M = 2 + m, so C(p + (1+m), 1+m).
law das_dennis_count:
  for m: Nat
  for p: Nat
  {Refs.count(1n+1n+m, p) == Refs.binomial(Nat.add(p, 1n+m), 1n+m) : Nat}

# LAW: M == 1 yields a single direction
law das_dennis_m1_len:
  for p: Nat
  {Util.list_len(List<&2, F32>, Refs.das_dennis(1n, p)) == 1n : Nat}

# LAW: |DasDennis(M, p+1)| = Count(M, p+1). p+1 avoids p==0 (C# rejects
# partitions < 1; v0 returns Nil{} for M>1 / p==0 while Count is C(M-1, M-1)).
law das_dennis_len:
  for m: Nat
  for p: Nat
  {Util.list_len(List<&2, F32>, Refs.das_dennis(m, 1n+p)) == Refs.count(m, 1n+p) : Nat}

# LAW: empty population → no associations
law associate_empty:
  {Surv.associate(Nil{}, Nil{}, Nil{}) == Nil{} : List<&2, Surv.Assignment>}

# LAW: |associate(P, ·, ·)| = |P|
law associate_len:
  for +pop: List<&2, Ind.Individual>
  for +F: List<&2, List<&2, F32>>
  for +dirs: List<&2, List<&2, F32>>
  {Util.list_len(Surv.Assignment, Surv.associate(pop, F, dirs)) == Util.list_len(Ind.Individual, pop) : Nat}

# LAW: empty combined pool → empty selection
law select_empty:
  {Surv.select(Nil{}, 0n, Nil{}) == Nil{} : List<&2, Ind.Individual>}

# LAW: selection size is min(target, |combined|)
law select_size:
  for +pop: List<&2, Ind.Individual>
  for +n: Nat
  for +dirs: List<&2, List<&2, F32>>
  {Util.list_len(Ind.Individual, Surv.select(pop, n, dirs)) == Util.nat_min(n, Util.list_len(Ind.Individual, pop)) : Nat}

# LAW: v0 from_objectives still exposes the given objective vector
law from_objectives_roundtrip:
  {Ind.objectives(Ind.from_objectives([0.0, 1.0])) == [0.0, 1.0] : List<&2, F32>}

# LAW: C# SBX defaults η=30, pair probability=1.0
law sbx_default_eta:
  {Sbx.eta(Sbx.default()) == 30.0 : F32}

law sbx_default_probability:
  {Sbx.probability(Sbx.default()) == 1.0 : F32}

# LAW: C# polynomial mutation default η=20
law poly_default_eta:
  {Poly.eta(Poly.default()) == 20.0 : F32}

# LAW: C# Run uses 1/n when mutationProbability is unset
law poly_typical_n2:
  {Poly.typical_probability(2n) == 0.5 : F32}

def law_box2() -> Bounds.Box:
  Bounds.unit_n(2n, 2n)

def law_parent_a() -> Ind.Individual:
  Ind.from_variables([0.2, 0.8], 2n)

def law_parent_b() -> Ind.Individual:
  Ind.from_variables([0.7, 0.3], 2n)

# LAW: pair probability 0 copies parent variables (first NextDouble > 0).
law sbx_prob0_child1_vars:
  {Ind.variables(Sbx.child1(Sbx.crossover(Sbx.mk(30.0, 0.0), law_parent_a(), law_parent_b(), law_box2(), Rng.from_nat(1n)))) == Ind.variables(law_parent_a()) : List<&2, F32>}

law sbx_prob0_child2_vars:
  {Ind.variables(Sbx.child2(Sbx.crossover(Sbx.mk(30.0, 0.0), law_parent_a(), law_parent_b(), law_box2(), Rng.from_nat(1n)))) == Ind.variables(law_parent_b()) : List<&2, F32>}

# LAW: per-variable probability 0 leaves the decision vector unchanged
# (each NextDouble > 0 on this seed).
law poly_prob0_vars:
  {Ind.variables(Poly.result(Poly.mutate(Poly.default(), law_parent_a(), law_box2(), Rng.from_nat(1n), 0.0))) == Ind.variables(law_parent_a()) : List<&2, F32>}
