# Checked-in profile driver: short ZDT1 smoke (not the oracle protocol).
# `python3 ab/profile_bend_run.py` uses this by default.

import Base
import ./profile_run.bend as Prof
import ../src/algorithm.bend as Algo
import ../src/problems.bend as Prob

def main() -> IO(Unit):
  do IO<Unit>:
    Prof.run_and_emit(Prob.zdt1(30n), Algo.smoke_zdt1(), "zdt1-smoke", 2n, 4n)
