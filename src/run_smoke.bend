# Short fixed-seed ZDT1 Run smoke (not the C# oracle protocol).
# Settings: n=30, Das–Dennis partitions=4, pop=8, gens=3, seed=1,
# tournament=PymooCompatible, SBX η=30 p=1.0, PM η=20 p=1/n.
# Prints ND front CSV (one objective row per line). No IGD / HV.
# Native: `bend src/run_smoke.bend -o ab/out/run_smoke` then
# `./ab/out/run_smoke` (optional `--threads N`). Same CSV as `bend` check-run.

import Base
import ./algorithm.bend as Algo
import ./problems.bend as Prob

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("# smoke: zdt1 n=30 partitions=4 pop=8 gens=3 seed=1 tournament=PymooCompatible")
    Algo.emit_front(Algo.nd_front(Algo.run(Prob.zdt1(30n), Algo.smoke_zdt1())))
