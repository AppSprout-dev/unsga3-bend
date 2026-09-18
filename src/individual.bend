# Individual — C# Unsga3.Algorithm.Individual, v0 slice.
# Objectives only. Decision variables, constraints, and Evaluate arrive
# with SBX / polynomial mutation in pass 2. Do not add them here.

import Base

type Individual is Data:
  MkIndividual{
    f: List<&2, F32>
    rnk: Nat
    nic: Nat
    aref: Nat
    dist: F32
  }

def from_objectives(+f: List<&2, F32>) -> Individual:
  MkIndividual{f, 0n, 0n, 0n, 0.0}

def objectives(ind: Individual) -> List<&2, F32>:
  match ind:
    case MkIndividual{f, rnk, nic, aref, dist}:
      f

def rank(ind: Individual) -> Nat:
  match ind:
    case MkIndividual{f, rnk, nic, aref, dist}:
      rnk
