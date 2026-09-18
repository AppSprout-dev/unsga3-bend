# v0 proofs. `bend PROOF.bend` is the gate.
# Every law is still open: ?TODO documents the expected proof obligations.
# Empty-input / M=1 facts should be short once the core is implemented;
# sort_index_count, select_size, and association laws need the real algorithms.

import Base
import ./LAWS.bend as Laws

def Laws.sort_empty():
  ?TODO

def Laws.sort_index_count(pop):
  ?TODO

def Laws.dominates_irreflexive(ind):
  ?TODO

def Laws.normalize_empty():
  ?TODO

def Laws.normalize_len(pop):
  ?TODO

def Laws.binomial_k0(n):
  ?TODO

def Laws.das_dennis_count_m1(p):
  ?TODO

def Laws.das_dennis_count(m, p):
  ?TODO

def Laws.das_dennis_m1_len(p):
  ?TODO

def Laws.associate_empty():
  ?TODO

def Laws.associate_len(pop, F, dirs):
  ?TODO

def Laws.select_empty():
  ?TODO

def Laws.select_size(pop, n, dirs):
  ?TODO
