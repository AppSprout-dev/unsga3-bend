# Pass 2 operator smoke: SBX then polynomial mutation on a 2-var unit box.
# Fixed seed. Prints child decision vectors. No IGD / HV / Wilcoxon.

import Base
import ./individual.bend as Ind
import ./bounds.bend as Bounds
import ./rng.bend as Rng
import ./sbx.bend as Sbx
import ./polynomial_mutation.bend as Poly
import ./util.bend as Util

def parent_a() -> Ind.Individual:
  Ind.from_variables([0.2, 0.8], 2n)

def parent_b() -> Ind.Individual:
  Ind.from_variables([0.7, 0.3], 2n)

def box2() -> Bounds.Box:
  Bounds.unit_n(2n, 2n)

def run.go3(+m1: Ind.Individual, pair: Rng.State & Ind.Individual) -> Ind.Individual & Ind.Individual:
  (rng3, m2) = pair
  (m1, m2)

def run.go2(c2: Ind.Individual, +box: Bounds.Box, pair: Rng.State & Ind.Individual) -> Ind.Individual & Ind.Individual:
  (rng2, m1) = pair
  run.go3(m1, Poly.mutate(Poly.default(), c2, box, rng2, Poly.typical_probability(2n)))

def run.go1(+box: Bounds.Box, trip: Rng.State & Ind.Individual & Ind.Individual) -> Ind.Individual & Ind.Individual:
  (rng1, c1, c2) = trip
  run.go2(c2, box, Poly.mutate(Poly.default(), c1, box, rng1, Poly.typical_probability(2n)))

# seed 42; mutation p = 1/n = 0.5 (C# Run default when unset).
def run() -> Ind.Individual & Ind.Individual:
  +box = box2()
  run.go1(box, Sbx.crossover(Sbx.default(), parent_a(), parent_b(), box, Rng.from_nat(42n)))

def main.emit(pair: Ind.Individual & Ind.Individual) -> IO(Unit):
  (m1, m2) = pair
  do IO<Unit>:
    IO.print("c1=" ++ Util.show_f32s(Ind.variables(m1)))
    IO.print("c2=" ++ Util.show_f32s(Ind.variables(m2)))

def main() -> IO(Unit):
  main.emit(run())
