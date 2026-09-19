# Mating tournament — C# TournamentSelection / TournamentMode.
# Default for algorithm A/B is PymooCompatible (pymoo
# comp_by_rank_and_ref_line_dist): same niche → rank then perp dist;
# else random. RankNicheDistance (C# default: rank → niche count → dist)
# is also implemented. This slice is unconstrained, so CV branches are
# unused (all individuals are treated feasible).

import Base
import ./individual.bend as Ind
import ./non_dominated_sort.bend as NDS
import ./normalization.bend as Norm
import ./survival.bend as Surv
import ./rng.bend as Rng
import ./util.bend as Util

type Mode is Data:
  PymooCompatible{}
  RankNicheDistance{}

def pymoo() -> Mode:
  PymooCompatible{}

def rank_niche() -> Mode:
  RankNicheDistance{}

def get_ind(+pop: List<&2, Ind.Individual>, i: Nat) -> Ind.Individual:
  Maybe.default(&2, Ind.Individual, List.get(&2, Ind.Individual, pop, i), Ind.from_objectives(Nil{}))

def coin(a: Ind.Individual, b: Ind.Individual, rng: Rng.State) -> Rng.State & Ind.Individual:
  +rng2 = Rng.next_double(rng)
  (rng2, Bool.pick(Ind.Individual, F32.is_lt(Rng.last_double(rng2), 0.5), a, b))

def cmp_pick(a: Ind.Individual, b: Ind.Individual, rng: Rng.State, ab: Bool, ba: Bool) -> Rng.State & Ind.Individual:
  match ab ba:
    case True{} _:
      (rng, a)
    case False{} True{}:
      (rng, b)
    case False{} False{}:
      coin(a, b, rng)

def by_dist(+a: Ind.Individual, +b: Ind.Individual, rng: Rng.State) -> Rng.State & Ind.Individual:
  +da = Ind.perp_dist(a)
  +db = Ind.perp_dist(b)
  cmp_pick(a, b, rng, F32.is_lt(da, db), F32.is_lt(db, da))

def by_rank.eq(+a: Ind.Individual, +b: Ind.Individual, rng: Rng.State, same: Bool) -> Rng.State & Ind.Individual:
  match same:
    case True{}:
      by_dist(a, b, rng)
    case False{}:
      cmp_pick(a, b, rng, Nat.is_lt(Ind.rank(a), Ind.rank(b)), Nat.is_lt(Ind.rank(b), Ind.rank(a)))

def by_rank(+a: Ind.Individual, +b: Ind.Individual, rng: Rng.State) -> Rng.State & Ind.Individual:
  by_rank.eq(a, b, rng, Nat.is_eq(Ind.rank(a), Ind.rank(b)))

def winner_pymoo.same(+a: Ind.Individual, +b: Ind.Individual, rng: Rng.State, same: Bool) -> Rng.State & Ind.Individual:
  match same:
    case True{}:
      by_rank(a, b, rng)
    case False{}:
      coin(a, b, rng)

def winner_pymoo(+a: Ind.Individual, +b: Ind.Individual, rng: Rng.State) -> Rng.State & Ind.Individual:
  winner_pymoo.same(a, b, rng, Nat.is_eq(Ind.associated_ref(a), Ind.associated_ref(b)))

def by_niche(+a: Ind.Individual, +b: Ind.Individual, rng: Rng.State) -> Rng.State & Ind.Individual:
  +na = Ind.niche(a)
  +nb = Ind.niche(b)
  cmp_pick(a, b, rng, Nat.is_lt(na, nb), Nat.is_lt(nb, na))

def winner_rnd.eq(+a: Ind.Individual, +b: Ind.Individual, rng: Rng.State, same: Bool) -> Rng.State & Ind.Individual:
  match same:
    case True{}:
      by_niche(a, b, rng)
    case False{}:
      cmp_pick(a, b, rng, Nat.is_lt(Ind.rank(a), Ind.rank(b)), Nat.is_lt(Ind.rank(b), Ind.rank(a)))

def winner_rnd(+a: Ind.Individual, +b: Ind.Individual, rng: Rng.State) -> Rng.State & Ind.Individual:
  winner_rnd.eq(a, b, rng, Nat.is_eq(Ind.rank(a), Ind.rank(b)))

