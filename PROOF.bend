# Proofs. `bend PROOF.bend` is the gate.
# Closed: empty-input / M=1 / binomial / das_dennis_count, pass-2
# operator defaults / typical 1/n / from_objectives / ZDT-DTLZ dimensions /
# zero-parent tournament / zero-pop Run, plus dominates_irreflexive
# (same-list flags → verdict 0) and |normalize| / |associate| via
# mid-split map length. Remaining: quantified sort partition /
# |DasDennis| for M≥2 / select niching / F32-opaque p=0 / |Run|==pop.

import Base
import ./LAWS.bend as Laws
import ./src/individual.bend as Ind
import ./src/non_dominated_sort.bend as NDS
import ./src/normalization.bend as Norm
import ./src/survival.bend as Surv
import ./src/util.bend as Util

# Same-list Pareto walk keeps both flags equal, so verdict is 0n
# without any F32 axiom: verdict(True,True)=0 and verdict(False,False)=0.
def compare_same.true(+xs: List<&2, F32>) -> {NDS.compare_pareto.go(xs, xs, True{}, True{}) == 0n : Nat}:
  match xs:
    case Nil{}:
      {==}
    case +x <> rest:
      compare_same.true(rest)

def compare_same.switch(+rest: List<&2, F32>, lt: Bool) -> {NDS.compare_pareto.go(rest, rest, lt, lt) == 0n : Nat}:
  match rest:
    case Nil{}:
      match lt:
        case True{}:
          {==}
        case False{}:
          {==}
    case +y <> ys:
      match lt:
        case True{}:
          compare_same.true(ys)
        case False{}:
          compare_same.switch(ys, F32.is_lt(y, y))

def compare_same.false(+xs: List<&2, F32>) -> {NDS.compare_pareto.go(xs, xs, False{}, False{}) == 0n : Nat}:
  compare_same.switch(xs, False{})

def dominates_via(c: Nat, e: {c == 0n : Nat}) -> {NDS.dominates.fin(c) == NDS.dominates.fin(0n) : Bool}:
  %e : {NDS.dominates.fin(c) == NDS.dominates.fin(_) : Bool}
  {==}

