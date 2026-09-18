# Survival / niching — C# ReferencePointManager + NondominatedSortingSurvival.
# Associate normalized individuals to Das–Dennis rays; select `target_size`
# from a combined pool (fill complete fronts, niche-preserve the last).
# Deterministic when C# rng is null: lowest ref among min-count niches,
# then min perpendicular distance if that niche is empty, else lowest index.

import Base
import ./individual.bend as Ind
import ./non_dominated_sort.bend as NDS
import ./normalization.bend as Norm
import ./util.bend as Util

type Assignment is Data:
  MkAssignment{
    reference_index: Nat
    perpendicular_distance: F32
    niche_count: Nat
  }

def asg_ref(a: Assignment) -> Nat:
  match a:
    case MkAssignment{reference_index, perpendicular_distance, niche_count}:
      reference_index

def asg_dist(a: Assignment) -> F32:
  match a:
    case MkAssignment{reference_index, perpendicular_distance, niche_count}:
      perpendicular_distance

def asg_count(a: Assignment) -> Nat:
  match a:
    case MkAssignment{reference_index, perpendicular_distance, niche_count}:
      niche_count

def get_asg(asgs: List<&2, Assignment>, i: Nat) -> Assignment:
  Maybe.default(&2, Assignment, List.get(&2, Assignment, asgs, i), MkAssignment{0n, 0.0, 0n})

def get_ind(+pop: List<&2, Ind.Individual>, i: Nat) -> Ind.Individual:
  Maybe.default(&2, Ind.Individual, List.get(&2, Ind.Individual, pop, i), Ind.from_objectives(Nil{}))

def perp.big(+f: List<&2, F32>, +w: List<&2, F32>, +ww: F32) -> F32:
  +t = F32.div(Util.vec_dot(f, w), ww)
  F32.sqrt(Util.vec_sqnorm(Util.vec_sub(f, Util.vec_scale(t, w))))

def perp.zero(+f: List<&2, F32>, tiny: Bool) -> F32:
  match tiny:
    case True{}:
      F32.sqrt(Util.vec_sqnorm(f))
    case False{}:
      0.0

def perp.pick(+f: List<&2, F32>, +w: List<&2, F32>, +ww: F32, tiny: Bool) -> F32:
  match tiny:
    case True{}:
      perp.zero(f, True{})
    case False{}:
      perp.big(f, w, ww)

def perp(+f: List<&2, F32>, +w: List<&2, F32>) -> F32:
  +ww = Util.vec_sqnorm(w)
  perp.pick(f, w, ww, F32.is_lt(ww, 0.0000000000000001))

def nearest_go(+f: List<&2, F32>, dirs: List<&2, List<&2, F32>>, +i: Nat, +best_i: Nat, +best_d: F32) -> Assignment:
  match dirs:
    case Nil{}:
      MkAssignment{best_i, best_d, 0n}
    case +w <> ws:
      +d = perp(f, w)
      nearest_go(
        f,
        ws,
        1n+i,
        Bool.pick(Nat, F32.is_lt(d, best_d), i, best_i),
        Bool.pick(F32, F32.is_lt(d, best_d), d, best_d)
      )

def nearest_one(f: List<&2, F32>, dirs: List<&2, List<&2, F32>>) -> Assignment:
  nearest_go(f, dirs, 0n, 0n, 1000000000.0)

def associate_raw(pop: List<&2, Ind.Individual>, F: List<&2, List<&2, F32>>, +dirs: List<&2, List<&2, F32>>) -> List<&2, Assignment>:
  match pop F:
    case Nil{} fs:
      Nil{}
    case ind <> rest Nil{}:
      nearest_one(Ind.objectives(ind), dirs) <> associate_raw(rest, Nil{}, dirs)
    case ind <> rest f <> fs:
      nearest_one(f, dirs) <> associate_raw(rest, fs, dirs)

def count_asg(asgs: List<&2, Assignment>, acc: List<&2, Nat>) -> List<&2, Nat>:
  match asgs:
    case Nil{}:
      acc
    case a <> rest:
      count_asg(rest, Util.inc_at(acc, asg_ref(a)))

