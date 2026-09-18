# v0 A/B driver: run Survival.select on a population of objective vectors
# and print the selected front as CSV (one row per individual).
# No SBX, mutation, or generational Run.

import Base
import ./individual.bend as Ind
import ./reference_directions.bend as Refs
import ./survival.bend as Surv
import ./util.bend as Util

# Shared smoke fixture (same vectors as ab/fixtures/core_2obj.json).
def fixture_pop() -> List<&2, Ind.Individual>:
  Ind.from_objectives([0.0, 1.0])
  <> Ind.from_objectives([0.5, 0.5])
  <> Ind.from_objectives([1.0, 0.0])
  <> Ind.from_objectives([0.2, 0.9])
  <> Ind.from_objectives([0.9, 0.2])
  <> Ind.from_objectives([0.8, 0.8])
  <> Ind.from_objectives([1.0, 1.0])
  <> Ind.from_objectives([0.1, 0.95])
  <> Nil{}

def emit(xs: List<&2, Ind.Individual>) -> IO(Unit):
  match xs:
    case Nil{}:
      do IO<Unit>:
        return Unit{}
    case ind <> rest:
      do IO<Unit>:
        IO.print(Util.show_f32s(Ind.objectives(ind)))
        emit(rest)

def run_select(+pop: List<&2, Ind.Individual>, +target: Nat, +m: Nat, +partitions: Nat) -> List<&2, Ind.Individual>:
  Surv.select(pop, target, Refs.das_dennis(m, partitions))

def main() -> IO(Unit):
  do IO<Unit>:
    selected : List<&2, Ind.Individual> = run_select(fixture_pop(), 5n, 2n, 4n)
    emit(selected)