# |xs ++ ys| = |xs| + |ys|
def len_append(-A: Data, xs: List<&2, A>, +ys: List<&2, A>) -> {List.length(&2, A, List.append(&2, A, xs, ys)) == Nat.add(List.length(&2, A, xs), List.length(&2, A, ys)) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      %len_append(A, t, ys) : {1n+List.length(&2, A, List.append(&2, A, t, ys)) == 1n+_ : Nat}
      {==}

# |take n xs| + |drop n xs| = |xs|
def take_drop_len(-A: Data, xs: List<&2, A>, n: Nat) -> {Nat.add(List.length(&2, A, List.take(&2, A, xs, n)), List.length(&2, A, List.drop(&2, A, xs, n))) == List.length(&2, A, xs) : Nat}:
  match xs n:
    case Nil{} k:
      {==}
    case h <> t 0n:
      {==}
    case h <> t 1n+p:
      %take_drop_len(A, t, p) : {1n+Nat.add(List.length(&2, A, List.take(&2, A, t, p)), List.length(&2, A, List.drop(&2, A, t, p))) == 1n+_ : Nat}
      {==}

# add(a,b) == add(c,d) from a==c and b==d (rewrite RHS→LHS toward a common form)
def add_both(+a: Nat, +b: Nat, +c: Nat, +d: Nat, e1: {a == c : Nat}, e2: {b == d : Nat}) -> {Nat.add(a, b) == Nat.add(c, d) : Nat}:
  %e1 : {Nat.add(a, b) == Nat.add(_, d) : Nat}
  %e2 : {Nat.add(a, b) == Nat.add(a, _) : Nat}
  {==}

def map_norm_len.mid(
  +ideal: List<&2, F32>,
  +nadir: List<&2, F32>,
  +p: Nat,
  +all: List<&2, Ind.Individual>,
  +mid: Nat,
  e_xs: {Util.list_len(List<&2, F32>, Norm.map_norm.go(ideal, nadir, p, List.take(&2, Ind.Individual, all, mid))) == Util.list_len(Ind.Individual, List.take(&2, Ind.Individual, all, mid)) : Nat},
  e_ys: {Util.list_len(List<&2, F32>, Norm.map_norm.go(ideal, nadir, p, List.drop(&2, Ind.Individual, all, mid))) == Util.list_len(Ind.Individual, List.drop(&2, Ind.Individual, all, mid)) : Nat}
) -> {Util.list_len(List<&2, F32>, List.append(&2, List<&2, F32>, Norm.map_norm.go(ideal, nadir, p, List.take(&2, Ind.Individual, all, mid)), Norm.map_norm.go(ideal, nadir, p, List.drop(&2, Ind.Individual, all, mid)))) == Nat.add(Util.list_len(Ind.Individual, List.take(&2, Ind.Individual, all, mid)), Util.list_len(Ind.Individual, List.drop(&2, Ind.Individual, all, mid))) : Nat}:
  Equal.trans(
    Nat,
    Util.list_len(List<&2, F32>, List.append(&2, List<&2, F32>, Norm.map_norm.go(ideal, nadir, p, List.take(&2, Ind.Individual, all, mid)), Norm.map_norm.go(ideal, nadir, p, List.drop(&2, Ind.Individual, all, mid)))),
    Nat.add(Util.list_len(List<&2, F32>, Norm.map_norm.go(ideal, nadir, p, List.take(&2, Ind.Individual, all, mid))), Util.list_len(List<&2, F32>, Norm.map_norm.go(ideal, nadir, p, List.drop(&2, Ind.Individual, all, mid)))),
    Nat.add(Util.list_len(Ind.Individual, List.take(&2, Ind.Individual, all, mid)), Util.list_len(Ind.Individual, List.drop(&2, Ind.Individual, all, mid))),
    len_append(List<&2, F32>, Norm.map_norm.go(ideal, nadir, p, List.take(&2, Ind.Individual, all, mid)), Norm.map_norm.go(ideal, nadir, p, List.drop(&2, Ind.Individual, all, mid))),
    add_both(
      Util.list_len(List<&2, F32>, Norm.map_norm.go(ideal, nadir, p, List.take(&2, Ind.Individual, all, mid))),
      Util.list_len(List<&2, F32>, Norm.map_norm.go(ideal, nadir, p, List.drop(&2, Ind.Individual, all, mid))),
      Util.list_len(Ind.Individual, List.take(&2, Ind.Individual, all, mid)),
      Util.list_len(Ind.Individual, List.drop(&2, Ind.Individual, all, mid)),
      e_xs,
      e_ys
    )
  )

def map_norm_len.finish(
  +ideal: List<&2, F32>,
  +nadir: List<&2, F32>,
  +p: Nat,
  +all: List<&2, Ind.Individual>,
  +mid: Nat,
  e_xs: {Util.list_len(List<&2, F32>, Norm.map_norm.go(ideal, nadir, p, List.take(&2, Ind.Individual, all, mid))) == Util.list_len(Ind.Individual, List.take(&2, Ind.Individual, all, mid)) : Nat},
  e_ys: {Util.list_len(List<&2, F32>, Norm.map_norm.go(ideal, nadir, p, List.drop(&2, Ind.Individual, all, mid))) == Util.list_len(Ind.Individual, List.drop(&2, Ind.Individual, all, mid)) : Nat}
) -> {Util.list_len(List<&2, F32>, List.append(&2, List<&2, F32>, Norm.map_norm.go(ideal, nadir, p, List.take(&2, Ind.Individual, all, mid)), Norm.map_norm.go(ideal, nadir, p, List.drop(&2, Ind.Individual, all, mid)))) == Util.list_len(Ind.Individual, all) : Nat}:
  Equal.trans(
    Nat,
    Util.list_len(List<&2, F32>, List.append(&2, List<&2, F32>, Norm.map_norm.go(ideal, nadir, p, List.take(&2, Ind.Individual, all, mid)), Norm.map_norm.go(ideal, nadir, p, List.drop(&2, Ind.Individual, all, mid)))),
    Nat.add(Util.list_len(Ind.Individual, List.take(&2, Ind.Individual, all, mid)), Util.list_len(Ind.Individual, List.drop(&2, Ind.Individual, all, mid))),
    Util.list_len(Ind.Individual, all),
    map_norm_len.mid(ideal, nadir, p, all, mid, e_xs, e_ys),
    take_drop_len(Ind.Individual, all, mid)
  )

def map_norm_len(
  +ideal: List<&2, F32>,
  +nadir: List<&2, F32>,
  +fuel: Nat,
  +pop: List<&2, Ind.Individual>
) -> {Util.list_len(List<&2, F32>, Norm.map_norm.go(ideal, nadir, fuel, pop)) == Util.list_len(Ind.Individual, pop) : Nat}:
  match fuel pop:
    case 0n Nil{}:
      {==}
    case 0n +h <> +t:
      %map_norm_len(ideal, nadir, 0n, t) : {1n+Util.list_len(List<&2, F32>, Norm.map_norm.go(ideal, nadir, 0n, t)) == 1n+_ : Nat}
      {==}
    case 1n+p Nil{}:
      {==}
    case 1n+p +h <> Nil{}:
      {==}
    case 1n+p +h <> +k <> +rest:
      +all = {h <> k <> rest : List<&2, Ind.Individual>}
      +mid = Nat.div(Util.list_len(Ind.Individual, all), 2n)
      map_norm_len.finish(
        ideal,
        nadir,
        p,
        all,
        mid,
        map_norm_len(ideal, nadir, p, List.take(&2, Ind.Individual, all, mid)),
        map_norm_len(ideal, nadir, p, List.drop(&2, Ind.Individual, all, mid))
      )

def assoc_raw_len.mid(
  +dirs: List<&2, List<&2, F32>>,
  +p: Nat,
  +all: List<&2, Ind.Individual>,
  +F: List<&2, List<&2, F32>>,
  +mid: Nat,
  e_xs: {Util.list_len(Surv.Assignment, Surv.associate_raw.go(dirs, p, List.take(&2, Ind.Individual, all, mid), List.take(&2, List<&2, F32>, F, mid))) == Util.list_len(Ind.Individual, List.take(&2, Ind.Individual, all, mid)) : Nat},
  e_ys: {Util.list_len(Surv.Assignment, Surv.associate_raw.go(dirs, p, List.drop(&2, Ind.Individual, all, mid), List.drop(&2, List<&2, F32>, F, mid))) == Util.list_len(Ind.Individual, List.drop(&2, Ind.Individual, all, mid)) : Nat}
) -> {Util.list_len(Surv.Assignment, List.append(&2, Surv.Assignment, Surv.associate_raw.go(dirs, p, List.take(&2, Ind.Individual, all, mid), List.take(&2, List<&2, F32>, F, mid)), Surv.associate_raw.go(dirs, p, List.drop(&2, Ind.Individual, all, mid), List.drop(&2, List<&2, F32>, F, mid)))) == Nat.add(Util.list_len(Ind.Individual, List.take(&2, Ind.Individual, all, mid)), Util.list_len(Ind.Individual, List.drop(&2, Ind.Individual, all, mid))) : Nat}:
  Equal.trans(
    Nat,
    Util.list_len(Surv.Assignment, List.append(&2, Surv.Assignment, Surv.associate_raw.go(dirs, p, List.take(&2, Ind.Individual, all, mid), List.take(&2, List<&2, F32>, F, mid)), Surv.associate_raw.go(dirs, p, List.drop(&2, Ind.Individual, all, mid), List.drop(&2, List<&2, F32>, F, mid)))),
    Nat.add(Util.list_len(Surv.Assignment, Surv.associate_raw.go(dirs, p, List.take(&2, Ind.Individual, all, mid), List.take(&2, List<&2, F32>, F, mid))), Util.list_len(Surv.Assignment, Surv.associate_raw.go(dirs, p, List.drop(&2, Ind.Individual, all, mid), List.drop(&2, List<&2, F32>, F, mid)))),
    Nat.add(Util.list_len(Ind.Individual, List.take(&2, Ind.Individual, all, mid)), Util.list_len(Ind.Individual, List.drop(&2, Ind.Individual, all, mid))),
    len_append(Surv.Assignment, Surv.associate_raw.go(dirs, p, List.take(&2, Ind.Individual, all, mid), List.take(&2, List<&2, F32>, F, mid)), Surv.associate_raw.go(dirs, p, List.drop(&2, Ind.Individual, all, mid), List.drop(&2, List<&2, F32>, F, mid))),
    add_both(
      Util.list_len(Surv.Assignment, Surv.associate_raw.go(dirs, p, List.take(&2, Ind.Individual, all, mid), List.take(&2, List<&2, F32>, F, mid))),
      Util.list_len(Surv.Assignment, Surv.associate_raw.go(dirs, p, List.drop(&2, Ind.Individual, all, mid), List.drop(&2, List<&2, F32>, F, mid))),
      Util.list_len(Ind.Individual, List.take(&2, Ind.Individual, all, mid)),
      Util.list_len(Ind.Individual, List.drop(&2, Ind.Individual, all, mid)),
      e_xs,
      e_ys
    )
  )

def assoc_raw_len.finish(
  +dirs: List<&2, List<&2, F32>>,
  +p: Nat,
  +all: List<&2, Ind.Individual>,
  +F: List<&2, List<&2, F32>>,
  +mid: Nat,
  e_xs: {Util.list_len(Surv.Assignment, Surv.associate_raw.go(dirs, p, List.take(&2, Ind.Individual, all, mid), List.take(&2, List<&2, F32>, F, mid))) == Util.list_len(Ind.Individual, List.take(&2, Ind.Individual, all, mid)) : Nat},
  e_ys: {Util.list_len(Surv.Assignment, Surv.associate_raw.go(dirs, p, List.drop(&2, Ind.Individual, all, mid), List.drop(&2, List<&2, F32>, F, mid))) == Util.list_len(Ind.Individual, List.drop(&2, Ind.Individual, all, mid)) : Nat}
) -> {Util.list_len(Surv.Assignment, List.append(&2, Surv.Assignment, Surv.associate_raw.go(dirs, p, List.take(&2, Ind.Individual, all, mid), List.take(&2, List<&2, F32>, F, mid)), Surv.associate_raw.go(dirs, p, List.drop(&2, Ind.Individual, all, mid), List.drop(&2, List<&2, F32>, F, mid)))) == Util.list_len(Ind.Individual, all) : Nat}:
  Equal.trans(
    Nat,
    Util.list_len(Surv.Assignment, List.append(&2, Surv.Assignment, Surv.associate_raw.go(dirs, p, List.take(&2, Ind.Individual, all, mid), List.take(&2, List<&2, F32>, F, mid)), Surv.associate_raw.go(dirs, p, List.drop(&2, Ind.Individual, all, mid), List.drop(&2, List<&2, F32>, F, mid)))),
    Nat.add(Util.list_len(Ind.Individual, List.take(&2, Ind.Individual, all, mid)), Util.list_len(Ind.Individual, List.drop(&2, Ind.Individual, all, mid))),
    Util.list_len(Ind.Individual, all),
    assoc_raw_len.mid(dirs, p, all, F, mid, e_xs, e_ys),
    take_drop_len(Ind.Individual, all, mid)
  )

def assoc_raw_len.fuel0(
  +dirs: List<&2, List<&2, F32>>,
  +rest: List<&2, Ind.Individual>,
  F: List<&2, List<&2, F32>>
) -> {Util.list_len(Surv.Assignment, Surv.associate_raw.go(dirs, 0n, rest, F)) == Util.list_len(Ind.Individual, rest) : Nat}:
  match rest:
    case Nil{}:
      {==}
    case +ind <> +more:
      match F:
        case Nil{}:
          %assoc_raw_len.fuel0(dirs, more, Nil{}) : {1n+Util.list_len(Surv.Assignment, Surv.associate_raw.go(dirs, 0n, more, Nil{})) == 1n+_ : Nat}
          {==}
        case +f <> +fs:
          %assoc_raw_len.fuel0(dirs, more, fs) : {1n+Util.list_len(Surv.Assignment, Surv.associate_raw.go(dirs, 0n, more, fs)) == 1n+_ : Nat}
          {==}

def assoc_raw_len(
  +dirs: List<&2, List<&2, F32>>,
  +fuel: Nat,
  +pop: List<&2, Ind.Individual>,
  +F: List<&2, List<&2, F32>>
) -> {Util.list_len(Surv.Assignment, Surv.associate_raw.go(dirs, fuel, pop, F)) == Util.list_len(Ind.Individual, pop) : Nat}:
  match fuel pop:
    case 0n Nil{}:
      {==}
    case 0n +ind <> +rest:
      assoc_raw_len.fuel0(dirs, {ind <> rest : List<&2, Ind.Individual>}, F)
    case 1n+p Nil{}:
      {==}
    case 1n+p +ind <> Nil{}:
      {==}
    case 1n+p +h <> +k <> +rest:
      +all = {h <> k <> rest : List<&2, Ind.Individual>}
      +mid = Nat.div(Util.list_len(Ind.Individual, all), 2n)
      assoc_raw_len.finish(
        dirs,
        p,
        all,
        F,
        mid,
        assoc_raw_len(dirs, p, List.take(&2, Ind.Individual, all, mid), List.take(&2, List<&2, F32>, F, mid)),
        assoc_raw_len(dirs, p, List.drop(&2, Ind.Individual, all, mid), List.drop(&2, List<&2, F32>, F, mid))
      )

def map_halves_len.mid(
  ~A: Data,
  ~B: Data,
  ~C: Data,
  ~f: @+c:C -> @+x:A -> B,
  +ctx: C,
  +p: Nat,
  +all: List<&2, A>,
  +mid: Nat,
  e_xs: {Util.list_len(B, Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.take(&2, A, all, mid))) == Util.list_len(A, List.take(&2, A, all, mid)) : Nat},
  e_ys: {Util.list_len(B, Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.drop(&2, A, all, mid))) == Util.list_len(A, List.drop(&2, A, all, mid)) : Nat}
) -> {Util.list_len(B, List.append(&2, B, Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.take(&2, A, all, mid)), Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.drop(&2, A, all, mid)))) == Nat.add(Util.list_len(A, List.take(&2, A, all, mid)), Util.list_len(A, List.drop(&2, A, all, mid))) : Nat}:
  Equal.trans(
    Nat,
    Util.list_len(B, List.append(&2, B, Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.take(&2, A, all, mid)), Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.drop(&2, A, all, mid)))),
    Nat.add(Util.list_len(B, Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.take(&2, A, all, mid))), Util.list_len(B, Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.drop(&2, A, all, mid)))),
    Nat.add(Util.list_len(A, List.take(&2, A, all, mid)), Util.list_len(A, List.drop(&2, A, all, mid))),
    len_append(B, Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.take(&2, A, all, mid)), Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.drop(&2, A, all, mid))),
    add_both(
      Util.list_len(B, Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.take(&2, A, all, mid))),
      Util.list_len(B, Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.drop(&2, A, all, mid))),
      Util.list_len(A, List.take(&2, A, all, mid)),
      Util.list_len(A, List.drop(&2, A, all, mid)),
      e_xs,
      e_ys
    )
  )