def with_counts(+counts: List<&2, Nat>, asgs: List<&2, Assignment>) -> List<&2, Assignment>:
  match asgs:
    case Nil{}:
      Nil{}
    case MkAssignment{+r, d, n} <> rest:
      MkAssignment{r, d, Util.get_nat(counts, r)} <> with_counts(counts, rest)

def associate(+pop: List<&2, Ind.Individual>, +F: List<&2, List<&2, F32>>, +dirs: List<&2, List<&2, F32>>) -> List<&2, Assignment>:
  +raw = associate_raw(pop, F, dirs)
  with_counts(count_asg(raw, Util.zeros_nat(Util.list_len(List<&2, F32>, dirs))), raw)

def front0(fronts: List<&2, List<&2, Nat>>) -> List<&2, Nat>:
  match fronts:
    case Nil{}:
      Nil{}
    case h <> t:
      h

def n_fronts(fronts: List<&2, List<&2, Nat>>) -> Nat:
  Util.list_len(List<&2, Nat>, fronts)

def head_len(fronts: List<&2, List<&2, Nat>>) -> Nat:
  match fronts:
    case Nil{}:
      0n
    case h <> t:
      Util.list_len(Nat, h)

def gather(+pop: List<&2, Ind.Individual>, idxs: List<&2, Nat>) -> List<&2, Ind.Individual>:
  match idxs:
    case Nil{}:
      Nil{}
    case i <> rest:
      get_ind(pop, i) <> gather(pop, rest)

def cand_refs(+asgs: List<&2, Assignment>, cand: List<&2, Nat>) -> List<&2, Nat>:
  match cand:
    case Nil{}:
      Nil{}
    case i <> rest:
      asg_ref(get_asg(asgs, i)) <> cand_refs(asgs, rest)

def min_count(+counts: List<&2, Nat>, refs: List<&2, Nat>, acc: Nat) -> Nat:
  match refs:
    case Nil{}:
      acc
    case +r <> rs:
      min_count(counts, rs, Util.nat_min(acc, Util.get_nat(counts, r)))

def cons_if(h: Nat, rest: List<&2, Nat>, keep: Bool) -> List<&2, Nat>:
  match keep:
    case True{}:
      h <> rest
    case False{}:
      rest

def refs_at(+counts: List<&2, Nat>, +need: Nat, refs: List<&2, Nat>) -> List<&2, Nat>:
  match refs:
    case Nil{}:
      Nil{}
    case +r <> rs:
      cons_if(r, refs_at(counts, need, rs), Nat.is_eq(Util.get_nat(counts, r), need))

def min_idx(xs: List<&2, Nat>, acc: Nat) -> Nat:
  match xs:
    case Nil{}:
      acc
    case +x <> rest:
      min_idx(rest, Util.nat_min(acc, x))

