# NonDominatedSort — C# Unsga3.Core.NonDominatedSort.
# Fast non-dominated sorting by peeling (Deb et al.). v0: Pareto on
# objectives only (no constraint-domination until constraints exist).
# Per-candidate split / first_scan uses mid-split `a b = f(lo) f(hi)`
# (same front/leftover order as the tail-first walk). Inner is_dominated
# stays a sequential OR so a first hit skips the rest.

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

# Sequential OR so a first hit can skip the rest. Candidate-level
# parallelism lives in split_walk / first_scan (coarse mid-split).
def is_dominated(+pop: List<&2, Ind.Individual>, others: List<&2, Nat>, +i: Nat) -> Bool:
  match others:
    case Nil{}:
      False{}
    case +j <> js:
      Bool.or(
        Bool.and(Bool.not(Nat.is_eq(i, j)), dominates_idx(pop, j, i)),
        is_dominated(pop, js, i)
      )

# Per-candidate domination is independent given `all`. Mid-split;
# `take ++ drop` matches the old tail-first first_put order.
def first_scan.go(+pop: List<&2, Ind.Individual>, +all: List<&2, Nat>, +fuel: Nat, cand: List<&2, Nat>) -> List<&2, Nat>:
  match fuel cand:
    case 0n Nil{}:
      Nil{}
    case 0n +i <> rest:
      first_put(i, first_scan.go(pop, all, 0n, rest), is_dominated(pop, all, i))
    case 1n+p Nil{}:
      Nil{}
    case 1n+p +i <> Nil{}:
      first_put(i, Nil{}, is_dominated(pop, all, i))
    case 1n+p h <> t:
      +xs = {h <> t : List<&2, Nat>}
      +mid = Nat.div(Util.list_len(Nat, xs), 2n)
      lo hi = first_scan.go(pop, all, p, List.take(&2, Nat, xs, mid)) first_scan.go(pop, all, p, List.drop(&2, Nat, xs, mid))
      List.append(&2, Nat, lo, hi)

def first_scan(+pop: List<&2, Ind.Individual>, +all: List<&2, Nat>, +cand: List<&2, Nat>) -> List<&2, Nat>:
  first_scan.go(pop, all, Util.list_len(Nat, cand), cand)

def first_front(+pop: List<&2, Ind.Individual>, +remaining: List<&2, Nat>) -> List<&2, Nat>:
  first_scan(pop, remaining, remaining)

# Split remaining into (front, leftover). Same front as first_scan, leftover
# in original order. |front| + |leftover| = |remaining| by construction.
type Split is Data:
  Split{
    ff: List<&2, Nat>
    ot: List<&2, Nat>
  }

def split_put(+i: Nat, s: Split, dominated: Bool) -> Split:
  match s:
    case Split{ff, ot}:
      match dominated:
        case True{}:
          Split{ff, i <> ot}
        case False{}:
          Split{i <> ff, ot}

def split_cat(a: Split, b: Split) -> Split:
  match a b:
    case Split{ff1, ot1} Split{ff2, ot2}:
      Split{List.append(&2, Nat, ff1, ff2), List.append(&2, Nat, ot1, ot2)}

# Per-candidate split is independent given `all`. Mid-split then
# concatenate fronts / leftovers so order matches the tail-first walk.
def split_walk.go(+pop: List<&2, Ind.Individual>, +all: List<&2, Nat>, +fuel: Nat, cand: List<&2, Nat>) -> Split:
  match fuel cand:
    case 0n Nil{}:
      Split{Nil{}, Nil{}}
    case 0n +i <> rest:
      split_put(i, split_walk.go(pop, all, 0n, rest), is_dominated(pop, all, i))
    case 1n+p Nil{}:
      Split{Nil{}, Nil{}}
    case 1n+p +i <> Nil{}:
      split_put(i, Split{Nil{}, Nil{}}, is_dominated(pop, all, i))
    case 1n+p h <> t:
      +xs = {h <> t : List<&2, Nat>}
      +mid = Nat.div(Util.list_len(Nat, xs), 2n)
      lo hi = split_walk.go(pop, all, p, List.take(&2, Nat, xs, mid)) split_walk.go(pop, all, p, List.drop(&2, Nat, xs, mid))
      split_cat(lo, hi)

def split_walk(+pop: List<&2, Ind.Individual>, +all: List<&2, Nat>, +cand: List<&2, Nat>) -> Split:
  split_walk.go(pop, all, Util.list_len(Nat, cand), cand)

# Empty first_scan (unreachable on a finite Pareto set) keeps the head so
# peel stays a partition. Observationally first_front + minus when the
# remaining list has a unique head (range / peeled leftovers).
def split_ne(+i: Nat, +rest: List<&2, Nat>, s: Split) -> Split:
  match s:
    case Split{ff, ot}:
      match ff:
        case Nil{}:
          Split{i <> Nil{}, rest}
        case h <> t:
          Split{h <> t, ot}

def split_front(+pop: List<&2, Ind.Individual>, remaining: List<&2, Nat>) -> Split:
  match remaining:
    case Nil{}:
      Split{Nil{}, Nil{}}
    case +i <> +rest:
      split_ne(i, rest, split_walk(pop, i <> rest, i <> rest))

def split_fst(s: Split) -> List<&2, Nat>:
  match s:
    case Split{ff, ot}:
      ff

def split_snd(s: Split) -> List<&2, Nat>:
  match s:
    case Split{ff, ot}:
      ot

def peel(+pop: List<&2, Ind.Individual>, fuel: Nat, remaining: List<&2, Nat>) -> List<&2, List<&2, Nat>>:
  match fuel remaining:
    case 0n Nil{}:
      Nil{}
    case 1n+f Nil{}:
      Nil{}
    case 0n +i <> +rest:
      {i <> rest : List<&2, Nat>} <> Nil{}
    case 1n+f +i <> +rest:
      +s = split_front(pop, i <> rest)
      split_fst(s) <> peel(pop, f, split_snd(s))

def sort(+population: List<&2, Ind.Individual>) -> List<&2, List<&2, Nat>>:
  +n = Util.list_len(Ind.Individual, population)
  peel(population, n, List.range(n))

def front_index_count(fronts: List<&2, List<&2, Nat>>) -> Nat:
  match fronts:
    case Nil{}:
      0n
    case h <> t:
      Nat.add(Util.list_len(Nat, h), front_index_count(t))
