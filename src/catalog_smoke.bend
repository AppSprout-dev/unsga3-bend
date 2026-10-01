# Catalog smoke — not an oracle and not an IGD table.
# Each new C# problem: default n_var / n_obj, box ends, Evaluate at x_i=0.5,
# then a short Run (pop=4, gens=1, seed=1, partitions=2, PymooCompatible).
# ZDT1 / ZDT2 / DTLZ2 protocol budgets are not used here.

import Base
import ./algorithm.bend as Algo
import ./bounds.bend as Bounds
import ./individual.bend as Ind
import ./problems.bend as Prob
import ./reference_directions.bend as Refs
import ./tournament.bend as Tour
import ./util.bend as Util

def show_nat(n: Nat) -> String:
  F32.show(F32.from_nat(n))

def last_ix(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      p

def halves(n: Nat) -> List<&2, F32>:
  List.replicate(F32, n, 0.5)

def short_cfg(+m: Nat) -> Algo.Config:
  Algo.mk(Refs.das_dennis(m, 2n), 4n, 1n, 1n, Tour.pymoo(), True{})

def box_line(name: String, +p: Prob.Problem) -> String:
  +n = Prob.n_var(p)
  +b = Prob.box_of(p)
  +a = Bounds.at(b, 0n)
  +z = Bounds.at(b, last_ix(n))
  "box " ++ name
    ++ " lo0=" ++ F32.show(Bounds.lo(a))
    ++ " hi0=" ++ F32.show(Bounds.hi(a))
    ++ " loL=" ++ F32.show(Bounds.lo(z))
    ++ " hiL=" ++ F32.show(Bounds.hi(z))

def eval_line(name: String, +p: Prob.Problem) -> String:
  +nv = Prob.n_var(p)
  +nm = Prob.n_obj(p)
  +f = Ind.objectives(Prob.evaluate(p, Ind.from_variables(halves(nv), nm)))
  "eval " ++ name ++ " nv=" ++ show_nat(nv) ++ " nm=" ++ show_nat(nm) ++ " f=" ++ Util.show_f32s(f)

def run_line(name: String, +p: Prob.Problem) -> String:
  +pop = Algo.run(p, short_cfg(Prob.n_obj(p)))
  +nd = Algo.nd_front(pop)
  "run " ++ name
    ++ " len=" ++ show_nat(Util.list_len(Ind.Individual, pop))
    ++ " nd=" ++ show_nat(Util.list_len(Ind.Individual, nd))

def trio(+name: String, +p: Prob.Problem) -> List<&2, String>:
  box_line(name, p) <> eval_line(name, p) <> run_line(name, p) <> Nil{}

def lines() -> List<&2, String>:
  List.append(
    &2,
    String,
    List.append(
      &2,
      String,
      List.append(
        &2,
        String,
        List.append(
          &2,
          String,
          List.append(&2, String, trio("zdt3", Prob.zdt3(30n)), trio("zdt4", Prob.zdt4(10n))),
          trio("zdt6", Prob.zdt6(10n))
        ),
        trio("dtlz1", Prob.dtlz1(3n, 5n))
      ),
      List.append(&2, String, trio("dtlz3", Prob.dtlz3(3n, 10n)), trio("dtlz4", Prob.dtlz4(3n, 10n)))
    ),
    List.append(
      &2,
      String,
      List.append(&2, String, trio("dtlz7", Prob.dtlz7(3n, 20n)), trio("sphere", Prob.sphere(10n))),
      List.append(&2, String, trio("ackley", Prob.ackley(30n)), trio("rosenbrock", Prob.rosenbrock(10n)))
    )
  )

def emit(xs: List<&2, String>) -> IO(Unit):
  match xs:
    case Nil{}:
      do IO<Unit>:
        return Unit{}
    case h <> t:
      do IO<Unit>:
        IO.print(h)
        emit(t)

# x_i=1 hits F32 cos(π/2)<0 on the DTLZ2 map. DTLZ3 must stay ≥0.
def axis_dtlz3() -> String:
  +f = Ind.objectives(Prob.evaluate(Prob.dtlz3(3n, 10n), Ind.from_variables(List.replicate(F32, 12n, 1.0), 3n)))
  "axis dtlz3 f=" ++ Util.show_f32s(f)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(axis_dtlz3())
    emit(lines())
