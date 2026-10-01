# Named problems — C# Unsga3.Problems.
# ZDT1 / ZDT2 / DTLZ2 stay the oracle problems. The rest of the unconstrained
# catalog (ZDT3 / ZDT4 / ZDT6, DTLZ1 / DTLZ3 / DTLZ4 / DTLZ7, Sphere / Ackley /
# Rosenbrock) matches the same C# Evaluate formulas. Minimize.
# OSY / TNK / C1-DTLZ1 match ConstrainedProblems.cs (g ≤ 0, positive = violation).
# Unconstrained kinds write an empty constraint vector (cv 0). No IGD here.
# `alpha` is DTLZ4's exponent (C# default 100). Other kinds ignore it.

import Base
import ./individual.bend as Ind
import ./bounds.bend as Bounds
import ./util.bend as Util

type Family is Data:
  Zdt1{}
  Zdt2{}
  Zdt3{}
  Zdt4{}
  Zdt6{}
  Dtlz1{}
  Dtlz2{}
  Dtlz3{}
  Dtlz4{}
  Dtlz7{}
  Sphere{}
  Ackley{}
  Rosenbrock{}
  Osy{}
  Tnk{}
  C1Dtlz1{}

type Problem is Data:
  MkProblem{
    kind: Family
    box: Bounds.Box
    alpha: F32
  }

def box_of(p: Problem) -> Bounds.Box:
  match p:
    case MkProblem{kind, box, alpha}:
      box

def kind_of(p: Problem) -> Family:
  match p:
    case MkProblem{kind, box, alpha}:
      kind

def alpha_of(p: Problem) -> F32:
  match p:
    case MkProblem{kind, box, alpha}:
      alpha

def n_obj(p: Problem) -> Nat:
  Bounds.n_obj(box_of(p))

def n_var(p: Problem) -> Nat:
  Bounds.n_var(box_of(p))

def mk_prob(kind: Family, box: Bounds.Box) -> Problem:
  MkProblem{kind, box, 0.0}

# ZDT1 / ZDT2 / ZDT3: n variables (C# default 30), 2 objectives, x ∈ [0,1]^n.
def zdt1(n: Nat) -> Problem:
  mk_prob(Zdt1{}, Bounds.unit_n(n, 2n))

def zdt2(n: Nat) -> Problem:
  mk_prob(Zdt2{}, Bounds.unit_n(n, 2n))

def zdt3(n: Nat) -> Problem:
  mk_prob(Zdt3{}, Bounds.unit_n(n, 2n))

# ZDT4: C# default n=10. x0 ∈ [0,1], x1.. ∈ [-5,5].
def zdt4_ivs(n: Nat) -> List<&2, Bounds.Interval>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Bounds.interval(0.0, 1.0) <> List.replicate(Bounds.Interval, p, Bounds.interval(F32.neg(5.0), 5.0))

def zdt4(n: Nat) -> Problem:
  mk_prob(Zdt4{}, Bounds.box(2n, zdt4_ivs(n)))

# ZDT6: C# default n=10, x ∈ [0,1]^n.
def zdt6(n: Nat) -> Problem:
  mk_prob(Zdt6{}, Bounds.unit_n(n, 2n))

# n = M + k - 1 (C# Dtlz*Problem).
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
  mk_prob(Dtlz2{}, Bounds.unit_n(dtlz_n(m, k), m))

# DTLZ1: C# default M=3, k=5 ⇒ n=7.
def dtlz1(+m: Nat, k: Nat) -> Problem:
  mk_prob(Dtlz1{}, Bounds.unit_n(dtlz_n(m, k), m))

# DTLZ3: C# default M=3, k=10. DTLZ2 map, DTLZ1 g.
def dtlz3(+m: Nat, k: Nat) -> Problem:
  mk_prob(Dtlz3{}, Bounds.unit_n(dtlz_n(m, k), m))

# DTLZ4: C# default α=100, k=10.
def dtlz4_alpha(+m: Nat, k: Nat, +alpha: F32) -> Problem:
  MkProblem{Dtlz4{}, Bounds.unit_n(dtlz_n(m, k), m), alpha}

