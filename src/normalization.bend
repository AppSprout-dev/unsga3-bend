# Normalization — C# Unsga3.Core.Normalization (v0).
# Persistent ideal / worst, ASF extreme points (previous extremes ∪ ND,
# or the whole population when the ND index set is empty), intercept
# hyperplane nadir via (E−ideal)·b = 1, then C# front/pop/unit fallbacks.
# ASF: floor 1e-3 on ideal-translated objectives; preferred axis weight 1,
# other axes 1e-6 (divide form).

import Base
import ./individual.bend as Ind
import ./util.bend as Util

type State is Data:
  MkState{
    n_objectives: Nat
    ideal: List<&2, F32>
    worst: List<&2, F32>
    nadir: List<&2, F32>
    intercepts: List<&2, F32>
    extremes: List<&2, List<&2, F32>>
  }

def new_state(n_objectives: Nat) -> State:
  MkState{n_objectives, Nil{}, Nil{}, Nil{}, Nil{}, Nil{}}

def state_n(st: State) -> Nat:
  match st:
    case MkState{n_objectives, ideal, worst, nadir, intercepts, extremes}:
      n_objectives

def state_ideal(st: State) -> List<&2, F32>:
  match st:
    case MkState{n_objectives, ideal, worst, nadir, intercepts, extremes}:
      ideal

def col_min.go(rest: List<&2, Ind.Individual>, acc: List<&2, F32>) -> List<&2, F32>:
  match rest:
    case Nil{}:
      acc
    case ind <> xs:
      col_min.go(xs, Util.vec_min(acc, Ind.objectives(ind)))

def col_min(pop: List<&2, Ind.Individual>) -> List<&2, F32>:
  match pop:
    case Nil{}:
      Nil{}
    case ind <> rest:
      col_min.go(rest, Ind.objectives(ind))

def col_max.go(rest: List<&2, Ind.Individual>, acc: List<&2, F32>) -> List<&2, F32>:
  match rest:
    case Nil{}:
      acc
    case ind <> xs:
      col_max.go(xs, Util.vec_max(acc, Ind.objectives(ind)))

def col_max(pop: List<&2, Ind.Individual>) -> List<&2, F32>:
  match pop:
    case Nil{}:
      Nil{}
    case ind <> rest:
      col_max.go(rest, Ind.objectives(ind))

def get_ind(+pop: List<&2, Ind.Individual>, i: Nat) -> Maybe<&2, Ind.Individual>:
  List.get(&2, Ind.Individual, pop, i)

def max_at.go(acc: List<&2, F32>, m: Maybe<&2, Ind.Individual>) -> List<&2, F32>:
  match m:
    case None{}:
      acc
    case Some{ind}:
      Util.vec_max(acc, Ind.objectives(ind))

def max_at(+pop: List<&2, Ind.Individual>, acc: List<&2, F32>, i: Nat) -> List<&2, F32>:
  max_at.go(acc, get_ind(pop, i))

def col_max_idx.go(+pop: List<&2, Ind.Individual>, idxs: List<&2, Nat>, acc: List<&2, F32>) -> List<&2, F32>:
  match idxs:
    case Nil{}:
      acc
    case i <> rest:
      col_max_idx.go(pop, rest, max_at(pop, acc, i))

def col_max_idx.start(+pop: List<&2, Ind.Individual>, rest: List<&2, Nat>, m: Maybe<&2, Ind.Individual>) -> List<&2, F32>:
  match m:
    case None{}:
      col_max_idx.go(pop, rest, col_max(pop))
    case Some{ind}:
      col_max_idx.go(pop, rest, Ind.objectives(ind))

def col_max_idx(+pop: List<&2, Ind.Individual>, idxs: List<&2, Nat>) -> List<&2, F32>:
  match idxs:
    case Nil{}:
      col_max(pop)
    case i <> rest:
      col_max_idx.start(pop, rest, get_ind(pop, i))

def merge_ideal(prev: List<&2, F32>, cur: List<&2, F32>) -> List<&2, F32>:
  match prev:
    case Nil{}:
      cur
    case x <> xs:
      Util.vec_min(x <> xs, cur)

def merge_worst(prev: List<&2, F32>, cur: List<&2, F32>) -> List<&2, F32>:
  match prev:
    case Nil{}:
      cur
    case x <> xs:
      Util.vec_max(x <> xs, cur)

def nd_or_all(nd: List<&2, Nat>, n: Nat) -> List<&2, Nat>:
  match nd:
    case Nil{}:
      List.range(n)
    case h <> t:
      h <> t

