# Scaling-gate driver. One native binary, many cells.
#
#   ./scale_run --threads 1 <cell-id> gens=<N> burn=<P> mode=<name>
#
# `--threads` is a Bend runtime flag and is ignored here. `mode=` is
# fast (Run), uniform (Run, then spin until the clock has moved by another
# run_ms), quad (O(N²) arithmetic, no Run), cubic (Run, then slow_pass),
# alloc (cons list of 1000*N), alloc2 (cons list of N*N).
# A bare `slow` is mode=cubic. Omitted gens falls back to 16.
# Cell ids and sizes must match bench/gate.config.json.
#
# This is a timing probe, not an oracle and not an IGD run.

import Base
import ../src/algorithm.bend as Algo
import ../src/individual.bend as Ind
import ../src/problems.bend as Prob
import ../src/reference_directions.bend as Refs
import ../src/tournament.bend as Tour
import ../src/util.bend as Util
import ./alloc_pass.bend as Alloc
import ./quad_pass.bend as Quad
import ./slow_pass.bend as Slow

def default_gens() -> Nat:
  16n

type Flags is Data:
  MkFlags{
    cell: String
    gens: Nat
    passes: Nat
    mode: String
  }

type Seen is Data:
  SawMode{name: String}
  SawGens{n: Nat}
  SawBurn{n: Nat}
  SawCell{name: String}
  SawSkip{}

def flags0() -> Flags:
  MkFlags{"", default_gens(), 1n, "fast"}

def flag_mode(+acc: Flags, name: String) -> Flags:
  match acc:
    case MkFlags{cell, gens, passes, mode}:
      MkFlags{cell, gens, passes, name}

def flag_gens(+acc: Flags, n: Nat) -> Flags:
  match acc:
    case MkFlags{cell, gens, passes, mode}:
      MkFlags{cell, n, passes, mode}

def flag_burn(+acc: Flags, n: Nat) -> Flags:
  match acc:
    case MkFlags{cell, gens, passes, mode}:
      MkFlags{cell, gens, n, mode}

def flag_cell(+acc: Flags, name: String) -> Flags:
  match acc:
    case MkFlags{cell, gens, passes, mode}:
      MkFlags{name, gens, passes, mode}

def read_pref(+h: String, +drop_n: Nat, +fallback: Nat) -> Nat:
  Maybe.default(&2, Nat, Nat.read(String.drop(h, drop_n)), fallback)

def classify.acell(is_a: Bool, h: String) -> Seen:
  match is_a:
    case True{}:
      SawCell{h}
    case False{}:
      SawSkip{}

def classify.cell(is_cell: Bool, +h: String) -> Seen:
  match is_cell:
    case True{}:
      SawCell{h}
    case False{}:
      classify.acell(String.starts_with(h, "a"), h)

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
      SawMode{"cubic"}
    case False{}:
      classify.gens(String.starts_with(h, "gens="), h)

def classify.mode(is_mode: Bool, +h: String) -> Seen:
  match is_mode:
    case True{}:
      SawMode{String.drop(h, 5n)}
    case False{}:
      classify.slow(String.eq(h, "slow"), h)

def classify(+h: String) -> Seen:
  classify.mode(String.starts_with(h, "mode="), h)

def apply(seen: Seen, +acc: Flags) -> Flags:
  match seen:
    case SawMode{name}:
      flag_mode(acc, name)
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

def chunk(fuel: Nat, acc: F32) -> F32:
  match fuel:
    case 0n:
      acc
    case 1n+f:
      chunk(f, F32.add(acc, 1.0))

# Fuel shrinks every chunk so the recursion is structural. The clock stops
# it earlier. 200000 chunks is the cap, not the expected depth: each step
# does 8000 additions before the next read.
def drag.spin(fuel: Nat, cont: Bool, +target: Nat, acc: F32) -> IO(F32):
  match fuel cont:
    case 0n False{}:
      IO.pure(F32, acc)
    case 0n True{}:
      IO.pure(F32, acc)
    case 1n+f False{}:
      IO.pure(F32, acc)
    case 1n+f True{}:
      do IO<F32>:
        now : Nat <- IO.now()
        nxt : F32 = chunk(8000n, acc)
        drag.spin(f, Nat.is_lt(now, target), target, nxt)

