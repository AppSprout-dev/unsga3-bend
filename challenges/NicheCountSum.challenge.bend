# Trusted challenge surface for Laws.niche_count_sum.
# The closure is PROOF.bend (`def Laws.niche_count_sum`). This file is the
# hole: it restates the contract and does not prove it. Do not import it
# from PROOF.bend. Do not weaken LAWS.bend to match a stub.

import Base
import ../src/survival.bend as Surv
import ../src/util.bend as Util

# LAW: mid-split niche histogram is conservative. Each in-bin assignment
# increments exactly once; List.set / inc_at drops i >= n_dirs (empty
# dirs → zeros(0) is a no-op). When every asg_ref is < n_dirs this is
# |asgs|. Nat only — no F32 / RNG claim.
law niche_count_sum:
  for +asgs: List<&2, Surv.Assignment>
  for +n_dirs: Nat
  {Util.nats_sum(Surv.count_raw.go(n_dirs, Util.list_len(Surv.Assignment, asgs), asgs)) == Surv.in_bin_count(asgs, n_dirs) : Nat}

# Hole. Not a second proof.
def niche_count_sum(asgs, n_dirs):
  ?TODO
