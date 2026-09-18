# Proofs. `bend PROOF.bend` is the gate.
# Closed: empty-input / M=1 / binomial / das_dennis_count, plus pass-2
# operator defaults / typical 1/n / from_objectives / ZDT-DTLZ dimensions /
# zero-parent tournament / zero-pop Run. Remaining quantified size /
# irreflexivity / F32-opaque p=0 copy / |Run|==pop stay ?TODO.

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
  {==}

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

def Laws.from_objectives_roundtrip():
  {==}

def Laws.sbx_default_eta():
  {==}

def Laws.sbx_default_probability():
  {==}

def Laws.poly_default_eta():
  {==}

def Laws.poly_typical_n2():
  {==}

def Laws.sbx_prob0_child1_vars():
  ?TODO

def Laws.sbx_prob0_child2_vars():
  ?TODO

def Laws.poly_prob0_vars():
  ?TODO

def Laws.zdt1_n_obj():
  {==}

def Laws.zdt2_n_obj():
  {==}

def Laws.zdt1_n_var():
  {==}

def Laws.dtlz2_n_obj():
  {==}

def Laws.dtlz2_n_var():
  {==}

def Laws.select_parents_zero():
  {==}

def Laws.run_zero_pop():
  {==}

def Laws.run_pop_size(cfg):
  ?TODO
