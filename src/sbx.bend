# Simulated Binary Crossover — C# Unsga3.Operators.Crossover.SimulatedBinaryCrossover.
# Defaults match C#: η = 30, pair probability = 1.0 (Deb & Agrawal).

import Base
import ./individual.bend as Ind
import ./bounds.bend as Bounds
import ./rng.bend as Rng
import ./util.bend as Util

type Sbx is Data:
  MkSbx{
    eta: F32
    probability: F32
  }

def mk(+eta: F32, +probability: F32) -> Sbx:
  MkSbx{eta, probability}

def default() -> Sbx:
  MkSbx{30.0, 1.0}

def eta(op: Sbx) -> F32:
  match op:
    case MkSbx{eta, probability}:
      eta

def probability(op: Sbx) -> F32:
  match op:
    case MkSbx{eta, probability}:
      probability

def child1(trip: Rng.State & Ind.Individual & Ind.Individual) -> Ind.Individual:
  (rng, c1, c2) = trip
  c1

def child2(trip: Rng.State & Ind.Individual & Ind.Individual) -> Ind.Individual:
  (rng, c1, c2) = trip
  c2

def near(+x1: F32, +x2: F32) -> Bool:
  F32.is_lt(F32.abs(F32.sub(x1, x2)), 1.0e-14)

def order.fin(+x1: F32, +x2: F32, gt: Bool) -> F32 & F32:
  match gt:
    case True{}:
      (x2, x1)
    case False{}:
      (x1, x2)

def order(+x1: F32, +x2: F32) -> F32 & F32:
  order.fin(x1, x2, F32.is_gt(x1, x2))

# C#: if rand <= 1/alpha then (rand*alpha)^(1/(η+1)) else (1/(2-rand*alpha))^(1/(η+1)).
def beta.pick(+rand: F32, +alpha: F32, +inv: F32, lo: Bool) -> F32:
  match lo:
    case True{}:
      F32.pow(F32.mul(rand, alpha), inv)
    case False{}:
      F32.pow(F32.div(1.0, F32.sub(2.0, F32.mul(rand, alpha))), inv)

def beta(+rand: F32, +alpha: F32, +inv: F32) -> F32:
  beta.pick(rand, alpha, inv, F32.is_le(rand, F32.div(1.0, alpha)))

def assign.fin(+c1: Ind.Individual, +c2: Ind.Individual, +i: Nat, +v1: F32, +v2: F32, swap: Bool) -> Ind.Individual & Ind.Individual:
  match swap:
    case True{}:
      (Ind.set_var_at(c1, i, v2), Ind.set_var_at(c2, i, v1))
    case False{}:
      (Ind.set_var_at(c1, i, v1), Ind.set_var_at(c2, i, v2))

def assign(+c1: Ind.Individual, +c2: Ind.Individual, +i: Nat, +v1: F32, +v2: F32, swap: Bool) -> Ind.Individual & Ind.Individual:
  assign.fin(c1, c2, i, v1, v2, swap)

# One variable. Does not recurse — `loop` is the only recursive def.
def apply(
  +eta: F32,
  +box: Bounds.Box,
  rng: Rng.State,
  c1: Ind.Individual,
  c2: Ind.Individual,
  +i: Nat,
  +x1: F32,
  +x2: F32
) -> Rng.State & Ind.Individual & Ind.Individual:
  +iv = Bounds.at(box, i)
  +lo = Bounds.lo(iv)
  +hi = Bounds.hi(iv)
  (a0, b0) = order(x1, x2)
  +a = a0
  +b = b0
  +delta = F32.sub(b, a)
  (rng2, +rand) = Rng.next_double(rng)
  +inv = F32.div(1.0, F32.add(eta, 1.0))
  +neg = F32.neg(F32.add(eta, 1.0))
  +alpha1 = F32.sub(2.0, F32.pow(F32.add(1.0, F32.div(F32.mul(2.0, F32.sub(a, lo)), delta)), neg))
  +alpha2 = F32.sub(2.0, F32.pow(F32.add(1.0, F32.div(F32.mul(2.0, F32.sub(hi, b)), delta)), neg))
  +c1v = F32.clamp(F32.mul(0.5, F32.sub(F32.add(a, b), F32.mul(beta(rand, alpha1, inv), delta))), lo, hi)
  +c2v = F32.clamp(F32.mul(0.5, F32.add(F32.add(a, b), F32.mul(beta(rand, alpha2, inv), delta))), lo, hi)
  (rng3, sw) = Rng.next_double(rng2)
  (n1, n2) = assign(c1, c2, i, c1v, c2v, F32.is_gt(sw, 0.5))
  (rng3, n1, n2)

def close_or_apply(
  +eta: F32,
  +x1s: List<&2, F32>,
  +x2s: List<&2, F32>,
  +box: Bounds.Box,
  rng: Rng.State,
  c1: Ind.Individual,
  c2: Ind.Individual,
  +i: Nat,
  close: Bool
) -> Rng.State & Ind.Individual & Ind.Individual:
  match close:
    case True{}:
      (rng, c1, c2)
    case False{}:
      apply(eta, box, rng, c1, c2, i, Util.get_f32(x1s, i), Util.get_f32(x2s, i))

def after_coin(
  +eta: F32,
  +x1s: List<&2, F32>,
  +x2s: List<&2, F32>,
  +box: Bounds.Box,
  rng: Rng.State,
  c1: Ind.Individual,
  c2: Ind.Individual,
  +i: Nat,
  skip: Bool
) -> Rng.State & Ind.Individual & Ind.Individual:
  match skip:
    case True{}:
      (rng, c1, c2)
    case False{}:
      +x1 = Util.get_f32(x1s, i)
      +x2 = Util.get_f32(x2s, i)
      close_or_apply(eta, x1s, x2s, box, rng, c1, c2, i, near(x1, x2))

def loop(
  +eta: F32,
  +x1s: List<&2, F32>,
  +x2s: List<&2, F32>,
  +box: Bounds.Box,
  rng: Rng.State,
  c1: Ind.Individual,
  c2: Ind.Individual,
  fuel: Nat,
  +i: Nat
) -> Rng.State & Ind.Individual & Ind.Individual:
  match fuel:
    case 0n:
      (rng, c1, c2)
    case 1n+f:
      (rng2, u) = Rng.next_double(rng)
      (rng3, n1, n2) = after_coin(eta, x1s, x2s, box, rng2, c1, c2, i, F32.is_gt(u, 0.5))
      loop(eta, x1s, x2s, box, rng3, n1, n2, f, 1n+i)

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
      loop(eta, x1s, x2s, box, rng, c1, c2, n, 0n)

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
  (rng2, u) = Rng.next_double(rng)
  maybe(eta, x1s, x2s, box, rng2, c1, c2, n, F32.is_gt(u, prob))

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
