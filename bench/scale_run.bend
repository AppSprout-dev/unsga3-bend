# Scaling-gate driver. One native binary, many cells.
#
#   ./scale_run --threads 1 <cell-id> gens=<N> burn=<P> [slow]
#
# `--threads` is a Bend runtime flag and is ignored here. `slow` selects
# bench/slow_pass.bend after Run. `gens=` is the generation budget.
# `burn=` is the negative-control weight (List.get repeats per index);
# the fast path ignores it. Omitted gens falls back to default_gens.
# This is a timing probe, not an oracle and not an IGD run.
# Cell ids and sizes must match bench/scale_gate.py.
#
# Grid (DTLZ2, k=10, seed=1, PymooCompatible, duplicate elimination on):
#   m0idle      runtime floor, no Run
#   m3p12n23    M=3 p=12 pop=23   (oracle reference set, smaller pop)
#   m3p12n46    M=3 p=12 pop=46
#   m3p12n92    M=3 p=12 pop=92   (oracle DTLZ2 shape; anchor)
#   m3p4n92     M=3 p=4  pop=92   (smoke partitions, oracle pop)
#   m3p8n92     M=3 p=8  pop=92   (mid partitions, oracle pop)
#   m5p4n70     M=5 p=4  pop=70   (pop = Das–Dennis count)
#   m8p2n36     M=8 p=2  pop=36
#   m8p3n120    M=8 p=3  pop=120

import Base
import ../src/algorithm.bend as Algo
import ../src/individual.bend as Ind
import ../src/problems.bend as Prob
import ../src/reference_directions.bend as Refs
import ../src/tournament.bend as Tour
import ../src/util.bend as Util
import ./slow_pass.bend as Slow

def default_gens() -> Nat:
  12n

type Burned is Data:
  Burned{
    variant: String
    sum: F32
    used: Nat
  }

type Flags is Data:
  MkFlags{
    cell: String
    gens: Nat
    passes: Nat
    slow: Bool
  }

type Seen is Data:
  SawSlow{}
  SawGens{n: Nat}
  SawBurn{n: Nat}
  SawCell{name: String}
  SawSkip{}

def flags0() -> Flags:
  MkFlags{"", default_gens(), 1n, False{}}

def flag_slow(+acc: Flags) -> Flags:
  match acc:
    case MkFlags{cell, gens, passes, slow}:
      MkFlags{cell, gens, passes, True{}}

def flag_gens(+acc: Flags, n: Nat) -> Flags:
  match acc:
    case MkFlags{cell, gens, passes, slow}:
      MkFlags{cell, n, passes, slow}

def flag_burn(+acc: Flags, n: Nat) -> Flags:
  match acc:
    case MkFlags{cell, gens, passes, slow}:
      MkFlags{cell, gens, n, slow}

def flag_cell(+acc: Flags, name: String) -> Flags:
  match acc:
    case MkFlags{cell, gens, passes, slow}:
      MkFlags{name, gens, passes, slow}

def read_pref(+h: String, +drop_n: Nat, +fallback: Nat) -> Nat:
  Maybe.default(&2, Nat, Nat.read(String.drop(h, drop_n)), fallback)

def classify.cell(is_cell: Bool, h: String) -> Seen:
  match is_cell:
    case True{}:
      SawCell{h}
    case False{}:
      SawSkip{}

def classify.burn(is_burn: Bool, +h: String) -> Seen:
  match is_burn:
    case True{}:
      SawBurn{read_pref(h, 5n, 1n)}
    case False{}:
      classify.cell(String.starts_with(h, "m"), h)

def classify.gens(is_gens: Bool, +h: String) -> Seen:
  match is_gens:
    case True{}:
      SawGens{read_pref(h, 5n, default_gens())}
    case False{}:
      classify.burn(String.starts_with(h, "burn="), h)

def classify.slow(is_slow: Bool, +h: String) -> Seen:
  match is_slow:
    case True{}:
      SawSlow{}
    case False{}:
      classify.gens(String.starts_with(h, "gens="), h)