def drag(extra: Nat) -> IO(F32):
  do IO<F32>:
    t0 : Nat <- IO.now()
    drag.spin(200000n, True{}, Nat.add(t0, extra), 0.0)

def show_lines(
  +cell: String,
  +mode: String,
  +m: Nat,
  +p: Nat,
  +pop_n: Nat,
  +gens: Nat,
  +nlen: Nat,
  +refs: Nat,
  +algo_ms: Nat,
  +run_ms: Nat,
  +burn_ms: Nat,
  +note: String
) -> IO(Unit):
  do IO<Unit>:
    IO.print("# cell=" ++ cell)
    IO.print("# variant=" ++ mode)
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
    IO.print("# burn=" ++ note)
    IO.print("# burn_weight=" ++ Nat.show(nlen))

def emit_fast(
  +cell: String,
  +m: Nat,
  +p: Nat,
  +pop_n: Nat,
  +gens: Nat
) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    +pop : List<&2, Ind.Individual> = Algo.run(
      Prob.dtlz2(m, 10n),
      Algo.mk(Refs.das_dennis(m, p), pop_n, gens, 1n, Tour.pymoo(), True{})
    )
    t1 : Nat <- IO.now()
    nlen : Nat = Util.list_len(Ind.Individual, pop)
    +run_ms : Nat = Nat.sub(t1, t0)
    show_lines(cell, "fast", m, p, pop_n, gens, nlen, Refs.count(m, p), run_ms, run_ms, 0n, "0.0")

def emit_uniform(
  +cell: String,
  +m: Nat,
  +p: Nat,
  +pop_n: Nat,
  +gens: Nat
) -> IO(Unit):
  do IO<Unit>:
    +t0 : Nat <- IO.now()
    +pop : List<&2, Ind.Individual> = Algo.run(
      Prob.dtlz2(m, 10n),
      Algo.mk(Refs.das_dennis(m, p), pop_n, gens, 1n, Tour.pymoo(), True{})
    )
    +t1 : Nat <- IO.now()
    +run_ms : Nat = Nat.sub(t1, t0)
    spun : F32 <- drag(run_ms)
    +t2 : Nat <- IO.now()
    nlen : Nat = Util.list_len(Ind.Individual, pop)
    +algo : Nat = Nat.sub(t2, t0)
    +extra : Nat = Nat.sub(t2, t1)
    show_lines(cell, "uniform", m, p, pop_n, gens, nlen, Refs.count(m, p), algo, run_ms, extra, F32.show(spun))

def emit_cubic(
  +cell: String,
  +m: Nat,
  +p: Nat,
  +pop_n: Nat,
  +gens: Nat,
  +passes: Nat
) -> IO(Unit):
  do IO<Unit>:
    +t0 : Nat <- IO.now()
    +pop : List<&2, Ind.Individual> = Algo.run(
      Prob.dtlz2(m, 10n),
      Algo.mk(Refs.das_dennis(m, p), pop_n, gens, 1n, Tour.pymoo(), True{})
    )
    +t1 : Nat <- IO.now()
    sum : F32 = Slow.burn(pop, passes)
    +t2 : Nat <- IO.now()
    nlen : Nat = Util.list_len(Ind.Individual, pop)
    +run_ms : Nat = Nat.sub(t1, t0)
    +burn_ms : Nat = Nat.sub(t2, t1)
    show_lines(
      cell,
      "cubic",
      m,
      p,
      pop_n,
      gens,
      nlen,
      Refs.count(m, p),
      Nat.add(run_ms, burn_ms),
      run_ms,
      burn_ms,
      F32.show(sum)
    )

def emit_quad(+cell: String, +m: Nat, +p: Nat, +pop_n: Nat, +gens: Nat, +passes: Nat) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    sum : F32 = Quad.burn(pop_n, passes)
    t1 : Nat <- IO.now()
    +ms : Nat = Nat.sub(t1, t0)
    show_lines(cell, "quad", m, p, pop_n, gens, pop_n, 0n, ms, 0n, ms, F32.show(sum))

