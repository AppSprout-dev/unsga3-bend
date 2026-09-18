# Normalization — C# Unsga3.Core.Normalization (v0).
# Persistent ideal = componentwise min. Nadir = max of the ND index set
# when supplied, else max of the population; degenerate span → 1
# (C# intercept fallback). ASF hyperplane intercepts are pass-2 polish.

import Base
import ./individual.bend as Ind
import ./util.bend as Util

type State is Data:
  MkState{
    n_objectives: Nat
    ideal: List<&2, F32>
    nadir: List<&2, F32>
    intercepts: List<&2, F32>
  }

def new_state(n_objectives: Nat) -> State:
  MkState{n_objectives, Nil{}, Nil{}, Nil{}}

def state_n(st: State) -> Nat:
  match st:
    case MkState{n_objectives, ideal, nadir, intercepts}:
      n_objectives

def state_ideal(st: State) -> List<&2, F32>:
  match st:
    case MkState{n_objectives, ideal, nadir, intercepts}:
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

def merge_nadir.fresh(front: List<&2, F32>, popm: List<&2, F32>) -> List<&2, F32>:
  match front:
    case Nil{}:
      popm
    case x <> xs:
      x <> xs

def merge_nadir(+prev: List<&2, F32>, +front: List<&2, F32>, +popm: List<&2, F32>) -> List<&2, F32>:
  match prev:
    case Nil{}:
      merge_nadir.fresh(front, popm)
    case x <> xs:
      Util.vec_max(x <> xs, front)

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

def normalize_nd.go(state: State, +pop: List<&2, Ind.Individual>, nd: List<&2, Nat>) -> State & List<&2, List<&2, F32>>:
  +mn = col_min(pop)
  +mx = col_max(pop)
  +fr = col_max_idx(pop, nd)
  +ideal = merge_ideal(state_ideal(state), mn)
  +nadir = merge_nadir(Nil{}, fr, mx)
  +n = n_obj_pop(pop)
  (MkState{n, ideal, nadir, Util.vec_sub(nadir, ideal)}, map_norm(ideal, nadir, pop))

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