def map_halves_len.finish(
  ~A: Data,
  ~B: Data,
  ~C: Data,
  ~f: @+c:C -> @+x:A -> B,
  +ctx: C,
  +p: Nat,
  +all: List<&2, A>,
  +mid: Nat,
  e_xs: {Util.list_len(B, Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.take(&2, A, all, mid))) == Util.list_len(A, List.take(&2, A, all, mid)) : Nat},
  e_ys: {Util.list_len(B, Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.drop(&2, A, all, mid))) == Util.list_len(A, List.drop(&2, A, all, mid)) : Nat}
) -> {Util.list_len(B, List.append(&2, B, Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.take(&2, A, all, mid)), Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.drop(&2, A, all, mid)))) == Util.list_len(A, all) : Nat}:
  Equal.trans(
    Nat,
    Util.list_len(B, List.append(&2, B, Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.take(&2, A, all, mid)), Util.map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.drop(&2, A, all, mid)))),
    Nat.add(Util.list_len(A, List.take(&2, A, all, mid)), Util.list_len(A, List.drop(&2, A, all, mid))),
    Util.list_len(A, all),
    map_halves_len.mid(~A, ~B, ~C, ~f, ctx, p, all, mid, e_xs, e_ys),
    take_drop_len(A, all, mid)
  )

def map_halves_len(
  ~A: Data,
  ~B: Data,
  ~C: Data,
  ~f: @+c:C -> @+x:A -> B,
  +ctx: C,
  +fuel: Nat,
  +xs: List<&2, A>
) -> {Util.list_len(B, Util.map_halves.go(~A, ~B, ~C, ~f, ctx, fuel, xs)) == Util.list_len(A, xs) : Nat}:
  match fuel xs:
    case 0n Nil{}:
      {==}
    case 0n +h <> +t:
      %map_halves_len(~A, ~B, ~C, ~f, ctx, 0n, t) : {1n+Util.list_len(B, Util.map_halves.go(~A, ~B, ~C, ~f, ctx, 0n, t)) == 1n+_ : Nat}
      {==}
    case 1n+p Nil{}:
      {==}
    case 1n+p +h <> Nil{}:
      {==}
    case 1n+p +h <> +k <> +rest:
      +all = {h <> k <> rest : List<&2, A>}
      +mid = Nat.div(Util.list_len(A, all), 2n)
      map_halves_len.finish(
        ~A,
        ~B,
        ~C,
        ~f,
        ctx,
        p,
        all,
        mid,
        map_halves_len(~A, ~B, ~C, ~f, ctx, p, List.take(&2, A, all, mid)),
        map_halves_len(~A, ~B, ~C, ~f, ctx, p, List.drop(&2, A, all, mid))
      )

