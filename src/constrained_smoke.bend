# Formulation and survival checks for OSY, TNK, and C1-DTLZ1.
# Mirrors C# ConstrainedProblemTests. Not an IGD table.
# Short runs inject one known feasible point (pop=12, gens=3, seed=1,
# PymooCompatible). Partitions are 4 when M=2 and 2 when M=3.
# Bend 2.0.34's interpreter faults when the three Runs share main.
# Check with `bend src/constrained_smoke.bend -o <bin>` and run the binary.

import Base
import ./algorithm.bend as Algo
import ./individual.bend as Ind
import ./normalization.bend as Norm
import ./problems.bend as Prob
import ./reference_directions.bend as Refs
import ./rng.bend as Rng
import ./survival.bend as Surv
import ./tournament.bend as Tour
import ./util.bend as Util

def bit(b: Bool) -> String:
  match b:
    case True{}:
      "1"
    case False{}:
      "0"

def show_nat(n: Nat) -> String:
  F32.show(F32.from_nat(n))

def at_ind(xs: List<&2, Ind.Individual>, i: Nat) -> Ind.Individual:
  Maybe.default(&2, Ind.Individual, List.get(&2, Ind.Individual, xs, i), Ind.from_objectives([0.0]))

def count_feas.on(later: Nat, feas: Bool) -> Nat:
  match feas:
    case True{}:
      1n+later
    case False{}:
      later

def count_feas(xs: List<&2, Ind.Individual>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      count_feas.on(count_feas(t), Ind.feasible(h))

def eval_at(+p: Prob.Problem, +x: List<&2, F32>) -> Ind.Individual:
  Prob.evaluate(p, Ind.from_variables(x, Prob.n_obj(p)))

def ones(n: Nat, +v: F32) -> List<&2, F32>:
  List.replicate(F32, n, v)

def point_line(name: String, +ind: Ind.Individual) -> String:
  "pt " ++ name
    ++ " f=" ++ Util.show_f32s(Ind.objectives(ind))
    ++ " g=" ++ Util.show_f32s(Ind.constraints(ind))
    ++ " cv=" ++ F32.show(Ind.constraint_violation(ind))
    ++ " feas=" ++ bit(Ind.feasible(ind))
    ++ " nv=" ++ show_nat(Ind.n_var(ind))
    ++ " ng=" ++ show_nat(Util.list_len(F32, Ind.constraints(ind)))

def surv_text(name: String, trip: Norm.State & List<&2, Ind.Individual> & Rng.State) -> String:
  (st, +sel, rng2) = trip
  +a = at_ind(sel, 0n)
  +b = at_ind(sel, 1n)
  "surv " ++ name
    ++ " n=" ++ show_nat(Util.list_len(Ind.Individual, sel))
    ++ " s0f=" ++ bit(Ind.feasible(a))
    ++ " s1f=" ++ bit(Ind.feasible(b))
    ++ " s1cv=" ++ F32.show(Ind.constraint_violation(b))
    ++ " s1lnk=" ++ bit(Ind.niche_linked(b))
    ++ " ideal=" ++ Util.show_f32s(Norm.state_ideal(st))

def surv_line(name: String, +pop: List<&2, Ind.Individual>, +m: Nat) -> String:
  surv_text(name, Surv.select_st(pop, 2n, Refs.das_dennis(m, 1n), Norm.new_state(m), Rng.from_nat(1n)))

def parts_for.go(two: Bool) -> Nat:
  match two:
    case True{}:
      4n
    case False{}:
      2n

def parts_for(m: Nat) -> Nat:
  parts_for.go(Nat.is_eq(m, 2n))

def run_line(name: String, +p: Prob.Problem, +seed_x: List<&2, F32>) -> String:
  +m = Prob.n_obj(p)
  +cfg = Algo.mk(Refs.das_dennis(m, parts_for(m)), 12n, 3n, 1n, Tour.pymoo(), True{})
  +pop = Algo.run_seeded(p, cfg, seed_x)
  +head = at_ind(pop, 0n)
  "run " ++ name
    ++ " len=" ++ show_nat(Util.list_len(Ind.Individual, pop))
    ++ " feas=" ++ show_nat(count_feas(pop))
    ++ " nm=" ++ show_nat(Ind.n_obj(head))

def pts() -> List<&2, String>:
  +osy = Prob.osy()
  +tnk = Prob.tnk()
  +c1 = Prob.c1_dtlz1(3n, 5n)
  point_line("osy_feas", eval_at(osy, [5.0, 1.0, 5.0, 0.0, 5.0, 0.0]))
    <> point_line("osy_lo", eval_at(osy, [0.0, 0.0, 1.0, 0.0, 1.0, 0.0]))
    <> point_line("tnk_feas", eval_at(tnk, [1.0, 1.0]))
    <> point_line("tnk_near", eval_at(tnk, [0.1, 0.1]))
    <> point_line("c1_feas", eval_at(c1, ones(7n, 0.5)))
    <> [point_line("c1_bad", eval_at(c1, ones(7n, 0.0)))]

def survs() -> List<&2, String>:
  +osy = Prob.osy()
  +tnk = Prob.tnk()
  +c1 = Prob.c1_dtlz1(3n, 5n)
  surv_line("osy", eval_at(osy, [0.0, 0.0, 1.0, 6.0, 1.0, 0.0]) <> eval_at(osy, [5.0, 1.0, 5.0, 0.0, 5.0, 0.0]) <> [eval_at(osy, [0.0, 0.0, 1.0, 0.0, 1.0, 0.0])], 2n)
    <> surv_line("tnk", eval_at(tnk, [3.0, 3.0]) <> eval_at(tnk, [0.1, 0.1]) <> [eval_at(tnk, [1.0, 1.0])], 2n)
    <> [surv_line("c1", eval_at(c1, ones(7n, 0.0)) <> eval_at(c1, ones(7n, 0.5)) <> [eval_at(c1, ones(7n, 0.2))], 3n)]

def run_osy() -> String:
  run_line("osy", Prob.osy(), [5.0, 1.0, 5.0, 0.0, 5.0, 0.0])

def run_tnk() -> String:
  run_line("tnk", Prob.tnk(), [1.0, 1.0])

def run_c1() -> String:
  run_line("c1", Prob.c1_dtlz1(3n, 5n), ones(7n, 0.5))

def emit(xs: List<&2, String>) -> IO(Unit):
  match xs:
    case Nil{}:
      do IO<Unit>:
        return Unit{}
    case h <> t:
      do IO<Unit>:
        IO.print(h)
        emit(t)

def main() -> IO(Unit):
  do IO<Unit>:
    emit(pts())
    emit(survs())
    IO.print(run_osy())
    IO.print(run_tnk())
    IO.print(run_c1())
    return Unit{}