def obj_at.go(m: Maybe<&2, Ind.Individual>) -> List<&2, F32>:
  match m:
    case None{}:
      Nil{}
    case Some{ind}:
      Ind.objectives(ind)

def obj_at(+pop: List<&2, Ind.Individual>, i: Nat) -> List<&2, F32>:
  obj_at.go(get_ind(pop, i))

def gather_objs(+pop: List<&2, Ind.Individual>, idxs: List<&2, Nat>) -> List<&2, List<&2, F32>>:
  match idxs:
    case Nil{}:
      Nil{}
    case i <> rest:
      obj_at(pop, i) <> gather_objs(pop, rest)

def map_norm(+ideal: List<&2, F32>, +nadir: List<&2, F32>, pop: List<&2, Ind.Individual>) -> List<&2, List<&2, F32>>:
  match pop:
    case Nil{}:
      Nil{}
    case ind <> rest:
      Util.vec_norm_div(Ind.objectives(ind), ideal, nadir) <> map_norm(ideal, nadir, rest)

def n_obj_pop(pop: List<&2, Ind.Individual>) -> Nat:
  match pop:
    case Nil{}:
      0n
    case ind <> rest:
      Ind.n_obj(ind)

# ASF on ideal-translated objectives (pymoo __F = F − ideal).
def asf_term(+fj: F32, +ij: F32, on_axis: Bool) -> F32:
  +raw = F32.sub(fj, ij)
  +v = Bool.pick(F32, F32.is_lt(raw, 1.0e-3), 0.0, raw)
  +w = Bool.pick(F32, on_axis, 1.0, 1.0e-6)
  F32.div(v, w)

def asf.go(f: List<&2, F32>, ideal: List<&2, F32>, +axis: Nat, +j: Nat, acc: F32) -> F32:
  match f ideal:
    case Nil{} ys:
      acc
    case xs Nil{}:
      acc
    case x <> xs y <> ys:
      asf.go(xs, ys, axis, 1n+j, F32.max(acc, asf_term(x, y, Nat.is_eq(j, axis))))

def asf(f: List<&2, F32>, +axis: Nat, +ideal: List<&2, F32>) -> F32:
  match f ideal:
    case Nil{} ys:
      0.0
    case xs Nil{}:
      0.0
    case x <> xs y <> ys:
      asf.go(xs, ys, axis, 1n, asf_term(x, y, Nat.is_eq(0n, axis)))

def pick_axis.go(rest: List<&2, List<&2, F32>>, +ideal: List<&2, F32>, +axis: Nat, +best_f: List<&2, F32>, +best_asf: F32) -> List<&2, F32>:
  match rest:
    case Nil{}:
      best_f
    case +f <> fs:
      +a = asf(f, axis, ideal)
      pick_axis.go(
        fs,
        ideal,
        axis,
        Bool.pick(List<&2, F32>, F32.is_lt(a, best_asf), f, best_f),
        Bool.pick(F32, F32.is_lt(a, best_asf), a, best_asf)
      )

def pick_axis(cand: List<&2, List<&2, F32>>, +ideal: List<&2, F32>, +axis: Nat) -> List<&2, F32>:
  match cand:
    case Nil{}:
      Nil{}
    case +h <> t:
      pick_axis.go(t, ideal, axis, h, asf(h, axis, ideal))

def pick_extremes.go(+cand: List<&2, List<&2, F32>>, +ideal: List<&2, F32>, fuel: Nat, +axis: Nat, acc: List<&2, List<&2, F32>>) -> List<&2, List<&2, F32>>:
  match fuel:
    case 0n:
      acc
    case 1n+f:
      pick_extremes.go(
        cand,
        ideal,
        f,
        1n+axis,
        List.append(&2, List<&2, F32>, acc, [pick_axis(cand, ideal, axis)])
      )

def pick_extremes(+cand: List<&2, List<&2, F32>>, +ideal: List<&2, F32>, m: Nat) -> List<&2, List<&2, F32>>:
  pick_extremes.go(cand, ideal, m, 0n, Nil{})

def get_row(+mat: List<&2, List<&2, F32>>, i: Nat) -> List<&2, F32>:
  Maybe.default(&2, List<&2, F32>, List.get(&2, List<&2, F32>, mat, i), Nil{})

def mat_get(+mat: List<&2, List<&2, F32>>, i: Nat, j: Nat) -> F32:
  Util.get_f32(get_row(mat, i), j)

