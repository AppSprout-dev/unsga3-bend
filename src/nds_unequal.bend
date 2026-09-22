# Unequal-length objectives. Not an IGD run.
# compare_pareto returns 0 (mutual non-domination) when the lists differ
# in length, including when the shared prefix would have dominated.
# C# ComparePareto throws. ZDT/DTLZ populations use one length.
# Equal-length domination is unchanged (1 = a dominates b, 2 = b dominates a).

import Base
import ./individual.bend as Ind
import ./non_dominated_sort.bend as NDS
import ./util.bend as Util

def show_nat(n: Nat) -> String:
  F32.show(F32.from_nat(n))

def show_idxs(xs: List<&2, Nat>) -> String:
  match xs:
    case Nil{}:
      ""
    case n <> Nil{}:
      show_nat(n)
    case n <> rest:
      show_nat(n) ++ "," ++ show_idxs(rest)

def front_at(fronts: List<&2, List<&2, Nat>>, i: Nat) -> List<&2, Nat>:
  Maybe.default(&2, List<&2, Nat>, List.get(&2, List<&2, Nat>, fronts, i), Nil{})

def short_long() -> List<&2, Ind.Individual>:
  Ind.from_objectives([0.0]) <> Ind.from_objectives([1.0, 0.0]) <> Nil{}

def dominated_pair() -> List<&2, Ind.Individual>:
  Ind.from_objectives([0.0, 0.0]) <> Ind.from_objectives([1.0, 1.0]) <> Nil{}

def main() -> IO(Unit):
  +uneq = NDS.sort(short_long())
  +dom = NDS.sort(dominated_pair())
  do IO<Unit>:
    IO.print("cmp_short_long " ++ show_nat(NDS.compare_pareto([0.0], [1.0, 0.0])))
    IO.print("cmp_long_short " ++ show_nat(NDS.compare_pareto([1.0, 0.0], [0.0])))
    IO.print("cmp_dom " ++ show_nat(NDS.compare_pareto([0.0, 0.0], [1.0, 1.0])))
    IO.print("cmp_rev " ++ show_nat(NDS.compare_pareto([1.0, 1.0], [0.0, 0.0])))
    IO.print("nfront_uneq " ++ show_nat(Util.list_len(List<&2, Nat>, uneq)))
    IO.print("front0_uneq " ++ show_idxs(front_at(uneq, 0n)))
    IO.print("nfront_dom " ++ show_nat(Util.list_len(List<&2, Nat>, dom)))
    IO.print("front0_dom " ++ show_idxs(front_at(dom, 0n)))
    IO.print("front1_dom " ++ show_idxs(front_at(dom, 1n)))