def classify(+h: String) -> Seen:
  classify.slow(String.eq(h, "slow"), h)

def apply(seen: Seen, +acc: Flags) -> Flags:
  match seen:
    case SawSlow{}:
      flag_slow(acc)
    case SawGens{n}:
      flag_gens(acc, n)
    case SawBurn{n}:
      flag_burn(acc, n)
    case SawCell{name}:
      flag_cell(acc, name)
    case SawSkip{}:
      acc

def scan(args: List<String>, +acc: Flags) -> Flags:
  match args:
    case Nil{}:
      acc
    case +h <> t:
      scan(t, apply(classify(h), acc))

def after(slow: Bool, +pop: List<&2, Ind.Individual>, +passes: Nat) -> Burned:
  match slow:
    case True{}:
      Burned{"slow", Slow.burn(pop, passes), passes}
    case False{}:
      Burned{"fast", 0.0, 0n}

def show_lines(
  +cell: String,
  +m: Nat,
  +p: Nat,
  +pop_n: Nat,
  +gens: Nat,
  +nlen: Nat,
  +refs: Nat,
  +algo_ms: Nat,
  +run_ms: Nat,
  +burn_ms: Nat,
  burned: Burned
) -> IO(Unit):
  match burned:
    case Burned{variant, sum, used}:
      do IO<Unit>:
        IO.print("# cell=" ++ cell)
        IO.print("# variant=" ++ variant)
        IO.print("# problem=dtlz2")
        IO.print("# m=" ++ Nat.show(m))
        IO.print("# k=10")
        IO.print("# partitions=" ++ Nat.show(p))
        IO.print("# pop=" ++ Nat.show(pop_n))
        IO.print("# gens=" ++ Nat.show(gens))
        IO.print("# seed=1")
        IO.print("# tournament=pymoo")
        IO.print("# ref_points=" ++ Nat.show(refs))
        IO.print("# algo_ms=" ++ Nat.show(algo_ms))
        IO.print("# run_ms=" ++ Nat.show(run_ms))
        IO.print("# burn_ms=" ++ Nat.show(burn_ms))
        IO.print("# pop_len=" ++ Nat.show(nlen))
        IO.print("# burn=" ++ F32.show(sum))
        IO.print("# burn_weight=" ++ Nat.show(used))

def show(
  +cell: String,
  +m: Nat,
  +p: Nat,
  +pop_n: Nat,
  +gens: Nat,
  +nlen: Nat,
  +t0: Nat,
  +t1: Nat,
  +t2: Nat,
  burned: Burned
) -> IO(Unit):
  +refs = Refs.count(m, p)
  +run_ms = Nat.sub(t1, t0)
  +burn_ms = Nat.sub(t2, t1)
  show_lines(
    cell,
    m,
    p,
    pop_n,
    gens,
    nlen,
    refs,
    Nat.add(run_ms, burn_ms),
    run_ms,
    burn_ms,
    burned
  )

def emit(
  +cell: String,
  +m: Nat,
  +p: Nat,
  +pop_n: Nat,
  +gens: Nat,
  +passes: Nat,
  slow: Bool
) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    +pop : List<&2, Ind.Individual> = Algo.run(
      Prob.dtlz2(m, 10n),
      Algo.mk(Refs.das_dennis(m, p), pop_n, gens, 1n, Tour.pymoo(), True{})
    )
    t1 : Nat <- IO.now()
    nlen : Nat = Util.list_len(Ind.Individual, pop)
    burned : Burned = after(slow, pop, passes)
    t2 : Nat <- IO.now()
    show(cell, m, p, pop_n, gens, nlen, t0, t1, t2, burned)

