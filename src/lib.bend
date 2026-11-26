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

# --- Consumer facade (usable via `import <hash>/lib.bend as Unsga3`) ---

def interval(+lo: F32, +hi: F32) -> Bounds.Interval:
  Bounds.interval(lo, hi)

def box(+n_obj: Nat, +ivs: List<&2, Bounds.Interval>) -> Bounds.Box:
  Bounds.box(n_obj, ivs)

def unit_box(+n_var: Nat, +n_obj: Nat) -> Bounds.Box:
  Bounds.unit_n(n_var, n_obj)

def span_box(+n_var: Nat, +n_obj: Nat, +lo: F32, +hi: F32) -> Bounds.Box:
  Bounds.span_n(n_var, n_obj, lo, hi)

def scored(+f: List<&2, F32>, +g: List<&2, F32>) -> Problems.Scored:
  Problems.scored(f, g)

def plain(+f: List<&2, F32>) -> Problems.Scored:
  Problems.plain(f)

def pymoo() -> Tournament.Mode:
  Tournament.pymoo()

def rank_niche() -> Tournament.Mode:
  Tournament.rank_niche()

def das_dennis(m: Nat, p: Nat) -> List<&2, List<&2, F32>>:
  ReferenceDirections.das_dennis(m, p)

def mk_config(+dirs: List<&2, List<&2, F32>>, +pop_size: Nat, +gens: Nat, +seed: Nat, +mode: Tournament.Mode, +elim_dups: Bool) -> Algorithm.Config:
  Algorithm.mk(dirs, pop_size, gens, seed, mode, elim_dups)

def run(+prob: Problems.Problem, +cfg: Algorithm.Config) -> List<&2, Individual.Individual>:
  Algorithm.run(prob, cfg)

def run_seeded(+prob: Problems.Problem, +cfg: Algorithm.Config, +seed_x: List<&2, F32>) -> List<&2, Individual.Individual>:
  Algorithm.run_seeded(prob, cfg, seed_x)

def run_with(~eval: @+x:List<&2, F32> -> Problems.Scored, +b: Bounds.Box, +cfg: Algorithm.Config) -> List<&2, Individual.Individual>:
  Algorithm.run_with(~eval, b, cfg)

def run_seeded_with(~eval: @+x:List<&2, F32> -> Problems.Scored, +b: Bounds.Box, +cfg: Algorithm.Config, +seed_x: List<&2, F32>) -> List<&2, Individual.Individual>:
  Algorithm.run_seeded_with(~eval, b, cfg, seed_x)

def nd_front(+pop: List<&2, Individual.Individual>) -> List<&2, Individual.Individual>:
  Algorithm.nd_front(pop)

def feas_nd(+pop: List<&2, Individual.Individual>) -> List<&2, Individual.Individual>:
  Algorithm.feas_nd(pop)

def select(+combined: List<&2, Individual.Individual>, +target_size: Nat, +dirs: List<&2, List<&2, F32>>) -> List<&2, Individual.Individual>:
  Survival.select(combined, target_size, dirs)

def zdt1(n: Nat) -> Problems.Problem:
  Problems.zdt1(n)

def zdt2(n: Nat) -> Problems.Problem:
  Problems.zdt2(n)

def dtlz2(+m: Nat, k: Nat) -> Problems.Problem:
  Problems.dtlz2(m, k)

def osy() -> Problems.Problem:
  Problems.osy()

def tnk() -> Problems.Problem:
  Problems.tnk()

def c1_dtlz1(+m: Nat, k: Nat) -> Problems.Problem:
  Problems.c1_dtlz1(m, k)
