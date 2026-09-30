# NonDominatedSort — C# Unsga3.Core.NonDominatedSort.
# Fast non-dominated sorting by peeling (Deb et al.).
# `sort` uses Deb constraint-domination: feasible beats infeasible;
# both infeasible and unequal CV → smaller CV; equal CV is mutual
# non-domination (objectives are not compared). Both feasible → Pareto.
# `dominates` stays the Pareto predicate (law dominates_irreflexive).
# Zero constraints (cv 0) keeps today's Pareto fronts.
#
# Layout (Bend guide: Arrays cannot ride a fork tree; List.get is a
# cons walk): one sequential pass materializes `Row{index, objectives, cv}`
# so the peel never `List.get`s a fat Individual. Per-candidate split
# still mid-splits `a b = f(lo) f(hi)` (same front/leftover order as
# the tail-first walk). Inner is_dominated stays a sequential OR so a
# first hit skips the rest. Same ranks and index order when every cv is 0.

import Base
import ./individual.bend as Ind
import ./util.bend as Util

# One sort-row: population index plus the objective vector. Built once
# per `sort`; leftover peels reuse the same rows (no re-index).
type Row is Data:
  Row{
    i: Nat
    f: List<&2, F32>
    cv: F32
  }

def row_idx(r: Row) -> Nat:
  match r:
    case Row{i, f, cv}:
      i

def row_f(r: Row) -> List<&2, F32>:
  match r:
    case Row{i, f, cv}:
      f

def row_cv(r: Row) -> F32:
  match r:
    case Row{i, f, cv}:
      cv

def rows_of.go(pop: List<&2, Ind.Individual>, +i: Nat) -> List<&2, Row>:
  match pop:
    case Nil{}:
      Nil{}
    case +h <> t:
      Row{i, Ind.objectives(h), Ind.constraint_violation(h)} <> rows_of.go(t, 1n+i)

def rows_of(+pop: List<&2, Ind.Individual>) -> List<&2, Row>:
  rows_of.go(pop, 0n)

def row_idxs(rs: List<&2, Row>) -> List<&2, Nat>:
  match rs:
    case Nil{}:
      Nil{}
    case +r <> t:
      row_idx(r) <> row_idxs(t)

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
  # Unequal lengths: mutual non-domination (0), even if the shared prefix
  # is strictly better. C# ComparePareto throws. ZDT/DTLZ use one length.
  # Locked by src/nds_unequal.bend.
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

# Equal CV among infeasible points: 0. Deb does not Pareto-compare.
# C# CompareConstraintDominated on published main falls through to
# Pareto; this tree does not (Deb / constraint-domination target).
def compare_cd.infeas(+cva: F32, +cvb: F32, a_lt: Bool, b_lt: Bool) -> Nat:
  match a_lt:
    case True{}:
      1n
    case False{}:
      match b_lt:
        case True{}:
          2n
        case False{}:
          0n

# 0 mutual, 1 a dominates b, 2 b dominates a.
# Feasible (cv ≤ 0) beats infeasible. Both feasible → Pareto,
# including unequal objective lengths (mutual non-domination).
def compare_cd.feas(
  +fa: List<&2, F32>,
  +fb: List<&2, F32>,
  +cva: F32,
  +cvb: F32,
  a_feas: Bool,
  b_feas: Bool
) -> Nat:
  match a_feas b_feas:
    case True{} True{}:
      compare_pareto(fa, fb)
    case True{} False{}:
      1n
    case False{} True{}:
      2n
    case False{} False{}:
      compare_cd.infeas(cva, cvb, F32.is_lt(cva, cvb), F32.is_lt(cvb, cva))

def compare_cd(+fa: List<&2, F32>, +fb: List<&2, F32>, +cva: F32, +cvb: F32) -> Nat:
  compare_cd.feas(fa, fb, cva, cvb, F32.is_le(cva, 0.0), F32.is_le(cvb, 0.0))

def compare_constraint(+a: Ind.Individual, +b: Ind.Individual) -> Nat:
  compare_cd(Ind.objectives(a), Ind.objectives(b), Ind.constraint_violation(a), Ind.constraint_violation(b))

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

# Pareto only. Irreflexivity is closed in PROOF.bend on this predicate.
# `sort` uses compare_cd, not this function.
def dominates(a: Ind.Individual, b: Ind.Individual) -> Bool:
  dominates.fin(compare_pareto(Ind.objectives(a), Ind.objectives(b)))

def dominates_ff(+fa: List<&2, F32>, +fb: List<&2, F32>) -> Bool:
  dominates.fin(compare_pareto(fa, fb))

def dominates_cd(+fa: List<&2, F32>, +cva: F32, +fb: List<&2, F32>, +cvb: F32) -> Bool:
  dominates.fin(compare_cd(fa, fb, cva, cvb))

