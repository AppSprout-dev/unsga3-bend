# Core + pass-2 facade. Importing this file is the module graph check:
# v0 selection, SBX / mutation, ZDT/DTLZ, tournament, Unsga3Algorithm.Run.

import Base
import ./individual.bend as Individual
import ./non_dominated_sort.bend as NonDominatedSort
import ./normalization.bend as Normalization
import ./reference_directions.bend as ReferenceDirections
import ./survival.bend as Survival
import ./util.bend as Util
import ./bounds.bend as Bounds
import ./rng.bend as Rng
import ./sbx.bend as Sbx
import ./polynomial_mutation.bend as Poly
import ./problems.bend as Problems
import ./tournament.bend as Tournament
import ./algorithm.bend as Algorithm

def core_modules_loaded() -> Bool:
  True{}

def variation_defaults() -> F32 & F32 & F32:
  (Sbx.eta(Sbx.default()), Sbx.probability(Sbx.default()), Poly.eta(Poly.default()))

def unit_box2() -> Bounds.Box:
  Bounds.unit_n(2n, 2n)

def rng_seed1() -> Rng.State:
  Rng.from_nat(1n)

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

def zdt1_n_obj() -> Nat:
  Problems.n_obj(Problems.zdt1(30n))

def dtlz2_n_var() -> Nat:
  Problems.n_var(Problems.dtlz2(3n, 10n))

def empty_run() -> List<&2, Individual.Individual>:
  Algorithm.run(Problems.zdt1(30n), Algorithm.mk(Nil{}, 0n, 0n, 1n, Tournament.pymoo(), True{}))

def parents_zero() -> List<&2, Individual.Individual>:
  Tournament.parents_of(Tournament.select_parents(Tournament.pymoo(), Nil{}, 0n, Rng.from_nat(1n)))
