# ReferenceDirections — C# Unsga3.Utilities.ReferenceDirections.
# Das–Dennis structured points on the unit simplex.
# Count = C(p + M - 1, M - 1); M == 1n → 1n. Points match C# recurse order
# (first coordinate increases 0..p, DFS).

import Base
import ./util.bend as Util

def binomial(+n: Nat, +k: Nat) -> Nat:
  Util.binomial(n, k)

def count.succ(+rest: Nat, +partitions: Nat, z: Bool) -> Nat:
  match z:
    case True{}:
      1n
    case False{}:
      Util.binomial(Nat.add(partitions, rest), rest)

def count.go(+rest: Nat, +partitions: Nat) -> Nat:
  count.succ(rest, partitions, Nat.is_eq(rest, 0n))

# Number of Das–Dennis points. M == 0n is a guard (0). M == 1n → 1.
# M == 1n+rest → if rest == 0 then 1 else C(p + rest, rest) = C(p + M - 1, M - 1).
def count(number_of_objectives: Nat, partitions: Nat) -> Nat:
  match number_of_objectives:
    case 0n:
      0n
    case 1n+rest:
      count.go(rest, partitions)

type Job is Data:
  Job{
    dims: Nat
    left: Nat
    prefix: List<&2, Nat>
  }

def snoc(+prefix: List<&2, Nat>, i: Nat) -> List<&2, Nat>:
  List.append(&2, Nat, prefix, [i])

def to_dir(+p: Nat, comps: List<&2, Nat>) -> List<&2, F32>:
  match comps:
    case Nil{}:
      Nil{}
    case i <> rest:
      F32.div(F32.from_nat(i), F32.from_nat(p)) <> to_dir(p, rest)

def to_dirs(+p: Nat, rows: List<&2, List<&2, Nat>>) -> List<&2, List<&2, F32>>:
  match rows:
    case Nil{}:
      Nil{}
    case row <> rest:
      to_dir(p, row) <> to_dirs(p, rest)

# i runs 0..left inclusive. Acc is reversed so i=0 is first (C# order).
def expand(+rd: Nat, +left: Nat, +prefix: List<&2, Nat>, fuel: Nat, +i: Nat, acc: List<&2, Job>) -> List<&2, Job>:
  match fuel:
    case 0n:
      List.reverse(&2, Job, acc)
    case 1n+f:
      expand(rd, left, prefix, f, 1n+i, Job{rd, Nat.sub(left, i), snoc(prefix, i)} <> acc)

def das_step(+p: Nat, fuel: Nat, +jobs: List<&2, Job>, acc: List<&2, List<&2, Nat>>) -> List<&2, List<&2, Nat>>:
  match fuel jobs:
    case f Nil{}:
      List.reverse(&2, List<&2, Nat>, acc)
    case 0n js:
      List.reverse(&2, List<&2, Nat>, acc)
    case 1n+f Job{dims, left, prefix} <> rest:
      match dims:
        case 0n:
          das_step(p, f, rest, acc)
        case 1n:
          das_step(p, f, rest, snoc(prefix, left) <> acc)
        case 1n+rd:
          das_step(p, f, List.append(&2, Job, expand(rd, left, prefix, 1n+left, 0n, Nil{}), rest), acc)

def das_go(+p: Nat, m: Nat, jobs: List<&2, Job>) -> List<&2, List<&2, F32>>:
  to_dirs(p, das_step(p, Util.nat_pow(1n+p, 1n+m), jobs, Nil{}))

def das_dennis.from(+m: Nat, +p: Nat, rest: Nat) -> List<&2, List<&2, F32>>:
  match rest:
    case 0n:
      [[1.0]]
    case 1n+q:
      das_go(p, m, [Job{m, p, Nil{}}])

def das_dennis.p0(rest: Nat) -> List<&2, List<&2, F32>>:
  match rest:
    case 0n:
      [[1.0]]
    case 1n+q:
      Nil{}

# Generate directions. M == 1n → [[1.0]]. M == 0n → Nil{}. p == 0n → Nil{} when M > 1.
def das_dennis(number_of_objectives: Nat, partitions: Nat) -> List<&2, List<&2, F32>>:
  match number_of_objectives partitions:
    case 0n p:
      Nil{}
    case 1n+rest 0n:
      das_dennis.p0(rest)
    case +m 1n+q:
      das_dennis.from(m, 1n+q, Nat.sub(m, 1n))