def dtlz4(+m: Nat, k: Nat) -> Problem:
  dtlz4_alpha(m, k, 100.0)

# DTLZ7: C# default M=3, k=20 ⇒ n=22.
def dtlz7(+m: Nat, k: Nat) -> Problem:
  mk_prob(Dtlz7{}, Bounds.unit_n(dtlz_n(m, k), m))

# Single-objective. M=1. C# defaults: Sphere n=10, Ackley n=30, Rosenbrock n=10.
def sphere(n: Nat) -> Problem:
  mk_prob(Sphere{}, Bounds.span_n(n, 1n, F32.neg(5.12), 5.12))

def ackley(n: Nat) -> Problem:
  mk_prob(Ackley{}, Bounds.span_n(n, 1n, F32.neg(32.768), 32.768))

def rosenbrock(n: Nat) -> Problem:
  mk_prob(Rosenbrock{}, Bounds.span_n(n, 1n, F32.neg(2.048), 2.048))

# OSY: 6 variables, 2 objectives, 6 inequalities. pymoo 0.6 scaling.
def osy() -> Problem:
  mk_prob(
    Osy{},
    Bounds.box(
      2n,
      Bounds.interval(0.0, 10.0)
        <> Bounds.interval(0.0, 10.0)
        <> Bounds.interval(1.0, 5.0)
        <> Bounds.interval(0.0, 6.0)
        <> Bounds.interval(1.0, 5.0)
        <> [Bounds.interval(0.0, 10.0)]
    )
  )

# TNK: [0, π] × [1e-30, π]. Disk constraint uses pymoo's factor of two.
def tnk() -> Problem:
  mk_prob(
    Tnk{},
    Bounds.box(2n, Bounds.interval(0.0, F32.pi()) <> [Bounds.interval(1.0e-30, F32.pi())])
  )

# C1-DTLZ1: DTLZ1 plus one inequality. C# default M=3, k=5 (n = M+k-1).
def c1_dtlz1(+m: Nat, k: Nat) -> Problem:
  mk_prob(C1Dtlz1{}, Bounds.unit_n(dtlz_n(m, k), m))

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

def list_tail(xs: List<&2, F32>) -> List<&2, F32>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      t

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

# C# Zdt3Problem: g * (1 - sqrt(r) - r * sin(10 π x0)), r = x0/g.
def zdt3_f(+x: List<&2, F32>) -> List<&2, F32>:
  +x0 = Util.get_f32(x, 0n)
  +g = zdt_g(x)
  +r = F32.div(x0, g)
  +s = F32.sin(F32.mul(F32.mul(10.0, F32.pi()), x0))
  x0 <> [F32.mul(g, F32.sub(F32.sub(1.0, F32.sqrt(r)), F32.mul(r, s)))]

def zdt4_term(+xi: F32) -> F32:
  F32.sub(F32.square(xi), F32.mul(10.0, F32.cos(F32.mul(F32.mul(4.0, F32.pi()), xi))))

def sum_zdt4(xs: List<&2, F32>) -> F32:
  match xs:
    case Nil{}:
      0.0
    case h <> t:
      F32.add(zdt4_term(h), sum_zdt4(t))

