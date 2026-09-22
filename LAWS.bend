# Core + pass-2 laws. Human-owned. Do not weaken v0 / operator claims.
# Every law below is closed in PROOF.bend (0 ?TODO). A law with no
# def Laws.<name> is an open claim — do not delete it to pass it.
# The wall checks lengths, literals, irreflexivity, and p=0 bit-zero
# copies. It does not buy simplex membership, front identity, or
# SBX / PM / ASF algebra. Das–Dennis length laws depend on @unsafe
# nth_comp.go.

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
import ./src/problems.bend as Prob
import ./src/tournament.bend as Tour
import ./src/algorithm.bend as Algo

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

# LAW: mid-split niche histogram is conservative. Each in-bin assignment
# increments exactly once; List.set / inc_at drops i >= n_dirs (empty
# dirs → zeros(0) is a no-op). When every asg_ref is < n_dirs this is
# |asgs|. Nat only — no F32 / RNG claim.
law niche_count_sum:
  for +asgs: List<&2, Surv.Assignment>
  for +n_dirs: Nat
  {Util.nats_sum(Surv.count_raw.go(n_dirs, Util.list_len(Surv.Assignment, asgs), asgs)) == Surv.in_bin_count(asgs, n_dirs) : Nat}

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
  {Poly.typical_probability(2n) == F32.div(1.0, F32.from_nat(2n)) : F32}

def law_box2() -> Bounds.Box:
  Bounds.unit_n(2n, 2n)

def law_parent_a() -> Ind.Individual:
  Ind.from_variables([0.2, 0.8], 2n)

def law_parent_b() -> Ind.Individual:
  Ind.from_variables([0.7, 0.3], 2n)

# LAW: pair probability 0 copies parent variables.
# Closed in PROOF.bend by a bit-zero short-circuit (the 0.0 word), not
# by an F32 inequality on NextDouble.
law sbx_prob0_child1_vars:
  {Ind.variables(Sbx.child1(Sbx.crossover(Sbx.mk(30.0, 0.0), law_parent_a(), law_parent_b(), law_box2(), Rng.from_nat(1n)))) == Ind.variables(law_parent_a()) : List<&2, F32>}

law sbx_prob0_child2_vars:
  {Ind.variables(Sbx.child2(Sbx.crossover(Sbx.mk(30.0, 0.0), law_parent_a(), law_parent_b(), law_box2(), Rng.from_nat(1n)))) == Ind.variables(law_parent_b()) : List<&2, F32>}

# LAW: per-variable probability 0 leaves the decision vector unchanged.
# Closed in PROOF.bend by the same bit-zero copy. Not an F32 inequality.
law poly_prob0_vars:
  {Ind.variables(Poly.result(Poly.mutate(Poly.default(), law_parent_a(), law_box2(), Rng.from_nat(1n), 0.0))) == Ind.variables(law_parent_a()) : List<&2, F32>}

# LAW: C# Zdt1Problem / Zdt2Problem / Dtlz2Problem dimensions
law zdt1_n_obj:
  {Prob.n_obj(Prob.zdt1(30n)) == 2n : Nat}

law zdt2_n_obj:
  {Prob.n_obj(Prob.zdt2(30n)) == 2n : Nat}

law zdt1_n_var:
  {Prob.n_var(Prob.zdt1(30n)) == 30n : Nat}

law dtlz2_n_obj:
  {Prob.n_obj(Prob.dtlz2(3n, 10n)) == 3n : Nat}

law dtlz2_n_var:
  {Prob.n_var(Prob.dtlz2(3n, 10n)) == 12n : Nat}

# LAW: zero parent-count tournament returns no parents
law select_parents_zero:
  {Util.list_len(Ind.Individual, Tour.parents_of(Tour.select_parents(Tour.pymoo(), Nil{}, 0n, Rng.from_nat(1n)))) == 0n : Nat}

# LAW: pop_size 0 → empty Run (C# ctor rejects pop < 2; Bend stays total)
law run_zero_pop:
  {Util.list_len(Ind.Individual, Algo.run(Prob.zdt1(30n), Algo.mk(Nil{}, 0n, 0n, 1n, Tour.pymoo(), True{}))) == 0n : Nat}

# LAW: |Run| == pop_size after gens (quantified; F32/RNG opaque)
law run_pop_size:
  for +cfg: Algo.Config
  {Util.list_len(Ind.Individual, Algo.run(Prob.zdt1(30n), cfg)) == Algo.cfg_pop(cfg) : Nat}
