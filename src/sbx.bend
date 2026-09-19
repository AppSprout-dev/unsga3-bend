# Simulated Binary Crossover — C# Unsga3.Operators.Crossover.SimulatedBinaryCrossover.
# Defaults match C#: η = 30, pair probability = 1.0 (Deb & Agrawal).
# Per-variable walk peels x1 / x2 / box intervals together (guide: the
# list is the shape a flat loop walks). Same RNG order as the old
# index + List.get / set_var_at loop; children are built once at the end.

import Base
import ./individual.bend as Ind
import ./bounds.bend as Bounds
import ./rng.bend as Rng
import ./util.bend as Util

type Sbx is Data:
  MkSbx{
    e: F32
    p: F32
  }

def mk(+e: F32, +p: F32) -> Sbx:
  MkSbx{e, p}

def default() -> Sbx:
  MkSbx{30.0, 1.0}

def eta(op: Sbx) -> F32:
  match op:
    case MkSbx{e, p}:
      e

def probability(op: Sbx) -> F32:
  match op:
    case MkSbx{e, p}:
      p

def child1(trip: Rng.State & Ind.Individual & Ind.Individual) -> Ind.Individual:
  (rng, c1, c2) = trip
  c1

def child2(trip: Rng.State & Ind.Individual & Ind.Individual) -> Ind.Individual:
  (rng, c1, c2) = trip
  c2

def near(+x1: F32, +x2: F32) -> Bool:
  F32.is_lt(F32.abs(F32.sub(x1, x2)), 1.0e-14)

# C#: if rand <= 1/alpha then (rand*alpha)^(1/(η+1)) else (1/(2-rand*alpha))^(1/(η+1)).
def beta.pick(+rand: F32, +alpha: F32, +inv: F32, lo: Bool) -> F32:
  match lo:
    case True{}:
      F32.pow(F32.mul(rand, alpha), inv)
    case False{}:
      F32.pow(F32.div(1.0, F32.sub(2.0, F32.mul(rand, alpha))), inv)

def beta(+rand: F32, +alpha: F32, +inv: F32) -> F32:
  beta.pick(rand, alpha, inv, F32.is_le(rand, F32.div(1.0, alpha)))

def close_heads(xs: List<&2, F32>, ys: List<&2, F32>) -> Bool:
  match xs ys:
    case +x <> xr +y <> yr:
      near(x, y)
    case Nil{} ys:
      False{}
    case x <> xs Nil{}:
      False{}

# Draw the next per-var coin only when more variables remain.
def advance(rng: Rng.State, rest: Nat) -> Rng.State:
  match rest:
    case 0n:
      rng
    case 1n+g:
      Rng.next_double(rng)

def finish(+m: Nat, trip: Rng.State & List<&2, F32> & List<&2, F32>) -> Rng.State & Ind.Individual & Ind.Individual:
  (rng, xs, ys) = trip
  (rng, Ind.from_variables(xs, m), Ind.from_variables(ys, m))

def done(rng: Rng.State, acc1: List<&2, F32>, acc2: List<&2, F32>) -> Rng.State & List<&2, F32> & List<&2, F32>:
  (rng, List.reverse(&2, F32, acc1), List.reverse(&2, F32, acc2))

def skip_kind(skip: Bool, close: Bool) -> Nat:
  match skip:
    case True{}:
      0n
    case False{}:
      match close:
        case True{}:
          0n
        case False{}:
          1n

# Kind: 0n = copy heads (skip or close), 1n = SBX the heads.
# One def so skip/cross are not mutually recursive with `loop`.
def loop.go(
  fuel: Nat,
  kind: Nat,
  xs1: List<&2, F32>,
  xs2: List<&2, F32>,
  ivs: List<&2, Bounds.Interval>,
  +eta: F32,
  rng: Rng.State,
  acc1: List<&2, F32>,
  acc2: List<&2, F32>
) -> Rng.State & List<&2, F32> & List<&2, F32>:
  match fuel kind xs1 xs2 ivs:
    case 0n k a b c:
      done(rng, acc1, acc2)
    case 1n++f 0n +x1 <> +rest1 +x2 <> +rest2 +iv <> ivrest:
      +rng2 = advance(rng, f)
      loop.go(
        f,
        skip_kind(F32.is_gt(Rng.last_double(rng2), 0.5), close_heads(rest1, rest2)),
        rest1, rest2, ivrest, eta, rng2, x1 <> acc1, x2 <> acc2
      )
    case 1n++f 1n+p +x1 <> +rest1 +x2 <> +rest2 +iv <> ivrest:
      +lo = Bounds.lo(iv)
      +hi = Bounds.hi(iv)
      +gt = F32.is_gt(x1, x2)
      +a = Bool.pick(F32, gt, x2, x1)
      +b = Bool.pick(F32, gt, x1, x2)
      +delta = F32.sub(b, a)
      +rng_a = Rng.next_double(rng)
      +rand = Rng.last_double(rng_a)
      +inv = F32.div(1.0, F32.add(eta, 1.0))
      +neg = F32.neg(F32.add(eta, 1.0))
      +alpha1 = F32.sub(2.0, F32.pow(F32.add(1.0, F32.div(F32.mul(2.0, F32.sub(a, lo)), delta)), neg))
      +alpha2 = F32.sub(2.0, F32.pow(F32.add(1.0, F32.div(F32.mul(2.0, F32.sub(hi, b)), delta)), neg))
      +c1v = F32.clamp(F32.mul(0.5, F32.sub(F32.add(a, b), F32.mul(beta(rand, alpha1, inv), delta))), lo, hi)
      +c2v = F32.clamp(F32.mul(0.5, F32.add(F32.add(a, b), F32.mul(beta(rand, alpha2, inv), delta))), lo, hi)
      +rng_b = Rng.next_double(rng_a)
      +sw = F32.is_gt(Rng.last_double(rng_b), 0.5)
      +n1 = Bool.pick(F32, sw, c2v, c1v)
      +n2 = Bool.pick(F32, sw, c1v, c2v)
      +rng_c = advance(rng_b, f)
      loop.go(
        f,
        skip_kind(F32.is_gt(Rng.last_double(rng_c), 0.5), close_heads(rest1, rest2)),
        rest1, rest2, ivrest, eta, rng_c, n1 <> acc1, n2 <> acc2
      )
    case 1n++f k Nil{} b c:
      done(rng, acc1, acc2)
    case 1n++f k a <> as Nil{} c:
      done(rng, acc1, acc2)
    case 1n++f k a <> as b <> bs Nil{}:
      done(rng, acc1, acc2)

