# Proofs. `bend PROOF.bend` is the gate.
# Closed: empty-input / M=1 / binomial / das_dennis_count, pass-2
# operator defaults / typical 1/n / from_objectives / ZDT-DTLZ dimensions /
# zero-parent tournament / zero-pop Run, plus dominates_irreflexive
# (same-list flags → verdict 0) and |normalize| / |associate| via
# mid-split map length. Remaining quantified laws use fuel induction,
# Row-peel Split partition, Das–Dennis by construction, p=0 bit-zero copy, and
# take-pad length locks for |select| / |Run|. `niche_count_sum` is mid-split
# histogram conservation (sum of bins = in-range assignment count).

import Base
import ./LAWS.bend as Laws
import ./src/individual.bend as Ind
import ./src/non_dominated_sort.bend as NDS
import ./src/normalization.bend as Norm
import ./src/survival.bend as Surv
import ./src/util.bend as Util
import ./src/reference_directions.bend as Refs
import ./src/algorithm.bend as Algo
import ./src/problems.bend as Prob

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

# |range.go(n, acc)| = n + |acc|
def add_succ_r(+p: Nat, +k: Nat) -> {Nat.add(p, 1n+k) == 1n+Nat.add(p, k) : Nat}:
  match p:
    case 0n:
      {==}
    case 1n+q:
      %add_succ_r(q, k) : {1n+Nat.add(q, 1n+k) == 1n+_ : Nat}
      {==}

def succ_eq(+a: Nat, +b: Nat, e: {a == b : Nat}) -> {1n+a == 1n+b : Nat}:
  %e : {1n+a == 1n+_ : Nat}
  {==}