# Sequential OR so a first hit can skip the rest. Candidate-level
# parallelism lives in split_walk (coarse mid-split). Walks `all`
# rows directly — no List.get into the population.
def is_dominated(+all: List<&2, Row>, +i: Nat, +fi: List<&2, F32>, +cvi: F32) -> Bool:
  match all:
    case Nil{}:
      False{}
    case +r <> rs:
      match r:
        case Row{+j, +fj, +cvj}:
          Bool.or(
            Bool.and(Bool.not(Nat.is_eq(i, j)), dominates_cd(fj, cvj, fi, cvi)),
            is_dominated(rs, i, fi, cvi)
          )

def row_dom(+all: List<&2, Row>, +r: Row) -> Bool:
  match r:
    case Row{+i, +f, +cv}:
      is_dominated(all, i, f, cv)

# Split remaining into (front indices, leftover rows). Same front
# membership and leftover order as the old index-list peel.
# |front| + |leftover| = |remaining| by construction.
type Split is Data:
  Split{
    ff: List<&2, Nat>
    ot: List<&2, Row>
  }

def split_put(+r: Row, s: Split, dominated: Bool) -> Split:
  match s:
    case Split{ff, ot}:
      match dominated:
        case True{}:
          Split{ff, r <> ot}
        case False{}:
          Split{row_idx(r) <> ff, ot}

def split_cat(a: Split, b: Split) -> Split:
  match a b:
    case Split{ff1, ot1} Split{ff2, ot2}:
      Split{List.append(&2, Nat, ff1, ff2), List.append(&2, Row, ot1, ot2)}

# Per-candidate split is independent given `all`. Mid-split then
# concatenate fronts / leftovers so order matches the tail-first walk.
def split_walk.go(+all: List<&2, Row>, +fuel: Nat, cand: List<&2, Row>) -> Split:
  match fuel cand:
    case 0n Nil{}:
      Split{Nil{}, Nil{}}
    case 0n +r <> rest:
      split_put(r, split_walk.go(all, 0n, rest), row_dom(all, r))
    case 1n+p Nil{}:
      Split{Nil{}, Nil{}}
    case 1n+p +r <> Nil{}:
      split_put(r, Split{Nil{}, Nil{}}, row_dom(all, r))
    case 1n+p h <> t:
      +xs = {h <> t : List<&2, Row>}
      +mid = Nat.div(Util.list_len(Row, xs), 2n)
      lo hi = split_walk.go(all, p, List.take(&2, Row, xs, mid)) split_walk.go(all, p, List.drop(&2, Row, xs, mid))
      split_cat(lo, hi)

def split_walk(+all: List<&2, Row>, +cand: List<&2, Row>) -> Split:
  split_walk.go(all, Util.list_len(Row, cand), cand)

# Empty first front (unreachable on a finite Pareto set) keeps the head
# so peel stays a partition.
def split_ne(+r: Row, +rest: List<&2, Row>, s: Split) -> Split:
  match s:
    case Split{ff, ot}:
      match ff:
        case Nil{}:
          Split{row_idx(r) <> Nil{}, rest}
        case h <> t:
          Split{h <> t, ot}

def split_front(remaining: List<&2, Row>) -> Split:
  match remaining:
    case Nil{}:
      Split{Nil{}, Nil{}}
    case +r <> +rest:
      split_ne(r, rest, split_walk(r <> rest, r <> rest))

def split_fst(s: Split) -> List<&2, Nat>:
  match s:
    case Split{ff, ot}:
      ff

def split_snd(s: Split) -> List<&2, Row>:
  match s:
    case Split{ff, ot}:
      ot

def peel(fuel: Nat, remaining: List<&2, Row>) -> List<&2, List<&2, Nat>>:
  match fuel remaining:
    case 0n Nil{}:
      Nil{}
    case 1n+f Nil{}:
      Nil{}
    case 0n +r <> +rest:
      row_idxs({r <> rest : List<&2, Row>}) <> Nil{}
    case 1n+f +r <> +rest:
      +s = split_front({r <> rest : List<&2, Row>})
      split_fst(s) <> peel(f, split_snd(s))

def sort(population: List<&2, Ind.Individual>) -> List<&2, List<&2, Nat>>:
  match population:
    case Nil{}:
      Nil{}
    case +h <> +t:
      +rs = rows_of.go({h <> t : List<&2, Ind.Individual>}, 0n)
      peel(Util.list_len(Row, rs), rs)

def front_index_count(fronts: List<&2, List<&2, Nat>>) -> Nat:
  match fronts:
    case Nil{}:
      0n
    case h <> t:
      Nat.add(Util.list_len(Nat, h), front_index_count(t))
