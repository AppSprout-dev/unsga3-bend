# Simulated Binary Crossover — C# Unsga3.Operators.Crossover.SimulatedBinaryCrossover.
# Defaults match C#: η = 30, pair probability = 1.0 (Deb & Agrawal).

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

def close_at(+xs: List<&2, F32>, +ys: List<&2, F32>, +i: Nat) -> Bool:
  near(Util.get_f32(xs, i), Util.get_f32(ys, i))

# Draw the next per-var coin only when more variables remain.
def advance(rng: Rng.State, rest: Nat) -> Rng.State:
  match rest:
    case 0n:
      rng
    case 1n+g:
      Rng.next_double(rng)

# fuel is remaining variables including the current index `i`.
# skip = last per-var coin > 0.5. close = |x1-x2| < 1e-14 at `i`.
def loop(
  fuel: Nat,
  +i: Nat,
  skip: Bool,
  close: Bool,
  +eta: F32,
  +x1s: List<&2, F32>,
  +x2s: List<&2, F32>,
  +box: Bounds.Box,
  rng: Rng.State,
  c1: Ind.Individual,
  c2: Ind.Individual
) -> Rng.State & Ind.Individual & Ind.Individual:
  match fuel skip close:
    case 0n s c:
      (rng, c1, c2)
    case 1n++f True{} c:
      +rng2 = advance(rng, f)
      loop(
        f, 1n+i,
        F32.is_gt(Rng.last_double(rng2), 0.5),
        close_at(x1s, x2s, 1n+i),
        eta, x1s, x2s, box, rng2, c1, c2
      )
    case 1n++f False{} True{}:
      +rng2 = advance(rng, f)
      loop(
        f, 1n+i,
        F32.is_gt(Rng.last_double(rng2), 0.5),
        close_at(x1s, x2s, 1n+i),
        eta, x1s, x2s, box, rng2, c1, c2
      )
    case 1n++f False{} False{}:
      +iv = Bounds.at(box, i)
      +lo = Bounds.lo(iv)
      +hi = Bounds.hi(iv)
      +x1 = Util.get_f32(x1s, i)
      +x2 = Util.get_f32(x2s, i)
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
      +n1 = Ind.set_var_at(c1, i, Bool.pick(F32, sw, c2v, c1v))
      +n2 = Ind.set_var_at(c2, i, Bool.pick(F32, sw, c1v, c2v))
      +rng_c = advance(rng_b, f)
      loop(
        f, 1n+i,
        F32.is_gt(Rng.last_double(rng_c), 0.5),
        close_at(x1s, x2s, 1n+i),
        eta, x1s, x2s, box, rng_c, n1, n2
      )

def start(
  +eta: F32,
  +x1s: List<&2, F32>,
  +x2s: List<&2, F32>,
  +box: Bounds.Box,
  rng: Rng.State,
  c1: Ind.Individual,
  c2: Ind.Individual,
  n: Nat
) -> Rng.State & Ind.Individual & Ind.Individual:
  match n:
    case 0n:
      (rng, c1, c2)
    case 1n+f:
      +rng2 = Rng.next_double(rng)
      loop(
        1n+f, 0n,
        F32.is_gt(Rng.last_double(rng2), 0.5),
        close_at(x1s, x2s, 0n),
        eta, x1s, x2s, box, rng2, c1, c2
      )

def maybe(
  +eta: F32,
  +x1s: List<&2, F32>,
  +x2s: List<&2, F32>,
  +box: Bounds.Box,
  rng: Rng.State,
  c1: Ind.Individual,
  c2: Ind.Individual,
  +n: Nat,
  skip: Bool
) -> Rng.State & Ind.Individual & Ind.Individual:
  match skip:
    case True{}:
      (rng, c1, c2)
    case False{}:
      start(eta, x1s, x2s, box, rng, c1, c2, n)

def draw(
  +eta: F32,
  +prob: F32,
  +x1s: List<&2, F32>,
  +x2s: List<&2, F32>,
  +box: Bounds.Box,
  rng: Rng.State,
  c1: Ind.Individual,
  c2: Ind.Individual,
  +n: Nat
) -> Rng.State & Ind.Individual & Ind.Individual:
  +rng2 = Rng.next_double(rng)
  maybe(eta, x1s, x2s, box, rng2, c1, c2, n, F32.is_gt(Rng.last_double(rng2), prob))

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
  draw(
    eta(op),
    probability(op),
    x1s,
    x2s,
    box,
    rng,
    Ind.from_variables(x1s, m),
    Ind.from_variables(x2s, m),
    Bounds.n_var(box)
  )