def Laws.sort_empty():
  {==}

def Laws.sort_index_count(pop):
  ?TODO

def Laws.dominates_irreflexive(ind):
  +xs = Ind.objectives(ind)
  dominates_via(NDS.compare_pareto.go(xs, xs, False{}, False{}), compare_same.false(xs))

def Laws.normalize_empty():
  {==}

def Laws.normalize_len(pop):
  match pop:
    case Nil{}:
      {==}
    case +h <> +t:
      +pop2 = {h <> t : List<&2, Ind.Individual>}
      +mn = Norm.col_min(pop2)
      +mx = Norm.col_max(pop2)
      +ideal = Norm.merge_ideal(Nil{}, mn)
      +worst = Norm.merge_worst(Nil{}, mx)
      +nd_use = Norm.nd_or_all(Nil{}, Util.list_len(Ind.Individual, pop2))
      +front = Norm.col_max_idx(pop2, nd_use)
      +cand = List.append(&2, List<&2, F32>, Nil{}, Norm.gather_objs(pop2, nd_use))
      +m = Norm.n_obj_pop(pop2)
      +ext = Norm.pick_extremes(cand, ideal, m)
      +nadir0 = Norm.nadir_from_maybe(Norm.try_intercepts(ext, ideal), ideal, worst, front)
      +nadir1 = Norm.fallback_pop(nadir0, ideal, mx)
      +nadir = Norm.fallback_unit(nadir1, ideal)
      map_norm_len(ideal, nadir, Util.list_len(Ind.Individual, pop2), pop2)

