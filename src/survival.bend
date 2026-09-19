# Survival / niching — C# ReferencePointManager + NondominatedSortingSurvival.
# Independent maps (associate / histograms / gather) use mid-split
# `a b = f(lo) f(hi)`. Nearest-ref stays sequential (associate_raw already
# splits per individual). Last-front fill builds `NRow{i, ref, dist}` once
# so the sequential niche loop never `List.get`s an Assignment (or a fat
# Individual) per remaining candidate. Same pick rules / same RNG order.
# Associate normalized individuals to Das–Dennis rays; select `target_size`
# from a combined pool (fill complete fronts, niche-preserve the last).
# Deterministic when C# rng is null (`select`): lowest ref among min-count
# niches, then min perpendicular distance if that niche is empty, else
# lowest index. `select_st` (Run) threads rng: random among equal
# min-count niches (C# Select(..., rng)). Empty niches take the closest
# unused member; extras draw among members within 2×best+0.01 of the
# ray — not uniform inNiche[rng.Next], which collapsed oracle ZDT2.

import Base
import ./individual.bend as Ind
import ./non_dominated_sort.bend as NDS
import ./normalization.bend as Norm
import ./rng.bend as Rng
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

# Last-front row: population index plus the two fields the fill loop
# reads. Built once from `asgs` so each pick walks this thin list
# instead of `List.get` into the combined-pool assignment spine.
type NRow is Data:
  NRow{
    i: Nat
    r: Nat
    d: F32
  }

def nrow_i(row: NRow) -> Nat:
  match row:
    case NRow{i, r, d}:
      i

def nrow_r(row: NRow) -> Nat:
  match row:
    case NRow{i, r, d}:
      r

def nrow_d(row: NRow) -> F32:
  match row:
    case NRow{i, r, d}:
      d

def nrows_of.go(+asgs: List<&2, Assignment>, cand: List<&2, Nat>, acc: List<&2, NRow>) -> List<&2, NRow>:
  match cand:
    case Nil{}:
      List.reverse(&2, NRow, acc)
    case +i <> rest:
      +a = get_asg(asgs, i)
      nrows_of.go(asgs, rest, NRow{i, asg_ref(a), asg_dist(a)} <> acc)

def nrows_of(+asgs: List<&2, Assignment>, +cand: List<&2, Nat>) -> List<&2, NRow>:
  nrows_of.go(asgs, cand, Nil{})

def first_row_i(rows: List<&2, NRow>) -> Nat:
  match rows:
    case Nil{}:
      0n
    case +row <> _:
      nrow_i(row)

def first_row_r(rows: List<&2, NRow>) -> Nat:
  match rows:
    case Nil{}:
      0n
    case +row <> _:
      nrow_r(row)

def get_nrow(rows: List<&2, NRow>, i: Nat) -> NRow:
  Maybe.default(&2, NRow, List.get(&2, NRow, rows, i), NRow{0n, 0n, 0.0})

def drop_nrow.put(+row: NRow, rest: List<&2, NRow>, drop: Bool) -> List<&2, NRow>:
  match drop:
    case True{}:
      rest
    case False{}:
      row <> rest

def drop_nrow(rows: List<&2, NRow>, +pick: Nat) -> List<&2, NRow>:
  match rows:
    case Nil{}:
      Nil{}
    case +row <> rest:
      drop_nrow.put(row, drop_nrow(rest, pick), Nat.is_eq(nrow_i(row), pick))

def keep_nat(h: Nat, rest: List<&2, Nat>, keep: Bool) -> List<&2, Nat>:
  match keep:
    case True{}:
      h <> rest
    case False{}:
      rest

