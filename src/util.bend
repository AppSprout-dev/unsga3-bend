# Shared helpers. Parallelize independent list splits; keep these total.
# Population maps use mid-split + `a b = f(lo) f(hi)` (bend guide Parallelism).
# Fuel is |xs| so the Nat shrinks; halves stay observationally ordered.

import Base

def list_len(-A: Data, xs: List<&2, A>) -> Nat:
  List.length(&2, A, xs)

# |take(xs ++ replicate(n, fill), n)| = n. Identity when |xs| = n
# (take never reads the pad). Used to lock Run / select to the law size.
def list_take_pad(-A: Data, +fill: A, xs: List<&2, A>, +n: Nat) -> List<&2, A>:
  List.take(&2, A, List.append(&2, A, xs, List.replicate(A, n, fill)), n)

# IEEE +0.0 is the all-false Word(32). Definitional on the 0.0 literal,
# so p=0 operator laws skip F32.is_gt / F32.is_eq (opaque Base laws).
def word_all_false(n: Nat, w: Word(n)) -> Bool:
  match n:
    case 0n:
      True{}
    case 1n+p:
      match w:
        case WCon{False{}, t}:
          word_all_false(p, t)
        case WCon{True{}, t}:
          False{}

def f32_is_zero(x: F32) -> Bool:
  match x:
    case F32{w}:
      word_all_false(32n, w)

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

def keep_if(-A: Data, +h: A, rest: List<&2, A>, keep: Bool) -> List<&2, A>:
  match keep:
    case True{}:
      h <> rest
    case False{}:
      rest

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

def nats_add(a: List<&2, Nat>, b: List<&2, Nat>) -> List<&2, Nat>:
  match a b:
    case Nil{} Nil{}:
      Nil{}
    case x <> xs y <> ys:
      Nat.add(x, y) <> nats_add(xs, ys)
    case Nil{} ys:
      ys
    case xs Nil{}:
      xs

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

# C# Normalize: denom < 1e-12 → 1.0 (intercept span uses the same floor).
def denom(+lo: F32, +hi: F32) -> F32:
  +span = F32.sub(hi, lo)
  f32_or_one(span, F32.is_lt(span, 1.0e-12))

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

def f32s_eq(a: List<&2, F32>, b: List<&2, F32>) -> Bool:
  match a b:
    case Nil{} Nil{}:
      True{}
    case x <> xs y <> ys:
      Bool.and(F32.is_eq(x, y), f32s_eq(xs, ys))
    case Nil{} y <> ys:
      False{}
    case x <> xs Nil{}:
      False{}

def has_f32s(+needle: List<&2, F32>, xs: List<&2, List<&2, F32>>) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case h <> t:
      Bool.or(f32s_eq(needle, h), has_f32s(needle, t))

# C# Unsga3Algorithm.DecisionKey: double.ToString("G12") — 12 significant
# digits, which on the unit box is 12 decimal places. Round each coord
# to 12 dp before duplicate-key compare. Bend F32 ULP is coarser than
# 1e-12, so this matches C# G12 at the precision this tree has.
def g12_scale() -> F32:
  1000000000000.0

def g12_round_abs(+x: F32) -> F32:
  +s = g12_scale()
  F32.div(F32.round(F32.mul(x, s)), s)

def g12_one.signed(+x: F32, neg: Bool) -> F32:
  match neg:
    case True{}:
      F32.neg(g12_round_abs(F32.neg(x)))
    case False{}:
      g12_round_abs(x)

def g12_one(+x: F32) -> F32:
  g12_one.signed(x, F32.is_lt(x, 0.0))

# Balanced fork-join map. Singleton / empty stay sequential. Fuel 0 is a
# total fallback (public callers pass |xs|). `~f` is a closed top-level.
# Mid take/drop is inlined: a computed pair cannot be matched.
def map_halves.go(
  ~A: Data,
  ~B: Data,
  ~C: Data,
  ~f: @+c:C -> @+x:A -> B,
  +ctx: C,
  +fuel: Nat,
  xs: List<&2, A>
) -> List<&2, B>:
  match fuel xs:
    case 0n Nil{}:
      Nil{}
    case 0n h <> t:
      f(ctx, h) <> map_halves.go(~A, ~B, ~C, ~f, ctx, 0n, t)
    case 1n+p Nil{}:
      Nil{}
    case 1n+p h <> Nil{}:
      f(ctx, h) <> Nil{}
    case 1n+p h <> t:
      +all = {h <> t : List<&2, A>}
      +mid = Nat.div(list_len(A, all), 2n)
      a b = map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.take(&2, A, all, mid)) map_halves.go(~A, ~B, ~C, ~f, ctx, p, List.drop(&2, A, all, mid))
      List.append(&2, B, a, b)

def map_halves(~A: Data, ~B: Data, ~C: Data, ~f: @+c:C -> @+x:A -> B, +ctx: C, +xs: List<&2, A>) -> List<&2, B>:
  map_halves.go(~A, ~B, ~C, ~f, ctx, list_len(A, xs), xs)

# Independent keep/drop. Mid-split; `take ++ drop` matches the old
# tail-first cons_if walk (original relative order).
def filter_halves.go(
  ~A: Data,
  ~C: Data,
  ~p: @+c:C -> @+x:A -> Bool,
  +ctx: C,
  +fuel: Nat,
  xs: List<&2, A>
) -> List<&2, A>:
  match fuel xs:
    case 0n Nil{}:
      Nil{}
    case 0n +h <> t:
      keep_if(A, h, filter_halves.go(~A, ~C, ~p, ctx, 0n, t), p(ctx, h))
    case 1n+p0 Nil{}:
      Nil{}
    case 1n+p0 +h <> Nil{}:
      keep_if(A, h, Nil{}, p(ctx, h))
    case 1n+p0 h <> t:
      +all = {h <> t : List<&2, A>}
      +mid = Nat.div(list_len(A, all), 2n)
      a b = filter_halves.go(~A, ~C, ~p, ctx, p0, List.take(&2, A, all, mid)) filter_halves.go(~A, ~C, ~p, ctx, p0, List.drop(&2, A, all, mid))
      List.append(&2, A, a, b)

def filter_halves(~A: Data, ~C: Data, ~p: @+c:C -> @+x:A -> Bool, +ctx: C, +xs: List<&2, A>) -> List<&2, A>:
  filter_halves.go(~A, ~C, ~p, ctx, list_len(A, xs), xs)

# Sequential cons walk (guide: the list is the shape a flat loop walks).
# n_var is 12–30 on the oracles; mid-split take/drop of that spine is
# more expensive than a tail walk. Same rounding as the old map_halves.
def g12_vec.go(xs: List<&2, F32>, acc: List<&2, F32>) -> List<&2, F32>:
  match xs:
    case Nil{}:
      List.reverse(&2, F32, acc)
    case +x <> rest:
      g12_vec.go(rest, g12_one(x) <> acc)

def g12_vec(xs: List<&2, F32>) -> List<&2, F32>:
  g12_vec.go(xs, Nil{})