def emit_idle(+cell: String, +gens: Nat) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    t1 : Nat <- IO.now()
    IO.print("# cell=" ++ cell)
    IO.print("# variant=idle")
    IO.print("# problem=idle")
    IO.print("# m=0")
    IO.print("# k=0")
    IO.print("# partitions=0")
    IO.print("# pop=0")
    IO.print("# gens=" ++ Nat.show(gens))
    IO.print("# seed=1")
    IO.print("# tournament=none")
    IO.print("# ref_points=0")
    IO.print("# algo_ms=" ++ Nat.show(Nat.sub(t1, t0)))
    IO.print("# run_ms=0")
    IO.print("# burn_ms=0")
    IO.print("# pop_len=0")
    IO.print("# burn=0.0")
    IO.print("# burn_weight=0")

def dispatch.miss(+cell: String) -> IO(Unit):
  IO.die(Unit, 2, "unknown cell " ++ cell)

def dispatch.m8p3(eq: Bool, slow: Bool, +cell: String, +gens: Nat, +passes: Nat) -> IO(Unit):
  match eq:
    case True{}:
      emit(cell, 8n, 3n, 120n, gens, passes, slow)
    case False{}:
      dispatch.miss(cell)

def dispatch.m8p2(eq: Bool, slow: Bool, +cell: String, +gens: Nat, +passes: Nat) -> IO(Unit):
  match eq:
    case True{}:
      emit(cell, 8n, 2n, 36n, gens, passes, slow)
    case False{}:
      dispatch.m8p3(String.eq(cell, "m8p3n120"), slow, cell, gens, passes)

def dispatch.m5(eq: Bool, slow: Bool, +cell: String, +gens: Nat, +passes: Nat) -> IO(Unit):
  match eq:
    case True{}:
      emit(cell, 5n, 4n, 70n, gens, passes, slow)
    case False{}:
      dispatch.m8p2(String.eq(cell, "m8p2n36"), slow, cell, gens, passes)

def dispatch.m3p8(eq: Bool, slow: Bool, +cell: String, +gens: Nat, +passes: Nat) -> IO(Unit):
  match eq:
    case True{}:
      emit(cell, 3n, 8n, 92n, gens, passes, slow)
    case False{}:
      dispatch.m5(String.eq(cell, "m5p4n70"), slow, cell, gens, passes)

def dispatch.m3p4(eq: Bool, slow: Bool, +cell: String, +gens: Nat, +passes: Nat) -> IO(Unit):
  match eq:
    case True{}:
      emit(cell, 3n, 4n, 92n, gens, passes, slow)
    case False{}:
      dispatch.m3p8(String.eq(cell, "m3p8n92"), slow, cell, gens, passes)

def dispatch.m3p12n92(eq: Bool, slow: Bool, +cell: String, +gens: Nat, +passes: Nat) -> IO(Unit):
  match eq:
    case True{}:
      emit(cell, 3n, 12n, 92n, gens, passes, slow)
    case False{}:
      dispatch.m3p4(String.eq(cell, "m3p4n92"), slow, cell, gens, passes)

def dispatch.m3p12n46(eq: Bool, slow: Bool, +cell: String, +gens: Nat, +passes: Nat) -> IO(Unit):
  match eq:
    case True{}:
      emit(cell, 3n, 12n, 46n, gens, passes, slow)
    case False{}:
      dispatch.m3p12n92(String.eq(cell, "m3p12n92"), slow, cell, gens, passes)

def dispatch.m3p12n23(eq: Bool, slow: Bool, +cell: String, +gens: Nat, +passes: Nat) -> IO(Unit):
  match eq:
    case True{}:
      emit(cell, 3n, 12n, 23n, gens, passes, slow)
    case False{}:
      dispatch.m3p12n46(String.eq(cell, "m3p12n46"), slow, cell, gens, passes)

def dispatch.idle(eq: Bool, slow: Bool, +cell: String, +gens: Nat, +passes: Nat) -> IO(Unit):
  match eq:
    case True{}:
      emit_idle(cell, gens)
    case False{}:
      dispatch.m3p12n23(String.eq(cell, "m3p12n23"), slow, cell, gens, passes)

def go(+f: Flags) -> IO(Unit):
  match f:
    case MkFlags{+cell, +gens, +passes, slow}:
      dispatch.idle(String.eq(cell, "m0idle"), slow, cell, gens, passes)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    go(scan(args, flags0()))
