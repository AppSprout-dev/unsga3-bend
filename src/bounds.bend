# Tiny IProblem bounds stub — variable count + per-var [lo, hi].
# Not ZDT / DTLZ and not Evaluate. Those arrive with the Run PR.

import Base

type Interval is Data:
  MkInterval{
    lo: F32
    hi: F32
  }

type Box is Data:
  MkBox{
    n_obj: Nat
    intervals: List<&2, Interval>
  }

def interval(+lo: F32, +hi: F32) -> Interval:
  MkInterval{lo, hi}

def lo(b: Interval) -> F32:
  match b:
    case MkInterval{lo, hi}:
      lo

def hi(b: Interval) -> F32:
  match b:
    case MkInterval{lo, hi}:
      hi

def box(+n_obj: Nat, intervals: List<&2, Interval>) -> Box:
  MkBox{n_obj, intervals}

def n_obj(b: Box) -> Nat:
  match b:
    case MkBox{n_obj, intervals}:
      n_obj

def intervals_of(b: Box) -> List<&2, Interval>:
  match b:
    case MkBox{n_obj, intervals}:
      intervals

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

# n_var copies of [0, 1]. Smoke / operator tests; not a named problem.
def unit_n(n_var: Nat, n_obj: Nat) -> Box:
  MkBox{n_obj, List.replicate(Interval, n_var, MkInterval{0.0, 1.0})}
