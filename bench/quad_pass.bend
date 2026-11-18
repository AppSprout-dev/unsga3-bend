# O(N²) time control. Not on the Run path and not imported by src/lib.bend.
#
# Nested fuel: outer N steps, each doing N additions. Both loops are tail
# calls, so this is arithmetic work, not a cons-list walk (List.get would
# turn the inner step into O(N) and the whole pass into O(N³)).

import Base

def inner(fuel: Nat, acc: F32) -> F32:
  match fuel:
    case 0n:
      acc
    case 1n+f:
      inner(f, F32.add(acc, 1.0))

def outer(+n: Nat, fuel: Nat, acc: F32) -> F32:
  match fuel:
    case 0n:
      acc
    case 1n++f:
      outer(n, f, inner(n, acc))

def repeat(+n: Nat, fuel: Nat, acc: F32) -> F32:
  match fuel:
    case 0n:
      acc
    case 1n++f:
      repeat(n, f, outer(n, n, acc))

def burn(+n: Nat, reps: Nat) -> F32:
  repeat(n, reps, 0.0)