def swap_rows.do(+mat: List<&2, List<&2, F32>>, +i: Nat, +k: Nat) -> List<&2, List<&2, F32>>:
  +ri = get_row(mat, i)
  +rk = get_row(mat, k)
  List.set(&2, List<&2, F32>, List.set(&2, List<&2, F32>, mat, i, rk), k, ri)

def swap_rows.when(+mat: List<&2, List<&2, F32>>, +i: Nat, +k: Nat, same: Bool) -> List<&2, List<&2, F32>>:
  match same:
    case True{}:
      mat
    case False{}:
      swap_rows.do(mat, i, k)

def swap_rows(+mat: List<&2, List<&2, F32>>, +i: Nat, +k: Nat) -> List<&2, List<&2, F32>>:
  swap_rows.when(mat, i, k, Nat.is_eq(i, k))

def scale_vec.go(fuel: Nat, +row: List<&2, F32>, +j: Nat, +div: F32) -> List<&2, F32>:
  match fuel:
    case 0n:
      row
    case 1n+f:
      scale_vec.go(f, Util.set_f32(row, j, F32.div(Util.get_f32(row, j), div)), 1n+j, div)

def scale_row(+mat: List<&2, List<&2, F32>>, +col: Nat, +n: Nat, +div: F32) -> List<&2, List<&2, F32>>:
  List.set(&2, List<&2, F32>, mat, col, scale_vec.go(1n+Nat.sub(n, col), get_row(mat, col), col, div))

def axpy_vec.go(fuel: Nat, +row: List<&2, F32>, +piv: List<&2, F32>, +j: Nat, +factor: F32) -> List<&2, F32>:
  match fuel:
    case 0n:
      row
    case 1n+f:
      +x = Util.get_f32(row, j)
      +p = Util.get_f32(piv, j)
      axpy_vec.go(f, Util.set_f32(row, j, F32.sub(x, F32.mul(factor, p))), piv, 1n+j, factor)

def axpy_row(+mat: List<&2, List<&2, F32>>, +row: Nat, +col: Nat, +n: Nat, +factor: F32, +piv: List<&2, F32>) -> List<&2, List<&2, F32>>:
  List.set(&2, List<&2, F32>, mat, row, axpy_vec.go(1n+Nat.sub(n, col), get_row(mat, row), piv, col, factor))

def find_pivot.go(fuel: Nat, +mat: List<&2, List<&2, F32>>, +col: Nat, +row: Nat, +best_row: Nat, +best: F32) -> Nat:
  match fuel:
    case 0n:
      best_row
    case 1n+f:
      +v = F32.abs(mat_get(mat, row, col))
      find_pivot.go(
        f,
        mat,
        col,
        1n+row,
        Bool.pick(Nat, F32.is_gt(v, best), row, best_row),
        F32.max(v, best)
      )

def find_pivot(+mat: List<&2, List<&2, F32>>, +col: Nat, +n: Nat) -> Nat:
  find_pivot.go(Nat.sub(n, col), mat, col, col, col, F32.abs(mat_get(mat, col, col)))

def elim_one(+row: Nat, +col: Nat, +n: Nat, +piv: List<&2, F32>, +mat: List<&2, List<&2, F32>>, skip: Bool) -> List<&2, List<&2, F32>>:
  match skip:
    case True{}:
      mat
    case False{}:
      axpy_row(mat, row, col, n, mat_get(mat, row, col), piv)

def elim_rows(fuel: Nat, +row: Nat, +col: Nat, +n: Nat, +piv: List<&2, F32>, mat: List<&2, List<&2, F32>>) -> List<&2, List<&2, F32>>:
  match fuel:
    case 0n:
      mat
    case 1n+f:
      elim_rows(f, 1n+row, col, n, piv, elim_one(row, col, n, piv, mat, Nat.is_eq(row, col)))

def ge_step(+col: Nat, +n: Nat, +mat: List<&2, List<&2, F32>>, +pivot: Nat, tiny: Bool) -> Maybe<&2, List<&2, List<&2, F32>>>:
  match tiny:
    case True{}:
      None{}
    case False{}:
      +swapped = swap_rows(mat, col, pivot)
      +div = mat_get(swapped, col, col)
      +scaled = scale_row(swapped, col, n, div)
      Some{elim_rows(n, 0n, col, n, get_row(scaled, col), scaled)}