def Laws.binomial_k0(n):
  match n:
    case 0n:
      {==}
    case 1n+p:
      {==}

def Laws.das_dennis_count_m1(p):
  {==}

def Laws.das_dennis_count(m, p):
  {==}

def Laws.das_dennis_m1_len(p):
  match p:
    case 0n:
      {==}
    case 1n+q:
      {==}

def Laws.das_dennis_len(m, p):
  ?TODO

def Laws.associate_empty():
  {==}

def Laws.associate_len(pop, F, dirs):
  match pop:
    case Nil{}:
      {==}
    case +h <> +t:
      +pop2 = {h <> t : List<&2, Ind.Individual>}
      +raw = Surv.associate_raw.go(dirs, Util.list_len(Ind.Individual, pop2), pop2, F)
      +counts = Surv.count_asg(raw, Util.zeros_nat(Util.list_len(List<&2, F32>, dirs)))
      Equal.trans(
        Nat,
        Util.list_len(Surv.Assignment, Util.map_halves.go(~Surv.Assignment, ~Surv.Assignment, ~List<&2, Nat>, ~Surv.with_counts.one, counts, Util.list_len(Surv.Assignment, raw), raw)),
        Util.list_len(Surv.Assignment, raw),
        Util.list_len(Ind.Individual, pop2),
        map_halves_len(~Surv.Assignment, ~Surv.Assignment, ~List<&2, Nat>, ~Surv.with_counts.one, counts, Util.list_len(Surv.Assignment, raw), raw),
        assoc_raw_len(dirs, Util.list_len(Ind.Individual, pop2), pop2, F)
      )

def Laws.select_empty():
  {==}

def Laws.select_size(pop, n, dirs):
  ?TODO

def Laws.from_objectives_roundtrip():
  {==}

def Laws.sbx_default_eta():
  {==}

def Laws.sbx_default_probability():
  {==}

def Laws.poly_default_eta():
  {==}

def Laws.poly_typical_n2():
  {==}

def Laws.sbx_prob0_child1_vars():
  ?TODO

def Laws.sbx_prob0_child2_vars():
  ?TODO

def Laws.poly_prob0_vars():
  ?TODO

def Laws.zdt1_n_obj():
  {==}

def Laws.zdt2_n_obj():
  {==}

def Laws.zdt1_n_var():
  {==}

def Laws.dtlz2_n_obj():
  {==}

def Laws.dtlz2_n_var():
  {==}

def Laws.select_parents_zero():
  {==}

def Laws.run_zero_pop():
  {==}

def Laws.run_pop_size(cfg):
  ?TODO
