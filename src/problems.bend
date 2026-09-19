# Named problems — C# Unsga3.Problems Zdt1 / Zdt2 / Dtlz2.
# Bounds + Evaluate match the attached C# IProblem / problem files.
# Minimize. Unconstrained (NumberOfConstraints = 0).

import Base
import ./individual.bend as Ind
import ./bounds.bend as Bounds
import ./util.bend as Util

type Family is Data:
  Zdt1{}
  Zdt2{}
  Dtlz2{}

type Problem is Data:
  MkProblem{
    kind: Family
    box: Bounds.Box
  }

def box_of(p: Problem) -> Bounds.Box:
  match p:
    case MkProblem{kind, box}:
      box

def kind_of(p: Problem) -> Family:
  match p:
    case MkProblem{kind, box}:
      kind

def n_obj(p: Problem) -> Nat:
  Bounds.n_obj(box_of(p))

def n_var(p: Problem) -> Nat:
  Bounds.n_var(box_of(p))

# ZDT1 / ZDT2: n variables (C# default 30), 2 objectives, x ∈ [0,1]^n.
def zdt1(n: Nat) -> Problem:
  MkProblem{Zdt1{}, Bounds.unit_n(n, 2n)}

def zdt2(n: Nat) -> Problem:
  MkProblem{Zdt2{}, Bounds.unit_n(n, 2n)}

# n = M + k - 1 (C# Dtlz2Problem).
def dtlz_n(m: Nat, k: Nat) -> Nat:
  match m:
    case 0n:
      k
    case 1n+pm:
      match k:
        case 0n:
          pm
        case 1n+pk:
          Nat.add(pm, 1n+pk)

# DTLZ2: C# default M=3, k=10 ⇒ n=12, x ∈ [0,1]^n.
def dtlz2(+m: Nat, k: Nat) -> Problem:
  MkProblem{Dtlz2{}, Bounds.unit_n(dtlz_n(m, k), m)}

def sum_from(xs: List<&2, F32>) -> F32:
  match xs:
    case Nil{}:
      0.0
    case h <> t:
      F32.add(h, sum_from(t))

def sum_tail(xs: List<&2, F32>) -> F32:
  match xs:
    case Nil{}:
      0.0
    case h <> t:
      sum_from(t)

def zdt_den(n: Nat) -> F32:
  match n:
    case 0n:
      1.0
    case 1n:
      1.0
    case 1n+p:
      F32.from_nat(p)

# C# Zdt1Problem.GLinear: 1 + 9 * sum(x[1..]) / (n - 1).
def zdt_g(+x: List<&2, F32>) -> F32:
  +n = Util.list_len(F32, x)
  F32.add(1.0, F32.div(F32.mul(9.0, sum_tail(x)), zdt_den(n)))

def zdt1_f(+x: List<&2, F32>) -> List<&2, F32>:
  +x0 = Util.get_f32(x, 0n)
  +g = zdt_g(x)
  x0 <> [F32.mul(g, F32.sub(1.0, F32.sqrt(F32.div(x0, g))))]

def zdt2_f(+x: List<&2, F32>) -> List<&2, F32>:
  +x0 = Util.get_f32(x, 0n)
  +g = zdt_g(x)
  +r = F32.div(x0, g)
  x0 <> [F32.mul(g, F32.sub(1.0, F32.mul(r, r)))]

def pred(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      p

def sum_sq_half(xs: List<&2, F32>) -> F32:
  match xs:
    case Nil{}:
      0.0
    case h <> t:
      F32.add(F32.square(F32.sub(h, 0.5)), sum_sq_half(t))

# C# DtlzHelper.GDtlz2: sum (x[i] - 0.5)^2 for i >= M-1.
def dtlz2_g(+x: List<&2, F32>, m: Nat) -> F32:
  sum_sq_half(List.drop(&2, F32, x, pred(m)))

def half_pi() -> F32:
  F32.div(F32.pi(), 2.0)

def prod_cos.go(+x: List<&2, F32>, fuel: Nat, +i: Nat, acc: F32) -> F32:
  match fuel:
    case 0n:
      acc
    case 1n+f:
      prod_cos.go(
        x,
        f,
        1n+i,
        F32.mul(acc, F32.cos(F32.mul(Util.get_f32(x, i), half_pi())))
      )

def prod_cos(+x: List<&2, F32>, n: Nat) -> F32:
  prod_cos.go(x, n, 0n, 1.0)

def dtlz2_sin(+x: List<&2, F32>, +m: Nat, +i: Nat) -> F32:
  F32.sin(F32.mul(Util.get_f32(x, pred(Nat.sub(m, i))), half_pi()))

def dtlz2_fi.tail(+x: List<&2, F32>, +m: Nat, +g: F32, +i: Nat, +body: F32, first: Bool) -> F32:
  match first:
    case True{}:
      body
    case False{}:
      F32.mul(body, dtlz2_sin(x, m, i))

# C# Dtlz2Problem: (1+g) * prod_{j<M-i-1} cos(x[j] π/2) [* sin(x[M-i-1] π/2) if i>0].
def dtlz2_fi(+x: List<&2, F32>, +m: Nat, +g: F32, +i: Nat) -> F32:
  dtlz2_fi.tail(
    x,
    m,
    g,
    i,
    F32.mul(F32.add(1.0, g), prod_cos(x, pred(Nat.sub(m, i)))),
    Nat.is_eq(i, 0n)
  )

def dtlz2_fs.go(+x: List<&2, F32>, +m: Nat, +g: F32, fuel: Nat, +i: Nat) -> List<&2, F32>:
  match fuel:
    case 0n:
      Nil{}
    case 1n+f:
      dtlz2_fi(x, m, g, i) <> dtlz2_fs.go(x, m, g, f, 1n+i)

def dtlz2_f(+x: List<&2, F32>, +m: Nat) -> List<&2, F32>:
  dtlz2_fs.go(x, m, dtlz2_g(x, m), m, 0n)

def eval_kind(kind: Family, +x: List<&2, F32>, +m: Nat) -> List<&2, F32>:
  match kind:
    case Zdt1{}:
      zdt1_f(x)
    case Zdt2{}:
      zdt2_f(x)
    case Dtlz2{}:
      dtlz2_f(x, m)

def evaluate(+p: Problem, +ind: Ind.Individual) -> Ind.Individual:
  Ind.set_objectives(ind, eval_kind(kind_of(p), Ind.variables(ind), n_obj(p)))

# Independent per individual. Mid-split + parallel recurse; same order as cons.
def evaluate_all(+p: Problem, +xs: List<&2, Ind.Individual>) -> List<&2, Ind.Individual>:
  Util.map_halves(~Ind.Individual, ~Ind.Individual, ~Problem, ~evaluate, p, xs)