def pred(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      p

# C# Zdt4Problem: 1 + 10*(n-1) + Σ_{i≥1} (x_i² - 10 cos(4 π x_i)).
def zdt4_g(+x: List<&2, F32>) -> F32:
  +n = Util.list_len(F32, x)
  F32.add(F32.add(1.0, F32.mul(10.0, F32.from_nat(pred(n)))), sum_zdt4(list_tail(x)))

def zdt4_f(+x: List<&2, F32>) -> List<&2, F32>:
  +x0 = Util.get_f32(x, 0n)
  +g = zdt4_g(x)
  x0 <> [F32.mul(g, F32.sub(1.0, F32.sqrt(F32.div(x0, g))))]

# C# Zdt6Problem: biased density. g = 1 + 9 * (mean of x[1..])^0.25.
def zdt6_f(+x: List<&2, F32>) -> List<&2, F32>:
  +x0 = Util.get_f32(x, 0n)
  +wave = F32.pow(F32.sin(F32.mul(F32.mul(6.0, F32.pi()), x0)), 6.0)
  +f0 = F32.sub(1.0, F32.mul(F32.exp(F32.mul(F32.neg(4.0), x0)), wave))
  +n = Util.list_len(F32, x)
  +g = F32.add(1.0, F32.mul(9.0, F32.pow(F32.div(sum_tail(x), zdt_den(n)), 0.25)))
  +r = F32.div(f0, g)
  f0 <> [F32.mul(g, F32.sub(1.0, F32.mul(r, r)))]

def sum_sq_half(xs: List<&2, F32>) -> F32:
  match xs:
    case Nil{}:
      0.0
    case h <> t:
      F32.add(F32.square(F32.sub(h, 0.5)), sum_sq_half(t))

def tail_from_m(+x: List<&2, F32>, m: Nat) -> List<&2, F32>:
  List.drop(&2, F32, x, pred(m))

# C# DtlzHelper.GDtlz2: sum (x[i] - 0.5)^2 for i >= M-1.
def dtlz2_g(+x: List<&2, F32>, m: Nat) -> F32:
  sum_sq_half(tail_from_m(x, m))

def dtlz1_term(+xi: F32) -> F32:
  +d = F32.sub(xi, 0.5)
  F32.sub(F32.square(d), F32.cos(F32.mul(F32.mul(20.0, F32.pi()), d)))

def sum_dtlz1(xs: List<&2, F32>) -> F32:
  match xs:
    case Nil{}:
      0.0
    case h <> t:
      F32.add(dtlz1_term(h), sum_dtlz1(t))

# C# DtlzHelper.GDtlz1: 100 * ((n - M + 1) + Σ (d² - cos(20 π d))), d = x-0.5.
# On a legal k≥1 box the tail length is n-M+1, which is that coefficient.
def dtlz1_g(+x: List<&2, F32>, m: Nat) -> F32:
  +tail = tail_from_m(x, m)
  F32.mul(100.0, F32.add(F32.from_nat(Util.list_len(F32, tail)), sum_dtlz1(tail)))

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

def prod_xs.go(+x: List<&2, F32>, fuel: Nat, +i: Nat, acc: F32) -> F32:
  match fuel:
    case 0n:
      acc
    case 1n+f:
      prod_xs.go(x, f, 1n+i, F32.mul(acc, Util.get_f32(x, i)))

def prod_xs(+x: List<&2, F32>, n: Nat) -> F32:
  prod_xs.go(x, n, 0n, 1.0)

def dtlz1_scale(+body: F32, +x: List<&2, F32>, +idx: Nat, first: Bool) -> F32:
  match first:
    case True{}:
      body
    case False{}:
      F32.mul(body, F32.sub(1.0, Util.get_f32(x, idx)))

# C# Dtlz1Problem: 0.5*(1+g) * prod_{j<M-i-1} x[j] [* (1-x[M-i-1]) if i>0].
def dtlz1_fi(+x: List<&2, F32>, +m: Nat, +g: F32, +i: Nat) -> F32:
  +idx = pred(Nat.sub(m, i))
  dtlz1_scale(F32.mul(F32.mul(0.5, F32.add(1.0, g)), prod_xs(x, idx)), x, idx, Nat.is_eq(i, 0n))

def dtlz1_fs.go(+x: List<&2, F32>, +m: Nat, +g: F32, fuel: Nat, +i: Nat) -> List<&2, F32>:
  match fuel:
    case 0n:
      Nil{}
    case 1n+f:
      dtlz1_fi(x, m, g, i) <> dtlz1_fs.go(x, m, g, f, 1n+i)

def dtlz1_f(+x: List<&2, F32>, +m: Nat) -> List<&2, F32>:
  dtlz1_fs.go(x, m, dtlz1_g(x, m), m, 0n)

# C# Dtlz3Problem: DTLZ2 map with DTLZ1's g.
def dtlz3_f(+x: List<&2, F32>, +m: Nat) -> List<&2, F32>:
  dtlz2_fs.go(x, m, dtlz1_g(x, m), m, 0n)

# Fuel shrinks first so the recursive call terminates. The g-tail stays raw.
def map_prefix_pow.go(fuel: Nat, xs: List<&2, F32>, +alpha: F32) -> List<&2, F32>:
  match fuel:
    case 0n:
      xs
    case 1n+f:
      match xs:
        case Nil{}:
          Nil{}
        case h <> t:
          F32.pow(h, alpha) <> map_prefix_pow.go(f, t, alpha)

# Raise the first `fuel` decision variables to α.
def map_prefix_pow(+xs: List<&2, F32>, fuel: Nat, +alpha: F32) -> List<&2, F32>:
  map_prefix_pow.go(fuel, xs, alpha)

# C# Dtlz4Problem: DTLZ2 with x^α inside the sine/cosine map. g is still GDtlz2.
def dtlz4_f(+x: List<&2, F32>, +m: Nat, +alpha: F32) -> List<&2, F32>:
  dtlz2_f(map_prefix_pow(x, pred(m), alpha), m)

def pos_or.fin(+x: F32, +fallback: F32, ok: Bool) -> F32:
  match ok:
    case True{}:
      x
    case False{}:
      fallback

def pos_or(+x: F32, +fallback: F32) -> F32:
  pos_or.fin(x, fallback, F32.is_gt(x, 0.0))

# C# Dtlz7Problem g: 1 + 9 * sum(x[M-1..]) / (n - M + 1).
def dtlz7_g(+x: List<&2, F32>, m: Nat) -> F32:
  +tail = tail_from_m(x, m)
  +den = pos_or(F32.from_nat(Util.list_len(F32, tail)), 1.0)
  F32.add(1.0, F32.div(F32.mul(9.0, sum_from(tail)), den))

def dtlz7_h.go(+x: List<&2, F32>, +g1: F32, fuel: Nat, +i: Nat, acc: F32) -> F32:
  match fuel:
    case 0n:
      acc
    case 1n+f:
      +fi = Util.get_f32(x, i)
      +term = F32.mul(F32.div(fi, g1), F32.add(1.0, F32.sin(F32.mul(F32.mul(3.0, F32.pi()), fi))))
      dtlz7_h.go(x, g1, f, 1n+i, F32.add(acc, term))

def dtlz7_prefix(+x: List<&2, F32>, fuel: Nat, +i: Nat) -> List<&2, F32>:
  match fuel:
    case 0n:
      Nil{}
    case 1n+f:
      Util.get_f32(x, i) <> dtlz7_prefix(x, f, 1n+i)

# f[i]=x[i] for i<M-1; f[M-1]=(1+g)*h; h = M - Σ f_i/(1+g) * (1+sin(3 π f_i)).
def dtlz7_f(+x: List<&2, F32>, +m: Nat) -> List<&2, F32>:
  match m:
    case 0n:
      Nil{}
    case 1n+p:
      +g = dtlz7_g(x, m)
      +g1 = F32.add(1.0, g)
      +h = F32.sub(F32.from_nat(m), dtlz7_h.go(x, g1, p, 0n, 0.0))
      List.append(&2, F32, dtlz7_prefix(x, p, 0n), [F32.mul(g1, h)])

def sum_sq(xs: List<&2, F32>) -> F32:
  match xs:
    case Nil{}:
      0.0
    case h <> t:
      F32.add(F32.square(h), sum_sq(t))

def sphere_f(+x: List<&2, F32>) -> List<&2, F32>:
  [sum_sq(x)]

type Acc2 is Data:
  Acc2{
    s1: F32
    s2: F32
  }

def ackley_go(xs: List<&2, F32>, +s1: F32, +s2: F32) -> Acc2:
  match xs:
    case Nil{}:
      Acc2{s1, s2}
    case +h <> t:
      ackley_go(
        t,
        F32.add(s1, F32.square(h)),
        F32.add(s2, F32.cos(F32.mul(F32.mul(2.0, F32.pi()), h)))
      )

def ackley_den(n: Nat) -> F32:
  match n:
    case 0n:
      1.0
    case 1n+p:
      F32.from_nat(1n+p)

def ackley_from(+n: Nat, acc: Acc2) -> List<&2, F32>:
  match acc:
    case Acc2{s1, s2}:
      +den = ackley_den(n)
      [F32.add(
        F32.add(
          F32.mul(F32.neg(20.0), F32.exp(F32.mul(F32.neg(0.2), F32.sqrt(F32.div(s1, den))))),
          F32.neg(F32.exp(F32.div(s2, den)))
        ),
        F32.add(20.0, F32.exp(1.0))
      )]

# C# AckleyProblem. n=0 stays total (denominator 1) instead of dividing by zero.
def ackley_f(+x: List<&2, F32>) -> List<&2, F32>:
  ackley_from(Util.list_len(F32, x), ackley_go(x, 0.0, 0.0))

def rosen_step(rest: List<&2, F32>, +a: F32) -> F32:
  match rest:
    case Nil{}:
      0.0
    case +b <> t:
      +diff = F32.sub(b, F32.square(a))
      +one = F32.sub(1.0, a)
      F32.add(F32.add(F32.mul(100.0, F32.square(diff)), F32.square(one)), rosen_step(t, b))

def rosenbrock_f(+x: List<&2, F32>) -> List<&2, F32>:
  match x:
    case Nil{}:
      [0.0]
    case a <> rest:
      [rosen_step(rest, a)]

# Objectives plus g ≤ 0. Unconstrained kinds leave g empty.
type Scored is Data:
  Scored{
    f: List<&2, F32>
    g: List<&2, F32>
  }

def plain(+f: List<&2, F32>) -> Scored:
  Scored{f, Nil{}}

def scored_f(s: Scored) -> List<&2, F32>:
  match s:
    case Scored{f, g}:
      f

def scored_g(s: Scored) -> List<&2, F32>:
  match s:
    case Scored{f, g}:
      g

# C# OsyProblem. f0 negates the weighted squares (x5 is not in f0).
def osy_f(+x: List<&2, F32>) -> List<&2, F32>:
  +x0 = Util.get_f32(x, 0n)
  +x1 = Util.get_f32(x, 1n)
  +x2 = Util.get_f32(x, 2n)
  +x3 = Util.get_f32(x, 3n)
  +x4 = Util.get_f32(x, 4n)
  +pen = F32.add(
    F32.mul(25.0, F32.square(F32.sub(x0, 2.0))),
    F32.add(
      F32.square(F32.sub(x1, 2.0)),
      F32.add(
        F32.square(F32.sub(x2, 1.0)),
        F32.add(F32.square(F32.sub(x3, 4.0)), F32.square(F32.sub(x4, 1.0)))
      )
    )
  )
  F32.neg(pen) <> [sum_sq(x)]

# pymoo divisors, then negated so a positive value is a violation.
def osy_g(+x: List<&2, F32>) -> List<&2, F32>:
  +x0 = Util.get_f32(x, 0n)
  +x1 = Util.get_f32(x, 1n)
  +x2 = Util.get_f32(x, 2n)
  +x3 = Util.get_f32(x, 3n)
  +x4 = Util.get_f32(x, 4n)
  +x5 = Util.get_f32(x, 5n)
  F32.neg(F32.div(F32.sub(F32.add(x0, x1), 2.0), 2.0))
    <> F32.neg(F32.div(F32.sub(F32.sub(6.0, x0), x1), 6.0))
    <> F32.neg(F32.div(F32.add(F32.sub(2.0, x1), x0), 2.0))
    <> F32.neg(F32.div(F32.add(F32.sub(2.0, x0), F32.mul(3.0, x1)), 2.0))
    <> F32.neg(F32.div(F32.sub(F32.sub(4.0, F32.square(F32.sub(x2, 3.0))), x3), 4.0))
    <> [F32.neg(F32.div(F32.sub(F32.add(F32.square(F32.sub(x4, 3.0)), x5), 4.0), 4.0))]

def osy_score(+x: List<&2, F32>) -> Scored:
  Scored{osy_f(x), osy_g(x)}

# C# TnkProblem. g0 = -(x²+y²-1-0.1 cos(16 atan(x/y))). g1 = 2((x-0.5)²+(y-0.5)²)-1.
def tnk_g(+x: List<&2, F32>) -> List<&2, F32>:
  +x0 = Util.get_f32(x, 0n)
  +x1 = Util.get_f32(x, 1n)
  +circle = F32.sub(
    F32.sub(F32.add(F32.square(x0), F32.square(x1)), 1.0),
    F32.mul(0.1, F32.cos(F32.mul(16.0, F32.atan(F32.div(x0, x1)))))
  )
  +dx = F32.sub(x0, 0.5)
  +dy = F32.sub(x1, 0.5)
  F32.neg(circle) <> [F32.sub(F32.mul(2.0, F32.add(F32.square(dx), F32.square(dy))), 1.0)]

def tnk_score(+x: List<&2, F32>) -> Scored:
  Scored{Util.get_f32(x, 0n) <> [Util.get_f32(x, 1n)], tnk_g(x)}

# Last objective / 0.6, earlier objectives / 0.5. fuel starts at |f|.
def c1_w(fuel: Nat, fs: List<&2, F32>, +acc: F32) -> F32:
  match fuel:
    case 0n:
      acc
    case 1n:
      match fs:
        case Nil{}:
          acc
        case +h <> rest:
          F32.add(acc, F32.div(h, 0.6))
    case 1n+f:
      match fs:
        case Nil{}:
          acc
        case +h <> rest:
          c1_w(f, rest, F32.add(acc, F32.div(h, 0.5)))

def c1_g(+fs: List<&2, F32>) -> List<&2, F32>:
  [F32.sub(c1_w(Util.list_len(F32, fs), fs, 0.0), 1.0)]

def c1_score(+x: List<&2, F32>, +m: Nat) -> Scored:
  +f = dtlz1_f(x, m)
  Scored{f, c1_g(f)}

def eval_kind(kind: Family, +x: List<&2, F32>, +m: Nat, +alpha: F32) -> Scored:
  match kind:
    case Zdt1{}:
      plain(zdt1_f(x))
    case Zdt2{}:
      plain(zdt2_f(x))
    case Zdt3{}:
      plain(zdt3_f(x))
    case Zdt4{}:
      plain(zdt4_f(x))
    case Zdt6{}:
      plain(zdt6_f(x))
    case Dtlz1{}:
      plain(dtlz1_f(x, m))
    case Dtlz2{}:
      plain(dtlz2_f(x, m))
    case Dtlz3{}:
      plain(dtlz3_f(x, m))
    case Dtlz4{}:
      plain(dtlz4_f(x, m, alpha))
    case Dtlz7{}:
      plain(dtlz7_f(x, m))
    case Sphere{}:
      plain(sphere_f(x))
    case Ackley{}:
      plain(ackley_f(x))
    case Rosenbrock{}:
      plain(rosenbrock_f(x))
    case Osy{}:
      osy_score(x)
    case Tnk{}:
      tnk_score(x)
    case C1Dtlz1{}:
      c1_score(x, m)

def apply_score(+ind: Ind.Individual, s: Scored) -> Ind.Individual:
  match s:
    case Scored{f, g}:
      Ind.set_constraints(Ind.set_objectives(ind, f), g)

def evaluate(+p: Problem, +ind: Ind.Individual) -> Ind.Individual:
  apply_score(ind, eval_kind(kind_of(p), Ind.variables(ind), n_obj(p), alpha_of(p)))

# Independent per individual. Mid-split + parallel recurse; same order as cons.
def evaluate_all(+p: Problem, +xs: List<&2, Ind.Individual>) -> List<&2, Ind.Individual>:
  Util.map_halves(~Ind.Individual, ~Ind.Individual, ~Problem, ~evaluate, p, xs)
