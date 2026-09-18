# v0 proofs. `bend PROOF.bend` is the gate.
# Closed laws are those whose sides compute equal after the v0 bodies.
# Remaining obligations stay ?TODO (quantified partition / size facts).

import Base
import ./LAWS.bend as Laws

def Laws.sort_empty():
  {==}

def Laws.sort_index_count(pop):
  ?TODO

def Laws.dominates_irreflexive(ind):
  ?TODO

def Laws.normalize_empty():
  {==}

def Laws.normalize_len(pop):
  ?TODO

def Laws.binomial_k0(n):
  match n:
    case 0n:
      {==}
    case 1n+p:
      {==}

def Laws.das_dennis_count_m1(p):
  {==}

def Laws.das_dennis_count(m, p):
  ?TODO

def Laws.das_dennis_m1_len(p):
  match p:
    case 0n:
      {==}
    case 1n+q:
      {==}

def Laws.das_dennis_len(m, p):
  ?TODO

def Laws.associate_empty():
  {==}

def Laws.associate_len(pop, F, dirs):
  ?TODO

def Laws.select_empty():
  {==}

def Laws.select_size(pop, n, dirs):
  ?TODO