def ge_col.go(fuel: Nat, +col: Nat, +n: Nat, acc: Maybe<&2, List<&2, List<&2, F32>>>) -> Maybe<&2, List<&2, List<&2, F32>>>:
  match fuel acc:
    case f None{}:
      None{}
    case 0n Some{mat}:
      Some{mat}
    case 1n+f Some{+mat}:
      +pivot = find_pivot(mat, col, n)
      ge_col.go(
        f,
        1n+col,
        n,
        ge_step(col, n, mat, pivot, F32.is_lt(F32.abs(mat_get(mat, pivot, col)), 1.0e-14))
      )

def ge_col(fuel: Nat, +col: Nat, +n: Nat, mat: List<&2, List<&2, F32>>) -> Maybe<&2, List<&2, List<&2, F32>>>:
  ge_col.go(fuel, col, n, Some{mat})

def extract_x.go(fuel: Nat, +mat: List<&2, List<&2, F32>>, +n: Nat, +i: Nat, acc: List<&2, F32>) -> List<&2, F32>:
  match fuel:
    case 0n:
      acc
    case 1n+f:
      extract_x.go(f, mat, n, 1n+i, List.append(&2, F32, acc, [mat_get(mat, i, n)]))

def extract_x(+mat: List<&2, List<&2, F32>>, +n: Nat) -> List<&2, F32>:
  extract_x.go(n, mat, n, 0n, Nil{})

def solve_linear.go(done: Maybe<&2, List<&2, List<&2, F32>>>, +n: Nat) -> Maybe<&2, List<&2, F32>>:
  match done:
    case None{}:
      None{}
    case Some{mat}:
      Some{extract_x(mat, n)}

def build_aug(+ideal: List<&2, F32>, ext: List<&2, List<&2, F32>>) -> List<&2, List<&2, F32>>:
  match ext:
    case Nil{}:
      Nil{}
    case row <> rest:
      List.append(&2, F32, Util.vec_sub(row, ideal), [1.0]) <> build_aug(ideal, rest)

def solve_linear(+ext: List<&2, List<&2, F32>>, +ideal: List<&2, F32>, +n: Nat) -> Maybe<&2, List<&2, F32>>:
  solve_linear.go(ge_col(n, 0n, n, build_aug(ideal, ext)), n)

def intercept_bad(+inv: F32) -> Bool:
  Bool.or(
    F32.is_ne(inv, inv),
    Bool.or(F32.is_le(inv, 1.0e-6), F32.is_ne(F32.mul(inv, 0.0), 0.0))
  )

def inv_ok.fin(+inv: F32, bad: Bool) -> Maybe<&2, F32>:
  match bad:
    case True{}:
      None{}
    case False{}:
      Some{inv}

def inv_ok.pos(+xj: F32, tiny: Bool) -> Maybe<&2, F32>:
  match tiny:
    case True{}:
      None{}
    case False{}:
      +inv = F32.div(1.0, xj)
      inv_ok.fin(inv, intercept_bad(inv))

# C#: |x| < 1e-12 or x < 0 fails; then intercept = 1/x must be finite and > 1e-6.
def inv_ok(+xj: F32) -> Maybe<&2, F32>:
  inv_ok.pos(xj, Bool.or(F32.is_lt(F32.abs(xj), 1.0e-12), F32.is_lt(xj, 0.0)))

def intercepts_from_x.one(h: Maybe<&2, F32>, ys: List<&2, F32>) -> Maybe<&2, List<&2, F32>>:
  match h:
    case None{}:
      None{}
    case Some{inv}:
      Some{inv <> ys}

def intercepts_from_x.cons(+xj: F32, rest: Maybe<&2, List<&2, F32>>) -> Maybe<&2, List<&2, F32>>:
  match rest:
    case None{}:
      None{}
    case Some{ys}:
      intercepts_from_x.one(inv_ok(xj), ys)

def intercepts_from_x(x: List<&2, F32>) -> Maybe<&2, List<&2, F32>>:
  match x:
    case Nil{}:
      Some{Nil{}}
    case xj <> xs:
      intercepts_from_x.cons(xj, intercepts_from_x(xs))

def try_intercepts.go(x: Maybe<&2, List<&2, F32>>) -> Maybe<&2, List<&2, F32>>:
  match x:
    case None{}:
      None{}
    case Some{xs}:
      intercepts_from_x(xs)

def try_intercepts(+ext: List<&2, List<&2, F32>>, +ideal: List<&2, F32>) -> Maybe<&2, List<&2, F32>>:
  try_intercepts.go(solve_linear(ext, ideal, Util.list_len(F32, ideal)))

def add_ideal(ideal: List<&2, F32>, icepts: List<&2, F32>) -> List<&2, F32>:
  match ideal icepts:
    case Nil{} zs:
      Nil{}
    case xs Nil{}:
      Nil{}
    case x <> xs z <> zs:
      F32.add(x, z) <> add_ideal(xs, zs)