def winner(mode: Mode, +a: Ind.Individual, +b: Ind.Individual, rng: Rng.State) -> Rng.State & Ind.Individual:
  match mode:
    case PymooCompatible{}:
      winner_pymoo(a, b, rng)
    case RankNicheDistance{}:
      winner_rnd(a, b, rng)

def one(+mode: Mode, +pop: List<&2, Ind.Individual>, rng: Rng.State) -> Rng.State & Ind.Individual:
  +n = Util.list_len(Ind.Individual, pop)
  +rng_a = Rng.next_nat(rng, n)
  +ia = Rng.last_nat(rng_a)
  +rng_b = Rng.next_except(rng_a, n, ia)
  +ib = Rng.last_nat(rng_b)
  winner(mode, get_ind(pop, ia), get_ind(pop, ib), rng_b)

type PHold is Data:
  PH{
    rng: Rng.State
    acc: List<&2, Ind.Individual>
  }

def parents_next.w(acc: List<&2, Ind.Individual>, pair: Rng.State & Ind.Individual) -> PHold:
  (rng, w) = pair
  PH{rng, w <> acc}

def parents_next(+mode: Mode, +pop: List<&2, Ind.Individual>, hold: PHold) -> PHold:
  match hold:
    case PH{rng, acc}:
      parents_next.w(acc, one(mode, pop, rng))

def parents_loop(fuel: Nat, hold: PHold, +mode: Mode, +pop: List<&2, Ind.Individual>) -> Rng.State & List<&2, Ind.Individual>:
  match fuel hold:
    case 0n PH{rng, acc}:
      (rng, List.reverse(&2, Ind.Individual, acc))
    case 1n+f h:
      parents_loop(f, parents_next(mode, pop, h), mode, pop)

def select_parents(+mode: Mode, +pop: List<&2, Ind.Individual>, count: Nat, rng: Rng.State) -> Rng.State & List<&2, Ind.Individual>:
  parents_loop(count, PH{rng, Nil{}}, mode, pop)

def parents_of(pair: Rng.State & List<&2, Ind.Individual>) -> List<&2, Ind.Individual>:
  (rng, xs) = pair
  xs

def stamp_front(idxs: List<&2, Nat>, +pop: List<&2, Ind.Individual>, +r: Nat) -> List<&2, Ind.Individual>:
  match idxs:
    case Nil{}:
      pop
    case +i <> rest:
      stamp_front(rest, List.set(&2, Ind.Individual, pop, i, Ind.set_rank(get_ind(pop, i), r)), r)

def stamp_ranks(fronts: List<&2, List<&2, Nat>>, pop: List<&2, Ind.Individual>, +r: Nat) -> List<&2, Ind.Individual>:
  match fronts:
    case Nil{}:
      pop
    case fr <> rest:
      stamp_ranks(rest, stamp_front(fr, pop, r), 1n+r)

def stamp_asgs.go(pop: List<&2, Ind.Individual>, asgs: List<&2, Surv.Assignment>, +i: Nat) -> List<&2, Ind.Individual>:
  match pop asgs:
    case Nil{} ys:
      Nil{}
    case xs Nil{}:
      xs
    case +ind <> rest +a <> as:
      Ind.stamp(ind, Ind.rank(ind), Surv.asg_count(a), Surv.asg_ref(a), Surv.asg_dist(a)) <> stamp_asgs.go(rest, as, 1n+i)

def stamp_asgs(pop: List<&2, Ind.Individual>, asgs: List<&2, Surv.Assignment>) -> List<&2, Ind.Individual>:
  stamp_asgs.go(pop, asgs, 0n)

def prepare.with(+dirs: List<&2, List<&2, F32>>, +pop: List<&2, Ind.Individual>, +fronts: List<&2, List<&2, Nat>>, pair: Norm.State & List<&2, List<&2, F32>>) -> Norm.State & List<&2, Ind.Individual>:
  (st, F) = pair
  +ranked = stamp_ranks(fronts, pop, 0n)
  (st, stamp_asgs(ranked, Surv.associate(ranked, F, dirs)))

# Recompute ranks + niche association (C# PrepareForSelection). Threads
# the persistent Normalization state.
def prepare(+pop: List<&2, Ind.Individual>, +dirs: List<&2, List<&2, F32>>, state: Norm.State) -> Norm.State & List<&2, Ind.Individual>:
  +fronts = NDS.sort(pop)
  prepare.with(dirs, pop, fronts, Norm.normalize_nd(state, pop, Surv.front0(fronts)))
