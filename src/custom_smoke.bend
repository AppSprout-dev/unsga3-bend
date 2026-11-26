# Custom-problem smoke via Lib.run_with (template evaluator + consumer facade).
# Exercises a user-defined constrained bi-objective problem through `src/lib.bend`
# without editing `src/problems.bend`.

import Base
import ./lib.bend as Unsga3
import ./individual.bend as Ind
import ./problems.bend as Prob
import ./util.bend as Util

# Minimize f0 = x0, f1 = (1 - x0) + x1, subject to g0 = 0.5 - (x0 + x1) <= 0.
def custom_eval(+x: List<&2, F32>) -> Prob.Scored:
  +x0 = Util.get_f32(x, 0n)
  +x1 = Util.get_f32(x, 1n)
  +f0 = x0
  +f1 = F32.add(F32.sub(1.0, x0), x1)
  +g0 = F32.sub(0.5, F32.add(x0, x1))
  Unsga3.scored(f0 <> [f1], [g0])

def line(ok: Bool, label: String) -> String:
  match ok:
    case True{}:
      "ok " ++ label
    case False{}:
      "FAIL " ++ label

def main() -> IO(Unit):
  +box = Unsga3.unit_box(2n, 2n)
  +cfg = Unsga3.mk_config(Unsga3.das_dennis(2n, 4n), 8n, 5n, 1n, Unsga3.pymoo(), True{})
  +pop = Unsga3.run_with(~custom_eval, box, cfg)
  +front = Unsga3.feas_nd(pop)
  do IO<Unit>:
    IO.print(line(Nat.is_eq(Util.list_len(Ind.Individual, pop), 8n), "custom_run_with_pop8"))
    IO.print(line(Nat.is_gt(Util.list_len(Ind.Individual, front), 0n), "custom_run_with_feas_front"))
