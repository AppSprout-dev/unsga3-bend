# v0 core facade. Importing this file is the module graph check.
# Bodies live in the imported modules. No Unsga3Algorithm.Run, SBX, or
# polynomial mutation here.

import Base
import ./individual.bend as Individual
import ./non_dominated_sort.bend as NonDominatedSort
import ./normalization.bend as Normalization
import ./reference_directions.bend as ReferenceDirections
import ./survival.bend as Survival
import ./util.bend as Util

def core_modules_loaded() -> Bool:
  True{}

def empty_fronts() -> List<&2, List<&2, Nat>>:
  NonDominatedSort.sort(Nil{})

def empty_normalized() -> Normalization.State & List<&2, List<&2, F32>>:
  Normalization.normalize(Normalization.new_state(2n), Nil{})

def das_dennis_m1() -> List<&2, List<&2, F32>>:
  ReferenceDirections.das_dennis(1n, 1n)

def empty_selected() -> List<&2, Individual.Individual>:
  Survival.select(Nil{}, 0n, Nil{})

def count_m1() -> Nat:
  Util.nat_min(ReferenceDirections.count(1n, 12n), 1n)
