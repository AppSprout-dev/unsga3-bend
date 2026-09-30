# Constraint-domination + offspring duplicate / odd-N contract.
# Not an IGD run. cv 0 keeps Pareto. Equal infeasible CV is mutual
# non-domination (objectives are not compared). PymooCompatible coins
# on equal CV; RankNicheDistance falls through to rank. Seen set is
# the survivor population. Odd N lets parent N-1 enter SBX; even N
# pair lookups stay on the old cursor.

import Base
import ./individual.bend as Ind
import ./non_dominated_sort.bend as NDS
import ./tournament.bend as Tour
import ./rng.bend as Rng
import ./algorithm.bend as Algo
import ./problems.bend as Prob
import ./util.bend as Util

def line(ok: Bool, label: String) -> String:
  match ok:
    case True{}:
      "ok " ++ label
    case False{}:
      "FAIL " ++ label

def feas_worse() -> Ind.Individual:
  Ind.from_objectives([1.0, 1.0])

def infeas_better() -> Ind.Individual:
  Ind.set_constraints(Ind.from_objectives([0.0, 0.0]), [1.0])

def eq_dom() -> Ind.Individual:
  Ind.set_constraints(Ind.from_objectives([0.0, 0.0]), [1.0])

def eq_worse() -> Ind.Individual:
  Ind.set_constraints(Ind.from_objectives([1.0, 1.0]), [0.4, 0.6])

def big_cv() -> Ind.Individual:
  Ind.set_constraints(Ind.from_objectives([0.0, 0.0]), [2.0])

def small_cv() -> Ind.Individual:
  Ind.set_constraints(Ind.from_objectives([1.0, 1.0]), [0.5])

def pair_pop(a: Ind.Individual, b: Ind.Individual) -> List<&2, Ind.Individual>:
  a <> b <> Nil{}

def nfronts(+pop: List<&2, Ind.Individual>) -> Nat:
  Util.list_len(List<&2, Nat>, NDS.sort(pop))

def on_front(+pop: List<&2, Ind.Individual>, +fi: Nat, +i: Nat) -> Bool:
  Util.in_nats(i, Maybe.default(&2, List<&2, Nat>, List.get(&2, List<&2, Nat>, NDS.sort(pop), fi), Nil{}))

def is0(c: Nat) -> Bool:
  Nat.is_eq(c, 0n)

def is1(c: Nat) -> Bool:
  Nat.is_eq(c, 1n)

def is2(c: Nat) -> Bool:
  Nat.is_eq(c, 2n)

def cv_of(g: List<&2, F32>) -> F32:
  Ind.constraint_violation(Ind.set_constraints(Ind.from_objectives([0.0]), g))

def feas_of(g: List<&2, F32>) -> Bool:
  Ind.feasible(Ind.set_constraints(Ind.from_objectives([0.0]), g))

def neg_one() -> F32:
  F32.neg(1.0)

def nonpos_g() -> List<&2, F32>:
  neg_one() <> [0.0]

def mixed_g() -> List<&2, F32>:
  neg_one() <> [0.5, 0.25]

def stamp_cv(+f: List<&2, F32>, +rnk: Nat, +g: List<&2, F32>) -> Ind.Individual:
  Ind.set_constraints(Ind.stamp(Ind.from_objectives(f), rnk, 0n, 0n, 0.1), g)

def cv_rank0() -> Ind.Individual:
  stamp_cv([0.2, 0.8], 0n, [1.0])

def cv_rank5() -> Ind.Individual:
  stamp_cv([0.3, 0.7], 5n, [1.0])

def feas_rank1() -> Ind.Individual:
  Ind.stamp(Ind.from_objectives([1.0, 1.0]), 1n, 0n, 0n, 0.9)

def infeas_rank0() -> Ind.Individual:
  Ind.set_constraints(Ind.stamp(Ind.from_objectives([0.0, 0.0]), 0n, 0n, 0n, 0.1), [3.0])

def bad_cv_good_rank() -> Ind.Individual:
  Ind.set_constraints(Ind.stamp(Ind.from_objectives([0.2, 0.8]), 0n, 0n, 0n, 0.1), [5.0])