def emit_alloc(
  +cell: String,
  +mode: String,
  +pop_n: Nat,
  +count: Nat
) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    +kept : Nat = Alloc.alloc(count)
    t1 : Nat <- IO.now()
    +ms : Nat = Nat.sub(t1, t0)
    show_lines(cell, mode, 0n, 0n, pop_n, 0n, kept, 0n, ms, 0n, ms, Nat.show(kept))

def emit_idle(+cell: String, +gens: Nat, +mode: String) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    t1 : Nat <- IO.now()
    show_lines(cell, "idle", 0n, 0n, 0n, gens, 0n, 0n, Nat.sub(t1, t0), 0n, 0n, mode)

def start.miss(+mode: String, +cell: String) -> IO(Unit):
  IO.die(Unit, 2, "unknown mode " ++ mode ++ " for " ++ cell)

def start.fast(
  eq: Bool,
  +mode: String,
  +cell: String,
  +m: Nat,
  +p: Nat,
  +pop_n: Nat,
  +gens: Nat,
  +passes: Nat
) -> IO(Unit):
  match eq:
    case True{}:
      emit_fast(cell, m, p, pop_n, gens)
    case False{}:
      start.miss(mode, cell)

def start.alloc2(
  eq: Bool,
  +mode: String,
  +cell: String,
  +m: Nat,
  +p: Nat,
  +pop_n: Nat,
  +gens: Nat,
  +passes: Nat
) -> IO(Unit):
  match eq:
    case True{}:
      emit_alloc(cell, mode, pop_n, Nat.mul(pop_n, pop_n))
    case False{}:
      start.fast(String.eq(mode, "fast"), mode, cell, m, p, pop_n, gens, passes)

def start.alloc(
  eq: Bool,
  +mode: String,
  +cell: String,
  +m: Nat,
  +p: Nat,
  +pop_n: Nat,
  +gens: Nat,
  +passes: Nat
) -> IO(Unit):
  match eq:
    case True{}:
      emit_alloc(cell, mode, pop_n, Nat.mul(pop_n, 1000n))
    case False{}:
      start.alloc2(String.eq(mode, "alloc2"), mode, cell, m, p, pop_n, gens, passes)

def start.cubic(
  eq: Bool,
  +mode: String,
  +cell: String,
  +m: Nat,
  +p: Nat,
  +pop_n: Nat,
  +gens: Nat,
  +passes: Nat
) -> IO(Unit):
  match eq:
    case True{}:
      emit_cubic(cell, m, p, pop_n, gens, passes)
    case False{}:
      start.alloc(String.eq(mode, "alloc"), mode, cell, m, p, pop_n, gens, passes)

def start.quad(
  eq: Bool,
  +mode: String,
  +cell: String,
  +m: Nat,
  +p: Nat,
  +pop_n: Nat,
  +gens: Nat,
  +passes: Nat
) -> IO(Unit):
  match eq:
    case True{}:
      emit_quad(cell, m, p, pop_n, gens, passes)
    case False{}:
      start.cubic(String.eq(mode, "cubic"), mode, cell, m, p, pop_n, gens, passes)

def start.uniform(
  eq: Bool,
  +mode: String,
  +cell: String,
  +m: Nat,
  +p: Nat,
  +pop_n: Nat,
  +gens: Nat,
  +passes: Nat
) -> IO(Unit):
  match eq:
    case True{}:
      emit_uniform(cell, m, p, pop_n, gens)
    case False{}:
      start.quad(String.eq(mode, "quad"), mode, cell, m, p, pop_n, gens, passes)

def start(
  +mode: String,
  +cell: String,
  +m: Nat,
  +p: Nat,
  +pop_n: Nat,
  +gens: Nat,
  +passes: Nat
) -> IO(Unit):
  start.uniform(String.eq(mode, "uniform"), mode, cell, m, p, pop_n, gens, passes)

def dispatch.miss(+cell: String) -> IO(Unit):
  IO.die(Unit, 2, "unknown cell " ++ cell)

