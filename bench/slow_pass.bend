# Negative control for the scaling gate. Not part of Unsga3Algorithm.Run
# and not imported by src/lib.bend.
#
# Extra work on a finished population:
#   outer `rows` is not a tail call (the recursive result is an argument
#   of F32.add), so it keeps one frame per individual;
#   each frame walks every index, and each index calls List.get `weight`
#   times. List.get walks the cons spine from the head.
# That is O(weight · N³) cell visits on top of Run, paid once (not once
# per generation). `weight` comes from the driver (`burn=`). The checksum
# is returned so the walk stays live. One weighted pass keeps the fixed
# call overhead off the cubic term; repeating a tiny pass would add a
# flat cost and hide the exponent.

import Base
import ../src/individual.bend as Ind
import ../src/util.bend as Util

def obj0(ind: Ind.Individual) -> F32:
  Maybe.default(&2, F32, List.get(&2, F32, Ind.objectives(ind), 0n), 0.0)

def at(+pop: List<&2, Ind.Individual>, i: Nat) -> Ind.Individual:
  Maybe.default(
    &2,
    Ind.Individual,
    List.get(&2, Ind.Individual, pop, i),
    Ind.from_objectives(Nil{})
  )

# `weight` List.get walks of one index. Tail call, so depth stays 1.
def touch(+pop: List<&2, Ind.Individual>, +i: Nat, fuel: Nat, acc: F32) -> F32:
  match fuel:
    case 0n:
      acc
    case 1n+f:
      touch(pop, i, f, F32.add(acc, obj0(at(pop, i))))

# Tail loop over indexes. Each index pays `weight` spine walks.
def row.go(+pop: List<&2, Ind.Individual>, +weight: Nat, fuel: Nat, acc: F32) -> F32:
  match fuel:
    case 0n:
      acc
    case 1n++f:
      row.go(pop, weight, f, touch(pop, f, weight, acc))

# Not tail: F32.add waits on the recursive rows. Depth = N.
def rows(+pop: List<&2, Ind.Individual>, +n: Nat, +weight: Nat, fuel: Nat) -> F32:
  match fuel:
    case 0n:
      0.0
    case 1n+f:
      F32.add(row.go(pop, weight, n, 0.0), rows(pop, n, weight, f))

def burn(+pop: List<&2, Ind.Individual>, weight: Nat) -> F32:
  +n = Util.list_len(Ind.Individual, pop)
  rows(pop, n, weight, n)
