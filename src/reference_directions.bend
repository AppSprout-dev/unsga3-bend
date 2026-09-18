# ReferenceDirections — C# Unsga3.Utilities.ReferenceDirections.
# Das–Dennis structured points on the unit simplex.
# Count is implemented: C(p + M - 1, M - 1), with M == 1n → 1n.
# Point generation for M > 1 is TODO(v0).

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

def das_dennis.succ(rest: Nat) -> List<&2, List<&2, F32>>:
  match rest:
    case 0n:
      [[1.0]]
    case 1n+m:
      Nil{}

# Generate directions. M == 1n → [[1.0]]. M > 1 is TODO(v0).
def das_dennis(number_of_objectives: Nat, partitions: Nat) -> List<&2, List<&2, F32>>:
  match number_of_objectives:
    case 0n:
      Nil{}
    case 1n+rest:
      das_dennis.succ(rest)
