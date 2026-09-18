# Polynomial mutation — C# Unsga3.Operators.Mutation.PolynomialMutation.
# Default η = 20. Probability per variable is an argument (C# Run uses 1/n).

import Base
import ./individual.bend as Ind
import ./bounds.bend as Bounds
import ./rng.bend as Rng

type Poly is Data:
  MkPoly{
    e: F32
  }

def mk(+e: F32) -> Poly:
  MkPoly{e}

def default() -> Poly:
  MkPoly{20.0}

def eta(op: Poly) -> F32:
  match op:
    case MkPoly{e}:
      e

# C# Unsga3Algorithm: mutationProbability ?? (1.0 / nVars) at the call site.
def typical_probability(n_var: Nat) -> F32:
  match n_var:
    case 0n:
      1.0
    case 1n+p:
      F32.div(1.0, F32.from_nat(1n+p))

def result(pair: Rng.State & Ind.Individual) -> Ind.Individual:
  (rng, ind) = pair
  ind

def deltaq.lo(+eta: F32, +mut_pow: F32, +delta1: F32, +rand: F32) -> F32:
  +xy = F32.sub(1.0, delta1)
  +val = F32.add(
    F32.mul(2.0, rand),
    F32.mul(F32.sub(1.0, F32.mul(2.0, rand)), F32.pow(xy, F32.add(eta, 1.0)))
  )
  F32.sub(F32.pow(val, mut_pow), 1.0)

def deltaq.hi(+eta: F32, +mut_pow: F32, +delta2: F32, +rand: F32) -> F32:
  +xy = F32.sub(1.0, delta2)
  +val = F32.add(
    F32.mul(2.0, F32.sub(1.0, rand)),
    F32.mul(F32.mul(2.0, F32.sub(rand, 0.5)), F32.pow(xy, F32.add(eta, 1.0)))
  )
  F32.sub(1.0, F32.pow(val, mut_pow))

def deltaq.pick(+eta: F32, +mut_pow: F32, +delta1: F32, +delta2: F32, +rand: F32, lo_side: Bool) -> F32:
  match lo_side:
    case True{}:
      deltaq.lo(eta, mut_pow, delta1, rand)
    case False{}:
      deltaq.hi(eta, mut_pow, delta2, rand)

def deltaq(+eta: F32, +mut_pow: F32, +delta1: F32, +delta2: F32, +rand: F32) -> F32:
  deltaq.pick(eta, mut_pow, delta1, delta2, rand, F32.is_lt(rand, 0.5))

def span_at(+box: Bounds.Box, i: Nat) -> F32:
  +iv = Bounds.at(box, i)
  F32.sub(Bounds.hi(iv), Bounds.lo(iv))

def tiny_at(+box: Bounds.Box, i: Nat) -> Bool:
  F32.is_lt(span_at(box, i), 1.0e-14)

def advance(rng: Rng.State, rest: Nat) -> Rng.State:
  match rest:
    case 0n:
      rng
    case 1n+g:
      Rng.next_double(rng)

# fuel is remaining variables including `i`.
# skip = last per-var coin > p. tiny = (hi-lo) < 1e-14 at `i`.
def loop(
  fuel: Nat,
  +i: Nat,
  skip: Bool,
  tiny: Bool,
  +eta: F32,
  +box: Bounds.Box,
  rng: Rng.State,
  +ind: Ind.Individual,
  +p: F32
) -> Rng.State & Ind.Individual:
  match fuel skip tiny:
    case 0n s t:
      (rng, ind)
    case 1n++f True{} t:
      +rng2 = advance(rng, f)
      loop(
        f, 1n+i,
        F32.is_gt(Rng.last_double(rng2), p),
        tiny_at(box, 1n+i),
        eta, box, rng2, ind, p
      )
    case 1n++f False{} True{}:
      +rng2 = advance(rng, f)
      loop(
        f, 1n+i,
        F32.is_gt(Rng.last_double(rng2), p),
        tiny_at(box, 1n+i),
        eta, box, rng2, ind, p
      )
    case 1n++f False{} False{}:
      +iv = Bounds.at(box, i)
      +lo = Bounds.lo(iv)
      +hi = Bounds.hi(iv)
      +x = Ind.var_at(ind, i)
      +dmax = F32.sub(hi, lo)
      +rng_a = Rng.next_double(rng)
      +rand = Rng.last_double(rng_a)
      +mut_pow = F32.div(1.0, F32.add(eta, 1.0))
      +dq = deltaq(eta, mut_pow, F32.div(F32.sub(x, lo), dmax), F32.div(F32.sub(hi, x), dmax), rand)
      +y = F32.clamp(F32.add(x, F32.mul(dq, dmax)), lo, hi)
      +nind = Ind.set_evaluated(Ind.set_var_at(ind, i, y), False{})
      +rng_b = advance(rng_a, f)
      loop(
        f, 1n+i,
        F32.is_gt(Rng.last_double(rng_b), p),
        tiny_at(box, 1n+i),
        eta, box, rng_b, nind, p
      )

def start(
  +eta: F32,
  +box: Bounds.Box,
  rng: Rng.State,
  ind: Ind.Individual,
  +p: F32,
  n: Nat
) -> Rng.State & Ind.Individual:
  match n:
    case 0n:
      (rng, ind)
    case 1n+f:
      +rng2 = Rng.next_double(rng)
      loop(
        1n+f, 0n,
        F32.is_gt(Rng.last_double(rng2), p),
        tiny_at(box, 0n),
        eta, box, rng2, ind, p
      )

def mutate(
  +op: Poly,
  +ind: Ind.Individual,
  +box: Bounds.Box,
  rng: Rng.State,
  +p: F32
) -> Rng.State & Ind.Individual:
  start(eta(op), box, rng, ind, p, Ind.n_var(ind))
