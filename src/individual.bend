# Individual — C# Unsga3.Algorithm.Individual.
# Pass 2 slice: decision variables + evaluated flag. Objectives-only
# v0 helpers (`from_objectives`, `objectives`) stay the sort / normalize
# / survival surface. Constraints and Evaluate stay later (with Run).

import Base

type Individual is Data:
  MkIndividual{
    x: List<&2, F32>
    f: List<&2, F32>
    rnk: Nat
    nic: Nat
    aref: Nat
    dist: F32
    ev: Bool
  }

# v0 / A/B path: objectives already known; no decision vector.
def from_objectives(+f: List<&2, F32>) -> Individual:
  MkIndividual{Nil{}, f, 0n, 0n, 0n, 0.0, True{}}

# Unevaluated candidate: variables set, objectives zeroed (C# ctor).
def from_variables(+x: List<&2, F32>, n_obj: Nat) -> Individual:
  MkIndividual{x, List.replicate(F32, n_obj, 0.0), 0n, 0n, 0n, 0.0, False{}}

def variables(ind: Individual) -> List<&2, F32>:
  match ind:
    case MkIndividual{x, f, rnk, nic, aref, dist, ev}:
      x

def objectives(ind: Individual) -> List<&2, F32>:
  match ind:
    case MkIndividual{x, f, rnk, nic, aref, dist, ev}:
      f

def rank(ind: Individual) -> Nat:
  match ind:
    case MkIndividual{x, f, rnk, nic, aref, dist, ev}:
      rnk

def evaluated(ind: Individual) -> Bool:
  match ind:
    case MkIndividual{x, f, rnk, nic, aref, dist, ev}:
      ev

def n_obj(ind: Individual) -> Nat:
  List.length(&2, F32, objectives(ind))

def n_var(ind: Individual) -> Nat:
  List.length(&2, F32, variables(ind))

def var_at(ind: Individual, i: Nat) -> F32:
  Maybe.default(&2, F32, List.get(&2, F32, variables(ind), i), 0.0)

def set_var_at(ind: Individual, i: Nat, v: F32) -> Individual:
  match ind:
    case MkIndividual{x, f, rnk, nic, aref, dist, ev}:
      MkIndividual{List.set(&2, F32, x, i, v), f, rnk, nic, aref, dist, ev}

def set_evaluated(ind: Individual, ev2: Bool) -> Individual:
  match ind:
    case MkIndividual{x, f, rnk, nic, aref, dist, ev}:
      MkIndividual{x, f, rnk, nic, aref, dist, ev2}
