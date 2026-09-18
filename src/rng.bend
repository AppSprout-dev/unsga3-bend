# RandomProvider surface — C# Unsga3.Utilities.RandomProvider.
# Seed + NextDouble in [0, 1) + Next / NextExcept for tournament.
# Portable Numerical Recipes LCG (not .NET System.Random). Algorithm
# A/B fronts will not match C# bit-for-bit because of this RNG delta.
#
# Affine API: `next_double` / `next_nat` return the advanced state;
# `last_double` / `last_nat` are that draw. Callers use lets, not
# pair-destructure.

import Base

type State is Data:
  MkState{
    s0: U32
    u: U32
    z: F32
    k: Nat
  }

def new(+s0: U32) -> State:
  MkState{s0, s0, 0.0, 0n}

def from_nat(seed: Nat) -> State:
  new(U32.from_nat(seed))

def seed_of(s: State) -> U32:
  match s:
    case MkState{s0, u, z, k}:
      s0

def last_double(s: State) -> F32:
  match s:
    case MkState{s0, u, z, k}:
      z

def last_nat(s: State) -> Nat:
  match s:
    case MkState{s0, u, z, k}:
      k

def step(u: U32) -> U32:
  U32.add(U32.mul(1664525, u), 1013904223)

# Top 24 bits / 2^24 so the F32 mantissa is exact and the value is in [0, 1).
def to_unit(u: U32) -> F32:
  F32.div(U32.to_f32(U32.shrn(u, 8n)), 16777216.0)

def next_double(s: State) -> State:
  match s:
    case MkState{s0, u, z, k}:
      +n = step(u)
      MkState{s0, n, to_unit(n), k}

def pred_or_zero(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      p

def clamp_lt.fin(+i: Nat, +n: Nat, ok: Bool) -> Nat:
  match ok:
    case True{}:
      i
    case False{}:
      pred_or_zero(n)

def clamp_lt(+i: Nat, +n: Nat) -> Nat:
  clamp_lt.fin(i, n, Nat.is_lt(i, n))

def idx_from(+z: F32, n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n++p:
      clamp_lt(F32.to_nat(F32.trunc(F32.mul(z, F32.from_nat(1n+p)))), 1n+p)

def with_k(s: State, k2: Nat) -> State:
  match s:
    case MkState{s0, u, z, k}:
      MkState{s0, u, z, k2}

# Uniform integer in [0, n). n == 0n → 0n.
def next_nat(s: State, n: Nat) -> State:
  +s2 = next_double(s)
  with_k(s2, idx_from(last_double(s2), n))

def bump_except(+v: Nat, +exclude: Nat, below: Bool) -> Nat:
  match below:
    case True{}:
      v
    case False{}:
      1n+v

# C# NextExcept: uniform in [0, n) distinct from exclude when n > 1.
def next_except.go(s: State, +exclude: Nat, n: Nat) -> State:
  match n:
    case 0n:
      with_k(s, 0n)
    case 1n:
      with_k(s, 0n)
    case 1n+m:
      +s2 = next_nat(s, m)
      +v = last_nat(s2)
      with_k(s2, bump_except(v, exclude, Nat.is_lt(v, exclude)))

def next_except(s: State, n: Nat, exclude: Nat) -> State:
  next_except.go(s, exclude, n)