def arm(
  eq: Bool,
  +mode: String,
  +cell: String,
  +gens: Nat,
  +passes: Nat,
  +m: Nat,
  +p: Nat,
  +pop_n: Nat,
  next: IO(Unit)
) -> IO(Unit):
  match eq:
    case True{}:
      start(mode, cell, m, p, pop_n, gens, passes)
    case False{}:
      next

def go(+cell: String, +gens: Nat, +passes: Nat, +mode: String) -> IO(Unit):
  arm(
    String.eq(cell, "m0idle"),
    mode,
    cell,
    gens,
    passes,
    0n,
    0n,
    0n,
    arm(
      String.eq(cell, "m3p12n46"),
      mode,
      cell,
      gens,
      passes,
      3n,
      12n,
      46n,
      arm(
        String.eq(cell, "m3p12n92"),
        mode,
        cell,
        gens,
        passes,
        3n,
        12n,
        92n,
        arm(
          String.eq(cell, "m3p12n138"),
          mode,
          cell,
          gens,
          passes,
          3n,
          12n,
          138n,
          arm(
            String.eq(cell, "m3p12n184"),
            mode,
            cell,
            gens,
            passes,
            3n,
            12n,
            184n,
            arm(
              String.eq(cell, "m3p12n276"),
              mode,
              cell,
              gens,
              passes,
              3n,
              12n,
              276n,
              arm(
                String.eq(cell, "m3p12n368"),
                mode,
                cell,
                gens,
                passes,
                3n,
                12n,
                368n,
                arm(
                  String.eq(cell, "m3p12n3000"),
                  mode,
                  cell,
                  gens,
                  passes,
                  3n,
                  12n,
                  3000n,
                  arm(
                    String.eq(cell, "m3p4n92"),
                    mode,
                    cell,
                    gens,
                    passes,
                    3n,
                    4n,
                    92n,
                    arm(
                      String.eq(cell, "m3p8n92"),
                      mode,
                      cell,
                      gens,
                      passes,
                      3n,
                      8n,
                      92n,
                      arm(
                        String.eq(cell, "m3p20n92"),
                        mode,
                        cell,
                        gens,
                        passes,
                        3n,
                        20n,
                        92n,
                        arm(
                          String.eq(cell, "m5p4n70"),
                          mode,
                          cell,
                          gens,
                          passes,
                          5n,
                          4n,
                          70n,
                          arm(
                            String.eq(cell, "m8p2n36"),
                            mode,
                            cell,
                            gens,
                            passes,
                            8n,
                            2n,
                            36n,
                            arm(
                              String.eq(cell, "m8p3n120"),
                              mode,
                              cell,
                              gens,
                              passes,
                              8n,
                              3n,
                              120n,
                              arm(
                                String.eq(cell, "a400"),
                                mode,
                                cell,
                                gens,
                                passes,
                                0n,
                                0n,
                                400n,
                                arm(
                                  String.eq(cell, "a800"),
                                  mode,
                                  cell,
                                  gens,
                                  passes,
                                  0n,
                                  0n,
                                  800n,
                                  arm(
                                    String.eq(cell, "a1600"),
                                    mode,
                                    cell,
                                    gens,
                                    passes,
                                    0n,
                                    0n,
                                    1600n,
                                    arm(
                                      String.eq(cell, "a3200"),
                                      mode,
                                      cell,
                                      gens,
                                      passes,
                                      0n,
                                      0n,
                                      3200n,
                                      arm(
                                        String.eq(cell, "a6400"),
                                        mode,
                                        cell,
                                        gens,
                                        passes,
                                        0n,
                                        0n,
                                        6400n,
                                        dispatch.miss(cell)
                                      )
                                    )
                                  )
                                )
                              )
                            )
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )

def go.pick(idle: Bool, +cell: String, +gens: Nat, +passes: Nat, +mode: String) -> IO(Unit):
  match idle:
    case True{}:
      emit_idle(cell, gens, mode)
    case False{}:
      go(cell, gens, passes, mode)

def go.flags(+f: Flags) -> IO(Unit):
  match f:
    case MkFlags{+cell, +gens, +passes, +mode}:
      go.pick(String.eq(cell, "m0idle"), cell, gens, passes, mode)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    go.flags(scan(args, flags0()))