def clamp_worst(nadir: List<&2, F32>, worst: List<&2, F32>) -> List<&2, F32>:
  match nadir worst:
    case Nil{} ws:
      Nil{}
    case ns Nil{}:
      ns
    case +n <> ns +w <> ws:
      Bool.pick(F32, F32.is_gt(n, w), w, n) <> clamp_worst(ns, ws)

def nadir_from_maybe(m: Maybe<&2, List<&2, F32>>, +ideal: List<&2, F32>, +worst: List<&2, F32>, +front: List<&2, F32>) -> List<&2, F32>:
  match m:
    case None{}:
      front
    case Some{icepts}:
      clamp_worst(add_ideal(ideal, icepts), worst)

def fallback_pop(nadir: List<&2, F32>, ideal: List<&2, F32>, wpop: List<&2, F32>) -> List<&2, F32>:
  match nadir ideal wpop:
    case Nil{} ils wps:
      Nil{}
    case ns Nil{} wps:
      ns
    case ns ils Nil{}:
      ns
    case +n <> ns +i <> ils +w <> wps:
      Bool.pick(F32, F32.is_le(F32.sub(n, i), 1.0e-6), w, n) <> fallback_pop(ns, ils, wps)

def fallback_unit(nadir: List<&2, F32>, ideal: List<&2, F32>) -> List<&2, F32>:
  match nadir ideal:
    case Nil{} ils:
      Nil{}
    case ns Nil{}:
      ns
    case +n <> ns +i <> ils:
      Bool.pick(F32, F32.is_le(F32.sub(n, i), 1.0e-6), F32.add(i, 1.0), n) <> fallback_unit(ns, ils)

def spans_or_one(nadir: List<&2, F32>, ideal: List<&2, F32>) -> List<&2, F32>:
  match nadir ideal:
    case Nil{} ils:
      Nil{}
    case ns Nil{}:
      Nil{}
    case +n <> ns +i <> ils:
      +span = F32.sub(n, i)
      Bool.pick(F32, F32.is_le(span, 1.0e-12), 1.0, span) <> spans_or_one(ns, ils)

def normalize_nd.body(+ideal0: List<&2, F32>, +worst0: List<&2, F32>, +ext0: List<&2, List<&2, F32>>, +pop: List<&2, Ind.Individual>, nd: List<&2, Nat>) -> State & List<&2, List<&2, F32>>:
  +mn = col_min(pop)
  +mx = col_max(pop)
  +ideal = merge_ideal(ideal0, mn)
  +worst = merge_worst(worst0, mx)
  +nd_use = nd_or_all(nd, Util.list_len(Ind.Individual, pop))
  +front = col_max_idx(pop, nd_use)
  +cand = List.append(&2, List<&2, F32>, ext0, gather_objs(pop, nd_use))
  +m = n_obj_pop(pop)
  +ext = pick_extremes(cand, ideal, m)
  +nadir0 = nadir_from_maybe(try_intercepts(ext, ideal), ideal, worst, front)
  +nadir1 = fallback_pop(nadir0, ideal, mx)
  +nadir = fallback_unit(nadir1, ideal)
  (MkState{m, ideal, worst, nadir, spans_or_one(nadir, ideal), ext}, map_norm(ideal, nadir, pop))

def normalize_nd.go(state: State, +pop: List<&2, Ind.Individual>, nd: List<&2, Nat>) -> State & List<&2, List<&2, F32>>:
  match state:
    case MkState{n_objectives, ideal, worst, nadir, intercepts, extremes}:
      normalize_nd.body(ideal, worst, extremes, pop, nd)

def normalize_nd(state: State, +pop: List<&2, Ind.Individual>, nd: List<&2, Nat>) -> State & List<&2, List<&2, F32>>:
  match pop:
    case Nil{}:
      (state, Nil{})
    case h <> t:
      normalize_nd.go(state, h <> t, nd)

def normalize(state: State, pop: List<&2, Ind.Individual>) -> State & List<&2, List<&2, F32>>:
  normalize_nd(state, pop, Nil{})

def normalize_vecs.snd(pair: State & List<&2, List<&2, F32>>) -> List<&2, List<&2, F32>>:
  (state, vecs) = pair
  vecs

def normalize_vecs(+xs: List<&2, Ind.Individual>) -> List<&2, List<&2, F32>>:
  normalize_vecs.snd(normalize(new_state(n_obj_pop(xs)), xs))