def small_cv_bad_rank() -> Ind.Individual:
  Ind.set_constraints(Ind.stamp(Ind.from_objectives([0.3, 0.7]), 4n, 9n, 1n, 0.9), [0.25])

def seed682() -> Rng.State:
  Rng.from_nat(682n)

def obj_is(+expect: List<&2, F32>, pair: Rng.State & Ind.Individual) -> Bool:
  (rng, w) = pair
  Util.f32s_eq(expect, Ind.objectives(w))

def nocoin(pair: Rng.State & Ind.Individual) -> Bool:
  (rng, w) = pair
  F32.is_eq(Rng.last_double(rng), 0.0)

def hit_of(trip: List<&2, Ind.Individual> & List<&2, List<&2, F32>> & Bool) -> Bool:
  (acc, seen, hit) = trip
  hit

def picked() -> Ind.Individual:
  Ind.from_variables([0.25], 1n)

def unpicked() -> Ind.Individual:
  Ind.from_variables([0.75], 1n)

def fresh() -> Ind.Individual:
  Ind.from_variables([0.5], 1n)

def survivors() -> List<&2, Ind.Individual>:
  picked() <> unpicked() <> Nil{}

def mating() -> List<&2, Ind.Individual>:
  picked() <> Nil{}

def seen_pop() -> List<&2, List<&2, F32>>:
  Algo.seen_start(survivors(), True{})

def seen_mates() -> List<&2, List<&2, F32>>:
  Algo.seen_start(mating(), True{})

def slot(+pair: Nat, +n: Nat) -> Nat:
  Algo.wrap_pair(pair, n)

def mate(+pair: Nat, +n: Nat) -> Nat:
  Algo.pair_mate(slot(pair, n), n)

def both(+a: Nat, +b: Nat, +ea: Nat, +eb: Nat) -> Bool:
  Bool.and(Nat.is_eq(a, ea), Nat.is_eq(b, eb))

def dup_parent() -> Ind.Individual:
  Ind.from_variables([0.25], 2n)

def dup_offs() -> Rng.State & List<&2, Ind.Individual>:
  Algo.offs_loop(
    0n,
    Algo.OH{1n, 0n, Rng.from_nat(1n), Nil{}, Algo.seen_start(dup_parent() <> Nil{}, True{})},
    dup_parent() <> Nil{},
    Prob.zdt1(1n),
    0.0,
    True{},
    1n
  )

def offs_filled(pair: Rng.State & List<&2, Ind.Individual>) -> Bool:
  (rng, xs) = pair
  match xs:
    case Nil{}:
      False{}
    case +h <> rest:
      Bool.and(Nat.is_eq(Util.list_len(Ind.Individual, h <> rest), 1n), Util.f32s_eq(Ind.variables(h), [0.25]))