def uniq_refs.go(rows: List<&2, NRow>, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match rows:
    case Nil{}:
      List.reverse(&2, Nat, acc)
    case +row <> rest:
      +r = nrow_r(row)
      uniq_refs.go(rest, keep_nat(r, acc, Bool.not(Util.in_nats(r, acc))))

def uniq_refs(rows: List<&2, NRow>) -> List<&2, Nat>:
  uniq_refs.go(rows, Nil{})

def min_count_rows.go(+counts: List<&2, Nat>, rows: List<&2, NRow>, +acc: Nat) -> Nat:
  match rows:
    case Nil{}:
      acc
    case +row <> rest:
      min_count_rows.go(counts, rest, Util.nat_min(acc, Util.get_nat(counts, nrow_r(row))))

def min_count_rows(+counts: List<&2, Nat>, rows: List<&2, NRow>) -> Nat:
  min_count_rows.go(counts, rows, 4294967295n)

def refs_at_seq(+counts: List<&2, Nat>, +need: Nat, refs: List<&2, Nat>) -> List<&2, Nat>:
  match refs:
    case Nil{}:
      Nil{}
    case +r <> rest:
      keep_nat(r, refs_at_seq(counts, need, rest), Nat.is_eq(Util.get_nat(counts, r), need))

def in_ref_rows(+r: Nat, rows: List<&2, NRow>) -> List<&2, NRow>:
  match rows:
    case Nil{}:
      Nil{}
    case +row <> rest:
      Util.keep_if(NRow, row, in_ref_rows(r, rest), Nat.is_eq(nrow_r(row), r))

def argmin_dist_rows.go(rows: List<&2, NRow>, +best_i: Nat, +best_d: F32) -> Nat:
  match rows:
    case Nil{}:
      best_i
    case +row <> rest:
      +d = nrow_d(row)
      +lt = F32.is_lt(d, best_d)
      argmin_dist_rows.go(rest, Bool.pick(Nat, lt, nrow_i(row), best_i), Bool.pick(F32, lt, d, best_d))

def argmin_dist_rows(rows: List<&2, NRow>) -> Nat:
  match rows:
    case Nil{}:
      0n
    case +row <> rest:
      argmin_dist_rows.go(rest, nrow_i(row), nrow_d(row))

def min_dist_rows.go(rows: List<&2, NRow>, +acc: F32) -> F32:
  match rows:
    case Nil{}:
      acc
    case +row <> rest:
      +d = nrow_d(row)
      min_dist_rows.go(rest, Bool.pick(F32, F32.is_lt(d, acc), d, acc))

def min_dist_rows(rows: List<&2, NRow>) -> F32:
  match rows:
    case Nil{}:
      0.0
    case +row <> rest:
      min_dist_rows.go(rest, nrow_d(row))

def min_idx_rows.go(rows: List<&2, NRow>, +acc: Nat) -> Nat:
  match rows:
    case Nil{}:
      acc
    case +row <> rest:
      min_idx_rows.go(rest, Util.nat_min(acc, nrow_i(row)))

def min_idx_rows(rows: List<&2, NRow>) -> Nat:
  match rows:
    case Nil{}:
      0n
    case +row <> rest:
      min_idx_rows.go(rest, nrow_i(row))

def near_rows(+lim: F32, rows: List<&2, NRow>) -> List<&2, NRow>:
  match rows:
    case Nil{}:
      Nil{}
    case +row <> rest:
      Util.keep_if(NRow, row, near_rows(lim, rest), F32.is_le(nrow_d(row), lim))

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

# First-min on strict `<` (ties keep the lower index). Sequential over
# dirs; associate_raw already mid-splits per individual.
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

def associate_head(+dirs: List<&2, List<&2, F32>>, +ind: Ind.Individual, F: List<&2, List<&2, F32>>) -> Assignment:
  match F:
    case Nil{}:
      nearest_one(Ind.objectives(ind), dirs)
    case f <> fs:
      nearest_one(f, dirs)

# Nearest-ref per individual is independent given dirs. Mid-split pop and F.
def associate_raw.go(
  +dirs: List<&2, List<&2, F32>>,
  +fuel: Nat,
  pop: List<&2, Ind.Individual>,
  +F: List<&2, List<&2, F32>>
) -> List<&2, Assignment>:
  match fuel pop:
    case 0n Nil{}:
      Nil{}
    case 0n ind <> rest:
      match F:
        case Nil{}:
          nearest_one(Ind.objectives(ind), dirs) <> associate_raw.go(dirs, 0n, rest, Nil{})
        case f <> fs:
          nearest_one(f, dirs) <> associate_raw.go(dirs, 0n, rest, fs)
    case 1n+p Nil{}:
      Nil{}
    case 1n+p ind <> Nil{}:
      associate_head(dirs, ind, F) <> Nil{}
    case 1n+p h <> t:
      +all = {h <> t : List<&2, Ind.Individual>}
      +mid = Nat.div(Util.list_len(Ind.Individual, all), 2n)
      lo hi = associate_raw.go(dirs, p, List.take(&2, Ind.Individual, all, mid), List.take(&2, List<&2, F32>, F, mid)) associate_raw.go(dirs, p, List.drop(&2, Ind.Individual, all, mid), List.drop(&2, List<&2, F32>, F, mid))
      List.append(&2, Assignment, lo, hi)

def associate_raw(+pop: List<&2, Ind.Individual>, +F: List<&2, List<&2, F32>>, +dirs: List<&2, List<&2, F32>>) -> List<&2, Assignment>:
  associate_raw.go(dirs, Util.list_len(Ind.Individual, pop), pop, F)

# Histogram increments commute. Mid-split asgs, then add count vectors.
def count_raw.go(+n: Nat, +fuel: Nat, asgs: List<&2, Assignment>) -> List<&2, Nat>:
  match fuel asgs:
    case 0n Nil{}:
      Util.zeros_nat(n)
    case 0n a <> rest:
      Util.inc_at(count_raw.go(n, 0n, rest), asg_ref(a))
    case 1n+p Nil{}:
      Util.zeros_nat(n)
    case 1n+p a <> Nil{}:
      Util.inc_at(Util.zeros_nat(n), asg_ref(a))
    case 1n+p h <> t:
      +all = {h <> t : List<&2, Assignment>}
      +mid = Nat.div(Util.list_len(Assignment, all), 2n)
      lo hi = count_raw.go(n, p, List.take(&2, Assignment, all, mid)) count_raw.go(n, p, List.drop(&2, Assignment, all, mid))
      Util.nats_add(lo, hi)

def count_asg(+asgs: List<&2, Assignment>, +acc: List<&2, Nat>) -> List<&2, Nat>:
  Util.nats_add(acc, count_raw.go(Util.list_len(Nat, acc), Util.list_len(Assignment, asgs), asgs))

def with_counts.one(+counts: List<&2, Nat>, +a: Assignment) -> Assignment:
  match a:
    case MkAssignment{+r, d, n}:
      MkAssignment{r, d, Util.get_nat(counts, r)}

def with_counts(+counts: List<&2, Nat>, +asgs: List<&2, Assignment>) -> List<&2, Assignment>:
  Util.map_halves(~Assignment, ~Assignment, ~List<&2, Nat>, ~with_counts.one, counts, asgs)

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

def gather.one(+pop: List<&2, Ind.Individual>, +i: Nat) -> Ind.Individual:
  get_ind(pop, i)

def gather(+pop: List<&2, Ind.Individual>, +idxs: List<&2, Nat>) -> List<&2, Ind.Individual>:
  Util.map_halves(~Nat, ~Ind.Individual, ~List<&2, Ind.Individual>, ~gather.one, pop, idxs)

def cand_ref.one(+asgs: List<&2, Assignment>, +i: Nat) -> Nat:
  asg_ref(get_asg(asgs, i))

def cand_refs(+asgs: List<&2, Assignment>, cand: List<&2, Nat>) -> List<&2, Nat>:
  Util.map_halves(~Nat, ~Nat, ~List<&2, Assignment>, ~cand_ref.one, asgs, cand)

def min_count.go(+counts: List<&2, Nat>, +fuel: Nat, refs: List<&2, Nat>) -> Nat:
  match fuel refs:
    case 0n Nil{}:
      4294967295n
    case 0n +r <> rs:
      Util.nat_min(Util.get_nat(counts, r), min_count.go(counts, 0n, rs))
    case 1n+p Nil{}:
      4294967295n
    case 1n+p +r <> Nil{}:
      Util.get_nat(counts, r)
    case 1n+p h <> t:
      +all = {h <> t : List<&2, Nat>}
      +mid = Nat.div(Util.list_len(Nat, all), 2n)
      lo hi = min_count.go(counts, p, List.take(&2, Nat, all, mid)) min_count.go(counts, p, List.drop(&2, Nat, all, mid))
      Util.nat_min(lo, hi)

def min_count(+counts: List<&2, Nat>, refs: List<&2, Nat>, acc: Nat) -> Nat:
  match refs:
    case Nil{}:
      acc
    case +r <> +rs:
      +xs = {r <> rs : List<&2, Nat>}
      Util.nat_min(acc, min_count.go(counts, Util.list_len(Nat, xs), xs))

def cons_if(h: Nat, rest: List<&2, Nat>, keep: Bool) -> List<&2, Nat>:
  match keep:
    case True{}:
      h <> rest
    case False{}:
      rest

# First-occurrence unique (C# HashSet of refs-with-candidates).
def uniq_nats.go(xs: List<&2, Nat>, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      List.reverse(&2, Nat, acc)
    case +h <> t:
      uniq_nats.go(t, cons_if(h, acc, Bool.not(Util.in_nats(h, acc))))

def uniq_nats(xs: List<&2, Nat>) -> List<&2, Nat>:
  uniq_nats.go(xs, Nil{})

type CntNeed is Data:
  CN{
    counts: List<&2, Nat>
    need: Nat
  }

def refs_at.ok(+ctx: CntNeed, +r: Nat) -> Bool:
  match ctx:
    case CN{counts, need}:
      Nat.is_eq(Util.get_nat(counts, r), need)

def refs_at(+counts: List<&2, Nat>, +need: Nat, refs: List<&2, Nat>) -> List<&2, Nat>:
  Util.filter_halves(~Nat, ~CntNeed, ~refs_at.ok, CN{counts, need}, refs)

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

type RefPick is Data:
  RP{
    asgs: List<&2, Assignment>
    r: Nat
  }

def in_ref.ok(+ctx: RefPick, +i: Nat) -> Bool:
  match ctx:
    case RP{asgs, r}:
      Nat.is_eq(asg_ref(get_asg(asgs, i)), r)

def in_ref(+asgs: List<&2, Assignment>, +r: Nat, cand: List<&2, Nat>) -> List<&2, Nat>:
  Util.filter_halves(~Nat, ~RefPick, ~in_ref.ok, RP{asgs, r}, cand)

def argmin_join(+asgs: List<&2, Assignment>, +ia: Nat, +ib: Nat) -> Nat:
  Bool.pick(Nat, F32.is_lt(asg_dist(get_asg(asgs, ib)), asg_dist(get_asg(asgs, ia))), ib, ia)

def argmin_dist.go(+asgs: List<&2, Assignment>, +fuel: Nat, cand: List<&2, Nat>) -> Nat:
  match fuel cand:
    case 0n Nil{}:
      0n
    case 0n +i <> Nil{}:
      i
    case 0n +i <> +j <> js:
      argmin_join(asgs, i, argmin_dist.go(asgs, 0n, j <> js))
    case 1n+p Nil{}:
      0n
    case 1n+p +i <> Nil{}:
      i
    case 1n+p h <> t:
      +all = {h <> t : List<&2, Nat>}
      +mid = Nat.div(Util.list_len(Nat, all), 2n)
      lo hi = argmin_dist.go(asgs, p, List.take(&2, Nat, all, mid)) argmin_dist.go(asgs, p, List.drop(&2, Nat, all, mid))
      argmin_join(asgs, lo, hi)

def argmin_dist(+asgs: List<&2, Assignment>, cand: List<&2, Nat>) -> Nat:
  match cand:
    case Nil{}:
      0n
    case +i <> +rest:
      +xs = {i <> rest : List<&2, Nat>}
      argmin_dist.go(asgs, Util.list_len(Nat, xs), xs)

def pick_member.by(+asgs: List<&2, Assignment>, group: List<&2, Nat>, empty_niche: Bool) -> Nat:
  match empty_niche:
    case True{}:
      argmin_dist(asgs, group)
    case False{}:
      min_idx_ne(group)

# First remaining last-front index. Used when inNiche is empty
# (C# would throw; never pick a phantom combined-pool index 0).
def first_cand(cand: List<&2, Nat>) -> Nat:
  match cand:
    case Nil{}:
      0n
    case x <> _:
      x

def pick_member.by.safe(+asgs: List<&2, Assignment>, group: List<&2, Nat>, empty_niche: Bool, +fallback: Nat) -> Nat:
  match group:
    case Nil{}:
      fallback
    case g0 <> gs:
      pick_member.by(asgs, {g0 <> gs : List<&2, Nat>}, empty_niche)

def pick_member(+asgs: List<&2, Assignment>, +counts: List<&2, Nat>, +cand: List<&2, Nat>, +r: Nat) -> Nat:
  pick_member.by.safe(asgs, in_ref(asgs, r, cand), Nat.is_eq(Util.get_nat(counts, r), 0n), first_cand(cand))

# Affine API: advanced State; chosen index is `Rng.last_nat` (no pair match).
# C# Select(..., rng): draw only when more than one min-count ref.
def pick_ref.rng.go(+mins: List<&2, Nat>, n: Nat, +fallback: Nat, rng: Rng.State) -> Rng.State:
  match n:
    case 0n:
      Rng.with_k(rng, fallback)
    case 1n:
      Rng.with_k(rng, min_idx_ne(mins))
    case 1n+p:
      +rng2 = Rng.next_nat(rng, 1n+p)
      Rng.with_k(rng2, Util.get_nat(mins, Rng.last_nat(rng2)))

def pick_ref.rng.after(+mins: List<&2, Nat>, +fallback: Nat, rng: Rng.State) -> Rng.State:
  pick_ref.rng.go(mins, Util.list_len(Nat, mins), fallback, rng)

def pick_ref.rng(+asgs: List<&2, Assignment>, +counts: List<&2, Nat>, +cand: List<&2, Nat>, rng: Rng.State) -> Rng.State:
  +refs = uniq_nats(cand_refs(asgs, cand))
  pick_ref.rng.after(
    refs_at(counts, min_count(counts, refs, 4294967295n), refs),
    asg_ref(get_asg(asgs, first_cand(cand))),
    rng
  )

# Uniform inNiche[rng.Next] (C# non-empty + rng) lets far-from-ray last-front
# junk into a niche. With this LCG that pile-up dominates ZDT2's concave
# front (x0 → 0). Draw extras only among members within 2×best+0.01 of
# the ray (first assignment to a niche stays closest).
def near_lim(+best: F32) -> F32:
  F32.add(F32.mul(best, 2.0), 0.01)

def near_ok(+asgs: List<&2, Assignment>, +i: Nat, +lim: F32) -> Bool:
  F32.is_le(asg_dist(get_asg(asgs, i)), lim)

type NearPick is Data:
  NP{
    asgs: List<&2, Assignment>
    lim: F32
  }

def near_members.ok(+ctx: NearPick, +i: Nat) -> Bool:
  match ctx:
    case NP{asgs, lim}:
      near_ok(asgs, i, lim)

def near_members(+asgs: List<&2, Assignment>, group: List<&2, Nat>, +lim: F32) -> List<&2, Nat>:
  Util.filter_halves(~Nat, ~NearPick, ~near_members.ok, NP{asgs, lim}, group)

def pick_among.rng(+group: List<&2, Nat>, n: Nat, +fallback: Nat, rng: Rng.State) -> Rng.State:
  match n:
    case 0n:
      Rng.with_k(rng, fallback)
    case 1n:
      Rng.with_k(rng, min_idx_ne(group))
    case 1n+p:
      +rng2 = Rng.next_nat(rng, 1n+p)
      Rng.with_k(rng2, Util.get_nat(group, Rng.last_nat(rng2)))

def pick_near.rng(+asgs: List<&2, Assignment>, +group: List<&2, Nat>, rng: Rng.State) -> Rng.State:
  +near = near_members(asgs, group, near_lim(asg_dist(get_asg(asgs, argmin_dist(asgs, group)))))
  pick_among.rng(near, Util.list_len(Nat, near), first_cand(group), rng)

def pick_member.rng.empty(+asgs: List<&2, Assignment>, +group: List<&2, Nat>, empty_niche: Bool, rng: Rng.State) -> Rng.State:
  match empty_niche:
    case True{}:
      Rng.with_k(rng, argmin_dist(asgs, group))
    case False{}:
      pick_near.rng(asgs, group, rng)

def pick_member.rng.by(+asgs: List<&2, Assignment>, group: List<&2, Nat>, empty_niche: Bool, +fallback: Nat, rng: Rng.State) -> Rng.State:
  match group:
    case Nil{}:
      Rng.with_k(rng, fallback)
    case g0 <> gs:
      pick_member.rng.empty(asgs, {g0 <> gs : List<&2, Nat>}, empty_niche, rng)

def pick_member.rng(+asgs: List<&2, Assignment>, +counts: List<&2, Nat>, +cand: List<&2, Nat>, +r: Nat, rng: Rng.State) -> Rng.State:
  pick_member.rng.by(
    asgs,
    in_ref(asgs, r, cand),
    Nat.is_eq(Util.get_nat(counts, r), 0n),
    first_cand(cand),
    rng
  )

def seed_raw.go(+asgs: List<&2, Assignment>, +n: Nat, +fuel: Nat, selected: List<&2, Nat>) -> List<&2, Nat>:
  match fuel selected:
    case 0n Nil{}:
      Util.zeros_nat(n)
    case 0n +i <> rest:
      Util.inc_at(seed_raw.go(asgs, n, 0n, rest), asg_ref(get_asg(asgs, i)))
    case 1n+p Nil{}:
      Util.zeros_nat(n)
    case 1n+p +i <> Nil{}:
      Util.inc_at(Util.zeros_nat(n), asg_ref(get_asg(asgs, i)))
    case 1n+p h <> t:
      +all = {h <> t : List<&2, Nat>}
      +mid = Nat.div(Util.list_len(Nat, all), 2n)
      lo hi = seed_raw.go(asgs, n, p, List.take(&2, Nat, all, mid)) seed_raw.go(asgs, n, p, List.drop(&2, Nat, all, mid))
      Util.nats_add(lo, hi)

def seed_counts(+asgs: List<&2, Assignment>, +selected: List<&2, Nat>, +acc: List<&2, Nat>) -> List<&2, Nat>:
  Util.nats_add(acc, seed_raw.go(asgs, Util.list_len(Nat, acc), Util.list_len(Nat, selected), selected))

# fuel, k, cand first so the match follows binder order and fuel shrinks.
def pick_ref.rows(+counts: List<&2, Nat>, +rows: List<&2, NRow>) -> Nat:
  +refs = uniq_refs(rows)
  min_idx_ne(refs_at_seq(counts, min_count_rows(counts, rows), refs))

def pick_member.by.ne.rows(+group: List<&2, NRow>, empty_niche: Bool) -> Nat:
  match empty_niche:
    case True{}:
      argmin_dist_rows(group)
    case False{}:
      min_idx_rows(group)

def pick_member.by.rows(group: List<&2, NRow>, empty_niche: Bool, +fallback: Nat) -> Nat:
  match group:
    case Nil{}:
      fallback
    case g0 <> gs:
      pick_member.by.ne.rows({g0 <> gs : List<&2, NRow>}, empty_niche)

def pick_member.rows(+counts: List<&2, Nat>, +rows: List<&2, NRow>, +r: Nat) -> Nat:
  pick_member.by.rows(in_ref_rows(r, rows), Nat.is_eq(Util.get_nat(counts, r), 0n), first_row_i(rows))

def pick_ref.rng.rows(+counts: List<&2, Nat>, +rows: List<&2, NRow>, rng: Rng.State) -> Rng.State:
  +refs = uniq_refs(rows)
  pick_ref.rng.after(
    refs_at_seq(counts, min_count_rows(counts, rows), refs),
    first_row_r(rows),
    rng
  )

def pick_among.nrows(+rows: List<&2, NRow>, n: Nat, +fallback: Nat, rng: Rng.State) -> Rng.State:
  match n:
    case 0n:
      Rng.with_k(rng, fallback)
    case 1n:
      Rng.with_k(rng, first_row_i(rows))
    case 1n+p:
      +rng2 = Rng.next_nat(rng, 1n+p)
      Rng.with_k(rng2, nrow_i(get_nrow(rows, Rng.last_nat(rng2))))

def pick_near.rng.rows(+group: List<&2, NRow>, rng: Rng.State) -> Rng.State:
  +near = near_rows(near_lim(min_dist_rows(group)), group)
  pick_among.nrows(near, Util.list_len(NRow, near), first_row_i(group), rng)

def pick_member.rng.empty.rows(+group: List<&2, NRow>, empty_niche: Bool, rng: Rng.State) -> Rng.State:
  match empty_niche:
    case True{}:
      Rng.with_k(rng, argmin_dist_rows(group))
    case False{}:
      pick_near.rng.rows(group, rng)

def pick_member.rng.by.rows(group: List<&2, NRow>, empty_niche: Bool, +fallback: Nat, rng: Rng.State) -> Rng.State:
  match group:
    case Nil{}:
      Rng.with_k(rng, fallback)
    case g0 <> gs:
      pick_member.rng.empty.rows({g0 <> gs : List<&2, NRow>}, empty_niche, rng)

def pick_member.rng.rows(+counts: List<&2, Nat>, +rows: List<&2, NRow>, +r: Nat, rng: Rng.State) -> Rng.State:
  pick_member.rng.by.rows(
    in_ref_rows(r, rows),
    Nat.is_eq(Util.get_nat(counts, r), 0n),
    first_row_i(rows),
    rng
  )

def niche_loop(fuel: Nat, k: Nat, rows: List<&2, NRow>, +counts: List<&2, Nat>, selected: List<&2, Nat>) -> List<&2, Nat>:
  match fuel k rows:
    case 0n kk r:
      selected
    case f 0n r:
      selected
    case f kk Nil{}:
      selected
    case 1n+f 1n+krest +r0 <> +rs:
      +rows2 = {r0 <> rs : List<&2, NRow>}
      +r = pick_ref.rows(counts, rows2)
      +pick = pick_member.rows(counts, rows2, r)
      niche_loop(
        f,
        krest,
        drop_nrow(rows2, pick),
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
      +rows = nrows_of(asgs, fr)
      niche_loop(
        1n+Util.list_len(NRow, rows),
        need,
        rows,
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

def niche_loop.rng(fuel: Nat, k: Nat, rows: List<&2, NRow>, +counts: List<&2, Nat>, selected: List<&2, Nat>, rng: Rng.State) -> List<&2, Nat> & Rng.State:
  match fuel k rows:
    case 0n kk r:
      (selected, rng)
    case f 0n r:
      (selected, rng)
    case f kk Nil{}:
      (selected, rng)
    case 1n+f 1n+krest +r0 <> +rs:
      +rows2 = {r0 <> rs : List<&2, NRow>}
      +rng1 = pick_ref.rng.rows(counts, rows2, rng)
      +r = Rng.last_nat(rng1)
      +rng2 = pick_member.rng.rows(counts, rows2, r, rng1)
      +pick = Rng.last_nat(rng2)
      niche_loop.rng(
        f,
        krest,
        drop_nrow(rows2, pick),
        Util.inc_at(counts, r),
        List.append(&2, Nat, selected, [pick]),
        rng2
      )

def fill.rng(fuel: Nat, fronts: List<&2, List<&2, Nat>>, fits: Bool, +acc: List<&2, Nat>, +target: Nat, +asgs: List<&2, Assignment>, +n_dirs: Nat, rng: Rng.State) -> List<&2, Nat> & Rng.State:
  match fuel fronts fits:
    case 0n fs p:
      (acc, rng)
    case f Nil{} p:
      (acc, rng)
    case 1n+f +fr <> +rest False{}:
      +need = Nat.sub(target, Util.list_len(Nat, acc))
      +rows = nrows_of(asgs, fr)
      niche_loop.rng(
        1n+Util.list_len(NRow, rows),
        need,
        rows,
        seed_counts(asgs, acc, Util.zeros_nat(n_dirs)),
        acc,
        rng
      )
    case 1n+f +fr <> +rest True{}:
      +new_acc = List.append(&2, Nat, acc, fr)
      fill.rng(
        f,
        rest,
        Nat.is_le(Nat.add(Util.list_len(Nat, new_acc), head_len(rest)), target),
        new_acc,
        target,
        asgs,
        n_dirs,
        rng
      )

def fill.wrap.rng(+fronts: List<&2, List<&2, Nat>>, +target: Nat, +asgs: List<&2, Assignment>, +n_dirs: Nat, rng: Rng.State) -> List<&2, Nat> & Rng.State:
  fill.rng(
    1n+n_fronts(fronts),
    fronts,
    Nat.is_le(head_len(fronts), target),
    Nil{},
    target,
    asgs,
    n_dirs,
    rng
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

def unused_idxs(+used: List<&2, Nat>, +n: Nat) -> List<&2, Nat>:
  Util.minus(List.range(n), used)

# Length lock: |take(pad(core, want, n), want)| = want when want ≤ n.
# Identity when core is already a unique subset of 0..n-1 of length want
# (the fill / range / take paths used in A/B).
def pad_idxs(+xs: List<&2, Nat>, +want: Nat, +n: Nat) -> List<&2, Nat>:
  List.append(&2, Nat, xs, List.take(&2, Nat, unused_idxs(xs, n), Nat.sub(want, Util.list_len(Nat, xs))))

def clip_idxs(+xs: List<&2, Nat>, +want: Nat) -> List<&2, Nat>:
  List.take(&2, Nat, xs, want)

def size_lock(+xs: List<&2, Nat>, +want: Nat, +n: Nat) -> List<&2, Nat>:
  clip_idxs(List.append(&2, Nat, pad_idxs(xs, want, n), List.range(want)), want)

def select_idx(+combined: List<&2, Ind.Individual>, +target_size: Nat, +dirs: List<&2, List<&2, F32>>) -> List<&2, Nat>:
  +n = Util.list_len(Ind.Individual, combined)
  +want = Util.nat_min(target_size, n)
  size_lock(select_idx.by(combined, target_size, dirs, Nat.is_le(n, target_size)), want, n)

def select(+combined: List<&2, Ind.Individual>, +target_size: Nat, +dirs: List<&2, List<&2, F32>>) -> List<&2, Ind.Individual>:
  gather(combined, select_idx(combined, target_size, dirs))

# Persistent-normalization Select for Unsga3Algorithm.Run. Threads rng
# so last-front niching matches C# Select(..., rng) on min-count niche
# ties. Empty niches take closest; extras are random among near-best
# on that ray. v0 `select` stays the `rng == null` path (empty laws).
def size_lock.rng(+want: Nat, +n: Nat, pair: List<&2, Nat> & Rng.State) -> List<&2, Nat> & Rng.State:
  (xs, rng) = pair
  (size_lock(xs, want, n), rng)

def select_st.after(+st: Norm.State, +pop: List<&2, Ind.Individual>, pair: List<&2, Nat> & Rng.State) -> Norm.State & List<&2, Ind.Individual> & Rng.State:
  (idxs, rng2) = pair
  (st, gather(pop, idxs), rng2)

def select_st.with(+pop: List<&2, Ind.Individual>, +target: Nat, +dirs: List<&2, List<&2, F32>>, +fronts: List<&2, List<&2, Nat>>, pair: Norm.State & List<&2, List<&2, F32>>, rng: Rng.State) -> Norm.State & List<&2, Ind.Individual> & Rng.State:
  (st, F) = pair
  +n = Util.list_len(Ind.Individual, pop)
  +want = Util.nat_min(target, n)
  select_st.after(st, pop, size_lock.rng(want, n, fill.wrap.rng(fronts, target, associate(pop, F, dirs), Util.list_len(List<&2, F32>, dirs), rng)))

def select_st.big(+pop: List<&2, Ind.Individual>, +target: Nat, +dirs: List<&2, List<&2, F32>>, state: Norm.State, rng: Rng.State) -> Norm.State & List<&2, Ind.Individual> & Rng.State:
  +fronts = NDS.sort(pop)
  select_st.with(pop, target, dirs, fronts, Norm.normalize_nd(state, pop, front0(fronts)), rng)

def select_st.take(+pop: List<&2, Ind.Individual>, +target: Nat, state: Norm.State, rng: Rng.State) -> Norm.State & List<&2, Ind.Individual> & Rng.State:
  +n = Util.list_len(Ind.Individual, pop)
  (state, gather(pop, size_lock(List.take(&2, Nat, List.range(n), target), Util.nat_min(target, n), n)), rng)

def select_st.dirs(+pop: List<&2, Ind.Individual>, +target: Nat, +dirs: List<&2, List<&2, F32>>, state: Norm.State, rng: Rng.State, empty_dirs: Bool) -> Norm.State & List<&2, Ind.Individual> & Rng.State:
  match empty_dirs:
    case True{}:
      select_st.take(pop, target, state, rng)
    case False{}:
      select_st.big(pop, target, dirs, state, rng)

def select_st.by(+pop: List<&2, Ind.Individual>, +target: Nat, +dirs: List<&2, List<&2, F32>>, state: Norm.State, rng: Rng.State, small: Bool) -> Norm.State & List<&2, Ind.Individual> & Rng.State:
  match small:
    case True{}:
      (state, pop, rng)
    case False{}:
      select_st.dirs(pop, target, dirs, state, rng, List.is_empty(&2, List<&2, F32>, dirs))

def select_st(+combined: List<&2, Ind.Individual>, +target_size: Nat, +dirs: List<&2, List<&2, F32>>, state: Norm.State, rng: Rng.State) -> Norm.State & List<&2, Ind.Individual> & Rng.State:
  +n = Util.list_len(Ind.Individual, combined)
  select_st.by(combined, target_size, dirs, state, rng, Nat.is_le(n, target_size))