def loop(
  fuel: Nat,
  skip: Bool,
  close: Bool,
  +eta: F32,
  xs1: List<&2, F32>,
  xs2: List<&2, F32>,
  ivs: List<&2, Bounds.Interval>,
  rng: Rng.State,
  acc1: List<&2, F32>,
  acc2: List<&2, F32>
) -> Rng.State & List<&2, F32> & List<&2, F32>:
  loop.go(fuel, skip_kind(skip, close), xs1, xs2, ivs, eta, rng, acc1, acc2)

def start(
  +eta: F32,
  +x1s: List<&2, F32>,
  +x2s: List<&2, F32>,
  +box: Bounds.Box,
  rng: Rng.State,
  +m: Nat,
  n: Nat
) -> Rng.State & Ind.Individual & Ind.Individual:
  match n:
    case 0n:
      (rng, Ind.from_variables(x1s, m), Ind.from_variables(x2s, m))
    case 1n+f:
      +rng2 = Rng.next_double(rng)
      finish(
        m,
        loop(
          1n+f,
          F32.is_gt(Rng.last_double(rng2), 0.5),
          close_heads(x1s, x2s),
          eta, x1s, x2s, Bounds.intervals_of(box), rng2, Nil{}, Nil{}
        )
      )

def maybe(
  +eta: F32,
  +x1s: List<&2, F32>,
  +x2s: List<&2, F32>,
  +box: Bounds.Box,
  rng: Rng.State,
  +m: Nat,
  +n: Nat,
  skip: Bool
) -> Rng.State & Ind.Individual & Ind.Individual:
  match skip:
    case True{}:
      (rng, Ind.from_variables(x1s, m), Ind.from_variables(x2s, m))
    case False{}:
      start(eta, x1s, x2s, box, rng, m, n)

def draw(
  +eta: F32,
  +prob: F32,
  +x1s: List<&2, F32>,
  +x2s: List<&2, F32>,
  +box: Bounds.Box,
  rng: Rng.State,
  +m: Nat,
  +n: Nat
) -> Rng.State & Ind.Individual & Ind.Individual:
  +rng2 = Rng.next_double(rng)
  maybe(eta, x1s, x2s, box, rng2, m, n, F32.is_gt(Rng.last_double(rng2), prob))

# p=0 copies parents before any NextDouble. Matches C# children when
# pair probability is 0 (every draw is > 0). Bit-zero is definitional
# on the 0.0 literal; F32.is_gt stays off this path.
def draw_or_copy(
  +eta: F32,
  +prob: F32,
  +x1s: List<&2, F32>,
  +x2s: List<&2, F32>,
  +box: Bounds.Box,
  rng: Rng.State,
  +m: Nat,
  +n: Nat,
  zero: Bool
) -> Rng.State & Ind.Individual & Ind.Individual:
  match zero:
    case True{}:
      (rng, Ind.from_variables(x1s, m), Ind.from_variables(x2s, m))
    case False{}:
      draw(eta, prob, x1s, x2s, box, rng, m, n)

def crossover(
  +op: Sbx,
  +p1: Ind.Individual,
  +p2: Ind.Individual,
  +box: Bounds.Box,
  rng: Rng.State
) -> Rng.State & Ind.Individual & Ind.Individual:
  +x1s = Ind.variables(p1)
  +x2s = Ind.variables(p2)
  +m = Bounds.n_obj(box)
  +prob = probability(op)
  draw_or_copy(
    eta(op),
    prob,
    x1s,
    x2s,
    box,
    rng,
    m,
    Bounds.n_var(box),
    Util.f32_is_zero(prob)
  )
