# Polynomial mutation — C# Unsga3.Operators.Mutation.PolynomialMutation.
# Default η = 20. Probability per variable is an argument (C# Run uses 1/n).

import Base
import ./individual.bend as Ind
import ./bounds.bend as Bounds
import ./rng.bend as Rng

type Poly is Data:
  MkPoly{
    eta: F32
  }

def mk(+eta: F32) -> Poly:
  MkPoly{eta}

def default() -> Poly:
  MkPoly{20.0}

def eta(op: Poly) -> F32:
  match op:
    case MkPoly{eta}:
      eta

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

# One variable. Does not recurse — `loop` is the only recursive def.
def apply3(
  rng: Rng.State,
  ind: Ind.Individual,
  +i: Nat,
  +eta: F32,
  +lo: F32,
  +hi: F32,
  +x: F32,
  +dmax: F32
) -> Rng.State & Ind.Individual:
  (rng2, +rand) = Rng.next_double(rng)
  +mut_pow = F32.div(1.0, F32.add(eta, 1.0))
  +dq = deltaq(eta, mut_pow, F32.div(F32.sub(x, lo), dmax), F32.div(F32.sub(hi, x), dmax), rand)
  +y = F32.clamp(F32.add(x, F32.mul(dq, dmax)), lo, hi)
  (rng2, Ind.set_evaluated(Ind.set_var_at(ind, i, y), False{}))

def apply2(
  rng: Rng.State,
  ind: Ind.Individual,
  +i: Nat,
  +eta: F32,
  +lo: F32,
  +hi: F32,
  +x: F32,
  +dmax: F32,
  tiny: Bool
) -> Rng.State & Ind.Individual:
  match tiny:
    case True{}:
      (rng, ind)
    case False{}:
      apply3(rng, ind, i, eta, lo, hi, x, dmax)

def apply(
  +eta: F32,
  +box: Bounds.Box,
  rng: Rng.State,
  ind: Ind.Individual,
  +i: Nat
) -> Rng.State & Ind.Individual:
  +iv = Bounds.at(box, i)
  +lo = Bounds.lo(iv)
  +hi = Bounds.hi(iv)
  +x = Ind.var_at(ind, i)
  +dmax = F32.sub(hi, lo)
  apply2(rng, ind, i, eta, lo, hi, x, dmax, F32.is_lt(dmax, 1.0e-14))

def after_coin(
  +eta: F32,
  +box: Bounds.Box,
  rng: Rng.State,
  ind: Ind.Individual,
  +i: Nat,
  skip: Bool
) -> Rng.State & Ind.Individual:
  match skip:
    case True{}:
      (rng, ind)
    case False{}:
      apply(eta, box, rng, ind, i)

def loop(
  +eta: F32,
  +box: Bounds.Box,
  rng: Rng.State,
  ind: Ind.Individual,
  +p: F32,
  fuel: Nat,
  +i: Nat
) -> Rng.State & Ind.Individual:
  match fuel:
    case 0n:
      (rng, ind)
    case 1n+f:
      (rng2, u) = Rng.next_double(rng)
      (rng3, nind) = after_coin(eta, box, rng2, ind, i, F32.is_gt(u, p))
      loop(eta, box, rng3, nind, p, f, 1n+i)

def mutate(
  +op: Poly,
  ind: Ind.Individual,
  +box: Bounds.Box,
  rng: Rng.State,
  +p: F32
) -> Rng.State & Ind.Individual:
  +n = Ind.n_var(ind)
  loop(eta(op), box, rng, ind, p, n, 0n)