def add_zero_r(n: Nat) -> {Nat.add(n, 0n) == n : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %add_zero_r(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def range_go_len(+n: Nat, +acc: List<&2, Nat>) -> {List.length(&2, Nat, List.range.go(n, acc)) == Nat.add(n, List.length(&2, Nat, acc)) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      Equal.trans(
        Nat,
        List.length(&2, Nat, List.range.go(p, p <> acc)),
        Nat.add(p, List.length(&2, Nat, p <> acc)),
        Nat.add(1n+p, List.length(&2, Nat, acc)),
        range_go_len(p, p <> acc),
        add_succ_r(p, List.length(&2, Nat, acc))
      )

def range_len(+n: Nat) -> {List.length(&2, Nat, List.range(n)) == n : Nat}:
  Equal.trans(
    Nat,
    List.length(&2, Nat, List.range.go(n, Nil{})),
    Nat.add(n, 0n),
    n,
    range_go_len(n, Nil{}),
    add_zero_r(n)
  )

def to_dirs_len(+p: Nat, rows: List<&2, List<&2, Nat>>) -> {Util.list_len(List<&2, F32>, Refs.to_dirs(p, rows)) == Util.list_len(List<&2, Nat>, rows) : Nat}:
  match rows:
    case Nil{}:
      {==}
    case row <> rest:
      %to_dirs_len(p, rest) : {1n+Util.list_len(List<&2, F32>, Refs.to_dirs(p, rest)) == 1n+_ : Nat}
      {==}

def comps_all_len(+m: Nat, +p: Nat) -> {Util.list_len(List<&2, Nat>, Refs.comps_all(m, p)) == Refs.count(m, p) : Nat}:
  Equal.trans(
    Nat,
    Util.list_len(List<&2, Nat>, Util.map_halves.go(~Nat, ~List<&2, Nat>, ~Refs.DasCtx, ~Refs.nth_row, Refs.DasCtx{m, p}, Util.list_len(Nat, List.range(Refs.count(m, p))), List.range(Refs.count(m, p)))),
    Util.list_len(Nat, List.range(Refs.count(m, p))),
    Refs.count(m, p),
    map_halves_len(~Nat, ~List<&2, Nat>, ~Refs.DasCtx, ~Refs.nth_row, Refs.DasCtx{m, p}, Util.list_len(Nat, List.range(Refs.count(m, p))), List.range(Refs.count(m, p))),
    range_len(Refs.count(m, p))
  )

def das_ge2_len(+rd: Nat, +p: Nat) -> {Util.list_len(List<&2, F32>, Refs.to_dirs(1n+p, Refs.comps_all(1n+rd, 1n+p))) == Refs.count(1n+rd, 1n+p) : Nat}:
  Equal.trans(
    Nat,
    Util.list_len(List<&2, F32>, Refs.to_dirs(1n+p, Refs.comps_all(1n+rd, 1n+p))),
    Util.list_len(List<&2, Nat>, Refs.comps_all(1n+rd, 1n+p)),
    Refs.count(1n+rd, 1n+p),
    to_dirs_len(1n+p, Refs.comps_all(1n+rd, 1n+p)),
    comps_all_len(1n+rd, 1n+p)
  )

# |take xs k| = min(k, |xs|)
def nat_min_succ.go(
  +a: Nat,
  +b: Nat,
  le: Bool,
  e: {Nat.is_le(a, b) == le : Bool}
) -> {Util.nat_min(1n+a, 1n+b) == 1n+Util.nat_min(a, b) : Nat}:
  match le:
    case True{}:
      %Equal.sym(Bool, Nat.is_le(a, b), True{}, e) : {Util.nat_min.fin(1n+a, 1n+b, _) == 1n+Util.nat_min.fin(a, b, _) : Nat}
      {==}
    case False{}:
      %Equal.sym(Bool, Nat.is_le(a, b), False{}, e) : {Util.nat_min.fin(1n+a, 1n+b, _) == 1n+Util.nat_min.fin(a, b, _) : Nat}
      {==}

def nat_min_succ(+a: Nat, +b: Nat) -> {Util.nat_min(1n+a, 1n+b) == 1n+Util.nat_min(a, b) : Nat}:
  nat_min_succ.go(a, b, Nat.is_le(a, b), {==})

def take_len(-A: Data, xs: List<&2, A>, n: Nat) -> {List.length(&2, A, List.take(&2, A, xs, n)) == Util.nat_min(n, List.length(&2, A, xs)) : Nat}:
  match xs n:
    case Nil{} 0n:
      {==}
    case Nil{} 1n+k:
      {==}
    case h <> t 0n:
      {==}
    case h <> +t 1n++p:
      Equal.trans(
        Nat,
        1n+List.length(&2, A, List.take(&2, A, t, p)),
        1n+Util.nat_min(p, List.length(&2, A, t)),
        Util.nat_min(1n+p, 1n+List.length(&2, A, t)),
        succ_eq(List.length(&2, A, List.take(&2, A, t, p)), Util.nat_min(p, List.length(&2, A, t)), take_len(A, t, p)),
        Equal.sym(Nat, Util.nat_min(1n+p, 1n+List.length(&2, A, t)), 1n+Util.nat_min(p, List.length(&2, A, t)), nat_min_succ(p, List.length(&2, A, t)))
      )

# nat_min(0, k) = 0. Match k so Nat.cmp is not stuck on a computed RHS.
def min_zero_l(k: Nat) -> {Util.nat_min(0n, k) == 0n : Nat}:
  match k:
    case 0n:
      {==}
    case 1n+p:
      {==}

def min_add_r.zero.rw(+k: Nat, e: {Nat.add(k, 0n) == k : Nat}) -> {Util.nat_min(0n, Nat.add(k, 0n)) == Util.nat_min(0n, k) : Nat}:
  %e : {Util.nat_min(0n, Nat.add(k, 0n)) == Util.nat_min(0n, _) : Nat}
  {==}

def min_add_r.zero(+k: Nat) -> {Util.nat_min(0n, Nat.add(k, 0n)) == 0n : Nat}:
  Equal.trans(
    Nat,
    Util.nat_min(0n, Nat.add(k, 0n)),
    Util.nat_min(0n, k),
    0n,
    min_add_r.zero.rw(k, add_zero_r(k)),
    min_zero_l(k)
  )

# nat_min(a, k+a) = a
def min_add_r.succ(
  +p: Nat,
  +k: Nat,
  e: {Nat.add(k, 1n+p) == 1n+Nat.add(k, p) : Nat}
) -> {Util.nat_min(1n+p, Nat.add(k, 1n+p)) == Util.nat_min(1n+p, 1n+Nat.add(k, p)) : Nat}:
  %e : {Util.nat_min(1n+p, Nat.add(k, 1n+p)) == Util.nat_min(1n+p, _) : Nat}
  {==}

def min_add_r(+a: Nat, +k: Nat) -> {Util.nat_min(a, Nat.add(k, a)) == a : Nat}:
  match a:
    case 0n:
      min_add_r.zero(k)
    case 1n+p:
      Equal.trans(
        Nat,
        Util.nat_min(1n+p, Nat.add(k, 1n+p)),
        Util.nat_min(1n+p, 1n+Nat.add(k, p)),
        1n+p,
        min_add_r.succ(p, k, add_succ_r(k, p)),
        Equal.trans(
          Nat,
          Util.nat_min(1n+p, 1n+Nat.add(k, p)),
          1n+Util.nat_min(p, Nat.add(k, p)),
          1n+p,
          nat_min_succ(p, Nat.add(k, p)),
          succ_eq(Util.nat_min(p, Nat.add(k, p)), p, min_add_r(p, k))
        )
      )

def replicate_len(-A: Data, n: Nat, +x: A) -> {List.length(&2, A, List.replicate(A, n, x)) == n : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %replicate_len(A, p, x) : {1n+List.length(&2, A, List.replicate(A, p, x)) == 1n+_ : Nat}
      {==}

def take_pad_len.app(
  -A: Data,
  +fill: A,
  +xs: List<&2, A>,
  +n: Nat
) -> {Util.nat_min(n, List.length(&2, A, List.append(&2, A, xs, List.replicate(A, n, fill)))) == Util.nat_min(n, Nat.add(List.length(&2, A, xs), List.length(&2, A, List.replicate(A, n, fill)))) : Nat}:
  %len_append(A, xs, List.replicate(A, n, fill)) : {Util.nat_min(n, List.length(&2, A, List.append(&2, A, xs, List.replicate(A, n, fill)))) == Util.nat_min(n, _) : Nat}
  {==}

def take_pad_len.rep(
  -A: Data,
  +fill: A,
  +xs: List<&2, A>,
  +n: Nat
) -> {Util.nat_min(n, Nat.add(List.length(&2, A, xs), List.length(&2, A, List.replicate(A, n, fill)))) == Util.nat_min(n, Nat.add(List.length(&2, A, xs), n)) : Nat}:
  %replicate_len(A, n, fill) : {Util.nat_min(n, Nat.add(List.length(&2, A, xs), List.length(&2, A, List.replicate(A, n, fill)))) == Util.nat_min(n, Nat.add(List.length(&2, A, xs), _)) : Nat}
  {==}

def take_pad_len.min(
  -A: Data,
  +fill: A,
  +xs: List<&2, A>,
  +n: Nat
) -> {Util.nat_min(n, Nat.add(List.length(&2, A, xs), List.length(&2, A, List.replicate(A, n, fill)))) == n : Nat}:
  Equal.trans(
    Nat,
    Util.nat_min(n, Nat.add(List.length(&2, A, xs), List.length(&2, A, List.replicate(A, n, fill)))),
    Util.nat_min(n, Nat.add(List.length(&2, A, xs), n)),
    n,
    take_pad_len.rep(A, fill, xs, n),
    min_add_r(n, List.length(&2, A, xs))
  )

def take_pad_len.fin(
  -A: Data,
  +fill: A,
  +xs: List<&2, A>,
  +n: Nat
) -> {Util.nat_min(n, List.length(&2, A, List.append(&2, A, xs, List.replicate(A, n, fill)))) == n : Nat}:
  Equal.trans(
    Nat,
    Util.nat_min(n, List.length(&2, A, List.append(&2, A, xs, List.replicate(A, n, fill)))),
    Util.nat_min(n, Nat.add(List.length(&2, A, xs), List.length(&2, A, List.replicate(A, n, fill)))),
    n,
    take_pad_len.app(A, fill, xs, n),
    take_pad_len.min(A, fill, xs, n)
  )

def take_pad_len(
  -A: Data,
  +fill: A,
  +xs: List<&2, A>,
  +n: Nat
) -> {List.length(&2, A, Util.list_take_pad(A, fill, xs, n)) == n : Nat}:
  Equal.trans(
    Nat,
    List.length(&2, A, List.take(&2, A, List.append(&2, A, xs, List.replicate(A, n, fill)), n)),
    Util.nat_min(n, List.length(&2, A, List.append(&2, A, xs, List.replicate(A, n, fill)))),
    n,
    take_len(A, List.append(&2, A, xs, List.replicate(A, n, fill)), n),
    take_pad_len.fin(A, fill, xs, n)
  )

def size_lock_len.app(+xs: List<&2, Nat>, +want: Nat, +n: Nat) -> {Util.nat_min(want, List.length(&2, Nat, List.append(&2, Nat, Surv.pad_idxs(xs, want, n), List.range(want)))) == Util.nat_min(want, Nat.add(List.length(&2, Nat, Surv.pad_idxs(xs, want, n)), List.length(&2, Nat, List.range(want)))) : Nat}:
  %len_append(Nat, Surv.pad_idxs(xs, want, n), List.range(want)) : {Util.nat_min(want, List.length(&2, Nat, List.append(&2, Nat, Surv.pad_idxs(xs, want, n), List.range(want)))) == Util.nat_min(want, _) : Nat}
  {==}

def size_lock_len.rng(+xs: List<&2, Nat>, +want: Nat, +n: Nat) -> {Util.nat_min(want, Nat.add(List.length(&2, Nat, Surv.pad_idxs(xs, want, n)), List.length(&2, Nat, List.range(want)))) == Util.nat_min(want, Nat.add(List.length(&2, Nat, Surv.pad_idxs(xs, want, n)), want)) : Nat}:
  %range_len(want) : {Util.nat_min(want, Nat.add(List.length(&2, Nat, Surv.pad_idxs(xs, want, n)), List.length(&2, Nat, List.range(want)))) == Util.nat_min(want, Nat.add(List.length(&2, Nat, Surv.pad_idxs(xs, want, n)), _)) : Nat}
  {==}

def size_lock_len.min(+xs: List<&2, Nat>, +want: Nat, +n: Nat) -> {Util.nat_min(want, Nat.add(List.length(&2, Nat, Surv.pad_idxs(xs, want, n)), List.length(&2, Nat, List.range(want)))) == want : Nat}:
  Equal.trans(
    Nat,
    Util.nat_min(want, Nat.add(List.length(&2, Nat, Surv.pad_idxs(xs, want, n)), List.length(&2, Nat, List.range(want)))),
    Util.nat_min(want, Nat.add(List.length(&2, Nat, Surv.pad_idxs(xs, want, n)), want)),
    want,
    size_lock_len.rng(xs, want, n),
    min_add_r(want, List.length(&2, Nat, Surv.pad_idxs(xs, want, n)))
  )

def size_lock_len.fin(+xs: List<&2, Nat>, +want: Nat, +n: Nat) -> {Util.nat_min(want, List.length(&2, Nat, List.append(&2, Nat, Surv.pad_idxs(xs, want, n), List.range(want)))) == want : Nat}:
  Equal.trans(
    Nat,
    Util.nat_min(want, List.length(&2, Nat, List.append(&2, Nat, Surv.pad_idxs(xs, want, n), List.range(want)))),
    Util.nat_min(want, Nat.add(List.length(&2, Nat, Surv.pad_idxs(xs, want, n)), List.length(&2, Nat, List.range(want)))),
    want,
    size_lock_len.app(xs, want, n),
    size_lock_len.min(xs, want, n)
  )

def size_lock_len(+xs: List<&2, Nat>, +want: Nat, +n: Nat) -> {Util.list_len(Nat, Surv.size_lock(xs, want, n)) == want : Nat}:
  Equal.trans(
    Nat,
    List.length(&2, Nat, List.take(&2, Nat, List.append(&2, Nat, Surv.pad_idxs(xs, want, n), List.range(want)), want)),
    Util.nat_min(want, List.length(&2, Nat, List.append(&2, Nat, Surv.pad_idxs(xs, want, n), List.range(want)))),
    want,
    take_len(Nat, List.append(&2, Nat, Surv.pad_idxs(xs, want, n), List.range(want)), want),
    size_lock_len.fin(xs, want, n)
  )

def gather_len(+pop: List<&2, Ind.Individual>, +idxs: List<&2, Nat>) -> {Util.list_len(Ind.Individual, Surv.gather(pop, idxs)) == Util.list_len(Nat, idxs) : Nat}:
  map_halves_len(~Nat, ~Ind.Individual, ~List<&2, Ind.Individual>, ~Surv.gather.one, pop, Util.list_len(Nat, idxs), idxs)

def split_len(s: NDS.Split) -> Nat:
  match s:
    case NDS.Split{ff, ot}:
      Nat.add(Util.list_len(Nat, ff), Util.list_len(NDS.Row, ot))

def split_put_len.t(
  +ff: List<&2, Nat>,
  +ot: List<&2, NDS.Row>,
  +n: Nat,
  e: {Nat.add(Util.list_len(Nat, ff), Util.list_len(NDS.Row, ot)) == n : Nat}
) -> {Nat.add(Util.list_len(Nat, ff), 1n+Util.list_len(NDS.Row, ot)) == 1n+n : Nat}:
  Equal.trans(
    Nat,
    Nat.add(Util.list_len(Nat, ff), 1n+Util.list_len(NDS.Row, ot)),
    1n+Nat.add(Util.list_len(Nat, ff), Util.list_len(NDS.Row, ot)),
    1n+n,
    add_succ_r(Util.list_len(Nat, ff), Util.list_len(NDS.Row, ot)),
    succ_eq(Nat.add(Util.list_len(Nat, ff), Util.list_len(NDS.Row, ot)), n, e)
  )

def split_put_len.f(
  +ff: List<&2, Nat>,
  +ot: List<&2, NDS.Row>,
  +n: Nat,
  e: {Nat.add(Util.list_len(Nat, ff), Util.list_len(NDS.Row, ot)) == n : Nat}
) -> {Nat.add(1n+Util.list_len(Nat, ff), Util.list_len(NDS.Row, ot)) == 1n+n : Nat}:
  %e : {1n+Nat.add(Util.list_len(Nat, ff), Util.list_len(NDS.Row, ot)) == 1n+_ : Nat}
  {==}

def split_walk_len.cons(
  +r: NDS.Row,
  +rest: List<&2, NDS.Row>,
  s: NDS.Split,
  dominated: Bool,
  e: {split_len(s) == Util.list_len(NDS.Row, rest) : Nat}
) -> {split_len(NDS.split_put(r, s, dominated)) == 1n+Util.list_len(NDS.Row, rest) : Nat}:
  match s:
    case NDS.Split{ff, ot}:
      match dominated:
        case True{}:
          split_put_len.t(ff, ot, Util.list_len(NDS.Row, rest), e)
        case False{}:
          split_put_len.f(ff, ot, Util.list_len(NDS.Row, rest), e)

def add_comm(a: Nat, +b: Nat) -> {Nat.add(a, b) == Nat.add(b, a) : Nat}:
  match a:
    case 0n:
      Equal.sym(Nat, Nat.add(b, 0n), b, add_zero_r(b))
    case 1n++p:
      Equal.trans(
        Nat,
        1n+Nat.add(p, b),
        1n+Nat.add(b, p),
        Nat.add(b, 1n+p),
        succ_eq(Nat.add(p, b), Nat.add(b, p), add_comm(p, b)),
        Equal.sym(Nat, Nat.add(b, 1n+p), 1n+Nat.add(b, p), add_succ_r(b, p))
      )

def add_assoc(+a: Nat, +b: Nat, +c: Nat) -> {Nat.add(Nat.add(a, b), c) == Nat.add(a, Nat.add(b, c)) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n++p:
      succ_eq(Nat.add(Nat.add(p, b), c), Nat.add(p, Nat.add(b, c)), add_assoc(p, b, c))

def add4_rearr(+a: Nat, +b: Nat, +c: Nat, +d: Nat) -> {Nat.add(Nat.add(a, b), Nat.add(c, d)) == Nat.add(Nat.add(a, c), Nat.add(b, d)) : Nat}:
  Equal.trans(
    Nat,
    Nat.add(Nat.add(a, b), Nat.add(c, d)),
    Nat.add(a, Nat.add(b, Nat.add(c, d))),
    Nat.add(Nat.add(a, c), Nat.add(b, d)),
    add_assoc(a, b, Nat.add(c, d)),
    Equal.trans(
      Nat,
      Nat.add(a, Nat.add(b, Nat.add(c, d))),
      Nat.add(a, Nat.add(Nat.add(b, c), d)),
      Nat.add(Nat.add(a, c), Nat.add(b, d)),
      add_both(a, Nat.add(b, Nat.add(c, d)), a, Nat.add(Nat.add(b, c), d), {==}, Equal.sym(Nat, Nat.add(Nat.add(b, c), d), Nat.add(b, Nat.add(c, d)), add_assoc(b, c, d))),
      Equal.trans(
        Nat,
        Nat.add(a, Nat.add(Nat.add(b, c), d)),
        Nat.add(a, Nat.add(Nat.add(c, b), d)),
        Nat.add(Nat.add(a, c), Nat.add(b, d)),
        add_both(a, Nat.add(Nat.add(b, c), d), a, Nat.add(Nat.add(c, b), d), {==}, add_both(Nat.add(b, c), d, Nat.add(c, b), d, add_comm(b, c), {==})),
        Equal.trans(
          Nat,
          Nat.add(a, Nat.add(Nat.add(c, b), d)),
          Nat.add(a, Nat.add(c, Nat.add(b, d))),
          Nat.add(Nat.add(a, c), Nat.add(b, d)),
          add_both(a, Nat.add(Nat.add(c, b), d), a, Nat.add(c, Nat.add(b, d)), {==}, add_assoc(c, b, d)),
          Equal.sym(Nat, Nat.add(Nat.add(a, c), Nat.add(b, d)), Nat.add(a, Nat.add(c, Nat.add(b, d))), add_assoc(a, c, Nat.add(b, d)))
        )
      )
    )
  )

def split_cat_len.body(
  +ff1: List<&2, Nat>,
  +ot1: List<&2, NDS.Row>,
  +ff2: List<&2, Nat>,
  +ot2: List<&2, NDS.Row>
) -> {Nat.add(Util.list_len(Nat, List.append(&2, Nat, ff1, ff2)), Util.list_len(NDS.Row, List.append(&2, NDS.Row, ot1, ot2))) == Nat.add(Nat.add(Util.list_len(Nat, ff1), Util.list_len(NDS.Row, ot1)), Nat.add(Util.list_len(Nat, ff2), Util.list_len(NDS.Row, ot2))) : Nat}:
  Equal.trans(
    Nat,
    Nat.add(Util.list_len(Nat, List.append(&2, Nat, ff1, ff2)), Util.list_len(NDS.Row, List.append(&2, NDS.Row, ot1, ot2))),
    Nat.add(Nat.add(Util.list_len(Nat, ff1), Util.list_len(Nat, ff2)), Nat.add(Util.list_len(NDS.Row, ot1), Util.list_len(NDS.Row, ot2))),
    Nat.add(Nat.add(Util.list_len(Nat, ff1), Util.list_len(NDS.Row, ot1)), Nat.add(Util.list_len(Nat, ff2), Util.list_len(NDS.Row, ot2))),
    add_both(
      Util.list_len(Nat, List.append(&2, Nat, ff1, ff2)),
      Util.list_len(NDS.Row, List.append(&2, NDS.Row, ot1, ot2)),
      Nat.add(Util.list_len(Nat, ff1), Util.list_len(Nat, ff2)),
      Nat.add(Util.list_len(NDS.Row, ot1), Util.list_len(NDS.Row, ot2)),
      len_append(Nat, ff1, ff2),
      len_append(NDS.Row, ot1, ot2)
    ),
    add4_rearr(Util.list_len(Nat, ff1), Util.list_len(Nat, ff2), Util.list_len(NDS.Row, ot1), Util.list_len(NDS.Row, ot2))
  )

def split_cat_len(a: NDS.Split, b: NDS.Split) -> {split_len(NDS.split_cat(a, b)) == Nat.add(split_len(a), split_len(b)) : Nat}:
  match a b:
    case NDS.Split{ff1, ot1} NDS.Split{ff2, ot2}:
      split_cat_len.body(ff1, ot1, ff2, ot2)

def split_walk_go_len.mid(
  +all: List<&2, NDS.Row>,
  +p: Nat,
  +xs: List<&2, NDS.Row>,
  +mid: Nat,
  e_lo: {split_len(NDS.split_walk.go(all, p, List.take(&2, NDS.Row, xs, mid))) == Util.list_len(NDS.Row, List.take(&2, NDS.Row, xs, mid)) : Nat},
  e_hi: {split_len(NDS.split_walk.go(all, p, List.drop(&2, NDS.Row, xs, mid))) == Util.list_len(NDS.Row, List.drop(&2, NDS.Row, xs, mid)) : Nat}
) -> {split_len(NDS.split_cat(NDS.split_walk.go(all, p, List.take(&2, NDS.Row, xs, mid)), NDS.split_walk.go(all, p, List.drop(&2, NDS.Row, xs, mid)))) == Nat.add(Util.list_len(NDS.Row, List.take(&2, NDS.Row, xs, mid)), Util.list_len(NDS.Row, List.drop(&2, NDS.Row, xs, mid))) : Nat}:
  Equal.trans(
    Nat,
    split_len(NDS.split_cat(NDS.split_walk.go(all, p, List.take(&2, NDS.Row, xs, mid)), NDS.split_walk.go(all, p, List.drop(&2, NDS.Row, xs, mid)))),
    Nat.add(split_len(NDS.split_walk.go(all, p, List.take(&2, NDS.Row, xs, mid))), split_len(NDS.split_walk.go(all, p, List.drop(&2, NDS.Row, xs, mid)))),
    Nat.add(Util.list_len(NDS.Row, List.take(&2, NDS.Row, xs, mid)), Util.list_len(NDS.Row, List.drop(&2, NDS.Row, xs, mid))),
    split_cat_len(NDS.split_walk.go(all, p, List.take(&2, NDS.Row, xs, mid)), NDS.split_walk.go(all, p, List.drop(&2, NDS.Row, xs, mid))),
    add_both(
      split_len(NDS.split_walk.go(all, p, List.take(&2, NDS.Row, xs, mid))),
      split_len(NDS.split_walk.go(all, p, List.drop(&2, NDS.Row, xs, mid))),
      Util.list_len(NDS.Row, List.take(&2, NDS.Row, xs, mid)),
      Util.list_len(NDS.Row, List.drop(&2, NDS.Row, xs, mid)),
      e_lo,
      e_hi
    )
  )

def split_walk_go_len.finish(
  +all: List<&2, NDS.Row>,
  +p: Nat,
  +xs: List<&2, NDS.Row>,
  +mid: Nat,
  e_lo: {split_len(NDS.split_walk.go(all, p, List.take(&2, NDS.Row, xs, mid))) == Util.list_len(NDS.Row, List.take(&2, NDS.Row, xs, mid)) : Nat},
  e_hi: {split_len(NDS.split_walk.go(all, p, List.drop(&2, NDS.Row, xs, mid))) == Util.list_len(NDS.Row, List.drop(&2, NDS.Row, xs, mid)) : Nat}
) -> {split_len(NDS.split_cat(NDS.split_walk.go(all, p, List.take(&2, NDS.Row, xs, mid)), NDS.split_walk.go(all, p, List.drop(&2, NDS.Row, xs, mid)))) == Util.list_len(NDS.Row, xs) : Nat}:
  Equal.trans(
    Nat,
    split_len(NDS.split_cat(NDS.split_walk.go(all, p, List.take(&2, NDS.Row, xs, mid)), NDS.split_walk.go(all, p, List.drop(&2, NDS.Row, xs, mid)))),
    Nat.add(Util.list_len(NDS.Row, List.take(&2, NDS.Row, xs, mid)), Util.list_len(NDS.Row, List.drop(&2, NDS.Row, xs, mid))),
    Util.list_len(NDS.Row, xs),
    split_walk_go_len.mid(all, p, xs, mid, e_lo, e_hi),
    take_drop_len(NDS.Row, xs, mid)
  )

def split_walk_go_len(
  +all: List<&2, NDS.Row>,
  +fuel: Nat,
  cand: List<&2, NDS.Row>
) -> {split_len(NDS.split_walk.go(all, fuel, cand)) == Util.list_len(NDS.Row, cand) : Nat}:
  match fuel cand:
    case 0n Nil{}:
      {==}
    case 0n +r <> +rest:
      split_walk_len.cons(r, rest, NDS.split_walk.go(all, 0n, rest), NDS.row_dom(all, r), split_walk_go_len(all, 0n, rest))
    case 1n+p Nil{}:
      {==}
    case 1n+p +r <> Nil{}:
      split_walk_len.cons(r, Nil{}, NDS.Split{Nil{}, Nil{}}, NDS.row_dom(all, r), {==})
    case 1n+p +h <> +k <> +rest:
      +xs = {h <> k <> rest : List<&2, NDS.Row>}
      +mid = Nat.div(Util.list_len(NDS.Row, xs), 2n)
      split_walk_go_len.finish(
        all,
        p,
        xs,
        mid,
        split_walk_go_len(all, p, List.take(&2, NDS.Row, xs, mid)),
        split_walk_go_len(all, p, List.drop(&2, NDS.Row, xs, mid))
      )

def split_walk_len(
  +all: List<&2, NDS.Row>,
  +cand: List<&2, NDS.Row>
) -> {split_len(NDS.split_walk(all, cand)) == Util.list_len(NDS.Row, cand) : Nat}:
  split_walk_go_len(all, Util.list_len(NDS.Row, cand), cand)

def split_ne_len(
  +r: NDS.Row,
  +rest: List<&2, NDS.Row>,
  s: NDS.Split,
  e: {split_len(s) == 1n+Util.list_len(NDS.Row, rest) : Nat}
) -> {split_len(NDS.split_ne(r, rest, s)) == 1n+Util.list_len(NDS.Row, rest) : Nat}:
  match s:
    case NDS.Split{ff, ot}:
      match ff:
        case Nil{}:
          {==}
        case h <> t:
          e

def split_front_len(
  +r: NDS.Row,
  +rest: List<&2, NDS.Row>
) -> {split_len(NDS.split_front(r <> rest)) == 1n+Util.list_len(NDS.Row, rest) : Nat}:
  split_ne_len(r, rest, NDS.split_walk(r <> rest, r <> rest), split_walk_len(r <> rest, r <> rest))

def row_idxs_len(rs: List<&2, NDS.Row>) -> {Util.list_len(Nat, NDS.row_idxs(rs)) == Util.list_len(NDS.Row, rs) : Nat}:
  match rs:
    case Nil{}:
      {==}
    case +r <> +t:
      %row_idxs_len(t) : {1n+Util.list_len(Nat, NDS.row_idxs(t)) == 1n+_ : Nat}
      {==}

def peel_count.fin(
  +f: Nat,
  s: NDS.Split,
  +n: Nat,
  e_part: {split_len(s) == n : Nat},
  e_ih: {NDS.front_index_count(NDS.peel(f, NDS.split_snd(s))) == Util.list_len(NDS.Row, NDS.split_snd(s)) : Nat}
) -> {Nat.add(Util.list_len(Nat, NDS.split_fst(s)), NDS.front_index_count(NDS.peel(f, NDS.split_snd(s)))) == n : Nat}:
  match s:
    case NDS.Split{+ff, +ot}:
      Equal.trans(
        Nat,
        Nat.add(Util.list_len(Nat, ff), NDS.front_index_count(NDS.peel(f, ot))),
        Nat.add(Util.list_len(Nat, ff), Util.list_len(NDS.Row, ot)),
        n,
        add_both(
          Util.list_len(Nat, ff),
          NDS.front_index_count(NDS.peel(f, ot)),
          Util.list_len(Nat, ff),
          Util.list_len(NDS.Row, ot),
          {==},
          e_ih
        ),
        e_part
      )

def peel_count.fuel0(
  +r: NDS.Row,
  +rest: List<&2, NDS.Row>
) -> {NDS.front_index_count(NDS.row_idxs({r <> rest : List<&2, NDS.Row>}) <> Nil{}) == Util.list_len(NDS.Row, {r <> rest : List<&2, NDS.Row>}) : Nat}:
  Equal.trans(
    Nat,
    Nat.add(Util.list_len(Nat, NDS.row_idxs({r <> rest : List<&2, NDS.Row>})), 0n),
    Util.list_len(Nat, NDS.row_idxs({r <> rest : List<&2, NDS.Row>})),
    Util.list_len(NDS.Row, {r <> rest : List<&2, NDS.Row>}),
    add_zero_r(Util.list_len(Nat, NDS.row_idxs({r <> rest : List<&2, NDS.Row>}))),
    row_idxs_len({r <> rest : List<&2, NDS.Row>})
  )

def peel_count(
  fuel: Nat,
  remaining: List<&2, NDS.Row>
) -> {NDS.front_index_count(NDS.peel(fuel, remaining)) == Util.list_len(NDS.Row, remaining) : Nat}:
  match fuel remaining:
    case 0n Nil{}:
      {==}
    case 1n+f Nil{}:
      {==}
    case 0n +r <> +rest:
      peel_count.fuel0(r, rest)
    case 1n++f +r <> +rest:
      +s = NDS.split_front({r <> rest : List<&2, NDS.Row>})
      peel_count.fin(
        f,
        s,
        1n+Util.list_len(NDS.Row, rest),
        split_front_len(r, rest),
        peel_count(f, NDS.split_snd(s))
      )

def rows_of_len.go(pop: List<&2, Ind.Individual>, +i: Nat) -> {Util.list_len(NDS.Row, NDS.rows_of.go(pop, i)) == Util.list_len(Ind.Individual, pop) : Nat}:
  match pop:
    case Nil{}:
      {==}
    case +h <> +t:
      %rows_of_len.go(t, 1n+i) : {1n+Util.list_len(NDS.Row, NDS.rows_of.go(t, 1n+i)) == 1n+_ : Nat}
      {==}

def Laws.sort_index_count(pop):
  match pop:
    case Nil{}:
      {==}
    case +h <> +t:
      +rs = NDS.rows_of.go({h <> t : List<&2, Ind.Individual>}, 0n)
      Equal.trans(
        Nat,
        NDS.front_index_count(NDS.peel(Util.list_len(NDS.Row, rs), rs)),
        Util.list_len(NDS.Row, rs),
        Util.list_len(Ind.Individual, {h <> t : List<&2, Ind.Individual>}),
        peel_count(Util.list_len(NDS.Row, rs), rs),
        rows_of_len.go({h <> t : List<&2, Ind.Individual>}, 0n)
      )

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
  match m:
    case 0n:
      {==}
    case 1n+rd:
      match rd:
        case 0n:
          {==}
        case 1n+q:
          das_ge2_len(1n+q, p)

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
  +npop = Util.list_len(Ind.Individual, pop)
  +want = Util.nat_min(n, npop)
  +idxs = Surv.size_lock(Surv.select_idx.by(pop, n, dirs, Nat.is_le(npop, n)), want, npop)
  Equal.trans(
    Nat,
    Util.list_len(Ind.Individual, Surv.gather(pop, idxs)),
    Util.list_len(Nat, idxs),
    want,
    gather_len(pop, idxs),
    size_lock_len(Surv.select_idx.by(pop, n, dirs, Nat.is_le(npop, n)), want, npop)
  )

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
  {==}

def Laws.sbx_prob0_child2_vars():
  {==}

def Laws.poly_prob0_vars():
  {==}

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
  +n = Algo.cfg_pop(cfg)
  take_pad_len(Ind.Individual, Ind.from_objectives(Nil{}), Algo.run.sized(Prob.zdt1(30n), cfg, n), n)

# --- niche_count_sum: mid-split histogram conservation -------------------

def add_one_r(+x: Nat) -> {Nat.add(x, 1n) == 1n+x : Nat}:
  Equal.trans(
    Nat,
    Nat.add(x, 1n),
    1n+Nat.add(x, 0n),
    1n+x,
    add_succ_r(x, 0n),
    succ_eq(Nat.add(x, 0n), x, add_zero_r(x))
  )

def nat_pred(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      p

def succ_inj(+a: Nat, +b: Nat, e: {1n+a == 1n+b : Nat}) -> {a == b : Nat}:
  %e : {nat_pred(1n+a) == nat_pred(_) : Nat}
  {==}

def zeros_sum(n: Nat) -> {Util.nats_sum(Util.zeros_nat(n)) == 0n : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      zeros_sum(p)

def bin_hit_n0(i: Nat) -> {Util.bin_hit(i, 0n) == 0n : Nat}:
  match i:
    case 0n:
      {==}
    case 1n+p:
      {==}

def bin_hit_cong(+i: Nat, +a: Nat, +b: Nat, e: {a == b : Nat}) -> {Util.bin_hit(i, a) == Util.bin_hit(i, b) : Nat}:
  %e : {Util.bin_hit(i, a) == Util.bin_hit(i, _) : Nat}
  {==}

def set_len(-A: Data, xs: List<&2, A>, n: Nat, +x: A) -> {Util.list_len(A, List.set(&2, A, xs, n, x)) == Util.list_len(A, xs) : Nat}:
  match xs n:
    case Nil{} k:
      {==}
    case h <> t 0n:
      {==}
    case h <> t 1n+p:
      %set_len(A, t, p, x) : {1n+Util.list_len(A, List.set(&2, A, t, p, x)) == 1n+_ : Nat}
      {==}

def inc_at_len(+xs: List<&2, Nat>, +i: Nat) -> {Util.list_len(Nat, Util.inc_at(xs, i)) == Util.list_len(Nat, xs) : Nat}:
  set_len(Nat, xs, i, 1n+Util.get_nat(xs, i))

def nats_add_same_len(a: List<&2, Nat>, b: List<&2, Nat>, e: {Util.list_len(Nat, a) == Util.list_len(Nat, b) : Nat}) -> {Util.list_len(Nat, Util.nats_add(a, b)) == Util.list_len(Nat, a) : Nat}:
  match a b:
    case Nil{} Nil{}:
      {==}
    case +x <> xs +y <> ys:
      %nats_add_same_len(xs, ys, succ_inj(Util.list_len(Nat, xs), Util.list_len(Nat, ys), e)) : {1n+Util.list_len(Nat, Util.nats_add(xs, ys)) == 1n+_ : Nat}
      {==}
    case Nil{} +y <> ys:
      Equal.sym(Nat, Util.list_len(Nat, y <> ys), 0n, e)
    case +x <> xs Nil{}:
      {==}

def nats_add_len_n(
  +a: List<&2, Nat>,
  +b: List<&2, Nat>,
  +n: Nat,
  e_a: {Util.list_len(Nat, a) == n : Nat},
  e_b: {Util.list_len(Nat, b) == n : Nat}
) -> {Util.list_len(Nat, Util.nats_add(a, b)) == n : Nat}:
  Equal.trans(
    Nat,
    Util.list_len(Nat, Util.nats_add(a, b)),
    Util.list_len(Nat, a),
    n,
    nats_add_same_len(
      a,
      b,
      Equal.trans(Nat, Util.list_len(Nat, a), n, Util.list_len(Nat, b), e_a, Equal.sym(Nat, Util.list_len(Nat, b), n, e_b))
    ),
    e_a
  )

def nats_add_sum(a: List<&2, Nat>, b: List<&2, Nat>) -> {Util.nats_sum(Util.nats_add(a, b)) == Nat.add(Util.nats_sum(a), Util.nats_sum(b)) : Nat}:
  match a b:
    case Nil{} Nil{}:
      {==}
    case +x <> xs +y <> ys:
      Equal.trans(
        Nat,
        Nat.add(Nat.add(x, y), Util.nats_sum(Util.nats_add(xs, ys))),
        Nat.add(Nat.add(x, y), Nat.add(Util.nats_sum(xs), Util.nats_sum(ys))),
        Nat.add(Nat.add(x, Util.nats_sum(xs)), Nat.add(y, Util.nats_sum(ys))),
        add_both(
          Nat.add(x, y),
          Util.nats_sum(Util.nats_add(xs, ys)),
          Nat.add(x, y),
          Nat.add(Util.nats_sum(xs), Util.nats_sum(ys)),
          {==},
          nats_add_sum(xs, ys)
        ),
        add4_rearr(x, y, Util.nats_sum(xs), Util.nats_sum(ys))
      )
    case Nil{} ys:
      {==}
    case xs Nil{}:
      add_zero_r(Util.nats_sum(xs))

def inc_at_sum.nil(i: Nat) -> {Util.nats_sum(Util.inc_at(Nil{}, i)) == Nat.add(Util.nats_sum(Nil{}), Util.bin_hit(i, 0n)) : Nat}:
  %bin_hit_n0(i) : {0n == Nat.add(0n, _) : Nat}
  {==}

def inc_at_sum.zero(+h: Nat, +t: List<&2, Nat>) -> {Util.nats_sum(Util.inc_at(h <> t, 0n)) == Nat.add(Util.nats_sum(h <> t), 1n) : Nat}:
  Equal.sym(
    Nat,
    Nat.add(Nat.add(h, Util.nats_sum(t)), 1n),
    1n+Nat.add(h, Util.nats_sum(t)),
    add_one_r(Nat.add(h, Util.nats_sum(t)))
  )

def inc_at_sum(
  xs: List<&2, Nat>,
  i: Nat
) -> {Util.nats_sum(Util.inc_at(xs, i)) == Nat.add(Util.nats_sum(xs), Util.bin_hit(i, Util.list_len(Nat, xs))) : Nat}:
  match xs i:
    case Nil{} k:
      inc_at_sum.nil(k)
    case +h <> t 0n:
      inc_at_sum.zero(h, t)
    case +h <> t 1n+p:
      Equal.trans(
        Nat,
        Nat.add(h, Util.nats_sum(Util.inc_at(t, p))),
        Nat.add(h, Nat.add(Util.nats_sum(t), Util.bin_hit(p, Util.list_len(Nat, t)))),
        Nat.add(Nat.add(h, Util.nats_sum(t)), Util.bin_hit(p, Util.list_len(Nat, t))),
        add_both(
          h,
          Util.nats_sum(Util.inc_at(t, p)),
          h,
          Nat.add(Util.nats_sum(t), Util.bin_hit(p, Util.list_len(Nat, t))),
          {==},
          inc_at_sum(t, p)
        ),
        Equal.sym(
          Nat,
          Nat.add(Nat.add(h, Util.nats_sum(t)), Util.bin_hit(p, Util.list_len(Nat, t))),
          Nat.add(h, Nat.add(Util.nats_sum(t), Util.bin_hit(p, Util.list_len(Nat, t)))),
          add_assoc(h, Util.nats_sum(t), Util.bin_hit(p, Util.list_len(Nat, t)))
        )
      )

def in_bin_take_drop(+n: Nat, asgs: List<&2, Surv.Assignment>, mid: Nat) -> {Nat.add(Surv.in_bin_count(List.take(&2, Surv.Assignment, asgs, mid), n), Surv.in_bin_count(List.drop(&2, Surv.Assignment, asgs, mid), n)) == Surv.in_bin_count(asgs, n) : Nat}:
  match asgs mid:
    case Nil{} k:
      {==}
    case +a <> rest 0n:
      {==}
    case +a <> +rest 1n+p:
      Equal.trans(
        Nat,
        Nat.add(Nat.add(Util.bin_hit(Surv.asg_ref(a), n), Surv.in_bin_count(List.take(&2, Surv.Assignment, rest, p), n)), Surv.in_bin_count(List.drop(&2, Surv.Assignment, rest, p), n)),
        Nat.add(Util.bin_hit(Surv.asg_ref(a), n), Nat.add(Surv.in_bin_count(List.take(&2, Surv.Assignment, rest, p), n), Surv.in_bin_count(List.drop(&2, Surv.Assignment, rest, p), n))),
        Nat.add(Util.bin_hit(Surv.asg_ref(a), n), Surv.in_bin_count(rest, n)),
        add_assoc(Util.bin_hit(Surv.asg_ref(a), n), Surv.in_bin_count(List.take(&2, Surv.Assignment, rest, p), n), Surv.in_bin_count(List.drop(&2, Surv.Assignment, rest, p), n)),
        add_both(
          Util.bin_hit(Surv.asg_ref(a), n),
          Nat.add(Surv.in_bin_count(List.take(&2, Surv.Assignment, rest, p), n), Surv.in_bin_count(List.drop(&2, Surv.Assignment, rest, p), n)),
          Util.bin_hit(Surv.asg_ref(a), n),
          Surv.in_bin_count(rest, n),
          {==},
          in_bin_take_drop(n, rest, p)
        )
      )

def count_raw_len(
  +n: Nat,
  +fuel: Nat,
  asgs: List<&2, Surv.Assignment>
) -> {Util.list_len(Nat, Surv.count_raw.go(n, fuel, asgs)) == n : Nat}:
  match fuel asgs:
    case 0n Nil{}:
      replicate_len(Nat, n, 0n)
    case 0n +a <> +rest:
      Equal.trans(
        Nat,
        Util.list_len(Nat, Util.inc_at(Surv.count_raw.go(n, 0n, rest), Surv.asg_ref(a))),
        Util.list_len(Nat, Surv.count_raw.go(n, 0n, rest)),
        n,
        inc_at_len(Surv.count_raw.go(n, 0n, rest), Surv.asg_ref(a)),
        count_raw_len(n, 0n, rest)
      )
    case 1n+p Nil{}:
      replicate_len(Nat, n, 0n)
    case 1n+p +a <> Nil{}:
      Equal.trans(
        Nat,
        Util.list_len(Nat, Util.inc_at(Util.zeros_nat(n), Surv.asg_ref(a))),
        Util.list_len(Nat, Util.zeros_nat(n)),
        n,
        inc_at_len(Util.zeros_nat(n), Surv.asg_ref(a)),
        replicate_len(Nat, n, 0n)
      )
    case 1n+p +h <> +k <> +rest:
      +all = {h <> k <> rest : List<&2, Surv.Assignment>}
      +mid = Nat.div(Util.list_len(Surv.Assignment, all), 2n)
      nats_add_len_n(
        Surv.count_raw.go(n, p, List.take(&2, Surv.Assignment, all, mid)),
        Surv.count_raw.go(n, p, List.drop(&2, Surv.Assignment, all, mid)),
        n,
        count_raw_len(n, p, List.take(&2, Surv.Assignment, all, mid)),
        count_raw_len(n, p, List.drop(&2, Surv.Assignment, all, mid))
      )

def count_raw_sum.inc(
  +n: Nat,
  +hist: List<&2, Nat>,
  +i: Nat,
  +rest_count: Nat,
  e_len: {Util.list_len(Nat, hist) == n : Nat},
  e_sum: {Util.nats_sum(hist) == rest_count : Nat}
) -> {Util.nats_sum(Util.inc_at(hist, i)) == Nat.add(Util.bin_hit(i, n), rest_count) : Nat}:
  Equal.trans(
    Nat,
    Util.nats_sum(Util.inc_at(hist, i)),
    Nat.add(Util.nats_sum(hist), Util.bin_hit(i, Util.list_len(Nat, hist))),
    Nat.add(Util.bin_hit(i, n), rest_count),
    inc_at_sum(hist, i),
    Equal.trans(
      Nat,
      Nat.add(Util.nats_sum(hist), Util.bin_hit(i, Util.list_len(Nat, hist))),
      Nat.add(rest_count, Util.bin_hit(i, n)),
      Nat.add(Util.bin_hit(i, n), rest_count),
      add_both(
        Util.nats_sum(hist),
        Util.bin_hit(i, Util.list_len(Nat, hist)),
        rest_count,
        Util.bin_hit(i, n),
        e_sum,
        bin_hit_cong(i, Util.list_len(Nat, hist), n, e_len)
      ),
      add_comm(rest_count, Util.bin_hit(i, n))
    )
  )

def count_raw_sum.mid(
  +n: Nat,
  +p: Nat,
  +all: List<&2, Surv.Assignment>,
  +mid: Nat,
  e_lo: {Util.nats_sum(Surv.count_raw.go(n, p, List.take(&2, Surv.Assignment, all, mid))) == Surv.in_bin_count(List.take(&2, Surv.Assignment, all, mid), n) : Nat},
  e_hi: {Util.nats_sum(Surv.count_raw.go(n, p, List.drop(&2, Surv.Assignment, all, mid))) == Surv.in_bin_count(List.drop(&2, Surv.Assignment, all, mid), n) : Nat}
) -> {Util.nats_sum(Util.nats_add(Surv.count_raw.go(n, p, List.take(&2, Surv.Assignment, all, mid)), Surv.count_raw.go(n, p, List.drop(&2, Surv.Assignment, all, mid)))) == Nat.add(Surv.in_bin_count(List.take(&2, Surv.Assignment, all, mid), n), Surv.in_bin_count(List.drop(&2, Surv.Assignment, all, mid), n)) : Nat}:
  Equal.trans(
    Nat,
    Util.nats_sum(Util.nats_add(Surv.count_raw.go(n, p, List.take(&2, Surv.Assignment, all, mid)), Surv.count_raw.go(n, p, List.drop(&2, Surv.Assignment, all, mid)))),
    Nat.add(Util.nats_sum(Surv.count_raw.go(n, p, List.take(&2, Surv.Assignment, all, mid))), Util.nats_sum(Surv.count_raw.go(n, p, List.drop(&2, Surv.Assignment, all, mid)))),
    Nat.add(Surv.in_bin_count(List.take(&2, Surv.Assignment, all, mid), n), Surv.in_bin_count(List.drop(&2, Surv.Assignment, all, mid), n)),
    nats_add_sum(Surv.count_raw.go(n, p, List.take(&2, Surv.Assignment, all, mid)), Surv.count_raw.go(n, p, List.drop(&2, Surv.Assignment, all, mid))),
    add_both(
      Util.nats_sum(Surv.count_raw.go(n, p, List.take(&2, Surv.Assignment, all, mid))),
      Util.nats_sum(Surv.count_raw.go(n, p, List.drop(&2, Surv.Assignment, all, mid))),
      Surv.in_bin_count(List.take(&2, Surv.Assignment, all, mid), n),
      Surv.in_bin_count(List.drop(&2, Surv.Assignment, all, mid), n),
      e_lo,
      e_hi
    )
  )

def count_raw_sum.finish(
  +n: Nat,
  +p: Nat,
  +all: List<&2, Surv.Assignment>,
  +mid: Nat,
  e_lo: {Util.nats_sum(Surv.count_raw.go(n, p, List.take(&2, Surv.Assignment, all, mid))) == Surv.in_bin_count(List.take(&2, Surv.Assignment, all, mid), n) : Nat},
  e_hi: {Util.nats_sum(Surv.count_raw.go(n, p, List.drop(&2, Surv.Assignment, all, mid))) == Surv.in_bin_count(List.drop(&2, Surv.Assignment, all, mid), n) : Nat}
) -> {Util.nats_sum(Util.nats_add(Surv.count_raw.go(n, p, List.take(&2, Surv.Assignment, all, mid)), Surv.count_raw.go(n, p, List.drop(&2, Surv.Assignment, all, mid)))) == Surv.in_bin_count(all, n) : Nat}:
  Equal.trans(
    Nat,
    Util.nats_sum(Util.nats_add(Surv.count_raw.go(n, p, List.take(&2, Surv.Assignment, all, mid)), Surv.count_raw.go(n, p, List.drop(&2, Surv.Assignment, all, mid)))),
    Nat.add(Surv.in_bin_count(List.take(&2, Surv.Assignment, all, mid), n), Surv.in_bin_count(List.drop(&2, Surv.Assignment, all, mid), n)),
    Surv.in_bin_count(all, n),
    count_raw_sum.mid(n, p, all, mid, e_lo, e_hi),
    in_bin_take_drop(n, all, mid)
  )

def count_raw_sum(
  +n: Nat,
  +fuel: Nat,
  asgs: List<&2, Surv.Assignment>
) -> {Util.nats_sum(Surv.count_raw.go(n, fuel, asgs)) == Surv.in_bin_count(asgs, n) : Nat}:
  match fuel asgs:
    case 0n Nil{}:
      zeros_sum(n)
    case 0n +a <> +rest:
      count_raw_sum.inc(
        n,
        Surv.count_raw.go(n, 0n, rest),
        Surv.asg_ref(a),
        Surv.in_bin_count(rest, n),
        count_raw_len(n, 0n, rest),
        count_raw_sum(n, 0n, rest)
      )
    case 1n+p Nil{}:
      zeros_sum(n)
    case 1n+p +a <> Nil{}:
      count_raw_sum.inc(
        n,
        Util.zeros_nat(n),
        Surv.asg_ref(a),
        0n,
        replicate_len(Nat, n, 0n),
        zeros_sum(n)
      )
    case 1n+p +h <> +k <> +rest:
      +all = {h <> k <> rest : List<&2, Surv.Assignment>}
      +mid = Nat.div(Util.list_len(Surv.Assignment, all), 2n)
      count_raw_sum.finish(
        n,
        p,
        all,
        mid,
        count_raw_sum(n, p, List.take(&2, Surv.Assignment, all, mid)),
        count_raw_sum(n, p, List.drop(&2, Surv.Assignment, all, mid))
      )

def Laws.niche_count_sum(asgs, n_dirs):
  count_raw_sum(n_dirs, Util.list_len(Surv.Assignment, asgs), asgs)

