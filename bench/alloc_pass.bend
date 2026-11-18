# Allocation control. Not on the Run path and not imported by src/lib.bend.
#
# A tail-built cons list of F32. Peak RSS is the caller's problem: the list
# is retained until the length is read. Linear mode asks for `per * n`
# cells. Quadratic mode asks for `n * n` cells.

import Base

def conses(fuel: Nat, acc: List<&2, F32>) -> List<&2, F32>:
  match fuel:
    case 0n:
      acc
    case 1n+f:
      conses(f, 1.0 <> acc)

def alloc(n: Nat) -> Nat:
  List.length(&2, F32, conses(n, Nil{}))
