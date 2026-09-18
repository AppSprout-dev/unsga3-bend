# RandomProvider surface — C# Unsga3.Utilities.RandomProvider.
# Seed + NextDouble in [0, 1). Portable Numerical Recipes LCG
# (not .NET System.Random). Integer Next / NextExcept wait for
# tournament / random niching.

import Base

type State is Data:
  MkState{
    seed: U32
    u: U32
  }

def new(+seed: U32) -> State:
  MkState{seed, seed}

def from_nat(seed: Nat) -> State:
  new(U32.from_nat(seed))

def seed_of(s: State) -> U32:
  match s:
    case MkState{seed, u}:
      seed

def step(u: U32) -> U32:
  U32.add(U32.mul(1664525, u), 1013904223)

def next_u32(s: State) -> State & U32:
  match s:
    case MkState{seed, u}:
      +n = step(u)
      (MkState{seed, n}, n)

# Top 24 bits / 2^24 so the F32 mantissa is exact and the value is in [0, 1).
def to_unit(u: U32) -> F32:
  F32.div(U32.to_f32(U32.shrn(u, 8n)), 16777216.0)

def next_double(s: State) -> State & F32:
  (s2, u) = next_u32(s)
  (s2, to_unit(u))
