# RandomProvider surface — C# Unsga3.Utilities.RandomProvider.
# Seed + NextDouble in [0, 1). Portable Numerical Recipes LCG
# (not .NET System.Random). Integer Next / NextExcept wait for
# tournament / random niching.
#
# Affine API: `next_double` returns the advanced state; `last_double`
# is that draw. Callers use lets, not pair-destructure.

import Base

type State is Data:
  MkState{
    s0: U32
    u: U32
    z: F32
  }

def new(+s0: U32) -> State:
  MkState{s0, s0, 0.0}

def from_nat(seed: Nat) -> State:
  new(U32.from_nat(seed))

def seed_of(s: State) -> U32:
  match s:
    case MkState{s0, u, z}:
      s0

def last_double(s: State) -> F32:
  match s:
    case MkState{s0, u, z}:
      z

def step(u: U32) -> U32:
  U32.add(U32.mul(1664525, u), 1013904223)

# Top 24 bits / 2^24 so the F32 mantissa is exact and the value is in [0, 1).
def to_unit(u: U32) -> F32:
  F32.div(U32.to_f32(U32.shrn(u, 8n)), 16777216.0)

def next_double(s: State) -> State:
  match s:
    case MkState{s0, u, z}:
      +n = step(u)
      MkState{s0, n, to_unit(n)}
