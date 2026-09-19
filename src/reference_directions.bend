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

# k-th composition of `p` into `m` parts, C# DFS order (first coord
# increases 0..p). Enumerating `range(Count)` makes |DasDennis| = Count
# by construction. @unsafe: Bool dispatch on `k < count(rest)` then
# either shrinks M or advances i; fuel is a bound, not the shrink key.
type DasCtx is Data:
  DasCtx{
    m: Nat
    p: Nat
  }

def nth_comp.fallback(m: Nat, p: Nat) -> List<&2, Nat>:
  match m:
    case 0n:
      Nil{}
    case 1n:
      [p]
    case 1n+rd:
      0n <> nth_comp.fallback(rd, p)

@unsafe def nth_comp.go(
  ready: Bool,
  take: Bool,
  fuel: Nat,
  +m: Nat,
  +p: Nat,
  +k: Nat,
  +i: Nat,
  left: Nat,
  c: Nat
) -> List<&2, Nat>:
  match ready take fuel:
    case True{} True{} f:
      i <> nth_comp.go(False{}, False{}, f, m, left, k, 0n, 0n, 0n)
    case True{} False{} f:
      nth_comp.go(False{}, False{}, f, 1n+m, p, Nat.sub(k, c), 1n+i, 0n, 0n)
    case False{} t 0n:
      nth_comp.fallback(m, p)
    case False{} t 1n+f:
      match m:
        case 0n:
          Nil{}
        case 1n:
          [p]
        case 1n+rd:
          +left2 = Nat.sub(p, i)
          +c2 = count(rd, left2)
          nth_comp.go(True{}, Nat.is_lt(k, c2), f, rd, p, k, i, left2, c2)

def nth_comp(+m: Nat, +p: Nat, +k: Nat) -> List<&2, Nat>:
  nth_comp.go(False{}, False{}, Nat.mul(Nat.add(p, 1n), Nat.add(m, 1n)), m, p, k, 0n, 0n, 0n)

def nth_row(+ctx: DasCtx, +k: Nat) -> List<&2, Nat>:
  match ctx:
    case DasCtx{+m, +p}:
      nth_comp(m, p, k)

def comps_all(+m: Nat, +p: Nat) -> List<&2, List<&2, Nat>>:
  Util.map_halves(~Nat, ~List<&2, Nat>, ~DasCtx, ~nth_row, DasCtx{m, p}, List.range(count(m, p)))

def das_dennis.from(+m: Nat, +p: Nat, rest: Nat) -> List<&2, List<&2, F32>>:
  match rest:
    case 0n:
      [[1.0]]
    case 1n+q:
      to_dirs(p, comps_all(m, p))

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
