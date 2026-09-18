# Shared discrete helpers for v0 laws (lengths, min, binomial).
# Parallelize list folds when they become hot; keep these total.

import Base

def list_len(-A: Data, xs: List<&2, A>) -> Nat:
  List.length(&2, A, xs)

def nat_min.fin(+a: Nat, +b: Nat, c: Bool) -> Nat:
  match c:
    case True{}:
      a
    case False{}:
      b

def nat_min(+a: Nat, +b: Nat) -> Nat:
  nat_min.fin(a, b, Nat.is_le(a, b))

# C(n, k). Used by Das–Dennis count = C(p + M - 1, M - 1).
def binomial(+n: Nat, +k: Nat) -> Nat:
  match n k:
    case x 0n:
      1n
    case 0n 1n+pk:
      0n
    case 1n+pn 1n+pk:
      Nat.add(binomial(pn, pk), binomial(pn, 1n+pk))
