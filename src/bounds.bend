# IProblem box — variable count + per-var [lo, hi].
# Named problems (ZDT1 / ZDT2 / DTLZ2) live in problems.bend.

import Base

type Interval is Data:
  MkInterval{
    low: F32
    high: F32
  }

type Box is Data:
  MkBox{
    m: Nat
    ivs: List<&2, Interval>
  }

def interval(+low: F32, +high: F32) -> Interval:
  MkInterval{low, high}

def lo(b: Interval) -> F32:
  match b:
    case MkInterval{low, high}:
      low

def hi(b: Interval) -> F32:
  match b:
    case MkInterval{low, high}:
      high

def box(+m: Nat, ivs: List<&2, Interval>) -> Box:
  MkBox{m, ivs}

def n_obj(b: Box) -> Nat:
  match b:
    case MkBox{m, ivs}:
      m

def intervals_of(b: Box) -> List<&2, Interval>:
  match b:
    case MkBox{m, ivs}:
      ivs

def n_var(b: Box) -> Nat:
  List.length(&2, Interval, intervals_of(b))

def at.go(m: Maybe<&2, Interval>) -> Interval:
  match m:
    case None{}:
      MkInterval{0.0, 1.0}
    case Some{iv}:
      iv

def at(b: Box, i: Nat) -> Interval:
  at.go(List.get(&2, Interval, intervals_of(b), i))

# nv copies of [0, 1]. Smoke / operator tests; not a named problem.
def unit_n(nv: Nat, nm: Nat) -> Box:
  MkBox{nm, List.replicate(Interval, nv, MkInterval{0.0, 1.0})}
