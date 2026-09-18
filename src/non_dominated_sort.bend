# NonDominatedSort — C# Unsga3.Core.NonDominatedSort.
# Fast non-dominated sorting by peeling (Deb et al.). v0: Pareto on
# objectives only (no constraint-domination until constraints exist).

import Base
import ./individual.bend as Ind
import ./util.bend as Util

def verdict.a(bb: Bool) -> Nat:
  match bb:
    case True{}:
      0n
    case False{}:
      1n

def verdict.b(bb: Bool) -> Nat:
  match bb:
    case True{}:
      2n
    case False{}:
      0n

# Minimization: 0n = mutual non-domination, 1n = a dominates b, 2n = b dominates a.
def verdict(ab: Bool, bb: Bool) -> Nat:
  match ab:
    case True{}:
      verdict.a(bb)
    case False{}:
      verdict.b(bb)

def compare_pareto.go(a: List<&2, F32>, b: List<&2, F32>, ab: Bool, bb: Bool) -> Nat:
  match a b:
    case Nil{} Nil{}:
      verdict(ab, bb)
    case +x <> xs +y <> ys:
      compare_pareto.go(xs, ys, Bool.or(ab, F32.is_lt(x, y)), Bool.or(bb, F32.is_lt(y, x)))
    case Nil{} y <> ys:
      0n
    case x <> xs Nil{}:
      0n

def compare_pareto(a: List<&2, F32>, b: List<&2, F32>) -> Nat:
  compare_pareto.go(a, b, False{}, False{})

def dominates.is1(p: Nat) -> Bool:
  match p:
    case 0n:
      True{}
    case 1n+q:
      False{}

def dominates.fin(c: Nat) -> Bool:
  match c:
    case 0n:
      False{}
    case 1n+p:
      dominates.is1(p)

def dominates(a: Ind.Individual, b: Ind.Individual) -> Bool:
  dominates.fin(compare_pareto(Ind.objectives(a), Ind.objectives(b)))

def get_ind(+pop: List<&2, Ind.Individual>, i: Nat) -> Maybe<&2, Ind.Individual>:
  List.get(&2, Ind.Individual, pop, i)

def dominates_idx.go(mj: Maybe<&2, Ind.Individual>, mi: Maybe<&2, Ind.Individual>) -> Bool:
  match mj mi:
    case Some{a} Some{b}:
      dominates(a, b)
    case None{} mi2:
      False{}
    case Some{a} None{}:
      False{}

def dominates_idx(+pop: List<&2, Ind.Individual>, j: Nat, i: Nat) -> Bool:
  dominates_idx.go(get_ind(pop, j), get_ind(pop, i))

def first_put(i: Nat, rest: List<&2, Nat>, dominated: Bool) -> List<&2, Nat>:
  match dominated:
    case True{}:
      rest
    case False{}:
      i <> rest

def is_dominated(+pop: List<&2, Ind.Individual>, others: List<&2, Nat>, +i: Nat) -> Bool:
  match others:
    case Nil{}:
      False{}
    case +j <> js:
      Bool.or(
        Bool.and(Bool.not(Nat.is_eq(i, j)), dominates_idx(pop, j, i)),
        is_dominated(pop, js, i)
      )

def first_scan(+pop: List<&2, Ind.Individual>, +all: List<&2, Nat>, cand: List<&2, Nat>) -> List<&2, Nat>:
  match cand:
    case Nil{}:
      Nil{}
    case +i <> rest:
      first_put(i, first_scan(pop, all, rest), is_dominated(pop, all, i))

def first_front(+pop: List<&2, Ind.Individual>, +remaining: List<&2, Nat>) -> List<&2, Nat>:
  first_scan(pop, remaining, remaining)

def peel(+pop: List<&2, Ind.Individual>, fuel: Nat, remaining: List<&2, Nat>) -> List<&2, List<&2, Nat>>:
  match fuel remaining:
    case f Nil{}:
      Nil{}
    case 0n rem:
      Nil{}
    case 1n+f +i <> +rest:
      +ff = first_front(pop, i <> rest)
      ff <> peel(pop, f, Util.minus(i <> rest, ff))

def sort(+population: List<&2, Ind.Individual>) -> List<&2, List<&2, Nat>>:
  +n = Util.list_len(Ind.Individual, population)
  peel(population, n, List.range(n))

def front_index_count(fronts: List<&2, List<&2, Nat>>) -> Nat:
  match fronts:
    case Nil{}:
      0n
    case h <> t:
      Nat.add(Util.list_len(Nat, h), front_index_count(t))
