# NonDominatedSort — C# Unsga3.Core.NonDominatedSort.
# Fast non-dominated sorting (Deb et al.). v0: Pareto on objectives only
# (no constraint-domination until constraints exist).

import Base
import ./individual.bend as Ind
import ./util.bend as Util

# Minimization compare:
#   0n = mutual non-domination
#   1n = a Pareto-dominates b
#   2n = b Pareto-dominates a
# TODO(v0): walk F32 objectives (Base F32 has no cmp yet; pick a discrete
# encoding or a host compare when implementing).
def compare_pareto(-a: List<&2, F32>, -b: List<&2, F32>) -> Nat:
  0n

# True if a Pareto-dominates b (minimization, ignores constraints).
# TODO(v0): ComparePareto(a.objectives, b.objectives) == 1n
def dominates(-a: Ind.Individual, -b: Ind.Individual) -> Bool:
  False{}

# Assign ranks (0 = best front) and return fronts as lists of indices
# into `population`. Empty population → empty fronts (implemented).
# TODO(v0): Deb et al. O(MN^2) sort; every index in exactly one front.
def sort(population: List<&2, Ind.Individual>) -> List<&2, List<&2, Nat>>:
  match population:
    case Nil{}:
      Nil{}
    case h <> t:
      Nil{}

def front_index_count(fronts: List<&2, List<&2, Nat>>) -> Nat:
  match fronts:
    case Nil{}:
      0n
    case Con{h, t}:
      Nat.add(Util.list_len(Nat, h), front_index_count(t))
