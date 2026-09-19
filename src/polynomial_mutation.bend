# Polynomial mutation — C# Unsga3.Operators.Mutation.PolynomialMutation.
# Default η = 20. Probability per variable is an argument (C# Run uses 1/n).
# Walks the decision vector and box intervals together (no List.get /
# set_var_at per index). Same RNG order as the old indexed loop.

import Base
import ./individual.bend as Ind
import ./bounds.bend as Bounds
import ./rng.bend as Rng
import ./util.bend as Util

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

def tiny_head(ivs: List<&2, Bounds.Interval>) -> Bool:
  match ivs:
    case Nil{}:
      False{}
    case +iv <> rest:
      F32.is_lt(F32.sub(Bounds.hi(iv), Bounds.lo(iv)), 1.0e-14)

def advance(rng: Rng.State, rest: Nat) -> Rng.State:
  match rest:
    case 0n:
      rng
    case 1n+g:
      Rng.next_double(rng)

def skip_kind(skip: Bool, tiny: Bool) -> Nat:
  match skip:
    case True{}:
      0n
    case False{}:
      match tiny:
        case True{}:
          0n
        case False{}:
          1n

def finish(+m: Nat, pair: Rng.State & List<&2, F32>) -> Rng.State & Ind.Individual:
  (rng, xs) = pair
  (rng, Ind.from_variables(xs, m))

def done(rng: Rng.State, acc: List<&2, F32>) -> Rng.State & List<&2, F32>:
  (rng, List.reverse(&2, F32, acc))

# Kind: 0n = copy the head (skip or tiny span), 1n = mutate the head.
def loop.go(
  fuel: Nat,
  kind: Nat,
  xs: List<&2, F32>,
  ivs: List<&2, Bounds.Interval>,
  +eta: F32,
  rng: Rng.State,
  acc: List<&2, F32>,
  +p: F32
) -> Rng.State & List<&2, F32>:
  match fuel kind xs ivs:
    case 0n k a b:
      done(rng, acc)
    case 1n++f 0n +x <> rest +iv <> +ivrest:
      +rng2 = advance(rng, f)
      loop.go(
        f,
        skip_kind(F32.is_gt(Rng.last_double(rng2), p), tiny_head(ivrest)),
        rest, ivrest, eta, rng2, x <> acc, p
      )
    case 1n++f 1n+q +x <> rest +iv <> +ivrest:
      +lo = Bounds.lo(iv)
      +hi = Bounds.hi(iv)
      +dmax = F32.sub(hi, lo)
      +rng_a = Rng.next_double(rng)
      +rand = Rng.last_double(rng_a)
      +mut_pow = F32.div(1.0, F32.add(eta, 1.0))
      +dq = deltaq(eta, mut_pow, F32.div(F32.sub(x, lo), dmax), F32.div(F32.sub(hi, x), dmax), rand)
      +y = F32.clamp(F32.add(x, F32.mul(dq, dmax)), lo, hi)
      +rng_b = advance(rng_a, f)
      loop.go(
        f,
        skip_kind(F32.is_gt(Rng.last_double(rng_b), p), tiny_head(ivrest)),
        rest, ivrest, eta, rng_b, y <> acc, p
      )
    case 1n++f k Nil{} b:
      done(rng, acc)
    case 1n++f k a <> as Nil{}:
      done(rng, acc)

def start(
  +eta: F32,
  +box: Bounds.Box,
  rng: Rng.State,
  +ind: Ind.Individual,
  +p: F32,
  n: Nat
) -> Rng.State & Ind.Individual:
  match n:
    case 0n:
      (rng, ind)
    case 1n+f:
      +rng2 = Rng.next_double(rng)
      +xs = Ind.variables(ind)
      +ivs = Bounds.intervals_of(box)
      finish(
        Ind.n_obj(ind),
        loop.go(
          1n+f,
          skip_kind(F32.is_gt(Rng.last_double(rng2), p), tiny_head(ivs)),
          xs, ivs, eta, rng2, Nil{}, p
        )
      )

# p=0 leaves the decision vector unchanged before any NextDouble.
# Matches C# when per-variable probability is 0 (every draw is > 0).
def start_or_copy(
  +eta: F32,
  +box: Bounds.Box,
  rng: Rng.State,
  ind: Ind.Individual,
  +p: F32,
  n: Nat,
  zero: Bool
) -> Rng.State & Ind.Individual:
  match zero:
    case True{}:
      (rng, ind)
    case False{}:
      start(eta, box, rng, ind, p, n)

def mutate(
  +op: Poly,
  +ind: Ind.Individual,
  +box: Bounds.Box,
  rng: Rng.State,
  +p: F32
) -> Rng.State & Ind.Individual:
  start_or_copy(eta(op), box, rng, ind, p, Ind.n_var(ind), Util.f32_is_zero(p))
