# Individual — C# Unsga3.Algorithm.Individual.
# Objectives + decision variables + evaluated + tournament bookkeeping
# (rank / niche / associated ref / perp distance).
# Constraints are g ≤ 0. `cv` is the sum of the positive parts
# (RefreshConstraintViolation). Feasible iff cv ≤ 0. Empty g is cv 0,
# so unconstrained ZDT / DTLZ stay on the Pareto path.
# `lnk` is false until `stamp` (C# AssociatedReference starts at -1).
# CV-fill clears it again: those members are not in a niche.

import Base

type Individual is Data:
  MkIndividual{
    x: List<&2, F32>
    f: List<&2, F32>
    g: List<&2, F32>
    cv: F32
    rnk: Nat
    nic: Nat
    aref: Nat
    dist: F32
    ev: Bool
    lnk: Bool
  }

def pos_part(+x: F32) -> F32:
  Bool.pick(F32, F32.is_gt(x, 0.0), x, 0.0)

# Sum of g_i where g_i > 0. Non-positive parts add nothing.
def sum_pos(xs: List<&2, F32>) -> F32:
  match xs:
    case Nil{}:
      0.0
    case +h <> t:
      F32.add(pos_part(h), sum_pos(t))

# v0 / A/B path: objectives already known; no decision vector.
# No constraints → cv 0 (feasible).
def from_objectives(+f: List<&2, F32>) -> Individual:
  MkIndividual{Nil{}, f, Nil{}, 0.0, 0n, 0n, 0n, 0.0, True{}, False{}}

# Unevaluated candidate: variables set, objectives zeroed (C# ctor).
# Constraints empty until a problem writes them.
def from_variables(+x: List<&2, F32>, n_obj: Nat) -> Individual:
  MkIndividual{x, List.replicate(F32, n_obj, 0.0), Nil{}, 0.0, 0n, 0n, 0n, 0.0, False{}, False{}}

def variables(ind: Individual) -> List<&2, F32>:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      x

def objectives(ind: Individual) -> List<&2, F32>:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      f

def constraints(ind: Individual) -> List<&2, F32>:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      g

def constraint_violation(ind: Individual) -> F32:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      cv

# C# IsFeasible: ConstraintViolation <= 0.
def feasible(ind: Individual) -> Bool:
  F32.is_le(constraint_violation(ind), 0.0)

def rank(ind: Individual) -> Nat:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      rnk

def evaluated(ind: Individual) -> Bool:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      ev

def n_obj(ind: Individual) -> Nat:
  List.length(&2, F32, objectives(ind))

def n_var(ind: Individual) -> Nat:
  List.length(&2, F32, variables(ind))

def var_at(ind: Individual, i: Nat) -> F32:
  Maybe.default(&2, F32, List.get(&2, F32, variables(ind), i), 0.0)

def set_var_at(ind: Individual, i: Nat, v: F32) -> Individual:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      MkIndividual{List.set(&2, F32, x, i, v), f, g, cv, rnk, nic, ar, pd, ev, lnk}

def set_evaluated(ind: Individual, ev2: Bool) -> Individual:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev2, lnk}

def niche(ind: Individual) -> Nat:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      nic

def associated_ref(ind: Individual) -> Nat:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      ar

def perp_dist(ind: Individual) -> F32:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      pd

def set_objectives(ind: Individual, +f2: List<&2, F32>) -> Individual:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      MkIndividual{x, f2, g, cv, rnk, nic, ar, pd, True{}, lnk}

# Replace g and recompute cv (sum of positive parts).
def set_constraints(ind: Individual, +g2: List<&2, F32>) -> Individual:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      MkIndividual{x, f, g2, sum_pos(g2), rnk, nic, ar, pd, ev, lnk}

def set_rank(ind: Individual, rnk2: Nat) -> Individual:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      MkIndividual{x, f, g, cv, rnk2, nic, ar, pd, ev, lnk}

def stamp(ind: Individual, +rnk2: Nat, +nic2: Nat, +aref2: Nat, +dist2: F32) -> Individual:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      MkIndividual{x, f, g, cv, rnk2, nic2, aref2, dist2, ev, True{}}

# C# AssociatedReference starts at -1. `stamp` is the assignment.
def niche_linked(ind: Individual) -> Bool:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      lnk

# CV fill does not assign a niche (pymoo merges these after survival).
def clear_niche(ind: Individual) -> Individual:
  match ind:
    case MkIndividual{x, f, g, cv, rnk, nic, ar, pd, ev, lnk}:
      MkIndividual{x, f, g, cv, rnk, 0n, 0n, 0.0, ev, False{}}