def main() -> IO(Unit):
  +feas_pop = pair_pop(feas_worse(), infeas_better())
  +eq_pop = pair_pop(eq_dom(), eq_worse())
  +cv_pop = pair_pop(big_cv(), small_cv())
  do IO<Unit>:
    IO.print(line(Bool.and(F32.is_eq(cv_of(Nil{}), 0.0), feas_of(Nil{})), "empty_g_feasible"))
    IO.print(line(Bool.and(F32.is_eq(cv_of(nonpos_g()), 0.0), feas_of(nonpos_g())), "nonpos_feasible"))
    IO.print(line(Bool.and(F32.is_eq(cv_of(mixed_g()), 0.75), Bool.not(feas_of(mixed_g()))), "pos_parts"))
    IO.print(line(is1(NDS.compare_constraint(feas_worse(), infeas_better())), "feas_dominates"))
    IO.print(line(is2(NDS.compare_constraint(infeas_better(), feas_worse())), "infeas_loses"))
    IO.print(line(Bool.and(Nat.is_eq(nfronts(feas_pop), 2n), Bool.and(on_front(feas_pop, 0n, 0n), on_front(feas_pop, 1n, 1n))), "feas_front"))
    IO.print(line(Bool.and(is0(NDS.compare_constraint(eq_dom(), eq_worse())), is0(NDS.compare_constraint(eq_worse(), eq_dom()))), "equal_cv_mutual"))
    IO.print(line(Bool.and(is1(NDS.compare_pareto([0.0, 0.0], [1.0, 1.0])), Bool.and(Nat.is_eq(nfronts(eq_pop), 1n), Bool.and(on_front(eq_pop, 0n, 0n), on_front(eq_pop, 0n, 1n)))), "equal_cv_one_front"))
    IO.print(line(Bool.and(is2(NDS.compare_constraint(big_cv(), small_cv())), is1(NDS.compare_constraint(small_cv(), big_cv()))), "smaller_cv"))
    IO.print(line(Bool.and(Nat.is_eq(nfronts(cv_pop), 2n), Bool.and(on_front(cv_pop, 0n, 1n), on_front(cv_pop, 1n, 0n))), "smaller_cv_front"))
    IO.print(line(Bool.and(obj_is([1.0, 1.0], Tour.winner(Tour.pymoo(), feas_rank1(), infeas_rank0(), seed682())), nocoin(Tour.winner(Tour.pymoo(), feas_rank1(), infeas_rank0(), seed682()))), "pymoo_feas"))
    IO.print(line(Bool.and(obj_is([1.0, 1.0], Tour.winner(Tour.rank_niche(), feas_rank1(), infeas_rank0(), seed682())), nocoin(Tour.winner(Tour.rank_niche(), feas_rank1(), infeas_rank0(), seed682()))), "rn_feas"))
    IO.print(line(obj_is([0.3, 0.7], Tour.winner(Tour.pymoo(), cv_rank0(), cv_rank5(), seed682())), "pymoo_equal_cv_coin"))
    IO.print(line(Bool.and(obj_is([0.2, 0.8], Tour.winner(Tour.rank_niche(), cv_rank0(), cv_rank5(), seed682())), nocoin(Tour.winner(Tour.rank_niche(), cv_rank0(), cv_rank5(), seed682()))), "rn_equal_cv_rank"))
    IO.print(line(Bool.and(obj_is([0.3, 0.7], Tour.winner(Tour.rank_niche(), bad_cv_good_rank(), small_cv_bad_rank(), seed682())), nocoin(Tour.winner(Tour.rank_niche(), bad_cv_good_rank(), small_cv_bad_rank(), seed682()))), "rn_smaller_cv"))
    IO.print(line(Bool.not(hit_of(Algo.try_add(Nil{}, unpicked(), seen_pop(), True{}))), "unpicked_rejected"))
    IO.print(line(hit_of(Algo.try_add(Nil{}, unpicked(), seen_mates(), True{})), "mates_would_accept"))
    IO.print(line(hit_of(Algo.try_add(Nil{}, fresh(), seen_pop(), True{})), "fresh_accepted"))
    IO.print(line(both(slot(0n, 4n), mate(0n, 4n), 0n, 1n), "even_0"))
    IO.print(line(both(slot(2n, 4n), mate(2n, 4n), 2n, 3n), "even_2"))
    IO.print(line(both(slot(4n, 4n), mate(4n, 4n), 0n, 1n), "even_4"))
    IO.print(line(both(slot(6n, 4n), mate(6n, 4n), 0n, 1n), "even_6"))
    IO.print(line(both(slot(0n, 5n), mate(0n, 5n), 0n, 1n), "odd_0"))
    IO.print(line(both(slot(2n, 5n), mate(2n, 5n), 2n, 3n), "odd_2"))
    IO.print(line(both(slot(4n, 5n), mate(4n, 5n), 4n, 0n), "odd_last"))
    IO.print(line(both(slot(6n, 5n), mate(6n, 5n), 0n, 1n), "odd_6"))
    IO.print(line(both(slot(0n, 1n), mate(0n, 1n), 0n, 0n), "odd_n1"))
    IO.print(line(Bool.and(Nat.is_eq(Algo.dup_fallback_cap(0n), 1n), Nat.is_eq(Algo.dup_fallback_cap(1n), 20n)), "dup_cap"))
    IO.print(line(offs_filled(dup_offs()), "dup_fallback_fills"))
