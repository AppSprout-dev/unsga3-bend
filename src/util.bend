# Shared helpers. Parallelize independent list splits; keep these total.

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

def nat_max.fin(+a: Nat, +b: Nat, c: Bool) -> Nat:
  match c:
    case True{}:
      a
    case False{}:
      b

def nat_max(+a: Nat, +b: Nat) -> Nat:
  nat_max.fin(a, b, Nat.is_ge(a, b))

def nat_pow(+b: Nat, e: Nat) -> Nat:
  match e:
    case 0n:
      1n
    case 1n+p:
      Nat.mul(b, nat_pow(b, p))

# C(n, k). Das–Dennis count = C(p + M - 1, M - 1).
def binomial(+n: Nat, +k: Nat) -> Nat:
  match n k:
    case x 0n:
      1n
    case 0n 1n+pk:
      0n
    case 1n+pn 1n+pk:
      Nat.add(binomial(pn, pk), binomial(pn, 1n+pk))

def in_nats(+x: Nat, xs: List<&2, Nat>) -> Bool:
  List.contains(~Nat, ~Nat.is_eq, xs, x)

def minus.put(h: Nat, rest: List<&2, Nat>, drop: Bool) -> List<&2, Nat>:
  match drop:
    case True{}:
      rest
    case False{}:
      h <> rest

def minus(+xs: List<&2, Nat>, +ys: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      minus.put(h, minus(t, ys), in_nats(h, ys))

def get_nat(xs: List<&2, Nat>, i: Nat) -> Nat:
  Maybe.default(&2, Nat, List.get(&2, Nat, xs, i), 0n)

def inc_at(+xs: List<&2, Nat>, +i: Nat) -> List<&2, Nat>:
  List.set(&2, Nat, xs, i, 1n+get_nat(xs, i))

def zeros_nat(n: Nat) -> List<&2, Nat>:
  List.replicate(Nat, n, 0n)

def vec_min(a: List<&2, F32>, b: List<&2, F32>) -> List<&2, F32>:
  match a b:
    case Nil{} Nil{}:
      Nil{}
    case x <> xs y <> ys:
      F32.min(x, y) <> vec_min(xs, ys)
    case Nil{} y <> ys:
      y <> ys
    case x <> xs Nil{}:
      x <> xs

def vec_max(a: List<&2, F32>, b: List<&2, F32>) -> List<&2, F32>:
  match a b:
    case Nil{} Nil{}:
      Nil{}
    case x <> xs y <> ys:
      F32.max(x, y) <> vec_max(xs, ys)
    case Nil{} y <> ys:
      y <> ys
    case x <> xs Nil{}:
      x <> xs

def vec_sub(a: List<&2, F32>, b: List<&2, F32>) -> List<&2, F32>:
  match a b:
    case Nil{} Nil{}:
      Nil{}
    case x <> xs y <> ys:
      F32.sub(x, y) <> vec_sub(xs, ys)
    case Nil{} y <> ys:
      Nil{}
    case x <> xs Nil{}:
      Nil{}

def vec_scale(+s: F32, v: List<&2, F32>) -> List<&2, F32>:
  match v:
    case Nil{}:
      Nil{}
    case x <> xs:
      F32.mul(s, x) <> vec_scale(s, xs)

def vec_dot(a: List<&2, F32>, b: List<&2, F32>) -> F32:
  match a b:
    case Nil{} Nil{}:
      0.0
    case x <> xs y <> ys:
      F32.add(F32.mul(x, y), vec_dot(xs, ys))
    case Nil{} y <> ys:
      0.0
    case x <> xs Nil{}:
      0.0

def vec_sqnorm(+v: List<&2, F32>) -> F32:
  vec_dot(v, v)

def ones_f32(n: Nat) -> List<&2, F32>:
  List.replicate(F32, n, 1.0)

def zeros_f32(n: Nat) -> List<&2, F32>:
  List.replicate(F32, n, 0.0)

def get_f32(xs: List<&2, F32>, i: Nat) -> F32:
  Maybe.default(&2, F32, List.get(&2, F32, xs, i), 0.0)

def set_f32(xs: List<&2, F32>, i: Nat, x: F32) -> List<&2, F32>:
  List.set(&2, F32, xs, i, x)

def f32_or_one(+span: F32, tiny: Bool) -> F32:
  match tiny:
    case True{}:
      1.0
    case False{}:
      span

def denom(+lo: F32, +hi: F32) -> F32:
  +span = F32.sub(hi, lo)
  f32_or_one(span, F32.is_le(span, 0.000001))

def vec_norm_div(f: List<&2, F32>, ideal: List<&2, F32>, nadir: List<&2, F32>) -> List<&2, F32>:
  match f ideal nadir:
    case Nil{} los his:
      Nil{}
    case x <> xs +lo <> los +hi <> his:
      F32.div(F32.sub(x, lo), denom(lo, hi)) <> vec_norm_div(xs, los, his)
    case x <> xs Nil{} his:
      Nil{}
    case x <> xs lo <> los Nil{}:
      Nil{}

def csv_step(x: F32, acc: String) -> String:
  match acc:
    case SNil{}:
      F32.show(x)
    case SCon{h, t}:
      F32.show(x) ++ "," ++ SCon{h, t}

def show_f32s(xs: List<&2, F32>) -> String:
  List.foldr(~&2, ~F32, ~String, ~csv_step, xs, "")