def min_idx_ne(xs: List<&2, Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case x <> rest:
      min_idx(rest, x)

def pick_ref(+asgs: List<&2, Assignment>, +counts: List<&2, Nat>, +cand: List<&2, Nat>) -> Nat:
  +refs = cand_refs(asgs, cand)
  min_idx_ne(refs_at(counts, min_count(counts, refs, 4294967295n), refs))

def in_ref(+asgs: List<&2, Assignment>, +r: Nat, cand: List<&2, Nat>) -> List<&2, Nat>:
  match cand:
    case Nil{}:
      Nil{}
    case +i <> rest:
      cons_if(i, in_ref(asgs, r, rest), Nat.is_eq(asg_ref(get_asg(asgs, i)), r))

def argmin_dist.go(+asgs: List<&2, Assignment>, cand: List<&2, Nat>, +best_i: Nat, +best_d: F32) -> Nat:
  match cand:
    case Nil{}:
      best_i
    case +i <> rest:
      +d = asg_dist(get_asg(asgs, i))
      argmin_dist.go(
        asgs,
        rest,
        Bool.pick(Nat, F32.is_lt(d, best_d), i, best_i),
        Bool.pick(F32, F32.is_lt(d, best_d), d, best_d)
      )

def argmin_dist(+asgs: List<&2, Assignment>, cand: List<&2, Nat>) -> Nat:
  match cand:
    case Nil{}:
      0n
    case +i <> rest:
      argmin_dist.go(asgs, rest, i, asg_dist(get_asg(asgs, i)))

def pick_member.by(+asgs: List<&2, Assignment>, group: List<&2, Nat>, empty_niche: Bool) -> Nat:
  match empty_niche:
    case True{}:
      argmin_dist(asgs, group)
    case False{}:
      min_idx_ne(group)

def pick_member(+asgs: List<&2, Assignment>, +counts: List<&2, Nat>, +cand: List<&2, Nat>, +r: Nat) -> Nat:
  pick_member.by(asgs, in_ref(asgs, r, cand), Nat.is_eq(Util.get_nat(counts, r), 0n))

def seed_counts(+asgs: List<&2, Assignment>, selected: List<&2, Nat>, acc: List<&2, Nat>) -> List<&2, Nat>:
  match selected:
    case Nil{}:
      acc
    case i <> rest:
      seed_counts(asgs, rest, Util.inc_at(acc, asg_ref(get_asg(asgs, i))))

# fuel, k, cand first so the match follows binder order and fuel shrinks.
def niche_loop(fuel: Nat, k: Nat, cand: List<&2, Nat>, +asgs: List<&2, Assignment>, +counts: List<&2, Nat>, selected: List<&2, Nat>) -> List<&2, Nat>:
  match fuel k cand:
    case 0n kk c:
      selected
    case f 0n c:
      selected
    case f kk Nil{}:
      selected
    case 1n+f 1n+krest +c0 <> +cs:
      +cand2 = {c0 <> cs : List<&2, Nat>}
      +r = pick_ref(asgs, counts, cand2)
      +pick = pick_member(asgs, counts, cand2, r)
      niche_loop(
        f,
        krest,
        Util.minus(cand2, [pick]),
        asgs,
        Util.inc_at(counts, r),
        List.append(&2, Nat, selected, [pick])
      )

def fill(fuel: Nat, fronts: List<&2, List<&2, Nat>>, fits: Bool, +acc: List<&2, Nat>, +target: Nat, +asgs: List<&2, Assignment>, +n_dirs: Nat) -> List<&2, Nat>:
  match fuel fronts fits:
    case 0n fs p:
      acc
    case f Nil{} p:
      acc
    case 1n+f +fr <> +rest False{}:
      +need = Nat.sub(target, Util.list_len(Nat, acc))
      niche_loop(
        1n+Util.list_len(Nat, fr),
        need,
        fr,
        asgs,
        seed_counts(asgs, acc, Util.zeros_nat(n_dirs)),
        acc
      )
    case 1n+f +fr <> +rest True{}:
      +new_acc = List.append(&2, Nat, acc, fr)
      fill(
        f,
        rest,
        Nat.is_le(Nat.add(Util.list_len(Nat, new_acc), head_len(rest)), target),
        new_acc,
        target,
        asgs,
        n_dirs
      )

def fill.wrap(+fronts: List<&2, List<&2, Nat>>, +target: Nat, +asgs: List<&2, Assignment>, +n_dirs: Nat) -> List<&2, Nat>:
  fill(
    1n+n_fronts(fronts),
    fronts,
    Nat.is_le(head_len(fronts), target),
    Nil{},
    target,
    asgs,
    n_dirs
  )

def select_idx.with(+pop: List<&2, Ind.Individual>, +target: Nat, +dirs: List<&2, List<&2, F32>>, +fronts: List<&2, List<&2, Nat>>, pair: Norm.State & List<&2, List<&2, F32>>) -> List<&2, Nat>:
  (st, F) = pair
  fill.wrap(fronts, target, associate(pop, F, dirs), Util.list_len(List<&2, F32>, dirs))

def select_idx.big(+pop: List<&2, Ind.Individual>, +target: Nat, +dirs: List<&2, List<&2, F32>>) -> List<&2, Nat>:
  +fronts = NDS.sort(pop)
  select_idx.with(pop, target, dirs, fronts, Norm.normalize_nd(Norm.new_state(0n), pop, front0(fronts)))

def select_idx.dirs(+pop: List<&2, Ind.Individual>, +target: Nat, +dirs: List<&2, List<&2, F32>>, empty_dirs: Bool) -> List<&2, Nat>:
  match empty_dirs:
    case True{}:
      List.take(&2, Nat, List.range(Util.list_len(Ind.Individual, pop)), target)
    case False{}:
      select_idx.big(pop, target, dirs)

def select_idx.by(+pop: List<&2, Ind.Individual>, +target: Nat, +dirs: List<&2, List<&2, F32>>, small: Bool) -> List<&2, Nat>:
  match small:
    case True{}:
      List.range(Util.list_len(Ind.Individual, pop))
    case False{}:
      select_idx.dirs(pop, target, dirs, List.is_empty(&2, List<&2, F32>, dirs))

def select_idx(+combined: List<&2, Ind.Individual>, +target_size: Nat, +dirs: List<&2, List<&2, F32>>) -> List<&2, Nat>:
  +n = Util.list_len(Ind.Individual, combined)
  select_idx.by(combined, target_size, dirs, Nat.is_le(n, target_size))

def select(+combined: List<&2, Ind.Individual>, +target_size: Nat, +dirs: List<&2, List<&2, F32>>) -> List<&2, Ind.Individual>:
  gather(combined, select_idx(combined, target_size, dirs))

# Persistent-normalization Select for Unsga3Algorithm.Run. Same
# deterministic niching as `select` (C# `rng == null`). Threads the
# Normalization state so ideal / extremes persist across generations.
def select_st.with(+pop: List<&2, Ind.Individual>, +target: Nat, +dirs: List<&2, List<&2, F32>>, +fronts: List<&2, List<&2, Nat>>, pair: Norm.State & List<&2, List<&2, F32>>) -> Norm.State & List<&2, Ind.Individual>:
  (st, F) = pair
  (st, gather(pop, fill.wrap(fronts, target, associate(pop, F, dirs), Util.list_len(List<&2, F32>, dirs))))

def select_st.big(+pop: List<&2, Ind.Individual>, +target: Nat, +dirs: List<&2, List<&2, F32>>, state: Norm.State) -> Norm.State & List<&2, Ind.Individual>:
  +fronts = NDS.sort(pop)
  select_st.with(pop, target, dirs, fronts, Norm.normalize_nd(state, pop, front0(fronts)))

def select_st.take(+pop: List<&2, Ind.Individual>, +target: Nat, state: Norm.State) -> Norm.State & List<&2, Ind.Individual>:
  (state, gather(pop, List.take(&2, Nat, List.range(Util.list_len(Ind.Individual, pop)), target)))

def select_st.dirs(+pop: List<&2, Ind.Individual>, +target: Nat, +dirs: List<&2, List<&2, F32>>, state: Norm.State, empty_dirs: Bool) -> Norm.State & List<&2, Ind.Individual>:
  match empty_dirs:
    case True{}:
      select_st.take(pop, target, state)
    case False{}:
      select_st.big(pop, target, dirs, state)

def select_st.by(+pop: List<&2, Ind.Individual>, +target: Nat, +dirs: List<&2, List<&2, F32>>, state: Norm.State, small: Bool) -> Norm.State & List<&2, Ind.Individual>:
  match small:
    case True{}:
      (state, pop)
    case False{}:
      select_st.dirs(pop, target, dirs, state, List.is_empty(&2, List<&2, F32>, dirs))

def select_st(+combined: List<&2, Ind.Individual>, +target_size: Nat, +dirs: List<&2, List<&2, F32>>, state: Norm.State) -> Norm.State & List<&2, Ind.Individual>:
  +n = Util.list_len(Ind.Individual, combined)
  select_st.by(combined, target_size, dirs, state, Nat.is_le(n, target_size))
