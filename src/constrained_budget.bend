# Native completion of the constrained budgets in ab/protocol.py
# `constrained_knobs` (PymooCompatible, seed 1):
#   OSY / TNK  partitions=12 pop=52 gens=250
#   C1-DTLZ1   partitions=12 pop=92 gens=150
# The duplicating CV insert overflowed these Runs. This driver must
# finish and print one `ok` line per problem. Not an IGD table.
# Check with `bend src/constrained_budget.bend -o <bin>` and run it.

import Base
import ./algorithm.bend as Algo
import ./individual.bend as Ind
import ./problems.bend as Prob
import ./reference_directions.bend as Refs
import ./tournament.bend as Tour
import ./util.bend as Util

def show_nat(n: Nat) -> String:
  F32.show(F32.from_nat(n))

def count_feas.on(later: Nat, feas: Bool) -> Nat:
  match feas:
    case True{}:
      1n+later
    case False{}:
      later

def count_feas(xs: List<&2, Ind.Individual>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      count_feas.on(count_feas(t), Ind.feasible(h))

def run_line(name: String, +p: Prob.Problem, +pop: Nat, +gens: Nat, +m: Nat, +parts: Nat) -> String:
  +cfg = Algo.mk(Refs.das_dennis(m, parts), pop, gens, 1n, Tour.pymoo(), True{})
  +out = Algo.run(p, cfg)
  "ok " ++ name
    ++ " len=" ++ show_nat(Util.list_len(Ind.Individual, out))
    ++ " feas=" ++ show_nat(count_feas(out))
    ++ " pop=" ++ show_nat(pop)
    ++ " gens=" ++ show_nat(gens)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("# constrained budget seed=1 tournament=PymooCompatible")
    IO.print(run_line("osy", Prob.osy(), 52n, 250n, 2n, 12n))
    IO.print(run_line("tnk", Prob.tnk(), 52n, 250n, 2n, 12n))
    IO.print(run_line("c1dtlz1", Prob.c1_dtlz1(3n, 5n), 92n, 150n, 3n, 12n))
    return Unit{}
